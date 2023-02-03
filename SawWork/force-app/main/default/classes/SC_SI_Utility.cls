/*---------------------------------------------------------------------------------
Class name          :   SC_SI_Utility
Test Class          :   SC_SI_AllUseCase_TC
Author              :   Vishnu Sharma / Himanshu / Sheena / Vamsee
Created             :   05-Jul-20
JIRA                :   ESESP-3015
Purpose             :   Utility Class for SI Functionality

Last Modified         Developer                           Purpose            
============= ========================         			  ==========
24-Aug-2020     Vishnu Sharma  / Himanshu                 Initial Version
* --------------------------------------------------------------------------------*/
public class SC_SI_Utility {
    
    // For Recursive Check
    public static Boolean impAccRecursiveCheck = true;
    public static Boolean impProdRecursiveCheck = true;
    // To bypass before delete validation when Impacted Account and Case Product are added from Case to SI
    public static Boolean byPassImpAccTrigger = false;
    public static Boolean byPassImpProdTrigger = false;
    
    // Method - 1 : Assigning Permission Set for both IRAPT and Non-IRAPT users
    // Called from UserTrigger_ai 
    Public Static void AssignPermissionSet(List<Id> iraptUserIdList, List<Id> nonIraptUserIdList, Boolean isUpdate){
        
        //Permission Set Ids
        Id iraptPSId, nonIraptPSId;
        
        //Queue Ids
        Id incidentQueueId, transitionQueueId;
        
        //Get the License details
        Map<Id, String> userIdLicenseMap = new  Map<Id, String>();
        
        For(User eachUser : [SELECT Id, profile.UserLicense.name FROM User WHERE Id in :iraptUserIdList OR Id in :nonIraptUserIdList]){
            userIdLicenseMap.put(eachUser.Id, eachUser.profile.UserLicense.name);
        }
        
        //Get the IDs stored in Custom MetaData
        for(SC_SI_Service_Incident_Utility__mdt eachmdt : [SELECT DeveloperName, Value__c FROM SC_SI_Service_Incident_Utility__mdt 
                                                           WHERE DeveloperName IN ('non_IRAPT_Permission_Set','IRAPT_Permission_Set','Incident_Queue','Transition_Queue')]){
                                                               if(eachmdt.DeveloperName == 'non_IRAPT_Permission_Set')
                                                                   nonIraptPSId = eachmdt.Value__c;
                                                               else if(eachmdt.DeveloperName == 'IRAPT_Permission_Set')
                                                                   iraptPSId =  eachmdt.Value__c;
                                                               else if(eachmdt.DeveloperName == 'Incident_Queue')
                                                                   incidentQueueId =  eachmdt.Value__c;
                                                               else if(eachmdt.DeveloperName == 'Transition_Queue')
                                                                   transitionQueueId =  eachmdt.Value__c;
                                                               
                                                           }
        
        //List to Insert Permission Set assignments
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        
        //List to Insert Group Member Records
        List<GroupMember> groupMemberList = new List<GroupMember>();
        
        PermissionSetAssignment eachPsa;
        GroupMember eachGroupMember;
        
        // Logic for IRAPT Users
        if(iraptUserIdList.size() > 0){
            
            for(Id eachId :iraptUserIdList){
                if(userIdLicenseMap.get(eachId) == 'Salesforce' || userIdLicenseMap.get(eachId) == 'Salesforce Platform'){
                    //Assign Permission Set
                    eachPsa = new PermissionSetAssignment();
                    eachPsa.AssigneeId = eachId;
                    eachPsa.PermissionSetId = iraptPSId;
                    psaList.add(eachPsa);
                    
                    //Add Users to the Incident Queue
                    eachGroupMember = new GroupMember();
                    eachGroupMember.UserOrGroupId = eachId;
                    eachGroupMember.GroupId = incidentQueueId;
                    groupMemberList.add(eachGroupMember);
                    
                    //Add Users to the Transition Queue
                    eachGroupMember = new GroupMember();
                    eachGroupMember.UserOrGroupId = eachId;
                    eachGroupMember.GroupId = transitionQueueId;
                    groupMemberList.add(eachGroupMember);
                }
                
                
            }
        }
        
        // Logic for Non IRAPT Users
        if(nonIraptUserIdList.size() > 0){
            
            for(Id eachId :nonIraptUserIdList){
                if(userIdLicenseMap.get(eachId) == 'Salesforce' || userIdLicenseMap.get(eachId) == 'Salesforce Platform'){
                    eachPsa = new PermissionSetAssignment();
                    eachPsa.AssigneeId = eachId;
                    eachPsa.PermissionSetId = nonIraptPSId;
                    psaList.add(eachPsa);
                }
            }
        }
        
        if(psaList.size() > 0)
            Insert psaList;
        
        if(groupMemberList.size() > 0)
            Insert groupMemberList;
        
        
        //To remove the earlier assigned permission set & Queue Membership
        if(isUpdate){
            List<PermissionSetAssignment> psaListForDelete =  [SELECT Id FROM PermissionSetAssignment WHERE (AssigneeId In :iraptUserIdList AND PermissionSetId =: nonIraptPSId) OR 
                                                               (AssigneeId In : nonIraptUserIdList AND PermissionSetId =:iraptPSId)];
            
            List<GroupMember> groupMemberListForDelete =  [SELECT Id FROM GroupMember WHERE (UserOrGroupId In :nonIraptUserIdList) AND (GroupId =:incidentQueueId OR GroupId =:transitionQueueId)];
            
            if(psaListForDelete.size() > 0)
                Delete psaListForDelete;
            
            if(groupMemberListForDelete.size() > 0)
                Delete groupMemberListForDelete;
            
        }
        
        
    }
    
    
    
