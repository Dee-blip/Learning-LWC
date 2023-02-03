global class AccountReassignmentBatchClass implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    global DMLResults results;
    global date todayDate;
    global integer accReassignmentUpdateCount;
    global AccountReassignmentDataProvider dataObj;
    
    global AccountReassignmentBatchClass(){
        dataObj = new AccountReassignmentDataProvider();
        dataObj.setReassignConfigSetting(GsmUtilClass.getKeyValueMetadata('Account_Reassignment_Config__mdt','Value__c','',true));
        dataObj.setReasonCodeSetting(GsmUtilClass.getReasonCodeSetting());
        accReassignmentUpdateCount = 0;
        todayDate = Date.today();
        query = 'Select Id,Name,Reassign__c,Reassign_Status__c,Status_Message__c,Effective_Month_Of_Transfer__c,Action__c,CreatedDate,Reassignment_Due_Date__c,IsPoolUserRequest__c,Account__c,Reason_Code__c,Adhoc_Request__c,Account_Status__c from Account_Reassignment__c where Reassign__c != true and (Reassign_Status__c = \'Approved\' OR Reassign_Status__c = \'Auto Approved\') and Reassignment_Due_Date__c != null and Reassignment_Due_Date__c <=: todayDate and CreatedDate=LAST_90_DAYS';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        results= new DMLResults(); 
        results.storeObjectState();
        return Database.getQueryLocator(query);
    } 
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        GroupSharing.accountShareManagementTriggerFirstRunFlag = false;
        
        List<Account_Reassignment__c> accReassignments = (List<Account_Reassignment__c>)scope;
        for(Account_Reassignment__c accReassign : accReassignments){
            AccountReassignmentTriggerClass.accept(accReassign,dataObj);
        }
        if(accReassignments.size()>0){
            accReassignmentUpdateCount = accReassignmentUpdateCount + accReassignments.size();
            results.add(Database.update(accReassignments,false),accReassignments);
            results.withClassName('AccountReassignmentBatchClass').insertRecordsInErrorLog();
        }
    }
    
    global void finish(Database.BatchableContext BC){
        AsyncApexJob jobDetails = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        string finalResult = 'Status: '+jobDetails.Status+', Total Records: '+accReassignmentUpdateCount+', Success: '+(accReassignmentUpdateCount - jobDetails.NumberOfErrors)+', Failure: '+jobDetails.NumberOfErrors;
        Util.updateCronRunWithResult('Active Account Reassignment', finalResult);
    }
}