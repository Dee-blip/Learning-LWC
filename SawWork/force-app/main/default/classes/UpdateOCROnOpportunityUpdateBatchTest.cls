@isTest(seeAllData = false)
public class UpdateOCROnOpportunityUpdateBatchTest {
    public static User dmlUser = utilTestClass.getTestRunUser();
    @isTest static void TestUpdateContactWithModifiedAccount(){
        System.runAs(dmlUser) {
            CDP_Config__c cdp_config_record = new CDP_Config__c(Name = 'UpdatedTimeForOCR_OpportunityFormula', Last_Update_DateTime__c = System.now().addHours(-50));
            insert cdp_config_record;

            String emailAddress = 'CustomContactWorkflow@gmail.com';
            Account newAccount = new Account();
            newAccount.Name = 'CustomContactWorkflowAccount';
            newAccount.BillingCountry = 'India';
            newAccount.BillingState = 'DELHI';
            newAccount.Updated_Date_For_CDP__c = System.now().addDays(-10);
            insert newAccount;

            Contact c = new Contact();
            c.email = emailAddress;
            c.lastname = 'TestLead';
            c.AccountId = newAccount.id;
            insert c;

            Opportunity oppty = new Opportunity();
            oppty.Name = '__Test Oppty';
            oppty.StageName = '4. Select Option';
            oppty.AccountId = newAccount.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;

            OpportunityContactRole opptyContactRole = new OpportunityContactRole();
            opptyContactRole.ContactId = c.Id;
            opptyContactRole.OpportunityId  = oppty.Id;
            opptyContactRole.Role = 'Lead';
            List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
            ocrList.add(opptyContactRole);

            Test.startTest();
            oppty.Loss_Reason__c = 'Other';
            oppty.Validation_Override__c = true;
            update oppty;

            UpdateOCROnOpportunityUpdate updateOCR = new UpdateOCROnOpportunityUpdate();
            //Database.executeBatch(updateOCR);
            Database.QueryLocator ql = updateOCR.start(null);
            updateOCR.execute(null,ocrList);
            updateOCR.Finish(null);

            Test.stopTest();
        }
    }
}