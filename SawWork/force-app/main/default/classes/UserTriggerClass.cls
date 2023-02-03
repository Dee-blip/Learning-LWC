/**
    UserTriggerClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>   
    @Description : This class implements Trigger logic on "Users".
                   The following is implemented :
                    1. On before insert and before update, just copy the AKAM_User_Id value from the AutoID.
                    2. Since during insert, the autoId is not generated -> fire the trigger again through a DML-SOQL.
                    
    @History
    --Developer           --Date            --Change
    Ali KM                08/12/2010        CR 870797 Change Contact.Owner to ONA when Users turn Inactive
                                            - Added logic to change Contact Owner to Account Owner when a User is made Inactive
                                            - Added following new methods
                                                -> resetContactOwnerForInActiveUsers(Users[] inactiveUsers) 
                                                    - This method is called from UserTrigger_ai Trigger for 
                                                                                all InActive Users with Contact entries.
                                                -> setInactiveContactOwner(String[] inactiveUsersAKAMId) 
                                                    - This method is called from 'resetContactOwnerForInActiveUsers()' method
                                                                                if any records qualify for contact owner updates.
                                                -> ButtonInvoke() Webservice method
                                                    - This method is added to do timely clean-up of all such Contacts with InActive Owners
                                                    - This code is invoked from 'Contacts > Button > FixAccountContactsWithInActiveOwners'
                                                -> setUserIdSet() 
                                                    - This method fetches list of Inactive users from supplied list of User Ids.     
    Ali KM                28/12/2010        CR 870797 Change Contact.Owner to ONA when Users turn Inactive
                                            - Added email alert for contacts greater than 10000 records in 
                                                -> setInactiveContactOwner() method.    
   Chandra Lohani         15/07/2011       - Added logic to update user Activated_On date when user gets activated for CR 1184251 
   Ali KM                 3/Nov/2011        - CR 1327133 Bug: Inactive User Contact owner update fails for bulk records.
                                                -> Added logic to use Batch Apex for updating Contact Owner for InActive users when No. of Contact Records >=9900
   Ali KM                 24/Jan/2012       CR 1259743 Make Contracts: a parent-child with accounts?
                                                -> Added method: updateMCHShare, thats invoked on UserTrigger_ai_au; when deactivated user is activated.
                                                    - It pulls up all associated contracts for the user and adds share for the user directly in 'Merge_Contract_Header__Share' object.
   Ali KM                 27/Mar/2012       CR 1610815 Apex Error when creating External Chatter User - Unable to login
                                                -> Updated the Set_AKAM_User_ID_After() method, as an error was thrown while creating External Chatter users. Instead of updating the 
                                                   same list thats queried to fetch user AutoID, created a dummy list and only updating the AKAM_UserID__c in it.
   Ali KM               19/05/2012          CR 1533601 Contract Visibility: Enhancements.                                                                                                                                                                                                                                                                     
*/
global class UserTriggerClass 
{   
    //public static Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers'); //SFDC-2304
    //public static UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); //SFDC-2304
    //public static GSM_Custom_Settings__c gsmCustomSettings=GSM_Custom_Settings__c.getInstance('UserTriggerClass#TemplateId'); //SFDC-2304
    // UserTriggerClass#BatchNotifyEmail
    
    /**
      ButtonInvoke()
      - Allows setInactiveContactOwner logic to be invoked by OnClick JavaScript button
     */
    /*Webservice static String ButtonInvoke()
    {   
        //@todo: 31/oct/2011: Need to fix below logic to run batchable if record size > 9900
        // ONA Contact User CustomSettings      
        String retMessage = 'This feature is disabled!';

        if (UserTriggerClass.customSettings.Toggle__c == true)      
        {        
            String exemptedUserAlias = UserTriggerClass.userTriggerCustomSettings.exemptedUserAlias__c;                     
            List<String> allInactiveContactOwners = new List<String>();
            List<Contact> updateContactsList = [Select Owner.AKAM_User_ID__c, Owner.Alias From Contact where Owner.IsActive = false AND AccountId!=null];
            for (Contact cntct : updateContactsList)
            {
                if (cntct.Owner.AKAM_User_ID__c!=null && !exemptedUserAlias.contains(cntct.Owner.Alias))
                    allInactiveContactOwners.add(cntct.Owner.AKAM_User_ID__c);
            }   
            if (allInactiveContactOwners.size()>0)
            {                           
                L2Q_UserTriggerClass.setInactiveContactOwner(allInactiveContactOwners);
                retMessage = 'Number for Contacts updated=' + allInactiveContactOwners.size();
            }
            else
                retMessage = 'No Contacts qualify for InActive Owner change update';
        }
        return retMessage;  
    }*/
    
    //Changes by Sharath Prasanna: Added the function
    public static void changeTimecardApprover(Map<Id, User> oldMap, Map<Id, User> newMap) 
    {
        //set to store the old manager IDs
        Set<Id> oldManagerUserIds = new Set<Id>();
        //set to store the new manager IDs
        Set<Id> newManagerUserIds = new Set<Id>();
        //Map of user ID to list of old and new managers
        Map<Id,List<Id>> userIdToManagers = new Map<Id,List<Id>>();
        //Map of ID to Contact record
        Map<Id,Contact> IdToContact = new Map<Id,Contact>();
        //The PSA contact record type ID
        Id PSAResourceId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
        //Set of inactive users
        Set<Id> inactiveUsers = new Set<Id>();
        //The PSA_TimecardApproverChange object to change the timecard approver
        PSA_TimecardApproverChange timecardApproverChange;

        // Loop through the newMap
        for (Id userID: newMap.keySet())
        {   
            User u = newMap.get(userId);
            //Check if the new manager is different from the old manager
            if(u.Managerid != oldMap.get(u.Id).Managerid)
            {
                //If there is an existing entry in the map for the current user ID, then remove the entry. There are duplicate updates for the same user
                if (userIdToManagers.containsKey(u.id))
                {
                    userIdToManagers.remove(u.id);    
                }    
                //Add an entry for the current user ID
                userIdToManagers.put(u.id,new List<Id>());            
                userIdToManagers.get(u.id).add(oldMap.get(u.Id).Managerid);  
                userIdToManagers.get(u.id).add(u.Managerid);            
                //Add an entry in the oldManagerUserIds and newManagerUserIds sets.
                oldManagerUserIds.add(oldMap.get(u.Id).Managerid);
                newManagerUserIds.add(u.Managerid);
            }
            // Check for inactive user
            if(!u.IsActive && oldMap.get(u.Id).IsActive)
            {
                //Add an entry to the set inactiveUsers
                inactiveUsers.add(u.id);
            }
        }
        //Check if the map userIdToManagers is not null and has an entry
        if(userIdToManagers != null && userIdToManagers.size() > 0)
        {   
            //Query for the contact records for the users who have the manager changed   
            IdToContact = new Map<Id,Contact>([select id, pse__Salesforce_User__c,email from Contact where RecordTypeId = :PSAResourceId and pse__Salesforce_User__c in :userIdToManagers.keySet()]);

            //create a new PSA_TimecardApproverChange object. Initialize the class variables.
            timecardApproverChange = new PSA_TimecardApproverChange();
            timecardApproverChange.queryType = 'ManagerChange';
            timecardApproverChange.userIdToManagers = userIdToManagers;
            timecardApproverChange.userIds = oldManagerUserIds;
            timecardApproverChange.IdToContact = IdToContact;
            //Enqueue the object: which extends queuable interface
            System.enqueueJob(timecardApproverChange);

        }
        //Check if the inactiveUsers is not null and has an entry
        if(inactiveUsers != null && inactiveUsers.size() > 0)
        {
                //Enqueue the timecardApproverChange with the queryType equal to UserInactive
                timecardApproverChange = new PSA_TimecardApproverChange();            
                timecardApproverChange.queryType = 'UserInactive';
                timecardApproverChange.inactiveUsers = inactiveUsers;            
                System.enqueueJob(timecardApproverChange);                             

        }

    }

}