/**
|  HISTORY  |                                                                            

|  DATE             DEVELOPER       JIRA        DESCRIPTION                               

|  ===========      =========       =======     =========== 

|  10-Jul-2019      Sumanth       ESESP-2460    Batch Class used to create autogen for Plus & Advanced

**/

global class SC_Autogen_PLUS_ADVANCED_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    
    
    public string batchQuery = NULL;
    public string batchName = 'Autogen PLUS-ADVANCED Case creation Batch - '; 
    
    // Setting Error Message
    public string errorMessage ='Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        'Batch Class Name = SC_Autogen_Plus_Advanced_Batch\n' + 
        'Support Class Name = SC_Autogen_Plus_Advanced_Support\n' +
        'Method Name = main_PLUS_ADVANCED_Method\n\n';
    
    public integer noOfErrors = 0;
    public List<Case> casesCreated = new List<Case>();
    
    /**
    Constructor
    **/
    
    public SC_Autogen_PLUS_ADVANCED_Batch(){ 
        
        system.debug(batchName + ' ......started...... ');
    }                  
    
    
    /*......Query on Contract Header to fetch all Active Contracts.......*/
    final static String DEFAULT_QUERY = 'select Id,Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c,' + 
        'Name,Account_Name__r.Name' +
        ' from Merge_Contract_Header__c where ' +
        ' Locked__c = true and ' +
        ' Cancellation_Date__c = Null and '+
        ' Contract_Transferred_To__c = Null and ' +
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
            
            /** Add Logic here to call support method **/   
            SC_Autogen_PLUS_ADVANCED_Support sc_PLUS_ADVANCEDSupportCls = new SC_Autogen_PLUS_ADVANCED_Support(); 
            List<Case> casesCreatedInBatch = sc_PLUS_ADVANCEDSupportCls.main_PLUS_ADVANCED_Method(allReturnContracts); 
            casesCreated.addAll(casesCreatedInBatch);
            
        }
        catch(Exception e)
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString() + '\n' + errHdr + '\n';
                
                
        }
        
    }   
    
    
    /*@Method <This method gets executed acutomatically when the batch job is finised.>
    @param <Database.BatchableContext BC - Batchable context>
    @return <void> - <Not returning anything>
    @throws exception - <No Exception>
    */    
    global void finish(Database.BatchableContext BC){
        
        string errHdr = ' ******* ';
        System.debug('......Start of Finish Method......'+system.now());
        try{
            
            SC_Autogen_PLUS_ADVANCED_Support sc_PLUS_ADVANCEDSupportCls = new SC_Autogen_PLUS_ADVANCED_Support(); 
            sc_PLUS_ADVANCEDSupportCls.linkTPMCasesWithEMCases(casesCreated); 
        }
        catch(Exception e){
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString() + '\n' + errHdr + '\n';
                
                
        }
        
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_PLUS_ADVANCED_Batch. # Of Errors : '+noOfErrors;
        
        // Calling Send Email Method for Errors
        if(noOfErrors > 0){
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        }
        
        
        
    }
    
    
    
    
}