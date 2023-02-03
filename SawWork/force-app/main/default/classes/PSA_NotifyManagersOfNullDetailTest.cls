/* ========================================================================
    Author: Sharath Prasanna
    Description: This is a test Class for PSA_NotifyManagersOfNullDetail and PSA_NullDetailReminderScheduler
    Created Date : 26/10/2015
    ======================================================================== */
    @isTest(SeeAllData=false)
    public class PSA_NotifyManagersOfNullDetailTest {
        public static testMethod void test(){
    
            // if( SC_BOCC_Setup__c.getValues('BOCC') == null)
            // {
            //     SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
            //     scSetting.Name = 'BOCC';
            //     scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
            //     scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
            //     scSetting.Product_Id__c = 'M-LC-160618';
            //     insert scSetting;
            // }
            //Creating the data required to create projects 
            PSA_TestUtility testUtil = new PSA_TestUtility();
            Account acct = testUtil.newAccount(true);
            pse__Region__c reg = testUtil.newRegionMaster(true);
            User usr = testUtil.newUserSysAdmin(true);        
            Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
            Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
            Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
            pse__Practice__c pract = testUtil.newPracticeMaster(true);
            pse__proj__c proj;
            Project_Contract__c projContract;
            Project_Contract_Line_Item__c projContractLineItem;
            
            //Creating a project with a contract line item
            proj = testUtil.newProject(true,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
            projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
            projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, null, projContract.Id);
            
            //Creating a project with no contract line items
            proj = testUtil.newProject(true,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
            
            Test.startTest();            
                //creating the CRON expression to run every 5 minutes
                String sch = '0 5 * * * ? ';
                //call the schedule function passing an instance of the scheduler class PSA_NullDetailReminderScheduler
                System.schedule('TestJob', sch , new PSA_NullDetailReminderScheduler());
                //  PSA_NotifyManagersOfNullDetail notifyBatch = new PSA_NotifyManagersOfNullDetail();
                //  Database.executebatch(notifyBatch);
            Test.stopTest();
        }
    }