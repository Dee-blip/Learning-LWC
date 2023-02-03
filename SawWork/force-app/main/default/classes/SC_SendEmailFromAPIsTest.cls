@isTest(seeAllData = false)
public class SC_SendEmailFromAPIsTest 
{
    public SC_SendEmailFromAPIsTest() 
    { }
    
    public static Id accId;
    public static Id caseId;
    public static Id orgWideAddress;
    @TestSetup
    static void setupMethod()
    {
        orgWideAddress = [SELECT Id, Address, DisplayName, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE DisplayName = 'sf-no-reply'].Id;
        utilTestClass.createCustomSettings();
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestAccountForAPITesting');
        accList.add(acc);
        insert accList;

        accid = acc.Id;

        Test.startTest();
        // Creating Case

        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = acc.Id;
        //newCase.OwnerId = amgUser.Id;
        newCase.origin='Akamai';
        newcase.Status = 'Assigned';
        newcase.Service__c = 'Alerts';
        newcase.Request_Type__c = 'Add Alerts';
        newcase.Request_Sub_Type__c ='N/A - Not Applicable';
        newcase.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        newcase.Resolution_Field__c = 'N/A - Not Applicable';
        newcase.Resolvable_by_Partner__c = false;
        newcase.LOE_Hours__c=2;
        newcase.LOE_Minutes__c=30;
        newcase.Solution_Summary__c= 'Test';
        newcase.PRISM_Used__c = 'Yes';
        newcase.Task_LOE__c= 8;
        newcase.Last_Case_Owner_Update__c = System.now();
        newcase.Last_Non_Case_Owner_Update__c = System.now();
        newcase.Last_Customer_Activity_Date__c = System.now();
        newCase.AuthorizedContacts__c = 'xyz@gmail.com';

        newCaseInsertList.add(newCase);
        insert newCaseInsertList;

        Test.stopTest();
        caseId = newCaseInsertList[0].Id;
    }

    @isTest
    public static void testCloseMethods()
    {
		System.debug('###### caseId' + caseId);
        caseId = [SELECT Id FROM Case LIMIT 1].Id;
        Test.startTest();
        Case_Email_Content__c varCEC = new  Case_Email_Content__c();
        varCEC.BCC_Addresses__c = 'kusharma@akamai.com';
        varCEC.CC_Addresses__c = 'kusharma@akamai.com';
        varCEC.To_Addresses__c = 'kusharma@akamai.com,xyz@gmail.com';
        varCEC.Email_Body__c = 'Email from Test class';
        varCEC.Email_Subject__c = 'Email from test class';
        varCEC.Email_Attachment_Ids__c = '';
        varCEC.Case__c = caseId;
        varCEC.From_Email_Address__c = orgWideAddress;
        insert varCEC;
        Test.stopTest();
    }
    
    @isTest
    public static void testsetAttachmentContentType()
    {
		SC_SendEmailFromAPIs seClass = new SC_SendEmailFromAPIs();
        seClass.setAttachmentContentType('pdf');
        seClass.setAttachmentContentType('png');
        seClass.setAttachmentContentType('xlsx');
        seClass.setAttachmentContentType('doc');
        seClass.setAttachmentContentType('snote');
        seClass.setAttachmentContentType('jpeg');
        seClass.setAttachmentContentType('text');
        seClass.setAttachmentContentType('ppt');
        seClass.setAttachmentContentType('xlsm');
        seClass.setAttachmentContentType('zip');
        seClass.setAttachmentContentType('csv');
        seClass.setAttachmentContentType('gif');
        seClass.setAttachmentContentType('rtf');
        seClass.setAttachmentContentType('mp4');
        seClass.setAttachmentContentType('tiff');
        seClass.setAttachmentContentType('html');
        System.assertEquals('',seClass.setAttachmentContentType('xml'));
    }
}