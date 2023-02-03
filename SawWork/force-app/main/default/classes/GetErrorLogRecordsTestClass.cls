@isTest
private class GetErrorLogRecordsTestClass {
    
    private static User dmlUser = new User(id=UserInfo.getUserId());
    
    @testSetup static void setupDataForTest(){
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        //creating lead
        Lead ml = new Lead();
        ml.LastName='MarketoLead';
        ml.Company='Company';
        ml.Associated_Account__c = acc.Id;
        ml.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        insert ml;

        Lead l = new Lead();
        l.RecordTypeId = akamaiRecordTypeId;
        l.email = 'test2@akamai.com.invalid';
        l.Associated_Account__c = acc.Id;
        l.Parent_Lead__c = ml.Id;
        l.Status = 'New';
        l.firstname = 'Test';
        l.lastname = 'AccountMatchTest2';
        l.Company = 'Test Company';
        l.Product_Line__c = 'Media';
        insert l;
        
    }
    static testmethod void GetErrorLogRecordsTest()
    {
        System.runAs(dmlUser)
        {
            Lead l = [Select Id from Lead where Status = 'New' limit 1];
            Error_log__c err = new Error_log__c();
            err.Class__c = 'GetErrorLogRecordsBasedOnID';
            err.Error_Message__c = 'Test class testing';
            err.RecordId__c = l.Id;
            err.Object_State__c = 'Error_Log';
            insert err;
            GetErrorLogRecordsBasedOnID d = new GetErrorLogRecordsBasedOnID(l.Id);
            Database.executeBatch(d,2000);
        }
    }

}