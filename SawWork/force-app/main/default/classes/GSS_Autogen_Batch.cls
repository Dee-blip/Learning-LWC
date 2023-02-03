/**
|  HISTORY  |          

|  TEST CLASS: GSS_Autogen_Test

|  DATE             DEVELOPER       JIRA            DESCRIPTION                               

|  ===========      =========       =======         =========== 

|  03-DEC-2020      Vikas           ESESP-4175      Batch Class used to create autogen for newly created automated approach

|  08-FEB-2021      Sandeep         FFPSA-1769      Updated Batch class to create Autogen Projects.

**/
public class GSS_Autogen_Batch implements Database.Batchable<SObject>, Database.stateful {
    
    public String batchQuery = NULL;
    public String batchName = 'Autogen Case and Project creation Batch - '; 
    public integer noOfErrors = 0;
    
    //Setting Error Message
    public String errorMessage =  'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        'Batch Class Name = GSS_Autogen_Batch\n' + 
        'Support Class Name = GSS_Autogen_Class\n' +
        'Method Name = mainAutogenMethod\n';
    
    static String defaultQuery = null;
    static String testClassQuery = null;
    static Id lineRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
    
    private String committedRecordType = 'Committed';
    private String usageRecordType = 'Usage';
    private List<String> productList = new List<String>();

    public Map<String, Set<GSS_Autogen__c>> productIdToGSSAutogenListMap = new Map<String, Set<GSS_Autogen__c>>();
    

