/*
Author          : Pinkesh / Sumukh SS
Description     : Apex Controller for SOCC Car RunBooks
Test Class      : 

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh 								SOCC CAR 2 - RunBooks 
18 Feb 2021			Tejaswini 					ESESP-4825		Runbooks Phase II: Sprint 1 - Changes on S-H 
------------------------------------------------------------------------------------------------------------------
*/

public class SC_SOCC_RUN_BOOK 
{
    public static boolean getUserAccessToEditRecord(set<Id> AccountIds)
    {
        List<SC_SOC_Passphrase_Access__mdt> lSOCPDAccess = [Select id, Account_Team_Role__c, Profile_ID_Text__c, User_Title_text__c from SC_SOC_Passphrase_Access__mdt where DeveloperName like 'Runbook_Access%']; 
        Boolean hasAccess = false;
        
        if(lSOCPDAccess != null)
        {
            //Map of valid account team role
            Map<Id, String> sValidAccTeamRoleMap = new Map<Id, String>();
            //Always store 18 digit profile ids in the metadata
            String lProfileId = '';
            //List of User titles with access
            List<String> lValidUserTitle = new List<String>();
            //List of account team roles with access
            List<String> lstmetadataroles = new List<String>();
            
            for(SC_SOC_Passphrase_Access__mdt eachrec : lSOCPDAccess){
                if(String.isNotBlank(eachrec.Profile_ID_Text__c))
                    lProfileId += eachrec.Profile_ID_Text__c + ',';
                if(String.isNotBlank(eachrec.User_Title_text__c))
                    lValidUserTitle.addAll(eachrec.User_Title_text__c.split(','));
                if(String.isNotBlank(eachrec.Account_Team_Role__c))
                    lstmetadataroles.addAll(eachrec.Account_Team_Role__c.split(','));
            }
            
            //Check if the logged in User has the "profile" specified in the custom metadata
            if(lProfileId.contains(UserInfo.getProfileId()))
                hasAccess = true;
            
            if(!hasAccess){
                //Current logged-in user record
                User user = [SELECT Id, ProfileId, Title FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
                
                //Check if logged user has specified User title
                for(String eachTitle : lValidUserTitle){
                    if(eachTitle.equalsIgnoreCase(user.Title)){
                        hasAccess = true;
                        break;
                    }
                }
            }
            
            if(!hasAccess){
                if(AccountIds != null){
                    List<AccountTeamMember> lValidAccTeamMem = [SELECT Id, AccountID, Title, TeamMemberRole FROM AccountTeamMember where AccountID IN :AccountIds and UserId = :UserInfo.getUserId()]; 
                    for(AccountTeamMember eachrec : lValidAccTeamMem)
                    {
                        sValidAccTeamRoleMap.put(eachrec.AccountID, eachrec.TeamMemberRole);
                    }
                    //List<String> lstmetadataroles = lSOCPDAccess.Account_Team_Role__c.split(',');
                    for(id i:AccountIds)
                    {
                        if(sValidAccTeamRoleMap != null && sValidAccTeamRoleMap.keySet().size() > 0)
                        {
                            for(string eachrole : lstmetadataroles)
                            {
                                if(sValidAccTeamRoleMap.get(i)==eachrole){
                                    hasAccess=true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        return hasAccess;
    }
    
    
    @AuraEnabled
    public static List<SC_SOCC_Situation_to_Handler_Mapping__c> getSituationToHandlerMappings(Id pdId)
    {
        return [Select Id,Situation__r.Name, Handler__r.Name,Handler__c,CreatedBy.Name,CreatedDate, Policy_Domain__c from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =: pdId];
    }
    
    @AuraEnabled
    public static String getLightningBaseURL(){
        SC_Utility__mdt scUtility = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = TRUE AND DeveloperName = 'Lightning_Base_URL' limit 1];
        return scUtility.Value_Text__c;
    }
    
    @AuraEnabled
    public static String getCommunityContactURL(){
        SC_Utility__mdt scUtility = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = TRUE AND DeveloperName = 'SOCC_Communtiy_Luna_URL' limit 1];
        return scUtility.Value_Text__c;
    }
    
    //To get List of situations based on policy domain product & additional products
    @AuraEnabled
    public static List<SC_SOCC_Situation_Catalog__c> getSituationsforPD(Id pdId)
    {
        List<String> SituationsforPD = new List<String>();
        Policy_Domain__c PD = [Select Product__c,Additional_Product__c from Policy_Domain__c where Id =:pdId limit 1];
        
        //Create Product Set
        Set<String> ProductSet = new Set<String>();
        ProductSet.add(PD.Product__c);
        if(PD.Additional_Product__c!=null)
        {
            ProductSet.addAll(PD.Additional_Product__c.split(';'));
        }
        //Changes by Tejaswini for ESESP-4825
        //Get situation to handler mapping list for PD
        List<SC_SOCC_Situation_to_Handler_Mapping__c> lS2HMapping = [Select Id, Name,  Policy_Domain__c, Handler__c, Situation__c FROM SC_SOCC_Situation_to_Handler_Mapping__c Where Policy_Domain__c=:pdId];
        List<Id> lSituationId=new List<Id>();
        for(SC_SOCC_Situation_to_Handler_Mapping__c s2h:lS2HMapping)
        {
            lSituationId.add(s2h.Situation__c);
            
        }
        //Get relevant Situations for PD
        List<SC_SOCC_Situation_Catalog__c> relSituationCatalogs = [Select Id,Name, Handler_Type__r.Name from SC_SOCC_Situation_Catalog__c where ((Id NOT in: lSituationId) AND (Product__c in:ProductSet or Product__c=''))];
        System.debug('relSituationCatalogs'+relSituationCatalogs);
       
        
        //Populate String list
        for(SC_SOCC_Situation_Catalog__c SC:relSituationCatalogs)
        {
            SituationsforPD.add(SC.Name);
        }
        
        return relSituationCatalogs;
    }
    
    //To get Handlers based on Situation Handler Type & Policy Domain
    @AuraEnabled
    public static List<Handler__c> getHandlerPD(Id situationId,Id pdId)
    {
        //get handler type
        String HandlerTypeName = [Select Handler_Type__r.Name from SC_SOCC_Situation_Catalog__c where Id=:situationId limit 1].Handler_Type__r.Name;
        return [Select Name from Handler__c where Handler_Type__r.Name=:HandlerTypeName and Policy_Domain__c=:pdId];
    }
    
    //To Create Situation to handler Mapping
    @AuraEnabled
    public static void createSituationToHandlerMapping(Id situationId,Id handlerId,Id pdId)
    {
        SC_SOCC_Situation_to_Handler_Mapping__c sHMap = new SC_SOCC_Situation_to_Handler_Mapping__c();
        sHMap.Situation__c = situationId;
        sHMap.Handler__c  = handlerId;
        sHMap.Policy_Domain__c  = pdId;
        
        insert sHMap;
        
    }
    
    //To delete Situation to Handler Mapping
    @AuraEnabled
    public static void deleteSHMappingRecord(Id SHRecordId)
    {   
        SC_SOCC_Situation_to_Handler_Mapping__c shMap = new SC_SOCC_Situation_to_Handler_Mapping__c(Id=SHRecordId);
        delete shMap;
    }
    
    
    @AuraEnabled
    public static list<SC_SOCC_Situation_to_Handler_Mapping__c> getassociatedSituations(Id HandlerID)
    {
        list<SC_SOCC_Situation_to_Handler_Mapping__c> AssociatedSituations= [select Situation__r.name from SC_SOCC_Situation_to_Handler_Mapping__c where Handler__c=:HandlerID];
        return AssociatedSituations;
    }
    
    //To get All Handlers and check if the loggedin user is a shift manager or not
    
    public class PD_Handler_Details{
        @AuraEnabled public list<Handler__c> HandlerDetails{get;set;}
        @AuraEnabled public Boolean IsShiftManager{get;set;}
        @AuraEnabled public list<integer> no_of_associated_situations{get;set;}
    }
    
    @AuraEnabled
    public static PD_Handler_Details getAllHandlers(Id pdId)
    {
        PD_Handler_Details each_PD_Handler_Details = new PD_Handler_Details();
        list<integer> sitcount=new list<integer>();
        list<Handler__c> HandlerDet = new list<Handler__c>();
        HandlerDet= [Select id,Name,Handler_Type__r.Name,CreatedBy.Name,CreatedDate, Lastmodifiedby.Name,LastModifiedDate from Handler__c where Policy_Domain__c=:pdId order by name];
        
        each_PD_Handler_Details.HandlerDetails=HandlerDet;
        if(HandlerDet.size()>0)
        {
            each_PD_Handler_Details.IsShiftManager=SC_SOCC_Instruction_Manager.checkIfShiftManager();
            set<id> handlerids=new set<id>();
            for(integer i=0;i<HandlerDet.size();i++)
            {
                handlerids.add(HandlerDet[i].Id);
            }
            AggregateResult[] groupedResults=[select count(id), Handler__c from SC_SOCC_Situation_to_Handler_Mapping__c where Handler__c IN :handlerids group by Handler__c];
            Map<string,Integer> handler_sitCountMap = new Map<string,Integer>();
            
            for (AggregateResult ar : groupedResults)
            {
                handler_sitCountMap.put(string.valueOf(ar.get('Handler__c')),integer.valueOf(ar.get('expr0')));
            }
            for(integer i=0;i<HandlerDet.size();i++)
            {
                if(handler_sitCountMap.containsKey(HandlerDet[i].Id))
                {
                    sitcount.add(handler_sitCountMap.get(HandlerDet[i].Id));
                }
                else
                {
                    sitcount.add(0);
                }
            } 
        }
        else
            each_PD_Handler_Details.IsShiftManager=false;
        each_PD_Handler_Details.no_of_associated_situations=sitcount;
        return each_PD_Handler_Details;
    }
    
    //To Delete All Handlers and Relevant situation to Handler Mapping
    @AuraEnabled
    public static void deleteAllHandlers(List<Id> HandlerIdList,Id pdId)
    {
        //Delete all Situation to Handler Mappings
        List<SC_SOCC_Situation_to_Handler_Mapping__c> shMapdelete = [Select Id from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =: pdId and Handler__c in: HandlerIdList];
        if(shMapdelete.size()>0)
        {
            delete shMapdelete;
        }
        
        List<Handler__c> Handlerstodelete = new List<Handler__c>();
        for(Id HandlerId:HandlerIdList)
        {
            Handler__c handler = new Handler__c(id=HandlerId);
            Handlerstodelete.add(handler);
        }
        
        if(Handlerstodelete.size()>0)
        {
            delete Handlerstodelete;
        }
    }
    
    
    @AuraEnabled
    public static void addInstructionforApproval(Id pdId,Id handlerId, String situationInstructionText,String ignoreInstructionText)
    {
        
        List<Instruction__c> pendingInstructionList = new List<Instruction__c>();
        pendingInstructionList = [select id, Status__c from Instruction__c where Handler__c =: handlerId and Status__c =: 'In Progress'];
        if(pendingInstructionList.size() > 0){
            throw new AuraHandledException('There are pending instructions for this Handler.');
        }
        else
        {
            Map<String, String> mInstructionTypeValue = new Map<String, String>();
            if(situationInstructionText != '')
                mInstructionTypeValue.put('Situation Instruction',situationInstructionText);
            if(ignoreInstructionText != '')
                mInstructionTypeValue.put('Ignore Condition',ignoreInstructionText);
            
            system.debug('mInstructionTypeValue : '+mInstructionTypeValue);
            SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdId, handlerId, mInstructionTypeValue);
        } 
    }
    
    @AuraEnabled
    public static void showNotificationCase(Id handlerId)
    {
        List<Instruction__c> pendingInstructionList = new List<Instruction__c>();
        pendingInstructionList = [select id, Status__c, Case__r.AKAM_Case_ID__c  from Instruction__c where Handler__c =: handlerId and Status__c =: 'In Progress'];
        if(pendingInstructionList.size() > 0){
            throw new AuraHandledException('Your edits are in review. For more information please refer case #'+pendingInstructionList[0].Case__r.AKAM_Case_ID__c);
        }        
    }
    
    public class InstructionWrapper
    {
        Id handlerId;
        Id situationId;
        String situationInstruction;
        String ignoreCondition;
    }
    @AuraEnabled
    public static void addMultipleInstructionforApproval(String handlerIdInstMap, String policyDomainId)
    {
        system.debug('handlerIdInstMap : '+handlerIdInstMap);
        List<Handler__c> newHandlerList = new List<Handler__c>();
        List<Id> handlerIdList = new List<Id>();
        List<InstructionWrapper> instructionWrapperList = new List<InstructionWrapper>();
        instructionWrapperList =(List<InstructionWrapper>)System.JSON.deserialize(handlerIdInstMap,List<InstructionWrapper>.class);
        //InstructionWrapper instructionWrappers = (InstructionWrapper)JSON.deserialize(handlerIdInstMap, InstructionWrapper.class);
        system.debug('instructionWrapperList : '+instructionWrapperList);
        for(InstructionWrapper thisInstruction : instructionWrapperList){
            system.debug('INSTRUCTION : '+thisInstruction);
            Handler__c newHandlerRecord = new Handler__c(); 
            if(String.isBlank(thisInstruction.situationInstruction) && String.isBlank(thisInstruction.ignoreCondition)){
                system.debug('inside blank');
            }
            else{
                newHandlerRecord.Id = thisInstruction.handlerId;
                newHandlerRecord.Situation_Instruction__c = thisInstruction.situationInstruction;
                newHandlerRecord.Ignore_Condition__c = thisInstruction.ignoreCondition;
                newHandlerList.add(newHandlerRecord);
                handlerIdList.add(thisInstruction.handlerId);
            }
            system.debug('handlerIdList : '+handlerIdList);
        }
        List<Instruction__c> pendingInstructionList = new List<Instruction__c>();
        Set<String> handlerSet = new Set<String>();
        String pendingHandlerName = '';
        pendingInstructionList = [select id, Status__c,Handler__r.Name from Instruction__c where Handler__c IN: handlerIdList and Status__c =: 'In Progress'];
        if(pendingInstructionList.size() > 0){
            for(Instruction__c thisInst : pendingInstructionList){
                handlerSet.add(thisInst.Handler__r.Name);
            }
            pendingHandlerName = String.join((Iterable<String>)handlerSet, ', '); 
            throw new AuraHandledException('There are pending instructions for '+pendingHandlerName.removeEnd(',')+' Handlers.');
        }
        else{
            SC_SOCC_Instruction_Manager.saveInstructionCreateCase(newHandlerList, Id.valueOf(policyDomainId));
        }
    }
    
    //To fetch Instruction Record for Pd and Handler
    @AuraEnabled
    public static Instruction__c getInstruction(Id pdId,Id HandlerId)
    {
        return [Select Value__c from Instruction__c where Policy_Domain__c=:pdId and Handler__c=:HandlerId and Status__c='In Progress' limit 1];
    }
    
    //To fetch Escalation detail Lists
    @AuraEnabled
    public static SC_SOCC_Escalation_List__c getEscalationListRec(Id EscalationListId)
    {
        return [SELECT Id, Name, Policy_Domain__c, Policy_Domain__r.Account_Name__c, Instructions__c, CreatedBy.Name, CreatedDate,
                (SELECT Id, Name, Order_Number__c, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
                 Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c,Authorized_Contact__r.Contact_Name__r.Phone, 
                 Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contacts__r ORDER BY Order_Number__c)
                FROM SC_SOCC_Escalation_List__c where Id=:EscalationListId];
    }
    
    //Fetch Handler Details for a Record
    @AuraEnabled
    public static Handler__c getHandlerRecordDetails(Id HandlerId)
    {
        system.debug('HandlerId'+handlerId);
        return [Select Escalation_List__c  from Handler__c where Id=:HandlerId];
    }
    
    /******** Code Block to Return a List of Wrapper of Handler and associated List of Escalation Contacts ****/
    @AuraEnabled
    public static  List<HandlerEscContact> getHandlerEscContactList(List<String> handlerIdList)
    {
        //Query All Handler Details
        List<Handler__c> handlerList = [Select Name,Escalation_List__c,Escalation_List__r.Name,Escalation_List__r.Instructions__c,Escalation_List__r.CreatedBy.Name,Handler_Type__r.Name,CreatedBy.Name,LastModifiedDate from Handler__c where id in:handlerIdList];
        
        //Map of escalation list Id and Handler
        Map<Id,Handler__c> esclationIdHandlerMap = new Map<Id,Handler__c>();
        for(Handler__c varHandler:handlerList)
        {
            esclationIdHandlerMap.put(varHandler.Escalation_List__c, varHandler);
        }
        
        //Query All related escalation Contacts
        List<SC_SOCC_Escalation_Contact__c> EscContactList = [SELECT Id, Name, Order_Number__c,Escalation_List__c, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
                                                              Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c,Authorized_Contact__r.Contact_Name__r.Phone, 
                                                              Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contact__c where Escalation_List__c in:esclationIdHandlerMap.keySet() ORDER BY Order_Number__c];
        //Map of escalation list Id and List of Escalation Contacts
        Map<Id,List<SC_SOCC_Escalation_Contact__c>> esclationIdContListMap = new  Map<Id,List<SC_SOCC_Escalation_Contact__c>>();
        
        for(SC_SOCC_Escalation_Contact__c escContact:EscContactList)
        {
            if(esclationIdContListMap.get(escContact.Escalation_List__c)!=null)
            {
                List<SC_SOCC_Escalation_Contact__c> tempList = esclationIdContListMap.get(escContact.Escalation_List__c);
                tempList.add(escContact);
                esclationIdContListMap.put(escContact.Escalation_List__c,tempList);
            }
            else
            {
                esclationIdContListMap.put(escContact.Escalation_List__c,new List<SC_SOCC_Escalation_Contact__c>{escContact});
            }
        }
        
        //Create a Map of Handler and List of Escalation Contact
        Map<Handler__c,List<SC_SOCC_Escalation_Contact__c>> handlerEscContactzMap  = new  Map<Handler__c,List<SC_SOCC_Escalation_Contact__c>>();
        
        //Create a List of wrapper Class
        List<HandlerEscContact> HandlerEscContactList = new List<HandlerEscContact>();
        
        for(Handler__c hndlr:handlerList)
        {
            HandlerEscContact hndlresccont = new HandlerEscContact();
            hndlresccont.Handler = hndlr;
            hndlresccont.EscalationContact=esclationIdContListMap.get(hndlr.Escalation_List__c);
            HandlerEscContactList.add(hndlresccont);
            handlerEscContactzMap.put(hndlr,esclationIdContListMap.get(hndlr.Escalation_List__c));
            
        }
        
        System.debug(handlerEscContactzMap);
        return HandlerEscContactList;
        
        
    }
    
    //Create a wrapper Class
    public class HandlerEscContact
    {
        @AuraEnabled public Handler__c Handler{get;set;}
        @AuraEnabled public List<SC_SOCC_Escalation_Contact__c> EscalationContact{get;set;}
        
    }
    
    //Create another wrapper class
    public class SHMapHandlerEscContact 
    {
        @AuraEnabled public SC_SOCC_Situation_to_Handler_Mapping__c SHMap{get;set;}
        @AuraEnabled public Handler__c Handler{get;set;}
        @AuraEnabled public List<SC_SOCC_Escalation_Contact__c> EscalationContact{get;set;}
        @AuraEnabled public String SituationNameList {get;set;}
    }
    
    //to get existing situation to Handler Mappings for Policy Domain
    @AuraEnabled
    public static List<SHMapHandlerEscContact> getSituationToHandlerMappingsHandlerEscalationContacts(Id pdId)
    {
        System.debug('getSituationToHandlerMappings');
        List<SC_SOCC_Situation_to_Handler_Mapping__c> shmapList = [Select Id,Situation__r.Name, Handler__r.Name,Handler__c,CreatedBy.Name,CreatedDate, Policy_Domain__c from SC_SOCC_Situation_to_Handler_Mapping__c where Policy_Domain__c =: pdId];
        //create a map of HandlerId and sHmap
        Map<Id,SC_SOCC_Situation_to_Handler_Mapping__c> handlerIdShMap = new Map<Id,SC_SOCC_Situation_to_Handler_Mapping__c>();
        Map<Id,List<String>> handlerSituationNameMap = new Map<Id,List<String>>();
        for(SC_SOCC_Situation_to_Handler_Mapping__c shmap:shmapList)
        {
            handlerIdShMap.put(shmap.Handler__c,shmap);
            system.debug('Handler Name : '+shmap.Handler__r.Name);
            system.debug('Situation Name : '+shmap.Situation__r.Name);
            
            if(handlerSituationNameMap.get(shmap.Handler__c) != null)
            {
                List<String> tempList = handlerSituationNameMap.get(shmap.Handler__c);
                tempList.add(shmap.Situation__r.Name);
                handlerSituationNameMap.put(shmap.Handler__c,tempList);
            }
            else{
                handlerSituationNameMap.put(shmap.Handler__c,new List<String>{shmap.Situation__r.Name});
                
            }
        }
        
        system.debug('handlerSituationNameMap : '+handlerSituationNameMap);
        //Query All Handler Details
        List<Handler__c> handlerList = [Select Id, Name,Escalation_List__c,Escalation_List__r.Name,Escalation_List__r.Instructions__c,Escalation_List__r.CreatedBy.Name,Handler_Type__r.Name,CreatedBy.Name,LastModifiedDate from Handler__c where id in:handlerIdShMap.keySet()];
        
        //Map of escalation list Id and Handler
        Map<Id,Handler__c> esclationIdHandlerMap = new Map<Id,Handler__c>();
        //Map of handlerId and Handler
        Map<Id,Handler__c> handlerIdHandlerMap = new Map<Id,Handler__c>();
        //Map of Handler Id and esclation Id
        Map<Id,Id> handlerescalationIdMap = new Map<Id,Id>();
        for(Handler__c varHandler:handlerList)
        {
            esclationIdHandlerMap.put(varHandler.Escalation_List__c, varHandler);
            handlerIdHandlerMap.put(varHandler.Id,varHandler);
            handlerescalationIdMap.put(varHandler.Id, varHandler.Escalation_List__c);
        }
        
        //Query All related escalation Contacts
        List<SC_SOCC_Escalation_Contact__c> EscContactList = [SELECT Id, Name, Order_Number__c,Escalation_List__c, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
                                                              Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c,Authorized_Contact__r.Contact_Name__r.Phone, 
                                                              Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contact__c where Escalation_List__c in:esclationIdHandlerMap.keySet() ORDER BY Order_Number__c];
        //Map of escalation list Id and List of Escalation Contacts
        Map<Id,List<SC_SOCC_Escalation_Contact__c>> esclationIdContListMap = new  Map<Id,List<SC_SOCC_Escalation_Contact__c>>();
        
        for(SC_SOCC_Escalation_Contact__c escContact:EscContactList)
        {
            if(esclationIdContListMap.get(escContact.Escalation_List__c)!=null)
            {
                List<SC_SOCC_Escalation_Contact__c> tempList = esclationIdContListMap.get(escContact.Escalation_List__c);
                tempList.add(escContact);
                esclationIdContListMap.put(escContact.Escalation_List__c,tempList);
            }
            else
            {
                esclationIdContListMap.put(escContact.Escalation_List__c,new List<SC_SOCC_Escalation_Contact__c>{escContact});
            }
        }
        
        //Create a Map of Handler and List of Escalation Contact
        Map<Handler__c,List<SC_SOCC_Escalation_Contact__c>> handlerEscContactzMap  = new  Map<Handler__c,List<SC_SOCC_Escalation_Contact__c>>();
        
        //Create a List of wrapper Class
        List<SHMapHandlerEscContact> SHMapHandlerEscContactList = new List<SHMapHandlerEscContact>();
        
        Set<Id> existingHandlerIdSet = new Set<Id>();
        for(SC_SOCC_Situation_to_Handler_Mapping__c shmap:shmapList)
        {
            system.debug('adfid : '+existingHandlerIdSet);
            if(!existingHandlerIdSet.contains(shmap.Handler__c)){
                SHMapHandlerEscContact shMapHandlerEscCont = new SHMapHandlerEscContact();
                shMapHandlerEscCont.Handler = handlerIdHandlerMap.get(shmap.Handler__c) ;
                shMapHandlerEscCont.EscalationContact=esclationIdContListMap.get(handlerescalationIdMap.get(shmap.Handler__c));
                shMapHandlerEscCont.SHMap = shmap;
                shMapHandlerEscCont.SituationNameList = string.join(handlerSituationNameMap.get(shmap.Handler__c),',');
                SHMapHandlerEscContactList.add(shMapHandlerEscCont);
            }
            existingHandlerIdSet.add(shmap.Handler__c);
            system.debug('sdjyfgadk: '+existingHandlerIdSet);
        }
        
        
        system.debug(SHMapHandlerEscContactList);
        return SHMapHandlerEscContactList;
    }
    
    
    
    //Check if any handler has pending instruction
    @AuraEnabled
    public static List<String> checkforPendingInstruction(List<Id> incomingHandlerId)
    {
        System.debug('incomingHandlerId '+incomingHandlerId);
        List<Instruction__c> lExistingInstruction = [SELECT Id, CreatedBy.Name,Handler__r.Name FROM Instruction__c WHERE Handler__c in:incomingHandlerId AND Status__c = 'In Progress'];
        System.debug('lExistingInstruction '+lExistingInstruction);
        Set<String> handlersYouCantDel = new Set<String>();
        List<String> handlersYouCantDelList = new List<String>();
        
        if(lExistingInstruction.size()>0)
        {
            for(Instruction__c varInst:lExistingInstruction)
            {
                handlersYouCantDel.add(varInst.Handler__r.Name);
            }
        }
        handlersYouCantDelList.addAll(handlersYouCantDel);
        return  handlersYouCantDelList;       
        
    }
    @AuraEnabled
    public static List<Handler_Type__c> getHandlerFieldMappings()
    {
        return [select id,name, Fields_To_Show__c from  Handler_Type__c];
    }
    
    @AuraEnabled
    public static String getPDID(String pdAkamId)
    {
        String decryptedPdAkamId = decryptPDId(pdAkamId);
        List<Id> employeeIdList = new List<Id>();
        List<Id> communityContactIdList = new List<Id>();

        //Inside Community
        if(Network.getNetworkId() != null || Test.isRunningTest()){
            //To check if the user is authorized to view the runbook
            for(User thisUser : [Select id,contactId,email from User where id =: userinfo.getUserId()]){
                if(thisUser.email.contains('@akamai.com'))
                    employeeIdList.add(thisUser.id);
                if(thisUser.contactId != null)
                    communityContactIdList.add(thisUser.contactId);
            }
            for(Policy_Domain__c thisPD : [Select Id, AKAM_Policy_Domain_ID__c from Policy_Domain__c where Account_Name__c in (Select PD_Account__c from SOCC_User_Account_Mapping__c where Internal_User__c in : employeeIdList and Internal_User__r.IsActive = true and Active__c = true)]){
                if(decryptedPdAkamId.endsWithIgnoreCase(thisPD.AKAM_Policy_Domain_ID__c))
                    return thisPD.Id;
            }
            for(Authorized_Contact__c thisAC : [Select Id, Policy_Domain__c, Policy_Domain__r.AKAM_Policy_Domain_ID__c from Authorized_Contact__c where Contact_Name__c in: communityContactIdList]){
                if(decryptedPdAkamId.endsWithIgnoreCase(thisAC.Policy_Domain__r.AKAM_Policy_Domain_ID__c))
                    return thisAC.Policy_Domain__c;
            }
            
        }
        //Inside Salesforce
        else{
            List<Policy_Domain__c> pd = [select Id from  Policy_Domain__c where AKAM_Policy_Domain_ID__c =: decryptedPdAkamId];
            if(pd.size() > 0) {
                return pd[0].Id;
            }
        }
        return 'NOT AUTHORIZED';
    }

    public static String decryptPDId(String encryptedId) {
        List<SC_Utility__mdt> lMetadata = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c=true AND DeveloperName IN ('Encryption_Key_for_PD_on_Community', 'IV_for_PD_Encryption_on_Community') ORDER BY DeveloperName ASC];
        Blob key = EncodingUtil.base64Decode(lMetadata[0].Value_Text__c);
        Blob iv = Blob.valueOf(lMetadata[1].Value_Text__c);
        Blob data = EncodingUtil.base64Decode(EncodingUtil.urlDecode(encryptedId, 'UTF-8'));
        Blob decrypted = Crypto.decrypt('AES128', key, iv, data);
        return decrypted.toString();
    }
    @AuraEnabled
    public static Boolean getCommunityAccess()
    {
        if(Network.getNetworkId() != null)
            return true;
        return false;
    }
    
}