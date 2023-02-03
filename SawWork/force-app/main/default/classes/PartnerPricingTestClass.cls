/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    08/06/2020     Created this Class - SFDC-6405
    
*/
@isTest(seeAllData = false)
private class PartnerPricingTestClass {
    static User dmlUser = new User(id=UserInfo.getUserId());

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        Test.startTest();
        System.runAs(utilTestClass.getTestRunUser())
        {
            new SobjectBuilder(Environment_Setup__c.sObjectType)
            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
            .put(Environment_Setup__c.Active_Org__c, true)
            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
            .create();

            new SObjectBuilder(Features_Toggle__c.sObjectType)
                .put(Features_Toggle__c.name, 'isCronErrorMailViaCode')
                .put(Features_Toggle__c.Toggle__c, false)
                .create();

            new SObjectBuilder(PRM_Settings__c.sObjectType)
                .put(PRM_Settings__c.name, 'NonLitePermissionSets')
                .put(PRM_Settings__c.Value__c, 'Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c')
                .create();
                SObjectFactory.createPartnerUsers(1);
            User partnerUser = SobjectRepository.getPartnerUser();
            
            
        }
    }

    static testmethod void testPartnerPricingAccessAndCertificationCreation()
    {   
        Account acc = SObjectRepository.getAccount();
        test.startTest();
        Product2 testProduct2= new Product2();
        testProduct2.Name = 'TEST';
        testProduct2.RecordTypeId = Product2.sObjectType.getDescribe().getRecordTypeInfosByName().get('NAP 3.0 Products').getRecordTypeId();
            // testProduct2.Family = productFamily;
        insert(testProduct2);
        NAP_Products_Pricing_Access__c napPPA = new NAP_Products_Pricing_Access__c(Partner_Name__c = acc.id, Product__c = testProduct2.id, Pricing_Access__c = 'Basic');
        insert napPPA;
        napPPA = [select id, AKAM_Created_Date__c, Pricing_Access_Updated_On__c from NAP_Products_Pricing_Access__c];
        system.assert(napPPA.Pricing_Access_Updated_On__c.date() == System.now().date());
        try
            {
                NAP_Products_Pricing_Access__c napPPA2 = new NAP_Products_Pricing_Access__c(Partner_Name__c = acc.id, Product__c = testProduct2.id, Pricing_Access__c = 'Basic');
                insert napPPA2;
            }
        catch(Exception e)
            {
                system.assert(e.getMessage().contains('duplicate value found'),e.getMessage() );
            }
            
        NAP_Partner_Certification_Compliance__c napPcc= new NAP_Partner_Certification_Compliance__c(Partner_Name__c=acc.id, Certification_Compliance__c = 'Basic');
        insert napPcc;
        ByPassAndLimitUtils.disable('NAP_Partner_Certification_Compliance_Trigger');
        napPcc= new NAP_Partner_Certification_Compliance__c(Partner_Name__c=acc.id, Certification_Compliance__c = 'Basic');
        insert napPcc;
        ByPassAndLimitUtils.disable('NAP_Partner_Pricing_Access_Trigger');
        napPPA = new NAP_Products_Pricing_Access__c(Partner_Name__c = acc.id, Product__c = testProduct2.id, Pricing_Access__c = 'Basic');
        insert napPPA;
        test.stopTest();
    }
}