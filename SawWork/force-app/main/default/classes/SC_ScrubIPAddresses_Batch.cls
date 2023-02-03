/*-------------------------------------------------------------------------------------------------------------
 * Class Name           : SC_ScrubIPAddresses_Batch
 * Support Class        : SC_ScrubAndRemoveIPAddresses
 * Developer Name       : Vamsee Surya
 * Date                 : 25th April,2017
 * JIRA                 : ESESP-562
 * Description          : Batch class to pick the cases to scrub the IP address. This batch class runs everyday. 
 -------------------------------------------------------------------------------------------------------------*/ 

global class SC_ScrubIPAddresses_Batch implements Database.Batchable<sObject>, Database.stateful{
    
    //This will store the Error Message from support class
    Public string errorMessage = '' ;
    
    //Get the record type ID
    Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        
    //This will store the Query for the batch class
    Public string caseQuery;
    
    //This will store the Query for the test class 
    Public string caseQuery_Test;
    
    public SC_ScrubIPAddresses_Batch(){
        caseQuery_Test =    'SELECT Subject, Description, Issue_Summary__c, Troubleshooting_to_Date__c, Data_Collected__c,' + 
                            'Customer_Expectations__c, Next_Action_Recommendation__c, Solution_Summary__c, Root_Cause__c  ' +
                            'FROM Case WHERE RecordTypeId=\''+ recTypeId + '\' AND Isclosed = True AND Is_IP_Scrubbed__c = False ' +
                            'ORDER BY CreatedDate desc Limit 10';
    
        //Get the settings for Scrubbing of IP Address
        SC_Scrub_IP_Addresses_Setting__mdt scrubIPSettings = [SELECT Implementation_Date__c,Is_Active__c ,No_of_days__c FROM SC_Scrub_IP_Addresses_Setting__mdt WHERE DeveloperName = 'Technical'];
        
        //If Scrubbing Process is active
        if(scrubIPSettings.Is_Active__c == true){
            
            //Get the Effective Start Date
            DateTime implementationDate = scrubIPSettings.Implementation_Date__c;
                
            //Consider the cases for scrubbing 7 days after the case closure
            DateTime considerationDate = (DateTime.now() - Integer.valueOf(scrubIPSettings.No_of_days__c)).dateGMT();
                
            //Closed date should be greater that implemention date and closed date should lesser than or equal to consideration date
            //(Lesser than is required because to pick the cases for the failed batch job)
            caseQuery =     'SELECT Subject, Description, Issue_Summary__c, Troubleshooting_to_Date__c, Data_Collected__c,' + 
                            'Customer_Expectations__c, Next_Action_Recommendation__c, Solution_Summary__c, Root_Cause__c  ' +
                            'FROM Case WHERE RecordTypeId=\''+ recTypeId + '\' AND Isclosed = True AND Is_IP_Scrubbed__c = False AND Account.SC_IP_Scrubbing__c = True' + 
                            ' AND ClosedDate >= '+ implementationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') +
                            ' AND ClosedDate <= ' + considerationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
    }
    
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? caseQuery_Test : caseQuery;
        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
            return null;
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        //Convert Sobject list to Case List
        List<Case> qualifiedcaseList = (Case[]) scope;
        
        //Call helper class to identify and remove the IP Addresses
        if(qualifiedcaseList.size() > 0){
            SC_ScrubAndRemoveIPAddresses scrubIPclass = new SC_ScrubAndRemoveIPAddresses();
            errorMessage += scrubIPclass.scrubIPAddresses(qualifiedcaseList) + '\n';
        }
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){
            //if error message is not empty then send email to support email address
            if(errorMessage.length() > 5){
                SC_ScrubAndRemoveIPAddresses.sendEmailforException(errorMessage);
            } 
        
    }


}