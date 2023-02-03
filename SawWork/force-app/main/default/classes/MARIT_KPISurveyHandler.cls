public class MARIT_KPISurveyHandler extends ApexTriggerHandlerAbstractClass {
    public MARIT_KPISurveyHandler(){
        
    }
    public override void beforeInsertBeforeUpdateTrigger(){
       List<String> akamContactList = new List<String>();
       List<String> akamAccountList = new List<String>();
       Map<String, Account> akamAccountToAccount = new Map<String, Account>();
       Map<String, Contact> akamContactToContact = new Map<String, Contact>();
       Map<String, KPI_survey__c> akamContactToCSAT = new Map<String, KPI_survey__c>();
       Map<String, KPI_survey__c> akamAccountToCSAT = new Map<String, KPI_survey__c>();
        
       for(SObject so: newList){
            
            KPI_survey__c csatObj = (KPI_survey__c)so;
            if (csatObj != null && csatObj.Account__c == null && (csatObj.AKAM_Account_ID__c != null && csatObj.AKAM_Account_ID__c != '')) {
                akamAccountList.add(csatObj.AKAM_Account_ID__c);
                akamAccountToCSAT.put(csatObj.AKAM_Account_ID__c, csatObj);
            }
            if (csatObj != null && csatObj.Contact__c == null && (csatObj.AKAM_Contact_ID__c != null && csatObj.AKAM_Contact_ID__c != '')) {
                akamContactList.add(csatObj.AKAM_Contact_ID__c);
                akamContactToCSAT.put(csatObj.AKAM_Contact_ID__c, csatObj);
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
    }     
    
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    public override void afterInsertAfterUpdateTrigger(){
    }
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}