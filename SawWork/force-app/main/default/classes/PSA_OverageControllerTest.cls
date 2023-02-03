@isTest(SeeAllData=false)
public class PSA_OverageControllerTest 
{
    static
    {
        createTestData();
    }
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;

    Public static pse__Project_Methodology__c  product1;
    Public static pse__Proj__c proj1;
    Public static pse__Practice__c pract;

    Public static pse__Grp__c grp;

    Public static Id practId;
    Public static pse__Milestone__c milestone;
    Public static pse__Assignment__c assign;
    Public static User usr;
    Public static User usr2;
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetailCommitted;
    Public static Merge_Contract_Detail__c contDetailOverage;
    Public static Project_Contract__c projCont;
    Public static Project_Contract_Line_Item__c projContItem;
    Public static pse__Schedule__c sched;
    Public static pse__Permission_Control__c pc;
    public static SC_SupportEmail__c scEmailSetup;


    Public static void createTestData()
    {

        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        
        // insert scSetting;
        
        testUtil = new PSA_TestUtility();
        //setup this as it is needed during this transaction
        scEmailSetup = testUtil.newSCEmailSetup(true);
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        
        

        //usr2 = testUtil.newUserSysAdmin(false);
        //usr2.title = 'Manager..Service Line';
        //usr2.Cost_Center__c = 50620.0;
        //insert usr2;

        usr = testUtil.newUserSysAdmin(false); 
        usr.title = 'Manager..Service Line';
        //usr.ManagerId = usr2.id;
        //usr.DelegatedApproverId = usr2.id;
        usr.PS_Out_of_Office__c = true;             
        insert usr;
        
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        insert resource;

        proj1 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj1.pse__Allow_Timecards_Without_Assignment__c =  true;
        insert proj1;
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        

        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
 
        List<Merge_Contract_Detail__c> details = new List<Merge_Contract_Detail__c>();
        contDetailCommitted = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailCommitted.Record_Type__c = 'Committed';
        contDetailCommitted.Billing_Duration__c = 'Monthly';
        contDetailCommitted.Product_Id__c = 'M-LC-160618';
        contDetailCommitted.Units_Low__c = 30;
        contDetailCommitted.Product__c = 'Test1';
        contDetailCommitted.Unit_of_Measure__c = 'Hour';
        //contDetailCommitted.Unit_Price__c = 120;
        details.add(contDetailCommitted);
        
        contDetailOverage = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetailOverage.Record_Type__c = 'Overage';
        contDetailOverage.Billing_Duration__c = 'Monthly';
        contDetailOverage.Product_Id__c = 'M-LC-160618';
        contDetailOverage.Units_Low__c = 30;
        contDetailOverage.Product__c = 'Test1';
        contDetailOverage.Unit_of_Measure__c = 'Hour';
        //contDetailOverage.Unit_Price__c = 120;
        details.add(contDetailOverage);

        insert details;

        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetailCommitted.Id, projCont.Id);
        sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(50));
        product1 = testUtil.newProjectProduct(true,proj1.Id,'Test Proj Prod');
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 


    }
    @isTest static void testAutomatedOverage()
    {
        pse__Timecard_Header__c timecard1;
        test.startTest();  

        //pse__Permission_Control__c pc2 = testUtil.newPermissionControl(true, usr2.Id, reg.Id); 

        List<pse__Time_Date__c> timedates;
        System.runAs(usr)
        {   
            
            assign = testUtil.newAssignment(false,proj1.Id,resource.Id,sched.Id);
            assign.pse__Bill_Rate__c = 0;
            insert assign;

            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            //timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Approved'; 
            timecard1.pse__Monday_Hours__c = 20;
            timecard1.pse__Tuesday_Hours__c = 20;
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Approved__c = true;
            insert timecard1; 
            
            timedates = testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});
            insert timedates;
                        
        }
        //System.runAs(usr2)
        //{
        //    timecard1.pse__Status__c = 'Approved';
        //    timecard1.pse__Approved__c = true;
        //    update timecard1;           

        //}
        
        List<Id> overageTimeDateIds = new List<Id>();
        
        for(pse__Time_Date__c timedate: timedates)
        {
            overageTimeDateIds.add(timedate.Id);
        }

        PSA_OverageController.checkRecursion = true;
        PSA_OverageController.checkRecursionPost = true;
        PSA_OverageController.checkOverage(overageTimeDateIds);    

         
        test.stopTest();
    }

    @isTest static void testFinanceCalendarController()
    {
        test.startTest();  
            
            Set<Date> holidays = new Set<Date>();           
            //holidays.add(financeHoliday.Holiday_Date__c);

            Date firstDate = Date.today().addMonths(1).toStartOfMonth();
            Date secondDate = firstDate.addMonths(1);
            Date firstReminderDate;

            PS_Overage_Schedule__c sched = new PS_Overage_Schedule__c();
            sched.Number_of_Mails_Sent__c  = 0;

            firstReminderDate = PSA_OverageController.addBusinessDays(firstDate, 1,holidays);                        
            sched.Reminder_Mail_Date__c = PSA_OverageController.convertToESTCutOff(firstReminderDate, 12);
             
            firstReminderDate = PSA_OverageController.addBusinessDays(firstDate, 3,holidays);                        
            sched.Lock_Date__c  = PSA_OverageController.convertToESTCutOff(firstReminderDate, 17);

            sched.Send_File_to_CMG__c = false;

            insert sched;           

            Finance_Calendar__c financeHoliday = new Finance_Calendar__c();
            financeHoliday.Holiday_Date__c = Date.today().addMonths(1).toStartOfMonth().addDays(1);
            financeHoliday.Active__c = true;
            financeHoliday.Holiday_Name__C = 'n1';
            financeHoliday.Location__c = 'Bangalore';

            insert financeHoliday;

            
            PSA_OverageController controller = new PSA_OverageController();
            
            String prefix = controller.prefix;
            controller.openNewOverageCreatePage();

            PSA_OverageController.getManualFieldsList();
            PSA_OverageController.getProfilesList();
            PSA_OverageController.sendFinanceReminderMail();
            PSA_OverageController.convertToESTCutOff(Date.today(),12);
            Set<Date> holidays1 = new Set<Date>();
            holidays1.add(Date.today().addDays(1));
            holidays1.add(Date.today().addDays(2));
            PSA_OverageController.addBusinessDays(Date.today(),3,holidays1);
            PSA_OverageController.sendOutOfOfficeMail();
            
            
            PSA_PSOverageHandler handler = new PSA_PSOverageHandler();
            handler.beforeDeleteBeforeUndeleteTrigger();
            handler.afterDeleteAfterUndeleteTrigger();

            PSA_PSApproverHandler handler1 = new PSA_PSApproverHandler();
            handler1.beforeDeleteBeforeUndeleteTrigger();
            handler1.afterDeleteAfterUndeleteTrigger();

            PSA_PSOverageScheduleHandler handler2 = new PSA_PSOverageScheduleHandler();
            handler2.beforeDeleteBeforeUndeleteTrigger();
            handler2.afterDeleteAfterUndeleteTrigger();

            PSA_FinanceCalendarHandler handler3 = new PSA_FinanceCalendarHandler();
            handler3.beforeDeleteBeforeUndeleteTrigger();
            handler3.afterDeleteAfterUndeleteTrigger();


        test.stopTest();
    }
    @isTest static void testApprovedHoursReCalcBatch()
    {
        pse__Timecard_Header__c timecard1;
        test.startTest();  
        Siebel_LOV__c newRec = new Siebel_LOV__c();
        newRec.Display_Value__c = 'Monthly';
        newRec.Description__c = '1';
        newRec.Active__c = 'Y';
        insert newRec;


        PSA_Timecard_Approval__c stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
        stopApproval.Stop_Approval__c = false;
        upsert stopApproval;

        List<pse__Time_Date__c> timedates;
        System.runAs(usr)
        {   
            
            assign = testUtil.newAssignment(false,proj1.Id,resource.Id,sched.Id);
            assign.pse__Bill_Rate__c = 0;
            insert assign;

            timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj1.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));           
            timecard1.pse__Billable__c = true;
            //timecard1.pse__Project_Methodology_Object__c = product1.Id;
             
            timecard1.pse__Status__c = 'Approved'; 
            timecard1.pse__Monday_Hours__c = 20;
            timecard1.pse__Tuesday_Hours__c = 20;
            timecard1.pse__Submitted__c = true;
            timecard1.pse__Approved__c = true;
            insert timecard1; 
            
            timedates = testUtil.createTimeDates(new List<pse__Timecard_Header__c>{timecard1});
            insert timedates;
                        
        }
        //System.runAs(usr2)
        //{
        //    timecard1.pse__Status__c = 'Approved';
        //    timecard1.pse__Approved__c = true;
        //    update timecard1;           

        //}
        
        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);

        PS_Approved_Hours__c approvedHourRec = new PS_Approved_Hours__c();
        approvedHourRec.Approved_Hours__c = 30;
        approvedHourRec.Billing_Duration__c = 'Monthly';
        approvedHourRec.Billing_Period_End_Date__c = lastDayOfMonth;
        approvedHourRec.Billing_Period_Start_Date__c = Date.today();
        approvedHourRec.CLI_End_Date__c = contDetailOverage.Effective_End_Date__c;
        approvedHourRec.CLI_Start_Date__c = contDetailOverage.Effective_Start_Date__c;
        approvedHourRec.Contract_Detail__c = contDetailOverage.Id;
        approvedHourRec.Original_Contract_ID__c = contDetailOverage.original_Contract_Id__c;
        approvedHourRec.Account__c = acct.Id;
        approvedHourRec.Locked__c = false;
        approvedHourRec.Project__c = proj1.Id;
        approvedHourRec.Units_Low__c = contDetailOverage.Units_Low__c;
        approvedHourRec.Overage_Hours__c = 1;                    

        insert approvedHourRec;

        PSA_ApprovedHoursReCalcBatch approvedBatch = new PSA_ApprovedHoursReCalcBatch();
        approvedBatch.query = 'select Billing_Duration__c,Approved_Hours__c, Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Contract_Detail__c, Id,Original_Contract_ID__c, Overage_Hours__c, Project__c, Units_Low__c,CLI_End_Date__c, CLI_Start_Date__c,Contract_Detail__r.Product_id__c,Contract_Detail__r.Units_Low__c, Contract_Detail__r.Unit_of_Measure__c,Overage_Filters__c from PS_Approved_Hours__c';
        Database.ExecuteBatch(approvedBatch);
        
        contDetailCommitted.Effective_End_Date__c = contDetailCommitted.Effective_End_Date__c.addMonths(3);
        contDetailOverage.Effective_End_Date__c = contDetailOverage.Effective_End_Date__c.addMonths(3);
        List<Merge_Contract_Detail__c> updateDetails = new List<Merge_Contract_Detail__c>();
        
        updateDetails.add(contDetailCommitted);
		updateDetails.add(contDetailOverage);
        
        update updateDetails;
         
        test.stopTest();
    }

}