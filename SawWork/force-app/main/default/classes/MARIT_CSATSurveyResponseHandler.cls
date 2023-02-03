public class MARIT_CSATSurveyResponseHandler  extends ApexTriggerHandlerAbstractClass {
    public MARIT_CSATSurveyResponseHandler(){
        
    }
    public override void beforeInsertBeforeUpdateTrigger(){
        List<String> akamCaseList = new List<String>();
        List<String> akamContactList = new List<String>();
        List<String> akamAccountList = new List<String>();
        List<String> userAliasList = new List<String>();
        
        Map<String, Case> akamCaseToCase = new Map<String, Case>();
        Map<String, Account> akamAccountToAccount = new Map<String, Account>();
        Map<String, Contact> akamContactToContact = new Map<String, Contact>();
        Map<String, User> userAliasToUser = new Map<String, User>();
        
        Map<String, CSAT_Survey_Response__c> akamCaseToCSAT = new Map<String, CSAT_Survey_Response__c>();
        Map<String, CSAT_Survey_Response__c> akamContactToCSAT = new Map<String, CSAT_Survey_Response__c>();
        Map<String, CSAT_Survey_Response__c> akamAccountToCSAT = new Map<String, CSAT_Survey_Response__c>();
        Map<String, CSAT_Survey_Response__c> userAliasToCSAT = new Map<String, CSAT_Survey_Response__c>();
        
        for(SObject so: newList){
            
            CSAT_Survey_Response__c csatObj = (CSAT_Survey_Response__c)so;
            //MARIT-1171: CSAT needs to be created in the org the case was closed .. Adding this fix as there is not QA env for Qualtrics
            if(!String.isBlank(csatObj.OrganizationId__c) && csatObj.OrganizationId__c.substring(0, 15) != UserInfo.getOrganizationId().substring(0, 15)){
                csatObj.addError('Case closed on a different org(' + csatObj.OrganizationId__c + ') and CSAT is getting inserted into this org('+UserInfo.getOrganizationId()+')');
            }
            if (csatObj.Case__c == null && (csatObj.AKAM_Case_ID__c != null && csatObj.AKAM_Case_ID__c != '')) {
                akamCaseList.add(csatObj.AKAM_Case_ID__c);
                akamCaseToCSAT.put(csatObj.AKAM_Case_ID__c, csatObj);
            }
            if (csatObj.Account__c == null && (csatObj.AKAM_Account_ID__c != null && csatObj.AKAM_Account_ID__c != '')) {
                akamAccountList.add(csatObj.AKAM_Account_ID__c);
                akamAccountToCSAT.put(csatObj.AKAM_Account_ID__c, csatObj);
            }
            if (csatObj.Contact__c == null && (csatObj.AKAM_Contact_ID__c != null && csatObj.AKAM_Contact_ID__c != '')) {
                akamContactList.add(csatObj.AKAM_Contact_ID__c);
                akamContactToCSAT.put(csatObj.AKAM_Contact_ID__c, csatObj);
            }
            if (Trigger.isInsert) {
                if (csatObj.Case_Owner_Manager_Alias__c != null && csatObj.Case_Owner_Manager_Alias__c != '') {
                    userAliasList.add(csatObj.Case_Owner_Manager_Alias__c.toLowercase());
                    userAliasToCSAT.put(csatObj.Case_Owner_Manager_Alias__c.toLowercase(), csatObj);
                }
            }
        }
        if (!akamCaseList.isEmpty()) {
            List<Case> caseList = MARIT_CSATSurveyTriggerClass.GetCaseObjects(akamCaseList);
            for(Case cObj: caseList) {
                akamCaseToCase.put(cObj.Akam_Case_Id__c, cObj);
            }
        }
        if (!akamAccountList.isEmpty()) {
            List<Account> accList = MARIT_CSATSurveyTriggerClass.GetAccountObjects(akamAccountList);
            for(Account accObj: accList) {
                akamAccountToAccount.put(accObj.AKAM_Account_ID__c, accObj);
            }
        }
        if (!akamContactList.isEmpty()) {
            List<Contact> conList = MARIT_CSATSurveyTriggerClass.GetContactObjects(akamContactList);
            for(Contact conObj: conList) {
                akamContactToContact.put(conObj.AKAM_Contact_ID__c, conObj);
            }
        }
        if (Trigger.isInsert) {
            if (!userAliasList.isEmpty()) {
                List<User> userList = MARIT_CSATSurveyTriggerClass.GetUserObjects(userAliasList);
                for(User userObj: userList) {
                    userAliasToUser.put(userObj.Alias.toLowercase(), userObj);
                }
            }
        }
        for(String akamCaseId : akamCaseToCSAT.keySet()) {
            Case cObj = akamCaseToCase.get(akamCaseId);
            if (cObj != null) {
                akamCaseToCSAT.get(akamCaseId).Case__c = cObj.Id;
                //getting from SF side rather that Qualtrics as SF data is correct
                
                akamCaseToCSAT.get(akamCaseId).Case_Owner__c  = cObj.Case_Owner_Name__c;
                akamCaseToCSAT.get(akamCaseId).Case_Owner_Manager__c  = cObj.Case_Owner_Manager__c;
                akamCaseToCSAT.get(akamCaseId).Case_Owner_Email_address__c  = cObj.Case_Owner_Email_address__c;
                akamCaseToCSAT.get(akamCaseId).Case_Owner_Manager_Email_address__c = cObj.Case_Owner_Manager_Email_address__c;         
            }
        }
        for(String akamAccountId : akamAccountToCSAT.keySet()) {
            Account accObj = akamAccountToAccount.get(akamAccountId);
            if (accObj != null) {
                akamAccountToCSAT.get(akamAccountId).Account__c = accObj.Id;
            }
        }
        for(String akamContactId : akamContactToCSAT.keySet()) {
            Contact conObj = akamContactToContact.get(akamContactId);
            if (conObj != null) {
                akamContactToCSAT.get(akamContactId).Contact__c = conObj.Id;
            }
        }
        if (Trigger.isInsert) {
            for(String userAlias : userAliasToCSAT.keySet()) {
                string aliasLowerCase = userAlias.toLowercase();
                User uObj = userAliasToUser.get(aliasLowerCase);
                if (uObj != null && userAliasToCSAT.get(aliasLowerCase) != null) {
                    userAliasToCSAT.get(aliasLowerCase).FollowUp_Assigned_To__c = uObj.Id;
                }
            }
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    public override void afterInsertAfterUpdateTrigger(){
    }
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}