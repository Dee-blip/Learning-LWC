@isTest(seeAllData = false)
public class UpdateLeadOnAccountUpdateBatchTest {
    public static User dmlUser = utilTestClass.getTestRunUser();
    @isTest static void TestUpdateLeadWithModifiedAccount(){
        System.runAs(dmlUser) {
            CDP_Config__c cdp_config_record = new CDP_Config__c(Name = 'UpdatedTimeForLead_AccountFormula', Last_Update_DateTime__c = System.now().addHours(-50));
            insert cdp_config_record;

            String emailAddress = 'CustomContactWorkflow@gmail.com';
            Account newAccount = new Account();
            newAccount.Name = 'CustomContactWorkflowAccount';
            newAccount.BillingCountry = 'India';
            newAccount.BillingState = 'DELHI';
            newAccount.Updated_Date_For_CDP__c = System.now().addDays(-10);
            insert newAccount;

            Lead l = new Lead();
            l.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            l.email = emailAddress;
            l.company = 'Test Company';
            l.lastname = 'TestLead';
            l.Associated_Account__c = newAccount.id;
            insert l;
/*
            Id leadtype = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            String leadJSON = '{"attributes":{"type":"Lead","url":"/services/data/v25.0/sobjects/Lead/500E0000002nH2fIAE"},"Id":"500E0000002nH2fIAE","Associated_Account__c":"'+newAccount.id+'","RecordTypeId":"'+leadtype+'","company":"Test Company","lastname":"TestLead","CreatedDate":"2019-10-04T17:54:26.000+0000","LastModifiedDate":"2019-10-05T17:54:26.000+0000"}'; 
            Lead l = (Lead) JSON.deserialize(leadJSON, Lead.class ); 
            System.debug('Test Lead createdDate:' + l.createdDate);
            System.debug('Test Lead LastModifiedDate:' + l.LastModifiedDate);
            System.debug('Test LeadId:' + l.Id);
*/            
            List<Lead> leadList = new List<Lead>();
            leadList.add(l);

            Test.startTest();
            newAccount.TERR_HIER_1__c = 'APJ';
            update newAccount;

            UpdateLeadOnAccountUpdate updateLead = new UpdateLeadOnAccountUpdate();
            //Database.executeBatch(updateLead);
            Database.QueryLocator ql = updateLead.start(null);
            updateLead.execute(null,leadList);
            updateLead.Finish(null);

            Test.stopTest();
        }
    }
}