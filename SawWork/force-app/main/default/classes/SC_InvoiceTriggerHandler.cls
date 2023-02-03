/*=============================================================================================================+  
SC_InvoiceTriggerHandler
@version 1.0
@author :Bhavesh Kumar
@Description : This class is used by SC team, and it is called from Invoice_ai_au trigger.
The following functionality is implemented :
- create a billing case when invoice is created and invoice's contract.delivery method = OIS or OIS/Email

@History
--Developer         --Date          --Change
Bhavesh Kumar       22/05/2021      Created the class Jira:ESESP-4094.
Harshil             28/04/2022      Populate Invoice:Original Amount on Case Creation:ESESP-6511
+=============================================================================================================*/

public class SC_InvoiceTriggerHandler {
    public SC_InvoiceTriggerHandler() {

    }

    public static void createBillingCaseForInvoice( List<Invoice__c> newList ){
        Map< Id, List<Id>> contractIdWithInvoiceList = new Map<Id, List<Id>>();
        Map<Id, Id> accIdWithATMid = new Map<Id, Id>();
        List<Id> accIdList = new List<Id>();
        Id billingRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
        List<Case> billingCaseList = new List<Case>();
        Map<Id, String> accIdWithAccCountryMap = new Map<Id, String>();
        Map<String, String> countryWithCountryCode = new Map<String, String>();
		
        for(Invoice__c inv : [Select Id,Account_Name__c,Original_Contract_Id__c, Name,Account_Name__r.Support_Level__c, CurrencyIsoCode, 
                                Account_Name__r.TERR_HIER_2__c, Account_Name__r.Customer_Tier__c,Account_Name__r.TERR_HIER_5__c, Original_Amount__c ,
                                Account_Name__r.Name, Account_Name__r.Akam_Account_Id__c, Original_Contract_Id__r.name, Account_Name__r.BillingCountry	
                              	from Invoice__c 
                                where ( Original_Contract_Id__r.Delivery_Method__c = 'OIS' OR Original_Contract_Id__r.Delivery_Method__c = 'OIS/EMAIL' )
                                        AND Id IN: newList]){
            if( inv.Account_Name__c != null ){
            	accIdList.add( inv.Account_Name__c );
                Case cs = new Case();
                cs.CurrencyIsoCode = inv.CurrencyIsoCode;
                cs.Submitted_Amount__c = inv.Original_Amount__c;
                cs.recordtypeId = billingRT;
                cs.AccountId = inv.Account_Name__c;
                cs.Support_Level__c = inv.Account_Name__r.Support_Level__c;
                cs.Region__c = inv.Account_Name__r.TERR_HIER_2__c;
                cs.Customer_Tier__c = inv.Account_Name__r.Customer_Tier__c;
                cs.Territory__c = inv.Account_Name__r.TERR_HIER_5__c;
                cs.Severity__c = '3';
                cs.Do_Not_Show_in_Portal__c = true;
                cs.Origin = 'Email';
                cs.Service__c = 'OIS';
                cs.Invoice__c = inv.Id;
                cs.Subject = inv.Account_Name__r.Name+'_'+inv.Account_Name__r.Akam_Account_Id__c+'_'+inv.Original_Contract_Id__r.name +'_'+ inv.Name + '_OIS Submission';
                cs.Description = inv.Account_Name__r.Name+'_'+inv.Account_Name__r.Akam_Account_Id__c+'_'+inv.Original_Contract_Id__r.name +'_'+ inv.Name + '_OIS Submission';
                cs.IR_Original_Contract_Id__c = inv.Original_Contract_Id__c;
                cs.Invoice_Original_Amount__c = inv.Original_Amount__c;
                billingCaseList.add(cs);    
                accIdWithAccCountryMap.put(inv.Account_Name__c, inv.Account_Name__r.BillingCountry);
            }
            

        }

        if (billingCaseList.size() > 0){
            for(CoutryISOList__mdt cntry : [select Country_ISO2__c, MasterLabel from CoutryISOList__mdt where MasterLabel in :accIdWithAccCountryMap.values()])
            {
                countryWithCountryCode.put(cntry.MasterLabel, cntry.Country_ISO2__c);
            }
            Id queueId = [select Id from Group WHERE  Type = 'Queue' AND Name = 'Billing Queue'].Id;
            for( AccountTeamMember atm : [Select Id, UserId, AccountId  
                                          	FROM AccountTeamMember 
                                          		WHERE AccountId in : accIdList 
                                          		AND TeamMemberRole = 'Billing Analyst' ]){
                accIdWithATMid.put( atm.AccountId , atm.UserId);
            }
            for( Case cs : billingCaseList) {
                if( accIdWithATMid.containsKey (cs.AccountId) ){
                    cs.OwnerId = accIdWithATMid.get(cs.AccountId);
                    cs.Status = 'Assigned';
                } else {
                    cs.OwnerId = queueId;
                    cs.Status = 'Unassigned';
                }
                String sub = cs.Subject;
                String countryCode = accIdWithAccCountryMap.get(cs.AccountId);
                if( countryCode!= null && countryWithCountryCode.containsKey(countryCode)){
                    cs.Subject = countryWithCountryCode.get(countryCode) +'_'+ sub;
                } else {
                    cs.Subject = sub;
                }
                cs.Description = cs.Subject;
            }
            try{
                insert billingCaseList;
            } catch(exception e ){
                
            }

        }
        
    }
}