/*---------------------------------------------------------------------------------
 * Class Name           : SC_UserTriggerClass
 * Developer Name       : Vamsee Surya S
 * Date                 : 01 June 2018
 * JIRA                 : ESESP-1069
 * Test class           : SC_Case_Trgr_EmlServc_Class_TC2


 * ---------------------- HISTORY ------------------------------ *
 * DATE             DEVELOPER       JIRA            DESCRIPTION                               
 * ===========      =========       =======         =========== 
 * 22-Jun-2020      Pinkesh         ESESP-3613      Remove the KCS Coach value on the related Users in order to deactivate the user

 ---------------------------------------------------------------------------------*/
public class SC_UserTriggerClass {
    
    /* This method will update the Chatter Email Settings of the user when user's Department is AkaTec
     * This method cannot be called in before insert because salesforce updates Userpreferencesdisablelikeemail to true while inserting. (ESESP-1069)
     */
    public static void updateUserChatterSettings(List<user> userList, boolean isAfterInsert){
        List<user> userToUpdate = new List<User>();
        for(User eachUser : userList){
            if(isAfterInsert)
                eachUser = new User(Id = eachUser.Id);
                
            eachUser.UserpreferencesdisablefollowersEmail = False; 
            eachUser.Userpreferencesdisableprofilepostemail = False;
            eachUser.Userpreferencesdisablesharepostemail = False;
            eachUser.Userpreferencesdisablelikeemail = False;
            eachUser.UserPreferencesDisProfPostCommentEmail = False;
            eachUser.UserPreferencesDisableBookmarkEmail = False;
            eachUser.UserPreferencesDisCommentAfterLikeEmail = False;
            eachUser.UserPreferencesDisMentionsCommentEmail = False;
            eachUser.UserPreferencesDisableAllFeedsEmail = False;
            eachUser.DigestFrequency = 'N';
            eachUser.UserPreferencesDisableMentionsPostEmail = False;
            eachUser.UserPreferencesDisableMessageEmail = False;
            eachUser.UserPreferencesDisableEndorsementEmail = False;
            eachUser.UserPreferencesDisableChangeCommentEmail = False;
            eachUser.UserPreferencesDisableLaterCommentEmail = False; 
                
            if(isAfterInsert)
                userToUpdate.add(eachUser);
        }
        
        //Update only when After Insert is called
        if(userToUpdate.size() > 0){
            Update userToUpdate;
        }
     }

    //Changes by Pinkesh - ESESP-3613: Remove the KCS Coach value on the related Users in order to deactivate the user
    public static void updateChildusers(Set<Id> sInactiveUser){
        //List of Child users where heirarchy field to be cleared
        List<User> lChildUser = new List<User>();

        //All the child users where one of the heirarchy field is populated
        for(User eachUser : [SELECT Id, SC_KCS_Coach__c, Delegated_Approver_custom__c, Backup_User__c FROM User WHERE SC_KCS_Coach__c in :sInactiveUser OR Delegated_Approver_custom__c in :sInactiveUser OR Backup_User__c in :sInactiveUser]){
            if(eachUser.SC_KCS_Coach__c != null || eachUser.Delegated_Approver_custom__c != null || eachUser.Backup_User__c != null){
                eachUser.SC_KCS_Coach__c = null;
                eachUser.Delegated_Approver_custom__c = null;
                eachUser.Backup_User__c = null;
                lChildUser.add(eachUser);
            }
        }

        //Updating the Hierarchy fields wil null values
        if(lChildUser.size()>0)
            update lChildUser;
        
        //future call to update KCS Entitlement records to avoid Mixed DML operation error
        updateKCSCoachOnChildusers(sInactiveUser);
    }

    @future
    public static void updateKCSCoachOnChildusers(Set<Id> sInactiveUser){
        //Delete the KCS entitlement record of the user who is getting deactivated
        List<KCS_Entitlement__c> lKCSEntitlementForDelete = new List<KCS_Entitlement__c>();
        //Clear the KCS Coach value on the related Coachees' KCS Entitlement records
        List<KCS_Entitlement__c> lKCSEntitlementForUpdate = new List<KCS_Entitlement__c>();

        for(KCS_Entitlement__c eachrec : [SELECT Id, User__c, KCS_Coach__c FROM KCS_Entitlement__c WHERE User__c IN :sInactiveUser OR KCS_Coach__c IN :sInactiveUser]){
            //Checking if this user is the deactivated user
            if(sInactiveUser.contains(eachrec.User__c)){
                lKCSEntitlementForDelete.add(eachrec);
            }
            else{
                eachrec.KCS_Coach__c = null;
                lKCSEntitlementForUpdate.add(eachrec);
            }
        }

        if(lKCSEntitlementForDelete.size() > 0)
            delete lKCSEntitlementForDelete;
        if(lKCSEntitlementForUpdate.size() > 0)
            update lKCSEntitlementForUpdate;
    }
}