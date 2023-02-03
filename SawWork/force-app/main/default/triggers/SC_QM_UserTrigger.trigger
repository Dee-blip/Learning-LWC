/*
Created By : Himanshu / Vamsee
Created On : 22 Jan 2020
Test Class :   SC_DD_DealDeskTest
*/
trigger SC_QM_UserTrigger on SC_QM_User_Filter__c (after Update){


    // Boolean to Call the Deal Job or Not
    boolean isCallToDealJob = false;
    
    // Loop for all the incoming records
    for(SC_QM_User_Filter__c eachRec : Trigger.New){
    
    
        // Condition to check 
        if(eachRec.User_Id__c == 'Deal_Desk' && eachRec.Status__c != Trigger.OldMap.get(eachRec.Id).Status__c && 
            eachRec.Status__c == 'Processed'){
            
            isCallToDealJob = true;
        }   
    }
    
    // Call to Deal Batch Job
    if(isCallToDealJob)
        Database.executeBatch(new SC_DD_ProcessODIDataJob(true),2000);
}