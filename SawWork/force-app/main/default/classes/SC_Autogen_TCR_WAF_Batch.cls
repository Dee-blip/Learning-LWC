/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(3.41)    DESCRIPTION                               

|  ===========      =========       =======     =========== 
                                                       
|  16-APR-2014      Himanshu Kar    2556174     This batch class is used to create Autogen Cases for TCR and WAF Use Cases.
                                                It will run in every day.  
|  20-APR-2015      Himanshu Kar    2957996     Added Configuration approach to decide whether Job will run or not                                 
+=====================================================================================================*/

global class SC_Autogen_TCR_WAF_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    public string batchQuery = NULL;
    public string batchName = 'Autogen TCR WAF Case creation Batch - '; 
    
    // Setting Error Message
    public string errorMessage ='Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                                'Batch Class Name = SC_Autogen_TCR_WAF_Batch\n' + 
                                'Support Class Name = SC_Autogen_TCR_WAF_Support\n' +
                                'Method Name = main_TCR_WAF_Method\n';
    
    // Variable to count the no of Errors
    public integer noOfErrors = 0;
    
    // Constructor
    public SC_Autogen_TCR_WAF_Batch(){ 
    
        system.debug(batchName + ' ......started...... ');
    }  
         
        /*......Query on Contract Header to fetch all Active Contracts.......*/
        final static String DEFAULT_QUERY = 'select Id,Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c,' + 
                                            'Name,Account_Name__r.Name' +
                                            ' from Merge_Contract_Header__c where ' +
                                            ' Locked__c = true and ' +
                                            ' Cancellation_Date__c = Null and '+
                                            ' Contract_Transferred_To__c = Null and ' +
                                            ' Effective_Start_Date__c <= Today and ' +
                                            ' Effective_End_Date__c >= Today and ' +
                                            ' Effective_Start_Date__c <> null and ' +
                                            ' Effective_End_Date__c <> null ' +
                                            ' order by createdDate desc'
                                           ;
                    
        /*......Query for Test Class.......*/           
        final static String TestClass_Query = 'select Id,Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c,' + 
                                            'Name,Account_Name__r.Name' +
                                            ' from Merge_Contract_Header__c where ' +
                                            ' Locked__c = true and ' +
                                            ' Cancellation_Date__c = Null and '+
                                            ' Contract_Transferred_To__c = Null and ' +
                                            ' Effective_Start_Date__c <= Today and ' +
                                            ' Effective_End_Date__c >= Today and ' +
                                            ' Effective_Start_Date__c <> null and ' +
                                            ' Effective_End_Date__c <> null ' +
                                            ' order by createdDate desc limit 10'
                                           ;
 
    
    
 /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
 global Database.QueryLocator start(Database.BatchableContext BC){
       
       system.debug(batchName + '......Inside start Method......');
        
        // If incoming request is from Test class, then run test class query otherwise run default query  
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : DEFAULT_QUERY;
        
        return Database.getQueryLocator(batchQuery);
    }
    
/*@Method <This method gets executed acutomatically when the batch job is execution mode.>*/   
global void execute(Database.BatchableContext BC, list<SObject> scope){
        
        system.debug(batchName + '......Inside Execute Method......');
        
        string errHdr = ' ******* ';
         
        /*......Used to store all the Accounts returned by the Query......*/
        List<Merge_Contract_Header__c> allReturnContracts = (Merge_Contract_Header__c[]) scope;  
        
        SC_Autogen_TCR_WAF_Support sc_TCR_WAFSupportCls = new SC_Autogen_TCR_WAF_Support(); 
        
        try{
            sc_TCR_WAFSupportCls.main_TCR_WAF_Method(allReturnContracts);  
        }
        catch(Exception e)
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
        }
      
    }


    /*@Method <This method gets executed acutomatically when the batch job is finised.>
    @param <Database.BatchableContext BC - Batchable context>
    @return <void> - <Not returning anything>
    @throws exception - <No Exception>
    */    
    global void finish(Database.BatchableContext BC){
       
       System.debug('......Start of Finish Method......'+system.now());
      
      // Setting Subject  
      string setEmailSub = 'Exception: In Batch Job - SC_Autogen_TCR_WAF_Batch. # Of Errors : '+noOfErrors;
        
      // Calling Send Email Method for Errors 
       if(noOfErrors > 0){
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
       }
        
        // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
    Id setDetailRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
 
    // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
    Id setHeaderRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Header').getRecordTypeId();

try{

    // Delete Header
    delete [select Id from Autogen_Contract_Header_Detail__c where RecordTypeId = :setHeaderRecordTypeId and Parent_Contract_Header__c = null limit 3000];

    // changes by Vandhana - commenting out Line item deletion
    // Delete Line
    //delete [select Id from Autogen_Contract_Header_Detail__c where RecordTypeId = :setDetailRecordTypeId and Parent_Contract_Detail__c = null limit 3000];

}
catch(Exception e){}
        
       // Call to SC_Sync_Contract_Header_Detail_Batch Job to run
        SC_Sync_Contract_Header_Detail_Batch detailBatch = new SC_Sync_Contract_Header_Detail_Batch(true,true);
        database.executebatch(detailBatch,200); 
      
    }   
}