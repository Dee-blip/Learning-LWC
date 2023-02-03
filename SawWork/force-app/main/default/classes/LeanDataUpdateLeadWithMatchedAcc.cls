//Created by mayank Bansal as part of MARIT-418
//This code will pick historic Lead or Contacts as well as Leads or Contacts got updated in last certain hours 
//with Matching Reported Account and will reassign those Leads/Contacts to new Accounts
global class LeanDataUpdateLeadWithMatchedAcc implements Database.Batchable<sObject>, Database.Stateful {
	global static List<String> listOfMDT = new List<String>();
    global static Map<String, LeanData__mdt> fetchRequiredMDTs = new Map<String, LeanData__mdt>();
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
      	listOfMDT.add('Automated_Lean_Data_Account_for_Lead');
        listOfMDT.add('WWWLeadGenAccountId');
        listOfMDT.add('LeanDataUpdateLeadWMatchedAccBatchSize');
        fetchRequiredMDTs = MarketingUtilClass.getLeanDataValueForMultiples(listOfMDT);
        System.debug('Mayank, fetchRequiredMDTs: '+fetchRequiredMDTs);
        String batchSize = fetchRequiredMDTs.get('LeanDataUpdateLeadWMatchedAccBatchSize').Value__c;
        object  intBatchSize = Integer.valueOf(batchSize);
        System.debug(intBatchSize instanceof integer);  
        String query;
        
        if(fetchRequiredMDTs.get('Automated_Lean_Data_Account_for_Lead').ToBeChecked__c  == true || Test.isRunningTest()){
        	//MARIT-634 moved limit of batch to custom metadata
            //MARIT-919 added LeanData_Account_Match_Source__c logic 
            query ='Select id, LeanData__Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, Associated_Account__c from Lead where LeanData__Reporting_Matched_Account__c != null and (Associated_Account__c = null OR Associated_Account__c =\''+fetchRequiredMDTs.get('WWWLeadGenAccountId').Value__c+'\') and Recordtype.Name = \'Marketo Lead\' order by CreatedDate desc limit ' + intBatchSize;
            System.debug('priyanka query: '+ query);
            return Database.getQueryLocator(query);
        } else {
            return Database.getQueryLocator([Select id, LeanData__Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, Associated_Account__c from Lead limit 0]);
        }
   }

    global void execute(Database.BatchableContext bc,List<Lead> scope){
		List<Lead> leadsToUpdate = new List<Lead>();

        for(Lead lead : scope){
            if(lead.LeanData__Reporting_Matched_Account__c != lead.Associated_Account__c){
                //Change Lead's Account
                //MARIT-919 added LeanData_Account_Match_Source__c logic 
                lead.Associated_Account__c = lead.LeanData__Reporting_Matched_Account__c;
                lead.LeanData_Account_Match_Source__c = 'LeanData Account Match - Automation';
                leadsToUpdate.add(lead);
            }
         }
        if(leadsToUpdate.size() > 0){
            Database.update(leadsToUpdate,false);
        }
    }

    global void finish(Database.BatchableContext BC){   
    }
}