/***
    PSA_TimecardApproval_Validation_Test
    @Description : This Class tests the PSA_TimecardApproval_Validation.
    @History
    --Developer           --Date            --Change
    Sharath               26 Sep 2018    Created the class
*/
@isTest(seeAlldata=false)
public class PSA_TimecardApproval_Validation_Test
{

    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static Contact resource2;
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
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetail;
    Public static Project_Contract__c projCont;
    Public static Project_Contract_Line_Item__c projContItem;
    Public static pse__Schedule__c sched;
    Public static pse__Permission_Control__c pc;
    Public static Investment_Workbox__c workRequest;

    static{
        createTestData();
    } 


    
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
        
        List<contact> contacts = new List<contact>();

        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        contacts.add(resource);

        resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
        resource2.email = 'PSAProjMgr4@akamai.com';
        contacts.add(resource2);


        insert contacts;


        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.Project_Sub_Type__c = 'Investment Work';
        proj1.pse__Project_Type__c = 'Internal';
        proj1.pse__Is_Billable__c = false;
        insert proj1;
        
        milestone = testUtil.newMilestone(false,proj1.Id,100,System.today().adddays(50));            
        milestone.Billable__c = false;
        milestone.start_date__c = System.today();
        milestone.pse__target_Date__c = System.today().adddays(50);
        milestone.RecordTypeId = Schema.SObjectType.pse__Milestone__c.getRecordTypeInfosByName().get('Investment Work').getRecordTypeId();
        milestone.pse__Planned_Hours__c = 20;
        insert milestone;
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 
        testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

        workRequest = new Investment_Workbox__c();
        workRequest.Account__c = acct.id; 
        workRequest.Time_To_Action__c = '<= 6 Hours'; 
        workRequest.Work_Type__c = 'Maintenance/Optimization'; 
        workRequest.LOE_Hours__c = 16;  
        workRequest.LOE_Minutes__c = 0;
        workRequest.Products__c  = 'Dynamic Site Accelerator,Kona Site Defender,Fast DNS';
        workRequest.Requestor__c = usr2.Id;
        workRequest.Justification__c = 'Customer Satisfaction/Retainment';
        workRequest.isProductSelected__c = true;
        workRequest.Validation_override__c = true;
        workRequest.Legacy_Data__c = 'Workbox';

    }

    @isTest static void testMethodOne() 
    {
        pse__Timecard_Header__c timecard1;
        //pse__Timecard_Header__c timecard2;
        
        //changes by sharath: test includes data setup
        test.startTest(); 

        System.runAs(usr) 
        {

            insert workRequest;

            milestone.Investment_Work__c = workRequest.Id;
            update milestone;

        }     
        System.runAs(usr2)
        {   

            assign = testUtil.newAssignment(false,proj1.Id,resource2.Id,sched.Id);
            assign.pse__Bill_Rate__c = 0;
            insert assign;

            timecard1 = testUtil.newTimecardHeader(false, resource2.Id, proj1.Id, assign.Id, milestone.Id, System.today().addDays(10), System.today().addDays(16));           
            timecard1.pse__Billable__c = false;
            timecard1.pse__Project_Methodology_Object__c = product1.Id;
            timecard1.pse__Status__c = 'Saved'; 
            timecard1.pse__Monday_Hours__c = 10;
            
            try
            {
                insert timecard1;
                timecard1.pse__Status__c = 'Submitted'; 
                timecard1.pse__Submitted__c = true;
                update timecard1;
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }  
             
        }

        test.stopTest();
    }
    @isTest static void testMethodTwo()
    {
        //pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        
        //changes by sharath: test includes data setup
        test.startTest(); 

        System.runAs(usr) 
        {

            insert workRequest;

            milestone.Investment_Work__c = workRequest.Id;
            update milestone;

        }     
        System.runAs(usr2)
        {   

            List<pse__Timecard_Header__c> timecards = new List<pse__Timecard_Header__c>();
            assign = testUtil.newAssignment(false,proj1.Id,resource2.Id,sched.Id);
            assign.pse__Bill_Rate__c = 0;
            insert assign;

            timecard2 = testUtil.newTimecardHeader(false, resource2.Id, proj1.Id, assign.Id, milestone.Id, System.today().addDays(10), System.today().addDays(16));           
            timecard2.pse__Billable__c = false;
            timecard2.pse__Project_Methodology_Object__c = product1.Id;
            timecard2.pse__Status__c = 'Saved'; 
            timecard2.pse__Monday_Hours__c = 21;

            timecards.add(timecard2); 
            try
            {
                insert timecard2;
                timecard2.pse__Status__c = 'Submitted'; 
                timecard2.pse__Submitted__c = true;

                update timecard2;             
            }
            catch(Exception e)
            {
                System.debug('Exception e:'+e);
            }  
             
        }

        test.stopTest();

    } 
}