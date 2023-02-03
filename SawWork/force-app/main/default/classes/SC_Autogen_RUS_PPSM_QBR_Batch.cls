/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(3.43)    DESCRIPTION                               

|  ===========      =========       =======     =========== 
                                                       
|  17-JUN-2014      Himanshu Kar    2604198     This batch class is used to create Autogen Cases for 
                                				RUS, PPSM and QBR Use Cases.
|                                               It will run in every day.

|  20-APR-2015      Himanshu Kar    2957996(4.7)	Added Configuration approach to decide whether Autogen UseCase will run or not

|  29-Jan-2018		Vamsee S		ESESP-613(18.2) Removed PIHC Autogen from Finish Method and 
													added SMP-Project Autogen to Finish Method
                                       
|                                                      
+=====================================================================================================*/

global class SC_Autogen_RUS_PPSM_QBR_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    public string batchQuery = NULL;
    public string batchName = 'Autogen RUS-PPSM-QBR  Case creation Batch - '; 
    
    // Setting Error Message
    public string errorMessage ='Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        						'Batch Class Name = SC_Autogen_RUS_PPSM_QBR_Batch\n' + 
                                'Support Class Name = SC_Autogen_RUS_PPSM_QBR_Support\n' +
                                'Method Name = main_RUS_PPSM_QBR_Method\n\n';
                            
    public integer noOfErrors = 0;
    
    // Constructor
    public SC_Autogen_RUS_PPSM_QBR_Batch(){ 
    
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
                            ' order by createdDate desc limit 50'
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
        
        
        try{
        	
        	SC_Autogen_RUS_PPSM_QBR_Support sc_RUS_PPSM_QBRSupportCls = new SC_Autogen_RUS_PPSM_QBR_Support(); 
            	sc_RUS_PPSM_QBRSupportCls.main_RUS_PPSM_QBR_Method(allReturnContracts);  
        		
        	
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
        
      string setEmailSub = 'Exception: In Batch Job - SC_Autogen_RUS_PPSM_QBR_Batch. # Of Errors : '+noOfErrors;
       
        // Calling Send Email Method for Errors
       if(noOfErrors > 0){
        	SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
        	sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
       }
        
		// Calling SMP-Project Job
       	if(SC_Autogen_Job_Enable_Disable__c.getValues('SMP-Project').IsActive__c){	
       		Database.executebatch(new PSA_AutoCreateBatchProject());
		}
    	
    }
}