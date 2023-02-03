/*=====================================================================================================+
Author              :   Aravind Perichiappan
Created             :   20-Aug-2021
Purpose             :   Test Class for SC_SecLawTransitionFormController_Test
+=====================================================================================================*/
@isTest
public class SC_SecLawTransitionFormController_Test {
    @testSetup static void setup()
    {
        utilTestClass.createCustomSettings();

        Account a = utilTestClass.CreateAccount('test account');
        insert a;

        EB_AccountProductMap__c cp = new EB_AccountProductMap__c(
            Name = 'caseProduct',
            EB_Account__c = a.Id,
            EB_Product__c = 'product'
        );
        insert cp;

        Case c = new Case(
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId(),
            AccountId = a.Id,
            Case_Product__c = cp.Id
        );
        insert c;

        insert new SecLaw_Transition_Form__c(
            Case__c = c.Id,
            General_Information__c = 'High Priority',
            Form_Status__c = 'Incomplete'
        );
    }

    @isTest static void testTransition()
    {
        String caseId = [SELECT Id from Case LIMIT 1].Id;

        Test.startTest();
        String result = SC_SecLawTransitionFormController.transitionToSecLaw(caseId, 'Other', '1', 'test');
        Test.stopTest();

        System.assertEquals(result, 'success', 'Transition to SecLaw was unsuccessful');
    }

    @isTest static void testGetSavedForm()
    {
        String caseId = [SELECT Id from Case LIMIT 1].Id;

        Test.startTest();
        SecLaw_Transition_Form__C savedForm = SC_SecLawTransitionFormController.getSavedFormOnCase(caseId);
        Test.stopTest();

        System.assertNotEquals(savedForm, null, 'Failed to get saved form');
    }

    @isTest static void testGetForm()
    {
        String formId = [SELECT Id from SecLaw_Transition_Form__c LIMIT 1].Id;

        Test.startTest();
        SecLaw_Transition_Form__C form = SC_SecLawTransitionFormController.getForm(formId);
        Test.stopTest();

        System.assertNotEquals(form, null, 'Failed to get form');
    }
}