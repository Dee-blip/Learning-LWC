/******

Author: Sharath Ravishankar
Created Date: 27/12/2016
Description: This is the test class written to test the whole process of provisioning and deprovisioning of licenses.
This covers the classes PSA_AutomateLicenseAssignment, CreateAndDeletePControls, PSA_LicenseDeprovisionBatch and PSA_BusinessContactUpdateBatch
CR : CR 3618691 
*/

@isTest(seeAlldata=false)
public class PSA_LicensingProcess_Test {
    
    static
    {
        PSA_LicensingProcess_Test.TestFetchData();
    }
    static String PACKAGE_NAMESPACE_PREFIX = 'pse';
    public static User testUser;
    public static User testAdminUser;
    public static Account testAccount;
    public static Contact testContact;
    public static PSA_TestUtility testUtility;
    public static list<profile> profileList;
    
    public Static void testFetchData()
    {
        testUtility = new PSA_TestUtility();
        //Creating a new user
        testUser = testUtility.newUserSysAdmin(true);
        // Creating a sys admin user to surpass Mixed DML Operation via Runas method
        testAdminUser  = testUtility.newUserSysAdmin(true);
        //Creating a new account 
        testAccount =  testUtility.newAccount(true);
        // Creating a contact
        testContact = testUtility.newResource(true, testAccount.Id, testUser.Id);
        testUser.AKAM_User_ID__c='test-00-ak';
        testUser.Email='tuser@akamai.com';
        profileList = [select Id from profile where name in ('Helpdesk Client-Chatter Only') limit 1];
        if(profileList!=NULL && profileList.size()!=0)
            {
                System.runAs(testAdminUser)
                {
                    testUser.ProfileId = profileList[0].Id;
                    update testUser;
                }
                testContact.Email=testUser.Email; 
                testContact.AKAM_Contact_ID__c = testUser.AKAM_User_ID__c; // required condition between the user and contact
                // records for providing licenses 
                update testContact;
            }
        
    }
    /*This test method invokes the process of assigning licenses and covers the class PSA_AutomateLicenseAssignment and
     PSA_CreateDeletePermissionControl. */
    
    public static testmethod void licenseProvisionTest()
    {
        test.startTest();
         System.runAs(testAdminUser)
        {
            //The contact record is deleted so as to increase the code coverage
            delete testContact;
            //Changing the profile of the user from Helpdesk chatter (non GSS) to GSS Professional Services(GSS)
            profileList = [select Id from profile where name in ('GSS Professional Services') limit 1];
            if(profileList!=NULL && profileList.size()!=0)
            {
                testUser.ProfileId = profileList[0].Id;
                update testUser;
            }
           
        }
        test.stopTest();
    }
    /*This test method tests the process of revoking of licenses and covers the class PSA_BusinessContactUpdateBatch, 
    PSA_AutomateLicenseAssignment(addRecordsToLicenseHistoryObject method is called when a license is revoked) and 
    PSA_LicenseDeprovisionBatch. */
    
     public static testmethod void licenseDeprovisionTest()
    {
        
        
     
        //Changing the profile of the user from Helpdesk chatter (non GSS) to GSS Professional Services(GSS)
        User testUser2 = testUtility.newUserSysAdmin(true);
        System.runAs(testAdminUser)
        {
        profileList = [select Id from profile where name in ('GSS Professional Services') limit 1];
            if(profileList!=NULL && profileList.size()!=0)
            {
                testUser.ProfileId = profileList[0].Id;
                update testUser;
            }

        }
        test.startTest(); 
            System.runAs(testAdminUser)
            {
            //Changing the profile of the user from GSS Professional Services(GSS) to Helpdesk chatter (non GSS)
                profileList = [select Id from profile where name in ('Helpdesk Client-Chatter Only') limit 1];
                if(profileList!=NULL && profileList.size()!=0)
                {
                    testUser.ProfileId = profileList[0].Id;
                    update testUser;
                } 
                PSA_License_DeProvisioned_User__c licenseDeprovisonUser = new PSA_License_DeProvisioned_User__c();
                licenseDeprovisonUser.License_removed__c = false;
                licenseDeprovisonUser.User__c = testUser.Id;
                insert licenseDeprovisonUser;


            }
            //calling the deprovision batch job.
            PSA_LicenseDeprovisionBatch dBatch = new PSA_LicenseDeprovisionBatch();
            Database.executeBatch(dBatch);

        test.stopTest();   
        
    }

    /*
    In this test class, userpackage license record is created before assigning the license to increase 
    the codecoverage(for the existing licenses loop)*/
   public static testmethod void licensePermissionTest()
    {
         System.runAs(testAdminUser)
        {
            //Create a record in userpackagelicense and then change the profile to GSS profile
            //List<PackageLicense> pls = new List<PackageLicense>();
            //pls = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX];  
            //if(pls != null && pls.size() == 1)
            {
                //PackageLicense pl = pls[0];          
                //UserPackageLicense uplTest = new UserPackageLicense();
                //uplTest.PackageLicenseId = pl.Id;
                //uplTest.UserId = testUser.Id;
                //Database.insert(uplTest,false);
             
                test.startTest();
                profileList = [select Id from profile where name in ('GSS Professional Services') limit 1];
                if(profileList!=NULL && profileList.size()!=0)
                    {
                        testUser.ProfileId = profileList[0].Id;
                        update testUser;
                    }
                test.stopTest();

            }        
        }
        
    }
  
}