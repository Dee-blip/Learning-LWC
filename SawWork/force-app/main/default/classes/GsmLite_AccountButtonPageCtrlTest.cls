@isTest(seeAllData=false)
public class GsmLite_AccountButtonPageCtrlTest 
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    static
    {
      utilTestClass.insertCustomSettings();
    }

    
    public static testmethod void testPartnerUsersOne()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.IsPartnerCustom__c = true;
            acc.BillingState = 'ANDAMAN AND NICOBAR ISLANDS';
            insert acc;
            
            Test.setCurrentPage(Page.GsmLite_AccountButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','PartnerUsers');
            ApexPages.currentPage().getParameters().put('accId',acc.Id);
            ApexPages.currentPage().getParameters().put('userProfile','Partner Community User');    
            
            GsmLite_AccountButtonPageController abpc = new GsmLite_AccountButtonPageController();
            
            PageReference pageRef = abpc.init();
            
            Test.stopTest();
        }
    }
    
     public static testmethod void testPartnerUsersTwo()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.IsPartnerCustom__c = true;
            acc.BillingState = 'ANDAMAN AND NICOBAR ISLANDS';
            insert acc;
            
            Test.setCurrentPage(Page.GsmLite_AccountButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','PartnerUsers');
            ApexPages.currentPage().getParameters().put('accId',acc.Id);
            ApexPages.currentPage().getParameters().put('userProfile','System Administrator'); 
            
            GsmLite_AccountButtonPageController abpc = new GsmLite_AccountButtonPageController();
            
            PageReference pageRef = abpc.init();
            
            Test.stopTest();
        }
    }
}