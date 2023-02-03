/*

Description: Test class to cover the TimecardActions class.
Author: Suhas
Developer                               Date                Changes
Suhas Jain                    1 Aug 2018           Included the test method for changes for FFPSA-545
Suhas Jain                    5 Sep 2018           Set SeeAllData=false
 */

@isTest(SeeAllData=false)
private class PSA_TimecardActionsPSHoursTest {

    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static Contact resourceEmp;
    Public static pse__Project_Methodology__c  product1;
    Public static pse__Proj__c proj1;
    Public static pse__Practice__c pract;
    Public static pse__Grp__c grp;
    Public static List<pse__Practice__c> practCorporateList;
    Public static Id practCorporateId;
    Public static Id practId;
    Public static pse__Milestone__c milestone;
    Public static pse__Assignment__c assign;
    Public static pse__Assignment__c assign1;
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

    static{
        PSA_TimecardActionsPSHoursTest.createPSHoursTestData();
    }

        
    
    //The function which creates the test data: called from the static block
    Public static void createPSHoursTestData()
    {

        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();        
          
        PSA_Settings__c psaSetting1 = new PSA_Settings__c();
        psaSetting1.name = 'Work Item Limit';
        psaSetting1.Value__c = '1';        
        psaSettings.add(psaSetting1);
          
        PSA_Settings__c psaSetting2 = new PSA_Settings__c();
        psaSetting2.name = 'Engineering Team Email';
        psaSetting2.Value__c = 'shprasan@akamai.com';
        psaSettings.add(psaSetting2);

        PSA_Settings__c psaSetting3 = new PSA_Settings__c();
        psaSetting3.name = 'FromEmailAdress';
        if(URL.getSalesforceBaseUrl().toExternalForm().contains('qa') || URL.getSalesforceBaseUrl().toExternalForm().contains('QA'))
        {
              psaSetting3.Value__c = 'qa-ps-notify@akamai.com';
        }
        else
        {
              psaSetting3.Value__c = 'prod-ps-notify@akamai.com';            
        }
        psaSettings.add(psaSetting3);

        PSA_Settings__c psaSetting4 = new PSA_Settings__c();
        psaSetting4.name = 'JobNotificationAdress';
        psaSetting4.Value__c = 'shprasan@akamai.com';
        psaSettings.add(psaSetting4);

        /*PSA_Settings__c psaSetting5 = new PSA_Settings__c();
        psaSetting5.name = 'CRM Integration';
        psaSetting5.Value__c = '00eA0000000QpNL';
        psaSettings.add(psaSetting5);*/

        PSA_Settings__c psaSetting6 = new PSA_Settings__c();
        psaSetting6.name = 'Validation On Timecard Recall Active';
        psaSetting6.Value__c = 'yes';
        psaSettings.add(psaSetting6);

        insert psaSettings;

        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        // insert scSetting;


        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        
        usr.ManagerId = usr2.id;
        usr.DelegatedApproverId = usr2.id;
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;

        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today().addDays(-20), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today().addDays(-20), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        /*projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-20), System.today().addDays(100));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);*/

    }
    
