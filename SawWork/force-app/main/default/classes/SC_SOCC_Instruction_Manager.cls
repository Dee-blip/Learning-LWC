/*
Author          :  Pinkesh
Description     :  Class for SOCC Car RunBooks
Test Class		:  SC_SOCC_Instruction_Manager_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh                              SOCC CAR 2 - RunBooks 
02 Dec 2020         Tejaswini                   ESESP-3741      Added more User Titles for Shift Managers
14 Dec 2020         Tejaswini                   ESESP-3732      Checking if the user is SSP or not
17 Feb 2021         Tejaswini                   ESESP-4822      Runbooks Phase II: Sprint 1 - Streamline Runbooks Approval Process
18 Feb 2021			Tejaswini 					ESESP-4823		Runbooks Phase II: Sprint 1 - Adding Instruction Details to Living Summary field
22 Feb 2022         Aravind                     ESESP-6460      Send email with stack trace when exception is thrown
-----------------------------------------------------------------------------------------------------------------------------------------
*/
public class SC_SOCC_Instruction_Manager {
    //Wrapper class with InstructionWrapper and Shift manager Access
    public class InstructionsWithShiftManager{
        @AuraEnabled public Boolean isShiftManager;
        @AuraEnabled public Boolean isSSP;
        @AuraEnabled public List<InstructionWrapper> lInstructions;
    }
    
    //Wrapper class for show Instruction Approval records
    public class InstructionWrapper{
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String instructionsType;
        @AuraEnabled public String status;
        @AuraEnabled public String value;
        @AuraEnabled public String caseId;
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public String objectType;
        @AuraEnabled public String objectId;
        @AuraEnabled public String objectName;
        @AuraEnabled public String createdBy;
        @AuraEnabled public Boolean isOwner;
        //Handler related fields
        @AuraEnabled public Id handler;
        @AuraEnabled public String handlerName;
        @AuraEnabled public String situationInstruction;
        @AuraEnabled public String ignoreCondition;
        //Policy Domain related fields
        @AuraEnabled public Id policyDomain;
        @AuraEnabled public String policyDomainName;
        @AuraEnabled public String specialInstructions;
        //Escalation List related fields
        @AuraEnabled public Id escalationList;
        @AuraEnabled public String escalationListName;
        @AuraEnabled public String escalationInstructions;
        
        //Changes by Tejaswini for ESESP-4822
        @AuraEnabled public Id escListId;
        @AuraEnabled public String caseIdWithoutSpecialChar;
        //@AuraEnabled public Boolean isS2HNotPresent;
    }
    
    public static void saveInstructionCreateCase(Id pdId, Id parentId, Map<String, String> mInstructionTypeValue){
        //Check if Shift manager
        Boolean isShiftManager = checkIfShiftManager();
        
        //ESESP-4953 - Multiple Service Account
        List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        
        //ESESP-4953
        serviceAccountPDList = [Select id, Service_Account__c,Policy_Domain__c from Service_Account_PD_Mapping__c where Service_Account__c =: pdId];
        for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
            serviceAccountIDList.add(SAPDMap.Service_Account__c);
        }
        
        //Create Case for this instruction submition
        Id caseId;
        for(String instructionsType : mInstructionTypeValue.keySet()){
            if(instructionsType.equalsIgnoreCase('Situation Instruction') || instructionsType.equalsIgnoreCase('Ignore Condition')){
                caseId = createCaseForHandler(parentId, mInstructionTypeValue, isShiftManager, serviceAccountIDList);
                break;
            }
            else if(instructionsType.equalsIgnoreCase('Policy Domain Instruction')){
                caseId = createCaseForPolicyDomain(parentId, mInstructionTypeValue, isShiftManager, serviceAccountIDList);
                break;
            }
            else{
                caseId = createCaseForEscalationList(parentId, mInstructionTypeValue, isShiftManager, serviceAccountIDList);
                break;
            }
        }
        
        //Auto Approve if logged in user is a Shift Manager
        if(isShiftManager)
            autoApproveInstruction(parentId, mInstructionTypeValue);
        
        
        //List of instruction approval records to be inserted
        List<Instruction__c> lInstruct = new List<Instruction__c>();
        for(String instructionsType : mInstructionTypeValue.keySet()){
            String value = mInstructionTypeValue.get(instructionsType);
            
            //Create the instruction
            Instruction__c  instruct = new Instruction__c();
            instruct.Case__c = caseId;
            
            //setting parent Id
            if(instructionsType.equalsIgnoreCase('Situation Instruction') || instructionsType.equalsIgnoreCase('Ignore Condition'))
                instruct.Handler__c = parentId;
            else if(instructionsType.equalsIgnoreCase('Policy Domain Instruction'))
                instruct.Policy_Domain__c = parentId;
            else
                instruct.Escalation_List__c = parentId;
            
            instruct.Instructions_Type__c = instructionsType;
            if(isShiftManager)
                instruct.Status__c = 'Approved';
            else
                instruct.Status__c = 'In Progress';
            instruct.Value__c = value;
            
            lInstruct.add(instruct);
        }
        system.debug('lInstruct : '+lInstruct);
        try{
            if(lInstruct.size()>0)
                insert lInstruct;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    //Create Case For Handler
    public static Id createCaseForHandler(Id handlerId, Map<String, String> mInstructionTypeValue, Boolean isShiftManager, List<Id> serviceAccountIDList){
        //Get Record data
        Handler__c handlerRec = [SELECT Id, Name, Policy_Domain__c, Policy_Domain__r.Name, Policy_Domain__r.Account_Name__c, Policy_Domain__r.Account_Name__r.Name, Policy_Domain__r.Service_Account__c FROM Handler__c WHERE Id =:handlerId LIMIT 1];
        List<SC_SOCC_Situation_to_Handler_Mapping__c> situationToHandlerMappingRec = [SELECT Id, Situation__c, Situation__r.Name, Handler__c FROM SC_SOCC_Situation_to_Handler_Mapping__c WHERE Handler__c =:handlerId LIMIT 1];
        
        //Set Subject
        String subject = handlerRec.Policy_Domain__r.Account_Name__r.Name + ' | ' + handlerRec.Policy_Domain__r.Name + ' | Runbook update request';
        if(isShiftManager)
            subject += ' | Auto Approved';
        
        //Set Description
        String description = 'Account Name : ' + handlerRec.Policy_Domain__r.Account_Name__r.Name + '<br/>';
        description += 'Policy Domain Name : ' + handlerRec.Policy_Domain__r.Name + '<br/>';
        description += 'Handler Name : ' + handlerRec.Name + '<br/>';
        description += 'Situation Name : ';
        if(situationToHandlerMappingRec.size()>0)
            description += situationToHandlerMappingRec[0].Situation__r.Name;
        if(isShiftManager)
            description+= '<br/>Auto Approved : Instructions submitted by Shift Manager <br/>';
        description += '<br/>Instructions Approval Link : <br/>' + getLightningBaseURL() + '/lightning/n/Runbook_Approval_Requests <br/>';
        for(String instructionsType : mInstructionTypeValue.keySet()){
            description += '<br/>Pending ' + instructionsType + ' : <br/>' + mInstructionTypeValue.get(instructionsType) + '<br/>';
        }
        
        if(description.length() > 31999)
            description = description.substring(0, 31999);
        
        //Set Contact Id
        String contactId;
        //Set Origin
        //Check if User's contact is present on the Policy Domain's Account or Service Account   
        //Call Method to Create Case
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c.AccountId = handlerRec.Policy_Domain__r.Account_Name__c;
        c.Subject = subject;
        //c.Description = description;
        c.Living_Summary_Next_Steps__c = description;
        if(Network.getNetworkId() != null){ //Check if user is in community
            c.origin = 'Community';
            c.Do_Not_Show_in_Portal__c = false;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
            Id currentUserId = UserInfo.getUserId();
            
            //Commented for ESESP-4953 - Multiple Service Account
            //List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:handlerRec.Policy_Domain__r.Account_Name__c OR Contact.AccountId =:handlerRec.Policy_Domain__r.Service_Account__c)];
            List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:handlerRec.Policy_Domain__r.Account_Name__c OR Contact.AccountId IN: serviceAccountIDList)];
            if(userRec.size()>0)
                contactId = userRec[0].ContactId;
        }
        
