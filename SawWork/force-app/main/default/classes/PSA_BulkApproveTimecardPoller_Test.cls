/*
* Author: Sharath Prasanna
* This is the Test class for  PSA_BulkApproveTimecardPollerController class
* Changes by Sharath: Setting the seeAlldata to true and restructuring the whole test class
* Changes by Sharath: adding the test method for multi approval page.
*Changes by Suhas: SeeAllData=false
* Changes by Sharath: Refactored the class
*/
@isTest(SeeAllData=false)
private class PSA_BulkApproveTimecardPoller_Test
{
        public static PSA_TestUtility testUtil; 
        public static pse__Region__c reg;
        public static Account acct;
        public static Contact resource;
        public static Contact resource2;
        //Contact resource1;
        public static pse__Timecard_Header__c timecard;
        public static pse__Timecard_Header__c timecard2;
        public static pse__Project_Methodology__c  product1;
        public static pse__Proj__c proj1;
        public static pse__Practice__c pract;
        public static pse__Milestone__c milestone;
        public static pse__Assignment__c assign;
        public static User usr;
        public static User usr2;
        public static Merge_Contract_Header__c contract;
        public static Merge_Contract_Detail__c contDetail;
        public static Project_Contract__c projCont;
        public static Project_Contract_Line_Item__c projContItem;
        public static pse__Schedule__c sched;
        public static pse__Permission_Control__c pc;

   
    static
    {
        testUtil = new PSA_TestUtility();
        // if( SC_BOCC_Setup__c.getValues('BOCC') == null)
        // {
        //     SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        //     scSetting.Name = 'BOCC';
        //     scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //     scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //     scSetting.Product_Id__c = 'M-LC-160618';
        //     insert scSetting;
        // }
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true);
        usr.Managerid = usr2.id;
        usr.delegatedapproverid = usr2.id;
        insert usr;
        
        List<Contact> contacts = new List<Contact>();
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        contacts.add(resource);

        resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
        resource2.email = 'PSAProjMgr4@akamai.com';
        resource2.Validation_Override__c = true;
        contacts.add(resource2);

