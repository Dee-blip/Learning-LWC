@isTest(seeAllData=false)
public class gsm_AccountMergeFlowControllerTest {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();

    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {   
            ManagedPkgErrorClass.isFromManagedPackage = false;
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
             //SFDC-2572
            //Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            /* End Of Custom Setting Insertion */
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            List<User> userList = new List<User>();
            List<Account> accountRecs = new List<Account>();
            User accOwnerUser = utilTestClass.CreateUser('newUser', user_role, 'Sales Operations');
            userList.add(accOwnerUser);
            User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
            userList.add(usrSysAdmin);
           
            User usrNew = utilTestClass.CreateUser('TestUser', user_role, 'Sales Operations');
            userList.add(usrNew);
            
            User usrNewWin = utilTestClass.CreateUser('TestWin', user_role, 'Sales Operations');
            userList.add(usrNewWin);
            insert userList; 
            
            Territory_Mapping__c tm = new Territory_Mapping__c();
            tm.name = 'ANZ - ANZ Comm & Ent';
            tm.TERR_HIER_1__c = 'APJ';
            tm.TERR_HIER_2__c = 'ANZ';
            tm.TERR_HIER_3__c = 'ANZ Media & Enterprise';
            tm.TERR_HIER_4__c = 'ANZ Enterprise';
            tm.TERR_HIER_5__c = 'ANZ Comm & Ent';
            insert tm;

            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c newRule1 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', accOwnerUser.Id, 'Marketing Operations');
            newRule1.Territory_ID__c = tm.Id;
            ruleList.add(newRule1);
            Account_Reassignment_Rule__c newRule2 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE2', usrSysAdmin.Id, 'Marketing Operations');
            newRule2.Territory_ID__c = tm.Id;
            ruleList.add(newRule2);
            Account_Reassignment_Rule__c newRule3 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE3', usrNew.Id, 'Marketing Operations');
            newRule3.Territory_ID__c = tm.Id;
            ruleList.add(newRule3);
            Account_Reassignment_Rule__c newRule4 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE4', usrNewWin.Id, 'Marketing Operations');
            newRule4.Territory_ID__c = tm.Id;
            ruleList.add(newRule4);
            insert ruleList;
                        
            Account winningAcc = utilTestClass.CreateAccount('__Test Winning Account');
            winningAcc.OwnerId =usrSysAdmin.Id;
            winningAcc.Website='https://TestWinOrg.co.in';
           /* winningAcc.Parent_Division__c = 'Media & Carrier LATAM_Media & Carrier';
            winningAcc.Division__c = 'Software, Media & Gaming';
            winningAcc.Region__c = 'Media Core & OEM';
            winningAcc.Area__c = 'Media S. America';*/
            winningAcc.TERR_HIER_1__c = 'APJ';
            winningAcc.TERR_HIER_2__c = 'ANZ';
            winningAcc.TERR_HIER_3__c = 'ANZ Media & Enterprise';
            winningAcc.TERR_HIER_4__c = 'ANZ Enterprise';
            winningAcc.TERR_HIER_5__c = 'ANZ Comm & Ent';
            accountRecs.add(winningAcc);
            Account winningAcc1 = utilTestClass.CreateAccount('__Test Winning Account1');
            winningAcc1.OwnerId =usrNewWin.Id;
            winningAcc1.Website='https://TestWinOrg.co.in';
            //winningAcc1.Parent_Division__c = 'Media & Carrier LATAM_Media & Carrier';
            winningAcc1.TERR_HIER_1__c = 'APJ';
            winningAcc1.TERR_HIER_2__c = 'ANZ';
            winningAcc1.TERR_HIER_3__c = 'ANZ Media & Enterprise';
            winningAcc1.TERR_HIER_4__c = 'ANZ Enterprise';
            winningAcc1.TERR_HIER_5__c = 'ANZ Comm & Ent';
            accountRecs.add(winningAcc1);
            Account losingAcc = utilTestClass.CreateAccount('__Test Losing Account');
            losingAcc.OwnerId =accOwnerUser.Id;
            losingAcc.Website='https://TestLoseOrg.co.in';
            //losingAcc.Parent_Division__c = 'Media & Carrier LATAM_Media & Carrier';
            losingAcc.TERR_HIER_1__c = 'APJ';
            losingAcc.TERR_HIER_2__c = 'ANZ';
            losingAcc.TERR_HIER_3__c = 'ANZ Media & Enterprise';
            losingAcc.TERR_HIER_4__c = 'ANZ Enterprise';
            losingAcc.TERR_HIER_5__c = 'ANZ Comm & Ent';
            accountRecs.add(losingAcc);
            Account losingAcc1 = utilTestClass.CreateAccount('__Test Losing Account1');
            losingAcc1.OwnerId =usrNew.Id;
            losingAcc1.Website='https://TestLoseOrg.co.in';
            /*losingAcc1.Parent_Division__c = 'Media & Carrier LATAM_Media & Carrier';
            losingAcc1.Division__c = 'Software, Media & Gaming';
            losingAcc1.Region__c = 'Media Core & OEM';
            losingAcc1.Area__c = 'Media S. America';*/
            losingAcc1.TERR_HIER_1__c = 'APJ';
            losingAcc1.TERR_HIER_2__c = 'ANZ';
            losingAcc1.TERR_HIER_3__c = 'ANZ Media & Enterprise';
            losingAcc1.TERR_HIER_4__c = 'ANZ Enterprise';
            losingAcc1.TERR_HIER_5__c = 'ANZ Comm & Ent';
            accountRecs.add(losingAcc1);
            insert accountRecs;
            
            
            

            Merge_Contract_Header__c contObj = new Merge_Contract_Header__c();
            contObj.Account_Name__c = winningAcc.Id;
            contObj.Active__c = true;
            contObj.Effective_End_Date__c = system.today();
            insert contObj;
        }
    }

    static testmethod void accountMergeRequestTriggerTest() {
        Account winningAcc; 
        Account losingAcc;
        List<Id> targetIds = new List<Id>();
        User salesUser;
        List<String> userAlias = new List<String>{'newUser','SysAdmin','TestWin','TestUser'};
        for(User u : [select Id, Alias from User where Alias IN : userAlias]){
            if(u.Alias == 'newUser') {
                salesUser = u;  
            }
        }
        String Result = null;
        winningAcc = [Select Id, Name, OwnerId, Owner.Name, Account_Status__c, Revenue_Account__c,
                      TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,
                      Website, Region__c from Account where Name = '__Test Winning Account'];
        Account winningAcc1 = [Select Id, Name, OwnerId, Owner.Name, Account_Status__c, Revenue_Account__c,
                      TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,
                      Website, Region__c from Account where Name = '__Test Winning Account1'];
        losingAcc = [Select Id, Name, OwnerId, Owner.Name, Account_Status__c, Revenue_Account__c,
                      TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,
                      Website, Region__c from Account where Name = '__Test Losing Account'];
        Account losingAcc1 = [Select Id, Name, OwnerId, Owner.Name, Account_Status__c, Revenue_Account__c,
                      TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,
                      Website, Region__c from Account where Name = '__Test Losing Account1'];
        String accountsSearch = gsm_AccountMergeFlowController.getAccountData('__Test',losingAcc.Id);
        targetIds.add(losingAcc.Id);
        Result = gsm_AccountMergeFlowController.createAccountMerge('winning',targetIds,winningAcc.Id);
        //system.assertEquals(Result,'success');
        targetIds.clear();
        targetIds.add(winningAcc.Id);
        Result = gsm_AccountMergeFlowController.createAccountMerge('losing',targetIds,losingAcc.Id);
        //system.assertNotEquals(Result,'success');
        Account acc = gsm_AccountMergeFlowController.getAccountDetail(winningAcc.Id);
        String accStatus = gsm_AccountMergeFlowController.checkLosingAccountsStatus(targetIds);
        accStatus = gsm_AccountMergeFlowController.checkAccountStatus(winningAcc.Id);
        accStatus = gsm_AccountMergeFlowController.getUserTheme();
        Account_Merge_Request__c accMR = new Account_Merge_Request__c();
        accMR.Losing_Account__c = losingAcc1.Id;
        accMR.Winning_Account__c = winningAcc1.Id;
        accMR.Sales_Ops_User__c = salesUser.Id;
        accMR.Approved_by_Operations__c = true;
        insert accMR;
        gsm_AccountMergeFlowController.getAccountRequestsData(winningAcc1.id);
    }
}