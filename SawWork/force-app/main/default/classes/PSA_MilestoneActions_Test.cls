@isTest(SeeAllData=false)
/***
    PSA_MilestoneActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test the PSA_MilestoneActions class which has methods 
                   that are called by PSA_Milestone_Trigger.  This is to test the functionality
                   that if a Milestone has been added from a Template, or has timecards related to it
                   it cannot be deleted.
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
*/
private class PSA_MilestoneActions_Test {

    public static testMethod void testDeleteSuccessNotFromTemplateHasNoTimecards() {
        setupData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.StartTest();
        pse__Proj__c proj = [select Id from pse__Proj__c order by createddate desc limit 1];
        pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,System.today());
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        
        try {
            delete milestone;
        } catch (Exception e) {
            excCaught = true;
        }   
        Test.StopTest();
        Integer aftCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        System.assert(aftCount == befCount - 1);
        System.assert(!excCaught);
    }

    public static testMethod void testDeleteFailFromTemplate() {
        setupData();
        Test.StartTest();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Proj__c proj = [select Id from pse__Proj__c order by createddate desc limit 1];
        pse__Milestone__c milestone = [select Id, From_Template__c from pse__Milestone__c where pse__Project__c = :proj.Id limit 1];
        System.debug('milestone='+milestone);
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        
        try {
            delete milestone;
        } catch (Exception e) {
            excCaught = true;
        }   
        Test.StopTest();
        Integer aftCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        System.assert(aftCount == befCount);
        System.assert(excCaught);
    }

    public static testMethod void testDeleteFailHasTimecards() {
        setupData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.StartTest();
        pse__Proj__c proj = [select Id, pse__Allow_Timecards_Without_Assignment__c from pse__Proj__c order by createddate desc limit 1];
        proj.pse__Allow_Timecards_Without_Assignment__c = true;
        proj.pse__Project_Type__c = 'Internal';
        proj.pse__Is_Billable__c = false;
        update proj;  
        Boolean excCaught1;  
        pse__Milestone__c milestone = [select Id, From_Template__c from pse__Milestone__c where pse__Project__c = :proj.Id limit 1];
        Contact resource = [select Id from Contact order by createddate desc limit 1];
        User usr = [select Id from User where Profile.Name = 'System Administrator' order by createddate desc limit 1];
        System.runAs(usr)
         {         
            pse__Timecard_Header__c tch = testUtil.newTimecardHeader(false, resource.Id, proj.Id, null, milestone.Id, System.today(), System.today().addDays(6));   
            tch.pse__Billable__c = false;
            try{
            insert tch;
            }
            catch(Exception e)
            {
                excCaught1 = true;
            }
            
           }   
        
        System.debug('milestone='+milestone);
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        
        try {
            delete milestone;
        } catch (Exception e) {
            excCaught = true;
        }   
        Test.StopTest();
        Integer aftCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        //System.assert(aftCount == befCount);
        //System.assert(excCaught);
    }
    
    public static testMethod void testUpdateBillableFailFromTemplate() {
        setupData();
        Test.StartTest();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Proj__c proj = [select Id from pse__Proj__c order by createddate desc limit 1];
        pse__Milestone__c milestone = [select Id, Billable__c, Milestone_Type_List__c, From_Template__c from pse__Milestone__c where pse__Project__c = :proj.Id limit 1];
        System.debug('milestone='+milestone);
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        
        try {
            milestone.Billable__c = false;
            update milestone;
        } catch (Exception e) {
            excCaught = true;
        }   
        Test.StopTest();
        Integer aftCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        System.assert(aftCount == befCount);
        System.assert(excCaught);
    }
    
    public static testMethod void testUpdateMilestoneTypeFailFromTemplate() {
        setupData();
        Test.StartTest();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Proj__c proj = [select Id from pse__Proj__c order by createddate desc limit 1];
        pse__Milestone__c milestone = [select Id, Billable__c, Milestone_Type_List__c, From_Template__c from pse__Milestone__c where pse__Project__c = :proj.Id limit 1];
        System.debug('milestone='+milestone);
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        
        try {
            milestone.Milestone_Type_List__c = 'Joe';
            update milestone;
        } catch (Exception e) {
            excCaught = true;
        }   
        Test.StopTest();
        Integer aftCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        System.assert(aftCount == befCount);
        System.assert(excCaught);
    }
    public static testMethod void testUpdateMilestoneTypeFailFromTemplate1() {
        setupData();
        Test.StartTest();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Contact resource = [select Id from Contact order by createddate desc limit 1];
		pse__Schedule__c sched = testUtil.newSchedule(true, System.today().addDays(-10), System.today().addDays(15));
        pse__Proj__c proj = [select Id from pse__Proj__c order by createddate desc limit 1];
        pse__Milestone__c milestone = [select Id, Billable__c, Milestone_Type_List__c, From_Template__c from pse__Milestone__c where pse__Project__c = :proj.Id limit 1];
        System.debug('milestone='+milestone);
        Integer befCount = [select count() from pse__Milestone__c where pse__Project__c = :proj.Id];
        boolean excCaught = false;
        User usr = [select Id from User where Profile.Name = 'System Administrator' order by createddate desc limit 1];
        try{
            System.runAs(usr)
             {   
                 pse__Project_Methodology__c  product = testUtil.newProjectProduct(true,proj.Id,'Test Proj Prod');
                 pse__Assignment__c assign = testUtil.newAssignment(true, proj.Id, resource.Id, sched.Id);
                pse__Timecard_Header__c tch = testUtil.newTimecardHeader(false, resource.Id, proj.Id, null, milestone.Id, System.today(), System.today().addDays(6));   
                tch.pse__Billable__c = false;
                tch.pse__Status__c = 'Saved';
                tch.pse__Assignment__c = assign.Id;
                tch.pse__Project_Methodology_Object__c = product.Id;
                insert tch;
                
                
               }   
        
        
                milestone.pse__Closed_for_Time_Entry__c = true;
                update milestone;
        } Catch(exception e ){}
        
        
        Test.StopTest();
        
    }
    /* create everything necessary to create a project from a template project */
    public static void setupData() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Region__c reg = testUtil.newRegionMaster(true);
        Account acct = testUtil.newAccount(true);  
        User usr = testUtil.newUserSysAdmin(true);   
        pse__Permission_Control__c pcontrol = testUtil.newPermissionControl(true,usr.Id,reg.Id);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        //Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        //List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 1);
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        pse__Proj__c templateProj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);   
        templateProj.pse__Is_Template__c = true;
        insert templateProj;       
        pse__Milestone__c milestone = testUtil.newMilestone(true,templateProj.Id,100,System.today());
        
        System.runAs(usr) {         
            PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
            ApexPages.currentPage().getParameters().put('acctId',acct.Id);
            //ApexPages.currentPage().getParameters().put('oppId',opp.Id);  
            myCont.setup();
            myCont.selectProject();
            myCont.templateHolderList[0].selected = true;
            myCont.selectProject();
            myCont.newProject.Name = 'test saving new from templ';
            myCont.newProject.pse__Region__c = reg.Id;
            myCont.newProject.pse__Practice__c = practId;
            myCont.newProject.pse__Is_Billable__c  = true; 
            myCont.newProject.pse__Stage__c = 'In Progress';
            myCont.newProject.pse__Is_Active__c = true;
            myCont.newProject.pse__Project_Type__c = 'Customer Project';  
            myCont.newProject.pse__Billing_Type__c = 'One-Time: Fixed Price';
            myCont.newProject.pse__Expense_Budget__c = 1000;
            myCont.newProject.pse__Start_Date__c = Date.today();
            myCont.newProject.pse__End_Date__c = Date.today().addDays(1);
            myCont.newProject.Contract_Closed__c = 'No';
            myCont.newProject.pse__Project_Manager__c = resource.Id;
            myCont.newProject.pse__Account__c = acct.Id;
            myCont.newBudget.getBudget().pse__Effective_Date__c = System.today().addDays(1);
            myCont.newBudget.getBudget().pse__Invoice_Date__c =  System.today().addDays(1);
            myCont.saveProject();
        }
    }
}