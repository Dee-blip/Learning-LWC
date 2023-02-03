/*=====================================================================================================+                                                                           
|  DATE             DEVELOPER       JIRA      DESCRIPTION                               
|  ===========      =========       =======     =========== 
                                                       
|  18-May-2017     Aditya Sonam    ESESP-584    This batch class is used to create Autogen Cases for PIVC.
                                                It will run once in every 24 hour.
|  31-Jan-2018      Vamsee S     ESESP-613  Removed PIVC Autogen Case Creation (Commented out the complete code)
+=====================================================================================================*/

global class SC_Autogen_PIVC_Batch{// implements Database.Batchable<SObject>, Database.stateful {
  
    //Constructor for Test Coverage
    Public SC_Autogen_PIVC_Batch(){
        
    }
    /*
    Public String batchQuery = Null;
    global integer noOfErrors = 0;
     
     // Constructor of Batch Class
    public SC_Autogen_PIVC_Batch(){
    
    }
   
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                     'Batch Class Name = SC_Autogen_PIVC_Batch\n' + 
                                 'Support Class Name = SC_Autogen_PIVC_Support\n' +
                                 'Method Name = mergePIVCMethod\n';
  
    // Normal Execution Query
    final static String Account_Query = 'select Id,Name,Account_Name__c' + 
                                         ' from Account';
      
    // Test Class Query                          
    final static String TestClassAccount_Query =  'select Id,Name,Account_Name__c' + 
                                              ' from Account'+
                              ' Order by CreatedDate desc Limit 10';
                                
   /*@Method <This method gets executed acutomatically when the batch job is started.>
   global Database.QueryLocator start(Database.BatchableContext BC){
   
        batchQuery = (System.Test.isRunningTest()) ? TestClassAccount_Query : Account_Query;
        
        return Database.getQueryLocator(batchQuery);
   }
  
   global void execute(Database.BatchableContext BC, list<SObject> scope){
   
      string errHdr = ' ******* ';
      /*......Used to store all the Contracts returned by the Query......
      List<Account> allReturnAccount = (Account[]) scope;    
      try{
          // Call to PIVC Support Class
        SC_Autogen_PIVC_Support sc_PIVCSupportCls = new SC_Autogen_PIVC_Support();
          sc_PIVCSupportCls.mergePIVCMethod(allReturnAccount);
            }
          
        catch(Exception e) {
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
    global void finish(Database.BatchableContext BC){
      
      string setEmailSub = 'Exception: In Batch Job - SC_Autogen_PIVC_Batch. # Of Errors : '+noOfErrors;
        
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
   */                            
 }