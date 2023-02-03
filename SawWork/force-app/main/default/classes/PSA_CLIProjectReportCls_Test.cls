/***
    PSA_CLIProjectReportCls_Test
    @author Sandeep Naga
    @Description : 

    @History
    --Developer           --Date             --Change
    Sandeep Naga       17th Jan 2020       Created the class.    

*/

@isTest(SeeAllData=false)
public class PSA_CLIProjectReportCls_Test {
    
    static
    {
        createTestData();
    }
    
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static Contact resource2;
    Public static pse__Practice__c pract;
    Public static Id practId;
    Public static User usr;
    Public static User usr2;
    Public static pse__Schedule__c sched;
    
    
    Public static pse__Proj__c proj1;
    Public static pse__Proj__c proj2;
    Public static pse__Milestone__c milestone1;
    Public static pse__Milestone__c milestone2;
    Public static pse__Assignment__c assign1;
    Public static pse__Assignment__c assign2;
    Public static pse__Project_Methodology__c  product1;
    Public static pse__Project_Methodology__c  product2;
  
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetailCommitted;
    Public static Merge_Contract_Detail__c contDetailOverage;
    Public static Project_Contract__c projCont1;
    Public static Project_Contract__c projCont2;
    Public static Project_Contract_Line_Item__c projContItem1;
    Public static Project_Contract_Line_Item__c projContItem2;
    
    
    public static void createTestData(){

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
        practId = pract.ID;
        
        usr2 = testUtil.newUserSysAdmin(false); 
        usr2.title = 'Manager..Service Line';
        insert usr2;
        
        usr = testUtil.newUserSysAdmin(false); 
        usr.title = 'Manager..Service Line';
        usr.ManagerId = usr2.Id;
        insert usr;
        
     
        List<Contact> resourceList = new List<Contact>();
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        resourceList.add(resource);
        
        resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
        resource2.email = 'PSAProj2@akamai.com';
        resourceList.add(resource2);
        
        insert resourceList;

        List<pse__Proj__c> projList = new List<pse__Proj__c>();
        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.pse__Allow_Timecards_Without_Assignment__c =  true;
        projList.add(proj1);
        
        proj2 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj2.pse__Allow_Timecards_Without_Assignment__c =  true;
        projList.add(proj2);
        
        insert projList;       
        
        List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
        milestone1 = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone1.Billable__c = true;
        milestoneList.add(milestone1);
        
        milestone2 = testUtil.newMilestone(false,proj2.Id,100,date.newInstance(2015, 08, 21));            
        milestone2.Billable__c = true;
        milestoneList.add(milestone2);
        
        insert milestoneList;
        
        List<pse__Project_Methodology__c> productList = new List<pse__Project_Methodology__c>();
        product1 = testUtil.newProjectProduct(false,proj1.Id,'Test Proj Prod');
        productList.add(product1);
        product2 = testUtil.newProjectProduct(false,proj2.Id,'Test Proj Prod');
        productList.add(product2);
        
        insert productList;
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);

        
        //contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contract = testUtil.newContract(true, acct.Id, '123','456',null,firstDayOfMonth, lastDayOfMonth);
 
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        //contDetailCommitted = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailCommitted = testUtil.newContractDetail(false, 'test','test',contract.Id, firstDayOfMonth, lastDayOfMonth);
        contDetailCommitted.Record_Type__c = 'Committed';
        contDetailCommitted.Billing_Duration__c = 'Monthly';
        contDetailCommitted.Product_Id__c = 'M-LC-160618';
        contDetailCommitted.Units_Low__c = 5;
        contDetailCommitted.Product__c = 'Test1';
        contDetailCommitted.Unit_of_Measure__c = 'Hour';
        details.add(contDetailCommitted);
        
        //contDetailOverage = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailOverage = testUtil.newContractDetail(false, 'test','test',contract.Id, firstDayOfMonth, lastDayOfMonth);
        contDetailOverage.Record_Type__c = 'Overage';
        contDetailOverage.Billing_Duration__c = 'Monthly';
        contDetailOverage.Product_Id__c = 'M-LC-160618';
        contDetailOverage.Units_Low__c = 5;
        contDetailOverage.Product__c = 'Test1';
        contDetailOverage.Unit_of_Measure__c = 'Hour';
        details.add(contDetailOverage);

        insert details;

        List<Project_Contract__c> projContList = new List<Project_Contract__c>();
        projCont1 = testUtil.newProjectContract(false, proj1.Id, contract.Id, acct.Id);
        projContList.add(projCont1);
        projCont2 = testUtil.newProjectContract(false, proj2.Id, contract.Id, acct.Id);
        projContList.add(projCont2);
        
        insert projContList;
        
        List<Project_Contract_Line_Item__c> projContItemList = new List<Project_Contract_Line_Item__c>(); 
        projContItem1 = testUtil.newProjectContractLineItem(false, proj1.Id, contract.Id, contDetailCommitted.Id, projCont1.Id);
        projContItemList.add(projContItem1);
        projContItem2 = testUtil.newProjectContractLineItem(false, proj2.Id, contract.Id, contDetailCommitted.Id, projCont2.Id);
        projContItemList.add(projContItem2);
        
