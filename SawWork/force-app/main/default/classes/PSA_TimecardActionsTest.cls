/*

Description: Test class to cover the TimecardActions class.
Author: Jaya
Developer                               Date                Changes
Sharath Prasanna                       29 July 2016            Changed the test class to improve the code coverage
sharath Prasanna                       1 March 2017            Changed the class to cover the  PSA_TimecardApproval_Validation and PSA_setApproverForTimecard classes
Sharath Ravishankar                    2 March 2017            Included the test method for PSA_NotifyPendingApprovalsWeekly and PSA_NotifyPendingApprovalsDaily
Sandeep Naga                           10 April 2020           Included the test methods for PSA_TimecardHoursThreshold_Validation
 */

@isTest(SeeAllData=false)
private class PSA_TimecardActionsTest {

    static{
        PSA_TimecardActionsTest.createTestData();
    } 

        Public static PSA_TestUtility testUtil;
        Public static pse__Region__c reg;
        Public static Account acct;
        Public static Contact resource;
        Public static Contact resourceEmp;
        Public static pse__Project_Methodology__c  product1;
        Public static pse__Proj__c proj1;
        Public static pse__Practice__c pract;
        Public static pse__Practice__c pract1;
        Public static pse__Grp__c grp;
        Public static List<pse__Practice__c> practCorporateList;
        Public static Id practCorporateId;
        Public static Id practId;
        Public static pse__Milestone__c milestone;
        Public static pse__Assignment__c assign;
        Public static User usr;
        Public static User usr2;
        Public static User usrEmp;
        Public static Merge_Contract_Header__c contract;
        Public static Merge_Contract_Detail__c contDetail;
        Public static Project_Contract__c projCont;
        Public static Project_Contract_Line_Item__c projContItem;
        Public static pse__Schedule__c sched;
        Public static pse__Permission_Control__c pc;
        Public static pse__Permission_Control__c pcEmp;
    
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {

        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        
        // insert scSetting;
        
        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        
        insert esSetting;

        
        
        
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        pract1 = testUtil.newPracticeMaster(false);
        pract1.Name = 'Corporate';
        insert pract1;
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        
        usr.ManagerId = usr2.id;
        usr.DelegatedApproverId = usr2.id;
        usr.Country = 'Testcountry';
        
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;

        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        /*projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); */
        
    }
    
    Public static void createAdditionaldata()
    {
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 
    }
    
//static method for creation of data for notify approval test methods
    //Public static void createDataNotifyApprovals()
    //{
    //    usrEmp = testUtil.newUserSysAdmin(false);
    //    usrEmp.ManagerId = usr.Id;
    //    usrEmp.DelegatedApproverId = usr.Id;
    //    insert usrEmp;
    //    practCorporateList = [SELECT Id from pse__Practice__c WHERE Name = 'Corporate' limit 1 ];
    //    if(practCorporateList == null || practCorporateList.size() != 1)
    //    {
    //        return;
    //    }
    //    practCorporateId = practCorporateList[0].Id;
    //    pcEmp = testUtil.newPermissionControl(true, usrEmp.Id, null, practCorporateId,null,null,null,true); 
    //    resourceEmp = testUtil.newResource(false,acct.Id, usrEmp.Id);
    //    resourceEmp.email = 'PSAEmpProj@akamai.com';
    //    resourceEmp.pse__Practice__c = practCorporateId;
    //    resourceEmp.pse__Region__c = reg.Id;
    //    grp = testUtil.newGroupMaster(true);
    //    resourceEmp.pse__Group__c = grp.Id;
    //    insert resourceEmp;
    //}
   
    //Testing the timecard submission, recall and approval: valid cases
    @isTest static void test_method_one() 
    {
         pse__Timecard_Header__c timecard1;
         pse__Timecard_Header__c timecard2;
        
        //changes by sharath: test includes data setup
        test.startTest(); 
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1; 
            
            //Testing timecard recall
            timecard1.pse__Status__c = 'Saved';
            timecard1.pse__Submitted__c = false;
            update timecard1;
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            try
            {
                insert timecard2;                
            }
            catch(Exception e)
            {
                
            }  
 
            //Testing Timecard approval
            timecard1.pse__Status__c = 'Approved';            
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Approved__c = true;            
            update timecard1;
            
        }

