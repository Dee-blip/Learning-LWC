/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 07-11-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-05-2021   apyati   Initial Version
**/

@isTest(seeAllData=false)
public class AccountPlanControllerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        User anyUser = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
      
        System.runAs(quipAccessUser) {
            //Account Creation
            Account acc = new Account();
            acc.Name = 'TestAccountPlan';
            acc.BillingCountry = 'India';
            acc.BillingState = 'DELHI';
            acc.website = 'www.AccountPlanWebsite.com';
            insert acc;
       
            //Account Plan Template Mapping Creation
            Account_Plan_Template_Mapping__c  mapping = new Account_Plan_Template_Mapping__c ();
            mapping.Name = 'Media & Carrier';
            mapping.Template_URL__c = 'https://www.google.com';
            mapping.Language__c = 'English';
            insert mapping;

            //Account Plan 
            Account_Plan__c plan = new Account_Plan__c ();
            plan.Name = 'TestAccountPlan Plan 1';
            plan.Account__c = acc.Id;
            plan.Language__c = 'English';
            insert plan;
        }
    }


    @isTest static void archivePlanTest(){
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        System.runAs(quipAccessUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
            String message = AccountPlanController.hasActivePlans(acc.Id);
            System.assertNotEquals(message,'','Plans dont exist');
            Account_Plan__c plan = new Account_Plan__c ();
            plan.Name = 'TestAccountPlan Plan 1';
            plan.Account__c = acc.Id;
            plan.Language__c = 'English';
            Test.startTest();
            insert plan;
            Test.stopTest();
            List<Account_Plan__c> plans = [SELECT Id FROM Account_Plan__c WHERE Archived__c= true AND Account__c = : acc.Id];
            System.assertEquals(1, plans.size(),'Plans not archived');
        }
    }

    @isTest static void archivePlanTestException(){
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        System.runAs(quipAccessUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
            try{
                String message = AccountPlanController.hasActivePlans(acc.Id+'test');
            }
            catch(AuraHandledException e){
                System.assertNotEquals(null, e.getMessage(), 'aura exception not captured');
            }
        }
    }
}