        insert projContItemList;
        
        
        //sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        sched = testUtil.newSchedule(true, firstDayOfMonth, lastDayOfMonth);
        
        
        
    }
    public static testMethod void test_automated_overage_from_approved_hours(){
        
        test.startTest();
             
        List<pse__Time_Date__c> timedates;
        pse__Timecard_Header__c timecard1;
        pse__Timecard_Header__c timecard2;
        pse__Timecard_Header__c newtimecard1= new pse__Timecard_Header__c();
        pse__Timecard_Header__c newtimecard2= new pse__Timecard_Header__c();
        List<pse__Timecard_Header__c> timecardList = new List<pse__Timecard_Header__c>();
        List<Id> tdIds = new List<Id>();
        
        System.runAs(usr)
        {   
            List<pse__Assignment__c> assignList = new List<pse__Assignment__c>();
            assign1 = testUtil.newAssignment(false,proj1.Id,resource.Id,sched.Id);
            assign1.pse__Bill_Rate__c = 0;
            assignList.add(assign1);
            
            assign2 = testUtil.newAssignment(false,proj2.Id,resource.Id,sched.Id);
            assign2.pse__Bill_Rate__c = 0;
            assignList.add(assign2);
            
            insert assignList;

            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign1.Id, milestone1.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            timecard1.pse__Status__c = 'Submitted'; 
            timecard1.pse__Monday_Hours__c = 20;
            timecard1.pse__Tuesday_Hours__c = 20;
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Approved__c = false;
            timecardList.add(timecard1);
            
            timecard2 = testUtil.newTimecardHeader(false, resource.Id, proj2.Id, assign2.Id, milestone2.Id, System.today(), System.today().addDays(6));           
            timecard2.pse__Billable__c = true;
            timecard2.pse__Status__c = 'Submitted'; 
            timecard2.pse__Monday_Hours__c = 20;
            timecard2.pse__Tuesday_Hours__c = 20;
            timecard2.pse__Submitted__c = true;
            timecard2.pse__Approved__c = false; 
            timecardList.add(timecard2);
            
            insert timecardList;
            
            timedates = testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1,timecard2});
            insert timedates;
            
            for(pse__Time_Date__c td : timedates){
                tdIds.add(td.Id);
            }
            
        }
        System.runAs(usr2)
        {
            timecardList = new List<pse__Timecard_Header__c>();
 
            newtimecard1.Id = timecard1.Id;
            newtimecard1.pse__Status__c = 'Approved'; 
            newtimecard1.pse__Approved__c = true;
            timecardList.add(newtimecard1);
            
            newtimecard2.Id = timecard2.Id;
            newtimecard2.pse__Status__c = 'Approved'; 
            newtimecard2.pse__Approved__c = true;
            timecardList.add(newtimecard2);   
            
            update timecardList;
                
        }
        System.debug('tdIds:'+tdIds);
        PSA_OverageController.checkOverage(tdIds);


        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);

        List<PS_Approved_Hours__c> approvedHourRecList = new List<PS_Approved_Hours__c>();
        
        PS_Approved_Hours__c approvedHourRec1 = new PS_Approved_Hours__c();
        approvedHourRec1.Approved_Hours__c = 30;
        approvedHourRec1.Billing_Duration__c = 'Monthly';
        approvedHourRec1.Billing_Period_End_Date__c = lastDayOfMonth;
        approvedHourRec1.Billing_Period_Start_Date__c = Date.today();
        approvedHourRec1.CLI_End_Date__c = contDetailOverage.Effective_End_Date__c;
        approvedHourRec1.CLI_Start_Date__c = contDetailOverage.Effective_Start_Date__c;
        approvedHourRec1.Contract_Detail__c = contDetailOverage.Id;
        approvedHourRec1.Original_Contract_ID__c = contDetailOverage.original_Contract_Id__c;
        approvedHourRec1.Account__c = acct.Id;
        approvedHourRec1.Locked__c = false;
        approvedHourRec1.Project__c = proj1.Id;
        approvedHourRec1.Units_Low__c = contDetailOverage.Units_Low__c;
        approvedHourRec1.Overage_Hours__c = 1;   
        
        approvedHourRecList.add(approvedHourRec1);
        
        PS_Approved_Hours__c approvedHourRec2 = new PS_Approved_Hours__c();
        approvedHourRec2.Approved_Hours__c = 30;
        approvedHourRec2.Billing_Duration__c = 'Monthly';
        approvedHourRec2.Billing_Period_End_Date__c = lastDayOfMonth;
        approvedHourRec2.Billing_Period_Start_Date__c = Date.today();
        approvedHourRec2.CLI_End_Date__c = contDetailOverage.Effective_End_Date__c;
        approvedHourRec2.CLI_Start_Date__c = contDetailOverage.Effective_Start_Date__c;
        approvedHourRec2.Contract_Detail__c = contDetailOverage.Id;
        approvedHourRec2.Original_Contract_ID__c = contDetailOverage.original_Contract_Id__c;
        approvedHourRec2.Account__c = acct.Id;
        approvedHourRec2.Locked__c = false;
        approvedHourRec2.Project__c = proj2.Id;
        approvedHourRec2.Units_Low__c = contDetailOverage.Units_Low__c;
        approvedHourRec2.Overage_Hours__c = 1;  
        
        approvedHourRecList.add(approvedHourRec2);

        insert approvedHourRecList;
        
        PSA_CLIProjectReportCls.getfetchResults(Date.today()-60,Date.today()+60 );
        
        test.stopTest();
    }

}