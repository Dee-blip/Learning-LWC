/**
|  HISTORY  |                    

| CLASSES COVERED: GSS_Autogen_Class, GSS_Autogen_Batch, GSS_Autogen_Util

|  DATE             DEVELOPER       JIRA            DESCRIPTION                               

|  ===========      =========       =======         =========== 

|  21-Jan-2021      Vikas           ESESP-4175      Test class for GSS Autogen Batch Class

|  21-March-2021    Sandeep         FFPSA-1769      Test class for GSS Autogen Batch Class - Projects Coverage

**/
@isTest(seeAllData=false)
public class GSS_Autogen_Test {
    // For Account Record
    public static Account accRec;
    // For Contract Header Record
    public static List<Merge_Contract_Header__c> contractList;
    // For Contract Header Record
    public static List<GSS_Autogen__c> autogenList;

    public static PSA_TestUtility testUtil;
    public static pse__Region__c reg;
    public static pse__Practice__c pract;
    public static User usr;
    public static Contact resource;
    public static Id professionalServicesId;

    
	// Method-1: Creating Test Data for Account + Contract Header
    public static void testDataSetup()
    { 
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();

        testUtil = new PSA_TestUtility();

        // For Account Record
        accRec = new Account(Name='GSS Autogen Batch Account',AKAM_Account_ID__c='TestGSSAutoBatch',Type='Brand - Active',Parent_Division__c='APJ_',Division__c='Americas',Support_Level__c ='Premium_2.0');
        insert accRec;
        //accRec.Area__c = 'Undefined';
        accRec.TERR_HIER_5__c = 'Undefined';
        accRec.AKAM_Account_ID__c = 'AKAM_ACCOUNT_ID';
        update accRec;
       
        //Creating the region with name as Undefined (Territory)
        reg = new pse__Region__c();
        reg.Name = 'Undefined' + ' (Territory)';
        insert reg;

        //Create Project Template Data
        pract = testUtil.newPracticeMaster(true);
        usr = testUtil.newUserSysAdmin(true); 
        resource = testUtil.newResource(true, accRec.Id, usr.Id);
        testUtil.newPermissionControl(true, usr.Id, reg.Id);

        //Create Project Template
        
        professionalServicesId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        GSM_Custom_Settings__c gsmSetting = new GSM_Custom_Settings__c();
        gsmSetting.Name = 'CaseTrigger#updateContact';
        gsmSetting.Value__c = 'Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback';
        insert gsmSetting;

        GSM_Custom_Settings__c gsmSetting2 = new GSM_Custom_Settings__c();
        gsmSetting2.Name = 'IR_CaseDefaultRecordTypeId';
        gsmSetting2.Value__c = '012G0000000ygAxIAI';
        insert gsmSetting2;

        GSM_Custom_Settings__c gsmSetting3 = new GSM_Custom_Settings__c();
        gsmSetting3.Name = 'IR_CaseRecordTypeIds';
        gsmSetting3.Value__c = '012G0000000ygAxIAI,012G0000000ygB2IAI';
        insert gsmSetting3;
        
        SC_RiverbedCaseProdID__c scRiverbedCaseProdIDSetting = new SC_RiverbedCaseProdID__c();
        scRiverbedCaseProdIDSetting.Name = 'Riverbed_SAAS_OEM';
        scRiverbedCaseProdIDSetting.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        scRiverbedCaseProdIDSetting.RecordTypeID__c = '012G0000000z10xIAA';

        insert scRiverbedCaseProdIDSetting;

        Email_to_Case__c ecSetting = new Email_to_Case__c();
        ecSetting.Name = 'Momentum';
        ecSetting.CaseType__c = '';
        ecSetting.Priority__c = 'Medium';
        ecSetting.delimiter__c = '#case';
        ecSetting.EmailTemplate__c ='00XA0000000bwQE';
        ecSetting.Queue_Email__c ='momentum-admins-qaa@akamai.com';
        ecSetting.GroupEmail__c ='momentum-help-qaa@akamai.com';
        ecSetting.CaseRecord__c ='012A0000000OWfW';
        ecSetting.ContextAlias__c ='CRMOPS';
        ecSetting.Severity__c ='3 - Difficult to do job';
        ecSetting.Contact__c ='003A000000Z4JBG';
        ecSetting.OrgWide__c ='0D2A00000004Cnh';
        ecSetting.reporterId__c ='0B7A0000000CaWW';
        insert ecSetting;

        Email_to_Case__c ecSetting1 = new Email_to_Case__c();
        ecSetting1.Name = 'ProdMgmt';
        ecSetting1.CaseType__c = '';
        ecSetting1.Priority__c = 'Medium';
        ecSetting1.delimiter__c = '#case';
        ecSetting1.EmailTemplate__c ='00XA0000000cIp6';
        ecSetting1.Queue_Email__c ='China-app-sf-qaa@akamai.com';
        ecSetting1.GroupEmail__c ='chinacdn_application-qaa@akamai.com';
        ecSetting1.CaseRecord__c ='012A0000000OmQ8';
        ecSetting1.ContextAlias__c ='CRMOPS';
        ecSetting1.Severity__c ='3 - Difficult to do job';
        ecSetting1.Contact__c ='003A000000Zs1L4';
        ecSetting1.OrgWide__c ='0D2A00000004CpJ';
        ecSetting1.reporterId__c ='0B7A0000000CaWW';
        insert ecSetting1;

        SCRecordTypeCustomSetting__c scRecordTypeCustomSetting1 = new SCRecordTypeCustomSetting__c();
        scRecordTypeCustomSetting1.Name = 'NotificationTeam';
        scRecordTypeCustomSetting1.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';
        scRecordTypeCustomSetting1.RecordTypeDeveloperName__c = '';
        insert scRecordTypeCustomSetting1;

        SC_FromEmailAddress__c scFromEmailAddress1 = new SC_FromEmailAddress__c();
        scFromEmailAddress1.Name = 'Noreply';
        scFromEmailAddress1.FromAddress__c = 'sf-no-reply@akamai.com';
        scFromEmailAddress1.OrgAddressId__c = '0D2G00000004FpYKAU';
        insert scFromEmailAddress1;

        PSA_Settings__c validateOnRecallSetting = new PSA_Settings__c();
        validateOnRecallSetting.name = 'Validation On Timecard Recall Active';
        validateOnRecallSetting.Value__c = 'Yes';
        insert validateOnRecallSetting;

        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;
        PSA_Settings__c projectManager;
        if(PSA_Settings__c.getInstance('Work Item Limit') == null){
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Work Item Limit';
            workItemLimit.Value__c = '10';
            psaSettings.add(workItemLimit);
        }

        if(PSA_Settings__c.getInstance('Engineering Team Email') == null){
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Engineering Team Email';
            workItemLimit.Value__c = 'services-engg@akamai.com';
            psaSettings.add(workItemLimit);   
        }

        if(PSA_Settings__c.getInstance('Project Manager') == null){
            projectManager = new PSA_Settings__c();
            projectManager.Name = 'Project Manager';
            projectManager.Value__c = resource.Id;
            psaSettings.add(projectManager);            
        }

        if(!psaSettings.isEmpty()){
            insert psaSettings;
        }

        // For Contract Record
        contractList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c mergeContract;
        for(integer count =0; count < 5 ; count++)
        {    
            mergeContract = new Merge_Contract_Header__c();
            mergeContract.Name                       ='GSS Test Merge Contract-' + count;
            mergeContract.Contract_Id__c             ='GSS-Test-MC-123-' + count;
            mergeContract.Original_Contract_Id__c    ='GSS-Test-MC-123-' + count;
            mergeContract.Account_Name__c            = accRec.Id;
            mergeContract.Locked__c                  = true;
            mergeContract.Cancellation_Date__c       = Null;
            mergeContract.Contract_Transferred_To__c = Null;
            mergeContract.Effective_Start_Date__c    = System.Today();
            mergeContract.Effective_End_Date__c      = System.today().addYears(1);
            mergeContract.AKAM_Created_Date__c       = System.Today();
            mergeContract.Active__c                  = true;
            mergeContract.CI_Account_Name__c         = 'AKAM_ACCOUNT_ID';
            
            contractList.add(mergeContract);
        }
        insert contractList;

        

        List<pse__Proj__c> projectTemplatesList = new List<pse__Proj__c>();

        pse__Proj__c projectTemplate                                = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, accRec.Id);
        projectTemplate.pse__Expense_Notes__c                       = 'GSS Product/Managed Security Service_SCA-Project Template';
        projectTemplate.pse__Project_Type__c                        = 'GSS Product';
        projectTemplate.Project_Sub_Type__c                         = 'Managed Security Service';
        projectTemplate.Ongoing_Project_Recurring_Budget_Amt__c     = 0;
        projectTemplate.Ongoing_Project_Recurring_Planned_Hour__c   = 0;
        projectTemplatesList.add(projectTemplate);

