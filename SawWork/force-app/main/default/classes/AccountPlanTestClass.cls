/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(seeAllData=false)
private class AccountPlanTestClass {
    
    private static Integer numberOfTestAccounts=10;

    @testSetup
    static void createTestData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            User accOwner = (User) new SObjectBuilder(User.sObjectType)
                .eagerPopulate()
                .put(User.Username, 'acttrgr@akamai.com')
                .put(User.Email, 'rsddd@akamai.com')
                .put(User.CommunityNickname, 'rsdnic')
                .create()
                .getRecord();
        

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

    static testMethod void AccountStrategyTestPositive() {
        // TO DO: implement unit test
        List<Account> listOfTestAccounts = [select id, Vertical__c, Sub_Vertical__c from Account limit :numberOfTestAccounts];
        List<Account_Strategy__c> asList=new List<Account_Strategy__c>();
        for(integer i=0;i<numberOfTestAccounts;i++)
        {
             for(integer j=0;j<100;j++)
             {
                Account_Strategy__c asObj=new Account_Strategy__c();
                asObj.Name='Test Account Strategy';
                asObj.Account__c=listOfTestAccounts[i].id;
                asObj.Type__c='Upside';
                asObj.Sub_Type__c='Event';
                asObj.Impact__c='High';
                asObj.Likelihood__c='Rare';
                asObj.Monthly_Revenue_Impact_USD__c=3210.00;
                asObj.Start_Date__c=Date.Today();
                asObj.End_Date__c=Date.today().addDays(5);
                asObj.Status__c='Open';
                asObj.Alignment__c='Yes';
                
                asList.add(asObj);
             }
        }
        Test.startTest();
        insert asList;
        asList=[Select Id,Name, Akam_Account_Strategy_ID__c,AKAM_System__c,AKAM_Modified_By__c,
                       AKAM_Created_By__c,AKAM_Created_Date__c,AKAM_Modified_Date__c from Account_Strategy__c where id IN:asList];
                       
        for(integer i=0;i<asList.size();i++)
        {
        System.assertNotEquals(asList[i].Akam_Account_Strategy_ID__c,null);
        System.assertEquals(asList[i].AKAM_System__c,'FORCE');
        System.assertNotEquals(asList[i].AKAM_Modified_By__c,null);
        System.assertNotEquals(asList[i].AKAM_Created_By__c,null);
        System.assertNotEquals(asList[i].AKAM_Created_Date__c,null);
        System.assertNotEquals(asList[i].AKAM_Modified_Date__c,null);
        }
        Test.stopTest();  
    }
    
    static testMethod void TrafficShareWithDeliveryVendorTestNegative() {
        // TO DO: implement unit test
        List<Account> listOfTestAccounts = [select id, Vertical__c, Sub_Vertical__c from Account limit :numberOfTestAccounts];
        List<Account_Strategy__c> asList=new List<Account_Strategy__c>();
        Account acc=listOfTestAccounts[0];
            
            Test.startTest();
                Traffic_Share__c tsObj=new Traffic_Share__c();
                tsObj.Product__c='Media Delivery';
                tsObj.Account__c=acc.id;
                tsObj.PB_Month__c=20000;
                tsObj.Customer_Priority__c='Price';
                insert tsObj;
        
                Traffic_Share__c tsObj1=new Traffic_Share__c();
                tsObj1.Product__c='Storage';
                tsObj1.Account__c=acc.id;
                tsObj1.PB_Month__c=10000;
                tsObj1.Customer_Priority__c='Price';
                
                try
                {
                 insert tsObj1;
                }
                catch(DMLException e)
                {
                    System.assert(e.getMessage().contains('Duplicate value on record'));
                }
            
                Delivery_Vendor__c dv1= new     Delivery_Vendor__c();
                dv1.Delivery_Vendor__c='Akamai';
                dv1.Traffic_Share__c=tsObj.Id;
                dv1.Vendor_Traffic_Share__c=25.00;
                
                insert dv1;
                
                Delivery_Vendor__c dv2= new     Delivery_Vendor__c();
                dv2.Delivery_Vendor__c='DIY';
                dv2.Traffic_Share__c=tsObj.Id;
                dv2.Vendor_Traffic_Share__c=25.00;
                dv2.Can_Akamai_get_more_traffic__c='Yes';
                
                insert dv2;
                
            tsObj=[Select Id,Can_Akamai_get_more_traffic__c,Traffic_Share_compliant__c from Traffic_Share__c where id =:tsObj.Id];
            
            System.assertEquals(tsObj.Can_Akamai_get_more_traffic__c,true);
            System.assertEquals(tsObj.Traffic_Share_Compliant__c,false);
            Test.stopTest();    
            
    }
}