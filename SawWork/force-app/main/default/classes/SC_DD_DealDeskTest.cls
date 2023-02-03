/****************************************************************************
* Class name            :   SC_DD_DealDeskTest
* Author                :   Vishnu Vardhan
* Created               :   25-February-2020
* Purpose               :   Test Class for DealDesk Classes
* Provides Coverage for 
* Classes               :   SC_DD_ApprovalCompCont
                            SC_DD_BatchTestClass
                            SC_DD_DataCreationClass
                            SC_DD_DealDashboardCont
                            SC_DD_DealDeskCont
                            SC_DD_DealPermissions
                            SC_DD_DealSharing
                            SC_DD_DealTriggerHandler
                            SC_DD_ProcessODIDataJob
                            SC_DD_ProcessPreDealData_Batch
                            SC_DD_ProcessPreDealData_Support
* Triggers              :   SC_DD_DealTrigger
                            SC_QM_UserTrigger
-------------------------------------------------------------------------------
DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
    March 12, 2020   Vishnu Vardhan   ESESP-4937      GRAZT changes
****************************************************************************/
@isTest
public class SC_DD_DealDeskTest {
    
    static final String ACC_AKAMID = 'TestAccount';

    static final List<String> SOCC_PRODS = new List<String> {
        'Managed Kona', 
        'RRS', 
        'PnP: Managed Kona & SMP', 
        'PnP: Premium 2.0 & Managed Kona',
        'Advanced',
        'Plus'
    };

    static pse__Region__c reg;
    static Account acct;
    static pse__Practice__c pract;
    static pse__Practice__c pract1;
    static Contact resource;
    static User usr;
    static User usr2;
    static User soccUser;
    static User akatecUser;
    static pse__Assignment__c assign;
    static User admUser;

    public static pse__Work_Calendar__c cal;

    public static pse__Proj__c proj;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetail;
    public static pse__Milestone__c milestone;
    public static  Project_Contract__c projCont;
    public static Project_Contract_Line_Item__c projContItem;
    public static pse__Schedule__c sched;
    public static pse__Permission_Control__c pc;

    static {

        /*SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        scSetting.Name = 'BOCC';
        scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        scSetting.Product_Id__c = 'M-LC-139829';
        
        insert scSetting;*/

        List<SC_DD_Products__c> mkProds = new List<SC_DD_Products__c>(); //[select id, name from SC_DD_Products__c where Name = 'M-LC-139829'];

            mkProds.add(new SC_DD_Products__c(Name = 'M-LC-139829', End_of_Life__c = False, Product_Name__c = 'Managed Kona'));
            mkProds.add(new SC_DD_Products__c(Name = 'M-LC-165776', End_of_Life__c = False, Product_Name__c = 'Advanced'));
        // }
        insert mkProds;

        PSA_TestUtility testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(false);

        acct.name = ACC_AKAMID;//'TestDDACCOUNT' + math.random();
        acct.akam_account_id__c = ACC_AKAMID;
        acct.Type = 'Direct Customer - Active';
        acct.TERR_HIER_1__c = 'Media Americas';
        acct.TERR_HIER_2__c = 'Broadcasting';
        acct.TERR_HIER_3__c = 'Broadcasting';
        acct.TERR_HIER_4__c = 'Broadcasting';
        acct.TERR_HIER_5__c = 'Broadcasting';
        
        acct.recalculateFormulas();
        upsert acct AKAM_Account_ID__c;

        admUser =  [select id from User where Profile.Name = 'System Administrator' and isActive = true and alias = 'CRMOPS' limit 1];
        
        //soccUser = [select id, Cost_Key__c, Department from User where Department = 'GSS Global Programs' and isActive = true and Profile.Name like 'GSS Operations' limit 1];
        soccUser = [select id, Cost_Key__c, Department, profile.name, isActive from User where Department like '%SOCC%' and Cost_Key__c != null and isActive = true and profile.name = 'Managed Security – SOC' limit 1];

        akatecUser = [select id, Cost_Key__c, Department, profile.name, isActive from User where Cost_Key__c != null and isActive = true and profile.name = 'Support - Tech Support Agent' limit 1];

        
        usr =  [select id, contactid, contact.id, cost_key__c, Department from user where Profile.Name = 'GSS Professional Services Manager' 
                                                                                    and isActive = true 
                                                                                    and Manager.isActive = true 
                                                                                    and DelegatedApproverId != null limit 1];// testUtil.newUserSysAdmin(false); 
        
        // Custom setting for SC_SupportEmail__c
        SC_SupportEmail__c autogenCs = new SC_SupportEmail__c(Support_Email_AutoGen__c='scdev@akamai.com',Name='1');
        Insert autogenCs;
        

        List<SC_DD_Department_Cost__c> costData = new List<SC_DD_Department_Cost__c>();


        costData.add(new SC_DD_Department_Cost__c( Actual_Headcount__c = 10, Cost_Key__c = usr.Cost_Key__c, Department_Name__c = usr.Department, Opex_Cost__c = 1000, Status__c = 'Active'));
        costData.add(new SC_DD_Department_Cost__c( Actual_Headcount__c = 10, Cost_Key__c = soccUser.Cost_Key__c, Department_Name__c = soccUser.Department, Opex_Cost__c = 1000, Status__c = 'Active'));
        costData.add(new SC_DD_Department_Cost__c( Actual_Headcount__c = 10, Cost_Key__c = akatecUser.Cost_Key__c, Department_Name__c = akatecUser.Department, Opex_Cost__c = 1000, Status__c = 'Active'));

        insert costData;
        List<SC_DD_GSSServiceProduct__c> servProds =
            [select id, name, ESR_Green_Threshold__c, ESR_Yellow_Threshold__c
             from SC_DD_GSSServiceProduct__c
             where Is_Service_Support_Product__c = true and
             Is_Active__c = true order by Name];
        for(SC_DD_GSSServiceProduct__c sp: servProds) {
            sp.ESR_Green_Threshold__c = 0.95;
            if(sp.name.toLowerCase().startsWith('pnp')) {
                sp.ESR_Yellow_Threshold__c = 0.9;
            } else {
                sp.ESR_Yellow_Threshold__c = 0.8;
            }
        }
        update servProds;
    }


