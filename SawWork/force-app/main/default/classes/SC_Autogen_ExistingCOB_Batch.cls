/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(4.3)/JIRA      DESCRIPTION                               
|  ===========      =========       ============      =========== 
                                                       
|  23-Dec-2014      Aditya Sonam     2637462           This batch class is used to create Autogen Cases for Existing Customer On boarding
                                                       It will run in every 24 hour.
|                                       
|  18-May-2017      Aditya Sonam     ESESP-584         Moving PIVC component to another class, This class will run after each NCO batch job.
													   Call to SC_Sync_Contract_Header_Detail_Batch Job to run
+=====================================================================================================*/

/*
* Test Class : SC_Autogen_AllUseCase_TC 
*/

global class SC_Autogen_ExistingCOB_Batch implements Database.Batchable<SObject>, Database.stateful 
{
  
    public String batchQuery = Null;
    global integer noOfErrors = 0;
     
    // Constructor of Batch Class
    public SC_Autogen_ExistingCOB_Batch()
    {
    }
   
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                                'Batch Class Name = SC_Autogen_ExistingCOB_Batch\n' + 
                                'Support Class Name = SC_Autogen_ExistingCOB_Support\n' +
                                'Method Name = main_ECOB_Method\n';
    
    // Normal Execution Query
    final static String Account_Query = 'select Id,Name,Account_Name__c' + ' from Account';
    
    // Test Class Query                          
    final static String TestClassAccount_Query =  'select Id,Name,Account_Name__c' + 
                                        		  ' from Account'+
        				 						  ' Order by CreatedDate desc Limit 10';
                                
   /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
   global Database.QueryLocator start(Database.BatchableContext BC)
   {
        batchQuery = (System.Test.isRunningTest()) ? TestClassAccount_Query : Account_Query;
        return Database.getQueryLocator(batchQuery);
   }
  
   global void execute(Database.BatchableContext BC, list<SObject> scope)
   {
       string errHdr = ' ******* ';
       /*......Used to store all the Contracts returned by the Query......*/
       list<Account> allReturnAccount = (Account[]) scope;    
       try{
           // Call to ExistingCOB Support Class
           SC_Autogen_ExistingCOB_Support sc_ECOBSupportCls = new SC_Autogen_ExistingCOB_Support();
           sc_ECOBSupportCls.mergedContractHeaderMethod(allReturnAccount);
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
    global void finish(Database.BatchableContext BC)
    {    
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_ExistingCOB_Batch. # Of Errors : '+noOfErrors;
        
        // Calling Send Email Method for Errors
        if(noOfErrors > 0)
        {
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        } 
        // Call to SC_Sync_Contract_Header_Detail_Batch Job to run
        SC_Sync_Contract_Header_Detail_Batch detailBatch = new SC_Sync_Contract_Header_Detail_Batch(true,false);
        database.executebatch(detailBatch,200);
    }                              
}