        insert contacts;

        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');

        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);  

        
        //create a permission control record for usr2
        testUtil.newPermissionControl(true, usr2.Id, reg.Id);  
        
        
    }
  @isTest static void testController()
  {

        test.startTest();

        List <pse__Timecard_Header__c> timecards = new List <pse__Timecard_Header__c>();


        System.runAs(usr)
        {     
            timecard = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard.pse__Billable__c = true;
            timecard.pse__Project_Methodology_Object__c = product1.Id;
            timecard.pse__Status__c = 'Submitted'; 
            timecard.pse__Monday_Hours__c = 1;
            timecards.add(timecard);  

            try
            {
                insert timecards;                  
            }
            catch (Exception e)
            {
                
            }
        }


        PageReference pageRef = Page.PSA_BulkApproveTimecardPoller;
        //pageRef.getParameters().put('comment','Test');
        //pageRef.getParameters().put('action','Approve');
        String timecardIDS = timecard.ID;//+','+timecard2.id ;
        PSE_Timecard_Approval_Object__c approvalObject = new PSE_Timecard_Approval_Object__c();
        approvalObject.Timecard_IDs__c = timecardIDS;
        approvalObject.Comments__c = 'test';
        approvalObject.Action__c = 'Approve';
        insert approvalObject;
      
        //PSA_Settings__c psetting = PSA_Settings__c.getInstance('TimecardBatchSize');
        //psetting.Value__c = '1';
        //update psetting;      

        pageRef.getParameters().put('ApprovalObjectID',approvalObject.ID);
        Test.setCurrentPage(pageRef);

        PSA_BulkApproveTimecardPollerController pollerController = new PSA_BulkApproveTimecardPollerController();
        //System.assert(pollerController.Comment == 'Test');
        //pollerController.Comment = 'Test Approve';
        //pollerController.Action = 'Approve'
        //TimecardIDList = new 
        pollerController.ApproveorRejectTimecards();
        pollerController.UnprocessedTimecardsError();
        pollerController.redirectToApprovalPage();
        pollerController.sendProcessTerminationMail();      

        test.stopTest();    
  }

  //Adding the test method for multi approval page
  @isTest static void testMultiApprovalPageMethod1()
  {
      Test.startTest();


        //Runa as usr and submit a timecard. It'll be pending with the user usr2
        System.runAs(usr)
        {     
            timecard = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard.pse__Billable__c = true;
            timecard.pse__Project_Methodology_Object__c = product1.Id;
            timecard.pse__Status__c = 'Submitted'; 
            timecard.pse__Monday_Notes__c = 'Test';
            timecard.pse__Monday_Hours__c = 1;
            timecard.psE__submitted__c = true;
            insert timecard;  
        }            

        //run as usr2. Open the multi approval page
        System.runAs(usr2)
        {
                //Setting up the page
                PageReference pageRef = Page.PSA_TCApproveNew;
                List<pse__Timecard_Header__c> TC2ApproveBYUserFilters = new List<pse__Timecard_Header__c>();
                Test.setCurrentPage(pageRef);
                PSA_BulkApproveFromEmailController bulkApproveFromEmailController = new PSA_BulkApproveFromEmailController();
                
                //set filters so that the submitted timecard gets selected
                bulkApproveFromEmailController.MyFilter10 = null;  
                bulkApproveFromEmailController.MyFilter1 = timecard.pse__Project__c;
                bulkApproveFromEmailController.MyFilter2 = acct.id;
                bulkApproveFromEmailController.MyFilter3 = resource.id;
                bulkApproveFromEmailController.MyFilter4 = milestone.Id;
                bulkApproveFromEmailController.MyFilter6 = System.today();
                bulkApproveFromEmailController.MyFilter7 = System.today().addDays(6);
                bulkApproveFromEmailController.MyFilter9 = 'True';

                
                TC2ApproveBYUserFilters.add(timecard);
                bulkApproveFromEmailController.lMCaseERjson = JSON.serialize(TC2ApproveBYUserFilters);
                
                //call the various functions in the controller
                bulkApproveFromEmailController.populateMyTable();
                bulkApproveFromEmailController.ApproveMyRecords();
                bulkApproveFromEmailController.RefreshFilterProject();
                bulkApproveFromEmailController.RefreshFilterMilestone();
                bulkApproveFromEmailController.resetFilters();
                bulkApproveFromEmailController.getTimecards2Approve();
                bulkApproveFromEmailController.refreshMyFilters();
                bulkApproveFromEmailController.pageMessageUpdate();

                
                TC2ApproveBYUserFilters = new List<pse__Timecard_Header__c>{timecard};
                bulkApproveFromEmailController.TC2ApproveBYUserFilters = TC2ApproveBYUserFilters;
                
                //Access the filter options in the controller
                Id userId = bulkApproveFromEmailController.currentUserId;
                List <SelectOption> options;
                options =bulkApproveFromEmailController.DelegatedTimecardOptions;
                options =bulkApproveFromEmailController.BillableOptions;
                options = bulkApproveFromEmailController.ProductFilter;
                options = bulkApproveFromEmailController.MilestoneFilter;
                options = bulkApproveFromEmailController.ResourcesFilter;
                options = bulkApproveFromEmailController.projectsOwned1;
                options = bulkApproveFromEmailController.AccountsOwned;

                String preferenceID = bulkApproveFromEmailController.Userpreference;
                preferenceID = bulkApproveFromEmailController.DisplayMessage;
                preferenceID = bulkApproveFromEmailController.MyFilter5;


                TC2ApproveBYUserFilters = bulkApproveFromEmailController.TC2ApproveBYUserFilters;
                pse__proj__c proj =bulkApproveFromEmailController.proj;
                
                
                //Set the delegated filter to True and call the populateMyTable method
                bulkApproveFromEmailController.MyFilter10 = 'True';   
                bulkApproveFromEmailController.populateMyTable();


        }
        Test.stopTest();
  }

  @isTest static void testMultiApprovalPageMethod2()
  {
      Test.startTest();


        //Runa as usr and submit a timecard. It'll be pending with the user usr2
        System.runAs(usr)
        {     
            timecard = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard.pse__Billable__c = true;
            timecard.pse__Project_Methodology_Object__c = product1.Id;
            timecard.pse__Status__c = 'Submitted'; 
            timecard.pse__Monday_Notes__c = 'Test';
            timecard.pse__Monday_Hours__c = 1;
            timecard.psE__submitted__c = true;
            insert timecard;  
        }            

        //run as usr2. Open the multi approval page
        System.runAs(usr2)
        {
                //Setting up the page
                PageReference pageRef = Page.PSA_TCApproveNew;
                List<pse__Timecard_Header__c> TC2ApproveBYUserFilters = new List<pse__Timecard_Header__c>();
                Test.setCurrentPage(pageRef);
                PSA_BulkApproveFromEmailController bulkApproveFromEmailController = new PSA_BulkApproveFromEmailController();
                String urlString = bulkApproveFromEmailController.url;
                Date StartDate = bulkApproveFromEmailController.StartDate;
                Date EndDate = bulkApproveFromEmailController.EndDate;
                String MyFilter = bulkApproveFromEmailController.MyFilter;
                Integer piwSize = bulkApproveFromEmailController.piwSize;
                //call the ApproveSelectedTC method
                PSA_BulkApproveFromEmailController.ApproveSelectedTC('Approve',timecard.id,'Approve');                


        }  
  }
}