    @testSetup
    static void dataInitialization() {

        insertBatchConfig();
        
        SC_DD_DataCreationClass dataClass1 = new SC_DD_DataCreationClass('GSS Products');
        SC_DD_DataCreationClass dataClass2 = new SC_DD_DataCreationClass('Marketing Product');
        SC_DD_DataCreationClass dataClass3 = new SC_DD_DataCreationClass('Marketing Product (Others)');
        SC_DD_DataCreationClass dataClass4 = new SC_DD_DataCreationClass('Mapping');
        SC_DD_DataCreationClass dataClass5 = new SC_DD_DataCreationClass('Custom Setting');

        
        SC_DD_Customer_PreDeal_Data__c preDeal = new SC_DD_Customer_PreDeal_Data__c(Akam_Account_ID__c = ACC_AKAMID, Account_DGRAT__c = acct.SC_DD_DGRAT__c,
                                                   Product_name__c = 'Advanced', Status__c='Active', Current_Customer_Role_MRR__c = 1233, PS_Hours__c = 123, 
                                                  PS_Delivery_Cost__c = 1231 , PS_Budget_Hour__c = 123, PS_No_Of_Months__c = 11,
                                                  PS_Non_Billable_Hours__c = 123, SOCC_LOE_Hours__c = 12, SOCC_LOE_Delivery_Cost__c = 122, 
                                                  AkaTec_LOE_Hours__c  = 123, Akatec_LOE_Delivery_Cost__c  = 123, PS_PerHour_Cost__c = 123,
                                                  Revenue_Months__c = 12, Total_Revenue_All_Months__c  = 12312, Total_Revenue_Filtered_Months__c =  10000);
        
        insert preDeal; //new List<SObject> { preDeal, depCost };    //acc

        // Case Custom Settings
        SCUtilTestClass.createCustomSettingsForCase();

        List<SC_DD_SOCC_ConfigTask__mdt> taskTypes = [SELECT MasterLabel, LOE_Mins__c FROM SC_DD_SOCC_ConfigTask__mdt];


        List<EB_AccountProductMap__c> caseProducts = new List<EB_AccountProductMap__c>();
        

        // SOCC Cases
        List<Case> soccCases = new List<Case>();
        for(String caseProdName: SOCC_PRODS ) {
            caseProducts.add(new EB_AccountProductMap__c(Name = caseProdName, EB_Product__c = caseProdName, EB_AKAM_AccountId__c = ACC_AKAMID));
            string caseAkamId = 'CASE - ' + caseProdName;
            Case aSoccCase = getCase(ACC_AKAMID, caseAkamId, 'Managed Security', caseProdName);
            aSoccCase.ownerId = soccUser.Id;
            aSoccCase.Case_Assignment_Using_Active_Rules__c = false;
            soccCases.add(aSoccCase);
        }
        insert caseProducts;
        // Akatec Cases
        list<Case> akaTecCases = new List<Case>();

        for(integer i = 0; i < 10; i++) {
            String caseAkamId = 'AKCASE' + i;
            Case akaTecCase = getCase(ACC_AKAMID, caseAkamId, 'Technical', 'Advanced');
            akatecCase.Task_LOE__c = 200;
            akaTecCase.Support_Level__c = 'Advanced';
            akaTecCase.status = 'Closed';
            akaTecCase.OwnerId = akatecUser.Id;
            akaTecCase.Case_Assignment_Using_Active_Rules__c = false;
            akaTecCases.add(akaTecCase);
        }
        

            System.runAs(soccUser) {
                insert soccCases;
                // SOCC Tasks
                List<Task> soccTasks = new List<Task>();
                for(Case cs: soccCases ) {
                    soccTasks.add( new Task( Type__c= taskTypes[0].MasterLabel, WhatId = cs.Id)); //OwnerId= caseOwner.Id,
                }
                insert soccTasks;
            }

            System.runAs(akatecUser) {
                insert akaTecCases;
            }
        System.debug('mss ' + [select id, Name from SC_DD_GSSServiceProduct__c where name = 'MSS 2.0']);

        SC_DD_DataCreationClass.createSoatwoRrstwoMssTwoProds();
        System.debug('mss ' + [select id, Name from SC_DD_GSSServiceProduct__c where name = 'MSS 2.0']);   
    }

    static Case getCase(String akamAccId, String caseAkamId, String caseRecType, String caseProdName) {
        Case aCase = new Case();
        aCase.Subject = 'Test Case Subject';
        aCase.Description = 'Test Case Description';
        aCase.RecordType = new RecordType(Name = caseRecType);
        aCase.Recent_Update__c = false;
        aCase.AKAM_Case_ID__c = caseAkamId;
        aCase.Account = new Account( AKAM_Account_ID__c = akamAccId); 
        aCase.validation_override__c = true;
        if(String.isNotBlank(caseProdName)) {
            aCase.Case_Product__r = new EB_AccountProductMap__c(Name = caseProdName);
        }
        aCase.origin = 'Others';
        return aCase;
    }


    @IsTest
    static void testDDBatch() {
        PSA_TestUtility testUtil = new PSA_TestUtility();


        SC_DD_Utility__c DDSetting = SC_DD_Utility__c.getValues('DD Setting');
        DDSetting.End_date__c = System.today().addDays(30);
        update DDSetting;
        
        test.StartTest();

		CheckRecursion.runOnce();
        CheckRecursion.runInsertOnce();
        
        cal = testUtil.newWorkCalender(true);
        resource = testUtil.newResource(false, acct.Id, usr.Id, reg.Id, cal.Id);
        resource.FirstName = 'TestDDUSER' + Math.random();
        resource.LastName = 'TestDDUSER' + Math.random();
        pract = testUtil.newPracticeMaster(false);
        insert new List<SObject>{resource, pract};
        proj = testUtil.newProject(false,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);    
        proj.Ongoing_Project_Recurring_Planned_Hour__c = 12;
        insert proj;

        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail.product_id__c = 'M-LC-139829';// Managed Kona Site Defender Service => Managed Kona [SELECT Id, Product__r.Name, Product_Name__c, Product_Group__c FROM SC_DD_Mapping__c where RecordType.Name = 'Professional Service' and Parent_GSS_Product__r.name = 'Managed Kona' limit 1].Product__r.Name;
        insert contDetail;
        
        projCont = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projCont.Id);

        sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
        
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);



        pse__Timecard_Header__c timecard1;
        // User adminUser = testUtil.newUserSysAdmin(true);        
        pse__Permission_Control__c pc1 = testUtil.newPermissionControl(true, admUser.Id, reg.Id);

        System.runAs(admUser) {
            assign = testUtil.newAssignment(TRUE, proj.Id, resource.Id, sched.Id);
        }
            System.runAs(usr) {
                //changes for 19.1.2
                milestone = testUtil.newMilestone(false,proj.Id,100,date.newInstance(2015, 08, 21));            
                milestone.Billable__c = true;
                insert milestone;

                pse__Project_Methodology__c product1 = testUtil.newProjectProduct(true,proj.Id,'Test Proj Prod');

                 // Testing the timecard submission: 
                timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
                timecard1.pse__Billable__c = true;
                timecard1.pse__Project_Methodology_Object__c = product1.Id;
                    
                timecard1.pse__Status__c = 'Submitted'; 
                timecard1.pse__Monday_Hours__c = 1;
                timecard1.pse__Submitted__c = true;
                timecard1.pse__Assignment__c = assign.Id;
                insert timecard1; 
            }   
            assign = [select Id, Project_Contract_Line_Item__c from pse__Assignment__c where id = :assign.Id limit 1];
            
            Id batchProcessId = Database.executeBatch(new SC_DD_ProcessPreDealData_Batch(null));
        test.Stoptest(); 
    }


    @IsTest
    static void testDDBatchWithAkatecData() {
        PSA_TestUtility testUtil = new PSA_TestUtility();


        SC_DD_Utility__c DDSetting = SC_DD_Utility__c.getValues('DD Setting');
        DDSetting.End_date__c = System.today().addDays(30);
        update DDSetting;

        test.StartTest();


        cal = testUtil.newWorkCalender(true);

        resource = testUtil.newResource(false, acct.Id, usr.Id, reg.Id, cal.Id);
        resource.FirstName = 'TestDDUSER' + Math.random();
        resource.LastName = 'TestDDUSER' + Math.random();
        pract = testUtil.newPracticeMaster(false);
        insert new List<SObject>{resource, pract};

		CheckRecursion.runOnce();
        CheckRecursion.runInsertOnce();
                
        proj = testUtil.newProject(true,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);    
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail.product_id__c = 'M-LC-165776';
        insert contDetail;
        
        projCont = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projCont.Id);

        sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
        
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);



        pse__Timecard_Header__c timecard1;
        // User adminUser = testUtil.newUserSysAdmin(true);        
        pse__Permission_Control__c pc1 = testUtil.newPermissionControl(true, admUser.Id, reg.Id);

        System.runAs(admUser) {
            assign = testUtil.newAssignment(TRUE, proj.Id, resource.Id, sched.Id);
        }
            System.runAs(usr) {
                //changes for 19.1.2
                milestone = testUtil.newMilestone(false,proj.Id,100,date.newInstance(2015, 08, 21));            
                milestone.Billable__c = true;
                insert milestone;

                pse__Project_Methodology__c product1 = testUtil.newProjectProduct(true,proj.Id,'Test Proj Prod');

                // Testing the timecard submission: 
                timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
                timecard1.pse__Billable__c = true;
                timecard1.pse__Project_Methodology_Object__c = product1.Id;
                    
                timecard1.pse__Status__c = 'Submitted'; 
                timecard1.pse__Monday_Hours__c = 1;
                timecard1.pse__Submitted__c = true;
                timecard1.pse__Assignment__c = assign.Id;
                insert timecard1; 

            }   
            assign = [select Id, Project_Contract_Line_Item__c from pse__Assignment__c where id = :assign.Id limit 1];
            
            Id batchProcessId = Database.executeBatch(new SC_DD_ProcessPreDealData_Batch(null));
        test.Stoptest(); 

    }

    // Test Account Search - SC_DD_DealDeskCont.getAccounts(<searchStr>)
    testMethod static void testAccountSearch() {
        List<Account> accountSearchResult = SC_DD_DealDeskCont.getAccounts(ACC_AKAMID);
        System.assert((accountSearchResult != null && accountSearchResult.size() > 0 ), 'Account Search Result Size > 0');
        system.assertEquals(ACC_AKAMID, accountSearchResult[0].akam_account_id__c, 'Verify Account Search Result');
    }

    //  Test Product Fetch - SC_DD_DealDeskCont.getGssProductDetails()
    testMethod static void testGetGssProductDetails() {
        System.assert( SC_DD_DealDeskCont.getGssProductDetails().size() > 0,  'Testing GSS Product Fetch - getGssProductDetails()');
    }
    // Test Down time
    testMethod static void testDowntime() {
        SC_DD_Utility__c ddSetting = SC_DD_Utility__c.getInstance('DD Setting');
        ddSetting.UI_Status__c = 'Processing';
        update ddSetting;
        AuraHandledException auraEx; 
        try {
            SC_DD_DealDeskCont.getGssProductDetails();
        } catch (AuraHandledException ex) {
            auraEx = ex;
        }
        System.assert(auraEx != null, 'DealDesk Downtime test');
    }

    //  Test Package Component Fetch - SC_DD_DealDeskCont.getProductRules(<prod>, <prodtype>)
    testMethod static void testGetProductRules() {
        
        SC_DD_GSSServiceProduct__c prod = getAnActiveProduct();
        String packageCompDefaultValues = '';

        Map<String, SC_DD_DealDeskCont.config> prodConfigData = SC_DD_DealDeskCont.getProductRules(prod.Name, prod.Product_Type__c, packageCompDefaultValues);
        System.assert(prodConfigData.size() > 0, 'Verifying Package Component Fetch' );

        for(SC_DD_DealDeskCont.config pcf: prodConfigData.values()) {
            pcf.requested = 1234;
        }

        packageCompDefaultValues = JSON.serialize(prodConfigData);
        Map<String, SC_DD_DealDeskCont.config> prodConfigWithDefaults = SC_DD_DealDeskCont.getProductRules(prod.Name, prod.Product_Type__c, packageCompDefaultValues);

        for(SC_DD_DealDeskCont.config pcf: prodConfigWithDefaults.values()) {
            System.assertEquals(1234, pcf.requested, 'Verifying Package Comp Default Values');
        }

    }

    // Test Contract Info fetch - SC_DD_DealDeskCont.getContractInfo(<accId>)
    testMethod static void testGetContractInfo() {
        SC_DD_DealDeskCont.getContractInfo(ACC_AKAMID);
    }
    
    //  Test Customer MRR fetch - SC_DD_DealDeskCont.getCustomerMrr(<akamAccId>)
    testMethod static void testGetCustomerMrr() {
        SC_DD_DealDeskCont.getCustomerMrr(ACC_AKAMID);
    }

    //  Test Currency Conversion fetch - SC_DD_DealDeskCont.getConversionRates(<prod>, <prodtype>)
    testMethod static void testGetConversionRates() {
        List<CurrencyType> conversionRates = SC_DD_DealDeskCont.getConversionRates();
        System.assert(conversionRates.size() > 0, 'Verifying Conersion Rates Fetch');
    }


    testMethod static void testGraztRestrictions() {

        PSA_TestUtility testUtil = new PSA_TestUtility();


        pse__Region__c geo = testUtil.newRegionMaster(false);
        geo.Name = 'Media Americas (Geography)';
        geo.psa_Old__c =false;
        insert geo;

        pse__Region__c region = testUtil.newRegionMaster(false);
        region.Name = 'Broadcasting (Region)';
        region.psa_Old__c =false;
        region.pse__Parent_Region__c = geo.id;
        insert region;

        // Run as Deal Desk User
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1 ];
        User slmUser = [select id from User where Profile.Name  =  'GSS Professional Services Manager' and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1];
        Inv_WorkBox_Region_Mapping__c graztApprover = new Inv_WorkBox_Region_Mapping__c(TERR_HIER_1__c = geo.id, TERR_HIER_2__c = region.Id, User__c = slmUser.Id, RecordType = new RecordType(Name='DealDesk'));
        
        Test.startTest();

        System.runAs(admUser) {            
            insert graztApprover;
            update graztApprover;
        }
        Test.stopTest();
    }

     
    
    testMethod static void testESRDeal() {
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        SC_DD_GSSServiceProduct__c advProd = [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c 
                                              from SC_DD_GSSServiceProduct__c where name = 'Advanced' limit 1][0];
        
        advProd.Computed_ESR_Override_Class__c = 'SC_DD_DealDeskCont.AdvancedProductEsr';
        update advProd;
        
        SC_DD_Package_Components__c avdProj = new SC_DD_Package_Components__c();
        avdProj.GSS_Product__c = advProd.Id;
        avdProj.Name = 'Additional Project Management (Hrs/quarter)';
        avdProj.Min__c = 0;
        avdProj.Max__c = 1;
        avdProj.Standard__c = 0;
        avdProj.Sequence__c = 8;
        insert avdProj;
        
        Map<String, SC_DD_DealDeskCont.Config> prodConfigs = new Map<String, SC_DD_DealDeskCont.Config> ();
        for(SC_DD_Package_Components__c cf: [select id, Name, Package_Hours_Formula__c, Sequence__c, GSS_Product__c, Max__c, Min__c, Standard__c FROM SC_DD_Package_Components__c 
                                             where GSS_Product__r.Name = 'Advanced']) 
        {
            SC_DD_DealDeskCont.Config prodConfig = new SC_DD_DealDeskCont.Config();
            prodConfig.sfid = cf.Id;
            prodConfig.product = cf.GSS_Product__c;
            prodConfig.configName = cf.Name;
            prodConfig.customFormula = cf.Package_Hours_Formula__c;
            prodConfig.defaultCustValue = cf.Standard__c;
            // if current values exist requested value will be current value, if not use Standard value
            prodConfig.requested = cf.Standard__c;
            prodConfig.standard = cf.Standard__c ;
            prodConfig.sequence = Integer.valueOf(cf.Sequence__c);
            prodConfig.min = cf.Min__c ;
            prodConfig.max = cf.Max__c ;
            prodConfig.minError = 'Negative values not allowed';//'minimum value is ' + cf.Min__c ;
            prodConfig.maxError = 'maximum value is ' + cf.Max__c ;
            prodConfig.allowBelowMin = false;
            prodConfig.allowAboveMax = false;
            prodConfigs.put(cf.Name, prodConfig);
        }

        Test.startTest();
        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(advProd.Name, advProd.Product_Type__c, ''));

        

        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, 'Advanced', packageComp, 1231,  45678, 
                                                 50, 'US (USD)', null, false, false);
        }
        Test.stopTest();
    }
     
    
    testMethod static void testPremiumThree() {
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        SC_DD_GSSServiceProduct__c advProd = [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c 
                                              from SC_DD_GSSServiceProduct__c where name = 'Premium 3.0' limit 1][0];
        
        advProd.Computed_ESR_Override_Class__c = 'SC_DD_DealDeskCont.PremiumThreeProductEsr';
        update advProd;
        
        SC_DD_Package_Components__c avdProj = new SC_DD_Package_Components__c();
        avdProj.GSS_Product__c = advProd.Id;
        avdProj.Name = 'Additional Project Management (Hrs/quarter)';
        avdProj.Min__c = 0;
        avdProj.Max__c = 1;
        avdProj.Standard__c = 0;
        avdProj.Sequence__c = 8;
        insert avdProj;
        
        Map<String, SC_DD_DealDeskCont.Config> prodConfigs = new Map<String, SC_DD_DealDeskCont.Config> ();
        for(SC_DD_Package_Components__c cf: [select id, Name, Package_Hours_Formula__c, Sequence__c, GSS_Product__c, Max__c, Min__c, Standard__c FROM SC_DD_Package_Components__c 
                                             where GSS_Product__r.Name = 'Premium 3.0']) 
        {
            SC_DD_DealDeskCont.Config prodConfig = new SC_DD_DealDeskCont.Config();
            prodConfig.sfid = cf.Id;
            prodConfig.product = cf.GSS_Product__c;
            prodConfig.configName = cf.Name;
            prodConfig.customFormula = cf.Package_Hours_Formula__c;
            prodConfig.defaultCustValue = cf.Standard__c;
            // if current values exist requested value will be current value, if not use Standard value
            prodConfig.requested = cf.Standard__c;
            prodConfig.standard = cf.Standard__c ;
            prodConfig.sequence = Integer.valueOf(cf.Sequence__c);
            prodConfig.min = cf.Min__c ;
            prodConfig.max = cf.Max__c ;
            prodConfig.minError = 'Negative values not allowed';//'minimum value is ' + cf.Min__c ;
            prodConfig.maxError = 'maximum value is ' + cf.Max__c ;
            prodConfig.allowBelowMin = false;
            prodConfig.allowAboveMax = false;
            prodConfigs.put(cf.Name, prodConfig);
        }

        Test.startTest();
        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(advProd.Name, advProd.Product_Type__c, ''));

        

        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, 'Premium 3.0', packageComp, 1231,  45678, 
                                                 50, 'US (USD)', null, false, false);
        }
        Test.stopTest();
    }
     
    
    testMethod static void testMssTwoDeal() {
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        SC_DD_GSSServiceProduct__c mssTwoProd = [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c 
                                              from SC_DD_GSSServiceProduct__c where name = 'MSS 2.0' limit 1][0];
        
        System.debug('mss ' + [select id, Name from SC_DD_GSSServiceProduct__c where name = 'MSS 2.0']);
        
        Map<String, SC_DD_DealDeskCont.Config> prodConfigs = new Map<String, SC_DD_DealDeskCont.Config> ();
        Test.startTest();
        for(SC_DD_Package_Components__c cf: [select id, Name, Package_Hours_Formula__c, Sequence__c, GSS_Product__c, Max__c, Min__c, Standard__c FROM SC_DD_Package_Components__c 
                                             where GSS_Product__r.Name = 'MSS 2.0']) 
        {
            SC_DD_DealDeskCont.Config prodConfig = new SC_DD_DealDeskCont.Config();
            prodConfig.sfid = cf.Id;
            prodConfig.product = cf.GSS_Product__c;
            prodConfig.configName = cf.Name;
            prodConfig.customFormula = cf.Package_Hours_Formula__c;
            prodConfig.defaultCustValue = cf.Standard__c;
            // if current values exist requested value will be current value, if not use Standard value
            prodConfig.requested = cf.Standard__c;
            prodConfig.standard = cf.Standard__c ;
            prodConfig.sequence = Integer.valueOf(cf.Sequence__c);
            prodConfig.min = cf.Min__c ;
            prodConfig.max = cf.Max__c ;
            prodConfig.minError = 'Negative values not allowed';//'minimum value is ' + cf.Min__c ;
            prodConfig.maxError = 'maximum value is ' + cf.Max__c ;
            prodConfig.allowBelowMin = false;
            prodConfig.allowAboveMax = false;
            prodConfigs.put(cf.Name, prodConfig);
        }


        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(mssTwoProd.Name, mssTwoProd.Product_Type__c, ''));

        

        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, 'MSS 2.0', packageComp, 1231,  45678, 
                                                 50, 'US (USD)', null, false, false);
        }
        Test.stopTest();
    }
     
    testMethod static void testPnpSoaAdvancedProductEsr() {
        String pnpSoaAdvanced = 'Protect & Perform 1.1: SOA with Advanced';
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        createPnp11Product(pnpSoaAdvanced, 'SC_DD_EsrLogicOverrides.PnpSoaAdvancedProductEsr');
        String packageCompDefaultValues = '';
        Test.startTest();
        Map<String, SC_DD_DealDeskCont.config> prodConfigData = SC_DD_DealDeskCont.getProductRules(pnpSoaAdvanced, '', packageCompDefaultValues);
        //System.assert(prodConfigData.size() > 0, 'Verifying Package Component Fetch' );

        for(SC_DD_DealDeskCont.config pcf: prodConfigData.values()) {
            pcf.requested = 1234;
        }

        packageCompDefaultValues = JSON.serialize(prodConfigData);
        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(pnpSoaAdvanced, '', packageCompDefaultValues));
        
        
        
        System.runAs(ddaUser) {
            try{
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, pnpSoaAdvanced, packageComp, 1231,  45678, 
                                       50, 'US (USD)', null, false, false);
            }
            catch(Exception e){
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
            
        }
        Test.stopTest();
    }
    testMethod static void testPnpRrsAdvancedProductEsr() {
        String pnpRrsAdvanced = 'Protect & Perform 1.1: RRS with Advanced';
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        createPnp11Product(pnpRrsAdvanced, 'SC_DD_EsrLogicOverrides.PnpRrsAdvancedProductEsr');
        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(pnpRrsAdvanced, '', ''));
        
        Test.startTest();
        
        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, pnpRrsAdvanced, packageComp, 1231,  45678, 
                                       50, 'US (USD)', null, false, false);
        }
        Test.stopTest();
    }
    testMethod static void testPnpMssAdvancedProductEsr() {
        String pnpMssAdvanced = 'Protect & Perform 1.1: MSS with Advanced';
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        createPnp11Product(pnpMssAdvanced, 'SC_DD_EsrLogicOverrides.PnpMssAdvancedProductEsr');
        String packageComp =  JSON.serialize(SC_DD_DealDeskCont.getProductRules(pnpMssAdvanced, '', ''));
        
        Test.startTest();
        
        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, pnpMssAdvanced, packageComp, 1231,  45678, 
                                       50, 'US (USD)', null, false, false);
        }
        Test.stopTest();
    }
    
    static void createPnp11Product(String prodName, String esrOverride) {
        // For Test data creation, Cloning Snadalone Advanced prodict to create PnPAdnaced
        SC_DD_GSSServiceProduct__c soaAdv = [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c 
                                              from SC_DD_GSSServiceProduct__c where name = 'Advanced' limit 1][0];
        
        soaAdv.Name = prodName;
        soaAdv.List_Price_Multiplicand__c = 0.020680628272251308;
        soaAdv.Computed_ESR_Formula__c = 'requestedPrice / requestedHours';
        soaAdv.ESR_Green_Threshold__c = 1.0;
        soaAdv.ESR_Yellow_Threshold__c = 0.8999999999999999;
        soaAdv.Computed_ESR_Override_Class__c = esrOverride;//'SC_DD_EsrLogicOverrides.PnpSoaAdvancedProductEsr';
        soaAdv.GSS_Product_External_Id__c = 'Protect & Perform 1.1: SOA with Advanced';
        update soaAdv;
        
        insert new List<SC_DD_Package_Components__c> {
            new SC_DD_Package_Components__c( GSS_Product__c = soaAdv.Id,
                                            Name = 'Project Management (If 1= 24 Hrs/Qtr)',
                                            Min__c = 0,
                                            Max__c = 1,
                                            Standard__c = 0,
                                            Sequence__c = 8),
            new SC_DD_Package_Components__c(GSS_Product__c = soaAdv.Id,
                                            Name = 'Additional Project Management (Hrs/quarter)',
                                            Min__c = 0,
                                            Max__c = 24,
                                            Standard__c = 0,
                                            Sequence__c = 9)
                };
                    	
    }
    
    testMethod static void testDealWithSameGRAZTPreDeal() {
        Test.startTest();
        Account testAcc2 =  new Account(name = 'Test Account 2', akam_account_id__c = 'Test Account 2', Type = 'Direct Customer - Active', 
                            TERR_HIER_1__c = 'Media Americas', TERR_HIER_2__c = 'Broadcasting');
        insert testAcc2;
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1 ];

        SC_DD_Customer_PreDeal_Data__c preDeal = new SC_DD_Customer_PreDeal_Data__c(Akam_Account_ID__c = ACC_AKAMID, Account_DGRAT__c = testAcc2.SC_DD_DGRAT__c,
                                                   Product_name__c = 'Advanced', Status__c='Active', Current_Customer_Role_MRR__c = 1233, PS_Hours__c = 123, 
                                                  PS_Delivery_Cost__c = 1231 , PS_Budget_Hour__c = 123, PS_No_Of_Months__c = 11,
                                                  PS_Non_Billable_Hours__c = 123, SOCC_LOE_Hours__c = 12, SOCC_LOE_Delivery_Cost__c = 122, 
                                                  AkaTec_LOE_Hours__c  = 123, Akatec_LOE_Delivery_Cost__c  = 123, PS_PerHour_Cost__c = 123,
                                                  Revenue_Months__c = 12, Total_Revenue_All_Months__c  = 12312, Total_Revenue_Filtered_Months__c =  10000);
                                                  
        System.runAs(ddaUser) {
            
            String dealStr = SC_DD_DealDeskCont.getDeal( 'Test Account 2' , 'Advanced', 'packageComp', 1231,  45678, 50, 'US (USD)', null, false, true);
            SC_DD_Deal__c dealRec = (SC_DD_Deal__c)JSON.deserialize(dealStr, SC_DD_Deal__c.class);
            Id dealId = SC_DD_DealDeskCont.saveDeal(dealRec);
            dealRec.Id = dealId;
            // update deal
            SC_DD_DealDeskCont.saveDeal(dealRec);
        }
        Test.stopTest();
    }

    testMethod static void testDealWithSameAccountPreDeal() {
        Test.startTest();
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        
        SC_DD_Customer_PreDeal_Data__c preDeal = new SC_DD_Customer_PreDeal_Data__c(Akam_Account_ID__c = ACC_AKAMID, Account_DGRAT__c = acct.SC_DD_DGRAT__c,
                    Product_name__c = 'Advanced', Status__c='Active', Current_Customer_Role_MRR__c = 1233, PS_Hours__c = 123, 
                PS_Delivery_Cost__c = 1231 , PS_Budget_Hour__c = 123, PS_No_Of_Months__c = 11,
                PS_Non_Billable_Hours__c = 123, SOCC_LOE_Hours__c = 12, SOCC_LOE_Delivery_Cost__c = 122, 
                AkaTec_LOE_Hours__c  = 123, Akatec_LOE_Delivery_Cost__c  = 123, PS_PerHour_Cost__c = 123,
                Revenue_Months__c = 12, Total_Revenue_All_Months__c  = 12312, Total_Revenue_Filtered_Months__c =  10000);
                
        System.runAs(ddaUser) {
            String dealStr = SC_DD_DealDeskCont.getDeal( ACC_AKAMID , 'Advanced', 'packageComp', 1231,  45678, 50, 'US (USD)', null, false, false);
            SC_DD_Deal__c dealRec = (SC_DD_Deal__c)JSON.deserialize(dealStr, SC_DD_Deal__c.class);
            Id dealId = SC_DD_DealDeskCont.saveDeal(dealRec);
            dealRec.Id = dealId;
            // update deal
            SC_DD_DealDeskCont.saveDeal(dealRec);
        }
        Test.stopTest();
    }
     
    testMethod static void testDealThatAlreadyHasProduct() {
        Test.startTest();
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        System.runAs(ddaUser) {
            SC_DD_DealDeskCont.getDeal( ACC_AKAMID, 'Advanced', 'packageComp', 1231,  45678, 
                                                 50, 'US (USD)', null, false, true);
        }

        Test.stopTest();
    }
    
    testMethod static void testSubmitOtherProductDeal() {
        Test.startTest();
        insert new SC_DD_GSSServiceProduct__c(
            Name = 'Other',
            Is_Active__c = True,
            Is_Service_Support_Product__c = True,
            LOE_API_Call_Required__c = False);
        
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        
        
        System.runAs(ddaUser){
            id dealId = SC_DD_DealDeskCont.saveOtherDeal( ACC_AKAMID,
                                                         'Other',
                                                         'productName',
                                                         'productDescription',
                                                         'Discount',
                                                         'US (USD)',
                                                         800,
                                                         900,
                                                         'Test Explanation & Justification',
                                                         true);
        }

        Test.stopTest();
    }
    
    testMethod static void testOtherProductApproval() {
        
        SC_DD_GSSServiceProduct__c otherProd = new SC_DD_GSSServiceProduct__c(
            Name = 'Other',
            Is_Active__c = True,
            Is_Service_Support_Product__c = True,
            LOE_API_Call_Required__c = False);
        insert otherProd;
        
        Test.startTest();
        
        PSA_TestUtility testUtil = new PSA_TestUtility();
        
        
        pse__Region__c geo = testUtil.newRegionMaster(false);
        geo.Name = 'Media Americas (Geography)';
        geo.psa_Old__c =false;
        insert geo;
        
        pse__Region__c region = testUtil.newRegionMaster(false);
        region.Name = 'Broadcasting (Region)';
        region.psa_Old__c =false;
        region.pse__Parent_Region__c = geo.id;// = new pse__Region__c(Name = 'Media Americas (Geography)');
        insert region;
        
        User slmUser = [select id from User where Profile.Name  =  'GSS Professional Services Manager' and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1];
        
        System.runAs(admUser) {
            Inv_WorkBox_Region_Mapping__c graztApprover = new Inv_WorkBox_Region_Mapping__c( TERR_HIER_1__c = geo.Id, TERR_HIER_2__c = region.Id, User__c = slmUser.Id, RecordType = new RecordType(Name='DealDesk'));
            insert graztApprover;
        }
        
        id dealId;
        
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        System.runAs(ddaUser){
            dealId = SC_DD_DealDeskCont.saveOtherDeal( ACC_AKAMID,
                                                         'Other',
                                                         'productName',
                                                         'productDescription',
                                                         'Discount',
                                                         'US (USD)',
                                                         800,
                                                         900,
                                                         'Test Explanation & Justification',
                                                         true);
        }
        system.debug('sharing rule '  + [select id, account__r.sc_dd_dgrat__c from sc_dd_Deal__c where id = :dealId][0].account__r.sc_dd_dgrat__c);
        system.debug('sharing rule '  + [select id, grazt__c, recordtype.name from Inv_WorkBox_Region_Mapping__c where user__c = :slmUser.Id]);
        for(sc_dd_deal__share sh: [select id, UserOrGroup.name, rowcause from sc_dd_deal__share where parentid = :dealid]) {
            system.debug('sharing rule --> ' + sh.UserOrGroup.name + ' -- ' + sh.rowcause);
        }
        
        System.runAs(slmUser){
            sc_dd_deal__c deal = [select id, name, GSS_Product__c, GSS_Product_Name__c, Approval_Stage__c, Account__c from sc_dd_deal__c where id = :dealId];
            Boolean isApproved = SC_dD_ApprovalCompCont.performAction(deal, 'Approve', 'Other Deal Approved!');
            System.assertEquals(true, isApproved);
        }
        
        Test.stopTest();
    }
    
    testMethod static void testDealDashboardCont(){

        Test.startTest();


        PSA_TestUtility testUtil = new PSA_TestUtility();


        pse__Region__c geo = testUtil.newRegionMaster(false);
        geo.Name = 'Media Americas (Geography)';
        geo.psa_Old__c =false;
        insert geo;

        pse__Region__c region = testUtil.newRegionMaster(false);
        region.Name = 'Broadcasting (Region)';
        region.psa_Old__c =false;
        region.pse__Parent_Region__c = geo.id;// = new pse__Region__c(Name = 'Media Americas (Geography)');
        insert region;
        
        User slmUser = [select id from User where Profile.Name  =  'GSS Professional Services Manager' and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1];

        System.runAs(admUser) {
            Inv_WorkBox_Region_Mapping__c graztApprover = new Inv_WorkBox_Region_Mapping__c(TERR_HIER_1__c = geo.id, TERR_HIER_2__c = region.Id, User__c = slmUser.Id, RecordType = new RecordType(Name='DealDesk'));
            insert graztApprover;
        }

        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        SC_DD_Deal__c deal = new SC_DD_Deal__c(Account__r = new Account(AKAM_Account_Id__c = ACC_AKAMID), GSS_Product__c=getAnActiveProduct().Id, Local_Currency__c = 'US (USD)', Requested_Price__c = 12312, Requestor__c = ddaUser.Id, evaluation_action__c = 'Pending with DDA', approval_stage__c = 'DDA');
        insert deal;

        System.runAs(ddaUser){
            SC_DD_DealDashboardCont.getPendingDeals(System.UserInfo.getUserId());
        }
        
        deal.evaluation_action__c = 'Escalated';
        deal.approval_stage__c = 'SLM/SLD';
        update deal;

        //Test.startTest();
        System.runAs(slmUser){
            SC_DD_DealDashboardCont.getPendingDeals(System.UserInfo.getUserId());
        }
        
        SC_DD_DealDashboardCont.getPendingDeals(System.UserInfo.getUserId());

        Test.stopTest();
        
    }

    testMethod static void testApprovalComp() {

        
        Test.startTest();
        //Custom setting : Deal_Desk_Button_Visibility__c
        Upsert new List<Deal_Desk_Button_Visibility__c>{
            new Deal_Desk_Button_Visibility__c( Name='Red-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-DDA', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Green-DDA', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLM/SLD', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = true ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLD2', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SPO', Has_Approve_Access__c=true, Has_Escalate_Access__c = false, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Red-DDA', Has_Approve_Access__c=false, Has_Escalate_Access__c = true, Has_Reject_Access__c = true, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Yellow-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false ),
            new Deal_Desk_Button_Visibility__c( Name='Green-SLD1', Has_Approve_Access__c=false, Has_Escalate_Access__c = false, Has_Reject_Access__c = false, Has_SendToDDA_Access__c = false )
        } name;


        PSA_TestUtility testUtil = new PSA_TestUtility();

        pse__Region__c geo = testUtil.newRegionMaster(false);
        geo.Name = 'Media Americas (Geography)';
        geo.psa_Old__c =false;
        insert geo;

        pse__Region__c region = testUtil.newRegionMaster(false);
        region.Name = 'Broadcasting (Region)';
        region.psa_Old__c =false;
        region.pse__Parent_Region__c = geo.id;// = new pse__Region__c(Name = 'Media Americas (Geography)');
        insert region;

        User slmUser = [select id, manager.Id, Manager.Manager.Id from User where Profile.Name  =  'GSS Professional Services Manager' and isActive = true and managerid != null and manager.managerid != null and manager.isActive = true and manager.manager.isactive = true limit 1];
        User sld1 = slmUser.manager;
        User sld2 = slmUser.manager.manager;
        Inv_WorkBox_Region_Mapping__c graztApprover = new Inv_WorkBox_Region_Mapping__c( TERR_HIER_1__c = geo.id, TERR_HIER_2__c = region.Id, User__c = slmUser.Id, RecordType = new RecordType(Name='DealDesk'));
        System.runAs(admUser) {
            insert graztApprover;
        }

        Account acc = [select id, AKAM_Account_Id__c from Account where AKAM_Account_Id__c = :ACC_AKAMID];
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];
        SC_DD_Deal__c deal = new SC_DD_Deal__c(Account__c = acc.Id, GSS_Product__c=getAnActiveProduct().Id, Local_Currency__c = 'US (USD)', Requested_Price__c = 12312, 
                            Requestor__c = ddaUser.Id, evaluation_action__c = 'Pending with DDA', approval_stage__c = 'DDA',
                            EPS_Zone__c = 'Red',  ESR_Zone__c = 'Red', Deal_Zone__c = 'Red');
        insert deal;

        System.runAs(ddaUser){
            SC_DD_ApprovalCompCont.getEntitledActions(deal);
            SC_DD_ApprovalCompCont.performAction(deal, 'Escalate', 'Escalating Deal');
        }
        
        System.runAs(slmUser){
            SC_DD_ApprovalCompCont.getEntitledActions(deal);
            SC_DD_ApprovalCompCont.performAction(deal, 'Escalate', 'Escalating Deal');
        }

        deal = new SC_DD_Deal__c(Account__c = acc.Id, GSS_Product__c=getAnActiveProduct().Id, Local_Currency__c = 'US (USD)', Requested_Price__c = 12312, 
                            Requestor__c = ddaUser.Id, evaluation_action__c = 'Pending with DDA', approval_stage__c = 'DDA',
                            EPS_Zone__c = 'Red',  ESR_Zone__c = 'Red', Deal_Zone__c = 'Red');
        insert deal;

        System.runAs(sld1){
            SC_DD_ApprovalCompCont.getEntitledActions(deal);
            SC_DD_ApprovalCompCont.performAction(deal, 'Escalate', 'Escalating Deal');
        }

        deal = new SC_DD_Deal__c(Account__c = acc.Id, GSS_Product__c=getAnActiveProduct().Id, Local_Currency__c = 'US (USD)', Requested_Price__c = 12312, 
                            Requestor__c = ddaUser.Id, evaluation_action__c = 'Pending with DDA', approval_stage__c = 'DDA',
                            EPS_Zone__c = 'Red',  ESR_Zone__c = 'Red', Deal_Zone__c = 'Red');
        insert deal;

        System.runAs(sld2){
            SC_DD_ApprovalCompCont.getEntitledActions(deal);
            SC_DD_ApprovalCompCont.performAction(deal, 'Escalate', 'Escalating Deal');
        }
        Test.stopTest();        
    }

    testMethod static void testOdiBatchJob1() {
        Test.startTest();
        SC_QM_USER_FILTER__c uFilter = [select id, User_Id__c, Status__c from SC_QM_USER_FILTER__c where User_Id__c = 'Deal_Desk']; 
        uFilter.Status__c = 'Processed';
        update uFilter; //=> SC_QM_USER_FILTER__c trigger will invoke batch  SC_DD_ProcessODIDataJob
        Test.stopTest();
    }
    testMethod static void testOdiBatchJob2() {

        Test.startTest();
            Database.executeBatch(new SC_DD_ProcessODIDataJob(false), 1);
        Test.stopTest();
    }

    testMethod static void testFieldTracker() {

        Test.startTest();
        insert new Account(name = 'Test Account 2', akam_account_id__c = 'Test Account 2', Type = 'Direct Customer - Active', 
                            TERR_HIER_1__c = 'Media Americas', TERR_HIER_2__c = 'Broadcasting');
        User ddaUser = [select id from User where Profile.Name = :SC_DD_ApprovalCompCont.DDA_PROFILE and managerid != null and manager.managerid != null and isActive = true limit 1 ];

        SC_DD_Customer_PreDeal_Data__c preDeal = new SC_DD_Customer_PreDeal_Data__c(Akam_Account_ID__c = ACC_AKAMID, Account_DGRAT__c = acct.SC_DD_DGRAT__c,
                                                   Product_name__c = 'Advanced', Status__c='Active', Current_Customer_Role_MRR__c = 1233, PS_Hours__c = 123, 
                                                  PS_Delivery_Cost__c = 1231 , PS_Budget_Hour__c = 123, PS_No_Of_Months__c = 11,
                                                  PS_Non_Billable_Hours__c = 123, SOCC_LOE_Hours__c = 12, SOCC_LOE_Delivery_Cost__c = 122, 
                                                  AkaTec_LOE_Hours__c  = 123, Akatec_LOE_Delivery_Cost__c  = 123, PS_PerHour_Cost__c = 123,
                                                  Revenue_Months__c = 12, Total_Revenue_All_Months__c  = 12312, Total_Revenue_Filtered_Months__c =  10000);
                                                  
        System.runAs(ddaUser) {
            
            String dealStr = SC_DD_DealDeskCont.getDeal( 'Test Account 2' , 'Advanced', 'packageComp', 1231,  45678, 50, 'US (USD)', null, false, true);
            SC_DD_Deal__c dealRec = (SC_DD_Deal__c)JSON.deserialize(dealStr, SC_DD_Deal__c.class);
            Id dealId = SC_DD_DealDeskCont.saveDeal(dealRec);

            update new SC_DD_Deal__c(Id = dealId, Approval_Stage__c = 'SPO', Evaluation_Action__C = 'Escalated', Comments__c = 'Escalated', Commented_By__c = 'SLM/SLD');
            List<Map<String, Object>> history = SC_DD_FieldTracker.getHistory('SC_DD_deal__c', new List<String>{'Comments__c', 'Commented_By__c', 'Evaluation_Action__c', 'Deal_Zone__c', 'Approval_Stage__c', 'Auto_Escalated__c'}, dealId);
            
            System.assert(history.size() > 0, 'History Data');

            AuraHandledException auraException;
            try{
                SC_DD_FieldTracker.getHistory('', new List<String>(), dealId);
            } catch( AuraHandledException aex) {
                auraException = aex;
            }

            System.assert(auraException != null, 'Exception on invalid input');
        }

        Test.stopTest();
    }

    static void insertBatchConfig() {
        
        insert new List<SObject>{
            new SC_QM_USER_FILTER__c( User_Id__c = 'Deal_Desk', Status__c = 'New'),
            new SC_DD_BatchJob_Config__c(Name = 'MRR1',      Sequence_No__c = 1, IS_ODI_Data__c = true, Status__c = 'New',
                                         Query__c = 'select Id,Status__c from SC_DD_Customer_MRR__c order by Status__c'),
                
            new SC_DD_BatchJob_Config__c(Name = 'Revenue1',  Sequence_No__c = 2, IS_ODI_Data__c = true, Status__c = 'New',
                                        Query__c = 'select Id,Status__c from SC_DD_Revenue__c order by Status__c'),
                
            new SC_DD_BatchJob_Config__c(Name = 'Cost1',     Sequence_No__c = 3, IS_ODI_Data__c = true,  Status__c = 'New',
                                        Query__c = 'select Id,Status__c from SC_DD_Department_Cost__c order by Status__c', Is_Last_Record__c = true),
                
            new SC_DD_BatchJob_Config__c(Name = 'PreDealData1',  Sequence_No__c = 11, Status__c = 'New',
                                        Query__c = 'select Id,Status__c from SC_DD_Customer_PreDeal_Data__c'),
                
            new SC_DD_BatchJob_Config__c(Name = 'Deal Desk UI',  Status__c = 'Processed' ) 
        };      
        
        
    }
    
    static SC_DD_GSSServiceProduct__c getAnActiveProduct() {
        return [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c 
                from SC_DD_GSSServiceProduct__c
                where Is_Service_Support_Product__c = true and Is_Active__c = true and LOE_API_Call_Required__c = false order by Name limit 1][0];
    }
   
    
}