@isTest(seeAllData=false)
public class MARIT_KPIISurveyHandlerTest {
    @testSetup
    static void setupMethod() 
    {

        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        Account acc = utilTestClass.CreateAccount('Test Account');
        insert acc;
        
        // Create contact
        Contact con = utilTestClass.CreateContact('Test First','Test Contact');
        con.AccountId = acc.Id;
        con.email = 'testContactFollowUp@akamai.com';
        insert con;
    }
    
    public static testmethod void KPI_RecordCreation() 
    {
        Account testAccount = [select Id, Akam_Account_Id__c from Account where Name = 'Test Account']; 
        Contact testContact = [select Id, Akam_Contact_Id__c from Contact where Email = 'testContactFollowUp@akamai.com']; 
        
        kpi_survey__c kpiObj = new kpi_survey__c();
        kpiObj.AKAM_Contact_ID__c = testContact.Akam_Contact_Id__c;
        kpiObj.AKAM_Account_ID__c = testAccount.Akam_Account_Id__c;
        kpiObj.Response_Id__c = 'TestResponseId001';
        kpiObj.Start_Date__c = System.Datetime.now();
        kpiObj.End_Date__c = System.Datetime.now();
        insert kpiObj;

        System.assert(kpiObj.Id != null, 'KPI Survey Object must be inserted');
    }    
}