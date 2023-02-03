@isTest(seeAllData=false)
public class GSM_AccountMergeApprovalJobTest {
    static User dmlUser = utilTestClass.getTestRunUser();
    static testmethod void oneTestToTestThemAll() {
        List<Account> accountRecs = new List<Account>();
        System.runAs(dmlUser) {   
            Test.startTest();
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            List<User> userList = new List<User>();
            
            User accOwnerUser = utilTestClass.CreateUser('newUser', user_role, 'Sales Operations');
            accOwnerUser.email = 'no-reply@akamai.com';
            userList.add(accOwnerUser);
            User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
            usrSysAdmin.email = 'no-reply@akamai.com';
            userList.add(usrSysAdmin);
            User newUsr = utilTestClass.CreateUser('Test', 'Worldwide', 'System Administrator');
            newUsr.email = 'no-reply@akamai.com';
            userList.add(newUsr);
            User newUsrW = utilTestClass.CreateUser('TestW', 'Worldwide', 'System Administrator');
            newUsrW.email = 'no-reply@akamai.com';
            userList.add(newUsrW);
            insert userList; 
            
            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c newRule1 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', accOwnerUser.Id, 'Business Operations');
            ruleList.add(newRule1);
            Account_Reassignment_Rule__c newRule2 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE2', usrSysAdmin.Id, 'Business Operations');
            ruleList.add(newRule2);
            insert ruleList;
            
            Account winningAcc = utilTestClass.CreateAccount('__Test Winning Account');
            winningAcc.OwnerId =usrSysAdmin.Id;
            winningAcc.type='- Active';
            winningAcc.Website='https://TestWinOrg.co.in';
            accountRecs.add(winningAcc);
            Account losingAcc = utilTestClass.CreateAccount('__Test Losing Account');
            losingAcc.OwnerId =accOwnerUser.Id;
            losingAcc.type='Lead';
            losingAcc.Website='https://TestLoseOrg.co.in';
            losingAcc.Parent_Division__c = 'Web EMEA_Web';
            losingAcc.Division__c = 'Web EMEA Channels';
            losingAcc.Region__c = 'Web EMEA Channels';
            accountRecs.add(losingAcc);
            insert accountRecs;      
            
            
            GSM_AccountMergeApprovalJob o = new GSM_AccountMergeApprovalJob();
            
            
            
            List<Id> targetIds = new List<Id>();
            targetIds.add(losingAcc.Id);   
            Account_Merge_Request__c accMR = new Account_Merge_Request__c();
            accMR.Losing_Account__c = losingAcc.Id;
            accMR.Winning_Account__c = winningAcc.Id;
            accMR.Sales_Ops_User__c = accOwnerUser.Id;
            accMR.Losing_Account_RSM__c = accOwnerUser.Id;
            accMR.Losing_Account_Owner__c = newUsr.Id;
            accMR.Winning_Account_Owner__c = newUsrW.Id;
            accMR.Winning_Account_RSM__c = usrSysAdmin.Id;
            accMR.Approved_by_Operations__c = false;
            accMR.Merge_Status__c  = 'Approval Pending';
            accMR.Merge_Account_Status_Type__c  = 'Lead to Active';
            accMR.Losing_Account_Name__c  = 'losing';
            accMR.Losing_Account_AKAM_ID_Text__c = 'test';
            accMR.Winning_Account_Name__c   = 'test'; 
            accMR.Winning_Account_Division__c = 'test';
            accMR.Losing_Account_Division__c  = 'test'; 
            accMR.Losing_Account_Status_Text__c = 'test';
            accMR.Losing_Account_Must_Map_Text__c = 'test';
            accMR.ORG_URL__c = 'test';
            insert accMR;
            List<Account_Merge_Request__c> li = [select id,CreatedDate,Merge_Status__c,Merge_Account_Status_Type__c, 
                                                 Losing_Account_RSM__r.Email,Winning_Account_RSM__r.Email,Approval_Level__c,
                                                 Losing_Account_RSM__c,Winning_Account_RSM__c,Losing_Account_Owner__r.Name,
                                                 Losing_Account_RSM__r.Name,Winning_Account_Owner__r.Name,
                                                 Winning_Account_RSM__r.Name,Losing_Account_AKAM_ID_Text__c,Losing_Account_Name__c,
                                                 Winning_Account_Name__c , Winning_Account_Division__c,Winning_Account_AKAM_ID__c,Winning_Account_Status__c,Winning_Account_Must_Map__c,
                                                 Losing_Account_Division__c,Losing_Account_Status_Text__c,Losing_Account_Must_Map_Text__c,
                                                 CreatedBy.Name,ORG_URL__c
                                                 from Account_Merge_Request__c  where id = :accMR.id];
            
            
            
            
            o.sendEmailToRSM(li, li);
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting for approval');
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req.setObjectId(accMR.id);
            req.setSubmitterId(userinfo.getuserId());
            req.setProcessDefinitionNameorid('Account_Merge_Process_New');
            req.setSkipEntryCriteria(true);
            
            //Submit the approval request
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess());
            System.assertEquals('Pending', result.getInstanceStatus(),'Instance Status'+result.getInstanceStatus());
            
            
            system.debug('status for approval::'+result.getInstanceStatus());
            List<String> pidList = new List<String>();
            for( ProcessInstanceWorkitem pItem : [Select Id,ProcessInstance.TargetObject.Name 
                                                  from ProcessInstanceWorkitem 
                                                  where ProcessInstance.TargetObjectId =: accMR.id]){
                                                      pidList.add(pItem.Id);
                                                  }
            
            
            
            
            o.evaluateForReminderEmailAndAutoApproval();
            
        }
        
        test.stopTest();
        
        
    }
    
}