/**
 * Name             : IndirectCustomerPopupController
 * Created By       : Satyanarayan choudhary
 * Created Date     : 15-July-2013
 * Purpose          : popup functionalty to select Indirect Customer for Case. 
 */

public with sharing class IndirectCustomerPopupController {
    
    public Boolean closeWin { get; set;}
    public List<Merge_Contract_Header__c> contractList {get; set;}
    public String indirectCustomerId { get; set; }
    Case sObjCase;
    // constructor
    public IndirectCustomerPopupController(ApexPages.StandardController controller) {
        sObjCase = (Case)controller.getRecord();
        if(sObjCase != null){
            sObjCase = [SELECT Id,AccountId FROM Case WHERE Id =: sObjCase.Id];
            System.debug('<<<< ACT ID ' + sObjCase.AccountId);
            contractList = [SELECT Id, Account_Name__r.Name, Account_Name__r.Account_Status__c, Account_Name__r.Owner.Name, 
                                                         Account_Name__r.BillingStreet, Account_Name__r.BillingCity, Account_Name__r.BillingState,
                                                         Account_Name__r.BillingCountry 
                                            FROM Merge_Contract_Header__c 
                            WHERE Account_Name__c != null 
                                AND Account_Name__r.Account_Status__c = 'Indirect Customer - Active' 
                                And Parent_Account_Name__c =: sObjCase.AccountId  
                                And Effective_End_Date__c >= : Date.today() LIMIT 1000];
        } 
        closeWin = false;       
        
        
    }
    
    // A Method which update Indirecr_Customer__c of Case.
    public PageReference selectIndirectCustomer(){
        
        
        try
        { 
            sObjCase.Indirect_Customer__c = indirectCustomerId;
            update sObjCase;
            closeWin = true;
        }catch(Exception ex){
            ApexPages.addMessages(ex);
            closeWin = false;
        }    
        return null;
    }
    

}