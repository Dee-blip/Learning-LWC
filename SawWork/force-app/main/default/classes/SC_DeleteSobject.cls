/*=====================================================================================================+
Class name          :   SC_DeleteSobject
Author              :   Himanshu
Created             :   10-Sep-20
Purpose             :   Deleting any SObject records
Test Class          :   

Last Modified 	Developer    	Purpose             
============= 	===========  	=======
10-Sep-20     	Himanshu   		Initial Development 
+=====================================================================================================*/
public class SC_DeleteSobject implements Database.Batchable<sObject> {

    
    // Variables to be Used
    public string batchQuery, inputJobDetails;
    
    // Default Constructor
    public SC_DeleteSobject(string inputQuery, string jobName){
 	
 		batchQuery = inputQuery; 
        inputJobDetails = jobName;
 	}
    
    // Start Method
    public Database.QueryLocator start (Database.BatchableContext BC){
        if(test.isRunningTest()){
            batchQuery += ' LIMIT 10';
        }
        return Database.getQueryLocator(batchQuery);
    }
    
    // Execute Method
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }
    
    // Finish Method
    public void finish(Database.BatchableContext BC){
        
        // 1. Logic for EB_Product_Job
        if(inputJobDetails == 'EB_Product_Job'){
        	SC_User_Filter__c userFilterRecord = [Select Id, Unique_ID__c, Filter_Values__c from SC_User_Filter__c where Unique_ID__c = 'EB_Product_Job' Limit 1];
        	userFilterRecord.Filter_Values__c = 'Up-to-date';
        	Update userFilterRecord;
        }
    }
}