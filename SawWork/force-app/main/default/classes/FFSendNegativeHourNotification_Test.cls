/*

Description: Test class to cover sending email notifications on a daily basis for negative hour Timecards.
Author: Jaya
Created Date: 9/10/2015
Developer                               Date                Changes
Sharath                         12 July 2016            Changed the test data
Vandhana                        5 August 2016           Setting SeeAlldata to true
 */

@isTest(SeeAllData=false)
private class FFSendNegativeHourNotification_Test 
{   
     //changes by shprasan: Adding the static block to create custom setting
    /*
    static
    {
        utilTestClass.createCustomSettings();  

        //Start of changes by Sharath for the FF Upgrade v15
        PSA_Settings__c psaSetting = new PSA_Settings__c();
        psaSetting.Name = 'Validation On Timecard Recall Active';
        psaSetting.Value__c = 'yes';
        insert psaSetting;
        //End of changes by Sharath
    } */
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static pse__Project_Methodology__c  product1;
    Public static pse__Proj__c proj1;
    Public static pse__Practice__c pract;
    Public static pse__Practice__c pract1;
    Public static pse__Grp__c grp;
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

    static{
        createTestData();
    } 
    
    Public static void createTestData()    
    {
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
        
        //changes by sharath: Instead of two resources, the resource creating the project will submit timecards. Creating another user to become the project manager of the first user. 
        
        usr = testUtil.newUserSysAdmin(false);         
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.Managerid = usr2.id;
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
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');

        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);  

    }
    @isTest static void test_method_one() 
    {
        pse__Timecard_Header__c timecard;
        pse__Timecard_Header__c timecard2;
     
        test.startTest();
        System.runAs(usr)
        {                  
            List<pse__Timecard_Header__c> timecards = new List<pse__Timecard_Header__c>();
            timecard = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard.pse__Billable__c = true;
            timecard.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard.pse__Status__c = 'Submitted'; 
            timecard.pse__Monday_Hours__c = 1;
            timecards.add(timecard);
            //insert timecard;  

            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard2.pse__Status__c = 'Submitted'; 
            //Changes by sharath: changed the hours to -1
            timecard2.pse__Monday_Hours__c = -1;
            try
            {
                timecards.add(timecard2);
                insert timecards;
                insert testUtil.createTimeDates(timecards);
            }
            catch (Exception e)
            {
                
            }
        }

        //commenting out the query 
        //String query = 'Select Id, pse__Date__c, Product_Id__c, Contract_Id__c, pse__Hours__c, pse__Timecard__c, pse__Timecard__r.Name, pse__Timecard__r.pse__Resource__r.Name, pse__Timecard__r.pse__Resource__r.Email, pse__Timecard__r.pse__Approver__r.Name, pse__Timecard__r.pse__Approver__r.Email, pse__Timecard__r.pse__Project__r.pse__Account__c, pse__Timecard__r.pse__Project__r.pse__Account__r.Name, Negative_Notification_Sent__c, Project_Id__c, pse__Timecard__r.pse__Project__r.Owner.Email from pse__Time_Date__c where pse__Hours__c < 0 and Negative_Notification_Sent__c = false';

        FFSendNegativeHourNotification negativeHourNotification = new FFSendNegativeHourNotification();
        //negativeHourNotification.query = query;
        Database.executeBatch(negativeHourNotification);
        test.stopTest();
    }
}