//Created by Mayank Bansal as part of SFDC-3999
//Test Class: DeleteRecordsBatchJobTest
/*
Execute below code in Dev Console Anonymous Code and this is hard delete
String query = 'select Id from Task where CreatedBy.Name like \'%Marketo%\'';
DeleteRecordsBatchJob d = new DeleteRecordsBatchJob(query);
Database.executeBatch(d,2000);
*/

global class DeleteRecordsBatchJob implements Database.Batchable<sObject>, Database.Stateful{

	global final string query;

	global DeleteRecordsBatchJob(String q){
		query = q;
	}
	//start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc){
            return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc,List<sObject> scope){

    	Database.delete(scope,false);
        Database.emptyRecycleBin(scope);
    }

    // execution with this finish method
    global void finish(Database.BatchableContext BC){   
    }

}