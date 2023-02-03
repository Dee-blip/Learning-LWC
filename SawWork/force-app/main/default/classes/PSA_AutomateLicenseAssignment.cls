/******

Author: Jayalakshmi A
Created Date: 25/01/2016
Description: This is the action class for UserTrigger.cls. A new class was created since the existing action class is v16.0 and
UserPackageLicense is not available. This class assigns PSA license to the user who has been assigned a PSA Profile.

Developer                               Date                                        Reason
Sharath                                04/04/2016                               Changed the class for de-provisioning PSA License. Added the function addRecordsToLicenseHistoryObject.
*/

public class PSA_AutomateLicenseAssignment 
{
    /*The namespace prefix for Financial Force is pse. */

    static String PACKAGE_NAMESPACE_PREFIX = 'pse';
    static List<UserPackageLicense> firstUPLs = new List<UserPackageLicense>();
    public static String exceptionText {get; set;}   
    public static Database.SaveResult[] result;  
    public static Map<ID,UserPackageLicense> permissionControlUserId;  

    /****

    This function assigns PSA license to the user, creates a record in UserPackageLicense and invokes the function to 
    create or update the corresponding Contact record and create the Permission Control record. Since UserPackageLicense 
    is a Setup object, the method to create Contacts is within a future call. Setup and non setup objects cannot be updated
    in the same context.

    */
    public static void assignPSALicenseToUser(List<User> usersForPSA)
    {    
        PackageLicense pl = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status FROM PackageLicense WHERE NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX];      
        Set<Id> existingLicenses = new Set<Id>();
        List<Id> userIdsCheck = new List<Id>();
            //new variable added whcih contains the userids of the users which should be passed to postlicensing        
        List<Id> toBeAssignedIds = new List<Id>();
        
        List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();
        List<Id> successes = new List<Id>();       
        List<Id> userLicenseIds = new List<Id>();        
        List<String> firstLastName = new List<String>();
        List<Id> userIds = new List<Id>();     

        for(User user:usersForPSA)
        {
            userIdsCheck.add(user.Id);
        }  

        for(UserPackageLicense license: [select UserId from UserPackageLicense where PackageLicenseId = :pl.Id and UserId in :userIdsCheck])
        {
            existingLicenses.add(license.UserId);
        }  
       
        for (Integer i = 0; i< usersForPSA.size(); i++)
        {
            if(!existingLicenses.contains(usersForPSA[i].Id))
            {
                UserPackageLicense upl = new UserPackageLicense();
                upl.PackageLicenseId = pl.Id;
                upl.UserId = usersForPSA[i].Id;
                    //user ids are added for postlicensing
                toBeAssignedIds.add(usersForPSA[i].Id);
                firstUPLs.add(upl);
            }
        }
        
        try 
        {
          //bulk insert
          result = Database.insert(firstUPLs,false);
          for(Database.SaveResult resLicense : result)
            userLicenseIds.add(resLicense.getId());
          System.debug('userLicenseIds***!'+userLicenseIds);
          permissionControlUserId = new Map<ID,UserPackageLicense>([select ID, UserId from UserPackageLicense where Id in :userLicenseIds]);
          System.debug('****permissionControlUserId'+permissionControlUserId);
          for(UserPackageLicense upl : permissionControlUserId.values())
            userIds.add(upl.UserId);
          System.debug('userIds***'+userIds);
        } 

        /*If the licenses are not sufficient then LICENSE_LIMIT_EXCEE DED error is thrown. */
        catch(DmlException e) 
        {
             for (Integer i = 0; i < e.getNumDml(); i++) 
             {
                // process exception here 
                System.debug(e.getDmlMessage(i)); 
                String status = e.getDmlStatusCode(i);
                System.debug(status + ' ' + e.getDmlMessage(i));
                if(status.equals('LICENSE_LIMIT_EXCEEDED'))
                {
                    exceptionText = 'You tried to assign more licenses than available. ' 
                    +' You tried to create '+ firstUPLs.size()+' licenses but only have '
                    + (pl.AllowedLicenses - pl.UsedLicenses) + ' licenses free.';
                    System.debug(exceptionText);
                }
            }
        }
        //System.assertEquals(1,2);
        if(!(System.isFuture() || System.isScheduled() || System.isBatch()))
        {
            postLicenseTasks(toBeAssignedIds);
        }
        
        //System.assertEquals(1,2);
    }

    //Changes by Sharath: Added the function
    //The function addRecordsToLicenseHistoryObject, creates a record in the object PSA_License_DeProvisioned_User__c for every user whose profile changes 
    //from a PSA Profile to a non-PSA profile. The record consists of the UserID, name, email, Old and New profiles. The object has a flag called License_removed
    //which is false by default. When the batch job to revoke License runs, it picks up all the records where the flag is false, removes the license for the
    //corresponding users and sets the flag to true
    @future
    public static void addRecordsToLicenseHistoryObject (Map<String,String> UserIDToProfile)
    {
        Map<id,PSA_License_DeProvisioned_User__c> useridToDeprovisionMap = new Map<id,PSA_License_DeProvisioned_User__c>();
        List<PSA_License_DeProvisioned_User__c> insertDeprovision = new List<PSA_License_DeProvisioned_User__c>();
        PSA_License_DeProvisioned_User__c deprovisionedUser;
        //System.assertEquals(UserIDToProfile.values(),null);
        set <string> profileids= new Set<string>(UserIDToProfile.values());
        Map <id,Profile> ProfileIdToName = new Map <id,Profile>(new List<Profile>([select name from Profile where id in :profileids]));
        Map <Id,User>    UserIdToRecord = new Map <id,User>(new List<User>([select id,name,email,profile.name from user where id in :UserIDToProfile.keyset()]));
        //System.assertEquals(ProfileIdToName,null);
        //System.assertEquals(UserIdToRecord,null);

        PackageLicense pl = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX];      
        
        for(UserPackageLicense license: [select UserId from UserPackageLicense where PackageLicenseId = :pl.Id and UserId in :UserIDToProfile.keyset()])
        {
              deprovisionedUser = new PSA_License_DeProvisioned_User__c();
              deprovisionedUser.User__c = license.UserId;
              deprovisionedUser.Name__c = UserIdToRecord.get(license.UserId).name;
              deprovisionedUser.Email__c = UserIdToRecord.get(license.UserId).email;
              deprovisionedUser.Profile__c = UserIdToRecord.get(license.UserId).profile.name;
              deprovisionedUser.Old_Profile__c = ProfileIdToName.get(UserIDToProfile.get(license.UserId)).name;
              insertDeprovision.add(deprovisionedUser);
            
        }  

        try
        {
            //System.assertEquals(insertDeprovision,null);
            Database.insert(insertDeprovision,false);
            //insert insertDeprovision;
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }
 
    }
    @future
    public static void postLicenseTasks(List<Id> toBeAssignedIds)
    {
        PSA_CreateDeletePermissionControl.CreateAndDeletePControls(toBeAssignedIds);
    }
}