    // Method - 2 :Impacted Account functionality for SI records - Creation and deletion of Impacted Accounts based on the linked Case
    // Called from - Casetrigger_ai
    public static void UpdateImpactedAccountsonSI(List<Case> lNewCases,Map<Id,Case> oldMap,Boolean isInsert)
    {
        SC_SI_Impacted_Account__c  SIAcc;
        List<SC_SI_Impacted_Account__c> lSIAccounts = new List<SC_SI_Impacted_Account__c>();
        List<Case> lNewSICases = new List<Case>();
        
        //List of Old SI Ids on Updated Cases
        List<Id> lOldSIIds = new List<Id>();
        //List of Cases which should be processed to delete Acc on SI
        List<case> lDeleteCases = new List<case>();
        // Map of Unique Id(Service Incident Id and Account Id) and Impacted Account
        Map<String,SC_SI_Impacted_Account__c > mSI_ImpAcc = new Map<String,SC_SI_Impacted_Account__c >();
        // Map of Unique Id(Service Incident Id and Account Id) and Cases
        Map<String,List<Case>> mSI_Cases = new Map<String,List<Case>>();
        // Impacted Accounts to be deleted
        List<SC_SI_Impacted_Account__c > lDeleteImpAccts;
        Set<SC_SI_Impacted_Account__c > setDeleteImpAccts = new Set<SC_SI_Impacted_Account__c >();
        //Set to add unique String of Service Incident. and Impacted Account
        Set<String> siUniqueFields = new  Set<String>();
        
        for(Case c: lNewCases)
        {
            // Filter Cases for which Impacted Account will be inserted  
            if(c.Service_Incident__c  != null && c.AccountId != null &&
               ((isInsert) || (!isInsert && (c.Service_Incident__c  != oldMap.get(c.Id).Service_Incident__c || c.AccountId != oldMap.get(c.Id).AccountId
                                             || c.Work_Type__c != oldMap.get(c.Id).Work_Type__c))))
            {
                lNewSICases.add(c);
            }
            
            //To delete impacted accounts which is auto created and is not tied by any Case
            //If Account is changed on Case, delete account on old SI
            //If SI# no is changed on Case, delete account on old SI   
            if(!isInsert && oldMap.get(c.Id).AccountId!=null && 
               oldMap.get(c.Id).Service_Incident__c  !=null &&
               (c.AccountId!=oldMap.get(c.Id).AccountId || oldMap.get(c.Id).Service_Incident__c  != c.Service_Incident__c
               ))
            {
                
                lOldSIIds.add(oldMap.get(c.Id).Service_Incident__c );
                lDeleteCases.add(c); 
            }
        }
        
        if(!isInsert)
        { 
            if(lOldSIIds.size()>0)
            {
                //Create Map of Old SI Ids and Impacted Accounts
                for(SC_SI_Impacted_Account__c  SI_acc : [Select Id,Service_Incident__c ,Account_Name__c  from SC_SI_Impacted_Account__c  where 
                                                         Service_Incident__c  IN:lOldSIIds and Auto_Created_Record__c =true])
                {
                    mSI_ImpAcc.put(SI_acc.Service_Incident__c+'##'+SI_acc.Account_Name__c ,SI_acc);
                }
                for(Case SI_c : [Select Id,Service_Incident__c ,RecordTypeId,RecordType.Name,AccountId,Work_Type__c from Case where Service_Incident__c  IN: lOldSIIds])
                {
                    if(SI_c.Service_Incident__c  != null && SI_c.AccountId != null)
                    {               
                        if(!mSI_Cases.containsKey(SI_c.Service_Incident__c +'##'+SI_c.AccountId))                
                            mSI_Cases.put(SI_c.Service_Incident__c +'##'+SI_c.AccountId,new List<Case>());
                        (mSI_Cases.get(SI_c.Service_Incident__c +'##'+SI_c.AccountId)).add(SI_c);
                    }
                }
                
                
                //Iterating through cases which should be considered for their account deletion
                for(Case c: lDeleteCases)
                {
                    if(mSI_ImpAcc.containsKey(oldMap.get(c.Id).Service_Incident__c +'##'+oldMap.get(c.Id).AccountId)
                       && !mSI_Cases.containsKey(oldMap.get(c.Id).Service_Incident__c +'##'+oldMap.get(c.Id).AccountId)
                      )
                    {
                        setDeleteImpAccts.add(mSI_ImpAcc.get(oldMap.get(c.Id).Service_Incident__c +'##'+oldMap.get(c.Id).AccountId));             
                    }    
                }
                
                if(setDeleteImpAccts.size()>0)
                {
                    lDeleteImpAccts = new List<SC_SI_Impacted_Account__c >(setDeleteImpAccts);
                    byPassImpAccTrigger = true;
                    delete lDeleteImpAccts;
                    byPassImpAccTrigger = false;
                }
            }
        }
        
        if(lNewSICases.size() > 0)
        {
            for(Case c: lNewSICases){
                SIAcc = new SC_SI_Impacted_Account__c(SC_SI_Unique_field__c=c.Service_Incident__c + '-' + c.AccountId);
                SIAcc.Account_Name__c = c.AccountId;
                SIAcc.Service_Incident__c = c.Service_Incident__c ;
                SIAcc.Auto_Created_Record__c  = true;
                SIAcc.Validation_Override__c = true;
                SIAcc.From_Proactive_Case__c = c.Work_Type__c == 'Proactive' ? true : false;
                // For Duplicate SC_SI_Unique_field__c values
                if(!siUniqueFields.contains(SIAcc.SC_SI_Unique_field__c)){
                    lSIAccounts.add(SIAcc);
                    siUniqueFields.add(c.Service_Incident__c + '-' + c.AccountId);
                }
            }
            if(lSIAccounts.size() > 0)
            {
                try{
                    upsert lSIAccounts SC_SI_Unique_field__c;
                }
                catch(DmlException ex)
                {
                    if(ex.getDmlStatusCode(0)!='FIELD_CUSTOM_VALIDATION_EXCEPTION') 
                        lNewSICases[0].Service_Incident__c .AddError(ex);
                }
            }
        }
        impAccRecursiveCheck=false;
    }
    
