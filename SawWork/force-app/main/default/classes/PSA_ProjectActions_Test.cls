/***
    PSA_ProjectActions_Test
    @author Liz Ichihashi
    @Description : This Class tests the trigger that ensures that project manager and owner on a project
                   are always in sync.  If one is updated, the other is also.  PSA_Project_Trigger
                   is the name of the trigger that calls the PSA_ProjectActions method which 
                   contains the logic for this.
    @History
    --Developer           --Date             --Change
    Liz Ichihashi      1/04/2013         Created the class.    
    janantha           30/12/2014        Modified for CR 2808300
    Sharath            23 Dec 2016       Modified the class: Commented out the existing functions   
    Sharath            1st March 2017    Modified the class: Added the function to test the PSA_UpdateAssigmentsAction class
    Sharath            10th Aug 2017     Modified the class: Added the function to test the trigger for the Test Object
    Sharath            2nd feb 2018      Modified the class: added the function for delegated approval of timecards: FFPSA-142  
    Sharath            23rd April 2018   Modified the class: added the function for auto create of project Tasks: FFPSA-496  
    Sandeep            21st August 2018  Modified the class: added test function for FFPSA-620 : Exclude projects with BIC populated for projects with BED nearing 30 days
    Sandeep            22nd April 2019   Modified the class: added test function for FFPSA-1002 : Request to modify alert conditions for Project nearing BED
*/

//tets 
@isTest(SeeAllData=false) 
public class PSA_ProjectActions_Test {

    public static Id professionalServicesId;

    @testSetup
    public static void createTestDataSetup(){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
        //Map<String, Schema.SObjectType> globalDescribe1 = Schema.getGlobalDescribe();
        //Test.loadData(globalDescribe1.get('Email_to_Case__c'), 'Email_to_Case');  
        professionalServicesId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();

        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        insert esSetting;

        // SC_BOCC_Setup__c scBOCCSetup = new SC_BOCC_Setup__c();
        // scBOCCSetup.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scBOCCSetup.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scBOCCSetup.Product_Id__c = 'M-LC-160618';
        // scBOCCSetup.Name = 'BOCC';
        // insert scBOCCSetup;

        PSA_Settings__c validateOnRecallSetting = new PSA_Settings__c();
        validateOnRecallSetting.name = 'Validation On Timecard Recall Active';
        validateOnRecallSetting.Value__c = 'Yes';
        insert validateOnRecallSetting;

        GSM_Custom_Settings__c gsmSetting = new GSM_Custom_Settings__c();
        gsmSetting.Name = 'CastIronClass#AlertHourSetting';
        gsmSetting.Value__c = '1';
        //insert gsmSetting;
        GSM_Custom_Settings__c gsmSetting1 = new GSM_Custom_Settings__c();
        gsmSetting1.Name = 'CastIronClass#AlertToAddress';
        gsmSetting1.Value__c = 'vparimi-gmail@noemail-akamai.com';
        //insert gsmSetting1;
        GSM_Custom_Settings__c gsmSetting2 = new GSM_Custom_Settings__c();
        gsmSetting2.Name = 'CastIronClass#EmailTemplateName';
        gsmSetting2.Value__c = 'Castiron_Polling_Email_Template';
        //insert gsmSetting2;
        GSM_Custom_Settings__c gsmSetting3 = new GSM_Custom_Settings__c();
        gsmSetting3.Name = 'CastIronClass#OrgWideAddressId';
        gsmSetting3.Value__c = '0D2G00000004D7S';
        //insert gsmSetting3;
        GSM_Custom_Settings__c gsmSetting4 = new GSM_Custom_Settings__c();
        gsmSetting4.Name = 'CastIronClass#ReplyToAddress';
        gsmSetting4.Value__c = 'eaeblrops-gmail@noemail-akamai.com';
        //insert gsmSetting4;
        insert new List<GSM_Custom_Settings__c>{gsmSetting,gsmSetting1,gsmSetting2,gsmSetting3,gsmSetting4 };

        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;
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

        if(!psaSettings.isEmpty())
        {
            insert psaSettings;
        }
        //PSA_ProjectActions_Test.createTestData();
   
    } 

