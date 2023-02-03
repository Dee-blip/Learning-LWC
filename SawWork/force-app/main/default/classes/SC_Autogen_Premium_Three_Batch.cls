/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       JIRA      DESCRIPTION                               

|  ===========      =========       =======     =========== 
                                                       
|  29-APR-2019      Aditya Sonam    ESESP-1818  This batch class is used to create Autogen Cases for Premium 3.0

   Test Class:  SC_Autogen_AllUseCase_TC                                                                                        
+=====================================================================================================*/

Public class SC_Autogen_Premium_Three_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    public string batchQuery = NULL;
    public string batchName = 'Autogen Premium 3.0 Onboarding Batch - ' + Datetime.now(); 
    
    // Setting Error Message
    public string errorMessage =  'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                            'Batch Class Name = SC_Autogen_Premium_Three_Batch\n' + 
                                'Support Class Name = SC_Autogen_Premium_Three_Support\n' +
                                'Method Name = main_COB_Method\n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    

  SC_Utility__mdt customMdtVal = [Select value__c, Value_Text__c from SC_Utility__mdt where DeveloperName = 'Autogen_Premium_3_0_Case_Products' limit 1];
  Private List<String> productList = customMdtVal.value__c.split(',');
  Private string UoM = customMdtVal.Value_Text__c; 
  Private string LineRecordType = 'Committed';
  // Fetching Case Record Types
  static Id setRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();

  /*......Query on Contract Header to fetch all Active Contracts.......*/
      static String DEFAULT_QUERY = null;
      
      /*......Query for Test Class.......*/      
      static String TestClass_Query = null;
      
      
    // Constructor of Batch Class
    public SC_Autogen_Premium_Three_Batch(){
        system.debug(batchName + ' ......started...... ');
    }  
  
 /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
 Public Database.QueryLocator start(Database.BatchableContext BC){
       
       system.debug(batchName + '......Inside start Method......');
       

          DEFAULT_QUERY = 'SELECT Id, Parent_Contract_Header__r.Account_Name__c, IS_CLI_Onboarded__c ,' +
                          'Effective_Start_Date__c, Parent_Contract_Header__c,Product__c,' +
                          'Effective_End_Date__c,Parent_Contract_Detail__c,Parent_Contract_Detail__r.Name,Parent_Contract_Detail__r.Createddate,' + 
                                      'Parent_Contract_Header__r.Name,Parent_Contract_Header__r.Account_Name__r.Name,' +
                                      'Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c' + 
                                      ' FROM Autogen_Contract_Header_Detail__c WHERE ' +
                                      ' Parent_Contract_Header__r.Locked__c = true and ' +
                                      ' Parent_Contract_Header__r.Cancellation_Date__c = Null and '+
                                      ' Parent_Contract_Header__r.Contract_Transferred_To__c = Null and ' +
                                      ' IS_CLI_Onboarded__c = False and ' +
                                      ' Parent_Contract_Detail__r.Effective_End_Date__c <> null and '+
                            ' Parent_Contract_Detail__r.Unit_of_Measure__c = \'' +UoM+ '\'' +
                          ' and recordTypeId = \'' + setRecordTypeId + '\''+
                      ' and Product__c IN :productList and Parent_Contract_Detail__r.Record_Type__c=\'' +LineRecordType+ '\'';

                                    
            TestClass_Query =   DEFAULT_QUERY + ' limit 10'; 
        
            system.debug('--Query---'+DEFAULT_QUERY); 
        // If incoming request is from Test class, then run test class query otherwise run default query  
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : DEFAULT_QUERY;
        
       
        return Database.getQueryLocator(batchQuery);

    }
    
/*@Method <This method gets executed acutomatically when the batch job is execution mode.>*/   
Public void execute(Database.BatchableContext BC, list<SObject> scope){
        
        system.debug(batchName + '......Inside Execute Method......');
        
        string errHdr = ' ******* ';
         
  
        try{
        
                /*......Used to store all the Accounts returned by the Query......*/
            List<Autogen_Contract_Header_Detail__c> allReturnContracts = (Autogen_Contract_Header_Detail__c[]) scope; 
        
            // Call to COB Support Class - New
            SC_Autogen_Premium_Three_Support sc_PremiumSupportCls = new SC_Autogen_Premium_Three_Support();  
                sc_PremiumSupportCls.main_Premium_Method(allReturnContracts);  
            
                      
            
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
    Public void finish(Database.BatchableContext BC){
       
       System.debug('......Start of Finish Method......'+system.now());
       
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_Premium_Three_Batch. # Of Errors : '+noOfErrors;
       
        // Calling Send Email Method for Errors
       if(noOfErrors > 0){
          SC_Autogen_Premium_Three_Support sc_SupportCls = new SC_Autogen_Premium_Three_Support(); 
          sc_SupportCls.senEmailForError(setEmailSub, errorMessage);
       }     
    }   
}