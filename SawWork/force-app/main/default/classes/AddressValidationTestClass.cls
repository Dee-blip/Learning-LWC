/***
    AddressValidationTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the unit tests for AddressValidationClass.
                   AddressValidation is tested for Account and Contact objects.
                   Test cases are written for Single uploads and Bulk uploads.
                   The use cases that are covered are : 
                   1.  (POSITIVE) Single record "Address Validation" for "Account" and "Contact"
                   2.  (POSITIVE) Bulk records(200) "Address Validation" for "Account" and "Contact"
                   3.  (NEGATIVE) "Account.Billing" Address is mandatory.
                   4.  (NEGATIVE) Country fields are Mandatory if any of the other fields are filled.
                   5.  (NEGATIVE) The country should be a valid from the list of maintained countries.
                   6.  (NEGATIVE) Within the selected country, if CheckState checkbox is checked, then a state cannot be empty.
                   7.  (NEGATIVE) Within the selected country, if CheckState checkbox is checked, then a valid state should be entered.
                   8.  (POSITIVE) Street is defaulted to 'TBD', if any of the other fields are filled.
                   9.  (POSITIVE) City is defaulted to 'TBD', if any of the other fields are filled. 
                   10. (POSITIVE) Street and City are not defaulted to 'TBD', when all address fields are empty.
                   11. (NEGATIVE) No user should be able to enter more than 3 lines in the street field
                   12. (POSITIVE) Validation Override option bypasses Address Validation.
---------------------------
Ali KM                20/09/10          CR 798276 PDRA Update & CR 734770 Automate Account Reassignment - Next Steps 
                                        - After adding Code for these CRs, Tests failed on due to 'Script Limits Maxed' Errors. 
                                          As a result reduced Bulk Inserts from 200 to 150 in BulkAccountTests_Positive()     
Vinayendra T N        21/1/11           CR 919522 Developments related to PRM
                                        Added the test cases new address validation added on Opportunities for Partners
                                        The test cases added are :
                                           1.  (POSITIVE) Single record "Address Validation" for "Opportunities"
                                           2.  (POSITIVE) Bulk records(200) "Address Validation" for "Opportunities"
                                           3.  (NEGATIVE) Country fields are Mandatory if any of the other fields are filled.
                                           4.  (NEGATIVE) The country should be a valid from the list of maintained countries.
                                           5.  (NEGATIVE) Within the selected country, if CheckState checkbox is checked, then a state cannot be empty.
                                           6.  (NEGATIVE) Within the selected country, if CheckState checkbox is checked, then a valid state should be entered.
                                           7.  (POSITIVE) Street is defaulted to 'TBD', if any of the other fields are filled.
                                           8.  (POSITIVE) City is defaulted to 'TBD', if any of the other fields are filled. 
                                           9.  (POSITIVE) Street and City are not defaulted to 'TBD', when all address fields are empty.
                                           10. (POSITIVE) Validation Override option bypasses Address Validation.  
                                                                              
Vinayendra T N        06/06/11          CR 1121880 Update fields from text fields to picklist
                                            - Commenting out validation rule for Oppty. 
*/
@isTest(seeAllData = false)
private class AddressValidationTestClass 
{
    /**
      AccountTests_Positive()
      - Positive tests for AddressValidation on Account object.
     */
    static User partner;
    /* static{
       utilTestClass.insertCustomSettings();
       }*/
    static testmethod void AccountTests_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = 'TestAccount';
            Account acc = utilTestClass.CreateAccount('Test Accounthdhdfdfg');
            // Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming'; 
            // End Modified By Chandra For CR 693820           
            acc.BillingCountry = 'USA';
            acc.BillingState = 'NY';
            acc.BillingCity = 'Buffalo';
            acc.BillingStreet = 'Line1 \r\n Line2';
            acc.BillingPostalCode ='98789';
            acc.ShippingCountry = 'Canada';
            acc.ShippingState = 'AB';
            acc.ShippingCity = 'Whitehorse';
            acc.ShippingStreet = 'Line1 \r\n Line2';        
            acc.website='www.webadd.com';
            insert acc;
        }
    }
    /**
      ContactTests_Positive()
      - Positive tests for AddressValidation on Contact object.
     */ 
    static testmethod void ContactTests_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');
            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            //End Modified By Chandra For CR 693820
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acc.ShippingCountry = 'India';
            acc.ShippingState = 'Goa';
            acc.website='www.managep.com';
            insert acc;
            /*Contact con = new Contact();
              con.FirstName = '__ Test First';
              con.LastName = 'TestContact';*/
            Contact con = utilTestClass.CreateContact('__ Test First','TestContact');
            con.AccountId = acc.Id;
            con.MailingCountry = 'USA';
            con.MailingState = 'NY';
            con.MailingCity = 'Buffalo';
            con.MailingStreet = 'Line1 \r\n Line2';
            con.OtherCountry = 'Canada';
            con.OtherState = 'YK';
            con.OtherCity = 'Whitehorse';
            con.OtherStreet = 'Line1 \r\n Line2';       
            insert con;
        }
    }
    /**
      OpptyTests_Positive()
      - Positive tests for AddressValidation on Opportunity object.
     */ 
    /*static testmethod void OpptyTests_Positive()
      {
    //init();
    List<User> PartnerUsers=PRM_opportunity.createPartnerUsers(1,null);
    partner=PartnerUsers[0];
    system.runAs(partner)
    {
    Opportunity opp = new Opportunity();
    opp.Name = 'TestOpportunity';
    opp.StageName = '1-Create';
    opp.End_Customer_Country__c = 'USA';
    opp.End_Customer_State__c = 'NY';
    opp.End_Customer_City__c = 'Buffalo';
    opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';    
    opp.CloseDate= Date.today();
    insert opp;
    }
    }*/
    /**
      BulkAccountTests_Positive()
      - Positive tests for Address validation on  Bulk Insert of Accounts.
     */ 
    static testmethod void BulkAccountTests_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // old value = 200
            Account[] BulkAccounts = new Account[5];
            Integer count;


            // old value = 200
            for(count=0;count<5;count++)
            {
                //BulkAccounts[count] = new Account();
                //BulkAccounts[count].Name = '__ Test Account' + count;
                BulkAccounts[count] = utilTestClass.CreateAccount('__Test AccountVVV' + count + 'KKK');

                //Start Modified By Chandra For CR 693820
                BulkAccounts[count].Vertical__c = 'Gaming';
                //End Modified By Chandra For CR 693820 
                BulkAccounts[count].Sub_Vertical__c = 'Console Mfs';            
                BulkAccounts[count].BillingCity = 'Buffalo';
                BulkAccounts[count].BillingStreet = 'Street1';
                BulkAccounts[count].BillingState = 'NY';
                BulkAccounts[count].BillingPostalCode = '99998';
                BulkAccounts[count].BillingCountry = 'USA';
                BulkAccounts[count].ShippingCity = 'WhiteHorse';
                BulkAccounts[count].ShippingStreet = 'Street1';
                BulkAccounts[count].ShippingState = 'BC';
                BulkAccounts[count].ShippingPostalCode = '9999-9999';
                BulkAccounts[count].ShippingCountry = 'Canada';
                BulkAccounts[count].AKAM_Account_ID__c = 'AKA'+count+'MAI'+count+'TECH';
                BulkAccounts[count].website='www.bulkweb.com'; 
            }   
            Test.startTest();   
            insert BulkAccounts;
            Test.stopTest();
        }
    }       
    /**
      BulkContactTests_Positive()
      - Positive tests for Address validation on  Bulk Insert of Contacts.
     */ 
    static testmethod void BulkContactTests_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            //End Modified By Chandra For CR 693820     
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.BillingState = 'NY';
            acc.BillingCity = 'Buffalo';
            acc.BillingStreet = 'Line1 \r\n Line2';
            acc.ShippingCountry = 'Canada';
            acc.ShippingState = 'MB';
            acc.ShippingCity = 'Whitehorse';
            acc.website='www.testaddress.com';
            acc.ShippingStreet = 'Line1 \r\n Line2';        
            insert acc;
            Contact[] BulkContacts = new Contact[5];
            Integer count;
            for(count=0;count<5;count++)
            {
                /*BulkContacts[count] = new Contact();
                  BulkContacts[count].FirstName = '__ Test First' + count;
                  BulkContacts[count].LastName = 'Test Account ' + count;*/
                BulkContacts[count] = utilTestClass.CreateContact('__ Test First' + count,'Test Account' + count);
                BulkContacts[count].Email = 'testytest'+count+'@testing.com';
                BulkContacts[count].AccountId = acc.Id;
                BulkContacts[count].MailingCity = 'Buffalo';
                BulkContacts[count].MailingStreet = 'Street1';
                BulkContacts[count].MailingState = 'NY';
                BulkContacts[count].MailingPostalCode = '99990';
                BulkContacts[count].MailingCountry = 'USA';
                BulkContacts[count].OtherCity = 'WhiteHorse';
                BulkContacts[count].OtherStreet = 'Street1';
                BulkContacts[count].OtherState = 'NT';
                BulkContacts[count].OtherPostalCode = '9999-9999';
                BulkContacts[count].OtherCountry = 'Canada';
                //Start Modified By Chandra For CR 693820
                //BulkContacts[count].Akamai_Vertical__c = 'Gaming';
                //End Modified By Chandra For CR 693820
                //BulkContacts[count].Sub_Vertical__c = 'Console Mfs';            
            }       
            Test.startTest();
            insert BulkContacts;
            Test.stopTest();
        }
    }   
    /**
      BulkOpptyTests_Positive()
      - Positive tests for Address validation on  Bulk Insert of Opportunity.
     */ 
    /*static testmethod void BulkOpptyTests_Positive()
      {
    // old value = 200
    Opportunity[] BulkOpptys = new Opportunity[150];
    Integer count;
    List<User> PartnerUsers=PRM_opportunity.createPartnerUsers(1,null);
    partner=PartnerUsers[0];
    system.runAs(partner)
    {
    // old value = 200
    for(count=0;count<150;count++)
    {
    BulkOpptys[count] = new Opportunity();
    BulkOpptys[count].Name = 'TestOpportunity'+ count;
    BulkOpptys[count].StageName = '1-Create';
    BulkOpptys[count].End_Customer_Country__c = 'USA';
    BulkOpptys[count].End_Customer_State__c = 'NY';
    BulkOpptys[count].End_Customer_City__c = 'Buffalo';
    BulkOpptys[count].End_Customer_Street_Address__c = 'Line1 \r\n Line2';  
    BulkOpptys[count].CloseDate= Date.today();
    }   
    Test.startTest();   
    insert BulkOpptys;
    Test.stopTest();
    }
    }   */
    /**
      AccountDefaults_Positive()
      - Tests the defaulting of Street and City.
      - When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
     */
    static testMethod void AccountDefaults_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ Test ConAccount ';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            acc.BillingCountry= 'India';
            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            acc.website='www.addvalidate.com';
            //End Modified By Chandra For CR 693820
            insert acc;
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;      
            // When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
            acc.BillingCity = null;
            acc.BillingStreet = null;
            acc.BillingState = 'Delhi';
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'India';
            acc.ShippingCity = null;
            acc.ShippingStreet = null;
            acc.ShippingState = null;
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = null;
            update acc;     
            Account testAcc = [select Id,BillingCity,BillingStreet,ShippingCity,ShippingStreet from Account where Id=:acc.Id][0];
            system.assertEquals(testAcc.BillingCity,'TBD');
            system.assertEquals(testAcc.BillingStreet,'TBD');
            system.assertEquals(testAcc.ShippingCity,null);
            system.assertEquals(testAcc.ShippingStreet,null);   
        }
    }
    /**
      AccountDefaults2_Positive()
      - Tests the defaulting of Street and City.
      - Street is defaulted to 'TBD', if any other field is filled
      - City is defaulted to 'TBD', if any other field is filled
     */ 
    static testmethod void AccountDefaults2_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__Test Account';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            //End Modified By Chandra For CR 693820
            // Street is defaulted to 'TBD', if any other field is filled
            acc.BillingCity = 'City1';
            acc.BillingStreet = null;
            acc.BillingState = 'NY';
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.ShippingCity = 'City2';
            acc.ShippingStreet = null;
            acc.ShippingState = 'NT';
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'Canada';
            acc.website='www.google.com';
            insert acc;
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;  
            Account testAcc = [select Id,BillingCity,BillingStreet,ShippingCity,ShippingStreet from Account where Id=:acc.Id][0];
            system.assertEquals(testAcc.BillingCity,'City1');
            system.assertEquals(testAcc.BillingStreet,'TBD');
            // City is defaulted to 'TBD', if any other field is filled
            acc.BillingCity = null;
            acc.BillingStreet = 'Street1';
            acc.BillingState = 'NY';
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.ShippingCity = null;
            acc.ShippingStreet = 'Street2';
            acc.ShippingState = 'NT';
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'Canada';
            update acc;
            testAcc = [select Id,BillingCity,BillingStreet,ShippingCity,ShippingStreet from Account where Id=:acc.Id][0];
            //system.assertEquals(testAcc.BillingCity,'TBD');       
        }
    }
    /**
      ContactsDefaults_Positive()
      - Tests the defaulting of Street and City.
      - When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
     */
    static testmethod void ContactsDefaults_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            //End Modified By Chandra For CR 693820
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acc.ShippingCountry = 'India';
            acc.ShippingState = 'KERALA';
            acc.website='www.akasecure.com';
            insert acc;     
            /*Contact con = new Contact();
              con.AccountId = acc.Id;
              con.FirstName = '__ Test First';
              con.LastName = '__ TestContact';
              con.Akamai_Vertical__c = 'Gaming';
              con.Sub_Vertical__c = 'Console Mfs';  
              con.MailingCountry = 'India';*/
            Contact con = utilTestClass.CreateContact('__ Test First','__TestContact');
            con.AccountId = acc.Id;     
            insert con;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true; 
            // When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
            con.MailingCity = null;
            con.MailingStreet = null;
            con.MailingState = null;
            con.MailingPostalCode = null;
            con.MailingCountry = 'India';
            con.OtherCity = null;
            con.OtherStreet = null;
            con.OtherState = null;
            con.OtherPostalCode = null;
            con.OtherCountry = null;
            update con;             
            Contact testCon = [select Id,MailingCity,MailingStreet,OtherCity,OtherStreet from Contact where Id=:con.Id][0];
            system.assertEquals(testCon.MailingCity,'TBD');
            system.assertEquals(testCon.MailingStreet,'TBD');
            system.assertEquals(testCon.OtherCity,null);
            system.assertEquals(testCon.OtherStreet,null);          
        }
    }
    /**
      ContactsDefaults2_Positive()
      - Tests the defaulting of Street and City.
      - Street is defaulted to 'TBD', if any other field is filled
      - City is defaulted to 'TBD', if any other field is filled
     */ 
    static testmethod void ContactsDefaults2_Positive()
    {   
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            acc.website='www.samvalid.com';
            //End Modified By Chandra For CR 693820
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acc.ShippingCountry = 'India';
            acc.ShippingState = 'HARYANA';
            insert acc;     
            /*Contact con = new Contact();
              con.AccountId = acc.Id;
              con.FirstName = '__ Test First';
              con.LastName = '__ TestContact';*/
            Contact con = utilTestClass.CreateContact('__ Test First','__ TestContact');
            con.AccountId = acc.Id;
            // Street is defaulted to 'TBD', if any other field is filled
            con.MailingCity = 'City1';
            con.MailingStreet = null;
            con.MailingState = 'NY';
            con.MailingPostalCode = null;
            con.MailingCountry = 'USA';
            con.OtherCity = 'City2';
            con.OtherStreet = null;
            con.OtherState = 'NT';
            con.OtherPostalCode = null;
            con.OtherCountry = 'Canada';
            //con.Akamai_Vertical__c = 'Gaming';
            //con.Sub_Vertical__c = 'Console Mfs';    
            insert con;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            Contact testCon = [select Id,MailingCity,MailingStreet,OtherCity,OtherStreet from Contact where Id=:con.Id][0];
            system.assertEquals(testCon.MailingStreet,'TBD');
            // City is defaulted to 'TBD', if any other field is filled
            con.MailingCity = null;
            con.MailingStreet = 'Street1';
            con.MailingState = 'NY';
            con.MailingPostalCode = null;
            con.MailingCountry = 'USA';
            con.OtherCity = null;
            con.OtherStreet = 'Street2';
            con.OtherState = 'NT';
            con.OtherPostalCode = null;
            con.OtherCountry = 'Canada';
            //con.Akamai_Vertical__c = 'Gaming';
            //con.Sub_Vertical__c = 'Console Mfs';        
            update con;
            testCon = [select Id,MailingCity,MailingStreet,OtherCity,OtherStreet from Contact where Id=:con.Id][0];     
            system.assertEquals(testCon.MailingCity,'TBD');
             // SFDC-1255 
            con.MailingCountry = null;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            update con;
            testCon = [select Id,MailingCountry from Contact where Id=:con.Id][0]; 
            system.assertEquals(testCon.MailingCountry,'TBD');
        }
    }   
    /**
      OpportunityDefaults_Positive()
      - Tests the defaulting of Street and City.
      - When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
     */
    /*static testMethod void OpportunityDefaults_Positive()
      {
      List<User> PartnerUsers=PRM_opportunity.createPartnerUsers(1,null);
      partner=PartnerUsers[0];
      system.runAs(partner)
      {
      Opportunity opp = new Opportunity();
      opp.Name = 'TestOpportunity';
      opp.StageName = '1-Create';
      opp.End_Customer_Country__c = 'India';
      opp.CloseDate= Date.today();
      insert opp;
      AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;        
    // When all fileds are empty, then 'Street' and 'City' are not defaulted, else - they are defaulted to 'TBD'
    opp.End_Customer_State__c = null;
    opp.End_Customer_City__c = null;
    opp.End_Customer_Street_Address__c = null;
    opp.End_Customer_Country__c = 'india';
    update opp;     
    Opportunity testOpp = [select Id,End_Customer_City__c,End_Customer_Street_Address__c from Opportunity where Id=:opp.Id][0];
    system.assertEquals(testOpp.End_Customer_City__c,'TBD');
    system.assertEquals(testOpp.End_Customer_Street_Address__c,'TBD');
      }
      }*/
    /**
      AccountTests_Negative()
      - Negative tests for AddressValidation on Account object.
     */     
    static testmethod void AccountTests_Negative()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            //End Modified By Chandra For CR 693820
            acc.BillingCountry= 'India';
            acc.website='www.address.com';
            insert acc;     
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;  
            // Billing Address is mandatory.
            acc.BillingCity = null;
            acc.BillingStreet = null;
            acc.BillingState = null;
            acc.BillingPostalCode = null;
            acc.BillingCountry = null;
            acc.ShippingCity = null;
            acc.ShippingStreet = null;
            acc.ShippingState = null;
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = null;
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                //system.assert(e.getMessage().contains('Country is required for Primary Address'));
            }       
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;
            // Country fields are Mandatory if any of the other fields are filled.
            acc.BillingCity = 'City1';
            acc.BillingStreet = 'Street1';
            acc.BillingState = 'State1';
            acc.BillingPostalCode = '9999-9999';
            acc.BillingCountry = null;
            acc.ShippingCity = 'City1';
            acc.ShippingStreet = 'Street1';
            acc.ShippingState = 'State1';
            acc.ShippingPostalCode = '9999-9999';
            acc.ShippingCountry = null;
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Country field is mandatory. Please review "List of valid countries and states" link under FAQ'));
            }
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;
            // The country should be a valid from the list of maintained countries.
            acc.BillingCity = null;
            acc.BillingStreet = null;
            acc.BillingState = null;
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'WrongCountry';
            acc.ShippingCity = null;
            acc.ShippingStreet = null;
            acc.ShippingState = null;
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'WrongCountry';
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Please enter a valid country.'));
                system.assert(e.getMessage().contains('Please review "List of valid countries and states" link under FAQ'));
            }
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;
            // Within the selected country, if CheckState checkbox is checked, then a state cannot be empty.
            acc.BillingCity = 'City1';
            acc.BillingStreet = 'Street1';
            acc.BillingState = null;
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.ShippingCity = 'City2';
            acc.ShippingStreet = 'Street2';
            acc.ShippingState = null;
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'Canada';
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('State is mandatory for the selected Country. Please review "List of valid countries and states" link under FAQ'));
            }       
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;
            // Within the selected country, if CheckState checkbox is checked, then a valid state should be entered.
            acc.BillingCity = 'City1';
            acc.BillingStreet = 'Street1';
            acc.BillingState = 'WrongState';
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.ShippingCity = 'City2';
            acc.ShippingStreet = 'Street2';
            acc.ShippingState = 'WrongState';
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'Canada';
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Please enter a valid state for the selected country. Please review "List of valid countries and states" link under FAQ'));
            }   
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = true;
            // No user should be able to enter more than 3 lines in the street field
            acc.BillingCity = 'City1';
            acc.BillingStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
            acc.BillingState = 'NY';
            acc.BillingPostalCode = null;
            acc.BillingCountry = 'USA';
            acc.BillingPostalCode ='98789';
            acc.ShippingCity = 'City2';
            acc.ShippingStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
            acc.ShippingState = 'YK';
            acc.ShippingPostalCode = null;
            acc.ShippingCountry = 'Canada';
            try
            {
                update acc;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Street field can accept a maximum of 3 lines'));
            }
        }
    }
    /**
      ContactTests_Negative()
      - Negative tests for AddressValidation on Contact object.
     */         
    static testmethod void ContactTests_Negative()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = new Account();
            //acc.Name = '__ TestAccount';
            Account acc = utilTestClass.CreateAccount('__ TestAccount');

            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acc.ShippingCountry = 'India';
            acc.ShippingState = 'Karnataka';
            //Start Modified By Chandra For CR 693820
            acc.Vertical__c = 'Gaming';
            acc.website='www.addtesvali.com';
            //End Modified By Chandra For CR 693820
            insert acc;     
            /*Contact con = new Contact();
              con.AccountId = acc.Id;
              con.FirstName = '__ Test First';
              con.LastName = 'TestContact';
              con.Akamai_Vertical__c = 'Gaming';
              con.Sub_Vertical__c = 'Console Mfs';
              con.MailingCountry = 'India';*/
            Contact con = utilTestClass.CreateContact('__ Test First','__ TestContact');
            con.AccountId = acc.Id;
            insert con;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            // Country fields are Mandatory if any of the other fields are filled.
            con.MailingCity = 'City1';
            con.MailingStreet = 'Street1';
            con.MailingState = 'State1';
            con.MailingPostalCode = '9999-9999';
            con.MailingCountry = null;
            con.OtherCity = 'City1';
            con.OtherStreet = 'Street1';
            con.OtherState = 'State1';
            con.OtherPostalCode = '9999-9999';
            con.OtherCountry = null;
            try
            {
                update con;
            }
            catch(DmlException e)
            {
                //SFDC-155
                //system.assert(e.getMessage().contains('Country field is mandatory.'));
                system.assert(e.getMessage().contains('Please review "List of valid countries and states" link under FAQ'));
            }
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            // The country should be a valid from the list of maintained countries.
            con.MailingCity = null;
            con.MailingStreet = null;
            con.MailingState = null;
            con.MailingPostalCode = null;
            con.MailingCountry = 'WrongCountry';
            con.OtherCity = null;
            con.OtherStreet = null;
            con.OtherState = null;
            con.OtherPostalCode = null;
            con.OtherCountry = 'WrongCountry';
            try
            {
                update con;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Please enter a valid country.'));
                system.assert(e.getMessage().contains('Please review "List of valid countries and states" link under FAQ'));
            }
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            // Within the selected country, if CheckState checkbox is checked, then a state cannot be empty.
            con.MailingCity = 'City1';
            con.MailingStreet = 'Street1';
            con.MailingState = null;
            con.MailingPostalCode = null;
            con.MailingCountry = 'USA';
            con.OtherCity = 'City2';
            con.OtherStreet = 'Street2';
            con.OtherState = null;
            con.OtherPostalCode = null;
            con.OtherCountry = 'Canada';
            try
            {
                update con;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('State is mandatory for the selected Country. Please review "List of valid countries and states" link under FAQ'));
            }   
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true; 
            // Within the selected country, if CheckState checkbox is checked, then a valid state should be entered.
            con.MailingCity = 'City1';
            con.MailingStreet = 'Street1';
            con.MailingState = 'WrongState';
            con.MailingPostalCode = null;
            con.MailingCountry = 'USA';
            con.OtherCity = 'City2';
            con.OtherStreet = 'Street2';
            con.OtherState = 'WrongState';
            con.OtherPostalCode = null;
            con.OtherCountry = 'Canada';
            try
            {
                update con;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Please enter a valid state for the selected country. Please review "List of valid countries and states" link under FAQ'));
            }
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = true;
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = true;
            // No user should be able to enter more than 3 lines in the street field
            con.MailingCity = 'City1';
            con.MailingStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
            con.MailingState = 'NY';
            con.MailingPostalCode = null;
            con.MailingCountry = 'USA';
            con.OtherCity = 'City2';
            con.OtherStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
            con.OtherState = 'YK';
            con.OtherPostalCode = null;
            con.OtherCountry = 'Canada';
            try
            {
                update con;
            }
            catch(DmlException e)
            {
                system.assert(e.getMessage().contains('Street field can accept a maximum of 3 lines'));
            }
        }
    }
    /**
      OpportunityTests_Negative()
      - Negative tests for AddressValidation on Opportunity object.
     */     
    /*static testmethod void OpportunityTests_Negative()
      {
      Opportunity opp = new Opportunity();
      opp.Name = 'TestOpportunity';
      opp.StageName = '1-Create';
      opp.End_Customer_Country__c = 'india';
      opp.CloseDate= Date.today();
      insert opp;       
      AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;        
    // Billing Address is mandatory.
    opp.End_Customer_State__c = null;
    opp.End_Customer_City__c = null;
    opp.End_Customer_Street_Address__c = null;
    opp.End_Customer_Country__c = null;
    try
    {
    update opp;
    }
    catch(DmlException e)
    {
    system.assert(e.getMessage().contains('Country is required for Primary Address'));
    }       
    AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;      
    // Country fields are Mandatory if any of the other fields are filled.
    opp.End_Customer_City__c = 'City1';
    opp.End_Customer_Street_Address__c = 'Street1';
    opp.End_Customer_State__c = 'State1';
    opp.End_Customer_Country__c = null;
    try
    {
    update opp;
    }
    catch(DmlException e)
    {
    system.assert(e.getMessage().contains('Country field is mandatory. Please review "List of valid countries and states" link under FAQ'));
    }
    AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;  
    // The country should be a valid from the list of maintained countries.
    opp.End_Customer_State__c = null;
    opp.End_Customer_City__c = null;
    opp.End_Customer_Street_Address__c = null;
    opp.End_Customer_Country__c = 'Wrong Country';
    try
    {
    update opp;
    }
    catch(DmlException e)
    {
    system.assert(e.getMessage().contains('Please enter a valid country.'));
    system.assert(e.getMessage().contains('Please review "List of valid countries and states" link under FAQ'));
    }
    AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;  
    // Within the selected country, if CheckState checkbox is checked, then a state cannot be empty.
    opp.End_Customer_State__c = null;
    opp.End_Customer_City__c = null;
    opp.End_Customer_Street_Address__c = null;
    opp.End_Customer_Country__c = 'USA';
    try
    {
    update opp;
    }
    catch(DmlException e)
    {
    system.assert(e.getMessage().contains('State is mandatory for the selected Country. Please review "List of valid countries and states" link under FAQ'));
    }       
    AddressValidationClass.CallValidateAddressFirstRunFlag_Opportunity = true;  
    // Within the selected country, if CheckState checkbox is checked, then a valid state should be entered.
    opp.End_Customer_State__c = 'wrong state';
    opp.End_Customer_City__c = 'city1';
    opp.End_Customer_Street_Address__c = 'street1';
    opp.End_Customer_Country__c = 'USA';
    try
    {
        update opp;
    }
    catch(DmlException e)
    {
        system.assert(e.getMessage().contains('Please enter a valid state for the selected country. Please review "List of valid countries and states" link under FAQ'));
    }   
}*/
/**
  AccountValidationOverride_Positive()
  - Positive tests for AddressValidation Override on Account object.
 */
