/*******************************************************************************************************
Author       :   jrathod
Created Date :   Jan 05,2022
JIRA         :   ESESP-4062
********************************************************************************************************
Jay               05-Jan-2022       ESESP-4062    Initial version
*/
@IsTest
private class SC_FeedCommentTriggerTest {

    @TestSetup
    static void testSetup(){
        utilTestClass.createCustomSettings();
        SC_SupportEmail__c autogenCs = new SC_SupportEmail__c(Support_Email_AutoGen__c='scdev@akamai.com',Name='1');
        insert autogenCs;

        Map<String, Schema.RecordTypeInfo> rtMap = Case.SObjectType.getDescribe().getRecordTypeInfosByName();

        Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Direct - Active');
        insert accRec;

        Case aCase = new Case(AKAM_Case_ID__c='Case124abc',AccountId=accRec.Id,RecordTypeId=rtMap.get('Managed Security').getRecordTypeId(),
                Origin = 'Others',Do_Not_Show_in_Portal__c = false,Severity__c = '3',Customer_Temperature__c='Low',Level_of_Impact__c='Low');
        insert aCase;
    }

    @IsTest
    static void test_validateTaggedUsers() 
    {
        Test.startTest();
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and IsActive = TRUE And Name != 'CRM Ops' LIMIT 1];
        u.Email = 'test@akamai.com';
        update u;
        Case aCase = [SELECT Id FROM Case LIMIT 1];
        
        System.runAs(u)
        {
            FeedItem fi = new FeedItem(ParentId = aCase.Id, Body = 'Test Body');
            insert fi;

            FeedComment fc = new FeedComment(FeedItemId = fi.Id, CommentBody = 'Test Comment');
            insert fc;
            
            update fc;
        }

        Map<Id,FeedComment> feedComments = new Map<Id, FeedComment>([SELECT Id,ParentId,CommentBody FROM FeedComment LIMIT 10]);

        SC_FeedCommentTriggerHandler.validateTaggedUsers(feedComments);
        Test.stopTest();
    }


    @IsTest
    static void testSendErrorEmail(){
        Test.startTest();
        try{
            System.debug(1/0);
        }catch (Exception e){
            SC_ChatterMentionUtils.sendErrorEmail(e);
        }
        System.assert(Limits.getEmailInvocations() > 0);
        Test.stopTest();
    }

}