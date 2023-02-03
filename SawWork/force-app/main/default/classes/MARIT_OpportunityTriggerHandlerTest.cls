@isTest(seeAllData = false)
public class MARIT_OpportunityTriggerHandlerTest {
    public static User dmlUser = utilTestClass.getTestRunUser();
    @isTest static void TestOpportunityFormulaFieldUpdatesForCDP(){
        System.runAs(dmlUser) {
            Id ownerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            //creating account 1
            Account acc = new Account();
            acc.Name = 'testAcc-CDP';
            acc.Website = 'www.test.com';
            acc.TERR_HIER_1__c = 'APJ';
            acc.OwnerId = ownerId;

             //creating account 1
            Test.startTest();
            insert acc;
            Opportunity opp = new Opportunity();
            opp.name = 'Test';
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today();
            opp.StageName = '1. Identify Need';
            opp.Deal_Type__c = 'Direct';
            insert opp;
            opp.StageName = 'Closed Lost';
            opp.name = 'Test Loss';
            opp.Loss_Reason__c = 'Other'; 
            opp.Opportunity_Category__c = 'Other';
            opp.Validation_Override__c = true;
            update opp;
            Test.stopTest();
        }
    }
    //MARIT-1070
    @isTest static void testOpportunityAssociatedLeadOwner(){
        System.runAs(dmlUser){
            Id ownerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            //creating account 1
            Account acc = new Account();
            acc.Name = 'testAcc-OpportunityCase';
            acc.Website = 'www.test.com';
            acc.TERR_HIER_1__c = 'APJ';
            acc.OwnerId = ownerId;
            insert acc;
            //creating marketo lead
            Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead ml = new Lead();
            ml.RecordTypeId = akamaiRecordTypeId;
            ml.email = 'testml@akamai.com.invalid';
            ml.Status = 'New';
            ml.firstname = 'Test';
            ml.lastname = 'Test2';
            ml.Associated_Account__c = acc.Id;
            ml.Company = 'Test Company';
            ml.Product_Line__c = 'Media';
            ml.Country = 'India';
            ml.State = 'Karnataka';
            insert ml;
            Test.startTest();
            ml.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
            update ml;
            //converting cta
            Lead al = [Select Id,OwnerId,Status,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Associated_Contact__c,Associated_Opportunity__c from Lead where Parent_Lead__c = :ml.Id];
            al.Authority__c = 'test data for completing anum values';
            al.Need__c = 'test data for completing anum values';
            al.Urgency__c = 'test data for completing anum values';
            al.Money__c = 'test data for completing anum values';
            al.ANUM_Description__c = 'test data for completing anum values';
            al.Lead_Qualification_Status__c = 'Converted';
            update al;
            Lead convertedal = [Select Id,Status,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Associated_Contact__c,Associated_Opportunity__c,Owner__c from Lead where Parent_Lead__c = :ml.Id];
            Opportunity opp = [Select Id,Associated_Lead_Owner__c from Opportunity where Id = :convertedal.Associated_Opportunity__c];
            System.assert(convertedal.Owner__c == opp.Associated_Lead_Owner__c);
            Test.stopTest();
        }
    }
}