/***
    BatchableUpdateContactOwnerTest
    @version 1.0
    @author : Ali KM <mohkhan@akamai.com>   
    @Description : This class implements test cases for BatchableUpdateContactOwner class.
    @History
    --Developer           --Date            --Change
    Ali KM                31/10/2011        CR 1327133 Bug: Inactive User Contact owner update fails for bulk records.
    Ruchika Sharma        14/01/2015        Check code error: with DUPLICATE_VALUE, duplicate value found: AKAM_Contact_ID__c.
                                            --> made class from seeAlldata = true to seeAllData=false and inserted required custom settings.
*/
@isTest(SeeAllData = false)
private class BatchableUpdateContactOwnerTest 
{

    /**
      CreateUser()
      - Return a new User with selected Alias, Profile and Role
     */
    /*private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
      {
      Profile pr = [select Id from Profile where Name=:pProfile][0];
      UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
      User newUser = new User(alias = pUsrAlias, 
      email=pUsrAlias+'@akamai.com',
      emailencodingkey='UTF-8', 
      lastname=pUsrAlias, 
      languagelocalekey='en_US',
      localesidkey='en_US', 
      timezonesidkey='America/Los_Angeles', 
      username=pUsrAlias+'@akamai.com.tclass',
      profileid = pr.Id, 
      UserRoleId = role.Id );
      return newUser;     
      }*/

    /*private static Account CreateAccount(String pAccName)
      {
      Account accOld = new Account();
      accOld.Name = pAccName;
      accOld.BillingCountry = 'India';
    //Start Modified By Chandra For CR 693820
    accOld.Vertical__c = 'Gaming';
    //End Modified By Chandra For CR 693820
    accOld.Sub_Vertical__c = 'Console Mfs';         
    return accOld;
      }
     */
    /*
       private static Contact CreateContact(String FirstName,String LastName, Id Owner)
       {
       Contact con = new Contact();
       con.FirstName = FirstName;
       con.LastName = LastName;
       con.Akamai_Vertical__c = 'Gaming';
       con.Sub_Vertical__c = 'Console Mfs';
       con.Phone = '99999';
       con.Email = 'Testing@Testing.com';
       con.Title = 'Tester';   
       con.MailingCountry = 'India';
       con.OwnerId = Owner;
       return con;
       }*/


      static{
        List<String> listOfCustomSettings = new List<String>();
        listOfCustomSettings.add('Communities_Settings');
        listOfCustomSettings.add('Features_Toggle');
        listOfCustomSettings.add('GSM_Custom_Settings');
        listOfCustomSettings.add('UserTriggerClassSettings');
        listOfCustomSettings.add('PRM_Settings');
        listOfCustomSettings.add('Address_Validation_Class_Settings');
        listOfCustomSettings.add('Account_Reassignment_Settings');
        listOfCustomSettings.add('Sync_To_Siebel_Fields_Settings');
        
        
        utilTestClass.insertCustomSettings(listOfCustomSettings);
        }
    static testMethod void batchableUpdateContactOwner_Positive() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // TO DO: implement unit test
            //User accUsr = CreateUser('TST_acc', 'Sales - Rep', 'Worldwide');
            //User cntctUsr = CreateUser('TSTcntct', 'Sales - Rep', 'Worldwide');
            User accUsr = utilTestClass.CreateUser('TST_acc', 'Worldwide', 'Sales - Media');
            User cntctUsr = utilTestClass.CreateUser('TSTcntct', 'Worldwide', 'Sales - Media');
            insert accUsr;
            insert cntctUsr;

            //Account acc = CreateAccount('testAcc');
            Account acc = utilTestClass.CreateAccount('testAcc');
            acc.OwnerId = accUsr.Id;
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Console Mfs';
            insert acc;

            List<Contact> contactList = new List<Contact>();
            Contact contact;// = new Contact();
            for (integer i=0; i < 200; i++)
            {
                contact = utilTestClass.CreateContact('First'+i, 'Last'+i);
                contact.OwnerId = cntctUsr.Id;
                contact.AccountId = acc.id;
                contactList.add(contact);
            }
            insert contactList;

