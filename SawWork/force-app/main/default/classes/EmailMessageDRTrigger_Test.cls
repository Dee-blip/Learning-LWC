@isTest(seeAllData=false)
public class EmailMessageDRTrigger_Test {
    static testMethod void test_EmailMessage(){
        
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       	System.runAs (thisUser) {
        	utilTestClass.createCustomSettings();
        }
        ExternalSharingHelper.RunFromtestClass = true;
        
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();       
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('AMG').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.Validation_Override__c = True;
        insert cs; 
        test.startTest();
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'vs@akamai.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId = cs.Id));
        Database.insert(newEmail);  
        test.stopTest();    
    }
    

}