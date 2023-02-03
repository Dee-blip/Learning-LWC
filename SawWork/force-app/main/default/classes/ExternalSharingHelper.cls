/* ========================================================================
    Author: Sonia Sawhney
    Description: Helper class used for creating the S2S sync for the object
    Created Date : 07/21/2013
    Modification History:
    1. ssawhney on 03/17/2013 for preventing records from being added to S2S tables when primary org is down
    2. ssawhney on 07/17/2014 CR 2712153 - Reverse Update Issue for Objects
    3. ssawhney on 08/19/2014 CR 2753364 - Need to Sync Email messages from Prod to DR and Vice Verse
	4. Jay		on 03/15/2015 CR:2789994 -  added new article type and sync to DR functionality for new object
    5. ssawhney on 04/20/2015 CR 2979290 - Convert KB Article DR sync to dynamic code so that new article type addition can be a config change 
    Test Classes : 
	TestDRTriggers
    CreateRecordsBatchTest
    BatchableDeleteRecordsTest
    TestExternalSharingHelper
    TestKnowledgeArticleBatchables
    BatchablePushCreatedRecordsToProd_Test
    BatchableAccountTeamMembersTest
    TestCaseArticleBatchables 
    ======================================================================== */
public class ExternalSharingHelper
{ 
    //static variable used to control recursive trigger calls
    public static boolean isTriggerFutureControl = false;
    public static boolean RunFromtestClass = false;
    
    //map to store the mapping of read write and lookup fields 
    public static map<string, string> mpFields = new map<string, string>();
    
    //Extract all objects that can have tasks associated with them
    public static set<Schema.sobjectType> taskEnabledObjects;
    
    static{
        taskEnabledObjects  = new set<Schema.sobjectType>();
        taskEnabledObjects.addAll(Task.WhatId.getDescribe().getReferenceTo());
    }