    public Database.QueryLocator start(Database.BatchableContext batchContext){
        
        for(GSS_Autogen__c eachAutogen : [
            SELECT 
                id, Triggering_Product_ID__c, Triggering_Unit_of_Measure__c, Triggering_Billing_Duration__c, Triggering_Key__c, Case_Severity__c,
                Case_Record_Type__c, Case_Subject__c, Case_Service__c, Case_Description__c, Case_Sub_Type__c, Case_Request_Type__c,
                Case_Only__c, Project_Name__c, Project_Template__c, IS_Normal_Quarterly_Hours_Project__c, IS_Bucket_Project__c, Fixed_Hours_Per_Quarter__c, Fixed_Hours_Per_Month__c, LOE_Per_Unit_Low__c,
                Project_Template__r.Id, Project_Template__r.Name, Project_Template__r.pse__Billing_Type__c, Project_Template__r.pse__Allow_Self_Staffing__c, Project_Template__r.pse__Is_Billable__c, Project_Template__r.RecordtypeId, Project_Template__r.pse__Is_Active__c, Project_Template__r.pse__Project_Status__c, Project_Template__r.pse__Stage__c, Project_Template__r.pse__Practice__c, Project_Template__r.Project_Sub_Type__c, Project_Template__r.pse__Project_Type__c, Project_Template__r.pse__Account__c, Project_Template__r.pse__Start_Date__c, Project_Template__r.pse__End_Date__c,Project_Template__r.pse__Project_manager__c, Project_Template__r.pse__Region__c
            FROM GSS_Autogen__c 
            WHERE Inactive__c = false AND Triggering_Key__c != NULL 
        ]){
            productList.add(eachAutogen.Triggering_Product_ID__c);

            if(productIdToGSSAutogenListMap.containsKey(eachAutogen.Triggering_Product_ID__c)) {
                productIdToGSSAutogenListMap.get(eachAutogen.Triggering_Product_ID__c).add(eachAutogen);
            } 
            else {
                productIdToGSSAutogenListMap.put(eachAutogen.Triggering_Product_ID__c, new Set<GSS_Autogen__c> { eachAutogen });
            }
        
        }

        System.debug('Products list** ' + productList);
        System.debug('Products Map list** ' + productIdToGSSAutogenListMap);
        
        String selectClause = 'SELECT Id, Name,Parent_Contract_Header__r.Account_Name__c, IS_CLI_Onboarded__c ,' +
        'Effective_Start_Date__c, Parent_Contract_Header__c,Product__c,Effective_End_Date__c,' +
        'Parent_Contract_Detail__c,Parent_Contract_Detail__r.Name,Parent_Contract_Detail__r.Billing_Duration__c,'+
        'Parent_Contract_Detail__r.Createddate,Parent_Contract_Detail__r.Unit_of_Measure__c,Autogen_Triggering_Key__c,' + 
        'Parent_Contract_Header__r.Name,Parent_Contract_Header__r.Account_Name__r.Name,Parent_Contract_Detail__r.Original_Detail_Id__c,' +
        'Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c,Parent_Contract_Detail__r.Effective_Start_Date__c,Parent_Contract_Detail__r.Effective_End_Date__c,' + 
        'Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c,Parent_Contract_Detail__r.Original_Contract_Id__r.Currency__c,Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__c,' +
        'Parent_Contract_Detail__r.Unit_Price__c,Parent_Contract_Detail__r.Units_Low__c,Project__c,Case_For_Project__c,Parent_Contract_Detail__r.Original_Contract_Id__r.Name';

        String whereClause = 'WHERE ' +
        ' Parent_Contract_Header__r.Locked__c = true AND ' +
        ' Parent_Contract_Header__r.Active__c = true AND ' +
        ' Parent_Contract_Header__r.Cancellation_Date__c = Null AND '+
        ' Parent_Contract_Header__r.Contract_Transferred_To__c = Null AND ' +
        ' IS_CLI_Onboarded__c = False AND ' +
        ' Parent_Contract_Detail__r.Effective_End_Date__c <> null AND '+
        ' Parent_Contract_Detail__r.Effective_Start_Date__c <> null AND '+
        ' recordTypeId = \'' + lineRecordTypeId + '\' and '+
        ' Product__c IN :productList AND '+
        ' (Parent_Contract_Detail__r.Record_Type__c= \''+usageRecordType+'\' or Parent_Contract_Detail__r.Record_Type__c=\'' +committedRecordType+ '\') AND ';

        String dateFilter = ' ('+
            //CLI Effective Start Date is between (TODAY and last 90 calendar days).[-90 Days <= Effective Start Date <= Today] and CLI Created Date equals to last 96 hours. [-96 Hours <= CreatedDate]
            '(Effective_Start_Date__c = LAST_N_DAYS:90 AND Parent_Contract_Detail__r.CreatedDate = LAST_N_DAYS:4) '+
            ' OR '+
            //CLI Effective Start is between (TOMORROW and next 30 calendar days). [Tomorrow <= Effective Start Date <= +90 Days]
            '(Effective_Start_Date__c = today OR Effective_Start_Date__c = NEXT_N_DAYS:30 ) '+
        ' )';

        
        defaultQuery =  selectClause+' FROM Autogen_Contract_Header_Detail__c '+ whereClause +  dateFilter;                     
        System.debug('query*** '+ defaultQuery);    
        
        testClassQuery =   defaultQuery + ' limit 10'; 
        batchQuery = (System.Test.isRunningTest()) ? testClassQuery : defaultQuery;
        
        Database.QueryLocator records;

        try{
            records = Database.getQueryLocator(batchQuery);
        }
        catch(Exception e)
        {
            noOfErrors += 1;
            String errHdr = ' ******* ';
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
            
            System.debug('Error***: ' + errorMessage);
        }
        System.debug('Records size*** '+ records);
        return records;
        
    }
    public void execute(Database.BatchableContext batchContext, List<SObject> scope){
        
        String errHdr = ' ******* ';

        if(scope == null){
            System.debug('No records found');
        }
        else{                
            try{
                List<Autogen_Contract_Header_Detail__c> allReturnACHD = (Autogen_Contract_Header_Detail__c[]) scope;        
                // GSS_Autogen_Class gssAutogenClass = new GSS_Autogen_Class(productIdToGSSAutogenListMap, autogenProjectMap);
                System.debug('Calling GSS autogen starts');
                GSS_Autogen_Class gssAutogenClass = new GSS_Autogen_Class(productIdToGSSAutogenListMap);
                gssAutogenClass.mainAutogenMethod(allReturnACHD);
                System.debug('Calling GSS autogen ends');
            }
            catch(Exception e)
            {
                noOfErrors += 1;
                errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                    + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                    + '\n' + errHdr + '\n';
            }
        }
    }
    public void finish(Database.BatchableContext batchContext){

        // Calling Send Email Method for Errors
        if(noOfErrors > 0){
            String setEmailSub = 'Exception: In Batch Job - GSS_Autogen_Batch. # Of Errors : '+noOfErrors;
            GSS_Autogen_Util gssAutogenUtil = new GSS_Autogen_Util(); 

            PSA_Settings__c enggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
            String emailAddress = enggEmail != null ?enggEmail.Value__c : 'services-engg@akamai.com';
            
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Messaging.Singleemailmessage objEmail;
            objEmail = new Messaging.Singleemailmessage();
            objEmail.setReplyTo('noreply@akamai.com');
            objEmail.setToAddresses(new list<String>{emailAddress});            
            objEmail.setSubject(setEmailSub);
            objEmail.setHTMLBody( errorMessage );
            mailsToBeSent.add(objEmail);
            Messaging.sendEmail(mailsToBeSent,false);            
        } 
    }
}