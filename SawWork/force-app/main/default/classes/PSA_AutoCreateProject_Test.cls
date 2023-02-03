/*
 Developer              Date                Description
Sharath Ravishankar     24th April 2017     Test method testProjectCreationPSE has been added to cover 
                                            the class PSA_AutoCreatePSProject and few lines of PSA_AutogenProjectBatch
Sharath Ravishankar     24th May 2017       FFPSA-232 : Added contract details for testProjectCreationPSE to increase the coverage 
                                            for class PSA_AutoCreatePSProject for the new requirement 

Sharath Prasanna        23rd June 2017      FFPSA-180 : Covered the code for autogen of TAS products

Sharath Prasanna        24th Oct 2017       FFPSA-266 : Covered the code for the autogen of RRS products    

Sharath Prasanna        3rd April 2018      FFPSA-271 : Covered the code for autogen of PSS products

Sharath Prasanna        31st Oct 2018       FFPSA-598 : Covered the code for autogen of PNP SMP + SOA

Sandeep Naga            18th June 2019      FFPSA-973 : Covered the code for autogen of PLUS and PS Hours

Sujay                   1st OCT 2019        FFPSA-972 : Covered the code for autogen of Advanced Products

Sandeep Naga            19th DEC 2019      FFPSA-1148 : Covered the code for autogen of MSS Kona and Bot Manager

Sandeep Naga            26th MAY 2020       FFPSA-1295 : Covered code for Advanced Project Management Autogen Enhancement

Sandeep Naga            8th JUNE 2020       FFPSA-1055 : Covered code for autogen of mPulse Autogen
*/

//tets 
@isTest(SeeAllData=false)
public class PSA_AutoCreateProject_Test 
{

    public static PSA_TestUtility testUtil;
    public static Account acct;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetail1;
    public static Merge_Contract_Detail__c contDetail2;
    public static Merge_Contract_Detail__c contDetail3;
    public static Merge_Contract_Detail__c contDetail4;
    public static Merge_Contract_Detail__c contDetail5;
    public static Merge_Contract_Detail__c contDetail6;
    public static Merge_Contract_Detail__c contDetail7;
    public static Case caseCOB;

    
    public static pse__Region__c reg;
    public static pse__Practice__c pract;
    public static User usr;
    public static Contact resource;
    public static Id professionalServicesId;

    

