/* * Developer        Date        Description

   Nagaraj Desai    17/July/18       Added this class as part of SFDC-3601.
 **/
public class L2Q_ContactTriggerHandler extends ApexTriggerHandlerAbstractClass {
        public override void beforeInsertBeforeUpdateTrigger() {

                List<Contact> contactsTriggerNew = (List<Contact>)newList;
                List<Contact> contactsTriggerOld = (List<Contact>)oldList;
                Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
                Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;

                //SFDC-4384
                List<Contact> contactsWithMarketoAkamAccountIdChanged = new List<Contact>();
                String marketoIntegrationProfileId = GsmUtilClass.getGSMSettingValue('MarketoIntegrationProfileId');
                Id businessContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
                String WWWLeadGenAccountId = GsmUtilClass.getGSMSettingValue('ContactAssociation_WWWLeadGenAccountId');
                List<Contact> mailingAddressChangeContactList = new List<Contact>();
                List<Contact> otherAddressChangeContactList = new List<Contact>();
                Set<String> contactMailingAddressValidationFields = new Set<String>(GsmUtilClass.getGSMSettingValue('ContactMailingAddressValidationFields').split(','));
                Set<String> contactOtherAddressValidationFields = new Set<String>(GsmUtilClass.getGSMSettingValue('ContactOtherAddressValidationFields').split(','));
                List<Id> accountIdList = new List<Id>();
                for(Contact con: contactsTriggerNew) { // populate accountIdList
                        if(Trigger.isInsert) {
                                accountIdList.add(con.AccountId);
                                mailingAddressChangeContactList.add(con);
                                otherAddressChangeContactList.add(con);
                        }
                        if(Trigger.isUpdate && util.hasChanges(contactMailingAddressValidationFields, contactsTriggerOldMap.get(con.Id), con) )
                        {
                            mailingAddressChangeContactList.add(con);
                        }
                        if(Trigger.isUpdate && util.hasChanges(contactOtherAddressValidationFields, contactsTriggerOldMap.get(con.Id), con) )
                        {
                            otherAddressChangeContactList.add(con);
                        }

                }

                ContactTriggerClass.preProcessBeforeInsertUpdate(contactsTriggerNew, contactsTriggerOldMap);
                Map<Id,Account> contactAccountIdAccountMap = new Map<Id,Account>();//SFDC-4547-12
                if(accountIdList.size() > 0)//SFDC-4547-12 Existing code, needs rework
                    contactAccountIdAccountMap = new Map<Id,Account>([select Id,isPartner, Rebate_TC_Accepted_At__c,Rebate_TC_Rejected_At__c,Rebate_TC_Status__c from Account where id in:accountIdList]);

                //Start of modification CR 2919927 : rsharma
                //restrict the partner to create a contact on other account (for which partner should not have access to create account like customer account) except the account associated with partner contact or children of that account
                Id profileId = userinfo.getProfileId();
                String csProfileId = GsmUtilClass.getGSMSettingValue('ContactTrigger_ProfileRestrictAccount');
                String customError = GsmUtilClass.getGSMSettingValue('ContactTrigger_RestrictAccErr');

                If(csProfileId.contains(profileId)) {
                        ContactTriggerClass.restrictContactCreationByPartner(userInfo.getUserId());
                }                                         //SFDC-2391
                //End of modification CR 2919927

                /* Mailing Address Validation */
                if(!mailingAddressChangeContactList.isEmpty())
                {
                    AddressValidationClass.validateContactMailingAddress(mailingAddressChangeContactList);
                }
        
                /* Other Address Validation */
                if(!otherAddressChangeContactList.isEmpty())
                {
                    AddressValidationClass.validateContactOtherAddress(otherAddressChangeContactList);
                }

                /* For CRM Integration Users,use Contact.Associated AKAM Account Id to populate Contact.AccountId */
                //CR 2504208: Check whether the value of custom setting ContactTrigger#ProfileCheck, under GSM_Custom_Settings__c, contains the current User's ProfileId.
                String customSettingsContactTrigger = GsmUtilClass.getGSMSettingValue('ContactTrigger_ProfileCheck');                 //SFDC-2391
                List<Contact> AssociatedAccountIDMapList = new List<Contact>(); // End of CR 2504208

                /* CR 2841150 Detect Language for the combination of FirstName and LastName
                 */
                ContactTriggerClass.detectLanguageOnContact(contactsTriggerNew, contactsTriggerOldMap, false);

                for(Contact con: contactsTriggerNew) {

                        //SFDC-4384
                        if(Trigger.isUpdate && marketoIntegrationProfileId.contains(UserInfo.getProfileId()) && con.Active_Portal_Login__c == false && 
                        con.Marketo_AKAM_Account_ID__c != null && con.RecordTypeId == businessContactRecordTypeId && 
                        con.Marketo_AKAM_Account_ID__c != contactsTriggerOldMap.get(con.Id).Marketo_AKAM_Account_ID__c && 
                        (WWWLeadGenAccountId.contains(con.AccountId) || con.Associated_Account_Status__c == 'Lead'))
                        {
                            con.Associated_AKAM_Account_ID__c = con.Marketo_AKAM_Account_ID__c;
                        }
                        
                        if(Trigger.isInsert) {
                                Account acc = contactAccountIdAccountMap.get(con.AccountId);
                                if(acc!=null && acc.isPartner) {
                                        con = ContactTriggerClass.updateRebateField(con, acc);
                                }
                        }

                        //Start of modification CR 2919927 : rsharma
                        //check if current users profile id is present in custom setting to apply restriction for

                        if((Trigger.isInsert || (Trigger.isUpdate && con.AccountId != contactsTriggerOldMap.get(con.id).AccountId)) && (csProfileId.contains(profileId)) && (ContactTriggerClass.accHierarchyMap!=null && !ContactTriggerClass.accHierarchyMap.containsKey(con.AccountId))) {
                                //If the account associated with contact created by partner is not found in childAccs list, then its not valid account -> throw error to partner user
                                con.addError(customError);
                        } //End of modification CR 2919927

                        if(Trigger.isInsert || (!Trigger.isInsert && con.Associated_AKAM_Account_ID__c != contactsTriggerOldMap.get(con.Id).Associated_AKAM_Account_ID__c)) {
                                if(customSettingsContactTrigger.contains(profileId)) {
                                        AssociatedAccountIDMapList.add(con);
                                }
                        }

                        if(Trigger.isUpdate && con.Has_Akamai_University_Access__c != contactsTriggerOldMap.get(con.Id).Has_Akamai_University_Access__c ) {
                                if (con.Has_Akamai_University_Access__c == false) {
                                        con.Mark_for_Deactivation__c=true;
                                } else {
                                        con.Mark_for_Deactivation__c=false;
                                }
                        }

                }

                if(AssociatedAccountIDMapList.size()>0) {
                        ContactTriggerClass.AssociatedAccountIDMap(AssociatedAccountIDMapList,marketoIntegrationProfileId);
                }

                if (Trigger.isUpdate) {
                        ContactTriggerClass.updateContactMergeFields(Trigger.New);
                        // CR 2841150 Detect Language for the combination of FirstName and LastName on Update
                        ContactTriggerClass.detectLanguageOnContact(contactsTriggerNew, contactsTriggerOldMap, true);
                        contactsTriggerNew = ContactTriggerClass.updateMailingField(contactsTriggerNew, contactsTriggerOldMap);
                }

                SyncToSiebelFieldsClass.populateSyncToSiebelField('Contact');
                contactsTriggerNew = ContactTriggerClass.checkForAssociateContactToAccount(contactsTriggerNew, contactsTriggerOldMap);
        }

