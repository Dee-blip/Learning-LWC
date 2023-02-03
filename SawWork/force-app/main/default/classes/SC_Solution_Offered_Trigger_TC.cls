/*
Author          :  Pinkesh
Description     :  Test class for SC_Solution_Offered_Trigger

Date					Developer				JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Jul 2020         	Pinkesh					ESESP-3636      MSS Analytics
------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class SC_Solution_Offered_Trigger_TC {
    @testSetup
    static void setupMethod(){
        utilTestClass.createCustomSettings();
        // Creating Account Records
        Account accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111');
        insert accRec;
        
        Case cs1 = new Case();
        cs1.Description = 'testPS1';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        cs1.Subject = 'testS2ET1';
        cs1.Service__c = 'Managed Integration';
        cs1.Validation_Override__c = true;
        cs1.AccountId = accRec.Id;
        insert cs1;
    }
    
    @isTest
    public static void testMethod1()
    {
        Case c = [Select Id from Case LIMIT 1];
        SC_Solution_Offered__c so1 = new SC_Solution_Offered__c(Case__c=c.Id, Solution_Details__c='test1');
        insert so1;
        SC_Solution_Offered__c so2 = new SC_Solution_Offered__c(Case__c=c.Id, Solution_Details__c='test12');
        insert so2;
    }

}