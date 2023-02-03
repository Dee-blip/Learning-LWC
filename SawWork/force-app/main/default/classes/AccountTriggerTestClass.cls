@isTest(seeAllData=false)
private class AccountTriggerTestClass {
    private static Integer numberOfTestAccounts=10;
 
    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
 
            User accOwner = SobjectRepository.getSalesOpsUser();
        
 
            new SObjectBuilder(Account_Reassignment_Rule__c.sObjectType)
                .eagerPopulate()
                .put(Account_Reassignment_Rule__c.SubTerritory__c, 'Multiple')
                .put(Account_Reassignment_Rule__c.Associated_User__c, accOwner.Id)
                .create();
 
 
            new SobjectBuilder(Industry_Vertical_Sub_Vertical_Mapping__c.sObjectType)
                .count(3)
                .create();
 
            System.runAs(accOwner)
            {
                new SobjectBuilder(Account.sObjectType)
                    .eagerPopulate()
                    .put(Account.Vertical__c, 'Public Sector')
                    .put(Account.Sub_Vertical__c, 'PS - Higher Ed')
                    .put(Account.Anaplan_Sub_Territory__c, 'Multiple')
                    .count(numberOfTestAccounts)
                    .create();
            }
        }
    }
   
    //Vamsee Surya : Test Method for afterUpdate
    static testmethod void afterUpdate_Test(){
           
        SupportLevel_Sla_Map__c slaSetup = new SupportLevel_Sla_Map__c();
        slaSetup.Name = 'Standard';
        slaSetup.SlaProcess__c = 'Standard';
        Insert slaSetup;
       
        test.startTest();
            Account testAccount  = utilTestClass.CreateAccount('testAccount');
            testAccount.Support_Level__c = 'Premium';
               testAccount.Parent_Division__c = 'Web';
               testAccount.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
            Insert testAccount;
           
               AccountTeamMember accountTeamMemberPSA = new AccountTeamMember();
                                                accountTeamMemberPSA.AccountId = testAccount.Id;
                                                accountTeamMemberPSA.UserId = UserInfo.getUserId();
                                                accountTeamMemberPSA.TeamMemberRole = 'Technical Sales - Primary';
                                                insert accountTeamMemberPSA;
           
            List<Entitlement> entitlementList = new List<Entitlement>();
            Entitlement entitlementObject1 = new Entitlement();
            entitlementObject1.AccountId = testAccount.Id;
            entitlementObject1.Name = 'Billing Support';
            entitlementObject1.StartDate = System.today();
            entitlementObject1.EndDate = System.today().addDays(10);
            entitlementList.add(entitlementObject1);
            Entitlement entitlementObject2 = new Entitlement();
            entitlementObject2.AccountId = testAccount.Id;
            entitlementObject2.Name = 'Standard';
            entitlementObject2.StartDate = System.today();
            entitlementList.add(entitlementObject2);
            Insert entitlementList;
           
        
            testAccount.Support_Level__c = 'Standard';
            AccountTriggerClass.createUpdateEntitlementFirstRunFlag = True;
            Update testAccount;
        test.stopTest();
    }

    static testmethod void coverByPassLogic() {
    System.runAs(utilTestClass.getTestRunUser()) {
            ByPassAndLimitUtils.disable('AccountTriggerGeneric');
            Test.startTest();
            Account testAccount  = utilTestClass.CreateAccount('testAccount');
            testAccount.Support_Level__c = 'Premium';
            testAccount.Parent_Division__c = 'Web';
            testAccount.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
            Insert testAccount;
            Test.stopTest();
        }
    } 
 
    // changes by Vandhana for ESESP-5494 Support Differentiation for AkaTec (Saturn)
    static testmethod void testSupportDelivery() 
    {
        Test.startTest();
        Account_Support_Delivery_Type_Mapper__c accDelMap = new Account_Support_Delivery_Type_Mapper__c();
        accDelMap.Support_Delivery_Type__c = 'Global';
        accDelMap.Support_Level__c = 'Indirect_Customer;None;None-Collections;None-NoContractLine;Reseller;Standard;NetAlliance_Standard;Unspecified;Standard_EnhancedSLA;Network Support';
        accDelMap.Exception_Countries__c = 'China;Korea'; //Added by Aditi for ESESP-5717
        accDelMap.Exemption_Territories__c = 'Hong Kong;Taiwan'; //Added by Aditi for ESESP-5717
        insert accDelMap;
        
        Account testAccount  = utilTestClass.CreateAccount('testAccount');
        testAccount.Support_Level__c = 'Premium';
        testAccount.Parent_Division__c = 'Web';
        testAccount.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
        testAccount.Type = 'Direct Customer - Active';
        testAccount.BillingCountry = 'China';//Added by Aditi for ESESP-5717
        testAccount.TERR_HIER_5__c = 'Taiwan';//Added by Aditi for ESESP-5717
        Insert testAccount;
        
        accDelMap.Additional_Support_Levels__c = 'Premium';
        //accDelMap.Exception_Countries__c = 'China;Korea;Japan';
        //accDelMap.Exemption_Territories__c = 'Hong Kong';
        update accDelMap;
        
        accDelMap.Exception_Countries__c = 'China;Korea;Japan';
        //accDelMap.Exemption_Territories__c = 'Hong Kong';
        update accDelMap;
        
        //accDelMap.Exception_Countries__c = 'China;Korea;Japan';
        accDelMap.Exemption_Territories__c = 'Hong Kong';
        update accDelMap;
        
        //accDelMap.Exception_Countries__c = 'China;Korea;Japan';
        accDelMap.Exemption_Territories__c = 'Hong Kong;Taiwan';
        update accDelMap;
        
        accDelMap.Additional_Support_Levels__c = 'ETC';
        accDelMap.Exemption_Territories__c = 'Hong Kong';
        update accDelMap;
        
        accDelMap.Exemption_Territories__c = 'Hong Kong;Taiwan';
        update accDelMap;
        
        accDelMap.Exception_Countries__c = 'Korea;Japan';
        accDelMap.Exemption_Territories__c = 'Hong Kong';
        update accDelMap;
        
        Account testAccountAgainForMapper1  = utilTestClass.CreateAccount('testAccountAgainForMapper1');
        testAccountAgainForMapper1.Support_Level__c = 'Plus';
        testAccountAgainForMapper1.Parent_Division__c = 'Web';
        testAccountAgainForMapper1.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
        testAccountAgainForMapper1.Type = 'Direct Customer - Active';
        testAccountAgainForMapper1.BillingCountry = 'Japan';
        testAccountAgainForMapper1.TERR_HIER_5__c = 'Tokyo';
        //testAccountAgainForMapper1.Account_Elevation_Mailing_List__c = 'test@test.com,adsing@akamai.com';//Added for code coverage of validateElevationDLOnAccount()
        insert testAccountAgainForMapper1;
        
        accDelMap.Additional_Support_Levels__c = 'Plus';
        update accDelMap;
        
        
        Account testAccountAgainForMapper2  = utilTestClass.CreateAccount('testAccountAgainForMapper2');
        testAccountAgainForMapper2.Support_Level__c = 'Standard';
        testAccountAgainForMapper2.Parent_Division__c = 'Web';
        testAccountAgainForMapper2.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
        testAccountAgainForMapper2.Type = 'Direct Customer - Active';
        testAccountAgainForMapper2.BillingCountry = 'South Korea';
        testAccountAgainForMapper2.TERR_HIER_5__c = 'Seoul';
        //testAccountAgainForMapper1.Account_Elevation_Mailing_List__c = 'test@test.com,adsing@akamai.com';//Added for code coverage of validateElevationDLOnAccount()
        insert testAccountAgainForMapper2;
        
        accDelMap.Support_Level__c = 'Indirect_Customer;None;None-Collections;None-NoContractLine;Reseller;NetAlliance_Standard;Unspecified;Standard_EnhancedSLA;Network Support';
        accDelMap.Exemption_Territories__c = 'Hong Kong;Seoul';
        update accDelMap;
        

        //Aditi - Added below Account block  for ESESP-5717
        Account testAccountAgain  = utilTestClass.CreateAccount('testAccountAgain');
        testAccountAgain.Support_Level__c = 'Network Support';
        testAccountAgain.Parent_Division__c = 'Web';
        testAccountAgain.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
        testAccountAgain.Type = 'Direct Customer - Active';
        testAccountAgain.BillingCountry = 'Japan';
        testAccountAgain.TERR_HIER_5__c = 'Tokyo';
        testAccountAgain.Account_Elevation_Mailing_List__c = 'test@test.com,adsing@akamai.com';//Added for code coverage of validateElevationDLOnAccount()
        try{
            Insert testAccountAgain;
            
            //accDelMap.Exception_Countries__c = 'China;Korea;Japan';
            accDelMap.Support_Level__c = 'Indirect_Customer;None;None-Collections;None-NoContractLine;Reseller;Standard;NetAlliance_Standard;Unspecified;Standard_EnhancedSLA';
            update accDelMap;
        }
        catch(Exception ex){
            Boolean expectedExceptionThrown =  ex.getMessage().contains('is not valid. Please enter valid Akamai email addresses separated by comma.')?true:false;
            System.AssertEquals(expectedExceptionThrown, true);
        }


        Test.stopTest();
    } 
 
}