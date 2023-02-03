/*
Test class for QuickTaskCreate
Date: 20 December 2016
Developer: Vandhana Krishnamurthy

Date                 Developer Name                    Change
_____________________________________________________________________________________
21 Aug 2018            Vandhana                    ESESP-1623 : seeAllData=false
_____________________________________________________________________________________
*/

@isTest
private class QuickTaskCreate_Test 
{  
    static
    {
        utilTestClass.createCustomSettings();
    }
    @isTest static void TestLOE() 
    {             
        Account acc = utilTestClass.CreateAccount('QuickTaskCreate');
        insert acc;

        Case objCase2 = utilTestClass.createcase(acc.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(objCase2);
        PageReference newPage = Page.QuickTaskCreate;
        Test.setCurrentPageReference(newPage);
        newPage.getParameters().put('Id', objCase2.Id);
        QuickTaskCreate displayTasks = new QuickTaskCreate(sc);
        displayTasks.saveLOE();
        displayTasks.getWidgetEnabled();
        
        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c(Name='mPulse',EB_MarkedForDeletion__c = false,EB_Product__c='Test-456',EB_Account__c=acc.id);
        insert eb_product;
        
        objCase2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        objCase2.Case_Product__c  = eb_product.Id;
        update objCase2;
        sc = new ApexPages.StandardController(objCase2);
        newPage = Page.QuickTaskCreate;
        Test.setCurrentPageReference(newPage);
        newPage.getParameters().put('Id', objCase2.Id);
    }  
}