        else
        {
            c.origin = 'Akamai'; 
            c.Do_Not_Show_in_Portal__c = true;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
            
        }
        c.Severity__c = '3';
        c.Priority = 'Low';
        c.Policy_Domain__c = handlerRec.Policy_Domain__c;
        c.Sub_Type__c = 'Runbook Review';
        c.Service_Category__c = 'Managed Security';
        c.Problem__c = 'N/A - Not Applicable';
        c.Case_Assignment_Using_Active_Rules__c = true;
        c.Validation_Override__c = true;
        
        if(String.isNotBlank(contactId)){
            c.ContactId = contactId;
        }
        else{
            c.Alternate_Contact_Name__c = UserInfo.getName();
            c.Alternate_Contact_Email__c = UserInfo.getUserEmail();
            c.AlternateContactEmailManagedSecurity__c = UserInfo.getUserEmail();
        }
        //Changes by Tejaswini for ESESP-4822
        if(isShiftManager)
            c.Status = 'Closed';
        
        try{
            insert c;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        return c.Id;
    }
    
    //Create Case For Policy Domain
    public static Id createCaseForPolicyDomain(Id pdId, Map<String, String> mInstructionTypeValue, Boolean isShiftManager, List<Id> serviceAccountIDList){
        //Get Record data
        Policy_Domain__c pdRec = [SELECT Id, Name, Account_Name__c, Account_Name__r.Name, Service_Account__c FROM Policy_Domain__c WHERE Id =:pdId LIMIT 1];
        //Set Subject
        String subject = pdRec.Account_Name__r.Name + ' | ' + pdRec.Name + ' | Policy Domain Instruction update request';
        if(isShiftManager)
            subject += ' | Auto Approved';
        
        //Set Description
        String description = 'Account Name : ' + pdRec.Account_Name__r.Name + '<br/>';
        description += 'Policy Domain Name : ' + pdRec.Name;
        if(isShiftManager)
            description+= '<br/>Auto Approved : Instructions submitted by Shift Manager <br/>';
        description += '<br/>Instructions Approval Link : <br/>' + getLightningBaseURL() + '/lightning/n/Runbook_Approval_Requests <br/>';
        for(String instructionsType : mInstructionTypeValue.keySet()){
            description += '<br/>Pending ' + instructionsType + ' : <br/>' + mInstructionTypeValue.get(instructionsType) + '<br/>';
        }
        
        if(description.length() > 31999)
            description = description.substring(0, 31999);
        
        //Set Contact Id
        String contactId;
        
        //Call Method to Create Case
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c.AccountId = pdRec.Account_Name__c;
        c.Subject = subject;
        //c.Description = description;
        c.Living_Summary_Next_Steps__c = description;
        c.Severity__c = '3';
        c.Priority = 'Low';
        c.Policy_Domain__c = pdRec.Id;
        c.Sub_Type__c = 'Runbook Review';
        c.Service_Category__c = 'Managed Security';
        c.Problem__c = 'N/A - Not Applicable';
        if(Network.getNetworkId() != null){ //Check if user is in community
            c.origin = 'Community';
            c.Do_Not_Show_in_Portal__c = false;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
            Id currentUserId = UserInfo.getUserId();
            
            //Commented for ESESP-4953 - Multiple Service Account
            //List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:pdRec.Account_Name__c OR Contact.AccountId =:pdRec.Service_Account__c)];
            List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:pdRec.Account_Name__c OR Contact.AccountId IN: serviceAccountIDList)];
            if(userRec.size()>0)
                contactId = userRec[0].ContactId;
        }
        
        else
        {
            c.origin = 'Akamai'; 
            c.Do_Not_Show_in_Portal__c = true;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
            
        }
        c.Case_Assignment_Using_Active_Rules__c = true;
        c.Validation_Override__c = true;
        
        if(String.isNotBlank(contactId)){
            c.ContactId = contactId;
        }
        else{
            c.Alternate_Contact_Name__c = UserInfo.getName();
            c.Alternate_Contact_Email__c = UserInfo.getUserEmail();
            c.AlternateContactEmailManagedSecurity__c = UserInfo.getUserEmail();
        }
        //Changes by Tejaswini for ESESP-4822
        if(isShiftManager)
            c.Status = 'Closed';
        
        try{
            insert c;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        return c.Id;
    }
    
    //Create Case For Escalation List
    public static Id createCaseForEscalationList(Id escListId, Map<String, String> mInstructionTypeValue, Boolean isShiftManager, List<Id> serviceAccountIDList){
        //Get Record data
        SC_SOCC_Escalation_List__c escListRec = [SELECT Id, Name, Policy_Domain__c, Policy_Domain__r.Name, Policy_Domain__r.Account_Name__c, Policy_Domain__r.Account_Name__r.Name, Policy_Domain__r.Service_Account__c FROM SC_SOCC_Escalation_List__c WHERE Id =:escListId LIMIT 1];
        //Set Subject
        String subject = escListRec.Policy_Domain__r.Account_Name__r.Name + ' | ' + escListRec.Policy_Domain__r.Name + ' | Runbook update request';
        if(isShiftManager)
            subject += ' | Auto Approved';
        
        //Set Description
        String description = 'Account Name : ' + escListRec.Policy_Domain__r.Account_Name__r.Name + '<br/>';
        description += 'Policy Domain Name : ' + escListRec.Policy_Domain__r.Name + '<br/>';
        description += 'Escalation List Name : ' + escListRec.Name;
        if(isShiftManager)
            description+= '<br/>Auto Approved : Instructions submitted by Shift Manager <br/>';
        description += '<br/>Instructions Approval Link :<br/> ' + getLightningBaseURL() + '/lightning/n/Runbook_Approval_Requests <br/>';
        for(String instructionsType : mInstructionTypeValue.keySet()){
            description += '<br/>Pending ' + instructionsType + ' : <br/>' + mInstructionTypeValue.get(instructionsType) + '<br/>';
        }
        
        if(description.length() > 31999)
            description = description.substring(0, 31999);
        
        //Set Contact Id
        String contactId;
        //Check if User's contact is present on the Policy Domain's Account or Service Account
        
        //Call Method to Create Case
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c.AccountId = escListRec.Policy_Domain__r.Account_Name__c;
        c.Subject = subject;
        //c.Description = description;
        c.Living_Summary_Next_Steps__c = description;
        c.Severity__c = '3';
        c.Priority = 'Low';
        c.Policy_Domain__c = escListRec.Policy_Domain__c;
        c.Sub_Type__c = 'Runbook Review';
        c.Service_Category__c = 'Managed Security';
        c.Problem__c = 'N/A - Not Applicable';
        if(Network.getNetworkId() != null){ //Check if user is in community
            c.origin = 'Community';
            c.Do_Not_Show_in_Portal__c = false;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
            Id currentUserId = UserInfo.getUserId();
            
            //Commented for ESESP-4953 - Multiple Service Account
            //List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:escListRec.Policy_Domain__r.Account_Name__c OR Contact.AccountId =:escListRec.Policy_Domain__r.Service_Account__c)];
            List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:escListRec.Policy_Domain__r.Account_Name__c OR Contact.AccountId IN: serviceAccountIDList)];
            if(userRec.size()>0)
                contactId = userRec[0].ContactId;
        }
        
        else
        {
            c.origin = 'Akamai'; 
            c.Do_Not_Show_in_Portal__c = true;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
            
        }
        c.Case_Assignment_Using_Active_Rules__c = true;
        c.Validation_Override__c = true;
        
        if(String.isNotBlank(contactId)){
            c.ContactId = contactId;
        }
        else{
            c.Alternate_Contact_Name__c = UserInfo.getName();
            c.Alternate_Contact_Email__c = UserInfo.getUserEmail();
            c.AlternateContactEmailManagedSecurity__c = UserInfo.getUserEmail();
        }
        //Changes by Tejaswini for ESESP-4822
        if(isShiftManager)
            c.Status = 'Closed';
        try{
            insert c;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        return c.Id;
    }
    
    //Auto Approve intstruction if logged in user is shift manager
    public static void autoApproveInstruction(Id parentId, Map<String, String> mInstructionTypeValue){
        //Parents records to be updated
        Handler__c handler = new Handler__c();
        Policy_Domain__c policyDomain = new Policy_Domain__c();
        SC_SOCC_Escalation_List__c escalationList = new SC_SOCC_Escalation_List__c();
        
        for(String instructionsType : mInstructionTypeValue.keySet()){
            if(instructionsType.equalsIgnoreCase('Situation Instruction') || instructionsType.equalsIgnoreCase('Ignore Condition'))
                handler.Id = parentId;
            if(instructionsType.equalsIgnoreCase('Situation Instruction')){
                handler.Situation_Instruction__c = mInstructionTypeValue.get(instructionsType);
            }
            else if(instructionsType.equalsIgnoreCase('Ignore Condition')){
                handler.Ignore_Condition__c = mInstructionTypeValue.get(instructionsType);
            }
            else if(instructionsType.equalsIgnoreCase('Policy Domain Instruction')){
                policyDomain.Id = parentId;
                policyDomain.Special_Instructions__c = mInstructionTypeValue.get(instructionsType);
            }
            else{
                escalationList.Id = parentId;
                escalationList.Instructions__c = mInstructionTypeValue.get(instructionsType);
            }
        }
        
        try{
            if(handler.Id != null)
                update handler;
            if(policyDomain.Id != null)
                update policyDomain;
            if(escalationList.Id != null)
                update escalationList;
        }catch (Exception e) {
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    //For multiple Handlers create case and save instructions records
    public static void saveInstructionCreateCase(List<Handler__c> lHandler, Id pdId){
        //Check if Shift manager
        Boolean isShiftManager = checkIfShiftManager();
        //Create Case for this instruction submition
        Id caseId = createCaseForMultipleHandlers(lHandler, isShiftManager,pdId);
        //Id caseId = '5003C000003jnGnQAI';
        
        //Auto Approve if logged in user is a Shift Manager
        if(isShiftManager)
            autoApproveInstructionForMultipleHandler(lHandler);
        
        //List of instruction approval records to be inserted
        List<Instruction__c> lInstruct = new List<Instruction__c>();
        for(Handler__c eachHandler : lHandler){
            //create instruction record for situation instruction field
            if(String.isNotBlank(eachHandler.Situation_Instruction__c)){
                Instruction__c instruct = new Instruction__c();
                instruct.Case__c = caseId;
                instruct.Handler__c = eachHandler.Id;
                instruct.Instructions_Type__c = 'Situation Instruction';
                if(isShiftManager)
                    instruct.Status__c = 'Approved';
                else
                    instruct.Status__c = 'In Progress';
                instruct.Value__c = eachHandler.Situation_Instruction__c;
                
                lInstruct.add(instruct);
            }
            //create instruction record for Ignore Condition field
            if(String.isNotBlank(eachHandler.Ignore_Condition__c)){ 
                Instruction__c instruct = new Instruction__c();
                instruct.Case__c = caseId;
                instruct.Handler__c = eachHandler.Id;
                instruct.Instructions_Type__c = 'Ignore Condition';
                if(isShiftManager)
                    instruct.Status__c = 'Approved';
                else
                    instruct.Status__c = 'In Progress';
                instruct.Value__c = eachHandler.Ignore_Condition__c;
                
                lInstruct.add(instruct);
            }
        }
        
        try{
            if(lInstruct.size()>0)
                insert lInstruct;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    //Create case for multiple incoming handlers
    public static Id createCaseForMultipleHandlers(List<Handler__c> lHandler, Boolean isShiftManager, Id pdId){
        Set<Id> lHandlerId = new Set<Id>();
        for(Handler__c eachHandler : lHandler)
            lHandlerId.add(eachHandler.Id);
        
        //ESESP-4953 - Multiple Service Account
        List<Service_Account_PD_Mapping__c> serviceAccountPDList = new List<Service_Account_PD_Mapping__c>();
        List<Id> serviceAccountIDList = new List<Id>();
        
        serviceAccountPDList = [Select id, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: pdId];
        for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
            serviceAccountIDList.add(SAPDMap.Service_Account__c);
        }
        
        //Get record data
        List<Handler__c> lHandlerRec = [SELECT Id, Name, Policy_Domain__c, Policy_Domain__r.Name, Policy_Domain__r.Account_Name__c, Policy_Domain__r.Account_Name__r.Name, Policy_Domain__r.Service_Account__c FROM Handler__c WHERE Id IN :lHandlerId];
        List<SC_SOCC_Situation_to_Handler_Mapping__c> lSituationToHandlerMappingRec = [SELECT Id, Situation__c, Situation__r.Name, Handler__c FROM SC_SOCC_Situation_to_Handler_Mapping__c WHERE Handler__c IN :lHandlerId and policy_Domain__c =:pdId];
        
        //Map of Handler Id to Handler Name
        Map<Id, String> mHandlerIdName = new Map<Id, String>();
        
        //Map of Handlerid to the associated list of situtation names
        Map<Id, List<String>> mHandlerIdLSituationName = new Map<Id, List<String>>();
        
        //populating the maps
        for(Handler__c eachHandler : lHandlerRec)
            mHandlerIdName.put(eachHandler.Id, eachHandler.Name);
        
        system.debug('lSituationToHandlerMappingRec : '+lSituationToHandlerMappingRec);
        for(SC_SOCC_Situation_to_Handler_Mapping__c eachrec : lSituationToHandlerMappingRec){
            System.debug('eachrec :  ' + eachrec);
            System.debug('mHandlerIdLSituationName :  ' + mHandlerIdLSituationName);
            if(mHandlerIdLSituationName.get(eachrec.Handler__c) == null)
                mHandlerIdLSituationName.put(eachrec.Handler__c, new List<String>());
            List<String> lSituationName = mHandlerIdLSituationName.get(eachrec.Handler__c);
            lSituationName.add(eachrec.Situation__r.Name);
            mHandlerIdLSituationName.put(eachrec.Handler__c, lSituationName);
        }
        
        
        System.debug('-------mHandlerIdName : ' + mHandlerIdName);
        
        //Set Subject
        String subject = lHandlerRec[0].Policy_Domain__r.Account_Name__r.Name + ' | ' + lHandlerRec[0].Policy_Domain__r.Name + ' | Runbook update request';
        if(isShiftManager)
            subject += ' | Auto Approved';
        
        //Set Description
        String description = 'Account Name : ' + lHandlerRec[0].Policy_Domain__r.Account_Name__r.Name + '<br/>';
        description += 'Policy Domain Name : ' + lHandlerRec[0].Policy_Domain__r.Name + '<br/>';
        if(isShiftManager)
            description+= '<br/>Auto Approved : Instructions submitted by Shift Manager <br/>';
        description += '<br/>Instructions Approval Link :<br/> ' + getLightningBaseURL() + '/lightning/n/Runbook_Approval_Requests <br/>';
        
        for(Handler__c eachHandler : lHandler){
            System.debug('--------- Handler Id : ' + eachHandler.Id);
            description += '<br/>Handler Name : ' + mHandlerIdName.get(eachHandler.Id) + '<br/>';
            description += 'Situation Name : ';
            if(mHandlerIdLSituationName.get(eachHandler.Id) != null){
                for(String eachName : mHandlerIdLSituationName.get(eachHandler.Id))
                    description += eachName + ', ';
                description = description.removeEnd(', ');
            }
            description += '<br/>';
            
            if(String.isNotBlank(eachHandler.Situation_Instruction__c)){
                   description += '<br/>Pending Situation Instruction: <br/>' + eachHandler.Situation_Instruction__c + '<br/>';
             }
            if(String.isNotBlank(eachHandler.Ignore_Condition__c)){
                description += '<br/>Pending Ignore Condition: <br/>' + eachHandler.Ignore_Condition__c + '<br/>';
            }
            
        }
        
        if(description.length() > 31999)
            description = description.substring(0, 31999);
        
        System.debug('-------------------description : ' + description);
        
        //Set Contact Id
        String contactId;
        //Set Origin
        
        //Call Method to Create Case
        Case c = new Case();
        c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c.AccountId = lHandlerRec[0].Policy_Domain__r.Account_Name__c;
        c.Subject = subject;
        //c.Description = description;
        c.Living_Summary_Next_Steps__c = description;
        c.Severity__c = '3';
        c.Priority = 'Low';
        c.Policy_Domain__c = lHandlerRec[0].Policy_Domain__c;
        c.Sub_Type__c = 'Runbook Review';
        c.Service_Category__c = 'Managed Security';
        c.Problem__c = 'N/A - Not Applicable';
        if(Network.getNetworkId() != null){ //Check if user is in community
            c.origin = 'Community';
            c.Do_Not_Show_in_Portal__c = false;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
            Id currentUserId = UserInfo.getUserId();
            
            //Commented for ESESP-4953 - Multiple Service Account
            //List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:lHandlerRec[0].Policy_Domain__r.Account_Name__c OR Contact.AccountId =:lHandlerRec[0].Policy_Domain__r.Service_Account__c)];
            List<User> userRec = [SELECT Id, ContactId FROM User WHERE Id =:currentUserId AND (Contact.AccountId =:lHandlerRec[0].Policy_Domain__r.Account_Name__c OR Contact.AccountId IN: serviceAccountIDList)];
            if(userRec.size()>0)
                contactId = userRec[0].ContactId;
        }
        
        else
        {
            c.origin = 'Akamai'; 
            c.Do_Not_Show_in_Portal__c = true;
            c.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
            
        }
        c.Case_Assignment_Using_Active_Rules__c = true;
        c.Validation_Override__c = true;
        
        if(String.isNotBlank(contactId)){
            c.ContactId = contactId;
        }
        else{
            c.Alternate_Contact_Name__c = UserInfo.getName();
            c.Alternate_Contact_Email__c = UserInfo.getUserEmail();
            c.AlternateContactEmailManagedSecurity__c = UserInfo.getUserEmail();
        }
        //Changes by Tejaswini for ESESP-4822
        if(isShiftManager)
            c.Status = 'Closed';
        try{
            insert c;
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
        
        return c.Id;
        
    }
    
    //Auto approve and update multiple Handler when edited fro RunBook View
    public static void autoApproveInstructionForMultipleHandler(List<Handler__c> lHandler){
        List<Handler__c> lUpdatedHandler = new List<Handler__c>();
        
        for(Handler__c eachHandler : lHandler){
            Handler__c updatedHandler = new Handler__c(Id=eachHandler.Id);
            if(String.isNotBlank(eachHandler.Situation_Instruction__c))
                updatedHandler.Situation_Instruction__c = eachHandler.Situation_Instruction__c;
            if(String.isNotBlank(eachHandler.Ignore_Condition__c))
                updatedHandler.Ignore_Condition__c = eachHandler.Ignore_Condition__c;
            
            lUpdatedHandler.add(updatedHandler);
        }
        
        try{
            if(lUpdatedHandler.size() > 0)
                update lUpdatedHandler;
        }catch (Exception e) {
            SC_Jarvis_utility.sendErrorMails('Error in SOCC Instruction Manager: ', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //get data for Approval page with shift manager detail
    @AuraEnabled(cacheable=true)
    public static InstructionsWithShiftManager getData(String pdId){
        System.debug('*******Test****');
        Boolean isShiftManager = checkIfShiftManager();
        Boolean isSSP = false;
        
        if(String.isNotBlank(pdId))
        {
            Set<Id> accountIds = new Set<Id>();
            for(Policy_Domain__c varPd:[SELECT Id,Account_Name__c FROM Policy_Domain__c WHERE Id = :pdId LIMIT 1]){
                accountIds.add(varPd.Account_Name__c);
            }
    
            isSSP= SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(accountIds);
        }
        System.debug('******* is SSP'+isSSP);
        System.debug('******* is Shift Manager'+isShiftManager);

        
        //Variable to be returned
        InstructionsWithShiftManager instructionsWithShiftManager = new InstructionsWithShiftManager();
        instructionsWithShiftManager.isShiftManager = isShiftManager;
        instructionsWithShiftManager.isSSP=isSSP;
        instructionsWithShiftManager.lInstructions = getLInstructions(pdId, isShiftManager,isSSP);
        
        return instructionsWithShiftManager;
    } 
    
    
    //To get list of In Progress Instructions
    @AuraEnabled
    public static List<InstructionWrapper> getLInstructions(String pdId, Boolean isShiftManager, Boolean isSSP){
        List<Instruction__c> lInstruction = new List<Instruction__c>();
        if(String.isNotBlank(pdId)){
            if(isShiftManager || isSSP)
                lInstruction = [SELECT Id, Name, CreatedById, CreatedBy.Name, Instructions_Type__c, Status__c, Case__c, Case__r.AKAM_Case_ID__c, Value__c, Handler__c, Policy_Domain__c, Escalation_List__c, Handler__r.Name, Policy_Domain__r.Name, Escalation_List__r.Name, Handler__r.Situation_Instruction__c, Handler__r.Ignore_Condition__c, Policy_Domain__r.Special_Instructions__c, Escalation_List__r.Instructions__c,Handler__r.Escalation_List__c FROM Instruction__c 
                                WHERE (Policy_Domain__c =:pdId OR  Handler__r.Policy_Domain__c =:pdId OR Escalation_List__r.Policy_Domain__c =:pdId)
                                AND Status__c='In Progress' ORDER BY CreatedDate DESC];
            else
                lInstruction = [SELECT Id, Name, CreatedById, CreatedBy.Name, Instructions_Type__c, Status__c, Case__c, Case__r.AKAM_Case_ID__c, Value__c, Handler__c, Policy_Domain__c, Escalation_List__c, Handler__r.Name, Policy_Domain__r.Name, Escalation_List__r.Name, Handler__r.Situation_Instruction__c, Handler__r.Ignore_Condition__c, Policy_Domain__r.Special_Instructions__c, Escalation_List__r.Instructions__c,Handler__r.Escalation_List__c FROM Instruction__c 
                                WHERE (Policy_Domain__c =:pdId OR  Handler__r.Policy_Domain__c =:pdId OR Escalation_List__r.Policy_Domain__c =:pdId)
                                AND CreatedById =:UserInfo.getUserId() AND Status__c='In Progress' ORDER BY CreatedDate DESC];
        }
        else{
            if(isShiftManager)
                lInstruction = [SELECT Id, Name, CreatedById, CreatedBy.Name, Instructions_Type__c, Status__c, Case__c, Case__r.AKAM_Case_ID__c, Value__c, Handler__c, Policy_Domain__c, Escalation_List__c, Handler__r.Name, Policy_Domain__r.Name, Escalation_List__r.Name, Handler__r.Situation_Instruction__c, Handler__r.Ignore_Condition__c, Policy_Domain__r.Special_Instructions__c, Escalation_List__r.Instructions__c,Handler__r.Escalation_List__c FROM Instruction__c 
                                WHERE Status__c='In Progress' ORDER BY CreatedDate DESC];
            else
                lInstruction = [SELECT Id, Name, CreatedById, CreatedBy.Name, Instructions_Type__c, Status__c, Case__c, Case__r.AKAM_Case_ID__c, Value__c, Handler__c, Policy_Domain__c, Escalation_List__c, Handler__r.Name, Policy_Domain__r.Name, Escalation_List__r.Name, Handler__r.Situation_Instruction__c, Handler__r.Ignore_Condition__c, Policy_Domain__r.Special_Instructions__c, Escalation_List__r.Instructions__c,Handler__r.Escalation_List__c FROM Instruction__c 
                                WHERE CreatedById =:UserInfo.getUserId() AND Status__c='In Progress' ORDER BY CreatedDate DESC];
        }
        
        System.debug('----------- inside getLInstructions start');
        //Map<Id,List<SC_SOCC_Situation_to_Handler_Mapping__c>> mapHIdS2HMapping=new Map<Id,List<SC_SOCC_Situation_to_Handler_Mapping__c>>();
        
        //Stores list of Approval records to be returned
        List<InstructionWrapper> lInstructionWrapper = new List<InstructionWrapper>();
        for(Instruction__c eachRec : lInstruction){
            InstructionWrapper instructionWrapper = new InstructionWrapper();
            instructionWrapper.id = eachRec.Id;
            instructionWrapper.name = eachRec.Name;
            instructionWrapper.instructionsType = eachRec.Instructions_Type__c;
            instructionWrapper.status = eachRec.Status__c;
            instructionWrapper.value = eachRec.Value__c;
            instructionWrapper.createdBy = eachRec.CreatedBy.Name;
            instructionWrapper.caseId = '/' + eachRec.Case__c;
            instructionWrapper.akamCaseId = eachRec.Case__r.AKAM_Case_ID__c;
            
            instructionWrapper.handler = eachRec.Handler__c;
            instructionWrapper.handlerName = eachRec.Handler__r.Name;
            instructionWrapper.situationInstruction = eachRec.Handler__r.Situation_Instruction__c;
            instructionWrapper.ignoreCondition = eachRec.Handler__r.Ignore_Condition__c;
            instructionWrapper.policyDomain = eachRec.Policy_Domain__c;
            instructionWrapper.policyDomainName = eachRec.Policy_Domain__r.Name;
            instructionWrapper.specialInstructions = eachRec.Policy_Domain__r.Special_Instructions__c;
            instructionWrapper.escalationList = eachRec.Escalation_List__c;
            instructionWrapper.escalationListName = eachRec.Escalation_List__r.Name;
            instructionWrapper.escalationInstructions = eachRec.Escalation_List__r.Instructions__c;
            //Changes by Tejaswini for ESESP-4822
            instructionWrapper.escListId=eachRec.Handler__r.Escalation_List__c;
            instructionWrapper.caseIdWithoutSpecialChar =eachRec.Case__c;
            
            if(eachRec.CreatedById == UserInfo.getUserId())
            {
                instructionWrapper.isOwner = true;
            }
            else{
                instructionWrapper.isOwner = false;
            }
                
            //setting object type
            if(!String.isBlank(eachRec.Handler__c)){
                instructionWrapper.objectType = 'Handler';
                instructionWrapper.objectId = '/' + eachRec.Handler__c;
                instructionWrapper.objectName = eachRec.Handler__r.Name;
            }
            else if(!String.isBlank(eachRec.Policy_Domain__c)){
                instructionWrapper.objectType = 'Policy Domain';
                instructionWrapper.objectId = '/' + eachRec.Policy_Domain__c;
                instructionWrapper.objectName = eachRec.Policy_Domain__r.Name;
            }
            else if(!String.isBlank(eachRec.Escalation_List__c)){
                instructionWrapper.objectType = 'Escalation List';
                instructionWrapper.objectId = '/' + eachRec.Escalation_List__c;
                instructionWrapper.objectName = eachRec.Escalation_List__r.Name;
            }
            
            
            lInstructionWrapper.add(instructionWrapper);
        }
        
        
        System.debug('----------- inside getLInstructions end ');
        System.debug('----------- lInstructionWrapper : '+ lInstructionWrapper);
        return lInstructionWrapper;
    }
    
    //Approve instruction
    @AuraEnabled
    public static List<InstructionWrapper> approveInstruction(String pdId, String instructionRecJSON, Boolean isShiftManager, Boolean isSSP,String comment){
        InstructionWrapper instructionRec = (InstructionWrapper) System.JSON.deserializeStrict(instructionRecJSON, InstructionWrapper.Class);
        System.debug('----------- instructionRec : '+ instructionRec);
        System.debug('---------the comment is'+comment);
        //Check if the status of the instruction approval records has been changed
        Instruction__c latestInstructionRec = [SELECT Id, Status__c,Comments__c,Case__c FROM Instruction__c WHERE Id =:instructionRec.id LIMIT 1];
        if(!latestInstructionRec.Status__c.equals('In Progress'))
            throw new AuraHandledException('This request has already been ' + latestInstructionRec.Status__c + '. Please refresh the page.');
        
        //Update the corresponding instruction on the parent object
        if(instructionRec.instructionsType.equalsIgnoreCase('Situation Instruction')){
            try{
                
                Handler__c handler = new Handler__c(Id=instructionRec.handler, Situation_Instruction__c=instructionRec.value);
                update handler;
              
            }catch(Exception e){
                System.debug('----------- e.getMessage() : '+ e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
        else if(instructionRec.instructionsType.equalsIgnoreCase('Ignore Condition')){
            try{
                Handler__c handler = new Handler__c(Id=instructionRec.handler, Ignore_Condition__c=instructionRec.value);
                update handler;
            }catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        }
        else if(instructionRec.instructionsType.equalsIgnoreCase('Policy Domain Instruction')){
            try{    
                Policy_Domain__c policyDomain = new Policy_Domain__c(Id=instructionRec.policyDomain, Special_Instructions__c=instructionRec.value);
                update policyDomain;
            }catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        }
        else if(instructionRec.instructionsType.equalsIgnoreCase('Escalation List Instruction')){
            try{
                SC_SOCC_Escalation_List__c escalationList = new SC_SOCC_Escalation_List__c(Id=instructionRec.escalationList, Instructions__c=instructionRec.value);
                update escalationList;
            }catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        }
        //Changes by Tejaswini for ESESP-4822
        //Update the Instruction record status
        Instruction__c instruction = new Instruction__c();
        instruction.Id = instructionRec.id;
        instruction.Status__c = 'Approved';
        if(comment.length()>0)
        	instruction.Comments__c= comment;
        
        //Id caseId=latestInstructionRec.Case__c;
        System.debug('------Case Id is '+latestInstructionRec.Case__c);
        /* 
         Case c=[Select Id,Description from Case Where Id=:latestInstructionRec.Case__c LIMIT 1];
		 if(comment.length()>0)
        	c.Description = c.Description + '\n'+ 'Approval Comments: ' + comment;
         c.Validation_Override__c = true;
		*/
        //List<Case> lc= [Select Id,Description from Case Where Id=:latestInstructionRec.Case__c ];
        List<Case> lUpdatedCase=new List<Case>();
        for(Case c:[Select Id,Living_Summary_Next_Steps__c from Case Where Id=:latestInstructionRec.Case__c ]){
            if(comment.length()>0){
                if(c.Living_Summary_Next_Steps__c == null){
                    c.Living_Summary_Next_Steps__c = 'Approval Comments: ' + '<br/>'+comment+'<br/>';
                }
                else
                    c.Living_Summary_Next_Steps__c = c.Living_Summary_Next_Steps__c + 'Approval Comments: ' + '<br/>'+comment+'<br/>';
            }
        		
            c.Validation_Override__c = true;
            lUpdatedCase.add(c);
        }
        try{
            update instruction;
            if(lUpdatedCase.size()>0)
            update lUpdatedCase;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        System.debug('----------- before return');
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager,isSSP);
    }
    
    
    //Reject instruction
    @AuraEnabled
    public static List<InstructionWrapper> rejectInstruction(String pdId, String instructionRecJSON, Boolean isShiftManager, Boolean isSSP, String comment){
        InstructionWrapper instructionRec = (InstructionWrapper) System.JSON.deserializeStrict(instructionRecJSON, InstructionWrapper.Class);
        
        //Check if the status of the instruction approval records has been changed
        Instruction__c latestInstructionRec = [SELECT Id, Status__c,Comments__c,Case__c FROM Instruction__c WHERE Id =:instructionRec.id LIMIT 1];
        if(!latestInstructionRec.Status__c.equals('In Progress'))
            throw new AuraHandledException('This request has already been ' + latestInstructionRec.Status__c + '. Please refresh the page.');
        
        //Changes by Tejaswini for ESESP-4822
        List<Case> lUpdatedCase=new List<Case>();
        for(Case c:[Select Id,Living_Summary_Next_Steps__c from Case Where Id=:latestInstructionRec.Case__c ]){
            if(comment.length()>0){
                if(c.Living_Summary_Next_Steps__c == null){
                    c.Living_Summary_Next_Steps__c = 'Rejection Comments: ' + '<br/>'+comment+'<br/>';
                }
                else
                    c.Living_Summary_Next_Steps__c = c.Living_Summary_Next_Steps__c + 'Rejection Comments: ' + '<br/>'+comment+'<br/>';
            }
            c.Validation_Override__c = true;
            lUpdatedCase.add(c);
        }
        try{
            //Update the Instruction record status
            Instruction__c instruction = new Instruction__c();
            instruction.Id = instructionRec.id;
            instruction.Status__c = 'Rejected';
            if(comment.length()>0)
            	instruction.Comments__c = comment;
            update instruction;
            
            /*Case c= [Select Id,Description from Case Where Id=:latestInstructionRec.Case__c LIMIT 1];
            if(comment.length()>0)
            	c.Description=c.Description +'\n'+'Reject Comments :' + comment;
            c.Validation_Override__c = true;
            update c;*/
            if(lUpdatedCase.size()>0)
            update lUpdatedCase;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        System.debug('----------- before return');
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager,isSSP);
        
    }
    
    //Save Edited instruction 
    @AuraEnabled
    public static List<InstructionWrapper> saveEditedInstruction(String pdId, String instructionRecJSON, Boolean isShiftManager, Boolean isSSP){
        InstructionWrapper instructionRec = (InstructionWrapper) System.JSON.deserializeStrict(instructionRecJSON, InstructionWrapper.Class);
        
        //Check if the status of the instruction approval records has been changed
        Instruction__c latestInstructionRec = [SELECT Id, Status__c FROM Instruction__c WHERE Id =:instructionRec.id LIMIT 1];
        if(!latestInstructionRec.Status__c.equals('In Progress'))
            throw new AuraHandledException('This request has already been ' + latestInstructionRec.Status__c + '. Please refresh the page.');
        
        try{
            //Update the Instruction record status
            Instruction__c instruction = new Instruction__c();
            instruction.Id = instructionRec.id;
            instruction.Value__c = instructionRec.value;
            update instruction;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager, isSSP);
    }
    
    //Revoke instruction 
    @AuraEnabled
    public static List<InstructionWrapper> revokeInstruction(String pdId, String instructionRecJSON, Boolean isShiftManager, Boolean isSSP){
        InstructionWrapper instructionRec = (InstructionWrapper) System.JSON.deserializeStrict(instructionRecJSON, InstructionWrapper.Class);
        
        //Check if the status of the instruction approval records has been changed
        Instruction__c latestInstructionRec = [SELECT Id, Status__c FROM Instruction__c WHERE Id =:instructionRec.id LIMIT 1];
        if(!latestInstructionRec.Status__c.equals('In Progress'))
            throw new AuraHandledException('This request has already been ' + latestInstructionRec.Status__c + '. Please refresh the page.');
        
        try{
            //Update the Instruction record status
            Instruction__c instruction = new Instruction__c();
            instruction.Id = instructionRec.id;
            instruction.Status__c = 'Revoked';
            update instruction;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        System.debug('----------- before return');
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager, isSSP);
        
    }
    
    //check if user if a shift manager or not
    public static Boolean checkIfShiftManager(){
        /*SC_SOC_Passphrase_Access__mdt metadataRec = [SELECT Id, DeveloperName, User_Title_text__c, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName = 'Shift_Managers' limit 1];
        Set<String> sUserTitle = new Set<String>();
        Set<String> sProfile = new Set<String>();
        sUserTitle.addAll(metadataRec.User_Title_text__c.split(','));
        sProfile.addAll(metadataRec.Profile_ID_Text__c.split(','));
        
        user currentUserTitle = [SELECT Id, Title, Profile.Name FROM User where Id =:UserInfo.getUserId() limit 1];
        
        
        if(sUserTitle.contains(currentUserTitle.Title) ||  sProfile.contains(currentUserTitle.Profile.Name))
            return true;
        else
            return false;*/

        Set<String> sUserTitle = new Set<String>();
        Set<String> sProfile = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt metadataRec : [SELECT Id, DeveloperName, User_Title_text__c, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Shift_Managers_For_Instructions_%']) {
            if(String.isNotBlank(metadataRec.User_Title_text__c))
                sUserTitle.addAll(metadataRec.User_Title_text__c.split(','));
            if(String.isNotBlank(metadataRec.Profile_ID_Text__c))
                sProfile.addAll(metadataRec.Profile_ID_Text__c.split(','));
        }
        
        user currentUserTitle = [SELECT Id, Title, Profile.Name FROM User where Id =:UserInfo.getUserId() limit 1];
        
        
        if(sUserTitle.contains(currentUserTitle.Title) ||  sProfile.contains(currentUserTitle.Profile.Name))
            return true;
        else
            return false;
    }

    //check if user if a shift manager or not for deleting Situation to Handler Mapping
    public static Boolean checkIfShiftManagerForS2HMapping(){
        Set<String> sUserTitle = new Set<String>();
        Set<String> sProfile = new Set<String>();
        for(SC_SOC_Passphrase_Access__mdt metadataRec : [SELECT Id, DeveloperName, User_Title_text__c, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName LIKE 'Shift_Managers_S2H_mapping_deletion_%']) {
            if(String.isNotBlank(metadataRec.User_Title_text__c))
                sUserTitle.addAll(metadataRec.User_Title_text__c.split(','));
            if(String.isNotBlank(metadataRec.Profile_ID_Text__c))
                sProfile.addAll(metadataRec.Profile_ID_Text__c.split(','));
        }
        
        user currentUserTitle = [SELECT Id, Title, Profile.Name FROM User where Id =:UserInfo.getUserId() limit 1];
        
        
        if(sUserTitle.contains(currentUserTitle.Title) ||  sProfile.contains(currentUserTitle.Profile.Name))
            return true;
        else
            return false;
    }
    
    //get Lightning base URL
    public static String getLightningBaseURL(){
        SC_Utility__mdt scUtility = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = TRUE AND DeveloperName = 'Lightning_Base_URL' limit 1];
        return scUtility.Value_Text__c;
    }
    
    //Check if any instructions pending for approval on a PD
    @AuraEnabled
    public static void checkPendingInstructionForPD(String pdId){
        List<Instruction__c> lExistingInstruction = [SELECT Id, CreatedBy.Name FROM Instruction__c WHERE Policy_Domain__c =:pdId AND Status__c = 'In Progress' LIMIT 1];
        if(lExistingInstruction.size()>0)
            throw new AuraHandledException('There already exists a pending instruction submitted by ' + lExistingInstruction[0].CreatedBy.Name + '. Please contact him/her for further details.');
    }
    
    //Submit Policy Domain Special Instruction for approval
    @AuraEnabled
    public static void submitInstructionForPD(String pdId, String suggestedInstruction){
        Map<String, String> mInstructionTypeValue = new Map<String, String>();
        if(suggestedInstruction!=null)
        { string Instwithouthtml = suggestedInstruction.replaceAll('<[^>]+>','').replaceAll(' ','');
         if(Instwithouthtml.length()>0) 
         {
             mInstructionTypeValue.put('Policy Domain Instruction', suggestedInstruction);
             SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdId, pdId, mInstructionTypeValue);
         }
         else
         {
            throw new AuraHandledException('Please type in an instruction!');
         }
        }
    }
    
    //Check if latest status of the instruction approval records changed or not
    @AuraEnabled
    public static List<Instruction__c> getChangedBulkInstructions(String lInstructionRecJSON){
        List<InstructionWrapper> lInstructionRec = (List<InstructionWrapper>) System.JSON.deserializeStrict(lInstructionRecJSON, List<InstructionWrapper>.Class);
        List<Id> lInstructionId = new List<Id>();
        
        for(InstructionWrapper eachRec : lInstructionRec)
            lInstructionId.add(eachRec.id);
        
        List<Instruction__c> lLatestInstructionRec = [SELECT Id, Name, Status__c FROM Instruction__c WHERE Id IN :lInstructionId AND Status__c != 'In Progress' ORDER BY CreatedDate DESC];
        return lLatestInstructionRec;
        
        
    }
    
    //Bulk Approve Instructions
    @AuraEnabled
    public static List<InstructionWrapper> bulkApproveInstruction(String pdId, String lInstructionRecJSON, Boolean isShiftManager, Boolean isSSP,String comment){
        List<InstructionWrapper> lInstructionRec = (List<InstructionWrapper>) System.JSON.deserializeStrict(lInstructionRecJSON, List<InstructionWrapper>.Class);
        
        //List of records to be updated
        List<Handler__c> lHandler = new List<Handler__c>();
        Map<Id, Handler__c> mHandler = new Map<Id, Handler__c>();
        List<Policy_Domain__c> lPolicyDomain = new List<Policy_Domain__c>();
        List<SC_SOCC_Escalation_List__c> lEscalationList = new List<SC_SOCC_Escalation_List__c>();
        List<Instruction__c> lInstruction = new List<Instruction__c>();
        List<Case> lCase=new List<Case>();
        List<Id> lCaseId=new List<Id>();
        for(InstructionWrapper eachrec : lInstructionRec){
            //String ccId=eachrec.caseId;
            //List<String> listcaseId = ccId.split('/');
            
            //System.debug('-------The case Id is'+listcaseId.get(1));
            //Id finalId=
            //lCaseId.add(listcaseId.get(1));
            lCaseId.add(eachrec.caseIdWithoutSpecialChar);
            //updating instructions on parent records
            if(eachrec.instructionsType.equalsIgnoreCase('Situation Instruction')){
                if(mHandler.get(eachrec.handler) == null){
                    Handler__c handler = new Handler__c(Id=eachrec.handler, Situation_Instruction__c=eachrec.value);
                    mHandler.put(eachrec.handler, handler);
                    lHandler.add(handler);
                }
                else{
                    Handler__c handler = mHandler.get(eachrec.handler);
                    handler.Situation_Instruction__c = eachrec.value;
                    mHandler.put(eachrec.handler, handler);
                }
            }
            else if(eachrec.instructionsType.equalsIgnoreCase('Ignore Condition')){
                if(mHandler.get(eachrec.handler) == null){
                    Handler__c handler = new Handler__c(Id=eachrec.handler, Ignore_Condition__c=eachrec.value);
                    mHandler.put(eachrec.handler, handler);
                    lHandler.add(handler);
                }
                else{
                    Handler__c handler = mHandler.get(eachrec.handler);
                    handler.Ignore_Condition__c = eachrec.value;
                    mHandler.put(eachrec.handler, handler);
                }
            }
            else if(eachrec.instructionsType.equalsIgnoreCase('Policy Domain Instruction')){
                Policy_Domain__c pd = new Policy_Domain__c(Id=eachrec.policyDomain, Special_Instructions__c=eachrec.value);
                lPolicyDomain.add(pd);
            }
            else{
                SC_SOCC_Escalation_List__c el = new SC_SOCC_Escalation_List__c(Id=eachrec.escalationList, Instructions__c=eachrec.value);
                lEscalationList.add(el);
            }
            
            //updating Instruction record status to approved
            Instruction__c instruction = new Instruction__c(Id=eachrec.id, Status__c = 'Approved',Comments__c= comment);
            lInstruction.add(instruction);
            
            //Instruction__c latestInstructionRec = [SELECT Id, Case__c FROM Instruction__c WHERE Id =:eachrec.id LIMIT 1];
            
            
        }
        //Changes by Tejaswini for ESESP-4822
        Set<Case> setCase=new Set<Case>();
        List<Case> listCase= [Select Id,Living_Summary_Next_Steps__c from Case Where Id=:lCaseId];
        for(Case eachCase:listCase)
        {
            System.debug('------2 case id is'+eachCase.Id);
            if(comment.length()>0){
                if(eachCase.Living_Summary_Next_Steps__c == null){
                    eachCase.Living_Summary_Next_Steps__c = 'Approval Comments: ' + '<br/>'+ comment+ '<br/>';
                }
                else
                    eachCase.Living_Summary_Next_Steps__c = eachCase.Living_Summary_Next_Steps__c + 'Approval Comments: ' + '<br/>'+ comment+ '<br/>';
            }
            
            eachCase.Validation_Override__c = true;
            setCase.add(eachCase);
        }
        lCase.addAll(setCase);   
           
        try{
            if(lHandler.size()>0)
                update lHandler;
            if(lPolicyDomain.size()>0)
                update lPolicyDomain;
            if(lEscalationList.size()>0)
                update lEscalationList;
            if(lInstruction.size()>0)
                update lInstruction;
            if(lCase.size()>0)
                update lCase;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager, isSSP);
    }
    
    //Bulk Reject Instructions
    @AuraEnabled
    public static List<InstructionWrapper> bulkRejectInstruction(String pdId, String lInstructionRecJSON, Boolean isShiftManager, Boolean isSSP,String comment){
        List<InstructionWrapper> lInstructionRec = (List<InstructionWrapper>) System.JSON.deserializeStrict(lInstructionRecJSON, List<InstructionWrapper>.Class);
        
        //List of records to be updated
        List<Instruction__c> lInstruction = new List<Instruction__c>();
        List<Case> lCase = new List<Case>();
        List<Id> lCaseId=new List<Id>();
        
        for(InstructionWrapper eachrec : lInstructionRec){
            lCaseId.add(eachrec.caseIdWithoutSpecialChar);
            
            //updating Instruction record status 
            Instruction__c instruction = new Instruction__c(Id=eachrec.id, Status__c = 'Rejected', Comments__c = comment);
            lInstruction.add(instruction);
                 
        }
        //Changes by Tejaswini for ESESP-4822
        Set<Case> setCase=new Set<Case>();
        List<Case> listCase= [Select Id,Living_Summary_Next_Steps__c from Case Where Id=:lCaseId];
        for(Case eachCase:listCase)
        {
            System.debug('------2 case id is'+eachCase.Id);
            //Case c=new Case();
            //c.Id=eachCase.Id;
            //c.Description=eachCase.Description +'\n'+'Approve Comments :' + comment;
            //c.Validation_Override__c = true;
            //setCase.add(c);
            if(comment.length()>0){
                if(eachCase.Living_Summary_Next_Steps__c == null){
                    eachCase.Living_Summary_Next_Steps__c = 'Rejection Comments: ' + '<br/>'+ comment+ '<br/>';
                }
                else
                    eachCase.Living_Summary_Next_Steps__c = eachCase.Living_Summary_Next_Steps__c + 'Rejection Comments: ' + '<br/>'+ comment+ '<br/>';
            }
            eachCase.Validation_Override__c = true;
            setCase.add(eachCase);
        }
        lCase.addAll(setCase); 
        
        try{
            if(lInstruction.size()>0)
                update lInstruction;
            if(lCase.size()>0)
                update lCase;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager, isSSP);
    }
    
    //Bulk Revoke Instructions
    @AuraEnabled
    public static List<InstructionWrapper> bulkRevokeInstruction(String pdId, String lInstructionRecJSON, Boolean isShiftManager, Boolean isSSP){
        List<InstructionWrapper> lInstructionRec = (List<InstructionWrapper>) System.JSON.deserializeStrict(lInstructionRecJSON, List<InstructionWrapper>.Class);
        
        //List of records to be updated
        List<Instruction__c> lInstruction = new List<Instruction__c>();
        
        for(InstructionWrapper eachrec : lInstructionRec){
            //updating Instruction record status 
            Instruction__c instruction = new Instruction__c(Id=eachrec.id, Status__c = 'Revoked');
            lInstruction.add(instruction);
        }
        
        try{
            if(lInstruction.size()>0)
                update lInstruction;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        //returning latest list of approval records
        return getLInstructions(pdId, isShiftManager, isSSP);
    }
    
}