        Public static PSA_TestUtility testUtil;
        Public static pse__Region__c reg;
        Public static Account acct;
        Public static Contact resource;
        Public static Contact resource1;
        Public static pse__Project_Methodology__c  product1;
        Public static pse__Proj__c proj1;
        Public static pse__Practice__c pract;
        Public static Id practId;
        Public static pse__Milestone__c milestone;
        Public static pse__Assignment__c assign;
        Public static User usr;
        Public static User usr2;
        Public static Merge_Contract_Header__c contract;
        Public static Merge_Contract_Detail__c contDetail;
        Public static Project_Contract__c projCont;
        Public static Project_Contract_Line_Item__c projContItem;
        Public static pse__Schedule__c sched;
        Public static pse__Permission_Control__c pc;
    
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
        
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        usr.UserName =  '4201' + usr.UserName;
        usr.Title = 'Manager..Service Line';
        insert usr;
        
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        insert resource;


        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        System.debug('contract : '+ contract);
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(15));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');

        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 


    }

    

    //This method is used to test the function which sends out mail to TSP.
    public static testMethod void test_method_One()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();
        resource1 = testUtil.newResource(true, acct.Id, usr2.Id);
        Opportunity opp = testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
        opp.StageName = '1. Identify Need';
        opp.Validation_Override__c = TRUE;
        insert opp;
        List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 1);
        
        OpportunityTeamMember otm = new OpportunityTeamMember(
                                   TeamMemberRole = 'Technical Sales - Primary',
                                   OpportunityId = opp.Id,
                                   UserId        = usr.id);        
        insert otm;
        CheckRecursion.reset();        
        proj1.pse__Opportunity__c = opp.Id;
        update proj1;
        CheckRecursion.reset();                
        proj1.Basic_Implementation_Complete__c = Date.today().addDays(1000);
        proj1.Implementation_Complete__c = Date.today().addDays(1000);
        proj1.pse__End_Date__c = Date.today().addDays(1000);
        proj1.pse__Project_Manager__c = resource1.id;

        update proj1;
        test.stopTest();
    }
    
    //Method for project clone. Add an assignment to the project, Add a budget and a customer contact. Call the clone function
    @isTest static void test_method_Two()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();       
        System.runAs(usr)
        {   
                        
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            pse__Budget__c budget = testUtil.newBudget(true,proj1.Id,10.0, Date.today().addDays(100));  
            Customer_Contact__c c= new Customer_Contact__c ();
            c.Account__c = acct.Id;
            c.Contact__c = resource.Id;
            c.Project__c = proj1.id;
            insert c;          
            PSA_Project_Clone.CloneProjectAndChildRecords(proj1.id);
        }
        test.stopTest();        

    }
    //Change the project end date as a CRM Integration user. 
    @isTest static void test_method_Three()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();  
        USer crmUser = testUtil.newUserSysAdmin(false); 
        crmUser.ProfileId = [select id, name from Profile where name = 'CRM Integration'].id;
        insert crmUser;
        System.runAs(usr)
        {
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
        }
        System.runAs(crmUser)
        {      
            CheckRecursion.reset();                                 
            proj1.pse__End_Date__c = Date.today().addDays(356);
            proj1.Update_Milestone_Target_Date__c = true;
            update proj1;
        }
        test.stopTest();        

    }
    //Close the project for time entry. Then uncheck the closed for time entry check box
    @isTest static void test_method_Four()
    {
        PSA_ProjectActions_Test.createTestData();
        pse__Timecard_Header__c timecard1;
        test.startTest();       
        System.runAs(usr)
        {   
            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Saved';
            timecard1.pse__Monday_Hours__c = 1;
            insert timecard1;

            CheckRecursion.reset();
            proj1.pse__Closed_for_Time_Entry__c = true;
            proj1.PSA_Ignore_Saved_Timecards__c = true;            
            update proj1;

            CheckRecursion.reset();
            proj1.pse__Closed_for_Time_Entry__c = false;
            proj1.ownerid = usr2.id;            
            update proj1;

        }
        test.stopTest();        

    }

    //This function tests the closed for time entry for assignment and milestones
    @isTest static void test_method_Five()
    {
        PSA_ProjectActions_Test.createTestData();
        pse__Timecard_Header__c timecard1;
        test.startTest();       
        System.runAs(usr)
        {   
            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Saved';
            timecard1.pse__Monday_Hours__c = 1;
            insert timecard1;
            
            proj1.PSA_Ignore_Saved_Timecards__c = true;            
            update proj1;

            assign.pse__Closed_for_Time_Entry__c = true;
            update assign;

            milestone.pse__Closed_for_Time_Entry__c = true;
            update milestone;

        }
        test.stopTest();        

    }

    //Submit a timecard, as the project manager. Then change the manager of the project manager ->  This covers the PSA_TimecardApproverChange class and User_ai trigger
    @isTest static void test_method_Six()
    {   
        PSA_ProjectActions_Test.createTestData();
        pse__Timecard_Header__c timecard1;
        test.startTest();  

        System.runAs(usr)
        {   
            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Submitted';
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Monday_Hours__c = 1;
            insert timecard1;
            
        }
        user u3;
        System.runAs(usr2)
        {
            u3 = testUtil.newUserSysAdmin(true);
            usr.ManagerId = u3.id;
            update  usr;

        }

        PSA_Timecards_Approver_Change__c psaTimecards_Approver_Change = new PSA_Timecards_Approver_Change__c();
        psaTimecards_Approver_Change.New_Approver__c = u3.id;
        psaTimecards_Approver_Change.Old_Approver__c = usr2.id;
        psaTimecards_Approver_Change.IsProcessed__c = false;
        psaTimecards_Approver_Change.Timecard__c = timecard1.Id;
        insert psaTimecards_Approver_Change;
        
        PSA_TimecardApproverChangeBatch b = new PSA_TimecardApproverChangeBatch();
        database.executeBatch(b);        
        test.stopTest();        

    }

    //Re-assign a timecard, then makes that approver inactive
    @isTest static void test_method_Seven()
    {
        PSA_ProjectActions_Test.createTestData();
        pse__Timecard_Header__c timecard1;
        test.startTest();       
        System.runAs(usr)
        {   
            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Submitted';
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Monday_Hours__c = 1;
            insert timecard1;
            
        }
        user u3 = testUtil.newUserSysAdmin(true);
        ProcessInstanceWorkItem piw = [select id, Actorid from ProcessInstanceWorkItem where ProcessInstance.targetObjectId = :timecard1.id limit 1];
        piw.actorid = u3.id;
        update piw;

        System.runAs(usr2)
        {
            u3.IsActive = false;        
            update  u3;

        }

        test.stopTest();        

    }

    //Submit a timecard as a resource, not the project manager. Then change the project manager
    @isTest static void test_method_Eight()
    {
        PSA_ProjectActions_Test.createTestData();
        pse__Timecard_Header__c timecard1;
        test.startTest();
        testUtil.newPermissionControl(true, usr2.Id, reg.Id);         
        System.runAs(usr2)
        {   
            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);           
            assign = testUtil.newAssignment(true, proj1.Id, resource1.Id, sched.Id);
            testUtil.newPermissionControl(true, usr2.Id, reg.Id);  
            timecard1 = testUtil.newTimecardHeader(false, resource1.Id, proj1.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Submitted';
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Monday_Hours__c = 1;
            insert timecard1;
        }
        System.runAs(usr)
        {
            User u3 = testUtil.newUserSysAdmin(true);
            usr2.ManagerId = u3.id;
            update usr2;            
        }

        CheckRecursion.reset();
        proj1.pse__Project_Manager__c = resource1.id;
        update proj1;

        Map<id,List<Contact>> projectToContacts = new Map<id,List<Contact>>();
        projectToContacts.put(proj1.id,new List<Contact>());
        projectToContacts.get(proj1.id).add(resource);
        projectToContacts.get(proj1.id).add(resource1);
        Set<id> userIds = new Set<id>();
        userIds.add(usr.id);

        PSA_TimecardApproverChange timecardApproverChange = new PSA_TimecardApproverChange();
        timecardApproverChange.queryType = 'project';
        timecardApproverChange.projectToContacts = projectToContacts;
        timecardApproverChange.userIds = userIds;
        System.enqueueJob(timecardApproverChange);


        test.stopTest();        

    }

    //This method tests the automated creation of assignments on projects linked to cases, when the case owner changes from a queue to a user
    @isTest static void test_method_Nine()
    {

		PSA_ProjectActions_Test.createTestData();
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
        
        //changes by Sharath
        List<SCUserIdCustomSetting__c> userscUserIdCustomSettings = new List<SCUserIdCustomSetting__c>();
        SCUserIdCustomSetting__c scUserIdCustomSetting1 = new SCUserIdCustomSetting__c();
        scUserIdCustomSetting1.Name = 'Primary/SecondaryAssignmentQueue';
        scUserIdCustomSetting1.UserId__c = '00GG0000002igPLMAY';
        userscUserIdCustomSettings.add(scUserIdCustomSetting1);

        SCUserIdCustomSetting__c scUserIdCustomSetting2 = new SCUserIdCustomSetting__c();
        scUserIdCustomSetting2.Name = 'Cash Apps';
        scUserIdCustomSetting2.UserId__c = '00GG0000004T105';
        userscUserIdCustomSettings.add(scUserIdCustomSetting2);

        insert userscUserIdCustomSettings;

        SCRecordTypeCustomSetting__c scRecordTypeCustomSetting1 = new SCRecordTypeCustomSetting__c();
        scRecordTypeCustomSetting1.Name = 'NotificationTeam';
        scRecordTypeCustomSetting1.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';
        scRecordTypeCustomSetting1.RecordTypeDeveloperName__c = '';
        insert scRecordTypeCustomSetting1;


        SC_RiverbedCaseProdID__c sc_RiverbedCaseProdIDSetting = new SC_RiverbedCaseProdID__c();
        sc_RiverbedCaseProdIDSetting.Name = 'Riverbed_SAAS_OEM';
        sc_RiverbedCaseProdIDSetting.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        sc_RiverbedCaseProdIDSetting.RecordTypeID__c = '012G0000000z10xIAA';

        insert sc_RiverbedCaseProdIDSetting;

        SC_FromEmailAddress__c sc_FromEmailAddress1 = new SC_FromEmailAddress__c();
        sc_FromEmailAddress1.Name = 'Noreply';
        sc_FromEmailAddress1.FromAddress__c = 'sf-no-reply@akamai.com';
        sc_FromEmailAddress1.OrgAddressId__c = '0D2G00000004FpYKAU';
        insert sc_FromEmailAddress1;

        test.startTest();       
        System.runAs(usr)
        {   
            sched = testUtil.newSchedule(true, System.today().addDays(-4), System.today().addDays(-1));
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);

            List<Case> cases = new List<Case>();
            professionalServicesId  = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            Id queueId = [select id from group where name like 'PS_%_Queue' limit 1].id;
            Case  c1 = new Case();
            //c1.RecordTypeID = '012G0000000z10u';
            c1.RecordTypeID = professionalServicesId;
            c1.AccountID = acct.id;
            c1.Origin = 'Email';
            c1.Contract__c = contract.id;
            c1.Description = 'test';
            c1.pse_Project__c = proj1.id;            
            c1.ownerid = queueId;
            c1.Validation_Override__c = true;
            cases.add(c1);

            Case  c2 = new Case();
            //c2.RecordTypeID = '012G0000000z10u';
            c2.RecordTypeID = professionalServicesId;
            c2.AccountID = acct.id;
            c2.Origin = 'Email';
            c2.Contract__c = contract.id;
            c2.Description = 'test';
            c2.pse_Project__c = proj1.id; 
            c2.ownerid = queueId; 
            c2.Validation_Override__c = true;
            cases.add(c2);          

            insert cases;

            project_Case_Association__c pca= new project_Case_Association__c();
            pca.Case__c = c1.id;
            pca.Contract__c = contract.id;
            pca.Project__c = proj1.id;
            insert pca;

            resource1 = testUtil.newResource(true, acct.Id, usr2.Id);
            resource1.email = 'PSAProjMgr2@akamai.com';
            update resource1;

            c1.ownerId = usr2.Id;
            c2.ownerId = usr.Id;             
            c1.Validation_Override__c = true;
            c2.Validation_Override__c = true;

            cases = new List<Case>();
            cases.add(c1);
            cases.add(c2);
            update cases;
        }

        test.stopTest();        

    }

    //Method to test PSA_UpdateAssigmentsAction. Add an assignment to the project and call the updateAssignmentEndDates method.
    @isTest static void test_method_ten()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();       
        System.runAs(usr)
        {   
                        
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            pse__Budget__c budget = testUtil.newBudget(true,proj1.Id,10.0, Date.today().addDays(100));  
            String result = PSA_UpdateAssigmentsAction.updateAssignmentEndDates(proj1.id);
        }
        test.stopTest();        

    }

    @isTest static void Test_Object_Method1()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();       
        System.runAs(usr)
        {   
            assign = testUtil.newAssignment(true, proj1.Id, resource.Id, sched.Id);
            List<Test__c> tests = new List<Test__c>();
            Test__c test =  new Test__c();
            test.Estimated_Test_Duration__c = 12;
            test.Engagement__c = proj1.id;
            test.Deliverable__c = milestone.Id;
            tests.add(test);

            Test__c test2 =  new Test__c();
            test2.Estimated_Test_Duration__c = 12;
            test2.Engagement__c = proj1.id;
            test2.Deliverable__c = milestone.Id;
            tests.add(test2);

            insert tests;

            Attachment a = new Attachment();
            a.Parentid = test.Id;
            a.Name = 'test';
            Blob attach = Blob.valueOf('test');
            a.body = attach;
            insert a;

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.VersionData = Blob.valueOf('test');
            cv.Title = 'test';
            cv.PathOnClient = 'test';
            cv.FirstPublishLocationId = userInfo.getUserID();
            //cv.SharingOption = 'A';
            //cv.SharingPrivacy = 'N';
            insert cv;        

            Id ContentDocumentID = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;

            List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = ContentDocumentID;
            cdl.LinkedEntityId = test.Id;
            cdl.ShareType = 'V';    
            contentDocumentLinks.add(cdl);

            ContentDocumentLink cdl2 = new ContentDocumentLink();
            cdl2.ContentDocumentId = ContentDocumentID;
            cdl2.LinkedEntityId = test2.Id;
            cdl2.ShareType = 'V';
            contentDocumentLinks.add(cdl2);
            
            insert contentDocumentLinks;

            ContentDocument cd = [select id from ContentDocument where id = :ContentDocumentID limit 1];
            try
            {
                delete test;
            }
            catch(Exception e)
            {

            }
            try
            {
                delete a;                
                delete cd;                
            }
            catch(Exception e)
            {

            }
            try
            {

            }
            catch(Exception e)
            {
                delete cdl2;
            }
            test.Valid_Delete__c = true;
            update test;
            delete test;
        }
        test.stopTest();        

    }
    @isTest static void Test_Object_Method2()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();       
        //System.runAs(usr)
        {   
            Test__c test1 =  new Test__c();
            test1.Estimated_Test_Duration__c = 12;
            test1.Engagement__c = proj1.id;
            test1.Deliverable__c = milestone.Id;
            test1.Testing_PE_multi__c = 'test1;test2;test3';
            test1.Test_Date_Time__c = date.today();
            //test1.Report_Required__c = false;
            test1.Known_Issues_and_Errors__c = 'test';
            test1.Goals__c = 'test';
            test1.Notes__c = 'test';

            insert test1;
        

            PSA_CloneTestRecords.cloneTestRecord(test1.Id);

            PageReference pageRef = Page.PSA_SoastaResource;
            Test.setCurrentPage(pageRef); 
            
            ApexPages.StandardController sc = new ApexPages.StandardController(new Test__c());
            ApexPages.currentPage().getParameters().put('id', test1.Id);

            PSA_SoastaResourceController controller = new PSA_SoastaResourceController(sc);
            
            

            
            List<SelectOption> chosenList = controller.chosenList;
            List<SelectOption> availableList = controller.availableList;
            Test__c testRecord = controller.testRecord;

            controller.saveField();

            controller.CancelField();
            
        }
        test.stopTest();        

    }

    //Adding the method to cover delegation of timecards
    @isTest static void delegation1()
    {
		PSA_ProjectActions_Test.createTestData();
        test.startTest();  
            user usr3 = testUtil.newUserSysAdmin(true); 
            //Run as user usr3 and change the profile of usr2
            System.runAs(usr3)
            {
                usr2.profileid = [select id from profile where name = 'GSS Professional Services' limit 1].id;
                update usr2;
            }     
            //update the delegated approver of usr as usr2 and set the end date to today
            //This covers the user trigger and delegated approver history object trigger and controller function
            
            usr.delegatedapproverid= usr2.id;
            usr.delegation_endtime__c = Date.today();
            update usr;

            //update the custom delegated approver field to null and update the record
            //This covers the user trigger and delegated approver history object trigger and controller function

            usr.Delegated_Approver_Custom__c = null;
            update usr; 
            
            //run as usr. Covering the delegated approver custom page            
            System.runAs(usr)
            {
                PSA_DelegatedApproverController delegatedApprover = new PSA_DelegatedApproverController ();
                String message = delegatedApprover.messageString;

                //Set the delegated approver to usr2 and the end time to today - 1 day. This covers validation messages
                delegatedApprover.loggedInUser.delegatedapproverid = usr2.id;
                delegatedApprover.loggedInUser.delegation_endtime__c = Date.today().addDays(-1);
                delegatedApprover.saveApprover();    

                //set the end date to today and call the save method
                delegatedApprover.loggedInUser.delegation_endtime__c = Date.today();
                delegatedApprover.saveApprover();    

                //set the delegated approver to null and call the save method
                message = delegatedApprover.messageString;
                delegatedApprover.loggedInUser.delegatedapproverid = null;
                delegatedApprover.saveApprover();    

            }
                
        test.stopTest();    

    }
    @isTest static void delegation2()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();  
            user usr3 = testUtil.newUserSysAdmin(true); 
            FF_Delegation_History__c delgatedHistory = new FF_Delegation_History__c();
            delgatedHistory.Delegation_For__c = usr2.Id;
            delgatedHistory.Delegated_Approver__c = usr.id;
            delgatedHistory.Delegation_Start_Time__c = Datetime.now();
            delgatedHistory.Delegation_End_Time__c = Date.today();

            insert delgatedHistory;

            delgatedHistory.Delegated_Approver__c = usr3.id;
            update delgatedHistory;
            
            delgatedHistory.Delegated_Approver__c = NULL;
            update delgatedHistory;
        test.stopTest();    

    }

    //test method for PSA Task creation: Reminder on 1st of each month
    @isTest static void testTaskCreation()
    {
		PSA_ProjectActions_Test.createTestData();
        test.startTest();
            acct.TERR_HIER_2__c = 'Emerging Verticals';
            update acct;

            contDetail.product_id__c = 'M-LC-120877';
            update contDetail;

            database.executeBatch(new PSA_CreateProjectTaskBatch());
        
        test.stopTest();
    }

    //public static testMethod void testUpdateProjectManager() {
    //    PSA_TestUtility testUtil = new PSA_TestUtility();
    //    pse__Region__c reg = testUtil.newRegionMaster(true);
    //    Account acct = testUtil.newAccount(true);        
    //    User usr = testUtil.newUserSysAdmin(true);        
    //    Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
    //    User usr2 = testUtil.newUserSysAdmin(true);        
    //    Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
    //    Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
    //    List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 1);
    //    pse__Practice__c pract = testUtil.newPracticeMaster(true);
    //    Id practId = pract.ID;
    //    pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);        
    //    test.startTest();
    //    proj.pse__Project_Manager__c =  resource2.Id;
    //    update proj;
        
    //    proj = [Select OwnerId, pse__Project_Manager__c from pse__Proj__c where id = :proj.Id];
    //    System.assert(proj.OwnerId == usr2.Id);
    //    test.stopTest();
    //} 

    // Test that when owner is updated on a project, the project manager is also updated to be the same 
    //public static testMethod void testUpdateProjectOwner() {
    //    PSA_TestUtility testUtil = new PSA_TestUtility();
    //    pse__Region__c reg = testUtil.newRegionMaster(true);
    //    Account acct = testUtil.newAccount(true);        
    //    User usr = testUtil.newUserSysAdmin(true);        
    //    Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
    //    User usr2 = testUtil.newUserSysAdmin(true);        
    //    Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
    //    Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
    //    List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 1);
    //    pse__Practice__c pract = testUtil.newPracticeMaster(true);
    //    Id practId = pract.ID;
    //    test.startTest();
    //    pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);    
    //    proj.OwnerId = usr2.Id;
    //   // proj.Update_Milestone_Target_Date__c = true;
    //    update proj;
        
    //    proj = [Select OwnerId, pse__Project_Manager__c from pse__Proj__c where id = :proj.Id];
    //    System.assert(proj.pse__Project_Manager__c == resource2.Id);
    //    test.stopTest();
    //} 
    
    //Start of changes for janantha for CR 2808300
    //public static testMethod void testProjectEndDateChange()
    //{
    //    PSA_TestUtility testUtil = new PSA_TestUtility();
    //    pse__Region__c reg = testUtil.newRegionMaster(true);
    //    Account acct = testUtil.newAccount(true);        
    //    User usr = testUtil.newUserSysAdmin(true);        
    //    Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
    //    User usr2 = testUtil.newUserSysAdmin(true);        
    //    Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
    //    Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
    //    List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 1);
    //    pse__Practice__c pract = testUtil.newPracticeMaster(true);
    //    Id practId = pract.ID;
    //    pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id); 
    //    pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,date.newInstance(2015, 08, 21));
    //    proj.pse__End_Date__c = Date.today().addDays(50);
    //    proj.Update_Milestone_Target_Date__c = true;
    //    update proj;
    //}   
    //End of changes for janantha for CR 2808300

    //Start of changes by janantha for CR 2576145
    //public static testMethod void testProjectManagerChange()
    //{
    //    PSA_TestUtility testUtil = new PSA_TestUtility();
    //    pse__Region__c reg = testUtil.newRegionMaster(true);
    //    Account acct = testUtil.newAccount(true);        
    //    User usr = testUtil.newUserSysAdmin(true);           
    //    User usr2 = testUtil.newUserSysAdmin(true);           
    //    Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
    //    List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
    //    pse__Practice__c pract = testUtil.newPracticeMaster(true);
    //    Id practId = pract.ID;
    //    User usr1 = testUtil.newUserSysAdmin(true);  
    //    pse__Proj__c proj1;
    //    pse__Assignment__c assign;
    //    pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr1.Id, reg.Id);
    //    pse__Timecard_Header__c timecard;
    //    Contact resource;
    //    Contact resource2;
    //    pse__Milestone__c milestone;
    //    pse__Project_Methodology__c  product1;

    //    System.runAs(usr1) 
    //    {
    //        test.startTest();
    //        resource2 = testUtil.newResource(true, acct.Id, usr1.Id);
    //        resource2.email = 'PSAProjMgr1@akamai.com';
    //        update resource2;
    //        resource = testUtil.newResource(true, acct.Id, usr.Id);
    //        resource.email = 'PSAProjMgr2@akamai.com';
    //        update resource;
    //        proj1 = testUtil.newProject(true,reg.id,practId,false,'One-Time: Fixed Price', resource.Id, acct.Id); 
        
    //        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
    //        milestone.Billable__c = false;
    //        insert milestone;
    //        Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
    //        Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
    //        Project_Contract__c projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
    //        Project_Contract_Line_Item__c projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
    //        pse__Schedule__c sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
    //        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');                           
        
    //        assign = testUtil.newAssignment(false, proj1.Id, resource2.Id, sched.Id);
    //        assign.pse__Is_Billable__c = false;
    //        assign.pse__Bill_Rate__c = 0.0;
    //        insert assign;
                          
    //        timecard = testUtil.newTimecardHeader(false, resource2.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
    //        timecard.pse__Billable__c = false;
    //        timecard.pse__Project_Methodology_Object__c = product1.Id;
             
    //        timecard.pse__Status__c = 'Submitted'; 
    //        timecard.pse__Monday_Hours__c = 1;
    //        insert timecard;
              
    //        Contact resource1 = testUtil.newResource(true, acct.Id, usr2.Id);
    //        resource1.email = 'PSAProjMgr3@akamai.com';
    //        update resource1;
    //        proj1.pse__Project_Manager__c = resource1.Id;
    //        update proj1;
    //        test.stopTest();

    //    }
    //} 
    //End of changes by janantha for CR 2576145

     @isTest static void preventDupBEDTest()
     {
         PSA_ProjectActions_Test.createTestData();
         test.startTest(); 
        pse__Proj__c proj = [select Id, Billing_Effective_Date__c from pse__Proj__c limit 1];
        Delete [select Id from Task where whatId = :proj.Id ];
        Id PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();
        List<Task> tasks = new List<Task>();


        
        System.runAs(usr)
        {
            Task tsk = new Task();
            tsk.whatId = proj.Id;
            tsk.Type__c = 'BED Extension Required';
            tsk.ActivityDate = date.today()+ 3;
            tsk.RecordTypeId = PSAActivityId;
            
            insert tsk;

            Task tsk2 = new Task();
            tsk2.whatId = proj.Id;
            tsk2.Subject = 'Subject for Task to be updated';
            tsk2.Type__c = 'BED Extension Required';
            tsk2.ActivityDate = date.today()+1;
            tsk2.RecordTypeId = PSAActivityId;

            Database.insert(tsk2, false);

        }

        test.stoptest();

     }

    @isTest static void notifyBEDTest()
    {
        PSA_ProjectActions_Test.createTestData();
        //Sujay : updating Project and deleting Project within test.startTest() 
        test.startTest();
            pse__Proj__c proj = [select Id, Billing_Effective_Date__c from pse__Proj__c limit 1];
            proj.Billing_Effective_Date__c = date.today()+ 2;
            proj.Basic_Implementation_Complete__c = null;
            update proj;
    
    
            Delete [select Id from Task where whatId = :proj.Id ];
    
            Id PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();
            List<Task> tasks = new List<Task>();
    
            System.runAs(usr)
            {
                PSA_ProjectActions.isFirstTime = true ;
                    Task tsk = new Task();
                    tsk.whatId = proj.Id;
                    tsk.Type__c = 'BED Extension Required';
                    tsk.ActivityDate = date.today()+ 3;
                    tsk.RecordTypeId = PSAActivityId;
    
                    //insert tsk;
                    
    
                    tasks.add(tsk);
    
                    Task tsk2 = new Task();
                    tsk2.whatId = proj.Id;
                    tsk2.Subject = 'Subject for Task to be updated';
                    tsk2.ActivityDate = date.today()+1;
                    tsk2.RecordTypeId = PSAActivityId;
    
                    tasks.add(tsk2);
                    //insert tasks;
    
    
                    Task tsk3 = new Task();
                    tsk3.whatId = proj.Id;
                    tsk3.Type__c = 'BED Extension Required';
                    tsk3.ActivityDate = date.today()+ 10;
                    tsk3.RecordTypeId = PSAActivityId;
                    
                    //insert tsk;
                    
                    
                    tasks.add(tsk3);
    
                    Task tsk4 = new Task();
                    tsk4.whatId = proj.Id;
                    tsk4.Subject = 'Subject for Task to be updated';
                    tsk4.ActivityDate = date.today()+10;
                    tsk4.RecordTypeId = PSAActivityId;
    
                    tasks.add(tsk4);
                    Database.insert(tasks, false);
    
                    Task toUpdateTsk = [select Id from Task where Subject = 'Subject for Task to be updated' limit 1];
    
                    toUpdateTsk.Type__c = 'BED Extension Declined';
    
                    try 
                    {
                        update toUpdateTsk;
                    }
                    catch(Exception exc)
                    {
                        System.debug('messgg :' + exc);
                    }
    
                    Database.executeBatch(new PSA_BEDCheckfor5Days());
    
            }
        test.stopTest();
    }

    @isTest static void notifyBEDTest2()
    {
        PSA_ProjectActions_Test.createTestData();
        //Sujay : updating Project and deleting Project within test.startTest() 
        test.startTest();
            proj1.Billing_Effective_Date__c = date.today()+ 10;
            proj1.Basic_Implementation_Complete__c = null;
            update proj1;
    
            Delete [select Id from Task where whatId = :proj1.Id ];
    
            Id PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();
            List<Task> tasks = new List<Task>();
    
    
            System.runAs(usr)
            {
                PSA_ProjectActions.isFirstTime = true ;
    
                Task tsk3 = new Task();
                tsk3.whatId = proj1.Id;
                tsk3.Type__c = 'BED Extension Required';
                tsk3.ActivityDate = date.today()+ 10;
                tsk3.RecordTypeId = PSAActivityId;
                
                //insert tsk;
                
                tasks.add(tsk3);
    
                Task tsk4 = new Task();
                tsk4.whatId = proj1.Id;
                tsk4.Subject = 'Subject for Task to be updated';
                tsk4.ActivityDate = date.today()+10;
                tsk4.RecordTypeId = PSAActivityId;
    
                tasks.add(tsk4);
                Database.insert(tasks, false);
    
                Task toUpdateTsk = [select Id from Task where Subject = 'Subject for Task to be updated' limit 1];
    
                toUpdateTsk.Type__c = 'BED Extension Declined';
    
                try 
                {
                    update toUpdateTsk;
                }
                catch(Exception exc)
                {
                    System.debug('messgg :' + exc);
                }
    
                Database.executeBatch(new PSA_BEDCheckfor30Days());
    
            }
        
        test.stopTest();

    }


    @isTest static void notifyforBEDExtension()
    {
        PSA_ProjectActions_Test.createTestData();
        pse__Proj__c proj = [select Id, Billing_Effective_Date__c from pse__Proj__c limit 1];

        proj.Billing_Effective_Date__c = proj.Billing_Effective_Date__c +30 ;

        test.startTest();

        PSA_ProjectActions.isFirstTime = true ;

        update proj;

        test.stopTest();

    }
    
    @isTest static void updateBICAndICOnProjectforNewImplementation()
    {
        PSA_ProjectActions_Test.createTestData();
        //Start test
        test.startTest();
        
        List<pse__Project_Methodology__c> projectProductList = new List<pse__Project_Methodology__c>();
        
        delete product1;
         
        //Project products are created with BIC and Go-Live Date filled
        pse__Project_Methodology__c product2 = testUtil.newProjectProduct(false,proj1.Id,'Aqua');
        product2.Go_Live_Date__c = System.today().addDays(6);
        projectProductList.add(product2);
        System.debug('@@product1.Go_Live_Date__c__c: '+product1.Go_Live_Date__c+' ## ProjectId: '+proj1.Id+ '### Prod ID: '+product1.id);    
        
        upsert projectProductList;
        
        //CLOSE the project with COMPLETE
        List<pse__Proj__c> projectToCloseList = new List<pse__Proj__c>();
        projectToCloseList.add(proj1);
         
        projectToCloseList = testUtil.closeProjects(false,projectToCloseList,resource.Id);
        for(pse__Proj__c eachProject : projectToCloseList)
        {
            //Generic Case: Create a project of type 'New Implementation' and Customer Live checked
            eachProject.pse__Project_Type__c = 'New Implementation';
            eachProject.Customer_Live__c = true;
            eachProject.pse__Allow_Timecards_Without_Assignment__c = false;
            eachProject.Basic_Implementation_Complete__c = null;
            
        }
        System.debug('##projectToCloseList: '+projectToCloseList);
        
        update projectToCloseList;
        
        test.stopTest();
        
    }


    //Create test method to send emails for BED notification
    @isTest static void sendEmailForBEDNotification5Days()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();


            //update PCLI
            projContItem.Product_Text_Area__c = 'Professional Services - Managed Integration';
            update projContItem;

            
            delete product1;
            pse__Project_Methodology__c product2 = testUtil.newProjectProduct(false,proj1.Id,'Aqua');
            product2.Basic_Implementation_Complete__c = null;
            upsert product2;

            Delete [select Id from Task where whatId = :proj1.Id ];


            //Update BED on Project to within 5 days
            proj1.Billing_Effective_Date__c = date.today()+ 2;
            update proj1;
 

            Database.executeBatch(new PSA_BEDCheckfor5Days());



        test.stopTest();

            
    }

    //Create test method to send emails for BED notification
    @isTest static void sendEmailForBEDNotification30Days()
    {
        PSA_ProjectActions_Test.createTestData();
        test.startTest();


            //update PCLI
            projContItem.Product_Text_Area__c = 'Professional Services - Managed Integration';
            update projContItem;

            
            delete product1;
            pse__Project_Methodology__c product2 = testUtil.newProjectProduct(false,proj1.Id,'Aqua');
            product2.Basic_Implementation_Complete__c = null;
            upsert product2;

            Delete [select Id from Task where whatId = :proj1.Id ];


            //Update BED on Project to within 30 days, but after 5 days
            proj1.Billing_Effective_Date__c = date.today()+ 10;
            update proj1;

            Database.executeBatch(new PSA_BEDCheckfor30Days());

        test.stopTest();

            
    }


}