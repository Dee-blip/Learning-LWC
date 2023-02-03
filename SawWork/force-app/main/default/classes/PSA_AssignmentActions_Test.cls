/***
    PSA_AssignmentActions_Test
    --Developer           --Date            --Change
    Sharath               6 Sep 2018    refactored the class  
    Sujay                 7 March 19    Added the BoccSetup Custom Settings
*/
@isTest(SeeAllData=false)
public with sharing class PSA_AssignmentActions_Test {

        public static PSA_TestUtility testUtil;
        public static pse__Region__c reg;
        public static Account acct;
        public static User usr;
        public static pse__Work_Calendar__c cal;
        public static Contact resource;
        public static Opportunity opp;
        public static List<OpportunityLineItem> lineItems;
        public static pse__Practice__c pract;
        public static Id practId ;
        public static pse__Proj__c proj;
        public static Merge_Contract_Header__c contract;
        public static Merge_Contract_Detail__c contDetail;
        public static pse__Milestone__c milestone;
        public static  Project_Contract__c projCont;
        public static Project_Contract_Line_Item__c projContItem;

        public static pse__Schedule__c sched;
        
        public static pse__Assignment__c assign;
        public static pse__Permission_Control__c pc;
        //public static SC_BOCC_Setup__c BoccSetup;

    static
    {
        // BoccSetup = new SC_BOCC_Setup__c();
        // BoccSetup.Name          = 'BOCC';
        // BoccSetup.Product_Id__c = 'M-LC-160620';
        // BoccSetup.Entitlement_Process_Id_Proactive__c  = '5520f000000fxY0AAI';
        // BoccSetup.Entitlement_Process_Id_Reactive__c  = '5520f000000fxY5AAI';
        // insert BoccSetup;
        createData(); 
    }    
    public static void createData()
    {
            testUtil = new PSA_TestUtility();
            reg = testUtil.newRegionMaster(true);
            acct = testUtil.newAccount(true);  
            usr = testUtil.newUserSysAdmin(true);        
            cal = testUtil.newWorkCalender(true);
            resource = testUtil.newResource(true, acct.Id, usr.Id, reg.Id, cal.Id);
            pract = testUtil.newPracticeMaster(true);
            practId = pract.ID;
            proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);    
            contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
            contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
            
            projCont = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
            projContItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projCont.Id);
    
            sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
            
            pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);

    }    

    public static testMethod void test() 
    {
            test.StartTest();
            pse__Timecard_Header__c timecard1;
                System.runAs(usr) {
                    assign = testUtil.newAssignment(TRUE, proj.Id, resource.Id, sched.Id);
                    //changes for 19.1.2
                    milestone = testUtil.newMilestone(false,proj.Id,100,date.newInstance(2015, 08, 21));            
                    milestone.Billable__c = true;
                    insert milestone;

                    timecard1 = testUtil.newTimecardHeader(false, resource.Id, proj.Id, assign.id, milestone.Id, System.today(), System.today().addDays(6));
                    timecard1.pse__Status__c = 'Saved';
                    insert timecard1;

                    assign.pse__Closed_for_Time_Entry__c = TRUE ;
                    update assign;
                    //End of changes for 19.1.2
                }   
                assign = [select Id, Project_Contract_Line_Item__c from pse__Assignment__c where id = :assign.Id limit 1];
                
                System.assert(assign.Project_Contract_Line_Item__c != null);
            test.Stoptest();    
    }           
}