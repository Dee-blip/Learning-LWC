/*
************************************************************************************************************
Author              :   Vikas 
Created             :   24-Feb-2021
Purpose             :   Test Class for SC_AC_BulkEdit - Bulk Authorized Contact edit

************************************************************************************************************
*/

@isTest(seeAllData = false)
public class SC_AC_BulkEdit_TC {
    @testSetup
    static void testDataSetup()
    {
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestPLXAccount');   
        accList.add(acc);
        insert accList;
        
        Contact con = new Contact();
        con.lastname = 'con last name';
        con.AccountId = acc.Id;
        insert con;
        
        Policy_Domain__c pd = new Policy_Domain__c();
        pd.Account_name__c = acc.Id;
        pd.Name = 'plx PD';
        pd.Product__c  = 'PLX';
        pd.Policy_Domain_State__c = 'Active';
        insert pd;
    }
    public static testMethod void plxTestCases()
    {
        Policy_Domain__c thisPD = [select Id from Policy_Domain__c where name =: 'plx PD' limit 1];
        Contact thisCon = [select Id from Contact limit 1];
        Authorized_Contact__c thisAC = new Authorized_Contact__c();
        thisAC.Contact_Name__c = thisCon.Id;
        thisAC.Emergency_Text__c = true;
        insert thisAC;
        
        List<Authorized_Contact__c> ACList = [Select id,Emergency_Text__c from Authorized_Contact__c];
        Object ACObj = (Object)ACList;
        
		SC_AC_BulkEdit.getProductInterestsOnLoad();
        SC_AC_BulkEdit.getRecordsToDisplay(String.valueOf(thisPD.Id));
        system.debug('dsfsdf  :'+ACObj);
        SC_AC_BulkEdit.updateContacts(ACObj);
    }
}