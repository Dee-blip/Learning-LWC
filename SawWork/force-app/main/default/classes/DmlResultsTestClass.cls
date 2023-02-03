/**
   History
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    9/05/2017     Created this Class   SFDC-1572
        
*/

@isTest
public class DmlResultsTestClass {
	static
    {
      utilTestClass.insertCustomSettings();
    }
	@isTest static void DmlResults_test_method_one() {
		DmlResults dmlr = new DmlResults(true);
        dmlr.setStatusMailToAddress('rsharma@akamai.com');
		DMLResults results= new DMLResults(); 
		results.storeObjectState();
		results.clear();
		results.includeSuccess();
		List<Account> accList = new List<Account>();
		for(integer index = 0; index<10;index++){
			Account acc = utilTestClass.CreateAccount(utilTestClass.getRandomString(15));
			accList.add(acc);
			
		}
		results.add(Database.insert(accList,false));
		system.debug(LoggingLevel.ERROR,'accList after insert: '+accList);
		system.assertNotEquals(accList.size(),0);
		results.add(Database.upsert(accList,false));

		results.add(Database.delete(accList,false));
		List<Account> delAccList = [select id from account limit 10];
		system.assertEquals(delAccList.size(),0);
		system.debug(LoggingLevel.ERROR,'accList after delete: '+delAccList);
		results.add(Database.undelete(accList,false));
		List<Account> undelAccList = [select id from account limit 10];
		system.assertNotEquals(undelAccList.size(),0);
		system.debug(LoggingLevel.ERROR,'accList after undelete: '+undelAccList);
		results.dmlUpdate(undelAccList);
		results.dmlDelete(undelAccList);
		DMLResults DmlResult = new DMLResults(accList);

		DmlResult.add(DmlResult);
		}

	@isTest static void DmlResults_test_method_two() {
		DMLResults results= new DMLResults(); 
		List<Account> sameAccList = new List<Account>();
		Account acc1 = utilTestClass.CreateAccount('SameNameAccount');
		Account acc2 = utilTestClass.CreateAccount('SameNameAccount');
		sameAccList.add(acc1);
		sameAccList.add(acc2);
		//insert sameAccList;
		results.dmlInsert(sameAccList);

		results.withJobName('DmlResultsTestClass').toAddress('rsharma@akamai.com').sendLogMail();
        results.withClassName('DmlResultsTestClass').insertRecordsInErrorLog();
        results.resultsToString();
        results.resultsToHtml();
        results.fetchErrorLogs();
        //results.stampCronRunLog('Update Account With NAP PSOR values from Contract');
	}
	@isTest static void DmlResults_test_method_three() {
		Account acc = utilTestClass.CreateAccount(utilTestClass.getRandomString(15));

		DMLResults.Result res = new DMLResults.Result(Database.insert(acc,false));
		res.getRecordState();
		acc.Website = 'www.akamai.com';
		res = new DMLResults.Result(Database.upsert(acc,false));
		res = new DMLResults.Result(Database.delete(acc,false));
		res = new DMLResults.Result(Database.undelete(acc,false));
        Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
        batchJob.Name = 'Clean Up' + ' : Testcase';
        batchJob.Batch_Job_Type__c = 'Clean Up';
         batchJob.Run_Every__c = 1;
        batchJob.Period__c = 'Day';
        batchJob.Scheduled_to_Run__c = DateTime.now();
        batchJob.Validation_Override__c = true;
        insert batchJob;

        Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        batchRun.Trigger_Batch_Run__c = true;
        batchRun.Cron_Batch_Job__c = batchJob.Id;
        batchRun.Scheduled_to_Run__c =  DateTime.now();
        batchRun.Validation_Override__c = true;
        batchRun.Result__c = 'Success';
        insert batchRun;
        DMLResults dml = new DMLResults(true , true);
        dml.add(res);
        dml.withJobName('Clean Up');
        try{
            dml.stampCronRunLog();
        }catch(Exception e){
            
        }
        dml.add(new List<DMLResults.Result>{res});
       
        res.getRecordStateJson();
        res.recordURL();
        
        
	}
}