static testmethod void AccountValidationOverride_Positive()
{
    System.runAs(utilTestClass.getTestRunUser())
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        //Account acc = new Account();
        //acc.Name = '__ TestAccount';
        Account acc = utilTestClass.CreateAccount('__ TestAccount');

        acc.BillingCountry = 'WrongCountry';
        acc.BillingState = 'WrongState';
        acc.BillingCity = null;
        acc.BillingStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
        acc.ShippingCountry = 'WrongCountry';
        acc.ShippingState = 'WrongState';
        acc.ShippingCity = 'Whitehorse';
        acc.ShippingStreet = null;
        acc.Validation_Override__c = true;
        acc.website='www.hpe.com';  
        insert acc;
        // Refresh Account
        acc = [select Validation_Override__c from Account where Id=:acc.Id][0];
        // Cleared by Workflow
        system.assertEquals(acc.Validation_Override__c, false);
    }
}
/**
  ContactValidationOverride_Positive()
  - Positive tests for AddressValidation Override on Contact object.
 */ 
static testmethod void ContactValidationOverride_Positive()
{
    System.runAs(utilTestClass.getTestRunUser())
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        //Account acc = new Account();
        //acc.Name = '__ TestAccount';
        Account acc = utilTestClass.CreateAccount('__ TestAccount');

        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.BillingCountry = 'India';
        acc.BillingState = 'Delhi';
        acc.ShippingCountry = 'India';
        acc.ShippingState = 'Delhi';
        acc.website='www.accountadd.com';
        insert acc;
        /*Contact con = new Contact();
          con.Akamai_Vertical__c = 'Gaming';
          con.Sub_Vertical__c = 'Console Mfs';
          con.FirstName = '__ Test First';      
          con.LastName = 'TestContact';*/
        Contact con = utilTestClass.CreateContact('__ Test First','__ TestContact');
        con.AccountId = acc.Id;
        con.MailingCountry = 'WrongCountry';
        con.MailingState = 'WrongState';
        con.MailingCity = null;
        con.MailingStreet = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
        con.OtherCountry = 'WrongCountry';
        con.OtherState = 'WrongState';
        con.OtherCity = 'Whitehorse';
        con.OtherStreet = null;
        con.Validation_Override__c = true;      
        insert con;
        // Refresh Contact
        con = [select Validation_Override__c from Contact where Id=:con.Id][0];
        // Cleared by Workflow
        system.assertEquals(con.Validation_Override__c, false);
    }
}   
/**
  OpportunityValidationOverride_Positive()
  - Positive tests for AddressValidation Override on Opportunity object.
 */
