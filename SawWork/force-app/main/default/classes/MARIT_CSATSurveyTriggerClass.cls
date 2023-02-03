public without sharing class MARIT_CSATSurveyTriggerClass {
    public static List<Case> GetCaseObjects(List<String> akamCaseIds){
        List<Case> caseObjList = [Select Id, Case_Owner_Name__c,
                                  Case_Owner_Manager__c, Case_Owner_Email_address__c, Case_Owner_Manager_Email_address__c,
                                  Akam_Case_Id__c from Case where Akam_Case_Id__c in :akamCaseIds];
        return caseObjList;
    }
    public static List<Contact> GetContactObjects(List<String> akamContactIds){
        List<Contact> conObjList = [Select Id,Akam_Contact_Id__c from Contact where Akam_Contact_Id__c in :akamContactIds];
        return conObjList;
    }
    public static List<Account> GetAccountObjects(List<String> akamAccountIds){
        List<Account> accObjList = [Select Id,Akam_Account_Id__c from Account where Akam_Account_Id__c in :akamAccountIds];
        return accObjList;
    }
    public static List<User> GetUserObjects(List<String> userAliasList){
        List<User> UObjList = [Select Id, Alias from User where Alias in :userAliasList];
        return UObjList;
    }    
}