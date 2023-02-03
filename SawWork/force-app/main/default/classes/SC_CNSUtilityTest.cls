/*******************************************************************************************************
Author       :   jrathod
Created Date :   Jan 05,2022
JIRA         :   ESESP-5526
Description  :  Test class for CNS functions
********************************************************************************************************
Jay               05-Jan-2022       ESESP-5526    Initial version
*/

@IsTest
private class SC_CNSUtilityTest {

    @TestSetup
    static void testSetup(){
        utilTestClass.createCustomSettings();
        Map<String, Schema.RecordTypeInfo> rtMap = Case.SObjectType.getDescribe().getRecordTypeInfosByName();
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec;

        Case_Notification_Subscription__c sub1 = new Case_Notification_Subscription__c(Account__c = accRec.Id,User__c=UserInfo.getUserId(),Case_Record_Type__c ='Managed Security',Portal_Visibility__c ='All',Case_Origin__c ='All',Severity__c = '3 & below',Incident__c = 'No',ListenEmailComms__c = true);
        insert sub1;

        Case aCase = new Case(AKAM_Case_ID__c='Case124abc',AccountId=accRec.Id,RecordTypeId=rtMap.get('Managed Security').getRecordTypeId(),
                Origin = 'Others',Do_Not_Show_in_Portal__c = false,Severity__c = '3',Customer_Temperature__c='Low',Level_of_Impact__c='Low');
        insert aCase;

        SC_CNSOnCase__c sub2 = new SC_CNSOnCase__c();
        sub2.Case__c = aCase.Id;
        sub2.User__c = UserInfo.getUserId();
        insert sub2;

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
        );
        insert contentVersion;

    }

    @IsTest
    static void test_emailToCNSAsync_Inbound() {
        Case aCase = [SELECT Id FROM Case WHERE AKAM_Case_ID__c = 'Case124abc' LIMIT 1];
        ContentVersion contentVersion = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        EmailMessage message = new EmailMessage();
        message.FromAddress = 'test@gmail.com';
        message.ToAddress = 'test@example.com';
        message.ParentId = aCase.Id;
        message.Subject = 'Test Subject';
        message.TextBody = 'Test';
        message.HtmlBody = 'Test';
        message.Incoming = true;
        insert message;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = message.Id;
        cdl.ContentDocumentId = contentVersion.ContentDocumentId;
        insert cdl;
        Attachment att = new Attachment();
        att.ParentId   = message.Id;
        Blob bodyBlob  = Blob.valueOf('Unit Test Attachment Body');
        att.body       = bodyBlob;
        att.Name       = 'testAtt';
        insert att;

        Test.startTest();
        SC_CNSUtility.emailToCNSAsync(new List<Id>{message.Id});
        Test.stopTest();
        System.assertEquals(0,Limits.getEmailInvocations(),'Email should be sent.');
    }

    @IsTest
    static void test_getCaseNotificationSubsOnACase(){
        Case aCase = [SELECT Id FROM Case LIMIT 1];
        List<Map<String,Object>> subs = SC_CNSUtility.getCaseNotificationSubsOnACase(aCase.Id);
        System.assert(subs.size() > 0);
    }

    @IsTest
    static void testCnsOnCaseDuplicateCheck(){
        SC_CNSOnCase__c sub2 = [SELECT Id FROM SC_CNSOnCase__c LIMIT 1];
        Test.startTest();
        try{
            update sub2;
        }catch (Exception e){
            System.assert(e instanceof DmlException);
            System.assert(e.getMessage().contains('Subscription already exists'));
        }
        Test.stopTest();
    }

}