    static
    {

        testUtil = new PSA_TestUtility();
        professionalServicesId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        //creating the account: The account territory is set to undefined
        acct = testUtil.newAccount(true);
        acct.TERR_HIER_5__c = 'Undefined';
        update acct;

        //Creating the region with name as Undefined (Territory)
        reg = new pse__Region__c();
        reg.Name = 'Undefined' + ' (Territory)';
        insert reg;


        //Create Project Template Data
        pract = testUtil.newPracticeMaster(true);
        usr = testUtil.newUserSysAdmin(true); 
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        testUtil.newPermissionControl(true, usr.Id, reg.Id);

        //Create all custom settings required  
        // SC_BOCC_Setup__c scBOCCSetup = new SC_BOCC_Setup__c();
        // scBOCCSetup.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scBOCCSetup.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scBOCCSetup.Product_Id__c = 'M-LC-160618';
        // scBOCCSetup.Name = 'BOCC';
        // insert scBOCCSetup;
        

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
        
        SC_RiverbedCaseProdID__c sc_RiverbedCaseProdIDSetting = new SC_RiverbedCaseProdID__c();
        sc_RiverbedCaseProdIDSetting.Name = 'Riverbed_SAAS_OEM';
        sc_RiverbedCaseProdIDSetting.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        sc_RiverbedCaseProdIDSetting.RecordTypeID__c = '012G0000000z10xIAA';

        insert sc_RiverbedCaseProdIDSetting;

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

        SC_FromEmailAddress__c sc_FromEmailAddress1 = new SC_FromEmailAddress__c();
        sc_FromEmailAddress1.Name = 'Noreply';
        sc_FromEmailAddress1.FromAddress__c = 'sf-no-reply@akamai.com';
        sc_FromEmailAddress1.OrgAddressId__c = '0D2G00000004FpYKAU';
        insert sc_FromEmailAddress1;

        PSA_Settings__c validateOnRecallSetting = new PSA_Settings__c();
        validateOnRecallSetting.name = 'Validation On Timecard Recall Active';
        validateOnRecallSetting.Value__c = 'Yes';
        insert validateOnRecallSetting;



        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;
        PSA_Settings__c projectManager;
        if(PSA_Settings__c.getInstance('Work Item Limit') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Work Item Limit';
            workItemLimit.Value__c = '10';
            psaSettings.add(workItemLimit);
            
        }

        if(PSA_Settings__c.getInstance('Engineering Team Email') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Engineering Team Email';
            workItemLimit.Value__c = 'services-engg@akamai.com';
            psaSettings.add(workItemLimit);
            
        }

        if(PSA_Settings__c.getInstance('Project Manager') == null)
        {
            projectManager = new PSA_Settings__c();
            projectManager.Name = 'Project Manager';
            projectManager.Value__c = resource.Id;
            psaSettings.add(projectManager);
            
        }

        if(!psaSettings.isEmpty())
        {
            insert psaSettings;
        }


        

        

        

        
        //Creating the contract: The contract is not inserted.
        contract = testUtil.newContract(false, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contract.Locked__c = TRUE;
        contract.Cancellation_Date__c = null;
        contract.Contract_Transferred_To__c = null;
        contract.Active__c = true;
        contract.Currency__c = 'USD';
        contract.Original_Contract_Id__c = reg.id;

        //creating the  contract details
        contDetail1 = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail2= testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail3= testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail4 =testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail5 =testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail6 =testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail7 =testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        
        //creating the case. The case has to be linked to the contract
        caseCOB = new Case();
        //caseCOB.RecordTypeId = '012G0000000z10uIAA';
        caseCOB.RecordTypeId = professionalServicesId;
        caseCOB.AKAM_Created_Date__c = System.now();
        caseCOB.AKAM_System__c = 'FORCE';
        caseCOB.AKAM_Created_By__c = 'CRMOPS';
        caseCOB.Origin = 'Proactive';
        caseCOB.Request_Type__c = 'Customer Onboarding';
        caseCOB.Service__c = 'Accounts Audits';
        caseCOB.Subject = 'Test Case For PIHC';
        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.Contract__c = contract.Id;
        caseCOB.AccountId = acct.Id;
        caseCOB.Validation_Override__c = true;
        
        
        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - Kona - Security Services Primary - Project Template','GSS Product','Managed Security Service - Kona Site Defender'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - Kona - Technical Reviews – Project Template','GSS Product','Managed Security Service - Kona Site Defender'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - Kona - Security Config Assistance – Project Template','GSS Product','Managed Security Service - Kona Site Defender'));

        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan - Security Services Primary - Project Template','GSS Product','Managed Security Service - Bot Manager Premier'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan - Technical Reviews – Project Template','GSS Product','Managed Security Service - Bot Manager Premier'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan - Security Configuration Assistance – Project Template','GSS Product','Managed Security Service - Bot Manager Premier'));

        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan + Kona - Security Services Primary - Project Template','GSS Product','Managed Security Service - Bot Manager Premier & Kona Site Defender'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan + Kona - Technical Reviews – Project Template','GSS Product','Managed Security Service - Bot Manager Premier & Kona Site Defender'));
        projTemplatesList.add(createProjectTemplate('GSS Products/MSS - BotMan + Kona - Security Config Assistance – Project Template','GSS Product','Managed Security Service - Bot Manager Premier & Kona Site Defender'));

        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - Support Advocacy – Project Template','GSS Product','Premium 3.0'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - PS Hours – Project Template','GSS Product','Premium 3.0'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - Technical Business Assessments – Template','GSS Product','Premium 3.0'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - Technical Advisory – Project Template','GSS Product','Premium 3.0'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - Akamai University – Project Template','GSS Product','Premium 3.0'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Premium 3.0 - Off-Hour Configuration Assistance – Project Template','GSS Product','Premium 3.0'));

        insert projTemplatesList;
        
        createProjectTemplateMilestone(projTemplatesList);


        //Create all the required project templates
        

        //1. Service Management 2.0::Service Management
        //SMP cant find in template

        //2. Security Optimization Assistance : SOA

        //3. Managed Kona Site Defender - No Reviews : MKSD
        //4. Managed Kona Site Defender - with Reviews

        //5. Guided Delivery Services : GDS

        //6. Professional Services - Enterprise : PS-E

        //7. Technical Advisory Services : TAS

        //8. Readiness and Response Service : RRS

        //9. Professional Services - Security : PSS

        //10. PNP : PPN-SOA-SMP
        //11. PNP2

        //12. Plus : PLUS_PSHOURS
        
        //13, Advanced : Advanced

        
        
        
    }

    
    //method to create project template
    public static pse__Proj__c createProjectTemplate(String projectTemplateName, String projectTemplateType, String projectTemplateSubType)
    {
        testUtil = new PSA_TestUtility();
        //System.debug('@@@createProjectTemplate');
        //System.debug('@@@projectTemplateName: '+projectTemplateName);
        //System.debug('@@@projectTemplateType: '+projectTemplateType);
        //System.debug('@@@projectTemplateSubType: '+projectTemplateSubType);

        //System.debug('@@@reg.Id: '+reg.Id);
        //System.debug('@@@pract.Id: '+pract.Id);
        //System.debug('@@@resource.Id: '+resource.Id);
        //System.debug('@@@acct.Id: '+acct.Id);

        pse__Proj__c projectTemplate = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        
        //System.debug('@@@TESTCLASS: projectTemplate 1: '+projectTemplate);
        //projectTemplate.pse__Is_Template__c = true;
        projectTemplate.pse__Expense_Notes__c = projectTemplateName;
        projectTemplate.pse__Project_Type__c = projectTemplateType;
        projectTemplate.Project_Sub_Type__c = projectTemplateSubType;
        projectTemplate.Ongoing_Project_Recurring_Budget_Amt__c = 0;
        projectTemplate.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        //System.debug('@@@TESTCLASS: projectTemplate 2: '+projectTemplate);
        return projectTemplate;
    }

    public static void createProjectTemplateMilestone(List<pse__Proj__c> projTemplatesList)
    {
        List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
        for(pse__Proj__c eachTemplate : projTemplatesList)
        {
            eachTemplate.Name = eachTemplate.pse__Expense_Notes__c;
            eachTemplate.pse__Expense_Notes__c = '';
            eachTemplate.pse__Is_Template__c = true;
            milestoneList.add(testUtil.newMilestone(false,eachTemplate.id,0,date.today().addDays(1)));
        }
        update projTemplatesList;
        insert milestoneList;
    }

      
   
    //test function for SMP
    public static testMethod void testProjectCreation()
    {

        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Service Management (MRR) - Project Template','GSS Product','Service Management'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Service Management (OS) - Project Template','GSS Product','Service Management'));

        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-120877';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Service Management 2.0::Service Management';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-120877';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Configurations';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Service Management 2.0::Service Management';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-120877';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Service Management 2.0::Service Management';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail3);

        insert details;

        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.Autogen_UseCase__c = 'SMP-NonSecurity-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;


        PSA_AutoCreateBatchProject b = new PSA_AutoCreateBatchProject();
        Database.executeBatch(b);

        test.stopTest();
    }
    

    //Changes by Sharath: Adding the test method for the SOA product
    public static testMethod void testProjectCreationSOA()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Security Optimization Assistance_Service_Review - Project Template','GSS Product','Security Optimization Assistance'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Security Optimization Assistance_Config_Assistance-Project Template','GSS Product','Security Optimization Assistance'));

        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-160425';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Security Optimization Assistance';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-160425';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Security Optimization Assistance';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-160425';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Security Optimization Assistance';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        details.add(contDetail3);

        insert details;

        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.Autogen_UseCase__c = 'SOA-Parent';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;


        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);

        test.stopTest();
    }
    //Changes by Sharath: Adding the test method for the MKSD product
    public static testMethod void testProjectCreationMKSDwithoutReviews()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (TR) - Project Template','GSS Product','Managed Kona'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (SCSM) - Project Template','GSS Product','Managed Kona'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (Config. Assist.) - Project Template','GSS Product','Managed Kona'));

        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-139829';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Managed Kona Site Defender';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-139829';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Policies';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Managed Kona Site Defender';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-139829';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Managed Kona Site Defender';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        insert details;

        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.Autogen_UseCase__c = 'KONA-COB-WithKSD';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }
    //Changes by Sharath: Adding the test method for the MKSD product
    public static testMethod void testProjectCreationMKSDwithReviews()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (TR) - Project Template','GSS Product','Managed Kona'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (SCSM) - Project Template','GSS Product','Managed Kona'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Managed Kona (Config. Assist.) - Project Template','GSS Product','Managed Kona'));

        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-139829';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Managed Kona Site Defender';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-139829';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Policies';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Managed Kona Site Defender';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-139829';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Managed Kona Site Defender';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        contDetail4.Product_Id__c= 'M-LC-139829';
        contDetail4.Record_Type__c = 'Committed';
        contDetail4.Unit_of_Measure__c = 'Reviews';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Managed Kona Site Defender';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;

        details.add(contDetail4);

        insert details;

        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.Autogen_UseCase__c = 'KONA-COB-WithKSD';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }
    
    //Changes by Akhila: Adding the test method for the GDS product
    public static testMethod void testProjectCreationGDS()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Guided Delivery Service - Project Template','GSS Product','Guided Delivery Service'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-159905';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Guided Delivery Services';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-159905';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Unit';
        contDetail1.Billing_Duration__c = 'Quarterly';        
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Guided Delivery Services';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        insert details;

        caseCOB.Description = 'Test Case For GDS';
        caseCOB.Autogen_UseCase__c = 'GDS-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }
    
    //Changes by Sharath Ravishankar : Adding the test method for PS-E product
    public static testMethod void testProjectCreationPSE()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Bucket - Project Template','Professional Services','Bucket'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Time & Materials - Project Template','Professional Services','Time & Materials'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-135915';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Professional Services - Enterprise';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-135915';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Hour';
        contDetail2.Billing_Duration__c = 'Quarterly';        
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Professional Services - Enterprise';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-135915';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Billing_Duration__c = 'Quarterly';  
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Enterprise';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        contDetail4.Product_Id__c= 'M-LC-135915';
        contDetail4.Record_Type__c = 'Usage';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Billing_Duration__c = 'Quarterly';  
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Enterprise';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;

        details.add(contDetail4);

        contDetail5.Product_Id__c= 'M-LC-135915';
        contDetail5.Record_Type__c = 'Committed';
        contDetail5.Unit_of_Measure__c = 'Each';
        contDetail5.Billing_Duration__c = 'Quarterly';  
        contDetail5.Units_Low__c = 12;
        contDetail5.Unit_Price__c = 12;
        contDetail5.Original_Contract_Id__c = contract.id;
        contDetail5.Product__c = 'Professional Services - Enterprise';
        contDetail5.Units_High__c = 12;
        contDetail5.Original_Detail_Id__c = 'd5' + contract.id;

        details.add(contDetail5);

        insert details;

        caseCOB.Description = 'Test Case For PS-E';
        caseCOB.Autogen_UseCase__c = 'PSE-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sandeep Naga fro additional code coverage of PSE autogen projects
    public static testMethod void testProjectCreationPSE2()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Bucket - Project Template','Professional Services','Bucket'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Time & Materials - Project Template','Professional Services','Time & Materials'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-135915';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Annual';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Professional Services - Enterprise';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-135915';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Hour';
        contDetail2.Billing_Duration__c = 'Annual';        
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Professional Services - Enterprise';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-135915';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Billing_Duration__c = 'Annual';  
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Enterprise';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        contDetail4.Product_Id__c= 'M-LC-135915';
        contDetail4.Record_Type__c = 'Usage';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Billing_Duration__c = 'Annual';  
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Enterprise';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;

        details.add(contDetail4);

        contDetail5.Product_Id__c= 'M-LC-135915';
        contDetail5.Record_Type__c = 'Committed';
        contDetail5.Unit_of_Measure__c = 'Each';
        contDetail5.Billing_Duration__c = 'Annual';  
        contDetail5.Units_Low__c = 12;
        contDetail5.Unit_Price__c = 12;
        contDetail5.Original_Contract_Id__c = contract.id;
        contDetail5.Product__c = 'Professional Services - Enterprise';
        contDetail5.Units_High__c = 12;
        contDetail5.Original_Detail_Id__c = 'd5' + contract.id;

        details.add(contDetail5);

        insert details;

        caseCOB.Description = 'Test Case For PS-E';
        caseCOB.Autogen_UseCase__c = 'PSE-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sandeep Naga for failure case coverage of PSE autogen projects
    public static testMethod void testProjectCreationPSEFailCase()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Bucket - Project Template','Professional Services','Bucket'));
        projTemplatesList.add(createProjectTemplate('Professional Services/Time & Materials - Project Template','Professional Services','Time & Materials'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-135915';
        contDetail1.Record_Type__c = 'Usage';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Professional Services - Enterprise';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-135915';
        contDetail2.Record_Type__c = 'Usage';
        contDetail2.Unit_of_Measure__c = 'Hour';
        contDetail2.Billing_Duration__c = 'Quarterly';        
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Professional Services - Enterprise';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-135915';
        contDetail3.Record_Type__c = 'Usage';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Billing_Duration__c = 'Quarterly';  
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Enterprise';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        contDetail4.Product_Id__c= 'M-LC-135915';
        contDetail4.Record_Type__c = 'Overage';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Billing_Duration__c = 'Quarterly';  
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Enterprise';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;

        details.add(contDetail4);

        contDetail5.Product_Id__c= 'M-LC-135915';
        contDetail5.Record_Type__c = 'Usage';
        contDetail5.Unit_of_Measure__c = 'Each';
        contDetail5.Billing_Duration__c = 'Quarterly';  
        contDetail5.Units_Low__c = 12;
        contDetail5.Unit_Price__c = 12;
        contDetail5.Original_Contract_Id__c = contract.id;
        contDetail5.Product__c = 'Professional Services - Enterprise';
        contDetail5.Units_High__c = 12;
        contDetail5.Original_Detail_Id__c = 'd5' + contract.id;

        details.add(contDetail5);

        insert details;

        caseCOB.Description = 'Test Case For PS-E';
        caseCOB.Autogen_UseCase__c = 'PSE-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }



    //Changes by Sharath Prasanna: Adding the test method for the TAS product
    public static testMethod void testProjectCreationTAS()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Technical Advisory - Project Template','GSS Product','Technical Advisory'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);


        insert contract;

        contDetail1.Product_Id__c= 'M-LC-134267';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Technical Advisory Services';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-134267';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Hour';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Technical Advisory Services';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-134267';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Annual';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Technical Advisory Services';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        insert details;

        caseCOB.Description = 'Test Case For TAS';
        caseCOB.Autogen_UseCase__c = 'TAS-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutoCreateProjectUtil.sendErrorMails('Test','Test');
        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();


    }

    //Changes by Sharath: Adding the test method for the RRS product
    public static testMethod void testProjectCreationRRS()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Readiness & Response (SEM) - Project Template','GSS Product','Readiness & Response Service'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Readiness & Response Service (SSR)-Project Template','GSS Product','Readiness & Response Service'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Readiness & Response_Config Assist-Project Template','GSS Product','Readiness & Response Service'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-161467';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Readiness and Response Service';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-161467';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Readiness and Response Service';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-161467';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Readiness and Response Service';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);

        insert details;

        caseCOB.Description = 'Test Case For RRS';
        caseCOB.Autogen_UseCase__c = 'RRS-Parent';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        
        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sharath: Adding the test method for the PSS product
    public static testMethod void testProjectCreationPSS()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/PS-Security - Project Template','GSS Product','PS-Security'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        insert contract;

        contDetail1.Product_Id__c= 'M-LC-159904';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Hour';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Professional Services - Security';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-159904';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Hour';
        contDetail2.Billing_Duration__c = 'Annual';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Professional Services - Security';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-159904';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Security';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;

        details.add(contDetail3);


        contDetail4.Product_Id__c= 'M-LC-159904';
        contDetail4.Record_Type__c = 'Usage';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Security';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;

        details.add(contDetail4);

        insert details;
        
        caseCOB.Description = 'Test Case For PSS';
        caseCOB.Autogen_UseCase__c = 'PSS-COB';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        insert caseCOB;

        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }



    //Changes by Sharath: Adding the test method for the PNP -SOA and SMP product
    public static testMethod void testProjectCreationPNP()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Service Management (OS) - Project Template','GSS Product','Service Management'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Security Optimization Assistance_Service_Review - Project Template','GSS Product','Security Optimization Assistance'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);


        insert contract;

        contDetail1.Product_Id__c= 'M-LC-162752';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'PNP';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-162635';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'PNP';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-162764';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Configurations';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Security';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail3);


        contDetail4.Product_Id__c= 'M-LC-162752';
        contDetail4.Record_Type__c = 'Committed';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Billing_Duration__c = 'Monthly';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Security';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;
        contDetail4.Effective_Start_Date__c = date.today();
        contDetail4.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail4);

        insert details;
        

        List<Case> cases = new List<Case>();
        caseCOB.Description = 'Test Case For PSS';
        caseCOB.Service__c = 'Service Management';
        caseCOB.Autogen_UseCase__c = 'PPSOPSM';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        cases.add(caseCOB);

        case case2COB = new Case();
        //case2COB.RecordTypeId = '012G0000000z10uIAA';
        case2COB.RecordTypeId = professionalServicesId;
        case2COB.AKAM_Created_Date__c = System.now();
        case2COB.AKAM_System__c = 'FORCE';
        case2COB.AKAM_Created_By__c = 'CRMOPS';
        case2COB.Origin = 'Proactive';
        case2COB.Request_Type__c = 'Customer Onboarding';
        case2COB.Service__c = 'Security Optimization Assistance';
        case2COB.Subject = 'Test Case For PIHC';
        case2COB.Description = 'Test Case For PIHC';
        case2COB.Contract__c = contract.Id;
        case2COB.AccountId = acct.Id;
        case2COB.Autogen_UseCase__c = 'PPSOPSM';
        case2COB.Validation_Override__c = true;
        cases.add(case2COB);
        
        insert cases;

        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sharath: Adding the test method for the PNP -SOA and SMP product
    public static testMethod void testProjectCreationPNP2()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Service Management (OS) - Project Template','Professional Services','Service Management'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Security Optimization Assistance_Service_Review - Project Template','Professional Services','Security Optimization Assistance'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);


        insert contract;

        contDetail1.Product_Id__c= 'M-LC-162752';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'PNP';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-162635';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'PNP';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-162764';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Configurations';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Security';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail3);



        insert details;
        

        List<Case> cases = new List<Case>();
        caseCOB.Description = 'Test Case For PSS';
        caseCOB.Service__c = 'Service Management';
        caseCOB.Autogen_UseCase__c = 'PPSOPSM';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        cases.add(caseCOB);

        case case2COB = new Case();
        //case2COB.RecordTypeId = '012G0000000z10uIAA';
        case2COB.RecordTypeId = professionalServicesId;
        case2COB.AKAM_Created_Date__c = System.now();
        case2COB.AKAM_System__c = 'FORCE';
        case2COB.AKAM_Created_By__c = 'CRMOPS';
        case2COB.Origin = 'Proactive';
        case2COB.Request_Type__c = 'Customer Onboarding';
        case2COB.Service__c = 'Security Optimization Assistance';
        case2COB.Subject = 'Test Case For PIHC';
        case2COB.Description = 'Test Case For PIHC';
        case2COB.Contract__c = contract.Id;
        case2COB.AccountId = acct.Id;
        case2COB.Autogen_UseCase__c = 'PPSOPSM';
        case2COB.Validation_Override__c = true;
        cases.add(case2COB);
        
        insert cases;

        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sandeep Naga : Adding the test method for PNP failure case to get code coverage
    public static testMethod void testProjectCreationPNPFailureCase()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('Professional Services/MRR - Project Template','Professional Services','MRR'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Service Management (OS) - Project Template','GSS Product','Service Management'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Security Optimization Assistance_Service_Review - Project Template','GSS Product','Security Optimization Assistance'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);


        insert contract;

        contDetail1.Product_Id__c= 'M-LC-162752';
        contDetail1.Record_Type__c = 'Usage';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'PNP';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-162635';
        contDetail2.Record_Type__c = 'Usage';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'PNP';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-162764';
        contDetail3.Record_Type__c = 'Usage';
        contDetail3.Unit_of_Measure__c = 'Configurations';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Professional Services - Security';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail3);


        contDetail4.Product_Id__c= 'M-LC-162752';
        contDetail4.Record_Type__c = 'Usage';
        contDetail4.Unit_of_Measure__c = 'Hour';
        contDetail4.Billing_Duration__c = 'Monthly';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Professional Services - Security';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;
        contDetail4.Effective_Start_Date__c = date.today();
        contDetail4.Effective_End_Date__c = date.today().addDays(400);

        details.add(contDetail4);

        insert details;
        

        List<Case> cases = new List<Case>();
        caseCOB.Description = 'Test Case For PSS';
        caseCOB.Service__c = 'Service Management';
        caseCOB.Autogen_UseCase__c = 'PPSOPSM';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        cases.add(caseCOB);

        case case2COB = new Case();
        //case2COB.RecordTypeId = '012G0000000z10uIAA';
        case2COB.RecordTypeId = professionalServicesId;
        case2COB.AKAM_Created_Date__c = System.now();
        case2COB.AKAM_System__c = 'FORCE';
        case2COB.AKAM_Created_By__c = 'CRMOPS';
        case2COB.Origin = 'Proactive';
        case2COB.Request_Type__c = 'Customer Onboarding';
        case2COB.Service__c = 'Security Optimization Assistance';
        case2COB.Subject = 'Test Case For PIHC';
        case2COB.Description = 'Test Case For PIHC';
        case2COB.Contract__c = contract.Id;
        case2COB.AccountId = acct.Id;
        case2COB.Autogen_UseCase__c = 'PPSOPSM';
        case2COB.Validation_Override__c = true;
        cases.add(case2COB);
        
        insert cases;

        PSA_AutogenProjectBatch b = new PSA_AutogenProjectBatch();
        Database.executeBatch(b);
        test.stopTest();
    }

    //Changes by Sandeep Naga : Adding the test method for PLUS and PS Hours
    public static testMethod void testProjectCreationPLUSAndPSHours()
    {

        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Plus - Monthly Service Report – Project Template','GSS Product','Plus'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Plus - Professional Services – Project Template','GSS Product','Plus'));
     
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);


        

        insert contract;

        //System.debug('@@@contract.id: '+contract.id);

        contDetail1.Product_Id__c= 'M-LC-165777';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Plus Service and Support';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail1.Name = 'P-2QDL1F0';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);

        //System.debug('@@@contDetail1: '+contDetail1);

        details.add(contDetail1);

        contDetail2.Product_Id__c= 'M-LC-165777';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Configurations';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Plus Service and Support';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail2.Name = 'P-2QDL1EY';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);

        //System.debug('@@@contDetail2: '+contDetail2);

        details.add(contDetail2);

        contDetail3.Product_Id__c= 'M-LC-165777';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Plus Service and Support';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);

        //System.debug('@@@contDetail3: '+contDetail3);

        details.add(contDetail3);



        insert details;
        //System.debug('@@@details: '+details);

        List<Case> cases = new List<Case>();
        //caseCOB.Description = 'Test Case For PSS';
        //caseCOB.Service__c = 'Service Management';
        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'Plus';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);

       
        
        insert cases;


        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }

    
    //Changes by Sujay - FFPSA-972 Adding the test method for Advanced
    public static testMethod void testProjectCreationForAdvancedProducts()
    {

        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        
        test.startTest();

        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/Advanced - Service Reports – Project Template','GSS Product','Advanced'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Advanced - Professional Services – Project Template','GSS Product','Advanced'));
        projTemplatesList.add(createProjectTemplate('GSS Products/Advanced - Technical Advisory – Project Template','GSS Product','Advanced'));
     
        //FFPSA-1295: Changes by Sandeep
        projTemplatesList.add(createProjectTemplate('GSS Products/Advanced - Project Management – Project Template','GSS Product','Advanced'));
        
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);

        //insert the Header Info
        insert contract;

        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-165776';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Advanced Service and Support';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail1.Name = 'P-2QDL1F0';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Config CLI
        contDetail2.Product_Id__c= 'M-LC-165776';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Configurations';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Advanced Service and Support';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail2.Name = 'P-2QDL1EY';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Hour CLI
        contDetail3.Product_Id__c= 'M-LC-165776';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Advanced Service and Support';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);
        
        //FFPSA-1295 : Changes by Sandeep
        //Per Month CLI for Project Management
        contDetail4.Product_Id__c= 'M-LC-165782';
        contDetail4.Record_Type__c = 'Committed';
        contDetail4.Unit_of_Measure__c = 'Per Month';
        contDetail4.Billing_Duration__c = 'Monthly';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Advanced Service and Support';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'P-2QDL1GG';
        contDetail4.Name = 'P-2QDL1GG';
        contDetail4.Effective_Start_Date__c = date.today();
        contDetail4.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail4);
        
        List<Case> cases = new List<Case>();
        //caseCOB.Description = 'Test Case For PSS';
        //caseCOB.Service__c = 'Service Management';
        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'Advanced';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
        
        
        insert details;
        
        insert cases;

        Case caseTMP = new Case();
        //caseTMP.RecordTypeId = '012G0000000z10uIAA';
        caseTMP.RecordTypeId = professionalServicesId;
        caseTMP.AKAM_Created_Date__c = System.now();
        caseTMP.AKAM_System__c = 'FORCE';
        caseTMP.AKAM_Created_By__c = 'CRMOPS';
        caseTMP.Origin = 'Proactive';
        caseTMP.Request_Type__c = 'Customer Onboarding';
        caseTMP.Service__c = 'Accounts Audits';
        caseTMP.Subject = 'Test Case For PIHC';
        caseTMP.Description = 'Test Case For PIHC';
        caseTMP.Contract__c = contract.Id;
        caseTMP.AccountId = acct.Id;
        caseTMP.Validation_Override__c = true;
        caseTMP.Origin = 'Autogen';
        caseTMP.Autogen_UseCase__c = 'Project Management Option';
        caseTMP.Contract__c = contract.Id;
        caseTMP.Validation_Override__c = true;
        caseTMP.Contract_Detail__c = contDetail4.Name;
        caseTMP.ParentId = caseCOB.Id;
        
        insert caseTMP;
        

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }

    //Changes by Sandeep - FFPSA-1148 Adding the test method for MSS Kona, MSS Bot Manager, MSS Kona & Bot Manager
    public static testMethod void testProjectCreationForMSSKona()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        List<Case> cases = new List<Case>();
        
        test.startTest();

        //insert the Header Info
        insert contract;

        //MSS Kona Data

        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-166459';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'MSS Kona';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail1.Name = 'P-2QDL1EY';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Reviews CLI
        contDetail2.Product_Id__c= 'M-LC-166459';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'MSS Kona';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail2.Name = 'P-2QDL1F0';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Hour CLI
        contDetail3.Product_Id__c= 'M-LC-166459';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'MSS Kona';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);

        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'MSS - Kona Site Defender';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
 
        insert details;
        insert cases;

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }
    
    public static testMethod void testProjectCreationForMSSBotManager()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        List<Case> cases = new List<Case>();
        
        test.startTest();

        //insert the Header Info
        insert contract;

        //MSS Bot Manager Data

        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-166458';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'MSS Bot Manager';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail1.Name = 'P-2QDL1EY';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Reviews CLI
        contDetail2.Product_Id__c= 'M-LC-166458';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'MSS Bot Manager';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail2.Name = 'P-2QDL1F0';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Hour CLI
        contDetail3.Product_Id__c= 'M-LC-166458';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'MSS Bot Manager';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);

        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'MSS - Bot Manager Premier';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
 
        insert details;
        insert cases;

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }
    
    public static testMethod void testProjectCreationForMSSKonaAndBotManager()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        List<Case> cases = new List<Case>();
        
        test.startTest();

        //insert the Header Info
        insert contract;

        //MSS Kona and Bot Manager Data

        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-166460';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'MSS BMP & KSD';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail1.Name = 'P-2QDL1EY';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Reviews CLI
        contDetail2.Product_Id__c= 'M-LC-166460';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Reviews';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'MSS BMP & KSD';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail2.Name = 'P-2QDL1F0';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Hour CLI
        contDetail3.Product_Id__c= 'M-LC-166460';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'MSS BMP & KSD';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);

        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'MSS - BMP & KSD';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
 
        insert details;
        insert cases;

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }


    public static testMethod void autoCreatePremiumTest()
    {

        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        List<Case> cases = new List<Case>();
        
        test.startTest();

        //insert the Header Info
        insert contract;

        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-165819';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail1.Original_Detail_Id__c = 'd1' + contract.id;
        contDetail1.Name = 'P-2QDL1EY';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Assessments CLI
        contDetail2.Product_Id__c= 'M-LC-165819';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Assessments';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'd2' + contract.id;
        contDetail2.Name = 'P-2QDL1F0';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Support Advocacy Hours CLI
        contDetail3.Product_Id__c= 'M-LC-165819';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Support Advocacy Hours';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);

        //Onsite Training Days CLI
        contDetail4.Product_Id__c= 'M-LC-165819';
        contDetail4.Record_Type__c = 'Committed';
        contDetail4.Unit_of_Measure__c = 'Onsite Training Days';
        contDetail4.Billing_Duration__c = 'Monthly';
        contDetail4.Units_Low__c = 12;
        contDetail4.Unit_Price__c = 12;
        contDetail4.Original_Contract_Id__c = contract.id;
        contDetail4.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail4.Units_High__c = 12;
        contDetail4.Original_Detail_Id__c = 'd4' + contract.id;
        contDetail4.Name = 'P-2QDL1AQ';
        contDetail4.Effective_Start_Date__c = date.today();
        contDetail4.Effective_End_Date__c = date.today().addDays(400);

        //Technical Advisory Hours CLI
        contDetail5.Product_Id__c= 'M-LC-165819';
        contDetail5.Record_Type__c = 'Committed';
        contDetail5.Unit_of_Measure__c = 'Technical Advisory Hours';
        contDetail5.Billing_Duration__c = 'Monthly';
        contDetail5.Units_Low__c = 12;
        contDetail5.Unit_Price__c = 12;
        contDetail5.Original_Contract_Id__c = contract.id;
        contDetail5.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail5.Units_High__c = 12;
        contDetail5.Original_Detail_Id__c = 'd5' + contract.id;
        contDetail5.Name = 'P-2QDL1WZ';
        contDetail5.Effective_Start_Date__c = date.today();
        contDetail5.Effective_End_Date__c = date.today().addDays(400);

        //Hour CLI
        contDetail6.Product_Id__c= 'M-LC-165819';
        contDetail6.Record_Type__c = 'Committed';
        contDetail6.Unit_of_Measure__c = 'Hour';
        contDetail6.Billing_Duration__c = 'Monthly';
        contDetail6.Units_Low__c = 12;
        contDetail6.Unit_Price__c = 12;
        contDetail6.Original_Contract_Id__c = contract.id;
        contDetail6.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail6.Units_High__c = 12;
        contDetail6.Original_Detail_Id__c = 'd6' + contract.id;
        contDetail6.Name = 'P-2QDL1GG';
        contDetail6.Effective_Start_Date__c = date.today();
        contDetail6.Effective_End_Date__c = date.today().addDays(400);

        //Off-Hour CLI
        contDetail7.Product_Id__c= 'M-LC-165827';
        contDetail7.Record_Type__c = 'Committed';
        contDetail7.Unit_of_Measure__c = 'Hour';
        contDetail7.Billing_Duration__c = 'Monthly';
        contDetail7.Units_Low__c = 12;
        contDetail7.Unit_Price__c = 12;
        contDetail7.Original_Contract_Id__c = contract.id;
        contDetail7.Product__c = 'Premium Service and Support 3.0::Premium Service and Support 3.0';
        contDetail7.Units_High__c = 12;
        contDetail7.Original_Detail_Id__c = 'd7' + contract.id;
        contDetail7.Name = 'P-2QDL1BQ';
        contDetail7.Effective_Start_Date__c = date.today();
        contDetail7.Effective_End_Date__c = date.today().addDays(400);

        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);
        details.add(contDetail4);
        details.add(contDetail5);
        details.add(contDetail6);
        details.add(contDetail7);

        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'Premium 3.0';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
 
        insert details;
        insert cases;

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();

    }

    public static testMethod void autoCreateMPulseTest()
    {
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        List<Case> cases = new List<Case>();
        
        test.startTest();
        
        List<pse__Proj__c> projTemplatesList = new List<pse__Proj__c>();
        projTemplatesList.add(createProjectTemplate('GSS Products/mPulse Service - PS Hours - Project Template','GSS Product','mPulse Service'));
        projTemplatesList.add(createProjectTemplate('GSS Products/mPulse Service - Monthly Tuning Reports - Project Template','GSS Product','mPulse Service'));
       projTemplatesList.add(createProjectTemplate('GSS Products/mPulse Service - Business Assessment Reports - Project Template','GSS Product','mPulse Service'));
        insert projTemplatesList;

        createProjectTemplateMilestone(projTemplatesList);
        
        //insert the Header Info
        insert contract;
        
        //Per Month CLI
        contDetail1.Product_Id__c= 'M-LC-166357';
        contDetail1.Record_Type__c = 'Committed';
        contDetail1.Unit_of_Measure__c = 'Per Month';
        contDetail1.Billing_Duration__c = 'Monthly';
        contDetail1.Units_Low__c = 12;
        contDetail1.Unit_Price__c = 12;
        contDetail1.Original_Contract_Id__c = contract.id;
        contDetail1.Product__c = 'mPulse';
        contDetail1.Units_High__c = 12;
        contDetail1.Original_Detail_Id__c = 'P-2QDL1EY';
        contDetail1.Name = 'P-2QDL1EY';
        contDetail1.Effective_Start_Date__c = date.today();
        contDetail1.Effective_End_Date__c = date.today().addDays(400);
        
        //Reviews CLI
        contDetail2.Product_Id__c= 'M-LC-166357';
        contDetail2.Record_Type__c = 'Committed';
        contDetail2.Unit_of_Measure__c = 'Assessments';
        contDetail2.Billing_Duration__c = 'Monthly';
        contDetail2.Units_Low__c = 12;
        contDetail2.Unit_Price__c = 12;
        contDetail2.Original_Contract_Id__c = contract.id;
        contDetail2.Product__c = 'mPulse';
        contDetail2.Units_High__c = 12;
        contDetail2.Original_Detail_Id__c = 'P-2QDL1F0';
        contDetail2.Name = 'P-2QDL1F0';
        contDetail2.Effective_Start_Date__c = date.today();
        contDetail2.Effective_End_Date__c = date.today().addDays(400);
        
        //Hour CLI
        contDetail3.Product_Id__c= 'M-LC-166357';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Hour';
        contDetail3.Billing_Duration__c = 'Monthly';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'mPulse';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'P-2QDL1GZ';
        contDetail3.Name = 'P-2QDL1GZ';
        contDetail3.Effective_Start_Date__c = date.today();
        contDetail3.Effective_End_Date__c = date.today().addDays(400);
        
        details.add(contDetail1);
        details.add(contDetail2);
        details.add(contDetail3);

        caseCOB.Origin = 'Autogen';
        caseCOB.Autogen_UseCase__c = 'mPulse';
        caseCOB.Contract__c = contract.Id;
        caseCOB.Validation_Override__c = true;
        caseCOB.Contract_Detail__c = contDetail1.Name;
        cases.add(caseCOB);
 
        insert details;
        insert cases;

        PSA_AutogenProjectBatch_New testbatch = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(testbatch);

        test.stopTest();
    }  
        
    
    


        

    public static testMethod void  testUtilFunctions()
    {
        date myDate1;
        date myDate2;
        Integer noOfMonths;
        Double testDouble;

        test.startTest();    

        myDate1 = date.newInstance(2016, 10,10);
        myDate2 = date.newInstance(2016,11 ,02);
        noOfMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(myDate1,myDate2);

        myDate1 = date.newInstance(2016, 10,21);
        myDate2 = date.newInstance(2016,11 ,28);
        noOfMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(myDate1,myDate2);

        myDate1 = date.newInstance(2018, 10,10);
        myDate2 = date.newInstance(2017,3 ,31);
        noOfMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(myDate1,myDate2);

        myDate1 = null;
        myDate2 = date.newInstance(2017,3 ,31);
        noOfMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(myDate1,myDate2);

        testDouble = 2.5;
        PSA_AutoCreateProjectUtil.customRound(testDouble);  

        PSA_AutoCreateProjectUtil.monthlyRecurringHours(null);
        PSA_AutoCreateProjectUtil.securityServiceReviews(null);
        PSA_AutoCreateProjectUtil.hoursPerPolicy(null);
        PSA_AutoCreateProjectUtil.pricePerMonth(null);
        
        PSA_AutoCreateProjectUtil.customAddMonths(myDate2,testDouble);     
        
        test.stopTest();
    }

    public static testMethod void createBudgetTest()
    {
        //pse__Region__c reg;
        //pse__Practice__c pract;
        pse__Proj__c proj1;
        pse__Proj__c proj;
        Id practId;
        //User usr;
        //Contact resource;

        test.startTest();

        testUtil = new PSA_TestUtility();
        //reg = testUtil.newRegionMaster(true);
        //acct = testUtil.newAccount(true);
        //pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(true); 
        //usr2 = testUtil.newUserSysAdmin(true); 
        //usr.ManagerId = usr2.id;
        //insert usr;
        
        //resource = testUtil.newResource(true, acct.Id, usr.Id);
        //resource.email = 'PSAProjMgr2@akamai.com';
        //update resource;



        proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);

        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.Ongoing_Project_Recurring_Budget_Amt__c = 0;
        proj1.Project_Template__c = proj.Id;
        insert proj1;
        List<String> prjPrd = new List<String>{'Aqua Ion','Cloud Performance','CloudTest'};
        Map<id,List<String>> prjTemplatewithProducts = new Map<id,List<String>>();
        prjTemplatewithProducts.put(proj.Id, prjPrd);

        List<pse__proj__c> projToUpdate = new List<pse__proj__c>();
        projToUpdate.add(proj1);
        String str = 'Customer Purchase Order';
        PSA_AutoCreateProjectUtil.createBudget(projToUpdate, str);
        PSA_AutoCreateProjectUtil.createTemplateSpecificProjectProducts(projToUpdate, prjTemplatewithProducts);

        test.stopTest();

    }





}