//Created by mayank Bansal as part of MARIT-418
//This code will pick historic Lead or Contacts as well as Leads or Contacts got updated in last certain hours 
//with Matching Reported Account and will reassign those Leads/Contacts to new Accounts
global class LeanDataUpdateContactWithMatchedAcc implements Database.Batchable<sObject>, Database.Stateful {
	
	global static List<String> listOfMDT = new List<String>();
    global static Map<String, LeanData__mdt> fetchRequiredMDTs = new Map<String, LeanData__mdt>();
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        listOfMDT.add('Automated_Lean_Data_Account_for_Contact');
      	listOfMDT.add('WWWLeadGenAccountId');
        listOfMDT.add('LeanDataUpdateContactWMatchedAcBatchSize');
        fetchRequiredMDTs = MarketingUtilClass.getLeanDataValueForMultiples(listOfMDT);

        String batchSize = fetchRequiredMDTs.get('LeanDataUpdateContactWMatchedAcBatchSize').Value__c;
        object  intBatchSize = Integer.valueOf(batchSize);
        System.debug(intBatchSize instanceof integer);  
        String query;
        
        //MARIT-633 pmalhotr moved batch size to custom metadata and job running condition based on reporting
        //matched account status
        //MARIT-919 added LeanData_Account_Match_Source__c logic 
        if((fetchRequiredMDTs.get('Automated_Lean_Data_Account_for_Contact').ToBeChecked__c  == true && fetchRequiredMDTs.get('Automated_Lean_Data_Account_for_Contact').Reporting_Matched_Account_Status__c != null)|| Test.isRunningTest()){
            if(fetchRequiredMDTs.get('Automated_Lean_Data_Account_for_Contact').Reporting_Matched_Account_Status__c == 'Account Status CONTAINS "Lead"'){
                query = 'Select id, LeanData_Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, AccountId from Contact where LeanData_Reporting_Matched_Account__c != null and LeanData_Reporting_Matched_Account__r.Type like \'%Lead%\' and (AccountId = null OR AccountId =\''+ fetchRequiredMDTs.get('WWWLeadGenAccountId').Value__c +'\') order by CreatedDate desc limit '+ intBatchSize;
                return Database.getQueryLocator(query);
            } else if(fetchRequiredMDTs.get('Automated_Lean_Data_Account_for_Contact').Reporting_Matched_Account_Status__c == 'Account Status CONTAINS "LEAD" OR Account Status CONTAINS "Inactive"'){
                query = 'Select id, LeanData_Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, AccountId from Contact where LeanData_Reporting_Matched_Account__c != null and (LeanData_Reporting_Matched_Account__r.Type like \'%Lead%\' OR LeanData_Reporting_Matched_Account__r.Type like \'%Inactive%\') and (AccountId = null OR AccountId =\''+ fetchRequiredMDTs.get('WWWLeadGenAccountId').Value__c +'\') order by CreatedDate desc limit '+ intBatchSize;
                return Database.getQueryLocator(query);
            }else {
                query = 'Select id, LeanData_Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, AccountId from Contact where LeanData_Reporting_Matched_Account__c != null and (AccountId = null OR AccountId = \''+ fetchRequiredMDTs.get('WWWLeadGenAccountId').Value__c + '\') order by CreatedDate desc limit ' + intBatchSize;
                return Database.getQueryLocator(query);
            }
        }
        else
            return Database.getQueryLocator([Select id, LeanData_Reporting_Matched_Account__c, LeanData_Account_Match_Source__c, AccountId from Contact limit 0]);
    }

    global void execute(Database.BatchableContext bc,List<Contact> scope){
        List<Contact> contactsToUpdate = new List<Contact>();
    	for(Contact con : scope){
            if(con.LeanData_Reporting_Matched_Account__c != con.AccountId){
                //Change Contact's Account
                //MARIT-919 added LeanData_Account_Match_Source__c logic 
                con.AccountId = con.LeanData_Reporting_Matched_Account__c;
                con.LeanData_Account_Match_Source__c = 'LeanData Account Match - Automation';
                contactsToUpdate.add(con);
            }
         }
        
        if(contactsToUpdate.size() > 0){
            Database.update(contactsToUpdate,false);
        }
    }

    global void finish(Database.BatchableContext BC){   
    }
}