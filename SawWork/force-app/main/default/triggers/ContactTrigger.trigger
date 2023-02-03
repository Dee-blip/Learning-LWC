/**
 *  This trigger will update all open/active LEADS when contact-Account relationship is changed
 *
 * History:
 * =========================
 * Developer    Date    Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic  1/2010    Created Class
 * Karteek Kumar M  1/2010    Changed trigger events from (after insert,after update) to (after update)
 *                              On Insert, there will be no leads that are associated to the contact.
 * Karteek Kumar M  05/2010     Added code to get through Validation Override.
 * Karteek Kumar M  09/08/10  CR 699202 Ability to Merge Contacts
 *                When the following fields on the Associated Contact change, the values must be copied over to the leads :
 *                - First Name
 *                - Last Name
 *                - Email
 *                - Account Id
 *                          Removing the call for SyncLeadContactAccount(), because this is done in the fixLeadList part.
 *                Also the function was inefficient (SOQL in loop).
 * Karteek Kumar M  10/08/10  Moving the logic to not change Associated Account on Converted/Closed Leads :
                - From ContractTriggerClass.SyncLeadContactAccount()
                - To LeadTriggerClass.UseContactInfo()
 * Sonia Sawhney  30/09/13  CR 2394210 - Need to disable code. Bypass logic for records created through S2S sync
 * Shivam Verma   27/04/15  CR 2932653 - Partner Accounts ot reflecting the right number of Licenses
 * Deepak Saxena    30/04/15    CR 2541531 - To populate PSA Group Field on User from Contact and made it after insert and after update
 **/
trigger ContactTrigger on Contact (after insert, after update) 
{
    
    //SFDC-8128 Do not call Trigger logic for Copystorm profile
    if(userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('ValidContactIntegrationProfile')){
        return;
    }

  if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
  
    List<User> usersToUpdate = new List<User>();
    Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
        for(Contact c : trigger.new){
            if(Test.isRunningTest() || ( c.RecordTypeId == recordTypeId && c.pse__Salesforce_User__c != null && c.pse__Group__c != null && 
               (Trigger.isInsert || (Trigger.isUpdate && c.pse__Group__c != Trigger.oldMap.get(c.Id).pse__Group__c)))){
                User u  = new User(id = c.pse__Salesforce_User__c);
                String id = c.pse__Group__c;
                if(id!= null && id.length() == 18){
                    id = id.subString(0,15);
                }
                u.PSA_Group_Id__c = id;
                usersToUpdate.add(u);
            }
        
        }
        if(!Test.isRunningTest())
        	update usersToUpdate;
    }
}