    // Method - 3 : Case Product functionality for SI records - Creation and deletion of Case Products based on the linked Case
    // Called from - Casetrigger_ai
    public static void UpdateCaseProductsonSI(List<Case> lNewCases,Map<Id,Case> oldMap,Boolean isInsert)
    {
        SC_SI_Impacted_Product__c  SIProd;
        List<SC_SI_Impacted_Product__c> lSIImpProds = new List<SC_SI_Impacted_Product__c>();
        List<Case> lNewSICases = new List<Case>();
        
        
        //List of Old SI Ids on Updated Cases
        List<Id> lOldSIIds = new List<Id>();
        //List of Cases which should be processed to delete Impacted Product on SI
        List<case> lDeleteCases = new List<case>();
        //Map of Unique Id (SI Id and Account Id) and Impacted Product
        Map<String,SC_SI_Impacted_Product__c > mSI_Prod = new Map<String,SC_SI_Impacted_Product__c >();
        // Map of Unique Id (SI Id and Case Product Name) and Cases 
        Map<String,List<Case>> mSI_Cases = new Map<String,List<Case>>();
        // Products to be deleted
        List<SC_SI_Impacted_Product__c > lDeleteImpProds;
        Set<SC_SI_Impacted_Product__c > setDeleteImpProds = new Set<SC_SI_Impacted_Product__c >();      
        
        for(Case c: [Select Id,RecordTypeId,Service_Incident__c,Case_Product__c, Case_Product__r.Name  from Case where id =: lNewCases])
        {
            
            if(c.Service_Incident__c  != null && c.Case_Product__c  != null &&
               ((isInsert) || (!isInsert && (c.Service_Incident__c  != oldMap.get(c.Id).Service_Incident__c || c.Case_Product__c  != oldMap.get(c.Id).Case_Product__c))))
            {
                lNewSICases.add(c);
            }
            
            if(!isInsert && oldMap.get(c.Id).Case_Product__c !=null && 
               oldMap.get(c.Id).Service_Incident__c  !=null &&
               (c.Case_Product__c !=oldMap.get(c.Id).Case_Product__c  || oldMap.get(c.Id).Service_Incident__c  != c.Service_Incident__c
               ))
            {
                //To delete Impacted Products which is auto created and is not tied by any Case
                //If Case Product is changed on Case, delete Impacted Product on old SI
                //If SI# no is changed on Case, delete Impacted Product on old SI        
                lOldSIIds.add(oldMap.get(c.Id).Service_Incident__c );
                lDeleteCases.add(c); 
            }
        }
        
        if(!isInsert)
        { 
            if(lOldSIIds.size()>0)
            {
                //Create Map of Old SI Ids and Impacted Products
                for(SC_SI_Impacted_Product__c   SI_ImpProd : [Select Id,Service_Incident__c  ,Product__c   from SC_SI_Impacted_Product__c  where 
                                                              Service_Incident__c  IN:lOldSIIds and Auto_Created_Record__c =true])
                {
                    mSI_Prod.put(SI_ImpProd.Service_Incident__c+'##'+SI_ImpProd.Product__c, SI_ImpProd);
                }
                for(Case SI_c : [Select Id,Service_Incident__c ,Case_Product__c,Case_Product__r.Name from Case where Service_Incident__c  IN: lOldSIIds])
                {
                    if(SI_c.Service_Incident__c  != null && SI_c.Case_Product__c != null)
                    {               
                        if(!mSI_Cases.containsKey(SI_c.Service_Incident__c +'##'+SI_c.Case_Product__r.Name))                
                            mSI_Cases.put(SI_c.Service_Incident__c +'##'+SI_c.Case_Product__r.Name,new List<Case>());
                        (mSI_Cases.get(SI_c.Service_Incident__c +'##'+SI_c.Case_Product__r.Name)).add(SI_c);
                    }
                }
                
                Map<Id,String> dupOldMap = new Map<Id,String>();
                for(Case oldCase: oldMap.Values()){
                    dupOldMap.put(oldCase.Case_Product__c, oldCase.Id);
                }
                
                List<EB_AccountProductMap__c > lCaseProds = new List<EB_AccountProductMap__c >();
                lCaseProds = [Select Id, Name from EB_AccountProductMap__c where Id =: dupOldMap.keySet()];
                
                Map<Id,String> dupOldMap2 = new Map<Id,String>();
                for(EB_AccountProductMap__c eachProd: lCaseProds){
                    dupOldMap2.put(eachProd.Id, eachProd.Name);
                }
                
                
                //Iterating through cases which should be considered for their Product deletion
                for(Case c: lDeleteCases)
                {
                    if(mSI_Prod.containsKey(oldMap.get(c.Id).Service_Incident__c +'##'+dupOldMap2.get(oldMap.get(c.Id).Case_Product__c))
                       && !mSI_Cases.containsKey(oldMap.get(c.Id).Service_Incident__c +'##'+dupOldMap2.get(oldMap.get(c.Id).Case_Product__c))
                      )
                    {
                        setDeleteImpProds.add(mSI_Prod.get(oldMap.get(c.Id).Service_Incident__c +'##'+dupOldMap2.get(oldMap.get(c.Id).Case_Product__c)));             
                    }    
                }
            }
            
            
            if(setDeleteImpProds.size()>0)
            {
                lDeleteImpProds = new List<SC_SI_Impacted_Product__c >(setDeleteImpProds);
                byPassImpProdTrigger = true;
                delete lDeleteImpProds;
                byPassImpProdTrigger = false;
            }
        }
        
        if(lNewSICases.size() > 0)
        {
            Map<String,Id> mCaseProdNames = new  Map<String,Id>();
            Map<String,List<String>> mExistingCaseProdNames = new  Map<String,List<String>>();
            List<EB_Product__c> productList = new List<EB_Product__c>();
            List<SC_SI_Impacted_Product__c>   SI_Imp_Prod = new  List<SC_SI_Impacted_Product__c>();
            
            productList = [Select Id,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where  EB_ProductType__c = 'Product' and EB_ProductId__c!=''];
            
            for(EB_Product__c ebProd: productList){
                mCaseProdNames.put(ebProd.Product_Name__c,ebProd.Id);
            }
            
            SI_Imp_Prod =  [Select Id,Service_Incident__c  ,ParentProductName__c, Product__c from SC_SI_Impacted_Product__c  where Service_Incident__c!=null and Product__c != '' and ParentModuleName__c='' and SubModuleName__c=''];
            
            for(SC_SI_Impacted_Product__c eachImpProd: SI_Imp_Prod){
                if(!mExistingCaseProdNames.containsKey(eachImpProd.Service_Incident__c)){
                    mExistingCaseProdNames.put(eachImpProd.Service_Incident__c, new List<String>());  
                }
                mExistingCaseProdNames.get(eachImpProd.Service_Incident__c).add(eachImpProd.Product__c);
            }
            
            for(Case c: lNewSICases){
                if((mExistingCaseProdNames.containsKey(c.Service_Incident__c) && !mExistingCaseProdNames.get(c.Service_Incident__c).contains(c.Case_Product__r.Name))
                   || !mExistingCaseProdNames.containsKey(c.Service_Incident__c)){
                       SIProd = new SC_SI_Impacted_Product__c ();
                       SIProd.Service_Incident__c = c.Service_Incident__c ;
                       SIProd.Auto_Created_Record__c  = true;
                       SIProd.Validation_Override__c = true;
                       
                       if(mCaseProdNames.containsKey(c.Case_Product__r.Name)){
                           SIProd.ParentProductName__c=c.Case_Product__r.Name;
                           SIProd.Product_Name__c = mCaseProdNames.get(c.Case_Product__r.Name);
                       }
                       else{
                           SIProd.Case_Product__c = c.Case_Product__r.Name;
                       }
                       lSIImpProds.add(SIProd);
                   }
                
            }
            if(lSIImpProds.size() > 0)
            {
                try{
                    insert lSIImpProds;
                }
                catch(DmlException ex)
                {
                    if(ex.getDmlStatusCode(0)!='FIELD_CUSTOM_VALIDATION_EXCEPTION') 
                        lNewSICases[0].Service_Incident__c .AddError(ex);
                }
            }
        }
        impProdRecursiveCheck=false;
    } 
    