    //method used to create the sync between the primary and DR org
    public static void createS2Ssync(string parentFieldName, list<sObject> newObjects,string relatedRecords) 
    { 
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
            Id networkId = ConnectionHelper.getConnectionId(); 
        
            Set<Id> localObjectParentSet = new Set<Id>(); 
            List<sObject> lstObjects = new List<sObject>(); 
            Set<Id> sharedParentSet = new Set<Id>();    
        
            // only share records created in this org, do not add records received from another org. 
            for (sObject obj: newObjects) { 
                if (obj.get('ConnectionReceivedId') == null && (parentFieldName == null || parentFieldName == '' || (parentFieldName != '' && obj.get(parentFieldName) != null))) { 
                    //create a list of parent record ids 
                    if(parentFieldName != null && parentFieldName != '')
                        localObjectParentSet.add((Id)obj.get(parentFieldName)); 
                    lstObjects.add(obj); 
                }         
            } 
    
            if(lstObjects.size()>0)
            {
                
                //This code will only be excuted if the object has a parent object
                if (localObjectParentSet.size() > 0) { 
                    // Get the parent's partner network record connections 
                    for (PartnerNetworkRecordConnection sharingRecord:  
                                              [SELECT p.Status, p.LocalRecordId, p.ConnectionId 
                                               FROM PartnerNetworkRecordConnection p              
                                               WHERE p.LocalRecordId IN:localObjectParentSet]) { 
                              
                        // for each partner connection record for contact's account, check if it is active 
                        if ((sharingRecord.status.equalsignorecase('Sent') || sharingRecord.status.equalsignorecase('Pending') 
                          || sharingRecord.status.equalsignorecase('Received'))
                          && sharingRecord.ConnectionId == networkId) { 
                            sharedParentSet.add(sharingRecord.LocalRecordId); 
                        }               
                    } 
                }     
                 
                //Add an entry in the Partner Shadow table if the primary org is down
                if(environmentSetup.Environment_Type__c == 'DR' && environmentSetup.Active_Org__c == true)
                {
                    List<Partner_Connection__c> shadowconnections =  new  List<Partner_Connection__c>(); 
                        
                    for (sObject newObject : lstObjects) { 
                          //sync child only if the parent is shared
                         if (parentFieldName == null || parentFieldName == '' || sharedParentSet.contains((Id)newObject.get(parentFieldName))) {        
                             Partner_Connection__c newShadowConnection = new Partner_Connection__c(  
                                 LocalRecordId__c = newObject.Id, 
                                 RelatedRecords__c = relatedRecords,
                                 Operation__c = 'Insert');
                              
                             if(parentFieldName != null && parentFieldName != '')
                                  newShadowConnection.ParentRecordId__c = (Id)newObject.get(parentFieldName);                       
                             shadowconnections.add(newShadowConnection);    
                         }                 
                    } 
            
                    if (shadowconnections.size() > 0 ) { 
                           database.insert(shadowconnections,false); 
                    }    
                }
                else
                {
                    List<PartnerNetworkRecordConnection> connections =  new  List<PartnerNetworkRecordConnection>(); 
                        
                    for (sObject newObject : lstObjects) { 
                        //sync child only if the parent is shared
                        if (parentFieldName == null || parentFieldName == '' || sharedParentSet.contains((Id)newObject.get(parentFieldName))) {             
                            
                            PartnerNetworkRecordConnection newConnection = 
                              new PartnerNetworkRecordConnection( 
                                  ConnectionId = networkId, 
                                  LocalRecordId = newObject.Id, 
                                  RelatedRecords = relatedRecords,
                                  SendEmails = false );
                                  
                             Schema.sobjectType objectType = newObject.Id.getSObjectType();
                             
                             if(taskEnabledObjects.contains(objectType)){
                                 newConnection.SendClosedTasks = true;
                                 newConnection.SendOpenTasks = true;
                             }
                             if(parentFieldName != null && parentFieldName != '')
                                  newConnection.ParentRecordId = (Id)newObject.get(parentFieldName);                       
                             connections.add(newConnection);                     
                        } 
                    } 
            
                    if (connections.size() > 0 ) { 
                           database.insert(connections,false); 
                    } 
                }
            }
         }
    }
     
    //Capture the record updates in case of primary org down time
    public static void CaptureRecordUpdate(string objectName, set<Id> localrecordIds) 
    { 
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance(); 
        
            //Add an entry in the Partner Shadow table if the primary org is down 
            if(environmentSetup.Environment_Type__c == 'DR' && environmentSetup.Active_Org__c == true)
            {
                //Fetch all the Ids that are already present in the queue for syncing
                list<Partner_Connection__c> lstExistingRecords = [Select LocalRecordId__c from Partner_Connection__c where LocalRecordId__c in :localrecordIds and Synced__c=false];
                Set<Id> existingIds = new Set<Id>();
                
                if(lstExistingRecords.size() > 0)
                {    
                    for (Partner_Connection__c partner : lstExistingRecords) {   
                        existingIds.add(partner.LocalRecordId__c);
                    }
                }          
                
                List<Partner_Connection__c> shadowconnections =  new  List<Partner_Connection__c>(); 
                    
                //Add records to the Partner Connection object
                for (Id localId : localrecordIds) { 
                    //Do not add the records if already present for syncing
                    if(!existingIds.contains(localId))
                    {
                        Partner_Connection__c newShadowConnection = new Partner_Connection__c(  
                        LocalRecordId__c = localId,
                        Operation__c = 'Update',
                        Object_Name__c = objectName);                     
                        shadowconnections.add(newShadowConnection); 
                    }                    
                } 
        
                if (shadowconnections.size() > 0 ) { 
                       database.insert(shadowconnections,false); 
                }    
            }
        }
    }
        
    //static method used to link the lookup fields used for shadow object approach
    public static void linkObjectsSync(string objectName, list<sObject> lstObjects, boolean isUpdate, Map<Id, sObject> oldMap) 
    {     
        if(UserInfo.getName().equalsIgnoreCase('Connection User') || system.Test.isRunningTest())
        {
            list<sObject> filteredObjects = new list<sObject>();
            if(mpFields.size() > 0)
                 mpFields = new map<string, string>();
            
            //fetch the lookup mappings and store in a map
            list<Object_Lookup_Sync__c> lstFields = [Select RW_Field_Name__c, Lookup_Field_Name__c from Object_Lookup_Sync__c
                                                    where Object_Name__c = :objectName and User_Lookup__c = false];
            if(lstFields.size() > 0)
            {
                for(Object_Lookup_Sync__c field : lstFields)
                {
                    mpFields.put(field.RW_Field_Name__c, field.Lookup_Field_Name__c); 
                }
                
                //check if any updates has been made to any of the fields and add them to the set
                for (sObject obj : lstObjects)
                {
                    Id objId = (Id)obj.get('Id');
                    for (string fieldName : mpFields.keyset())
                    {
                        if((!IsUpdate && obj.get(fieldName) != null && obj.get(fieldName) != '') ||
                        (IsUpdate && (oldMap.get(objId)).get(fieldName) != obj.get(fieldName)))
                        {
                            filteredObjects.add(obj);
                            break;
                        }
                    }
                }
            } 
            //create a set of ids for which the corrsponding id in the current org needs to be fetched
            Set<Id> partnerIdSet = new Set<Id>(); 
            for (sObject obj: filteredObjects) 
            { 
                for (string fieldName : mpFields.keyset())
                { 
                    if(obj.get(fieldName) != null && obj.get(fieldName) != '')
                    {
                        Id partnerId = (Id) obj.get(fieldName);
                        partnerIdSet.add(partnerId); 
                    }
                }
            } 
            //create the mapping for source and target ids 
            Map<Id,Id> sourceTargetMap = new Map<Id,Id>(); 
            
            for (PartnerNetworkRecordConnection connection : 
                [SELECT Id, Status, ConnectionId, PartnerRecordId, LocalRecordId 
                 FROM PartnerNetworkRecordConnection 
                 WHERE PartnerRecordId in :partnerIdSet]) {                 
                if ( connection.Status == 'Sent' || connection.Status == 'Received')
                {                                                                
                    sourceTargetMap.put(connection.PartnerRecordId, connection.LocalRecordId); 
                } 
            } 
            
            //update all lookup fields for the object if the corresponding id is found in the source org
            for (sObject obj: filteredObjects) { 
                for (string fieldName : mpFields.keyset())
                { 
                    if(obj.get(fieldName) != null && obj.get(fieldName) != '' )
                    {
                        Id sourceId = (Id) obj.get(fieldName);
                        if(sourceTargetMap.get(sourceId) != null)
                        {
                            Id targetId = sourceTargetMap.get(sourceId);
                            obj.put(mpFields.get(fieldName),targetId);
                        }
                    }
                }                                                         
            }   
        }                       
    }
    
    //static method used to link the user or queue lookup fields. 
    //NOTE: for fields that could be user or queue, the value will be prefixed with User| or Queue| to denote the difference, 
    // otherwise we will assume it is a user 
    public static void linkUserLookups(string objectName, list<sObject> lstObjects, boolean isUpdate, Map<Id, sObject> oldMap){     
        if(UserInfo.getName().equalsIgnoreCase('Connection User') || system.Test.isRunningTest())
        {
            List<sObject> filteredObjects = new List<sObject>();
            if(mpFields.size() > 0)
                 mpFields = new Map<String, String>();
            
            //fetch the lookup mappings and store in a map
            list<Object_Lookup_Sync__c> lstFields = [Select RW_Field_Name__c, Lookup_Field_Name__c From Object_Lookup_Sync__c
                                                    Where Object_Name__c = :objectName And User_Lookup__c = true];
            if(lstFields.size() > 0){
                for(Object_Lookup_Sync__c field : lstFields){
                    mpFields.put(field.RW_Field_Name__c, field.Lookup_Field_Name__c); 
                }
                
                //check if any updates have been made to any of the fields and add them to the list
                for (sObject obj : lstObjects){
                    Id objId = (Id)obj.get('Id');
                    for (string fieldName : mpFields.keyset()){
                        if((!IsUpdate && obj.get(fieldName) != null && obj.get(fieldName) != '') ||
                            (IsUpdate && (oldMap.get(objId)).get(fieldName) != obj.get(fieldName)))
                        {
                            filteredObjects.add(obj);
                            break;
                        }
                    }
                }
            }
             
            //fetch all the user or queue values 
            Set<String> userAkamIds = new Set<String>();
            Set<String> queueDevNames = new Set<String>();
            for (sObject obj: filteredObjects){
                for (string fieldName : mpFields.keyset()){ 
                    Id objId = (Id)obj.get('Id');
                    if((!IsUpdate && obj.get(fieldName) != null && obj.get(fieldName) != '') ||
                        (IsUpdate && (oldMap.get(objId)).get(fieldName) != obj.get(fieldName)))
                    {
                        String lookupValue = (String) obj.get(fieldName);
                        if(lookupValue.contains('User|')){
                            String userAkamID = lookupValue.remove('User|');
                            userAkamIds.add(userAkamID);
                            obj.put(fieldName, userAkamID);
                        }
                        else if(lookupValue.contains('Queue|')){
                            String queueDevName = lookupValue.remove('Queue|');
                            queueDevNames.add(queueDevName);
                            obj.put(fieldName, queueDevName);
                        }
                        else {
                            string akamId = (string) obj.get(fieldName);
                            userAkamIds.add(akamId);
                        }
                    }
                }
            }
            
            //fetch the user or queue information and update the owner id
            Map<String, Id> userMap = new  Map<String, Id>();
            set<string> activeUsers = new  set<string>();
            try{
                for(User usr: [Select Id, AKAM_User_ID__c, isActive From User Where AKAM_User_ID__c IN: userAkamIds]){
                    userMap.put(usr.AKAM_User_ID__c, usr.Id);
                    if(usr.isActive)
                    {
                        activeUsers.add(usr.AKAM_User_ID__c);
                    }
                }
            } catch(Exception e){}
            
            Map<String, Id> queueMap = new  Map<String, Id>();
            try{
                for(Group grp: [Select Id, DeveloperName From Group Where DeveloperName IN: queueDevNames]){
                    queueMap.put(grp.DeveloperName, grp.Id);
                } 
            } catch(Exception e){}
            
            //update all lookup fields for the object if the user/queue id is found
            for (sObject obj: filteredObjects) { 
                for (string fieldName : mpFields.keyset()){ 
                    if(obj.get(fieldName) != null && obj.get(fieldName) != '' ){
                        String lookupVal = (String) obj.get(fieldName);
                        if(userMap.containsKey(lookupVal)){
                            if(!mpFields.get(fieldName).EqualsIgnoreCase('ownerid') || activeUsers.contains(lookupVal))
                            {
                                obj.put(mpFields.get(fieldName), userMap.get(lookupVal));
                            }
                        }
                        else if(queueMap.containsKey(lookupVal)){
                            obj.put(mpFields.get(fieldName), queueMap.get(lookupVal));
                        }
                    }
                }                                                         
            }   
        }                       
    }  
    
    //static method used for setting the correct record type
    public static void linkRecordType(string objectName, string rwFieldName, list<sObject> lstObjects){     
               
        if(UserInfo.getName().equalsIgnoreCase('Connection User') || system.Test.isRunningTest())
        {
            //fetch all the record type Ids
            String soql = 'SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = \'' + objectName + '\' AND IsActive = TRUE';
            List<RecordType> results = Database.query(soql);
            
            //create a map of developer names and record type Ids
            map<String, Id> recordTypeMap = new map<String, Id>();
            for(RecordType obj : results){
                recordTypeMap.put(obj.DeveloperName, obj.Id);
            }
            
            //map the correct record types
            for (sObject obj: lstObjects){
                if(obj.get(rwFieldName) != null && obj.get(rwFieldName) != '' && recordTypeMap.containsKey((string)obj.get(rwFieldName))) {
                    obj.put('RecordTypeId', recordTypeMap.get((string)obj.get(rwFieldName)));
                }
            }
         }    
     }
        
    //Method to update the AccountTeamMember ids on the shadow objects
    @future
    public static void UpdateAccountTeams(map<string,Id> mapAccountTeamObject, map<string,Id> mapShadowObject)
    {
        list<Account_team__c> lstTeams = new list<Account_team__c>();
        //Update the corresponding Account team Id at the shadow object
        for(string key : mapAccountTeamObject.keyset())
        {
            Account_team__c team = new Account_team__c(Id = mapShadowObject.get(key),
                                             AccountTeamId__c = mapAccountTeamObject.get(key));
            lstTeams.add(team);
        }
        ExternalSharingHelper.isTriggerFutureControl = true;
        update lstTeams;
    }     
    
    public static void CreateUpdateAccountTeams(list<AccountTeamMember> lstAccTeams)
    {
        list<Account_Team__c> lstAccountTeams = new list<Account_Team__c>();
      
        for(AccountTeamMember teamMember : lstAccTeams)
        {
            Account_Team__c customTeamMember = new Account_Team__c(TeamMemberRole__c = teamMember.TeamMemberRole, 
                AccountAccessLevel__c = teamMember.AccountAccessLevel,AccountTeamId__c = teamMember.Id,
                Account__c = teamMember.AccountId, User__c = teamMember.UserId);     
            lstAccountTeams.add(customTeamMember); 
        }          
        if(lstAccountTeams.size()>0)
        {
            Schema.SObjectField field =  Account_Team__c.Fields.AccountTeamId__c;
            Database.upsert(lstAccountTeams,field,false);
        }
    }
     
     
     //Method used for deleting data that has been deleted in the parent organization
    public static void DeletesObjects(List<PartnerNetworkRecordConnection> lstObjects)
    {
       Map<string,list<Id>> mpIds = new map<string,list<Id>>();
       string objectName;
       list<Id> ids;
       // loop through all the record connections and segregate the record ids for each object
       for (PartnerNetworkRecordConnection objRecord : lstObjects)
       {
            Id localId = (Id)objRecord.LocalRecordId;
            objectName = localId.getSObjectType().getDescribe().getName();
            if(mpIds.containsKey(objectName))
            {
                 ids = mpIds.get(objectName);
            }
            else
            {
                 ids = new list<Id>();
            }
            ids.add(objRecord.LocalRecordId);
            mpIds.put(objectName, ids);
       }
     
       //delete all records
       List<Id> idsToDelete = new  List<Id>();
       for(list<Id> lstIds : mpIds.values()){
           idsToDelete.addAll(lstIds);    
       }
       database.delete(idsToDelete,false);
    }
    
    //This method is used to populate the email template name/Id used for the DR functionality  
    public static void ManageEmailTemplates(list<EB_EmailTemplate__c>  lstEmailTemplates, boolean isInsert)
    {
        set<Id> emailTemplateIds = new set<Id>();
        set<string> emailTemplateNames = new set<string>();
        
        for(EB_EmailTemplate__c template : lstEmailTemplates)
        {
            if(template.EB_SFEmailTemplateId__c != null && template.ConnectionReceivedId == null)
                emailTemplateIds.add(template.EB_SFEmailTemplateId__c);
            if(template.SFEmailTemplateName__c != null && template.ConnectionReceivedId != null &&  isInsert)
                emailTemplateNames.add(template.SFEmailTemplateName__c);
        }
        if(emailTemplateIds.size()>0)
        { 
            Map<Id,EmailTemplate> templateMap = new  Map<Id,EmailTemplate>
                ([Select Id, DeveloperName from EmailTemplate where Id in :emailTemplateIds]);
            for(EB_EmailTemplate__c template : lstEmailTemplates)
            {
                if(template.EB_SFEmailTemplateId__c != null && template.ConnectionReceivedId == null && templateMap.get(template.EB_SFEmailTemplateId__c) != null)
                {
                    template.SFEmailTemplateName__c = templateMap.get(template.EB_SFEmailTemplateId__c).DeveloperName;
                }
            }
        }
        if(isInsert && emailTemplateNames.size() >0)
        {
            Map<string,Id> templateMap = new  Map<string,Id>();
            List<EmailTemplate> lstTemplates = [Select Id, DeveloperName from EmailTemplate where DeveloperName in :emailTemplateNames];
            for(EmailTemplate template : lstTemplates)
            {
                templateMap.put(template.DeveloperName, template.Id);
            }        
                 
            for(EB_EmailTemplate__c template : lstEmailTemplates)
            {
                if(template.SFEmailTemplateName__c != null  && template.ConnectionReceivedId != null && templateMap.get(template.SFEmailTemplateName__c) != null)
                {
                    template.EB_SFEmailTemplateId__c = (Id)templateMap.get(template.SFEmailTemplateName__c);
                }
            }
        }
    }
     //This method is used to delete the account teams when shadow object is deleted
    public static void DeleteAccountTeams(list<Account_Team__c>  lstAccountTeams)
    {
        set<Id> teamIds = new set<Id>();
        for(Account_Team__c member : lstAccountTeams)
        {
            if(member.AccountTeamId__c !=null)
                teamIds.add(member.AccountTeamId__c);
        }
        list<AccountTeamMember> lstTeams = [select Id from AccountTeamMember where Id in :teamIds];
        delete lstTeams;
    } 
    
    //Create/Update the AccountTeamMember records for the Account Teams 
    public static void CreateUpdateAccTeams(list<Account_Team__c> lstAccountTeam)
    {
        list<AccountTeamMember> lstMemberUpdate = new list<AccountTeamMember>();
        list<AccountTeamMember> lstMemberInsert = new list<AccountTeamMember>();
        map<string,Id> mapTeamMembers = new map<string,Id>();
        map<string,Id> mapAccountTeamMembers = new map<string,Id>();
        
        //loop through each record and separate the account team members where the corresponding Accountteam 
        //already exists or need to be created
        for(Account_Team__c team: lstAccountTeam)
        {
             AccountTeamMember member = new AccountTeamMember(TeamMemberRole = team.TeamMemberRole__c ,
                AccountId = team.Account__c, UserId = team.User__c);
             if(team.AccountTeamId__c != null)
             {
                 member.Id = team.AccountTeamId__c;
                 lstMemberUpdate.add(member);
             }
             else
             {
                 lstMemberInsert.add(member);
                 
                 //create a map of Account and User id combination which will be use to reestablish the relationship
                 //NOTE: Combination of Account and User is unique for each account team member
                 string key = (string)team.Account__c + (string)team.User__c;
                 mapTeamMembers.put(key,team.Id);
             }
        }
        if(lstMemberUpdate.size()>0)
        {
            database.update(lstMemberUpdate,false);
        }
        if(lstMemberInsert.size()>0)
        {
            database.insert(lstMemberInsert,false);    
            for(AccountTeamMember member : lstMemberInsert)
            {
                if(member.Id != null)
                {
                    string key = (string)member.AccountId + (string)member.UserId;
                    mapAccountTeamMembers.put(key,member.Id);
                }
            }
            //Update the team ids
            ExternalSharingHelper.UpdateAccountTeams(mapAccountTeamMembers, mapTeamMembers);
        }
    }

       // Create/Update Case_Article__c shadow objects for CaseArticle
    public static void UpsertCaseArticleShadows(List<CaseArticle> lstCaseArticles){
        List<Case_Article__c> lstCAShadows = new List<Case_Article__c>();
        Map<ID, String> kaIdToURL = new Map<ID, String>();
        
        // get a set of KnowledgeArticleId
        for(CaseArticle c : lstCaseArticles){
            kaIdToURL.put(c.KnowledgeArticleId, '');
        }
        
        // query the lastest version of the article to get the corresponding urlName
        for(KnowledgeArticleVersion k :  [Select KnowledgeArticleId, UrlName From KnowledgeArticleVersion Where KnowledgeArticleId IN: kaIdToURL.keySet() And PublishStatus = 'Online']){
            kaIdToURL.put(k.KnowledgeArticleId, k.UrlName);
        }
        
        for(CaseArticle c : lstCaseArticles){
            lstCAShadows.add(new Case_Article__c(
              CaseArticleID__c = c.Id
              , Case__c = c.CaseId
              , KnowledgeArticleID__c = c.KnowledgeArticleId
              , KnowledgeArticle_URLName__c = kaIdToURL.get(c.KnowledgeArticleId)
            ));
        }
        
        if(lstCAShadows.size() > 0){
            upsert lstCAShadows CaseArticleID__c;
        }
    } 
    
    //Create/Update the CaseArticle records 
    public static void CreateCaseArticle(list<Case_Article__c> lstShadows){
        List<CaseArticle> lstCaInsert = new List<CaseArticle>();
        Map<String, Id> mapUrlToKAID = new Map<String, Id>();
        Map<String, Id> mapShadowJunctions = new Map<String, Id>();
        Map<String, Id> mapActualJunctions = new Map<String, Id>();
        Map<String, String> mapKAID = new Map<String, String>();
        
        // get all unique urlNames
        for(Case_Article__c cas : lstShadows){
            mapUrlToKAID.put(cas.KnowledgeArticle_URLName__c, null);
        }
        
        // query for the latest articles that match the urlName
        for(KnowledgeArticleVersion k : [Select KnowledgeArticleId, UrlName From KnowledgeArticleVersion Where UrlName IN: mapUrlToKAID.keySet() And PublishStatus = 'Online' And Language = 'en_US']){
            mapUrlToKAID.put(k.UrlName, k.KnowledgeArticleId);
        }
        
        //loop through each record and separate those that already exist vs need to be created
        for(Case_Article__c cas: lstShadows){
             CaseArticle newJunction = new CaseArticle(CaseID = cas.Case__c, KnowledgeArticleId = mapUrlToKAID.get(cas.KnowledgeArticle_URLName__c));
             lstCaInsert.add(newJunction);
             
             //create a map of Case and Article id combination which will be use to reestablish the relationship
             String key = (String)cas.Case__c + (String)mapUrlToKAID.get(cas.KnowledgeArticle_URLName__c);
             mapShadowJunctions.put(key, cas.Id);
             mapKAID.put(key, mapUrlToKAID.get(cas.KnowledgeArticle_URLName__c));
        }
        
        if(lstCaInsert.size() > 0){
            List<Database.SaveResult> saveResult = Database.insert(lstCaInsert,false);    
            List<DR_Exception_Log__c> exceptionLogs = new List<DR_Exception_Log__c>();
            
            Integer ProcessedRecords = 0;
            for(Database.saveResult sr : saveResult){
                if(sr.isSuccess()){
                    ProcessedRecords++;
                }
                
                else{
                    for(Database.Error err : sr.getErrors()){
                        DR_Exception_Log__c ex = new DR_Exception_Log__c();
                        ex.Error_Message__c = err.getStatusCode() + ': ' + err.getMessage();
                        ex.Class_Name__c = 'External Sharing Helper';
                        ex.Method_Name__c = 'CreateCaseArticle';
                        ex.Object__c = 'CaseArticle';
                        ex.Additional_Comments__c = 'Error raised while inserting case article : ' + lstCaInsert[ProcessedRecords] + '. Here are the fields that might have caused the issue :'+ err.getFields();
                        exceptionLogs.add(ex);
                    }
                    
                    ProcessedRecords++;
                }
            }
            if(!exceptionLogs.isEmpty())
                insert exceptionLogs;
            
            for(CaseArticle ca : lstCaInsert){
                if(ca.Id != null){
                    String key = (String)ca.CaseID + (String)ca.KnowledgeArticleId;
                    mapActualJunctions.put(key, ca.Id);
                }
            }
            
            //Update the shadow CaseArticleID__c
            List<Case_Article__c> shadowCA = new List<Case_Article__c>();
            for(String key : mapShadowJunctions.keyset()){
                shadowCA.add(new Case_Article__c(
                    Id = mapShadowJunctions.get(key)
                    , CaseArticleID__c = mapActualJunctions.get(key)
                    , KnowledgeArticleID__c = mapKAID.get(key)
                ));
            }
            update shadowCA;
        }
    }
    
    //This method is used to delete the CaseArticle when shadow object is deleted
    public static void DeleteCaseArticleShadows(List<Case_Article__c> lstShadows){
        Set<Id> caseArticleIDs = new Set<Id>();
        
        for(Case_Article__c cas : lstShadows){
            if(cas.CaseArticleID__c != null)
              caseArticleIDs.add(cas.CaseArticleID__c);
        }
        
        List<CaseArticle> lstCaseArticles = [Select ID From CaseArticle Where Id IN: caseArticleIDs];
        delete lstCaseArticles;
    }
    
    //This method is used to create Email messages from shadow object
    public static void CreateEmailMessages(list<Email_Message_Shadow__c>  lstShadows)
    {
         //create EmailMessage record for each receieved Email Message shadow record
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        list<Id> activityIds = new list<Id>(); 
        list<Id> replyToMsg = new list<Id>();
        
        for(Email_Message_Shadow__c msgShadow : lstShadows)
        {
            if(msgShadow.ActivityId__c != null)
            {
                activityIds.add(msgShadow.ActivityId__c);
            }
            if(msgShadow.ReplyToEmailMessageId__c != null)
            {
                replyToMsg.add(msgShadow.ReplyToEmailMessageId__c);
            }
        }
        
        //create the mapping for source and target ids 
        Map<Id,Id> sourceTargetMap = new Map<Id,Id>();
        
        for (PartnerNetworkRecordConnection connection : [SELECT Id, Status, ConnectionId, PartnerRecordId, LocalRecordId 
             FROM PartnerNetworkRecordConnection WHERE PartnerRecordId in :activityIds]) {                 
            if (connection.Status == 'Received')
            {                                                                
                sourceTargetMap.put(connection.PartnerRecordId, connection.LocalRecordId); 
            } 
        } 
       
        for (Email_Message_Shadow__c shadow: [SELECT PartnerRecordId__c, LocalRecordId__c
             FROM Email_Message_Shadow__c WHERE PartnerRecordId__c in :replyToMsg]) {                                                                                
                sourceTargetMap.put(shadow.PartnerRecordId__c, shadow.LocalRecordId__c); 
        } 
        
        for(Email_Message_Shadow__c msgShadow : lstShadows){
            
            EmailMessage msg = new EmailMessage(
                BccAddress = msgShadow.Bcc__c,
                CcAddress = msgShadow.Cc__c,
                FromAddress = msgShadow.FromAddress__c,
                FromName = msgShadow.FromName__c,
                Headers = msgShadow.Email_Headers__c,
                HtmlBody = msgShadow.HtmlBody__c,
                Incoming = msgShadow.Incoming__c,
                MessageDate = msgShadow.MessageDate__c,
                ParentId = msgShadow.ParentId__c,
                Status = msgShadow.Status__c,
                Subject = msgShadow.Subject__c,
                TextBody = msgShadow.TextBody__c,
                ToAddress = msgShadow.To__c
            );
            if(msgShadow.ActivityId__c != null && sourceTargetMap.containsKey(msgShadow.ActivityId__c))
            {
                msg.ActivityId = sourceTargetMap.get(msgShadow.ActivityId__c);
            }
            if(msgShadow.ReplyToEmailMessageId__c != null && sourceTargetMap.containsKey(msgShadow.ReplyToEmailMessageId__c))
            {
                msg.ReplyToEmailMessageId = sourceTargetMap.get(msgShadow.ReplyToEmailMessageId__c);
            }
            emailMessages.add(msg);
        }
        database.insert(emailMessages,false); 
        
        list<Email_Message_Shadow__c> lstShadow = [Select Id, LocalRecordId__c from Email_Message_Shadow__c where Id in: lstShadows];
        for(integer i=0;i<lstShadow.size();i++)
        {
            lstShadow[i].LocalRecordId__c = emailMessages[i].Id;
        }
        database.update(lstShadow,false);
    }

    //Start of Changes for CR 2979290 by ssawhney
    //This method is used to dynamically create/update KB articles from shadow articles 
    public static void CreateUpdateKbArticles(string articleType,list<Knowledge_Article_DR_Mapping__c> fieldMap, List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){

        List<sObject> insertArticles = new List<sObject>();
        List<sObject> updateArticles = new List<sObject>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){

            sObject article = Schema.getGlobalDescribe().get(articleType).newSObject() ;
            for(Knowledge_Article_DR_Mapping__c field : fieldMap)
            {
                article.put(field.Field_Name__c,a.get(field.Generic_Field_Name__c));
            }
            //article.put('IsVisibleInPrm',true);
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.put('id', vID);
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put((string)article.get('UrlName'), a.Id);
            }
        }
        
        List<DR_Exception_Log__c> exceptionLogs = new List<DR_Exception_Log__c>();

        if(updateArticles.size()>0)
        {
            List<Database.SaveResult> saveResult = database.update(updateArticles,false);
            
            Integer ProcessedRecords = 0;
            for(Database.saveResult sr : saveResult){
                if(sr.isSuccess()){
                    ProcessedRecords++;
                }               
                else{
                    for(Database.Error err : sr.getErrors()){
                        DR_Exception_Log__c ex = new DR_Exception_Log__c();
                        ex.Error_Message__c = err.getStatusCode() + ': ' + err.getMessage();
                        ex.Class_Name__c = 'ExternalSharingHelper';
                        ex.Method_Name__c = 'CreateUpdateKbArticles';
                        ex.Object__c = 'Knowledge Article';
                        ex.Additional_Comments__c = 'Error raised while updating knowledge article :' + updateArticles[ProcessedRecords].get('KnowledgeArticleId') + '. Here are the fields that might have caused the issue :'+ err.getFields();
                        exceptionLogs.add(ex);
                    }                  
                    ProcessedRecords++;
                }
            }
        }
        if(insertArticles.size()>0)
        {
            List<Database.SaveResult> saveResult = database.insert(insertArticles,false);
            
            Integer ProcessedRecords = 0;
            for(Database.saveResult sr : saveResult){
                if(sr.isSuccess()){
                    ProcessedRecords++;
                }               
                else{
                    for(Database.Error err : sr.getErrors()){
                        DR_Exception_Log__c ex = new DR_Exception_Log__c();
                        ex.Error_Message__c = err.getStatusCode() + ': ' + err.getMessage();
                        ex.Class_Name__c = 'ExternalSharingHelper';
                        ex.Method_Name__c = 'CreateUpdateKbArticles';
                        ex.Object__c = 'Knowledge Article';
                        ex.Additional_Comments__c = 'Error raised while inserting knowledge article :' + insertArticles[ProcessedRecords].get('UrlName') + '. Here are the fields that might have caused the issue :'+ err.getFields();
                        exceptionLogs.add(ex);
                    }                  
                    ProcessedRecords++;
                }
            }
        }

        if(!exceptionLogs.isEmpty())
            insert exceptionLogs;
        
        if(updateArticles.size() > 0){
            for(sObject a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get((Id)a.get('Id')), true);
            }
        }
        if(insertArticles.size() > 0){
            string articleQuery = 'SELECT KnowledgeArticleId, UrlName FROM ' + articleType + ' WHERE Id =: insertArticles';
            List<sObject> newArticles = Database.query(articleQuery);
            for(sObject a : newArticles){
                KbManagement.PublishingService.publishArticle((Id)a.get('KnowledgeArticleId'), true);
                mapShadowToMaster.put((string)a.get('UrlName'), (Id)a.get('KnowledgeArticleId'));
            }
        }
    }

    //This method is used to fetch the field mappings for KB generic article and different KB articles
    public static map<string,list<Knowledge_Article_DR_Mapping__c>> FetchFieldMappings()
    {
        list<Knowledge_Article_DR_Mapping__c> mapping = Knowledge_Article_DR_Mapping__c.getall().values();
        map<string,list<Knowledge_Article_DR_Mapping__c>> fieldMappingsForArticleTypes = new map<string,list<Knowledge_Article_DR_Mapping__c>>();
        for(Knowledge_Article_DR_Mapping__c fieldMap: mapping)
        {
            list<Knowledge_Article_DR_Mapping__c> lstFieldMaps;
            if(fieldMappingsForArticleTypes.containsKey(fieldMap.Article_Type__c))
            {
                lstFieldMaps = fieldMappingsForArticleTypes.get(fieldMap.Article_Type__c);                
            }
            else
            {    
                lstFieldMaps = new list<Knowledge_Article_DR_Mapping__c>();       
            }
            lstFieldMaps.add(fieldMap);
            fieldMappingsForArticleTypes.put(fieldMap.Article_Type__c, lstFieldMaps);
        }
        return fieldMappingsForArticleTypes;
    }

    public static List<KA_Generic_Article__c> UpsertKbArticleShadow(string articleType, list<Knowledge_Article_DR_Mapping__c> fieldMap, list<sObject> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
      
        for(sObject a : articles)  
        {
            KA_Generic_Article__c shadow = new KA_Generic_Article__c();
            for(Knowledge_Article_DR_Mapping__c field : fieldMap)
            {
                shadow.put(field.Generic_Field_Name__c, a.get(field.Field_Name__c));
            }
            shadow.put('Knowledge_Article_Type__c',articleType);
            shadow.put('Knowledge_Article_ID__c', a.get('KnowledgeArticleId'));
            shadowArticles.add(shadow);
        }
        
        return shadowArticles;
    }
    //End of Changes for CR 2979290 by ssawhney
    
    //Commented by ssawhney on 07/17/2014 for CR 2712153 as this method is no longer used 
    // method to populate Owner_RW__c on the Case object when it is changed, run before insert/update
    /*public static void CaseSetOwnerRW(List<Case> newCases, Map<ID, Case> oldCases, Boolean isUpdate){
        Map<ID, ID> caseToOwnerID = new Map<ID, ID>();
        Map<ID, User> users = new Map<ID, User>();
        Map<ID, Group> queues = new Map<ID, Group>();
        
        // compile a list of cases where the owner has changed
        for(Case c : newCases){
            if(!isUpdate || (oldCases != null && !oldCases.isEmpty() && c.OwnerId != oldCases.get(c.ID).OwnerId) ){
                caseToOwnerID.put(c.ID, c.OwnerId);
            }
        }
        
        // get the users and groups associated with the case owners
        if(!caseToOwnerID.isEmpty()){
            try{
                users = new Map<ID, User>([Select ID, AKAM_User_ID__c From User Where ID IN: caseToOwnerID.values()]);
            }
            catch (Exception e){}
            
            try{
                queues = new Map<ID, Group>([Select ID, DeveloperName From Group Where ID IN: caseToOwnerID.values()]);
            }
            catch (Exception e){}
        }
        
        // set the Owner_RW__c field
        for(Case c : newCases){
            // if ownerID matches a user, prepend with 'User|'
            if(users.containsKey(c.OwnerId)){
                c.Owner_RW__c = 'User|'+users.get(c.OwnerId).AKAM_User_ID__c;
            }
            // if ownerID matches a queue, prepend with 'Queue|'
            else if(queues.containsKey(c.OwnerId)){
                c.Owner_RW__c = 'Queue|'+queues.get(c.OwnerId).DeveloperName;
            }
        }
    }*/
    
    /* Below Methods commented out as not currently in use
    public static void CreateCaseFeed(list<Case_Feed__c> lstCaseFeed)
    {
        list<FeedItem> lstFeedItemInsert = new list<FeedItem>();
        map<String,String> mapCaseFeedItems = new map <String,String>();
        map<String,String> mapFeedItems = new map <String,String>();
        for(Case_Feed__c cf: lstCaseFeed)
        {
            FeedItem fi = new FeedItem(Body = cf.Body__c, ParentId = cf.ParentId__c, LinkURL = cf.LinkURL__c, Title = cf.Title__c, Type = cf.Type__c);
            lstFeedItemInsert.add(fi);
            string key = (string)cf.ParentId__c + (string)cf.InsertedById__c + String.ValueOf(cf.FeedCreatedDate__c);
            mapCaseFeedItems.put(key,cf.Id);
        }
        if(lstFeedItemInsert.size()>0)
        {
            insert lstFeedItemInsert;
            for(FeedItem feedItem : lstFeedItemInsert)
            {
                string key = (string)feedItem.ParentId + (string)feedItem.CreatedById + String.ValueOf(feedItem.CreatedDate);
                mapFeedItems.put(key,feedItem.Id);
            }
            ExternalSharingHelper.UpdateCaseFeedIds(mapFeedItems, mapCaseFeedItems);
        }
    }
    
    //Method to update the Feed Item ids on the shadow objects
    @future
    public static void UpdateCaseFeedIds(map<string,Id> mapFeedItemObject, map<string,Id> mapShadowObject)
    {
        list<Case_Feed__c> lstCaseFeeds = new list<Case_Feed__c>();
        //Update the corresponding Feed Item Id at the shadow object
        for(string key : mapFeedItemObject.keyset())
        {
            Case_Feed__c cf = new Case_Feed__c(Id = mapShadowObject.get(key), CaseFeedId__c = mapFeedItemObject.get(key));
            lstCaseFeeds.add(cf);
        }
        ExternalSharingHelper.isTriggerFutureControl = true;
        update lstCaseFeeds;
    }
    
    public static void DeleteCaseFeeds(List<Case_Feed__c> lstShadowObject)
    {
        List<String> lstParentIds = new list<String>();
        for(Case_Feed__c cf : lstShadowObject)
        {
            if(cf.CaseFeedId__c != null)
            {
                lstParentIds.add(cf.CaseFeedId__c);
            }
        }
        List<FeedItem> feedItemDeletes = [SELECT Id FROM FeedItem WHERE Id IN :lstParentIds];
        if(feedItemDeletes.size() > 0)
        {
            delete feedItemDeletes;
        }
    }
    */
        
    //Commented out by ssawhney for CR 2979290 
    /*
    public static List<KA_Generic_Article__c> UpsertHowToArticleShadow(List<How_To__kav> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(How_To__kav a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'How_To__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Applies_To__c = a.Applies_To__c
                , Description__c = a.Description__c
                , Description_LTA__c = a.Description_LTA__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Procedure__c = a.Procedure__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Review_Every__c = a.Review_Every__c
                , keywords__c = a.Keywords__c
            ));
        }
        
        return shadowArticles;
    } 
    
    public static List<KA_Generic_Article__c> UpsertQnAArticleShadow(List<Question_Answer__kav> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(Question_Answer__kav a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'Question_Answer__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Answer__c = a.Answer__c
                , Answer_LTA__c = a.Answer_LTA__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Question__c = a.Question__c
                , Review_Every__c = a.Review_Every__c
                , keywords__c = a.keywords__c
            )); 
        }
        
        return shadowArticles;
    } 
    
    public static List<KA_Generic_Article__c> UpsertReleaseNoteArticleShadow(List<Release_Notes__kav> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(Release_Notes__kav a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'Release_Notes__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Bug_Fixes__c = a.Bug_Fixes__c
                , Enhancements__c = a.Enhancements__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Release_Date__c = a.Release_Date__c
                , Review_Every__c = a.Review_Every__c
                , What_s_New_LTA__c = a.What_s_New_LTA__c
                , What_s_New__c = a.What_s_New__c
                , keywords__c = a.keywords__c
            )); 
        }
        
        return shadowArticles;
    } 
    
    public static List<KA_Generic_Article__c> UpsertStabilityEngineeringArticleShadow(List<Stability_Engineering_Article__kav> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(Stability_Engineering_Article__kav a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'Stability_Engineering_Article__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Answer__c = a.Answer__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Question__c = a.Question__c
                , Review_Every__c = a.Review_Every__c
            )); 
        }
        
        return shadowArticles;
    }
    
    public static List<KA_Generic_Article__c> UpsertTroubleshootProcedureArticleShadow(List<Troubleshooting_Procedure__kav> articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(Troubleshooting_Procedure__kav a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'Troubleshooting_Procedure__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Applies_To__c = a.Applies_To__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Review_Every__c = a.Review_Every__c
                , Symptoms__c = a.Symptoms__c
                , Symptoms_LTA__c = a.Symptoms_LTA__c
                , Troubleshooting_Guide_LTA__c = a.Troubleshooting_Guide_LTA__c
                , Troubleshooting_Guide__c = a.Troubleshooting_Guide__c
                , keywords__c = a.keywords__c
                , Explanation__c = a.Explanation__c
                , known_issue_url__c = a.known_issue_url__c
            )); 
        }
        
        return shadowArticles;
    }
    
    //added by jay for CR:2789994 created new article type
    
    public static List<KA_Generic_Article__c> UpsertGlossaryDefinitionArticleShadow(List<Glossary_Definition__kav > articles){
        List<KA_Generic_Article__c> shadowArticles = new List<KA_Generic_Article__c>();
        
        for(Glossary_Definition__kav  a : articles){
            shadowArticles.add(new KA_Generic_Article__c(
                Knowledge_Article_ID__c = a.KnowledgeArticleId
                , Knowledge_Article_Type__c = 'Glossary_Definition__kav'
                , Summary__c = a.Summary
                , Title__c = a.Title
                , URL_Name__c = a.UrlName
                , Visibility__c = a.Visibility__c
                , Applies_To__c = a.Applies_To__c
                , Internal_Notes__c = a.Internal_Notes__c
                , term__c = a.term__c
                , keywords__c = a.Keywords__c
                , definition__c = a.definition__c
              )); 
        }
        
        return shadowArticles;
    }

    public static void CreateUpdateHowToArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<How_To__kav> insertArticles = new List<How_To__kav>();
        List<How_To__kav> updateArticles = new List<How_To__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            How_To__kav article = new How_To__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , Applies_To__c = a.Applies_To__c
                , Description__c = a.Description__c
                , Description_LTA__c = a.Description_LTA__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Procedure__c = a.Procedure__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Review_Every__c = a.Review_Every__c
                , keywords__c = a.Keywords__c
                
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }
        
        List<How_To__kav> upsertArticles = new List<How_To__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(How_To__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<How_To__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM How_To__kav WHERE Id =: insertArticles];
            for(How_To__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    
    public static void CreateUpdateQnAArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<Question_Answer__kav> insertArticles = new List<Question_Answer__kav>();
        List<Question_Answer__kav> updateArticles = new List<Question_Answer__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            Question_Answer__kav article = new Question_Answer__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , Answer__c = a.Answer__c
                , Answer_LTA__c = a.Answer_LTA__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Question__c = a.Question__c
                , Review_Every__c = a.Review_Every__c
                , keywords__c = a.Keywords__c
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }
        
        List<Question_Answer__kav> upsertArticles = new List<Question_Answer__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(Question_Answer__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<Question_Answer__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM Question_Answer__kav WHERE Id =: insertArticles];
            for(Question_Answer__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    
    public static void CreateUpdateReleaseNoteArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<Release_Notes__kav> insertArticles = new List<Release_Notes__kav>();
        List<Release_Notes__kav> updateArticles = new List<Release_Notes__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            Release_Notes__kav article = new Release_Notes__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , Bug_Fixes__c = a.Bug_Fixes__c
                , Enhancements__c = a.Enhancements__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Release_Date__c = a.Release_Date__c
                , Review_Every__c = a.Review_Every__c
                , What_s_New_LTA__c = a.What_s_New_LTA__c
                , What_s_New__c = a.What_s_New__c
                , keywords__c = a.Keywords__c
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }
        
        List<Release_Notes__kav> upsertArticles = new List<Release_Notes__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(Release_Notes__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<Release_Notes__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM Release_Notes__kav WHERE Id =: insertArticles];
            for(Release_Notes__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    
    public static void CreateStabilityEngineeringArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<Stability_Engineering_Article__kav> insertArticles = new List<Stability_Engineering_Article__kav>();
        List<Stability_Engineering_Article__kav> updateArticles = new List<Stability_Engineering_Article__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            Stability_Engineering_Article__kav article = new Stability_Engineering_Article__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , Answer__c = a.Answer__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Question__c = a.Question__c
                , Review_Every__c = a.Review_Every__c
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }
        
        List<Stability_Engineering_Article__kav> upsertArticles = new List<Stability_Engineering_Article__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(Stability_Engineering_Article__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<Stability_Engineering_Article__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM Stability_Engineering_Article__kav WHERE Id =: insertArticles];
            for(Stability_Engineering_Article__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    
    public static void CreateTroubleshootingProcedureArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<Troubleshooting_Procedure__kav> insertArticles = new List<Troubleshooting_Procedure__kav>();
        List<Troubleshooting_Procedure__kav> updateArticles = new List<Troubleshooting_Procedure__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            Troubleshooting_Procedure__kav article = new Troubleshooting_Procedure__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , Applies_To__c = a.Applies_To__c
                , Internal_Notes_LTA__c = a.Internal_Notes_LTA__c
                , Internal_Notes__c = a.Internal_Notes__c
                , Last_Review_Date__c = a.Last_Review_Date__c
                , Legacy_ID__c = a.Legacy_ID__c
                , Next_Review_Date__c = a.Next_Review_Date__c
                , Pre_Migration_State__c = a.Pre_Migration_State__c
                , Publishing_Notes__c = a.Publishing_Notes__c
                , Review_Every__c = a.Review_Every__c
                , Symptoms__c = a.Symptoms__c
                , Symptoms_LTA__c = a.Symptoms_LTA__c
                , Troubleshooting_Guide_LTA__c = a.Troubleshooting_Guide_LTA__c
                , Troubleshooting_Guide__c = a.Troubleshooting_Guide__c
                , keywords__c = a.Keywords__c
                , explanation__c = a.Explanation__c
                , known_issue_url__c = a.known_issue_url__c
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }
        
        List<Troubleshooting_Procedure__kav> upsertArticles = new List<Troubleshooting_Procedure__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(Troubleshooting_Procedure__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<Troubleshooting_Procedure__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM Troubleshooting_Procedure__kav WHERE Id =: insertArticles];
            for(Troubleshooting_Procedure__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    
    //new method added by jay for syncing NEW ARTICLE TYPE
    public static void CreateGlossaryDefinitionArticle(List<KA_Generic_Article__c> shadowArticles, Map<String, Id> mapShadowToArticle, Map<String, Id> mapShadowToMaster){
        List<Glossary_Definition__kav> insertArticles = new List<Glossary_Definition__kav>();
        List<Glossary_Definition__kav> updateArticles = new List<Glossary_Definition__kav>();
        
        Map<String, String> versionToKA = new Map<String, String>();
        
        for(KA_Generic_Article__c a : shadowArticles){
            Glossary_Definition__kav article = new Glossary_Definition__kav(
                Summary = a.Summary__c
                , Title = a.Title__c
                , UrlName = a.URL_Name__c
                , IsVisibleInPrm = true
                , Visibility__c = a.Visibility__c
                , internal_notes__C = a.internal_notes__c
                , term__c = a.term__c
                , keywords__c = a.Keywords__c
                , definition__c = a.definition__c
                , Applies_To__c = a.Applies_To__c 
            );
            
            if(a.Knowledge_Article_ID__c != null && a.Knowledge_Article_ID__c != ''){
                ID vID = KbManagement.PublishingService.editOnlineArticle(a.Knowledge_Article_ID__c, false);
                article.id = vID;
                versionToKA.put(vID, a.Knowledge_Article_ID__c);
                updateArticles.add(article);
            }
            else{
                insertArticles.add(article);
                mapShadowToArticle.put(article.UrlName, a.Id);
            }
        }     
	     
        List<Glossary_Definition__kav> upsertArticles = new List<Glossary_Definition__kav>();
        upsertArticles.addAll(updateArticles);
        upsertArticles.addAll(insertArticles);
        upsert upsertArticles;
        
        if(updateArticles.size() > 0){
            for(Glossary_Definition__kav a : updateArticles){
                KbManagement.PublishingService.publishArticle(versionToKA.get(a.id), true);
            }
        }
        if(insertArticles.size() > 0){
            List<Glossary_Definition__kav> newArticles = [SELECT KnowledgeArticleId, UrlName FROM Glossary_Definition__kav WHERE Id =: insertArticles];
            for(Glossary_Definition__kav a : newArticles){
                KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);
                mapShadowToMaster.put(a.UrlName, a.KnowledgeArticleId);
            }
        }
    }
    */

    //Commented by ssawhney on 07/17/2014 for CR 2712153 as this method is no longer used 
    //method used to link the synced records to the correct lookup records 
    /*@future 
    public static void linkObjects(string objectName, SET<Id> lstObjectIds, map<string, string> fieldMap) 
    { 
        //create the query and fetch all the fields for which the lookup fields needs to be updated
        string query = '';
        for(string fieldName : fieldMap.keyset())   
        {
            query = query + fieldName + ' ,';
        }     
        query = 'Select ' + query.removeEnd(',') + ' from ' + objectName + ' where Id in :lstObjectIds';
        //fetch the data from the database for all the read write fields
        list<sObject> lstObjects = Database.query(query);
  
        //create a set of ids for which the corrsponding id in the current org needs to be fetched
        Set<Id> partnerIdSet = new Set<Id>(); 
        for (sObject obj: lstObjects) 
        { 
            for (string fieldName : fieldMap.keyset())
            { 
                if(obj.get(fieldName) != null && obj.get(fieldName) != '')
                {
                    Id partnerId = (Id) obj.get(fieldName);
                    partnerIdSet.add(partnerId); 
                }
            }
        } 
        //create the mapping for source and target ids 
        Map<Id,Id> sourceTargetMap = new Map<Id,Id>(); 
        
        for (PartnerNetworkRecordConnection connection : 
            [SELECT Id, Status, ConnectionId, PartnerRecordId, LocalRecordId 
             FROM PartnerNetworkRecordConnection 
             WHERE PartnerRecordId in :partnerIdSet]) {                 
            if ( connection.Status == 'Sent' || connection.Status == 'Received')
            {                                                                
                sourceTargetMap.put(connection.PartnerRecordId, connection.LocalRecordId); 
            } 
        } 
        
        //update all lookup fields for the object if the corresponding id is found in the source org
        for (sObject obj: lstObjects ) { 
            for (string fieldName : fieldMap.keyset())
            { 
                if(obj.get(fieldName) != null && obj.get(fieldName) != '' )
                {
                    Id sourceId = (Id) obj.get(fieldName);
                    if(sourceTargetMap.get(sourceId) != null)
                    {
                        Id targetId = sourceTargetMap.get(sourceId);
                        obj.put(fieldMap.get(fieldName),targetId);
                    }
                }
            }                                                         
        }                          
        //update the data              
        isTriggerFutureControl = true;        
        database.update(lstObjects); 
    }            
    
    //Method used to filter the recordIds for the object and also fetch the field mappings
    public static set<Id> filterRecordIds(string objectName, boolean IsUpdate, list<sObject> lstNew, Map<Id, sObject> oldMap) 
    { 
        Set<Id> objectIds = new Set<Id>();
        if(UserInfo.getName().equalsIgnoreCase('Connection User') || system.Test.isRunningTest())
        {
            if(mpFields.size() > 0)
                 mpFields = new map<string, string>();
            
            //fetch the lookup mappings and store in a map
            list<Object_Lookup_Sync__c> lstFields = [Select RW_Field_Name__c, Lookup_Field_Name__c from Object_Lookup_Sync__c
                                                    where Object_Name__c = :objectName and User_Lookup__c = false];
            if(lstFields.size() > 0)
            {
                for(Object_Lookup_Sync__c field : lstFields)
                {
                    mpFields.put(field.RW_Field_Name__c, field.Lookup_Field_Name__c); 
                }
                
                //check if any updates has been made to any of the fields and add them to the set
                for (sObject obj : lstNew)
                {
                    Id objId = (Id)obj.get('Id');
                    for (string fieldName : mpFields.keyset())
                    {
                        if((!IsUpdate && obj.get(fieldName) != null && obj.get(fieldName) != '') ||
                        (IsUpdate && (oldMap.get(objId)).get(fieldName) != obj.get(fieldName)))
                        {
                            objectIds.add(objId);
                            break;
                        }
                    }
                }
            }
        }    
        return objectIds;
    }   */
}