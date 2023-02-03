// MARIT-10 or MARIT-140 Added by Ujjawal Somani on 17th Oct 2019
@isTest(seeAllData = false)
private class MSI_C2A_Lead_TestClass {
    static testMethod void TestMarketoLeadCreation() 
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
        List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, listOfTestAccounts)
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
            listOfTestContacts[0].Lead_Qualification_Stage__c ='Qualified Lead - Warm';
            update listOfTestContacts;
        }
        Test.startTest();
        System.assert(MSI_C2A_Controller.getParentLeadFromC2A(l.Id)==null , 'lead was: '+l.Id);
        List<Lead> newLead = [Select Id,parent_lead__c From Lead where parent_lead__c =:l.id limit 1];
        for (Lead ithLead : newLead) 
        {
            System.assert(MSI_C2A_Controller.getParentLeadFromC2A(ithLead.Id)!=null , 'ithlead was: '+ithLead);
        }
        List<Lead> newLead1 = [Select Id,Associated_Contact__c From Lead where Associated_Contact__c =:listOfTestContacts[0].id limit 1];
        for (Lead ithLead : newLead1)
        {
            System.assert(MSI_C2A_Controller.getParentLeadFromC2A(ithLead.Id)!=null , 'ithlead was: '+ithLead);
        }
        Test.stopTest();
    }
}