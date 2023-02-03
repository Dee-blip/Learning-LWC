/*
 * Developer              Date               JIRA				 Description
 * 
 * Sandeep Naga			12 August 2020		FFPSA-636		Created the testclass for SOA and Plus Auto Renewel Coverage
*/

@isTest(SeeAllData=false)
private class PSA_AutoRenewProject_Test {

    PSA_TestUtility testUtil;

    //Data reqired for a project creation
    public static PSA_TestUtility testUtil;
    public static Account acct;
   
    public static pse__Region__c reg;
    public static pse__Practice__c pract;
    public static User usr;
    public static Contact resource;
    public static pse__Schedule__c schedule;

    public static Merge_Contract_Header__c contract;
    public static List<Merge_Contract_Detail__c> contDetailList;

    public static pse__Proj__c projectTemplate;
    public static pse__Proj__c autogenProject;

    public static pse__Milestone__c milestone;
    public static pse__Budget__c budget;
    public static pse__Assignment__c assignment;

    public static Project_Contract__c pc;
    public static Project_Contract_Line_Item__c pcli;
    
    public static Date startDate;
    public static Date endDate;
    public static Date projectEndDate;

	//@testSetup static void setup(){
    static{
        testUtil = new PSA_TestUtility();

        //creating the account: The account territory is set to undefined
        acct = testUtil.newAccount(false);
        acct.TERR_HIER_5__c = 'Undefined';
        acct.AKAM_Account_ID__c = 'AKAM_ACCOUNT_ID';
        insert acct;

        //Creating the region with name as Undefined (Territory)
        reg = new pse__Region__c();
        reg.Name = 'Undefined' + ' (Territory)';
        insert reg;


        //Create Project Template Data
        pract = testUtil.newPracticeMaster(true);
        usr = testUtil.newUserSysAdmin(true); 
        testUtil.newPermissionControl(true, usr.Id, reg.Id);
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        schedule = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
        


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

        startDate = Date.today().addDays(-100);
        endDate = Date.today().addDays(5);
        projectEndDate = Date.today().addDays(3);

        //Creating the contract: The contract is not inserted.
        contract = testUtil.newContract(false, acct.Id, '123','456',null, startDate, endDate);
        contract.Locked__c = TRUE;
        contract.Cancellation_Date__c = null;
        contract.Contract_Transferred_To__c = null;
        contract.Active__c = true;
        contract.Currency__c = 'USD';
        contract.Original_Contract_Id__c = reg.id;     
        contract.CI_Account_Name__c =  'AKAM_ACCOUNT_ID';    
        insert contract;       

        contDetailList = new List<Merge_Contract_Detail__c>();
        
        projectTemplate = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);  
        projectTemplate.pse__Expense_Notes__c = 'Auto Renewal Template';      
        projectTemplate.pse__Project_Type__c = 'GSS Product';        
        projectTemplate.Ongoing_Project_Recurring_Budget_Amt__c = 0;
        projectTemplate.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        insert projectTemplate;
        projectTemplate.pse__Is_Template__c = True;
        projectTemplate.Name = projectTemplate.pse__Expense_Notes__c;
        projectTemplate.pse__Expense_Notes__c = '';

 
    }

    public static void createContractSetup(String unitOfMeasures, String product)
    {
        
        
        System.debug('unitOfMeasures: '+unitOfMeasures);
        for(String eachVal : unitOfMeasures.split(',')){
            System.debug('eachVal: '+eachVal);
            Merge_Contract_Detail__c tempCli = new Merge_Contract_Detail__c();
            tempCli = testUtil.newContractDetail(false, 'test','test',contract.Id, startDate, endDate);
            tempCli.Record_Type__c = 'Committed';
            tempCli.Units_Low__c = 12;
            tempCli.Unit_Price__c = 12;
            tempCli.Units_High__c = 12;
            tempCli.Billing_Duration__c = 'Monthly';
            tempCli.Original_Detail_Id__c = EncodingUtil.base64Encode(Crypto.generateAesKey(128)).substring(0, 10);
            tempCli.Original_Contract_Id__c = contract.id;
			System.debug('eachVal.split(:)[0]: '+eachVal.split(':')[0]);
            System.debug('eachVal.split(:)[1]: '+eachVal.split(':')[1]);
            System.debug('product: '+product);
            tempCli.Product_Id__c = eachVal.split(':')[0];
            tempCli.Unit_of_Measure__c = eachVal.split(':')[1];
            tempCli.Product__c = product;

            contDetailList.add(tempCli);
        }

    }

    public static void createAutogenProjectSetup(Merge_Contract_Detail__c cli, pse__Proj__c projectTemplate)
    {
        autogenProject = testUtil.newProject(false,reg.Id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        autogenProject.pse__Is_Template__c = False;
        autogenProject.Project_Off_Boarded__c = False;
        autogenProject.External_Id__c = EncodingUtil.base64Encode(Crypto.generateAesKey(128)).substring(0, 10);
        autogenProject.Project_Template__c = projectTemplate.Id;
        autogenProject.Autogen_Product__c = cli.Product__c;
        autogenProject.pse__End_Date__c = projectEndDate;
        autogenProject.pse__Planned_Hours__c = 100;

        insert autogenProject;
        
        System.debug('autogenProject:'+autogenProject);

        milestone = testUtil.newMilestone(true,autogenProject.id,0,date.today().addDays(1));
        budget = testUtil.newBudget(true,autogenProject.id,0,date.today().addDays(1));
        assignment = testUtil.newAssignment(true,autogenProject.id,resource.Id,schedule.Id);
        
        pc = testUtil.newProjectContract(true,autogenProject.Id,contract.Id,acct.Id);
        pcli = testUtil.newProjectContractLineItem(true,autogenProject.Id,contract.Id,cli.Id,pc.Id);
	
        System.debug('pcli:'+pcli);
    }

    public static testMethod void testSOARenewal1()
    {
        Test.startTest(); 
        System.runAs(usr) {
            for(PSA_ProjectTemplates__mdt templateMDT: [
                SELECT id, Auto_Renew_Product__c,Unit_Of_Measures__c, Name__c
                FROM PSA_ProjectTemplates__mdt
                WHERE Parent_Autogen__r.Product_Name__c = 'SOA'
                    AND Auto_Renew_Product__c!= null
                    AND Parent_Autogen__r.ProjectCase_Name__c = 'SOA'
            		AND Name__c = 'GSS Products/Security Optimization Assistance_Config_Assistance-Project Template'] )
            {
                createContractSetup(templateMDT.Unit_Of_Measures__c,'SOA');
            }
            
            insert contDetailList;

            projectTemplate.Name = 'GSS Products/Security Optimization Assistance_Config_Assistance-Project Template';
            projectTemplate.Project_Sub_Type__c = 'Security Optimization Assistance';
            update projectTemplate;
            
            for(Merge_Contract_Detail__c eachCli : contDetailList){
                if(eachCli.Unit_of_Measure__c == 'Hour'){
                    createAutogenProjectSetup(eachCli,projectTemplate);
                }
            }
            
            System.debug('Test planned hours:'+autogenProject.pse__Planned_Hours__c);
            
            Database.executeBatch(new PSA_AutoRenewProjectsBatch(), 200);
        }
        Test.stopTest();
        
        System.debug('pcli.ProjectDateInSync__c:'+pcli.ProjectDateInSync__c);
        System.debug('autogenProject.Project_Off_Boarded__c:'+autogenProject.Project_Off_Boarded__c);

        System.assert(pcli.ProjectDateInSync__c == False, 'Error: Project Not in Sync with PCLI');
        System.assert(autogenProject.Project_Off_Boarded__c == False, 'Error: Project Not offboarded');
    }



    public static testMethod void testSOARenewal2()
    {
        Test.startTest(); 
        System.runAs(usr) {
            for(PSA_ProjectTemplates__mdt templateMDT: [
                SELECT id, Auto_Renew_Product__c,Unit_Of_Measures__c, Name__c
                FROM PSA_ProjectTemplates__mdt
                WHERE Parent_Autogen__r.Product_Name__c = 'SOA'
            	AND Name__c = 'GSS Products/Security Optimization Assistance_Service_Review - Project Template'] )
            {
                createContractSetup(templateMDT.Unit_Of_Measures__c,'SOA');
            }
            
            insert contDetailList;

            projectTemplate.Name = 'GSS Products/Security Optimization Assistance_Service_Review - Project Template';
            projectTemplate.Project_Sub_Type__c = 'Security Optimization Assistance';
            update projectTemplate;
            
            for(Merge_Contract_Detail__c eachCli : contDetailList){
                if(eachCli.Unit_of_Measure__c == 'Reviews'){
                    createAutogenProjectSetup(eachCli,projectTemplate);
                }
            }
            

            Database.executeBatch(new PSA_AutoRenewProjectsBatch(), 200);
        }
        Test.stopTest();
        
        System.debug('pcli.ProjectDateInSync__c:'+pcli.ProjectDateInSync__c);
        System.debug('autogenProject.Project_Off_Boarded__c:'+autogenProject.Project_Off_Boarded__c);

        System.assert(pcli.ProjectDateInSync__c == False, 'Error: Project Not in Sync with PCLI');
        System.assert(autogenProject.Project_Off_Boarded__c == False, 'Error: Project Not offboarded');
    }


    public static testMethod void testPlusRenewal1()
    {
        Test.startTest(); 
        System.runAs(usr) {
            for(PSA_ProjectTemplates__mdt templateMDT: [
                SELECT id, Auto_Renew_Product__c,Unit_Of_Measures__c, Name__c
                FROM PSA_ProjectTemplates__mdt
                WHERE Parent_Autogen__r.Product_Name__c = 'PLUS_PSHOURS'
            	AND Name__c = 'GSS Products/Plus - Monthly Service Report – Project Template'] )
            {
                createContractSetup(templateMDT.Unit_Of_Measures__c,'PLUS_PSHOURS');
            }
            
            insert contDetailList;

            projectTemplate.Name = 'GSS Products/Plus - Monthly Service Report – Project Template';
            projectTemplate.Project_Sub_Type__c = 'Plus';
            update projectTemplate;
            
            for(Merge_Contract_Detail__c eachCli : contDetailList){
                if(eachCli.Unit_of_Measure__c == 'Configurations'){
                    createAutogenProjectSetup(eachCli,projectTemplate);
                }
            }
            

            Database.executeBatch(new PSA_AutoRenewProjectsBatch(), 200);
        }
        Test.stopTest();
        
        System.debug('pcli.ProjectDateInSync__c:'+pcli.ProjectDateInSync__c);
        System.debug('autogenProject.Project_Off_Boarded__c:'+autogenProject.Project_Off_Boarded__c);

        System.assert(pcli.ProjectDateInSync__c == False, 'Error: Project Not in Sync with PCLI');
        System.assert(autogenProject.Project_Off_Boarded__c == False, 'Error: Project Not offboarded');
    }

    public static testMethod void testPlusRenewal2()
    {
        Test.startTest(); 
        System.runAs(usr) {
            for(PSA_ProjectTemplates__mdt templateMDT: [
                SELECT id, Auto_Renew_Product__c,Unit_Of_Measures__c, Name__c
                FROM PSA_ProjectTemplates__mdt
                WHERE Parent_Autogen__r.Product_Name__c = 'PLUS_PSHOURS'
            	AND Name__c = 'GSS Products/Plus - Professional Services – Project Template'] )
            {
                createContractSetup(templateMDT.Unit_Of_Measures__c,'PLUS_PSHOURS');
            }

            insert contDetailList;
            
            projectTemplate.Name = 'GSS Products/Plus - Professional Services – Project Template';
            projectTemplate.Project_Sub_Type__c = 'Plus';
            update projectTemplate;

            for(Merge_Contract_Detail__c eachCli : contDetailList){                
                if(eachCli.Unit_of_Measure__c == 'Hour'){
                    createAutogenProjectSetup(eachCli,projectTemplate);
                }
            }                       
            Database.executeBatch(new PSA_AutoRenewProjectsBatch(), 200);
        }
        Test.stopTest();
        
        System.debug('pcli.ProjectDateInSync__c:'+pcli.ProjectDateInSync__c);
        System.debug('autogenProject.Project_Off_Boarded__c:'+autogenProject.Project_Off_Boarded__c);

        System.assert(pcli.ProjectDateInSync__c == False, 'Error: Project Not in Sync with PCLI');
        System.assert(autogenProject.Project_Off_Boarded__c == False, 'Error: Project Not offboarded');
    }
}