        projectTemplate                                             = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, accRec.Id);
        projectTemplate.pse__Expense_Notes__c                       = 'GSS Product/Managed Security Service_TSR-Project Template';
        projectTemplate.pse__Project_Type__c                        = 'GSS Product';
        projectTemplate.Project_Sub_Type__c                         = 'Managed Security Service';
        projectTemplate.Ongoing_Project_Recurring_Budget_Amt__c     = 0;
        projectTemplate.Ongoing_Project_Recurring_Planned_Hour__c   = 0;
        projectTemplatesList.add(projectTemplate);

        projectTemplate                                             = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, accRec.Id);        
        projectTemplate.pse__Expense_Notes__c                       = 'GSS Product/Managed Security Service_SSP-Project Template';
        projectTemplate.pse__Project_Type__c                        = 'GSS Product';
        projectTemplate.Project_Sub_Type__c                         = 'Managed Security Service';
        projectTemplate.Ongoing_Project_Recurring_Budget_Amt__c     = 0;
        projectTemplate.Ongoing_Project_Recurring_Planned_Hour__c   = 0;
        projectTemplatesList.add(projectTemplate);

        insert projectTemplatesList;

        List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
        Map<String,Id> projectTemplateNameToIdMap = new Map<String,Id>();
        for(pse__Proj__c eachTemplate : projectTemplatesList)
        {
            eachTemplate.Name = eachTemplate.pse__Expense_Notes__c;
            eachTemplate.pse__Expense_Notes__c = '';
            eachTemplate.pse__Is_Template__c = true;
            milestoneList.add(testUtil.newMilestone(false,eachTemplate.id,0,date.today().addDays(1)));
            projectTemplateNameToIdMap.put(eachTemplate.Name,eachTemplate.Id);
        }
        update projectTemplatesList;
        insert milestoneList;

        
        // For GSS Autogen
        autogenList = new List<GSS_Autogen__c>();
        GSS_Autogen__c gssAutogen;
        for(integer count =0; count < 3 ; count++)
        {
            gssAutogen = new GSS_Autogen__c();
            gssAutogen.Case_Description__c          = 'Test Description';
            gssAutogen.Case_Record_Type__c          = 'Professional Services';
            gssAutogen.Case_Request_Type__c         = 'Customer Onboarding';
            gssAutogen.Case_Sub_Type__c             = '';
            gssAutogen.Case_Severity__c             = '3';
            gssAutogen.Inactive__c                  = false;
            gssAutogen.Project_Name__c              = 'MSS Project';
            if(count == 0){
                gssAutogen.Triggering_Product_ID__c         = 'M-LC-168609';
                gssAutogen.Triggering_Unit_of_Measure__c    = 'Hour';
                gssAutogen.Triggering_Billing_Duration__c   = 'Quarterly';
                gssAutogen.Case_Service__c                  = 'Managed Security Service';
                gssAutogen.Case_Subject__c                  = 'MSS::Customer Onboarding::';
                
                gssAutogen.Project_Template__c                  = projectTemplateNameToIdMap.get('GSS Product/Managed Security Service_SCA-Project Template');
                gssAutogen.Project_Name__c                      = 'Managed Security Service_SCA';
                gssAutogen.IS_Normal_Quarterly_Hours_Project__c = true;
                gssAutogen.IS_Bucket_Project__c                 = false;
                gssAutogen.Fixed_Hours_Per_Month__c             = 0;
                gssAutogen.Fixed_Hours_Per_Quarter__c           = 0;
                gssAutogen.LOE_Per_Unit_Low__c                  = 0;


            }
            if(count == 1){
                gssAutogen.Triggering_Product_ID__c         = 'M-LC-168609';
                gssAutogen.Triggering_Unit_of_Measure__c    = 'Reviews';
                gssAutogen.Triggering_Billing_Duration__c   = 'Annual';
                gssAutogen.Case_Service__c                  = 'Managed Security Service';
                gssAutogen.Case_Subject__c                  = 'MSS::Customer Onboarding::';

                gssAutogen.Project_Template__c                      = projectTemplateNameToIdMap.get('GSS Product/Managed Security Service_TSR-Project Template');
                gssAutogen.Project_Name__c                          = 'Managed Security Service_TSR';
                gssAutogen.IS_Normal_Quarterly_Hours_Project__c     = false;
                gssAutogen.IS_Bucket_Project__c                     = false;
                gssAutogen.Fixed_Hours_Per_Month__c                 = 0;
                gssAutogen.Fixed_Hours_Per_Quarter__c               = 0;
                gssAutogen.LOE_Per_Unit_Low__c                      = 16;
            }
            if(count == 2){
                gssAutogen.Triggering_Product_ID__c         = 'M-LC-168609';
                gssAutogen.Triggering_Unit_of_Measure__c    = 'Per Month';
                gssAutogen.Triggering_Billing_Duration__c   = 'Monthly';
                gssAutogen.Case_Service__c                  = 'Managed Security Service';
                gssAutogen.Case_Subject__c                  = 'MSS::Customer Onboarding::';

                gssAutogen.Project_Template__c                  = projectTemplateNameToIdMap.get('GSS Product/Managed Security Service_SSP-Project Template');
                gssAutogen.Project_Name__c                      = 'Managed Security Service_SSP';
                gssAutogen.IS_Normal_Quarterly_Hours_Project__c = false;
                gssAutogen.IS_Bucket_Project__c                 = false;
                gssAutogen.Fixed_Hours_Per_Month__c             = 0;
                gssAutogen.Fixed_Hours_Per_Quarter__c           = 51;
                gssAutogen.LOE_Per_Unit_Low__c                  = 0;
            }
            autogenList.add(gssAutogen);
        }
        insert autogenList;
        
        //Create ACHD for Contract
        SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(true,false);
        synchHeader.HeaderSyncMethod(contractList);
    }
    
    // Method-2: Return CLI
    public static Merge_Contract_Detail__c setContractLineData(String productId, String unitOfMeasure, String billingDuration, String uniqueId)
    {
        Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c();
        contractDetail.Product_Id__c = productId;
        contractDetail.Effective_Start_Date__c = System.Today();
        contractDetail.Effective_End_Date__c = System.Today().addMonths(6);
        contractDetail.Unit_of_Measure__c = unitOfMeasure;
        contractDetail.Billing_Duration__c = billingDuration;
        contractDetail.Record_Type__c = 'Committed';
        contractDetail.AKAM_Created_Date__c = System.now();
        contractDetail.Original_Detail_Id__c  = contractList[0].Id + uniqueId;    
        contractDetail.Original_Contract_Id__c = contractList[0].Id;
        return contractDetail;
    }
    
    // Method-3 - Setting Contract Line Data for All Use Case
    public static void createContractLine(){
        // Creating Contract Line
        List<Merge_Contract_Detail__c> allCLIList = new List<Merge_Contract_Detail__c>();
        
        // Creating one MSS Product
        Merge_Contract_Detail__c cli1  = new Merge_Contract_Detail__c();
        cli1 = setContractLineData('M-LC-168609','Reviews','Annual','G1');
        allCLIList.add(cli1);
        
        Merge_Contract_Detail__c cli2  = new Merge_Contract_Detail__c();
        cli2 = setContractLineData('M-LC-168609','Reviews','Annual1','G2');
        allCLIList.add(cli2);
        
        Merge_Contract_Detail__c cli3  = new Merge_Contract_Detail__c();
        cli3 = setContractLineData('M-LC-168609','Hour','Quarterly','G3');
        allCLIList.add(cli3);

        Merge_Contract_Detail__c cli4  = new Merge_Contract_Detail__c();
        cli4 = setContractLineData('M-LC-168609','Per Month','Monthly','G4');
        allCLIList.add(cli4);
        
        insert allCLIList;
        
        //Create ACHD for CLI
        SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(false,false);
        synchHeader.DetailSyncMethod(allCLIList);
    }
    
   
    // Method-4 - 
    public static testMethod void gssAutogenTest()
    {
        testDataSetup();
        createContractLine();
        Test.startTest(); 
        System.runAs(usr)
        {
            GSS_Autogen_Batch autogenJob = new GSS_Autogen_Batch(); 
            autogenJob.noOfErrors = 2;
            // Calling all the Batch Class
            Database.executeBatch(autogenJob);
        }
                    
        Test.stopTest(); 
    }
    
    public static testMethod void gssAutogenExistingCase()
    {
        testDataSetup();
        Test.startTest(); 

        System.runAs(usr)
        {
            Case existingCase = new Case();
            existingCase.Subject = 'MSS::Customer Onboarding::';
            existingCase.Service__c = 'Managed Security Service';
            existingCase.Severity__c = '3';
            existingCase.Status = 'Unassigned';
            existingCase.Sub_Type__c = '';
            existingCase.Do_Not_Show_In_Portal_Picklist__c = '';
            existingCase.Contract__c = contractList[0].Id;
            existingCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            existingCase.Validation_Override__c = true;
            existingCase.Origin = 'Autogen';
            insert existingCase;
            
            Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c();
            contractDetail.Product_Id__c = 'M-LC-168609';
            contractDetail.Effective_Start_Date__c = System.Today();
            contractDetail.Effective_End_Date__c = System.Today().addMonths(6);
            contractDetail.Unit_of_Measure__c = 'Hour';
            contractDetail.Billing_Duration__c = 'Quarterly';
            contractDetail.Record_Type__c = 'Committed';
            contractDetail.AKAM_Created_Date__c = System.now();
            contractDetail.Original_Detail_Id__c  = contractList[0].Id + 'GSS-Autogen-3';    
            contractDetail.Original_Contract_Id__c = contractList[0].Id;
            
            List<Merge_Contract_Detail__c> cliList = new List<Merge_Contract_Detail__c>();
            cliList.add(contractDetail);
            insert cliList;
            
            SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(false,false);
            synchHeader.DetailSyncMethod(cliList);
            
            GSS_Autogen_Batch autogenJobNew = new GSS_Autogen_Batch(); 
            Database.executeBatch(autogenJobNew);
        }
        
        Test.stopTest(); 
    }
}