        test.stopTest();
    }
    
    //Testing the timecard rejection: valid cases
    @isTest static void test_method_two()
    {
         pse__Timecard_Header__c timecard1;
        test.startTest();  
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1; 
            
            timecard1.pse__Status__c = 'Rejected'; 
            timecard1.pse__Submitted__c = false;
            update timecard1;
        } 
        test.stopTest();
    }

    //Testing the timecard approval: resulting in net negative
    @isTest static void test_method_three()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        test.startTest();   
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1;
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;                 
            }
            catch(Exception e)
            {
                
            }
            timecard2.pse__Status__c = 'Approved';
            timecard2.pse__Approved__c = true;            
            try
            {
                update timecard2;                 
            }
            catch(Exception e)
            {
                
            }
                        
        }
        test.stopTest();
    }

    //Testing the timecard rejection: resulting in net negative    
    @isTest static void test_method_four()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        test.startTest(); 
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1;
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;                 
            }
            catch(Exception e)
            {
                
            }
            timecard1.pse__Status__c = 'Rejected';
            timecard1.pse__Submitted__c = false;
            try
            {
                update timecard1;                 
            }
            catch(Exception e)
            {
                
            }
                        
        }  
        test.stopTest();
    }

    //Testing the timecard recall: resulting in net negative    
    @isTest static void test_method_five()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        
        PSA_Settings__c psaSetting = PSA_Settings__c.getInstance('Validation On Timecard Recall Active');
        if (psaSetting == null)
        {
            psaSetting = new PSA_Settings__c();
            psaSetting.Name = 'Validation On Timecard Recall Active';
            psaSetting.Value__c = 'yes';
            insert psaSetting;
        }
        else
        {
            psaSetting.Value__c = 'yes';
            update psaSetting;
        }
        
        test.startTest();    
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1;
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;                 
            }
            catch(Exception e)
            {
                
            }
            timecard1.pse__Status__c = 'Saved';
            timecard1.pse__Submitted__c = false;
            try
            {
                update timecard1;                 
            }
            catch(Exception e)
            {
                
            }
                        
        } 
        test.stopTest();
    }
    //Test method for PSA_TimecardApproval_Validation    
    @isTest static void test_method_six()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        
        test.startTest();    
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1;
            
            timecard1.pse__Status__c = 'Approved';
            timecard1.pse__Approved__c = true;
            timecard1.PSA_Actual_Approver__c = usr.id;
            try{
                update timecard1; 
            }
            catch(Exception e){
                
            }
             

            //List <id>tcIDs = new List <id>();
            //tcIDs.add(timecard1.id);
            //PSA_TimecardApproval_Validation.rejectTC(tcIDs);    
                        
        } 
        test.stopTest();
    }

    //Test method for PSA_setApproverForTimecard
    @isTest static void test_method_seven()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        
        test.startTest(); 
        createAdditionaldata();
        System.runAs(usr)
        {   
            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1;

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = 1;
            timecard2.pse__Submitted__c = true;
            //timecard2.pse__Approved__c = true;
            insert timecard2;
            
            timecard2.pse__Status__c = 'Approved';
            timecard2.pse__Approved__c = true;
            update timecard2;

            Timecard_Approver__c timecardApprover = new Timecard_Approver__c();
            timecardApprover.Timecard__c = timecard2.id;
            timecardApprover.TIMECARD_ID__c = timecard2.id;
            timecardApprover.Assigned_approver__c = usr.id;
            insert timecardApprover;

            PSA_setApproverForTimecard b = new PSA_setApproverForTimecard();
            Database.executeBatch(b);
        } 
        test.stopTest();
    } 

    //Test method for PSA_TimecardHoursThreshold_Validation :Submission of timecards exceeding Legal Limits
    @isTest static void test_method_PSA_TimecardHoursThreshold_Validation1(){
        
        pse__Timecard_Header__c timecard1 = new pse__Timecard_Header__c();
        test.startTest(); 
        createAdditionaldata();
        System.runAs(usr)
        {
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 24;
            timecard1.pse__Submitted__c = true;   
            try{
                insert timecard1;
            }
            catch(Exception e){
            }
            
        }
        test.stopTest(); 
        
    }
    
    
    //Test method for PSA_TimecardHoursThreshold_Validation : Test Auraenabled method for timecard record page LwC
    @isTest static void test_method_PSA_TimecardHoursThreshold_Validation2(){
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        List<pse__Timecard_Header__c> timecardList;

        test.startTest();
        createAdditionaldata();
        System.runAs(usr)
        {
            
            PSA_Weekly_User_Timecard_Hours__c tempWeeklyUserRecord = new PSA_Weekly_User_Timecard_Hours__c();
            tempWeeklyUserRecord.Resource__c = resource.Id;
            tempWeeklyUserRecord.Weekly_Start_Date__c = System.today();
            tempWeeklyUserRecord.Weekly_End_Date__c = System.today().addDays(6); 
            tempWeeklyUserRecord.Total_Hours__c = 12;
            tempWeeklyUserRecord.Total_Approved_Hours__c = 12;
            tempWeeklyUserRecord.Country__c  = usr.Country;
            tempWeeklyUserRecord.Maximum_Hours_Threshold__c  = 10;
            tempWeeklyUserRecord.Legal_Hours_Threshold__c  = 20;
            insert tempWeeklyUserRecord;
            
            timecardList = new List<pse__Timecard_Header__c>(); 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 4;
            timecard1.pse__Submitted__c = true;
            timecardList.add(timecard1);
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
            
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = 1;
            timecard2.pse__Submitted__c = true;
            timecardList.add(timecard2);
             
            insert timecardList;
            
            
        }
        
        System.runAs(usr2)
        {    
            timecardList = new List<pse__Timecard_Header__c>();       
            
            timecard1.pse__Status__c = 'Approved';
            timecard1.pse__Approved__c = true;
            timecardList.add(timecard1);
            System.debug('@@@ timecard b4:'+ timecard1);
            update timecardList;
            System.debug('@@@ timecard af:'+ timecard1);
            
            
        }
        
        //Call the auraEnabled Method
        String result = PSA_TimecardHoursThreshold_Validation.checktoNotifyTimecardHoursConsumed(timecard2.Id);
        
        test.stopTest();
        
    }
    
    //begin of changes from Sharath Ravishankar
    //Test method for PSA_setApproverForTimecard
    
    //@isTest static void test_method_notifyApprovalsProject()
    //{
    //    createDataNotifyApprovals();
    //    test.startTest();       
    //    runNotifyApprovalsBatch('Project');
    //    test.stopTest();
    //}

    //@isTest static void test_method_notifyApprovalsAccount()
    //{
    //    createDataNotifyApprovals();
    //    test.startTest();       
    //    runNotifyApprovalsBatch('Account');
    //    test.stopTest();
    //}
    //@isTest static void test_method_notifyApprovalsResource()
    //{
    //    createDataNotifyApprovals();
    //    test.startTest();       
    //    runNotifyApprovalsBatch('Resource');
    //    test.stopTest();
    //}
    //@isTest static void test_method_notifyApprovalsAll()
    //{
    //    createDataNotifyApprovals();
    //    test.startTest();       
    //    runNotifyApprovalsBatch('All');
    //    test.stopTest();
    //}
    


    //static void runNotifyApprovalsBatch(String digestGrouping)
    //{
    //    pse__Timecard_Header__c timecard1;
    //    pse__Timecard_Header__c timecard2;

    //    System.runAs(usr)
    //    {   
    //        //Testing the timecard submission: 
    //        timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id,null, milestone.Id, System.today(), System.today().addDays(6));           
    //        timecard1.pse__Billable__c = true;
    //        timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
    //        timecard1.pse__Status__c = 'Submitted'; 
    //        timecard1.pse__Monday_Hours__c = 1;
    //        timecard1.pse__Monday_Notes__c = 'test';
    //        //timecard1.pse__Submitted__c = true;
    //        insert timecard1;

    //        //creating a psa_approval_notification_preference__c record for the manager
    //        PSA_Approval_Notification_Preference__c notPrefVar = new PSA_Approval_Notification_Preference__c();
    //        notPrefVar.Digest_Grouping__c = digestGrouping;
    //        notPrefVar.Notification_Frequency__c = 'Daily';
    //        notPrefVar.User__c = usr2.Id;
    //        insert notPrefVar;

    //        PSA_NotifyPendingApprovalsDaily appDJob = new PSA_NotifyPendingApprovalsDaily();
    //        Database.executeBatch(appDJob);


    //    } 
    //    System.runAs(usrEmp)
    //    {
    //        assign = testUtil.newAssignment(true,proj1.Id,resourceEmp.Id,sched.Id);

    //        timecard2 = testUtil.newTimecardHeader(false, resourceEmp.Id, proj1.Id,assign.Id, milestone.Id, System.today(), System.today().addDays(6));           
    //        timecard2.pse__Billable__c = true;
    //        timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
    //        timecard2.pse__Status__c = 'Submitted'; 
    //        timecard2.pse__Monday_Hours__c = 1;
    //        timecard2.pse__Monday_Notes__c = 'test';
    //        //timecard1.pse__Submitted__c = true;
    //        insert timecard2;

    //        PSA_Approval_Notification_Preference__c notPrefVar = new PSA_Approval_Notification_Preference__c();
    //        notPrefVar.Digest_Grouping__c = digestGrouping;
    //        notPrefVar.Notification_Frequency__c = 'Weekly';
    //        notPrefVar.User__c = usr.Id;
    //        insert notPrefVar;
            

    //        PSA_NotifyPendingApprovalsWeekly appWJob = new PSA_NotifyPendingApprovalsWeekly();
    //        Database.executeBatch(appWJob);

    //    }

    //}
    ////end of changes by Sharath Ravishankar 
    
}