        public override void beforeDeleteBeforeUndeleteTrigger() {
                  //SFDC-1938  Rajul Vishwakarma
                  if(Trigger.isDelete){
                        ContactTriggerClass.prepareAccoutsForRecomputation(false, false, null, null, Trigger.old);
                }
                //End
        }

        public override void afterInsertAfterUpdateTrigger() {
                //SFDC-2851
                List<Contact> contactsTriggerNew = (List<Contact>)newList;
                List<Contact> contactsTriggerOld = (List<Contact>)oldList;
                Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
                Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;

                //Sonali Tandon - -- CR 3094031- populate Account's Vertical & Sub vertical to Contact Vertical & Sub vertical
                List<Contact> listOfContacts = new List<Contact>();

                List<Id> opptyIdList = new List<Id>();
                List<Opportunity> opptyList = new List<Opportunity>();
                Map<Id,Contact> opptyIdToContactMap = new Map<Id,Contact>();
                
                List<Lead> listOfLeads = new List<Lead>();
                Map<Id, String> contactIdToNewEmailMap = new Map<Id, String>();
                Map<Id, String> contactIdToNewLoginMap = new Map<Id, String>();
                List<UpdatedUser> userList = new List<UpdatedUser>();
                List<Id> accountIdList = new List<Id>();

                //HC: Sync Stage/Status from Contact to C2A Lead

                Contact oldContact;
                for(Contact con : contactsTriggerNew) {

                        // MARIT-1597
                        /*
                        if(Trigger.isInsert || (Trigger.isUpdate && con.AccountId != contactsTriggerOldMap.get(con.Id).AccountId)) {
                                listOfContacts.add(con);
                        }*/

                        if(!UserInfo.getName().equalsIgnoreCase('Connection User')) { // move to
                                if(Trigger.isUpdate) {
                                        oldContact = contactsTriggerOldMap.get(con.Id);
                                        //Anand Hegde - CR 2580357 - update user.email when email on partner contact is updated
                                        if(con.Email != oldContact.Email) {
                                                contactIdToNewEmailMap.put(con.Id, con.Email);
                                        }

                                        if(con.Login__c!= oldContact.Login__c) {
                                                contactIdToNewLoginMap.put(con.Id, con.Login__c);
                                        }

                                        //Update the Current Licences on Account Movement
                                        if (con.AccountId != oldContact.AccountId && con.Partner_User__c != null && con.Active_Partner__c == true) {
                                                userList.add(new UpdatedUser(oldContact.AccountId, con.AccountId, con.NetAlliance_User_Profile__c));
                                        }
                                        //SFDC-8975
                                        //System.debug('Inside if Contact trigger class');
                                        // if(Util.hasChanges('Partner_User__c',oldContact,con) && con.Partner_User__c != null){
                                        //         accountIdList.add(con.AccountId);
                                        // }

                                }
                        }
                }
                //SFDC-8975
                //System.debug('accountIdList::'+accountIdList);
                // if(accountIdList.size() > 0){
                //      L2Q_ContactTriggerClass.getRebatePayouts(accountIdList);
                // }

                // MARIT-1597
                /*
                if(listOfContacts.size()>0) {
                        ContactTriggerClass.populateVerticalFieldsFromAccountForContact(listOfContacts);
                }
                */

                if(userList.size()>0) {
                        L2Q_UserTriggerClass.updateAccountLicenses(userList);
                }

                if(Trigger.isUpdate) {
                        if((contactIdToNewEmailMap.size()>0 || contactIdToNewLoginMap.size()>0) && !GsmUtilClass.isFeatureToggleEnabledCustomMetadata('PostRefreshActivitySwitch'))  {
                                PRM_opportunity.updateUserUsernameOrEmail(contactIdToNewEmailMap, contactIdToNewLoginMap);
                        } //SFDC-2304
                }

                //SFDC-9138 - Rajul Vishwakarma
                if(Trigger.isUpdate){
                        ContactTriggerClass.prepareAccoutsForRecomputation(false, true, Trigger.oldMap, Trigger.new, null);
                }
                if(Trigger.isInsert){
                        ContactTriggerClass.prepareAccoutsForRecomputation(true, false, null, Trigger.new, null);
                }
                //End
        }

        public override void afterDeleteAfterUndeleteTrigger() { //SFDC-2851
                List<Contact> contactsTriggerOld = (List<Contact>)oldList;
                if(!UserInfo.getName().equalsIgnoreCase('Connection User')) { // remove this
                        if (Trigger.isAfter && Trigger.isDelete) { // only for delete
                                ContactTriggerClass.initializeContactMerge(contactsTriggerOld);
                        }
                }
        }
}