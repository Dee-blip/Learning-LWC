/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(3.41)    DESCRIPTION                               

|  ===========      =========       =======     =========== 
                                                       
|  10-APR-2014      Himanshu Kar    2556174     This batch class is used to create Autogen Cases for Customer On boarding
                                                It will run in every 3 hour.
|
   20-APR-2015      Himanshu Kar    2957996   Added Configuration approach to decide whether Job will run or not   
|   
   13-AUG-2015      Himanshu Kar    3085881   Changed Query to Autogen_Contract_Header_Detail__c instead of Merge Contract Header as per New Design       

   5-April-2017       Vandhana 
                    Krishnamurthy    3697952   Moving 7 days Criteria to Custom Setting for COB

|  26-May-2017      Aditya Sonam     ESESP-584         Moving SC_Sync_Contract_Header_Detail_Batch batch job to SC_Autogen_ExistingCOB_Batch.
													   Call to SC_Autogen_ExistingCOB_Batch Job to run

|  26-Sep-2018      Vamsee S         ESESP-976   Add Prolexic Alert in NCO and ECO ticket
                                                                                             
+=====================================================================================================*/

global class SC_Autogen_COB_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    public string batchQuery = NULL;
    public string batchName = 'Autogen COB Case creation Batch - ' + Datetime.now(); 
    
    // Setting Error Message
    public string errorMessage =  'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                      'Batch Class Name = SC_Autogen_COB_Batch\n' + 
                                'Support Class Name = SC_Autogen_COB_Support\n' +
                                'Method Name = main_COB_Method\n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    
      /*...... Setting settimefrom= 7 Days before for the batch......*/
  // updated value to SC_AutoGenJob object value for AutogenUseCase = 'COB'
  // changes for CR 
  static SC_AutogenJob__c scJobCOB = [Select Initial_Frequency__c from SC_AutogenJob__c where Autogen_UseCase_Name__c = 'COB' limit 1];

  //static dateTime settimefrom  = system.now().addDays(-7);
  static dateTime settimefrom = system.now().addDays(-scJobCOB.Initial_Frequency__c.intValue());
  static String valuesettimefrom = String.valueOfGmt(settimefrom);
  static String timefrom= valuesettimefrom.substring(0,10)+'T'+valuesettimefrom.substring(11,17)+'00z'; 
 
  // Fetching Case Record Types
  static Id setRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Header').getRecordTypeId();

  /*......Query on Contract Header to fetch all Active Contracts.......*/
      static String DEFAULT_QUERY = null;
      
      /*......Query for Test Class.......*/      
      static String TestClass_Query = null;
      
      /*......Query for Inactive COB Job.......*/ 
      static String inactiveJob_Query = null;
      
    // Constructor of Batch Class
    public SC_Autogen_COB_Batch(){
     
        system.debug(batchName + ' ......started...... ');
        
        
    }  
                              
 
    
    
 /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
 global Database.QueryLocator start(Database.BatchableContext BC){
       
       system.debug(batchName + '......Inside start Method......');
       
       // Get the Switch Flag value from Custom setting
        //boolean flag = SC_Autogen_Job_Enable_Disable__c.getValues('SwitchCOB').IsActive__c;
        
        
          DEFAULT_QUERY = 'select Id,Parent_Contract_Header__r.Account_Name__c,Is_COB_Created__c,' +
                          'Parent_Contract_Header__r.Effective_Start_Date__c, Parent_Contract_Header__c,' +
                          'Parent_Contract_Header__r.Effective_End_Date__c,' + 
                                      'Parent_Contract_Header__r.Name,Parent_Contract_Header__r.Account_Name__r.Name,' +
                                      'Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c,' + 
                                      'Parent_Contract_Header__r.Opportunity_Name__r.Name,' +
                                      'Parent_Contract_Header__r.Opportunity_Name__r.AKAM_Opportunity_ID__c' +
                                      ' from Autogen_Contract_Header_Detail__c where ' +
                                      ' Parent_Contract_Header__r.Locked__c = true and ' +
                                      ' Parent_Contract_Header__r.Cancellation_Date__c = Null and '+
                                      ' Parent_Contract_Header__r.Contract_Transferred_To__c = Null and ' +
                                      ' Is_COB_Created__c = False and ' +
                                      ' Parent_Contract_Header__r.Effective_End_Date__c >= Today and ' +
                                      ' Parent_Contract_Header__r.Effective_Start_Date__c <> null and ' +
                                      ' Parent_Contract_Header__r.Effective_End_Date__c <> null and ' +
                                      ' recordTypeId = \'' + setRecordTypeId + '\'' + ' and ' +
                                      ' Parent_Contract_Header__r.createdDate > ' + timefrom +
                                      ' order by Parent_Contract_Header__r.createdDate desc'
                                    ;
                                    
            TestClass_Query =   DEFAULT_QUERY + ' limit 10'; 
        
             
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
            List<Autogen_Contract_Header_Detail__c> allReturnContracts = (Autogen_Contract_Header_Detail__c[]) scope; 
        
            // Call to COB Support Class - New
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();  
                sc_COBSupportCls.main_COB_Method(allReturnContracts);  
            
                      
            
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
       
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_COB_Batch. # Of Errors : '+noOfErrors;
       
        // Calling Send Email Method for Errors
       if(noOfErrors > 0){
          SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
          sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
       }
       // calling ECOB batch
		if(SC_Autogen_Job_Enable_Disable__c.getValues('ECOB').IsActive__c){
            integer batchSizeECOB = integer.valueOf(SC_Autogen_Running_Freq__c.getValues('ECOB').Batch_Size__c); 
       		Database.executebatch(new SC_Autogen_ExistingCOB_Batch (),batchSizeECOB);

          }
        
        
        // Call to SC_Sync_Contract_Eng_MrktgProd_Batch
        database.executebatch(new SC_Sync_Contract_Eng_MrktgProd_Batch());      
    }   
}