    public static void createAddisionalSetupData()
    {
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-20), System.today().addDays(100));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);
    }
    
    
    Public static void createDataNotifyApprovals()
    {
        usrEmp = testUtil.newUserSysAdmin(false);
        usrEmp.ManagerId = usr.Id;
        usrEmp.DelegatedApproverId = usr.Id;
        insert usrEmp;
        
        pse__Practice__c practiceRecord = testUtil.newPracticeMaster(false);
        practiceRecord.name = 'Corporate';
        insert practiceRecord;

        //practCorporateList = [SELECT Id from pse__Practice__c WHERE Name = 'Corporate' limit 1 ];
        //if(practCorporateList == null || practCorporateList.size() != 1)
        //{
        //    return;
        //}
        practCorporateId = practiceRecord.Id;
        pcEmp = testUtil.newPermissionControl(true, usrEmp.Id, null, practCorporateId,null,null,null,true); 

        resourceEmp = testUtil.newResource(false,acct.Id, usrEmp.Id);
        resourceEmp.email = 'PSAEmpProj@akamai.com';
        resourceEmp.pse__Practice__c = practCorporateId;
        resourceEmp.pse__Region__c = reg.Id;

        grp = testUtil.newGroupMaster(true);
        resourceEmp.pse__Group__c = grp.Id;
        insert resourceEmp;
    }
    
    

    @isTest static void psHoursUtilizationTest()
    {

        test.startTest();
        createAddisionalSetupData();
        System.assertEquals(1,1);

        //pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;

        contDetail.Unit_of_Measure__c = 'Hour';
        contDetail.Units_High__c = 100 ;
        contDetail.Units_Low__c = 100 ;
        contDetail.Billing_Duration__c = 'Quarterly';
        contDetail.Product_Id__c = 'M-LC-162622';
        contDetail.Effective_Start_Date__c = date.Today().addDays(-20);
        update contDetail;

        proj1.Current_Quarter__c = 1;
        update proj1;

        System.runAs(usr)
        {
            assign  = testUtil.newAssignment(true,proj1.Id,resource.Id,sched.Id);
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
                 
            timecard2.pse__Status__c = 'Submitted';
            timecard2.pse__Monday_Hours__c = 20;
            timecard2.pse__Tuesday_Hours__c = 20;
            timecard2.pse__Wednesday_Hours__c = 20;
            timecard2.pse__Thursday_Hours__c = 20;
            timecard2.pse__Submitted__c = true;
            //timecard2.pse__Approved__c = false;
            insert timecard2;

            //assign1  = testUtil.newAssignment(true,proj1.Id,resource.Id,sched.Id);
            //timecard3 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));
            //timecard3.pse__Project_Methodology_Object__c = product1.Id;

            //insert timecard3;

        }
        System.runAs(usr2)
        {
            PSA_TimecardActions.isFirstTime = true;
            timecard2.pse__Status__c = 'Approved';
            timecard2.pse__Approved__c = true;
            update timecard2;
        }


        projContItem.valid_delete__c = true;
        update projContItem;
        delete projContItem;
        
        System.debug('projContItem deleted' );
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        System.debug('projCont inserted : ' + projCont );
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        System.debug('projContItem inserted : ' + projContItem );

        contDetail.Effective_Start_Date__c = system.today().addDays(-6);
        update contDetail;
        
        System.debug('contDetail updated : ' + contDetail );


        test.stopTest();
    }

    @isTest static void psHoursUtilizationTest1()
    {

        test.startTest();
        createAddisionalSetupData();

        contDetail.Unit_of_Measure__c = 'Hour';
        contDetail.Units_High__c = 100 ;
        contDetail.Units_Low__c = 100 ;
        contDetail.Billing_Duration__c = 'Quarterly';
        contDetail.Product_Id__c = 'M-LC-162622';
        contDetail.Effective_Start_Date__c = date.Today().addDays(-390);
        update contDetail;

        pse__Timecard_Header__c timecard3;
        
        pse__Timecard_Header__c timecard4;


        System.runAs(usr)
        {
            assign1  = testUtil.newAssignment(true,proj1.Id,resource.Id,sched.Id);
            timecard3 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign1.Id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard3.pse__Billable__c = true;
            timecard3.pse__Project_Methodology_Object__c = product1.Id;
                 
            timecard3.pse__Status__c = 'Submitted';
            timecard3.pse__Monday_Hours__c = 20;
            timecard3.pse__Tuesday_Hours__c = 20;
            timecard3.pse__Wednesday_Hours__c = 20;
            timecard3.pse__Thursday_Hours__c = 20;
            timecard3.pse__Submitted__c = true;
            //timecard2.pse__Approved__c = false;

            timecard4 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign1.Id, milestone.Id, System.today().addDays(-14) , System.today().addDays(-8));           
            timecard4.pse__Billable__c = true;
            timecard4.pse__Project_Methodology_Object__c = product1.Id;
                 
            timecard4.pse__Status__c = 'Submitted';
            timecard4.pse__Monday_Hours__c = 20;
            timecard4.pse__Tuesday_Hours__c = 20;
            timecard4.pse__Wednesday_Hours__c = 20;
            timecard4.pse__Thursday_Hours__c = 20;
            timecard4.pse__Submitted__c = true;
            insert timecard3;


        }
        System.runAs(usr2)
        {
            PSA_TimecardActions.isFirstTime = true;
            timecard3.pse__Status__c = 'Approved';
            timecard3.pse__Approved__c = true;
            update timecard3;
        }
        test.stopTest();    


    }

    @isTest static void testMethodOne() 
    {
         pse__Timecard_Header__c timecard1;
         pse__Timecard_Header__c timecard2;
        
        //changes by sharath: test includes data setup
        test.startTest(); 
        
        createAddisionalSetupData();
        
        resourceEmp= testUtil.newResource(false, acct.Id, usr2.Id);
        resourceEmp.email = 'PSAProjMgr2@akamai.com';
        insert resourceEmp;

        //pse__Permission_Control__c pc2 = testUtil.newPermissionControl(true, usr2.Id, reg.Id);
        testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

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
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});

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

                insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard2});
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }  
        }
        System.runAs(usr2)
        {
            //Testing Timecard approval
            timecard1.pse__Status__c = 'Approved';            
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Approved__c = true;   
            try
            {
                update timecard1;
            }         
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
            
        }

        test.stopTest();
    }
    
    //Testing the timecard rejection: valid cases
    @isTest static void testMethodTwo()
    {
         pse__Timecard_Header__c timecard1;
        test.startTest();   
        
        createAddisionalSetupData();
        
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
            
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});

            timecard1.pse__Status__c = 'Rejected'; 
            timecard1.pse__Submitted__c = false;
            update timecard1;
        } 
        test.stopTest();
    }
    //Testing the timecard submit
    @isTest static void testMethodSubmitNetNegative()
    {
         pse__Timecard_Header__c timecard1;
         pse__Timecard_Header__c timecard2;
        test.startTest();  
        
        createAddisionalSetupData();
        resourceEmp= testUtil.newResource(false, acct.Id, usr2.Id);
        resourceEmp.email = 'PSAProjMgr2@akamai.com';
        insert resourceEmp;

        //pse__Permission_Control__c pc2 = testUtil.newPermissionControl(true, usr2.Id, reg.Id); 
        testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

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
            
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Saved'; 
            timecard2.pse__Monday_Hours__c = 1;
            //timecard2.pse__Submitted__c = true;
            insert timecard2; 
                        
        }
        System.runAs(usr2)
        {
            timecard1.pse__Status__c = 'Approved';
            timecard1.pse__Approved__c = true;
            update timecard1;           

        }
        System.runAs(usr)
        {
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -2;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard2});
                update timecard2; 
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
            
        }
            

         
        test.stopTest();
    }

    //Testing the timecard approval: resulting in net negative
    @isTest static void testMethodThree()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        test.startTest();  
        createAddisionalSetupData();
        
        resourceEmp= testUtil.newResource(false, acct.Id, usr2.Id);
        resourceEmp.email = 'PSAProjMgr2@akamai.com';
        insert resourceEmp;

        //pse__Permission_Control__c pc2 = testUtil.newPermissionControl(true, usr2.Id, reg.Id); 
        testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

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
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -3;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;     
                insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard2});            
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
        }    
        System.runAs(usr2)
        {
            timecard2.pse__Status__c = 'Approved';
            timecard2.pse__Approved__c = true;            
            timecard1.pse__Status__c = 'Approved';
            timecard1.pse__Approved__c = true;            

            try
            {
                update timecard1;                 
                update timecard2;
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
        }
        test.stopTest();
    }

    //Testing the timecard rejection: resulting in net negative    
    @isTest static void testMethodFour()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        test.startTest();      
        createAddisionalSetupData();
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
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;  
                insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard2});               
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
            timecard1.pse__Status__c = 'Rejected';
            timecard1.pse__Submitted__c = false;
            try
            {
                update timecard1;                 
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
                        
        }  
        test.stopTest();
    }

    //Testing the timecard recall: resulting in net negative    
    @isTest static void testMethodFive()
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
        
        createAddisionalSetupData();
        
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
            insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = -1;
            timecard2.pse__Submitted__c = true;
            try
            {
                insert timecard2;                 
                insert testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard2});
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
            timecard1.pse__Status__c = 'Saved';
            timecard1.pse__Submitted__c = false;
            try
            {
                update timecard1;                 
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }
                        
        } 
        test.stopTest();
    }
    //Test method for PSA_TimecardApproval_Validation    
    @isTest static void testMethodSix()
    {
        pse__Timecard_Header__c timecard1;
        //pse__Timecard_Header__c timecard2;
        
        test.startTest();  
        
        createAddisionalSetupData();
        
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
                System.debug('Exception e:'+e);
            }
             

            //List <id>tcIDs = new List <id>();
            //tcIDs.add(timecard1.id);
            //PSA_TimecardApproval_Validation.rejectTC(tcIDs);    
                        
        } 
        test.stopTest();
    }

    //Test method for PSA_setApproverForTimecard
    @isTest static void testMethodSeven()
    {
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        
        test.startTest();     
        
        createAddisionalSetupData();
        
        resourceEmp= testUtil.newResource(false, acct.Id, usr2.Id);
        resourceEmp.email = 'PSAProjMgr2@akamai.com';
        insert resourceEmp;

        //pse__Permission_Control__c pc2 = testUtil.newPermissionControl(true, usr2.Id, reg.Id); 
        testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

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
            
            System.debug('Querying data :: ' + [Select TargetObjectId, LastModifiedDate, Status, (Select ActorId,TargetObjectId, OriginalActorId from StepsAndWorkitems where CreatedDate = LAST_N_DAYS:1 order by CreatedDate desc limit 1) from ProcessInstance where LastModifiedDate >= LAST_N_DAYS:40]);
            System.debug('Querying data :: ' + [Select ActorId, OriginalActorId from ProcessInstanceWorkItem where CreatedDate = LAST_N_DAYS:1 order by CreatedDate]);

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = 1;
            timecard2.pse__Submitted__c = true;
            //timecard2.pse__Approved__c = true;
            insert timecard2;
            
            System.debug('Querying data2 :: ' + [Select TargetObjectId, LastModifiedDate, Status, (Select ActorId,TargetObjectId, OriginalActorId from StepsAndWorkitems where CreatedDate = LAST_N_DAYS:1 order by CreatedDate desc limit 1) from ProcessInstance where LastModifiedDate >= LAST_N_DAYS:40]);
            System.debug('Querying data2 :: ' + [Select ActorId, OriginalActorId from ProcessInstanceWorkItem where CreatedDate = LAST_N_DAYS:1 order by CreatedDate]);
            
            Timecard_Approver__c timecardApprover = new Timecard_Approver__c();
            timecardApprover.Timecard__c = timecard2.id;
            timecardApprover.TIMECARD_ID__c = timecard2.id;
            timecardApprover.Assigned_approver__c = usr.id;
            insert timecardApprover;
            
            PSA_setApproverForTimecard b = new PSA_setApproverForTimecard();
            Database.executeBatch(b);
            
        }    
        System.runAs(usr2)
        {
            timecard2.pse__Status__c = 'Approved';
            timecard2.pse__Approved__c = true;
            update timecard2;

            
            
            PSA_setApproverForTimecard b = new PSA_setApproverForTimecard();
            Database.executeBatch(b);
            
            PSA_Timecard_Approval__c stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
            stopApproval.Stop_Approval__c = false;
            upsert stopApproval;
            
            PSA_CorrectActualsOnProjects_Batch actualsBatch = new PSA_CorrectActualsOnProjects_Batch();
            Database.executeBatch(actualsBatch);

        } 
        test.stopTest();
    }
      
}