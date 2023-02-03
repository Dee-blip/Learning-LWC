/*
 * Created by Mayank Bansal as part of MARIT-212 to find out any errors logged in Error Log table based on Record Id
 * GetErrorLogRecordsBasedOnID d = new GetErrorLogRecordsBasedOnID('0013I000001uYGfQAM');
 * Database.executeBatch(d,2000); 
 */
global class GetErrorLogRecordsBasedOnID implements Database.Batchable<sObject>, Database.Stateful{
    
    global List<Error_Log__c> result = new List<Error_Log__c>();
    global List<Error_Log__c> errList = new List<Error_Log__c>();
    global Id recordId = null;
    global final string query = 'select id, Class__c, Error_Message__c, Object_State__c, RecordId__c from Error_log__c';

	//start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc){
            return Database.getQueryLocator(query);
    }
    
    global GetErrorLogRecordsBasedOnID(Id recId){
		recordId = recId;
	}

    global void execute(Database.BatchableContext bc,List<sObject> scope){
        
        List<Error_Log__c> errList = scope;
        for(Error_Log__c err : errList) {
            if( (err.Error_Message__c != null && err.Error_Message__c.contains(recordId)) || 
               (err.Object_State__c != null && err.Object_State__c.contains(recordId)) || 
               (err.RecordId__c != null && err.RecordId__c.contains(recordId))) {
                result.add(err);
            }
    		System.debug('Mayank, errLog:' +result);
    	}
    }

    // execution with this finish method
    global void finish(Database.BatchableContext BC){   
    }

}