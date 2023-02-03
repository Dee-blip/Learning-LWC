/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER       CR            DESCRIPTION                               

|  ===========    =========       =======       =========== 
                                                       
|  02-FEB-15      Kunal Sharma                  Creating PIHC Cases after 90 days of COB Creation.
  
   20-APR-2015    Himanshu Kar    2957996(4.7)  Added Configuration approach to decide whether Autogen UseCase will run or not 
|  20-APR-2015    Himanshu Kar    2956646(4.7)  Modified Case Creation Parameters     
|  11-Mar-2016    Sonia           3320211       GDRAT-to-DGRAT reorg: AMG functionality fixes - Replaced all Geography checks to use the custom setting
|  22-May-2017    Aditya Sonam    ESESP-584     Removed SC_Autogen_ExistingCOB_Batch 
|  31-Jan-2018    Vamsee S        ESESP-613     Removed PIHC Autogen Case Creation (Commented out the complete code)
+=====================================================================================================*/

global class SC_Autogen_PIHC_Batch { //implements Database.Batchable<SObject>, Database.stateful {
    
    //Constructor for Test Coverage
    Public SC_Autogen_PIHC_Batch(){
        
    }
    /*Commented by Vamsee
    // Variable for Setting Error Message
    static string errorString = 'Class: SCPIHCCaseBatch \n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    static integer numberOfBatches = 0;
    static Integer rangePIHC = (SC_Autogen_Case_Freq__c.getValues('PIHC').Initial_Freq__c).intValue();
    static SC_DGRAT_Reorg_Mapping__c DGRATMapping =  SC_DGRAT_Reorg_Mapping__c.getInstance();    

    //Query to retrive all the COB Cases
    final static string caseQueryCOB = 'SELECT Id, Account.Account_Status__c, Account.Akam_Account_Id__c, Description, ' +
                                         'Account.Name, Contract__r.Effective_Start_Date__c, AKAM_Created_Date__c ,Account.Geography_Formula__c ' +
                                         'FROM Case WHERE RecordType.DeveloperName = \'AMG\' '+
                                         'AND CreatedBy.Alias = \'CRMOPS\' '+
                                         'AND AKAM_Created_Date__c = LAST_N_DAYS:' + rangePIHC + ' ' + 
                                         'AND Request_Type__c = \'Customer Onboarding\' ' +
                                         'AND Work_Type__c = \'Proactive\' '+
                                         'AND Service__c = \'Accounts Audits\' ';
   
    final static string caseQueryCOBTest = 'SELECT Id, Account.Account_Status__c, Account.Akam_Account_Id__c,Description, ' +
                                         'Account.Name, Contract__r.Effective_Start_Date__c, AKAM_Created_Date__c , Account.Geography_Formula__c ' +
                                         'FROM Case WHERE RecordType.DeveloperName = \'AMG\' '+
                                         'AND CreatedBy.Alias = \'CRMOPS\' '+
                                         'AND AKAM_Created_Date__c = LAST_N_DAYS:' + rangePIHC + ' ' +
                                         'AND Request_Type__c = \'Customer Onboarding\' ' +
                                         'AND Work_Type__c = \'Proactive\' '+
                                         'AND Service__c = \'Accounts Audits\' LIMIT 20 ';
    //Execute the query created above.
    global Database.QueryLocator start(Database.BatchableContext varScope){
        system.debug('####' + caseQueryCOB);
        
        if(System.Test.isRunningTest()){
            return Database.getQueryLocator(caseQueryCOBTest);
        }
        return Database.getQueryLocator(caseQueryCOB);
    }
    
    global void execute(Database.BatchableContext BC, list<SObject> varScope){
        
        numberOfBatches++;
        
        //Getting the Id of Assignment Rule for Case.
        AssignmentRule caseAssignmentRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        
        //Getting the Id of AMG RT
        Id recordTypeAMG = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        Database.DMLOptions dmlOptn = new Database.DMLOptions();
        dmlOptn.AssignmentRuleHeader.assignmentRuleId = caseAssignmentRule.id;
        dmlOptn.EmailHeader.TriggerUserEmail = true;
        
        List<Case> lCasesToProcess = (List<Case>) varScope;
        List<Case> lPIHCCasesToCreate = new List<Case>();
        
        for(Case varCase: lCasesToProcess){
            
            if(varCase.Account.Account_Status__c.contains('Active') && 
              (DGRATMapping.Geography_APJ__c.containsIgnoreCase(varCase.Account.Geography_Formula__c) || 
               DGRATMapping.Geography_EMEA__c.containsIgnoreCase(varCase.Account.Geography_Formula__c))){
               
                    Date caseCreatedDate = Date.newInstance(varCase.AKAM_Created_Date__c.year(), varCase.AKAM_Created_Date__c.month(), varCase.AKAM_Created_Date__c.day());
                
                    // Added condition- If PIHC Job is active then it will go for case creation else not 
                    if(caseCreatedDate.addDays(rangePIHC) == System.today() && 
                      SC_Autogen_Job_Enable_Disable__c.getValues('PIHC').IsActive__c){
                        
                          lPIHCCasesToCreate.add(createCase(varCase,dmlOptn,recordTypeAMG,'PIHC'));
                    } 
                
            }
        }
        
        //Checking if we have a Cases to insert and inserting them.
        if(lPIHCCasesToCreate.size()>0){
            try{
                insert lPIHCCasesToCreate;
            }
            catch(exception e){
                string errorHeader = '------------------------------------------- \n\n';
                noOfErrors += 1;
                errorString += 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                                'Error while inserting batch ' + numberOfBatches +' : \n' + e + '\n' + errorHeader;
            }
        }
    }
    
    //Finish method sends email when the there are errors while creating the Cases
    global void finish(Database.BatchableContext bc){
        
        string setEmailSub = 'Exception: In Batch Job - SC_Autogen_PIHC_Batch. # Of Errors : '+noOfErrors;
       
        // Calling Send Email Method for Errors
       if(noOfErrors > 0){
            
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorString);
       }
       
       
    }
    
    //Method for Creating Cases
    public static Case createCase(Case varCase,Database.DMLOptions dmlOptn, Id recordTypeAMG, string useCase){
        
        Case newCaseInstance = new Case();
        newCaseInstance.setOptions(dmlOptn);
        newCaseInstance.Subject = createCaseSubject(varCase);
        newCaseInstance.Description = createCaseDescription(varCase);
        newCaseInstance.Contract__c = varCase.Contract__c;
        newCaseInstance.AccountId = varCase.AccountId;
        newCaseInstance.Service__c = SC_Serv_ReqTyp_value__c.getValues('PIHC').ServiceVal__c;
        newCaseInstance.Request_Type__c = SC_Serv_ReqTyp_value__c.getValues('PIHC').RequestTypeVal__c ;
        newCaseInstance.Request_Sub_Type__c = 'PIHC Completed';
        newCaseInstance.Severity__c = '3';
        newCaseInstance.Do_Not_Show_in_Portal__c = true;
        newCaseInstance.RecordTypeId = recordTypeAMG;
        newCaseInstance.Origin = 'Autogen';
        newCaseInstance.Autogen_UseCase__c  = useCase;
    newCaseInstance.Work_Type__c        = 'Proactive';
        
        return newCaseInstance;
    }
    
    //Setting the Description for the new Case
    public static string createCaseDescription(Case varCase){
        
        string caseDescription = 'Account Name: '                 + varCase.Account.Name + '\n' + 
                                 'Account Id: '                   + varCase.Account.Akam_Account_Id__c + '\n' + 
                                 'Contract Original Start Date: ' + varCase.Contract__r.Effective_Start_Date__c;
        
        return caseDescription;
    }
    
    //Setting the Subject for the new Case
    public static string createCaseSubject(Case varCase){
        string caseSubject = 'Complete PIHC: ' + varCase.Account.Name;
        return caseSubject;
    }*/
}