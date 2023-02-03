/*
       This class implements the unit tests for ActivityMassUpdateController 
       Use cases that are tested:
       1. Change the owner and Status of Tasks. More than one task has created for an object.
       2. Change the owner and Status for Many Tasks. 
*/

@isTest(seeAllData=false)
    private class ActivityMassUpdateControllerTestClass{

        //static User
        static User dmlUser = utilTestClass.getTestRunUser();

        static String oldStatus='Not Started', newStatus='Completed';
        static List<String> tskTypes=new List<String>{'SA','Legal','Deal Desk','China CDN','PS'};
        static List<String> tskSubject=new List<String>{'Call','Referral','Other','Send Letter','Send Quote'};

        // Setup method to create test data.
        @testSetup
        static void setupMethod()
        {
            System.runAs(dmlUser) {
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
                Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            }
        }

        static testmethod void activityUpdateTest()
        {
            System.runAs(dmlUser)
            {
                //Creating testuser 
                User oldOwner=utilTestClass.CreateUser('testold','CMG','CMG');
                //Creating testuser for new owner
                User newOwner=utilTestClass.CreateUser('testnew','CMG','CMG');
                insert (new User[] {oldOwner, newOwner});


                String oldStatus='Not Started', newStatus='Completed';

                //CR 2770464 - rsharma: Adding start and stop test so as to refresh governor limit.
                //Change Owner for tasks and check the new owner and Test for few tasks 
                String tsList=getOrderAppTasks(oldOwner);
                testChangeOwner(tsList, newOwner);
                Test.startTest();

                //Change Status for tasks and check the new status and Test for few tasks.
                testChangeStatus(tsList);

                //Change Status for tasks and check the new status and Test for lot of tasks
                tsList=getMoreTasks(oldOwner);
                testChangeOwner(tsList, newOwner);

                //Change Status for tasks and check the new status and Test for lot of tasks
                testChangeStatus(tsList);
                Test.stopTest();
            }

        }

        //Create tasks for case of one object has more than 1 task.
        public static String getOrderAppTasks(User oldOwner)
        {
            List<Task> allTasks=new List<Task>();
            String tskList='';
            Id akRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
            Id oaRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Order Approval Activity').getRecordTypeId();

            //Creating an account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = oldOwner.Id;
            acc.website='www.massupdate.com';
            System.runAs(oldOwner)
            {
                insert acc;
            }

            // Create Oppty
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
            opp.AccountId = acc.Id;
            opp.Contract_Effective_End_Date__c = Datetime.now().addMonths(2).date();
            opp.CloseDate = Datetime.now().addMonths(1).date();
            opp.Opportunity_Type__c = 'Auto Renewal';
            opp.AKAM_Modified_Date__c = Datetime.now().addMonths(-2);
            opp.Deal_Type__c='Direct';
            System.runAs(oldOwner)
            {
                insert opp;
            }


            // Create Order Approval
            Order_Approval__c oa = new Order_Approval__c();
            oa.Associated_Opportunity__c = opp.Id;
            oa.Approvals_Required__c = 'Deal Desk; Legal';
            oa.Type__c = 'ADS';
            System.runAs(oldOwner)
            {
                insert oa;
            }
            for(String ttype:tskTypes)
            {
                Task t = utilTestClass.CreateTask(oldOwner.Id,tskSubject[0],oldStatus,ttype,oa.Id);
                t.Task_Validation_Override__c = true;
                allTasks.add(t);
            }

            System.runAs(oldOwner)
            {
                insert allTasks;
            }


            for(Task eachTask:allTasks)
                tskList+=','+eachTask.Id;

            return tskList;
        }

        //Creating bulk of tasks and submitting to 
        public static String getMoreTasks(User oldOwner)
        {
            List<Task> allTasks=new List<Task>();
            String tskList='';

            //Creating 200 tasks
            for(Integer i=0;i<200;i++)
            {
                Integer rem=math.mod(i,3);
                allTasks.add(utilTestClass.CreateTask(oldOwner.Id,tskSubject[rem],oldStatus,tskTypes[rem],null));
            }

            System.runAs(oldOwner)
            {
                insert allTasks;
            }

            for(Task eachTask:allTasks)
                tskList+=','+eachTask.Id;

            return tskList;
        }

        public static void testChangeOwner(String tsList, User newOwner){

            ActivityMassUpdateController actObj=new ActivityMassUpdateController();
            Boolean updateOwnerFlag=false;

            //Object of ActivityMassUpdateController

            actObj.setCheckEmail('true');
            actObj.taskObj.OwnerId=newOwner.Id;
            String mailFlag=actObj.getCheckEmail();
            System.currentPagereference().getParameters().put('actList',tsList);
            actObj.updateOwner();
            //Checking the new Owner updated or not
            updateOwnerFlag=checkUpdatedOwner(tsList, newOwner);

            System.assertNotEquals(updateOwnerFlag,false);    
        }

        public static void testChangeStatus(String tsList){
            //Change Status Tese cases for new status
            Boolean updateStatusFlag=false;
            ActivityMassUpdateController actObj=new ActivityMassUpdateController();
            System.currentPagereference().getParameters().put('actList',tsList);
            actObj.taskObj.Status=newStatus;
            actObj.updateStatus();

            //Checking the new Status updated or not
            updateStatusFlag=checkUpdatedStatus(tsList);

            System.assertNotEquals(updateStatusFlag,false);
        }

        // Checks the updated owner with new owner
        public static Boolean checkUpdatedOwner(String allList, User newOwner)
        {
            Boolean updateFlag=true; 
            List<Id> actvList=allList.split(',',-1);
            List<Task> taskarray=[SELECT Id,OwnerId from Task WHERE Id IN :actvList];

            for(Task task:taskarray)
                System.assertEquals(task.OwnerId,newOwner.Id);

            return updateFlag;
        }

        //Checks the updated status with new status
        public static Boolean checkUpdatedStatus(String taskList)
        {
            Boolean updateFlag=true;
            List<Id> actvList=taskList.split(',',-1);
            List<Task> taskarray=new List<Task>();
            for(Task t:[SELECT Id,Status FROM Task WHERE Id IN:actvList]){
                System.assertEquals(t.Status,newStatus);
            }
            return updateFlag;                     
        }
    }