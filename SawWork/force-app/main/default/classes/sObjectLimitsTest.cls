@isTest
public class sObjectLimitsTest 
{
    @isTest static void sObjectLimitsTest()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new sObjectLimitsHttpCalloutMock());
        List<sObject_Limit__c> listAsParam1 = new List<sObject_Limit__c>();
        List<sObject_Limit__c> listAsParam2 = new List<sObject_Limit__c>();
        
        sObject_Limit__c sol1 = new sObject_Limit__c();
        sol1.Component_Type__c = 'CustomFields';
        sol1.Object_Name__c = 'Contact';
        sol1.Max_Limit__c = 800;
        sol1.Remaining_Limit__c = 1;
        sol1.Current_Usage_Count__c = 799;
        listAsParam1.add(sol1);
        insert listAsParam1;

        sObject_Limit__c sol2 = new sObject_Limit__c();
        sol2.Component_Type__c = 'CustomFields';
        sol2.Object_Name__c = 'Contact';
        sol2.Max_Limit__c = 800;
        sol2.Remaining_Limit__c = 1;
        sol2.Current_Usage_Count__c = 799;

        sObject_Limit__c sol3 = new sObject_Limit__c();
        sol3.Component_Type__c = 'ValidationRule';
        sol3.Object_Name__c = 'Contact';
        sol3.Max_Limit__c = 800;
        sol3.Remaining_Limit__c = 799;
        sol3.Current_Usage_Count__c = 1;
        
        listAsParam2.add(sol2);
        listAsParam2.add(sol3);
        
        TrackGovLimits tg = new TrackGovLimits(); 
        String returnStatus = tg.TrackGovLimits();
        
        sObjectLimitsDMLChain.resolve(listAsParam2);
        Test.stopTest();
    }
}