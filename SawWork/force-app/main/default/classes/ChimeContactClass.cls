public without sharing class ChimeContactClass{

    public static void provisonChimeFormAccessToContacts(List<Id> contactIdList, Map<Id, Id> contantIdtoChimeFormId){
        System.debug('Inside provisonChimeFormAccessToContacts method');
        Map<Id, User> contactIdToUser = new  Map<Id, User>();
        List<Id> existingUserId = new List<Id>();
        List<User> newUserList = new List<User>();
        List<User> updateUserList = new List<User>();
        List<Id> sendResetEmailUserList = new List<Id>();
        List<Id> updateContact = new List<Id>();

        List<Id> userIdWithChimePerm = new List<Id>();
        List<Id> userIdWithCommunityAccess = new List<Id>();

        String chimePermissionSet = GsmUtilClass.getGSMSettingValue('Chime_Permission_Set'); 

        //Map<Id, List<Id>> assignPermissionSet = new  Map<Id, List<Id>>(); //Map to assign permission set
        Map<Id, Id> assignChimePermission = new Map<Id, Id>(); //Map to assign Chime permission set
        Map<Id, Id> assignCommunityAccessPermissionSet = new Map<Id, Id>(); //Map to assign Community Access permission set

        List<String> permissionSetForChimeAndCommunityAccess = GSMUtilClass.getGSMSettingValue('PermissionSetForChimeAndCommunityAccess').split(',');

        for(User usr : [Select id, contactId, contact.Has_Chime_Access__c ,ProfileId, IsActive, Profile.UserLicense.Name from user where contactId in: contactIdList]){
            contactIdToUser.put(usr.contactId, usr);
            existingUserId.add(usr.id);
        }

        for(PermissionSetAssignment psa : [select id, AssigneeId, PermissionSetId from PermissionSetAssignment where PermissionSetId IN :permissionSetForChimeAndCommunityAccess and AssigneeId in :existingUserId]){
            if(chimePermissionSet.equalsIgnoreCase(psa.PermissionSetId)){
                userIdWithChimePerm.add(psa.AssigneeId); //User Record with Chime Permission
            }
            else{
                userIdWithCommunityAccess.add(psa.AssigneeId); //User Record with Community Access
            }
        }

        for(contact con : [Select Id, FirstName, LastName, Email, LinkedIn__c, MailingCountry, MailingState, AKAM_Contact_Id__c, Has_Chime_Access__c, Remove_Chime_Access_TimeStamp__c from Contact where id in :contactIdList]){
            if(contactIdToUser.containsKey(con.Id)){ //Contact has already user record associated with it.
                System.debug('Inside Contact has already user record');
                if(!contactIdToUser.get(con.id).IsActive){ //If the user is inActive, Activate it
                    contactIdToUser.get(con.id).IsActive = true;
                    updateUserList.add(contactIdToUser.get(con.id));
                }
                if(!userIdWithChimePerm.contains(contactIdToUser.get(con.id).id)){ //If User does not have chime permission, Assign the Chime permission.
                    assignChimePermission.put(contactIdToUser.get(con.id).Id, Id.valueOf(chimePermissionSet));
                    receiveChatterAndComments(contactIdToUser.get(con.id));
                    if(!hasChimeAccess(con)){
                        updateContact.add(con.id);
                        System.debug('UpdateContact:'+updateContact);
                    }
                    System.debug('assignChimePermission'+assignChimePermission);
                    System.debug('Assign the Chime permission');
                }
                if(con.Has_Chime_Access__c && con.Remove_Chime_Access_TimeStamp__c != null){
                    updateContact.add(con.id);
                }
                if(!'Customer Community Plus Login'.equalsIgnoreCase(contactIdToUser.get(con.id).Profile.UserLicense.Name)){ //Assign community access permission since the User license is not 'Customer Community Plus Login'
                    System.debug('Inside Not Customer Community Plus Login profile');
                    if('Partner Community'.equalsIgnoreCase(contactIdToUser.get(con.id).Profile.UserLicense.Name) && !userIdWithCommunityAccess.contains(contactIdToUser.get(con.id).id)){ // Provide Community permission set to partner users
                        assignCommunityAccessPermissionSet.put(contactIdToUser.get(con.id).Id, Id.valueOf('0PS0f000000UTb3'));
                    }
                    else if(!userIdWithCommunityAccess.contains(contactIdToUser.get(con.id).id)){ //Provide Community permission set to non partner users
                        assignCommunityAccessPermissionSet.put(contactIdToUser.get(con.id).Id, Id.valueOf('0PS0f000000UTb8'));
                    }
                }
            }
            else{
                newUserList.add(getNewProspectCommunityUser(con)); //Creating new prospect user record
            }
        }
        System.debug('Till here:');
        newUserList.addAll(updateUserList);
        System.debug('Till heree:'+newUserList);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        if(newUserList.size() > 0){
            Database.UpsertResult[] saveRes = Database.upsert(newUserList, false);
            Integer count = 0;
            System.debug('existingUserId:'+existingUserId);
            for(Database.UpsertResult result : saveRes){
                if(!result.isSuccess()){
                    String errMessage = '';
                    for(Database.Error err : result.getErrors()){
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }
                    Map<String, Object> fieldsToValue = newUserList[count].getPopulatedFieldsAsMap();
                    System.Debug(LoggingLevel.Error, 'AGH_ fieldsToValue:'+fieldsToValue);
                    String objectState = JSON.serialize(fieldsToValue);
                    Error_Log__c el = new Error_Log__c(Name='provisonChimeFormAccessToContacts', Class__c='ChimeContactClass', Error_Message__c=errMessage , Object_State__c=objectState);
                    System.debug(LoggingLevel.Error, 'AGH_ errored Upsert:'+el);
                    errorLogs.add(el);
                }
                else{
                    if(!existingUserId.contains(result.getId())){
                        assignChimePermission.put(result.getId(), Id.valueOf(chimePermissionSet));
                        sendResetEmailUserList.add(result.getId());
                        System.debug('Inside here');
                    }
                }
                count++;
            }
        }
            System.debug('We reached here:');
            if(assignChimePermission.size() > 0){
                System.debug('assignChimePermission:'+assignChimePermission);
                permissionSetAssignmentForUser(assignChimePermission);
            }
            
            if(assignCommunityAccessPermissionSet.size() > 0){ 
                permissionSetAssignmentForUser(assignCommunityAccessPermissionSet);
            }

            if(sendResetEmailUserList.size() > 0){ //Resetting password for newly created user record
                resetPasswordForCommunityGuestuser(sendResetEmailUserList);
            }

            if(sendResetEmailUserList.size() > 0  || updateContact.size() > 0){ //Updating contact Has_Chime_Access__c = True
                updateContactForUser(sendResetEmailUserList, updateContact, contantIdtoChimeFormId);
            }

            if(errorLogs.size()>0){
                Sawyer.saw(errorLogs, 'ChimeContactClass', 'provisonChimeFormAccessToContacts');
            }
    }

    @future
    public static void permissionSetAssignmentForUser(Map<Id, Id> userIdToPermissionSet){
        System.debug('Inside permissionSetAssignmentForUser');
        List<PermissionSetAssignment> permissionAssignmentList = new List<PermissionSetAssignment>();
        for(Id usrId : userIdToPermissionSet.keySet()){
                PermissionSetAssignment  psa = new PermissionSetAssignment(PermissionSetId = userIdToPermissionSet.get(usrId), AssigneeId = usrId);
                permissionAssignmentList.add(psa);
        }
        if(permissionAssignmentList.size() > 0){
            GsmUtilClass.doDatabaseUpsert(permissionAssignmentList,'ChimeContactClass','assignPermissionSetToUser', false);
        }
    }

    public static void resetPasswordForCommunityGuestuser(List<Id> resetEmailUserList){
        for(id eachUserId : resetEmailUserList){
            system.resetPassword(eachUserId, true);
        }
    }

    public static void sendChimeEmail(List<contact> contactList, Map<Id, Id> contantIdtoChimeFormId){
        List<Id> chimeIds = new List<Id>();
        Map<Id,List<String>> ccAddressesForForm = new Map<Id,List<String>>();
        Map<Id, CHIME__c> idToChimeMap = new Map<Id, CHIME__c> ();
        List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
        EmailTemplate em = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName = 'ChimeEmailContactProvisioning'][0];

        for(contact con : contactList){
            chimeIds.add(contantIdtoChimeFormId.get(con.Id));
        }
        Map<Id,Id> chimeToAccount = new Map<Id,Id>();
        for(CHIME__c ch : [Select id, name,createdby.email, Account__c, createdby.name, CHIME_Name__c from CHIME__c where id IN :chimeIds]){
            idToChimeMap.put(ch.id, ch);
            chimeToAccount.put(ch.id,ch.Account__c);
            ccAddressesForForm.put(ch.id,new List<String>{ch.createdby.email});
        }
        //Get Account team member TSP for this CHIME form
        Set<Id> setAccountList = new Set<Id>(chimeToAccount.values());
        Map<Id,String> accountToATMEmail = new Map<Id,String>();
       for(AccountTeamMember atm : [select id, AccountId, TeamMemberRole,userid ,user.email,Account.Name from AccountTeamMember where Accountid in:setAccountList]){
            if(atm.TeamMemberRole == 'Technical Sales - Primary' ){
                accountToATMEmail.put(atm.AccountId,atm.user.email);
            }
        }
        
        for(Id chimeId : chimeToAccount.keySet()){
            if(!ccAddressesForForm.containsKey(chimeId)){
               ccAddressesForForm.put(chimeId,new List<String>()); 
            }
            if(accountToATMEmail.get(chimeToAccount.get(chimeId)) != null){
                ccAddressesForForm.get(chimeId).add(accountToATMEmail.get(chimeToAccount.get(chimeId)));
            }
        }

        for(contact con : contactList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String msgBody = em.HtmlValue;
            msgBody = msgBody.replace('Form_Creator', idToChimeMap.get(contantIdtoChimeFormId.get(con.id)).createdby.name);
            String urlInstance = getCommunitySiteURL();
            String url = getCommunitySiteURL()+'chimecustomerform?c__chimeId='+idToChimeMap.get(contantIdtoChimeFormId.get(con.id)).id+'&c__chimeName='+idToChimeMap.get(contantIdtoChimeFormId.get(con.id)).CHIME_Name__c;
            msgBody = msgBody.replace('dummyUrl', url);
            mail.setTargetObjectId(con.id);
            mail.setSubject(em.Subject);
            mail.setHtmlBody(msgBody);
            mail.setSaveAsActivity(false);
            if( ccAddressesForForm.get(contantIdtoChimeFormId.get(con.id)) != null && 
                ccAddressesForForm.get(contantIdtoChimeFormId.get(con.id)).size()>0){
                mail.setccAddresses(ccAddressesForForm.get(contantIdtoChimeFormId.get(con.id)));
            }
            mailList.add(mail);
        }
        if(mailList.size() > 0){
            Messaging.sendEmail(mailList);
        }
    }

    @future
    public static void updateContactForUser(List<Id> userId, List<Id> contactId, Map<Id, Id> contantIdtoChimeFormId){
        List<contact> updateContact = new List<contact>();
        for(User usr : [Select id, contactId from user where id in :userId]){
            Contact con = new Contact(id = usr.contactId, Has_Chime_Access__c = true, Remove_Chime_Access_TimeStamp__c = null);
            updateContact.add(con);
        }

        for(Id conId : contactId){
            Contact con = new Contact(id = conId, Has_Chime_Access__c = true, Remove_Chime_Access_TimeStamp__c = null);
            updateContact.add(con);
        }

        if(updateContact.size() > 0){
            GsmUtilClass.doDatabaseUpdate(updateContact,'ChimeContactClass','updateContactForUser');
            sendChimeEmail(updateContact, contantIdtoChimeFormId);
        }
        
    }
    public static User getNewProspectCommunityUser(Contact con){
        User newUser = new User();
        newUser.Username = con.Email;
        newUser.Email = con.Email;
        newUser.alias = con.lastname.length() > 3 ? 'CCM-'+(con.FirstName.substring(0,1) + con.LastName.substring(0,2)) : 'CCM-'+(con.FirstName.substring(0,1) + con.LastName);
        newUser.CommunityNickname = ((con.firstname != null && con.firstname.length() > 0) ? con.firstname.substring(0,1) : '' ) + con.lastname.substring(0,1) + String.valueOf(Crypto.getRandomInteger()).substring(1,7);
        newUser.ProfileId = GsmUtilClass.getGSMSettingValue('SF_Community_Guest_Profile'); //SFCommunityGuests profile
        newUser.LastName = con.LastName;
        newUser.FirstName = con.FirstName;
        newUser.LinkedIn_URL__c = con.LinkedIn__c;
        newUser.IsActive = true;
        newUser.ContactId = con.Id;
        newUser.AKAM_User_Id__c = con.AKAM_Contact_Id__c;
        newUser.Country = con.MailingCountry;
        newUser.State = con.MailingState;
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.FederationIdentifier = con.AKAM_Contact_Id__c;
        receiveChatterAndComments(newUser);
        return newUser;
    }

    public static void assignChimePermissionSet(){

    }

    public static Boolean hasChimeAccess(Contact contct){ //Check whether contact record has Chime access or not.
        if(!contct.Has_Chime_Access__c){
            return false;
        }
        return true;
    }

    public static void receiveChatterAndComments(User usr){
        usr.UserPreferencesDisableMentionsPostEmail = false;
        usr.UserPreferencesDisMentionsCommentEmail = false;
    }

    public static String getCommunitySiteURL(){
        Network myCommunity = [SELECT Id FROM Network WHERE Name = 'Customer Community'];
        String url = Network.getLoginUrl(myCommunity.id).replace('login','');
        return url;
    }

    public static void uncheckChimeOnContact(Set<Id> contactList){
        list<contact> updateContactList = new list<contact>();
        list<Id> contactIdList = new list<Id>();

        for(CHIME_Contact__c chimeContact : [Select id, Contact__c from CHIME_Contact__c where Contact__c IN :contactList and Chime_access__c = true]){
            if(contactList.contains(chimeContact.Contact__c)){
                contactList.remove(chimeContact.Contact__c);
            }
        }
        
        for(Id conId : contactList){
            Contact con = new Contact(id = conId, Has_Chime_Access__c = false);
            updateContactList.add(con);
            contactIdList.add(con.id);
        }
        System.debug('updateContactList:'+updateContactList);
        if(updateContactList.size() > 0){
            GsmUtilClass.doDatabaseUpdate(updateContactList,'ChimeContactClass','uncheckChimeOnContact');
            removeChimePermission(contactIdList);
        }
    }
    //SFDC-8304 Validate if new Contacts already exists on this CHIME form
    public static void validateChimeContact(Map<Id,Set<Id>> chimeIdToContactSetMap,List<CHIME_Contact__c> chimeContactTriggerNew){
        
        Map<Id, Set<Id>> allChimeToContactMap = new Map<Id, Set<Id>>();
        Map<Id,String> chimeNameMap = new  Map<Id,String>();
        Map<Id,String> contactNameMap = new  Map<Id,String>();

        // Get all contacts for this chime form, supports bulk uploads
        for(CHIME_Contact__c chimeContact : [select id,chime__c,chime__r.CHIME_Name__c, contact__c,contact__r.name from CHIME_Contact__c where chime__c in :chimeIdToContactSetMap.keySet()]){
            if(!allChimeToContactMap.containsKey(chimeContact.chime__c)){
                allChimeToContactMap.put(chimeContact.chime__c, new Set<Id>());
            }
            allChimeToContactMap.get(chimeContact.chime__c).add(chimeContact.contact__c);

            chimeNameMap.put(chimeContact.chime__c,chimeContact.chime__r.CHIME_Name__c);
            contactNameMap.put(chimeContact.contact__c,chimeContact.contact__r.Name);
        }

        // Check if new Chime contact already has Contact associated, also check if bulk uploads consist any duplicates
        Set<String> found = new Set<String>();
        for(CHIME_Contact__c cc : chimeContactTriggerNew){

            if(found.contains(cc.chime__c+'-'+cc.contact__c)){
                cc.addError('Attempt to insert duplicate Contacts  on CHIME Form ');
            }
            else if(allChimeToContactMap.containsKey(cc.chime__c) &&  allChimeToContactMap.get(cc.chime__c).contains(cc.contact__c)){
                cc.addError('Contact "'+contactNameMap.get(cc.contact__c)+'" already exists on CHIME Form "'+chimeNameMap.get(cc.chime__c)+'"');
            }
            
            found.add(cc.chime__c+'-'+cc.contact__c);
        } 
    }

    @future
    public static void removeChimePermission(List<Id> contactList){
        String chimePermissionSet = GsmUtilClass.getGSMSettingValue('Chime_Permission_Set'); 
        List<id> userId = new List<id>();
        List<PermissionSetAssignment> permissionRemovalList = new List<PermissionSetAssignment>();
        for(user usedery : [Select id from user where contactId IN :contactList]){
            userId.add(usedery.id);
        }
        permissionRemovalList = [Select id from PermissionSetAssignment where PermissionSetId = :chimePermissionSet and AssigneeId IN :userId];
        System.debug('permissionRemovalList:'+permissionRemovalList);
        if(permissionRemovalList.size() > 0){
            GsmUtilClass.doDatabaseDelete(permissionRemovalList, 'ChimeContactClass','removeChimePermission');
        }
    }

}