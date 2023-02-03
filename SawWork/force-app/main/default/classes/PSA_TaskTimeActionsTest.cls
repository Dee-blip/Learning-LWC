/*

Description: Test class to cover the TaskTimeActions class.
Author: Suhas
 */

@isTest(SeeAllData=false)
public class PSA_TaskTimeActionsTest {

    static{
        PSA_TaskTimeActionsTest.createTestData();
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
        Public static pse__Milestone__c milestone1;
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
        //SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        //scSetting.Name = 'BOCC';
        //scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //scSetting.Product_Id__c = 'M-LC-160618';
        
        //insert scSetting;

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
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;

        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        milestone1 = testUtil.newMilestone(true,proj1.Id,100,date.newInstance(2015, 08, 21));            

        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 

        
    }

    @isTest static void test_method_one() 
    {
         pse__Timecard_Header__c timecard1;
        
        test.startTest();

        System.runAs(usr)
        {  

            pse__Project_Task__c projTask = new pse__Project_Task__c();
            projTask.pse__Project__c = proj1.Id;
            projTask.pse__Milestone__c = milestone1.Id;
            projTask.Name = 'test proj task';
            insert projTask;


            //Testing the timecard submission: 
            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, null, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 1;
            timecard1.pse__Submitted__c = true;
            insert timecard1; 

            
            pse__Task_Time__c tasktime = new pse__Task_Time__c();
            tasktime.pse__Timecard__c = timecard1.id;
            tasktime.pse__Project_Task__c = projTask.Id;

            try {
                insert tasktime;
            } catch (Exception e) {
                System.debug('expected exception');
            }

            

            timecard1.pse__Milestone__c = milestone1.Id;
            update timecard1;

        }       
        

        test.stopTest();
    }     
    
}