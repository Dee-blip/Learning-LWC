/* History:
 * =========================
 * @author  Shiva Ganesan,  12th October 2018  
 SFDC-3684 
 */
 // Check for diff contract and accounts type
 // check if revenue alligned goes back to false

global class RevenueAlignmentUpdateContractToAccount implements Database.Batchable<sObject>, Database.Stateful
{
	
	global String query;
    global DMLResults results;
    global Datetime currentDayLessOne;
	
	global RevenueAlignmentUpdateContractToAccount() 
	{
		currentDayLessOne = Datetime.now().addDays(-1);
		Cron_Batch_Job__c batchJob = [Select id, Completed__c from Cron_Batch_Job__c where Batch_Job_Type__c  = 'Revenue Alignment Update Contract To Account' order by CreatedDate desc limit 1];
		query = 'Select Id,Original_Contract_Id__c,Account_Name__c from Merge_Contract_Header__c where Revenue_Aligned__c = true ';
		if(batchJob.Completed__c != 0){
				query = query + ' and LastModifiedDate > :currentDayLessOne';
			}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		results= new DMLResults(); 
        results.storeObjectState();

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
		List<Merge_Contract_Header__c> mchList = (List<Merge_Contract_Header__c>)scope;
		Set<Id> accountIDs = new Set<Id>();

		for(Merge_Contract_Header__c eachMCH : mchList)
		{
			accountIDs.add(eachMCH.Account_Name__c);
		}
		List<Account> accountList = [Select id, Rev_Aligned__c from Account where id in :accountIDs and Rev_Aligned__c = false];
		For(Account acc: accountList){
			acc.Rev_Aligned__c = true;
		}
		if(accountList.size() > 0){
			results.add(Database.update(accountList,false),accountList);
		}
	}
	
	global void finish(Database.BatchableContext BC){
	}
	
}