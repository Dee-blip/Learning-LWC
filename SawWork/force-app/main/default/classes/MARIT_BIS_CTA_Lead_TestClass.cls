@isTest(seeAllData = false)
private class MARIT_BIS_CTA_Lead_TestClass {
    static testMethod void Test_BIS_CTA() 
    {
        User marketoUser = [select id from user where id = '005G0000005shZtIAI'];
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .count(1)
                .create()
                .getRecords();

        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
        Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.email = 'abdf@email.com';
        	l.Associated_Account__c = listOfTestAccounts[0].id;
            l.status = 'New';
            l.firstname = 'Test1';
            l.lastname = 'Lead1';
        	l.Company = 'Test Company';
            if(marketingOpsUser != null)
                l.ownerId = marketingOpsUser.id;
            l.Associated_Contact__c=null;
            l.Validation_Override__c = true;
        System.runAs(marketoUser)
        {
            insert l;
            l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
            update l;
        }
        Test.startTest();
        List<Lead> newLead = [Select Id,Associated_Account__c From Lead where id =:l.id limit 1];
        for (Lead ithLead : newLead) 
        {
            System.assert(MARIT_BIS_CTA_Controller.getAssociatedAccountFromCTA(ithLead.Id)!=null , 'ithlead was: '+ithLead);
        }
        Test.stopTest();
    }
}