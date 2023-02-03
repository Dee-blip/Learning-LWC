// comment

/*
Date                 Developer Name                    Change
_____________________________________________________________________________________
21 Aug 2018            Vandhana                    ESESP-1623 : seeAllData=false
_____________________________________________________________________________________
*/

@isTest
private class AccountTriggerEntitlementTest
{
	static
    {
        utilTestClass.createCustomSettings();
    }
    
    static testmethod void testEntitlementCreation()
    {
        List<Industry_Vertical_Sub_Vertical_Mapping__c> ivmLst = new List<Industry_Vertical_Sub_Vertical_Mapping__c>();
        Industry_Vertical_Sub_Vertical_Mapping__c ivm1 = new Industry_Vertical_Sub_Vertical_Mapping__c();
        ivm1.Industry__c = 'Enterprise';
        ivm1.Vertical__c = 'Automotive';
        ivm1.Sub_Vertical__c = 'AU - Other';
        ivmLst.add(ivm1);
        
        Industry_Vertical_Sub_Vertical_Mapping__c ivm2 = new Industry_Vertical_Sub_Vertical_Mapping__c();
        ivm2.Industry__c = 'Enterprise';
        ivm2.Vertical__c = 'Automotive';
        ivm2.Sub_Vertical__c = 'AU - RV';
        ivmLst.add(ivm2);
        
        insert ivmLst;
        
        List<Account> lstAcc = new List<Account>();
        Account existingAcc1 = utilTestClass.CreateAccount('Testing Credit Check');
        existingAcc1.Vertical__c = 'Automotive';
        lstAcc.add(existingAcc1);
        
        Account existingAcc2 = utilTestClass.CreateAccount('Master Account');
        lstAcc.add(existingAcc2);
        
        insert lstAcc;  
        
        AccountTriggerClass.createUpdateEntitlementFirstRunFlag = true;
        
        existingAcc1.Support_Level__c = 'Premium';
        update existingAcc1;
        
        AccountTriggerClass.createUpdateEntitlementFirstRunFlag = true;
        
        existingAcc1.Support_Level__c = 'Priority';
        update existingAcc1;
        
        existingAcc1 = [Select Id, Support_Level__c, (Select Id, Name, EndDate From Entitlements) From Account Where Id =: existingAcc1.id];
        
        //System.assertEquals(3, existingAcc1.Entitlements.size());
        
        merge existingAcc2 existingAcc1;
        
        existingAcc2 = [Select Id, (Select Id, Name, EndDate From Entitlements) From Account Where Id =: existingAcc2.id];
        
        if(existingAcc2.Entitlements.size()>0)
        {
            delete existingAcc2.Entitlements;
        
            delete existingAcc2;
        }    
    }
}