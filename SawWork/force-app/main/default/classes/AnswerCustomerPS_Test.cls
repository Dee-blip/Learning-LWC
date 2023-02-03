/*=====================================================================================================+			
    Authors             :   Aditya
    Created             :   31-Oct-17
    Purpose             :   Test Class for AnswerCutomerPSController
	Class				:	AnswerCutomerPSController
    
Date                 Developer Name                    Change
_____________________________________________________________________________________
21 Aug 2018            Vandhana                    ESESP-1623 : seeAllData=false
    
+=====================================================================================================*/
@isTest
private class AnswerCustomerPS_Test 
{
    static
    {
        utilTestClass.createCustomSettings();
        SC_AnswerCustomerPS__c sc = new SC_AnswerCustomerPS__c();
        sc.Name = 'ProfessionalServices';
        sc.From_Email_Addresses__c = 'test@akam.com';
        insert sc;
    }
    
    @isTest static void TestValidateEmails() 
    {
        List<Account> lstAcc = new List<Account>();
        Account acc1 = utilTestClass.CreateAccount('test emails1');
        lstAcc.add(acc1);
        
        Account acc2 = utilTestClass.CreateAccount('test emails2');
        lstAcc.add(acc2);
        
        insert lstAcc;
        
        List<Contact> lstCont = new List<Contact>();
        Contact cnt1 = utilTestClass.CreateContact('testemail' , 'contact1');
        cnt1.AccountId = acc1.Id;
        cnt1.Email = 'hgfd@akamai.com';
        cnt1.Validation_Override__c = true;
        lstCont.add(cnt1);
        
        Contact cnt2 = utilTestClass.CreateContact('testemail' , 'contact2');
        cnt2.AccountId = acc1.Id;
        cnt2.Email = 'xyzabc@gmail.com';
        cnt2.Validation_Override__c = true;
        lstCont.add(cnt2);
        
        Contact cnt3 = utilTestClass.CreateContact('testemail' , 'contact3');
        cnt3.AccountId = acc2.Id;
        cnt3.Email = 'cont@xyz.com';
        cnt3.Validation_Override__c = true;
        lstCont.add(cnt3);
        
        Contact cnt4 = utilTestClass.CreateContact('testemail' , 'contact4');
        cnt4.AccountId = acc2.Id;
        cnt4.Email = 'cont@abc.com';
        cnt4.Validation_Override__c = true;
        lstCont.add(cnt4);
        
        insert lstCont;
        
        Case objCase = utilTestClass.createcase(acc2.id);
        objCase.Alternate_Contact_Email__c = 'testalternate@test.com';
        update objCase;
        
        PageReference ref = Page.AnswerCustomerPS;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',objCase.Id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(objCase);
        AnswerCutomerPSController sendEmail = new AnswerCutomerPSController(sc);  
    } 
}