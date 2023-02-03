public with sharing class FundRequestCustomController {
    
    public List<SFDC_Budget__c> fundBudgetList {get; set;}
    
    public boolean standardUser {get; set;}
     
     public FundRequestCustomController() {
        Id accountId = null;
        this.standardUser = true;
        if (UserInfo.getUserType().equals('PowerPartner')) {
            User currentUser = [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id =: UserInfo.getUserId() ];
            accountId = currentUser.Contact.Account.Id;
       
            this.standardUser = false;
        }
      //  MDF_Configurations__c mdfConfigurations  =GsmUtilClass.getConfigurations();
        String prmMdfSettingValue = GsmUtilClass.getPRMSettingValue('MDF_Fund_Expiring_Alert'); //SFDC-2568
        Integer expiringAlertDays =0;
        if (prmMdfSettingValue != null) {  //SFDC-2568
            expiringAlertDays = Integer.valueOf(prmMdfSettingValue);   //SFDC-2568
        }
        Date expiryDate = System.today().addDays(expiringAlertDays);
        if (accountId != null) {
            this.fundBudgetList = [Select a.Name,a.Fund_Request_Deadline__c, a.Fund_Claim_Deadline__c, a.Available_Budget__c, a.Amount__c, a.Active__c, a.Account__r.Name, a.Account__c From SFDC_Budget__c a where a.Account__c =: accountId and a.Fund_Request_Deadline__c >=: System.today() AND a.Fund_Request_Deadline__c <= : expiryDate order by a.Fund_Request_Deadline__c];
        } else {
            this.fundBudgetList = [Select a.Name,a.Fund_Request_Deadline__c, a.Fund_Claim_Deadline__c, a.Available_Budget__c, a.Amount__c, a.Active__c, a.Account__r.Name, a.Account__c From SFDC_Budget__c a where  a.Fund_Request_Deadline__c >=: System.today() AND a.Fund_Request_Deadline__c <= : expiryDate order by a.Fund_Request_Deadline__c];
        }
        
     }
}