            Test.StartTest();
            String query = 'SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE AccountId!=null AND OwnerId =\'' + cntctUsr.Id + '\' LIMIT 200';
            BatchableUpdateContactOwner contactOwnerBatch = new BatchableUpdateContactOwner(query);
            ID batchprocessid = Database.executeBatch(contactOwnerBatch,200);
            Test.StopTest();

            System.AssertEquals(
                    database.countquery('SELECT COUNT()'
                        +' FROM Contact WHERE OwnerId=\'' + accUsr.Id + '\''),
                    200);
            
        }
    }
    
    static testMethod void batchableUpdateContactOwner_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accUsr = utilTestClass.CreateUser('TST_acc', 'Worldwide', 'Sales - Media');
            User cntctUsr = utilTestClass.CreateUser('TSTcntct', 'Worldwide', 'Sales - Media');
            insert accUsr;
            insert cntctUsr;

            Account acc = utilTestClass.CreateAccount('testAcc');
            acc.OwnerId = accUsr.Id;
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Console Mfs';
            insert acc;

            List<Contact> contactList = new List<Contact>();
            Contact contact;// = new Contact();
            for (integer i=0; i < 200; i++)
            {
                contact = utilTestClass.CreateContact('First'+i, 'Last'+i);
                contact.OwnerId = cntctUsr.Id;
                contact.AccountId = acc.id;
                contactList.add(contact);
            }
            insert contactList;
            
            Profile pr = [select id from profile where name='Chatter Free User'][0];
            User usrTst = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id);
            insert usrTst;


            Test.StartTest();
            contactList = [SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE AccountId!=null AND OwnerId =: cntctUsr.Id LIMIT 200];
            BatchableUpdateContactOwner contactOwnerBatch = new BatchableUpdateContactOwner();
            System.runAs(usrTst){
                contactOwnerBatch.execute(null,contactList);
            }
            Test.StopTest();
            
        }
    } 
    
    static testMethod void Test_CronAccountEngagementLevelBatchClass() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.StartTest();
            CronAccountEngagementLevelBatchClass btchCLass = new CronAccountEngagementLevelBatchClass();
            btchCLass.errorFlag = true;
            Account acc = utilTestClass.CreateAccount('__TestAcc');
            acc.Engagement_Level__c = 'Marketing Engaged';
            acc.Type = 'Lead';
            insert acc;
            
            Opportunity opp = utilTestClass.CreateOpportunity('TestOpp','Open');
            opp.AccountId = acc.Id;
            opp.CloseDate = System.today()+5; 
            insert opp;
            List<Account> accList = new List<Account>();
            acc = [Select Id, Engagement_Level__c, Total_No_of_Opportunities__c, Account_Status__c from Account where Id =: acc.Id];
            accList.add(acc);
            //btchCLass.execute(null,accList);
            Test.StopTest();
        }
    }
    
    static testMethod void Test_CronAccountEngagementLevelBatchClass_Negative() 
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.StartTest();
            CronAccountEngagementLevelBatchClass btchCLass = new CronAccountEngagementLevelBatchClass();
            btchCLass.errorFlag = true;
            Account acc = utilTestClass.CreateAccount('__TestAcc');
            acc.Engagement_Level__c = 'No Engagement';
            acc.Type = 'Parent Customer - Active';
            insert acc;
            
            Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo  = Schema.SObjectType.Lead.getRecordTypeInfosByName();
            Id akamaiLeadRecordTypeId = leadRecordTypeInfo.get('Akamai Lead').getRecordTypeId();
            
            Contact c = utilTestClass.CreateContact('John','Doe');
            c.AccountId = acc.Id;
            insert c;
            
            Lead lead = new Lead();
            lead.LeadSource = 'Web';
            lead.Associated_Account__c = acc.Id;
            lead.Associated_Contact__c = c.Id;
            lead.RecordTypeId = akamaiLeadRecordTypeId;
            insert lead;
            
            List<Account> accList = new List<Account>();
            acc = [Select Id, Engagement_Level__c, Total_No_of_Opportunities__c, Account_Status__c from Account where Id =: acc.Id];
            accList.add(acc);
            //btchCLass.execute(null,accList);
            Database.BatchableContext BC;
            Test.StopTest();
        }
    }
}