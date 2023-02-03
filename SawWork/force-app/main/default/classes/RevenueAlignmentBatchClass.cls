//SFDC-1367
/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    02/03/2017     Created this Class
    
*/
global class RevenueAlignmentBatchClass implements Database.Batchable<sObject>, Database.Stateful {
	
	final string query;
	global DMLResults results;
	String RevenueAlignmentWaiverUnsetValue;
	
	global RevenueAlignmentBatchClass() {
		RevenueAlignmentWaiverUnsetValue = GsmUtilClass.getGSMSettingValue('RevenueAlignmentWaiverUnsetValue');
		query = 'select id, Revenue_Alignment_Status__c from account where Revenue_Alignment_Status__c!=:RevenueAlignmentWaiverUnsetValue AND Account_Status__c like \'%Inactive\'';
		results= new DMLResults(); 
        results.storeObjectState();
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		List<Account> revenueAlignmentAccounts = (List<Account>)scope;
   		system.debug(LoggingLevel.Error,'revenueAlignmentAccounts: '+revenueAlignmentAccounts);
		List<Merge_Contract_Header__c> mergeContractHeaders = [select  id, Account_Name__c, Effective_End_Date__c from Merge_Contract_Header__c where Effective_End_Date__c <= Today And Account_Name__c IN :revenueAlignmentAccounts order by Effective_End_Date__c DESC];
		system.debug(LoggingLevel.Error,'mergeContractHeaders: '+mergeContractHeaders);
		Map<String,Merge_Contract_Header__c> mapOfAccountToLastContract = new Map<String,Merge_Contract_Header__c>();
		for(Merge_Contract_Header__c mhc: mergeContractHeaders){
			//as the account with status inactive has no active contract, so fetch the contract with last effective end date
			//contract for an account coming first in iteration is last contract
			if(!mapOfAccountToLastContract.containsKey(mhc.Account_Name__c))
				mapOfAccountToLastContract.put(mhc.Account_Name__c,mhc);
		}
		//Iterate over map of account to last contract and if the last contract has expired 13 months before, nullify that account's rev alignment status
		List<Account> changedAccounts = new List<Account>();
		Date today = Date.today();
		for(String acc: mapOfAccountToLastContract.keySet()){
			if(mapOfAccountToLastContract.get(acc).Effective_End_Date__c.monthsBetween(today)>=13){
				Account account = new Account(id=acc,Revenue_Alignment_Status__c=RevenueAlignmentWaiverUnsetValue);
				changedAccounts.add(account);
			}
		}
		system.debug(LoggingLevel.Error,'changedAccounts: '+changedAccounts);
		if(!changedAccounts.isEmpty())
			results.add(Database.update(changedAccounts,false),changedAccounts);

	}
	
	global void finish(Database.BatchableContext BC) {
		results.withJobName('Revenue Alignment Waiver Unset').toAddress(GsmUtilClass.getGSMSettingValue('RevenueAlignmentWaiverEmailLogToAddress')).sendLogMail();
	}	
	
}