    // Method - 4 : Validation for Business Executive
    // Called from EmailMessageTrigger
    Public static void EmailBusinessExecValidation(List<EmailMessage> emailMessageList){
        
        SC_SI_Email_Config__c emailConfig = [SELECT To_Email_Address__c, CC_Email_Address__c, BCC_Email_Address__c FROM SC_SI_Email_Config__c LIMIT 1];
        Set<String> businesExecEmail = new Set<String>();
        Set<String> emailRecipients;
        
        if(emailConfig.To_Email_Address__c != null)
            businesExecEmail.addAll((emailConfig.To_Email_Address__c.toLowerCase()).Split(','));
        if(emailConfig.CC_Email_Address__c != null)
            businesExecEmail.addAll((emailConfig.CC_Email_Address__c.toLowerCase()).Split(','));
        if(emailConfig.BCC_Email_Address__c != null)
            businesExecEmail.addAll((emailConfig.BCC_Email_Address__c.toLowerCase()).Split(','));
        
        For(EmailMessage eachEmail : emailMessageList){
            emailRecipients = new Set<String>();
            if(eachEmail.ToAddress != null)
                emailRecipients.addAll((eachEmail.ToAddress.toLowerCase()).Split(';'));
            if(eachEmail.CcAddress != null)
                emailRecipients.addAll((eachEmail.CcAddress.toLowerCase()).Split(';'));
            if(eachEmail.BccAddress != null)
                emailRecipients.addAll((eachEmail.BccAddress.toLowerCase()).Split(';'));
            
            if(businesExecEmail.removeall(emailRecipients))
                eachEmail.addError('You are not Authorized to send email to Business Executives');
        }
    }
    
