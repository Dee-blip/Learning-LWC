/* History:
* =========================
* @author Himanshu Verma,  14th Dec, 2020  
MARIT-949
*/
@isTest(seeAllData=false)
public class MARIT_CSAT_FollowUp_DialogTest {
    private static User dmlUser = new User(id=UserInfo.getUserId());
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
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        //oppty.OwnerId = Userinfo.getUserId();
        insert oppty;
        
        Order_Approval__c orderApproval = new Order_Approval__c();
        orderApproval.Associated_Opportunity__c = oppty.Id;
        insert orderApproval;
        
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = 'Support - Tech Support Agent' AND ManagerId != Null AND IsActive = TRUE LIMIT 1];
        Case c = new Case();
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c.Do_Not_Show_in_Portal__c = false;
        c.Sub_Type__c = 'Product Support';
        c.Status = 'Assigned';
        //c.Incident__c = incident.Id;
        c.Severity__c = '1';
        c.Origin = 'Email';
        c.AccountId = acc.Id;
        c.Level_of_Impact__c = 'Low';
        c.Customer_Temperature__c = 'Low';
        c.Subject = 'Tech Case 1';
        c.Validation_Override__c = true;
        c.OwnerId = userList[0].Id;
        insert c;
        
    }
    public static testmethod void CSAT_GetFollowUpFieldsAndRecordDetails() 
    {
        Account testAccount = [select Id, Akam_Account_Id__c from Account where Name = 'Test Account']; 
        Contact testContact = [select Id, Akam_Contact_Id__c from Contact where Email = 'testContactFollowUp@akamai.com']; 
        Case testCase = [select Id, Akam_Case_Id__c,Severity__c, Case_Owner_Manager_Alias__c, RecordType.Name  from Case limit 1];
        System.debug('Account : ' + testAccount);
        System.debug('Contanct : ' + testContact);
        System.debug('Case : ' + testCase);
        
        CSAT_Survey_Response__c csatObj = new CSAT_Survey_Response__c();
        csatObj.akam_case_id__c = testCase.Akam_Case_Id__c;
        csatObj.AKAM_Contact_ID__c = testContact.Akam_Contact_Id__c;
        csatObj.AKAM_Account_ID__c = testAccount.Akam_Account_Id__c;
        csatObj.Case_Owner_Manager_Alias__c = testCase.Case_Owner_Manager_Alias__c;
        csatObj.Response_Id__c = 'TestResponseId001';
        csatObj.Start_Date__c = System.Datetime.now();
        csatObj.End_Date__c = System.Datetime.now();
        csatObj.Rating__c = '2';
        
        insert csatObj;
            
        System.assert(csatObj.Id != null, 'CSAT Survey Object must be inserted');
        
        String retVal = MARIT_CSAT_FollowUp_Dialog_Controller.GetFollowUpFields(csatObj.Id);
        
        System.assert(retVal.contains('Customer_s_Primary_Concern__c'));
    }
}