/*static testmethod void OpportunityValidationOverride_Positive()
  {
  Opportunity opp = new Opportunity();
  opp.Name = '__ TestAccount';
  opp.End_Customer_Country__c  = 'WrongCountry';
  opp.End_Customer_State__c  = 'WrongState';
  opp.End_Customer_City__c = null;
  opp.StageName = '1-Create';
  opp.CloseDate= Date.today();
  opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
  opp.Validation_Override__c = true;    
  insert opp;
// Refresh Account
opp = [select Validation_Override__c from Opportunity where Id=:opp.Id][0];
// Cleared by Workflow
system.assertEquals(opp.Validation_Override__c, false);
}*/

static testmethod void ACRAddressValidation()
  {
  Account_Creation_Request__c ACR = new Account_Creation_Request__c();
  ACR.Account_Name__c = '__ TestAcc00';
  ACR.country__c  = 'INDIA';
  ACR.State__c  = 'Odisha';
  
  ACR.Website__c = 'www.google.com';
  //ACR.CloseDate= Date.today();
  //ACR.End_Customer_Street_Address__c = 'Line1 \r\n Line2 \r\n Line3 \r\n Line4 \r\n Line5';
  ACR.Validation_Override__c = true;    
  insert ACR;
// Refresh Account
//opp = [select Validation_Override__c from Opportunity where Id=:opp.Id][0];
// Cleared by Workflow
//system.assertEquals(opp.Validation_Override__c, false);
}
}