    // lookup search results method (Called from SC_SI_LookupComponent lightning comp.)
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord , String ObjectName) 
    {
        String searchKey = searchKeyWord + '%';
        
        // List < sObject > returnList = new List < sObject > ();
        
        String sQuery;
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
        
        if(ObjectName == 'User')
        {
            sQuery =  'SELECT Id, Name FROM User WHERE Name LIKE: searchKey ' 
                + 'AND SC_SI_IRAPT_User__c = TRUE order by Name ASC limit 5'; 
        }
        else
        {
            sQuery =  'select id, Name from ' + ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        }
        return Database.query(sQuery);
    }
    
    //method used for fetching Email Message data (Called from SC_SI_EmailRelatedList comp)
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getEmailRelatedListData(Id serviceIncidentId){
        
        return[Select Id,Status,Incoming,Subject,ToAddress,FromAddress,MessageDate from EmailMessage Where RelatedToId =: serviceIncidentId order by MessageDate desc limit 50000];
    }
    
    
    // Code for Page Redirection
    public String currentRecordId{get;set;}
    public BMCServiceDesk__Incident__c currentRecord{get;set;}
    
    public SC_SI_Utility(ApexPages.StandardController controller) {}
    
    //Method used to redirection in classic behaviour (Called from SC_SI_RedirectionPage VF page)
    public pagereference Redirect()
    {
        
        String recId = ApexPages.currentPage().getparameters().get('id'); 
        String rediretToURL;
        BMCServiceDesk__Incident__c currentRecord = [select id ,recordType.Name from BMCServiceDesk__Incident__c where id =: recId ];
        if(currentRecord.recordType.Name == 'Service Incident'){
            recId = recId + '%';
            List<SC_SI_Service_Incident__c> SIRec= [Select Id from SC_SI_Service_Incident__c where SC_SI_Old_Incident_Id__c LIKE :recId]; 
            rediretToURL = '/lightning/r/SC_SI_Service_Incident__c/'+SIRec[0].Id+'/view';
            
        }else{
            rediretToURL = '/'+recId+'?nooverride=1';
        }
        pagereference pageref = new pagereference(rediretToURL);
        pageref.setredirect(true);
        return pageref;
        
    }
    
    //Method used to redirection in lightning behaviour (Called from SC_SI_RedirectionComponent lightning comp)
    @auraEnabled(cacheable=true)
    public static wrapperClass lightningRedirectionController(Id recordId)
    {
        wrapperClass sampleWrapper = new wrapperClass();
        List<SC_SI_Service_Incident__c> SIRec = new List<SC_SI_Service_Incident__c>();
        sampleWrapper.recordTypeName = [Select Id,recordType.Name from BMCServiceDesk__Incident__c where Id=:recordId].recordType.Name;
        SIRec= [Select Id from SC_SI_Service_Incident__c where SC_SI_Old_Incident_Id__c=:recordId];
        if(SIRec.size() >0){
            sampleWrapper.SIId = SIRec[0].Id;
        }    
        
        return sampleWrapper;
    } 

    //Method for apex link - SC_SI_ServiceIncident
    public String inciName { get; set; }
    public String IncidentId { get; set; }
    public Boolean getShowDetails()
    {
         try
         {
            //Start of changes for CR 2026918 by ssawhney
            string query = '';
            //list<BMCServiceDesk__Incident__c> lstIncidents;
            list<sObject> lstIncidents;
            
            //Get the Id form the URL
            inciName= ApexPages.CurrentPage().getParameters().get('Id');
            
            if(inciName!=null)
            {
                 //First search happens on the Old SI number and then on the new one
                 query = 'select Id,Name from BMCServiceDesk__Incident__c where SI_SD_Dashboard_Incident__c like \'%' + inciName + '%\'';
                 lstIncidents = Database.query(query);
 
                 if(lstIncidents.size() == 0)
                 {
                    
                     if(!inciName.contains('SI-'))
                         query = 'select Id,Name from BMCServiceDesk__Incident__c where Name like \'%' + inciName + '%\'';
                     else
                         query = 'select Id,Name from SC_SI_Service_Incident__c where Name like \'%' + inciName + '%\'';
                     lstIncidents = Database.query(query);
                 }
            }
            else
            {
                //SDSI will only search for the old SI number
                inciName= ApexPages.CurrentPage().getParameters().get('SDSI');
                if(inciName!=null && lstIncidents == null)
                {
                     query = 'select Id,Name from BMCServiceDesk__Incident__c where SI_SD_Dashboard_Incident__c like \'%' + inciName + '%\'';
                     lstIncidents = Database.query(query);
     
                }
                else
                {
                    //SI will only search on the new incident numbers
                    inciName= ApexPages.CurrentPage().getParameters().get('SI');
                    if(inciName!=null && lstIncidents == null)
                    {
                         query = 'select Id,Name from BMCServiceDesk__Incident__c where Name like \'%' + inciName + '%\'';
                         lstIncidents = Database.query(query);
                     }
                }
             }
             
             if(lstIncidents == null || lstIncidents.size() == 0)
             {
                 return false;
             }
             else
             {
                 //Navigate to the service incident if only one SI is found
                 if(lstIncidents.size() == 1)
                     IncidentID = lstIncidents[0].Id;
                 return true;
             }
             //End of Changes for CR 2026918 by ssawhney
         }
         catch (exception ex)
         {
             return true;
         }
      //   return true;
    }
    //Method for apex link - SC_SI_ServiceIncident
    public String getGetLocation() {
        getShowDetails();
        if(IncidentID!=null)
         return '/'+IncidentID;
         else
         return '';
     }

    public SC_SI_Utility(){} 
    
    public class wrapperClass{
        @auraEnabled
        public String recordTypeName;
        @auraEnabled
        public Id SIId;
        
        
    } 
    
}