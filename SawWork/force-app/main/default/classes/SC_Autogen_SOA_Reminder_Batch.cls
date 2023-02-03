/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       JIRA            DESCRIPTION                               

|  ===========      =========       =======         =========== 

|  11-DEC-2018      Aditya Sonam    ESESP-1689      This batch class is used to create reminder cases for SOA products
=====================================================================================================*/                                                
global class SC_Autogen_SOA_Reminder_Batch implements Database.Batchable<SObject>, Database.stateful
{
    
    public string batchQuery = NULL;
    public string batchName = 'Autogen SOA Case creation Batch - ' + Datetime.now(); 
    
    // Setting Error Message
    public string errorMessage =    'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        'Batch Class Name = SC_Autogen_SOA_Reminder_Batch\n' + 
        'Support Class Name = SC_Autogen_SOA_Reminder_Support\n' +
        'Method Name = main_SOA_Method\n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    
    // Fetching Case Record Types
    //static Id setRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Header').getRecordTypeId();
    
    /*......Query on Contract Header to fetch all Active Contracts.......*/
    static String DEFAULT_QUERY = null;
    
    /*......Query for Test Class.......*/      
    static String TestClass_Query = null;
    static String Test_Query = null;
    
    /*......Query for Inactive COB Job.......*/ 
    static String inactiveJob_Query = null;
    
    // Constructor of Batch Class
    public SC_Autogen_SOA_Reminder_Batch(){
        
        system.debug(batchName + ' ......started...... ');
        
        
    }  
    
    /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        system.debug(batchName + '......Inside start Method......');
        
        DEFAULT_QUERY = 'Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,'+
                        ' Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,Account_Name__r.Geography_Formula__c,'+
                        ' AKAM_Created_Date__c,Opportunity_Name__c from Merge_Contract_Header__c where'+
                        ' Locked__c = true and Active__c = true and Cancellation_Date__c = Null and'+
                        ' Contract_Transferred_To__c = Null and Effective_End_Date__c > Today and'+
                        ' AKAM_Created_Date__c <> null and Account_Name__r.Auto_Create_SOA_Reminder_Cases__c = true'+ 
                        ' and Account_Name__r.Division__c = \'' + String.escapeSingleQuotes('Public Sector') + '\''+' order by AKAM_Created_Date__c asc'
                        ;
        
        Test_Query = 'Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,'+
                        ' Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,Account_Name__r.Geography_Formula__c,'+
                        ' AKAM_Created_Date__c,Opportunity_Name__c from Merge_Contract_Header__c where'+
                        ' Locked__c = true and Active__c = true and Cancellation_Date__c = Null and'+
                        ' Contract_Transferred_To__c = Null and Effective_End_Date__c > Today and'+
                        ' AKAM_Created_Date__c <> null and Account_Name__r.Auto_Create_SOA_Reminder_Cases__c = true'+ 
                        ' order by AKAM_Created_Date__c desc'
                        ;
        TestClass_Query =   Test_Query + ' limit 10'; 

        
        // If incoming request is from Test class, then run test class query otherwise run default query  
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : DEFAULT_QUERY;
        
        
        return Database.getQueryLocator(batchQuery);
        
    }
    
    /*@Method <This method gets executed acutomatically when the batch job is execution mode.>*/   
    global void execute(Database.BatchableContext BC, list<SObject> scope){
        
        system.debug(batchName + '......Inside Execute Method......');
        
        string errHdr = ' ******* ';

        try{
            
            /*......Used to store all the Accounts returned by the Query......*/
            List<Merge_Contract_Header__c> allReturnContracts = (Merge_Contract_Header__c[]) scope; 
            
            // Call to COB Support Class - New
            SC_Autogen_SOA_Reminder_Support sc_SOASupportCls = new SC_Autogen_SOA_Reminder_Support();  
            sc_SOASupportCls.main_SOA_Method(allReturnContracts);  

        }
        catch(Exception e)
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
        } 
    }
    
    
    /*@Method <This method gets executed automatically when the batch job is finised.>
    @param <Database.BatchableContext BC - Batchable context>
    @return <void> - <Not returning anything>
    @throws exception - <No Exception>
    */    
    global void finish(Database.BatchableContext BC){
        
        System.debug('......Start of Finish Method......'+system.now());
        
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_SOA_Batch. # Of Errors : '+noOfErrors;
        List<Case> clist = new List<case>();
        // Calling Send Email Method for Errors
        if(noOfErrors > 0){
            SC_Autogen_SOA_Reminder_Support sc_SOASupportCls = new SC_Autogen_SOA_Reminder_Support(); 
            sc_SOASupportCls.sendEmailForError(setEmailSub, errorMessage,clist);
        }     
    }      
}