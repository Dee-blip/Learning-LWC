public without sharing class L2Q_ManagePartnerOperationsController {
    public static Boolean erasePermissionsAndRevokeAccessHasRun = false; //SFDC-8760
    public static Boolean createPartnerUserRun = false; // SFDC-9797 @hpandey
    
    public class SelectOptionPicklistClass {
        @AuraEnabled public String label {
            get;
            set;
        }
        @AuraEnabled public String value {
            get;
            set;
        }
        @AuraEnabled public Boolean isSelected {
            get;
            set;
        }
        public SelectOptionPicklistClass(String label, String value) {
            this.label = label;
            this.value = value;
            this.isSelected = false;
        }
        public SelectOptionPicklistClass(String label, String value, Boolean isSelected) {
            this.label = label;
            this.value = value;
            this.isSelected = isSelected;
        }
    }

    public static Contact getPartnerContact(Id contactId) {
        Contact partnerContact;
        // SFDC-7240
        for (Contact eachContact: [SELECT Id, Name, FirstName, LastName, Email, MailingState, MailingCountry, Phone, Partner_User__c, Company__c, NetAlliance_User_Profile__c, DoNotSync__c, Validation_Override__c, AKAM_Contact_ID__c, Active_Portal_Login__c, Has_Akamai_University_Access__c, Has_View_Trial_Access__c, NetAlliance_User_Active__c, Login__c, Account.Id, Account.Name, Account.OwnerId, Account.Owner.Name, Account.Owner.Email, Account.IsPartner, Account.AKAM_Account_ID__c, Account.Partner_Type__c, Account.PulsarAPI_DetailsJSON__c, Account.Current_Licenses__c, Account.Maximum_Licenses__c, Account.Partner_Concierge_Access__c, Account.Autonomy_Partner__c
                FROM Contact WHERE Id =: contactId
            ]) {

            partnerContact = eachContact;
        }
        return partnerContact;
    }

    public static User getPartnerUser(Id contactId) {
        User partnerUser;
        for (User eachUser: [SELECT Id, FirstName, LastName, Name, Alias, Email, Username, ProfileId, UserRoleId, IsActive, UserRole.Name, Profile.Name, Can_Accept_POA__c, Has_MDF_Access__c, Has_PartnerPlans_Access__c, Has_DealRegistration_Access__c, Has_PartnerCertification_Access__c, View_Pricing_Details__c, Has_Partner_Concierge_Access__c, Has_Partner_Lead_Access__c, Has_Start_Trial_Access__c, Has_View_Trial_Access__c, Has_view_content_in_portals__c, Has_Portal_Tableau_Access__c, Has_CPQ_AutonomyAdmin__c, Has_CPQ_Autonomy_QuoteOnly__c, Has_Partner_Lead_View_Access__c
                FROM User
                WHERE ContactId =: contactId
            ]) {

            partnerUser = eachUser;
        }
        return partnerUser;
    }

    private static String emailToAlias(String emailStr) {
        if (('ak-' + emailStr.substring(0, emailStr.indexof('@'))).length() > 8) {
            return ('ak-' + emailStr.substring(0, emailStr.indexof('@'))).substring(0, 8);
        } else {
            return ('ak-' + emailStr.substring(0, emailStr.indexof('@')));
        }
    }

    private static User createPartnerUser(Contact partnerContact) {
        User partnerUser = new User();
        partnerUser.FirstName = partnerContact.FirstName;
        partnerUser.LastName = partnerContact.LastName;
        if (partnerContact.Email != null) {
            partnerUser.Username = partnerContact.Email + '.akamai';
            partnerUser.Alias = emailToAlias(partnerContact.Email);
            partnerUser.Email = partnerContact.Email;
        }
        partnerUser.ContactId = partnerContact.Id;
        partnerUser.LanguageLocaleKey = 'en_US';
        partnerUser.LocaleSidKey = 'en_US';
        partnerUser.EmailEncodingKey = 'UTF-8';
        partnerUser.TimeZoneSidKey = 'America/Los_Angeles';
        partnerUser.UserPreferencesContentNoEmail = true;
        partnerUser.UserPreferencesContentEmailAsAndWhen = true;
        partnerUser.ProfileId = GsmUtilClass.getPRMSettingValue('PartnerCommunityLiteProfileId');
        return partnerUser;
    }

    private static List < SelectOptionPicklistClass > getUserRoleOptions(User partnerUser, Contact partnerContact, Boolean userNotPresentInDB) {

        List < SelectOptionPicklistClass > listOfRoleOptions = new List < SelectOptionPicklistClass > ();
        for (UserRole eachUserRole: [select id, name
                from UserRole
                where PortalType = 'Partner'
                and PortalAccountId =: partnerContact.Account.Id
                order by name desc
            ]) {
            listOfRoleOptions.add(new SelectOptionPicklistClass(eachUserRole.Name, eachUserRole.Id, ((!userNotPresentInDB && partnerUser.UserRoleId == eachUserRole.Id) ||
                eachUserRole.Name.containsIgnoreCase(NAPSettings.getValue('Default_Role')))));

        }

        return listOfRoleOptions;
    }

    private static List < SelectOptionPicklistClass > getUserProfileOptions(User partnerUser, Contact partnerContact, Boolean userNotPresentInDB) {

        String Level3PartnerAccountAKAMId = GSMSettings.getValue('Level3PartnerAccountAKAMId');
        List < SelectOptionPicklistClass > listOfProfileOptions = new List < SelectOptionPicklistClass > ();
        for (Profile eachProfile: [select id, name
                from profile
                where userlicense.name = 'Partner Community'
                order by name asc
            ]) {
            if (!(Level3PartnerAccountAKAMId.contains(partnerContact.Account.AKAM_Account_Id__c) &&
                    eachProfile.Name.contains('Admin'))) {
                // level3 accounts should not see admin profile
                listOfProfileOptions.add(new SelectOptionPicklistClass(eachProfile.Name, eachProfile.Id, (!userNotPresentInDB && eachProfile.Id == partnerUser.ProfileId)));
            }
        }
        return listOfProfileOptions;
    }

    private static Boolean isLiteLicenseSufficient(User pUser) {
        String nonLitePermissions = GsmUtilClass.getPRMSettingValue('NonLitePermissionSets');
        for (String fieldName: nonLitePermissions.split(',')) {
            if (pUser.get(fieldName.trim()) == true) {
                return false;
            }
        }
        return true;
    }

    public static List < String > getProfile(User pUser) {
        // if Admin is selected, retain it
        // else if lite is sufficient then assign lite
        // else assign partner comm user
        List < String > results = new List < String > ();
        if (!String.valueOf(pUser.ProfileId).contains(GsmUtilClass.getPRMSettingValue('Partner_Admin_Id').subString(0, 15))) {
            if (isLiteLicenseSufficient(pUser)) {
                pUser.ProfileId = GsmUtilClass.getPRMSettingValue('PartnerCommunityLiteProfileId');
                // This is in Update access case
                if (pUser.Profile != null) {
                    pUser.Profile.Name = 'Partner Community Lite';
                }
                results.add(pUser.ProfileId);
                results.add('Partner Community Lite');
            } else {
                pUser.ProfileId = GsmUtilClass.getPRMSettingValue('Partner_User_ID');
                if (pUser.Profile != null) {
                    pUser.Profile.Name = 'Partner Community User';
                }
                results.add(pUser.ProfileId);
                results.add('Partner Community User');
            }
        } else {
            results.add(pUser.ProfileId);
            results.add('Partner Community Admin');
        }
        return results;
    }

    private static Boolean setLeadAccess(User pUser) {
        return (pUser.Has_MDF_Access__c || pUser.Has_PartnerPlans_Access__c ||
            pUser.Has_DealRegistration_Access__c || pUser.Has_PartnerCertification_Access__c ||
            pUser.Has_view_content_in_portals__c || pUser.Has_Partner_Concierge_Access__c ||
            pUser.Has_Start_Trial_Access__c || pUser.Has_View_Trial_Access__c);

    }

    //SFDC-7898-Start - @nadesai
    class PermissionSetAssignmentManager {
        private Map < String, PermissionSetAssignment > mapOfPermissionsToBeAdded;
        private Map < String, PermissionSetAssignment > mapOfPermissionsToBeDeleted;
        private Map < String,  PermissionSetAssignment > mapOfExistingPermissionSets;
        private Map < String,  PermissionSetLicenseAssign > mapOfExistingPSLicences; //Contains map of existing Permission Set Licences

        private Set < String > userFieldSchema;
        private String salesforceCPQ_LicencetId; //Licence Id of 'Salesforce CPQ Licence', this licence needs to be given to the user before we are giving any CPQ related PermissionSetAssignments
        private List < String > permissionsRequiringCPQLicence; //List of all the fields that require CPQ Licence
        private User user;
        private Contact contact;

        private void intitializeData(User user, Contact contact) {
            this.user = user;
            this.contact = contact;
            this.userFieldSchema = Schema.SObjectType.User.fields.getMap().keySet();
            this.mapOfPermissionsToBeAdded = new Map < String, PermissionSetAssignment > ();
            this.mapOfPermissionsToBeDeleted = new Map < String, PermissionSetAssignment > ();
            this.salesforceCPQ_LicencetId = trimId(NAPSettings.getValue('PartnerAccessGroup_CPQLicenceId'));
            setExistingPermissionsAndLicences();
        }

        public PermissionSetAssignmentManager(User user, Contact contact) {
            intitializeData(user, contact);
        }

        //check if a particular assignment should be added or deleted on a user
        public void processAssignment(String eachField, String permissionSetId) {
            permissionSetId = trimId(permissionSetId);
            Boolean isFieldSet = checkIfFieldSet(eachField);
            Boolean isPSAssigned = this.mapOfExistingPermissionSets.containsKey(permissionSetId);

            if (isFieldSet && !isPSAssigned) {
                this.mapOfPermissionsToBeAdded.put(permissionSetId, getAssignmentRecord(permissionSetId));
            } else if (!isFieldSet && isPSAssigned) {
                this.mapOfPermissionsToBeDeleted.put(permissionSetId, this.mapOfExistingPermissionSets.get(permissionSetId));
            }
        }

        public void handleAssignments() {
            deletePermissionToBeDeleted();
            insertPermissionToBeAdded();
        }

        //Trim Id to 15 chars and return 
        private String trimId(String idVal) {
            return idVal.subString(0, 15);
        }

        //Set the set whith the Permission Sets that the user has already been provided with
        private void setExistingPermissionsAndLicences() {
            this.permissionsRequiringCPQLicence = new List < String >();
            for(String eachCPQLicence : NAPSettings.getValue('PermissionsRequiringCPQLicence').split(',')) { //To handle new permissions that require CPQ licence, add to this metadata
                this.permissionsRequiringCPQLicence.add(trimId(eachCPQLicence));
            }
            // this set has permissionSetIds and permissionsetGroupIds as keys
            this.mapOfExistingPermissionSets = new Map < String,  PermissionSetAssignment> ();
            for (PermissionSetAssignment eachPSA: [SELECT Id, AssigneeId, PermissionSetId, PermissionSetGroupId
                    FROM PermissionSetAssignment WHERE AssigneeId =: this.user.Id
                ]) {
                this.mapOfExistingPermissionSets.put(trimId(eachPSA.PermissionSetId), eachPSA);
                if (eachPSA.PermissionSetGroupId != null) {
                    this.mapOfExistingPermissionSets.put(trimId(eachPSA.PermissionSetGroupId), eachPSA);
                }
            }

            //create set of existing permission set licences already assigned to the user
            this.mapOfExistingPSLicences = new Map < String, PermissionSetLicenseAssign > ();
            for (PermissionSetLicenseAssign eachLicence: [SELECT Id, PermissionSetLicenseId FROM PermissionSetLicenseAssign
                    WHERE AssigneeId =: this.user.Id
                ]) {
                this.mapOfExistingPSLicences.put(trimId(eachLicence.PermissionSetLicenseId), eachLicence);
            }
        }

        //Check if the boolean fields are set on user/ contact record
        private Boolean checkIfFieldSet(String fieldAPIName) {
            if (userFieldSchema.contains(fieldAPIName.toLowerCase())) {
                return user.get(fieldAPIName) != null && user.get(fieldAPIName) == true;
            }
            return contact.get(fieldAPIName) != null && contact.get(fieldAPIName) == true;
        }

        //If the passed in Id is PermissionSetGroup/ PermissionSet, construct & return a PermissionSetAssignment record
        private PermissionSetAssignment getAssignmentRecord(String permissionSetId) {
            if (String.valueOf(Id.valueOf(permissionSetId).getSobjectType()).equals('PermissionSetGroup')) {
                return new PermissionSetAssignment(AssigneeId = this.user.Id, PermissionSetGroupId = permissionSetId);
            }
            return new PermissionSetAssignment(AssigneeId = this.user.Id, PermissionSetId = permissionSetId);
        }

        /* To provide CPQ Licence to user :
         * C1 -> User should not already have the licence
         * C2 -> There should be some permissionset that requires this licence being given to the user
         */
        private void provideCPQLicenceToUserIfRequired() {
            if (!this.mapOfExistingPSLicences.containsKey(this.salesforceCPQ_LicencetId)) {
                for (String eachCPQPermission: this.permissionsRequiringCPQLicence) {
                    if (this.mapOfPermissionsToBeAdded.containsKey(eachCPQPermission)) {
                        PermissionSetLicenseAssign cpqLicence = new PermissionSetLicenseAssign(AssigneeId = this.user.Id, PermissionSetLicenseId = this.salesforceCPQ_LicencetId);
                        insert cpqLicence;
                        break;
                    }
                }
            }
        }

        /* To be able to delete CPQ licence from user :
         * C1 -> The licence had to be given to user initially
         * C2 -> There should be no permissionset getting added that requires CPQ Licence
         * C3 -> There should not be any permissionsets left on user that requires CPQ licence after deletion
         *       For this, get all the CPQ Permission from existing Permission Sets and check that they are all getting deleted
         */
        private Boolean canDeleteCPQLicence() {
            if (this.mapOfExistingPSLicences.containsKey(this.salesforceCPQ_LicencetId)) { //C1
                for (String eachCPQPermission: this.permissionsRequiringCPQLicence) {
                    if (this.mapOfPermissionsToBeAdded.containsKey(eachCPQPermission)) { //C2
                        return false;
                    } else if (this.mapOfExistingPermissionSets.containsKey(eachCPQPermission) &&
                        !this.mapOfPermissionsToBeDeleted.containsKey(eachCPQPermission)) { //C3
                        return false;
                    }
                }
                return true;
            }
            return false;
        }

        private void removeCPQLicenceFromUserIfNotRequired() {
            if (canDeleteCPQLicence()) {
                delete mapOfExistingPSLicences.get(this.salesforceCPQ_LicencetId);
                mapOfExistingPSLicences.remove(this.salesforceCPQ_LicencetId);
            }
        }

        private void insertPermissionToBeAdded() {
            if (this.mapOfPermissionsToBeAdded.size() > 0) {
                provideCPQLicenceToUserIfRequired();
                insert this.mapOfPermissionsToBeAdded.values();
            }
        }

        private void deletePermissionToBeDeleted() {
            if (this.mapOfPermissionsToBeDeleted.size() > 0) {
                delete this.mapOfPermissionsToBeDeleted.values();
                removeCPQLicenceFromUserIfNotRequired();
            }
        }

    }
    //End of SFDC-7898

    //SFDC-7898-Start - @nadesai
    class PermissionSetManager {
        //This map holds Field API names as keys and corresponding Custom Metadata Developer Names (These metadata contains permission set Ids) as values
        private Map < String, String > mapOfFieldsVsDeveloperNames;

        //This map holds Field API names as keys and corresponding permission set Ids as values
        private Map < String, String > mapOfFieldsVsPermissionSetId;

        public PermissionSetManager() {
            mapOfFieldsVsDeveloperNames = new Map < String, String > {
                'Has_MDF_Access__c' => 'PartnerAccess_MDFAccess',
                'Has_DealRegistration_Access__c' => 'PartnerAccess_DealRegAccess',
                'Has_Partner_Lead_Access__c' => 'PartnerAccess_PartnerLeadAccess',
                'Has_Start_Trial_Access__c' => 'PartnerAccess_StartTrialAccess',
                'Has_View_Trial_Access__c' => 'PartnerAccess_ViewTrialAccess',
                'Has_Partner_Lead_View_Access__c' => 'PartnerAccess_PartnerLeadViewAccess',
                'Has_PartnerPlans_Access__c' => 'PartnerAccess_PartnerPlanAccess',
                'Has_Akamai_University_Access__c' => 'PartnerAccess_AUAccess',
                'Has_view_content_in_portals__c' => 'PartnerAccess_viewContentInPortals',
                'Can_Accept_POA__c' => 'PartnerAccess_POAAccess',
                'Has_PartnerCertification_Access__c' => 'PartnerAccess_PartnerCertAccess',
                'View_Pricing_Details__c' => 'PartnerAccess_PricingAccess',
                'Has_Partner_Concierge_Access__c' => 'PartnerAccess_Partner_Concierge_Access',
                'Has_CPQ_Autonomy_QuoteOnly__c' => 'PartnerAccessGroup_CPQ_Autonomy_Quote',
                'Has_CPQ_AutonomyAdmin__c' => 'PartnerAccessGroup_CPQ_AutonomyAdmin'
            };
            setmapOfFieldsToPermissionSetIds();
        }

        private void setmapOfFieldsToPermissionSetIds() {
            this.mapOfFieldsVsPermissionSetId = new Map < String, String > ();
            Map < String, String > mapOfMetadataVsValues = NAPSettings.getValues(
                this.mapOfFieldsVsDeveloperNames.values()
            );
            for (String eachField: this.mapOfFieldsVsDeveloperNames.keySet()) {
                String eachDeveleoperName = mapOfFieldsVsDeveloperNames.get(eachField);
                String eachValue = mapOfMetadataVsValues.get(eachDeveleoperName);
                this.mapOfFieldsVsPermissionSetId.put(eachField, eachValue);
            }
        }

        public void setRequiredPermissionSetsFor(User user, Contact contact) {
            PermissionSetAssignmentManager psAssignment = new PermissionSetAssignmentManager(user, contact);
            for (String eachField: this.mapOfFieldsVsPermissionSetId.keySet()) {
                String permissionSetId = this.mapOfFieldsVsPermissionSetId.get(eachField);
                psAssignment.processAssignment(eachField, permissionSetId);
            }
            psAssignment.handleAssignments();
        }

        //SFDC-8760
        public Map < String, String > getMapOfFieldsVsPermissionSetId() {
            return this.mapOfFieldsVsPermissionSetId;
        }

    }
    //End of SFDC-7898

    //SFDC-7898 - Start- @nadesai
    public static void updateRemoveUserPermissionSet(User user, Contact partCon) {
        PermissionSetManager psManager = new PermissionSetManager();
        psManager.setRequiredPermissionSetsFor(user, partCon);
    }
    //End of SFDC-7898 - @nadesai

    public static String getPortalAdminString(Contact PartnerCon) {
        String strPortalAdmin = '';
        for (User usr: [Select Contact.Email, Contact.MobilePhone, Contact.Phone, Contact.Name
                From User
                where Contact.AccountId =: PartnerCon.Account.id
                AND isActive = true
                AND Profile.Name = 'Partner Community Admin'
                ORDER BY Contact.Name ASC
            ]) {
            strPortalAdmin = strPortalAdmin + generatePortalAdminString(usr);
        }
        return strPortalAdmin;
    }

    public static String generatePortalAdminString(User adminUser) {
        string strPortalAdminTemplate = '<br /><br />Name: #partnerAdminName#<br />';
        strPortalAdminTemplate += '<br />Email Id: #partnerEmail#<br />';
        strPortalAdminTemplate += '<br />Phone: #partnerPhone#<br />';
        strPortalAdminTemplate += '<br />Mobile Phone: #partnerMobilePhone#<br />';

        return strPortalAdminTemplate
            .replaceAll('#partnerAdminName#', (adminUser.Contact.Name != null ? adminUser.Contact.Name : 'NA'))
            .replaceAll('#partnerEmail#', (adminUser.Contact.Email != null ? adminUser.Contact.Email : 'NA'))
            .replaceAll('#partnerPhone#', (adminUser.Contact.Phone != null ? adminUser.Contact.Phone : 'NA'))
            .replaceAll('#partnerMobilePhone#', (adminUser.Contact.MobilePhone != null ? adminUser.Contact.MobilePhone : 'NA'));
    }

    private static string replaceTemplatePlaceholders(String templateText, Contact con) {
        return (String.isBlank(templateText) ? '' : templateText
            .replaceAll('#portalUserFullName#', (con.Name != null ? con.Name : 'NA'))
            .replaceAll('#portalUserCompanyName#', (con.Account.Name != null ? con.Account.Name : 'NA'))
            .replaceAll('#portalUserPhoneNo#', (con.Phone != null ? con.Phone : 'NA'))
            .replaceAll('#portalUserEmail#', (con.Email != null ? con.Email : 'NA')));
    }

    private static String replaceUsernamePassword(String templateText, Contact con, String tempPassword) {
        return (String.isBlank(templateText) ? '' : templateText
            .replaceAll('#user#', con.Name)
            .replaceAll('#username#', con.Email)
            .replaceAll('#password#', tempPassword));
    }

    public static string replaceAdmins(String templateText, String adminListString, String strPortalAdminHeader) {
        return templateText.replaceAll('#PORTALADMINS#', String.isBlank(adminListString) ? (strPortalAdminHeader + adminListString) : ' ');
    }

    public static Messaging.SingleEmailMessage PartnerUserWelcomeMail(String tempPassword, EmailTemplate toUserTemplate, Contact con) {
        String emailTextBody, emailHTMLBody, emailToList, emailCCList, pUsername;
        Messaging.SingleEmailMessage partnerUserMail = new Messaging.SingleEmailMessage();
        String strPortalAdmin = getPortalAdminString(con);
        //SFDC-7653 - @nadesai
        String strPortalAdminHeader = '<br />Please find below list of ' + NAPSettings.getValue('NAPRebrand_Type1') + ' for ' + con.Account.Name + '.';

        emailToList = con.Email;
        emailCCList = NAPSettings.getValue('emailCCList_ManagePartnerOperations');

        emailHTMLBody = replaceAdmins(replaceUsernamePassword(toUserTemplate.HtmlValue, con, tempPassword), strPortalAdmin, strPortalAdminHeader);
        emailTextBody = replaceAdmins(replaceUsernamePassword(toUserTemplate.Body, con, tempPassword), strPortalAdmin, strPortalAdminHeader);

        partnerUserMail = createSingleEmail(emailToList, emailCCList, toUserTemplate.Subject, emailTextBody, emailHTMLBody);
        return partnerUserMail;
    }

    private static Messaging.SingleEmailMessage CreatePartnerMail(String tempPassword, EmailTemplate partnerTemplate, Contact con) {
        String emailTextBody, emailHTMLBody, emailToList, emailCCList;
        Messaging.SingleEmailMessage partnerMail;

        emailToList = con.Email;
        emailCCList = NAPSettings.getValue('emailCCList_ManagePartnerOperations');

        emailHTMLBody = replaceUsernamePassword(partnerTemplate.HtmlValue, con, tempPassword);
        emailTextBody = replaceUsernamePassword(partnerTemplate.Body, con, tempPassword);

        partnerMail = createSingleEmail(emailToList, emailCCList, partnerTemplate.Subject, emailTextBody, emailHTMLBody);
        return partnerMail;
    }

    public static Messaging.SingleEmailMessage createSingleEmail(String toAddress, String ccAddress, String Subject, String bodytext, String htmltext) {
        boolean CcEmailflag = false;
        if (ccAddress != null && ccAddress != '')
            CcEmailflag = true;
        String[] toAddresses = toAddress.split(',');
        List < String > ccAddresses = new List < String > ();
        if (ccAddress != null && ccAddress != '') {
            ccAddresses = ccAddress.split(',');
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        if (CcEmailflag == true) {
            mail.setCcAddresses(ccAddresses);
        }
        mail.setPlainTextBody(bodytext);
        mail.setHtmlBody(htmltext);
        mail.setSubject(Subject);
        mail.setOrgWideEmailAddressId(GsmUtilClass.getPRMSettingValue('Partner_Portal_Email_Id')); //SFDC-2573
        mail.setSaveAsActivity(false);
        return mail;
    }

    public static Messaging.SingleEmailMessage NotifyOthersMail(EmailTemplate notifyOthersTemplate, Contact con, User partnerUser) {
        String emailTextBody, emailHTMLBody, emailToList;
        Messaging.SingleEmailMessage notifyOthersMail;

        emailToList = con.Account.Owner.Email;
        Set < String > emailCCSet = new Set < String > ();

        for (Channel_Mapping__c cm: [SELECT Id,
                PAE_ID__c, PAE_ID__r.Email, MDF_Approver__c,
                MDF_Approver__r.Email, MDF_Approver__r.IsActive
                FROM Channel_Mapping__c
                WHERE VAR_Manager_Status__c = 'Active'
                AND Master_Channel_Mapping__c = true
                AND Partner_Name__c =: con.Account.id
                AND Active__c = true
            ]) {
            if (cm.PAE_ID__r.Email != null) {
                emailCCSet.add(cm.PAE_ID__r.Email);
            }
            if (cm.MDF_Approver__r.Email != null && cm.MDF_Approver__r.IsActive) {
                emailCCSet.add(cm.MDF_Approver__r.Email);
            }
        }
        String emailCCList_ManagePartnerOperations = NAPSettings.getValue('emailCCList_ManagePartnerOperations');
        if (emailCCList_ManagePartnerOperations != null && emailCCList_ManagePartnerOperations != '') {
            emailCCSet.addAll(emailCCList_ManagePartnerOperations.split(','));
        }
        String emailCCList = String.join(new List < String > (emailCCSet), ', ');

        emailHTMLBody = replaceTemplatePlaceholders(notifyOthersTemplate.HtmlValue, con);
        emailTextBody = replaceTemplatePlaceholders(notifyOthersTemplate.Body, con);

        notifyOthersMail = createSingleEmail(emailToList, emailCCList, notifyOthersTemplate.Subject, emailTextBody, emailHTMLBody);

        return notifyOthersMail;
    }

    public static void sendPartnerWelcomeMails(String tempPassword, Contact con, User partnerUser, Boolean resetPasswordOnly) {

        EmailTemplate toAdminTemplate, notifyOthersTemplate, toUserTemplate, AUWelcomeTemplate, NAPUserPasswordResetTemplate, AUUserPasswordResetTemplate;
        List < Messaging.SingleEmailMessage > sendEmailList = new List < Messaging.SingleEmailMessage > ();

        for (EmailTemplate emt: [select Id, DeveloperName, Body, HtmlValue, Subject
                from EmailTemplate
                where DeveloperName IN('Akamai_Netalliance_Welcome_Admin_Luna_HTML',
                    'Akamai_Netalliance_Welcome_User_Luna_HTML',
                    'Akamai_Netalliance_Welcome_Admin_Notify_Luna_HTML',
                    'Akamai_University_Welcome_User_Luna_HTML',
                    'Akamai_Netalliance_Luna_Password_Reset_HTML',
                    'Akamai_University_Luna_Password_Reset_HTML')
            ]) {

            if (emt.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_Luna_HTML') {
                toAdminTemplate = emt;
            } else if (emt.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_Notify_Luna_HTML') {
                notifyOthersTemplate = emt;
            } else if (emt.DeveloperName == 'Akamai_Netalliance_Welcome_User_Luna_HTML') {
                toUserTemplate = emt;
            } else if (emt.DeveloperName == 'Akamai_University_Welcome_User_Luna_HTML') {
                AUWelcomeTemplate = emt;
            } else if (emt.DeveloperName == 'Akamai_Netalliance_Luna_Password_Reset_HTML') {
                NAPUserPasswordResetTemplate = emt;
            } else if (emt.DeveloperName == 'Akamai_University_Luna_Password_Reset_HTML') {
                AUUserPasswordResetTemplate = emt;
            }
        }

        if (resetPasswordOnly) {
            sendEmailList.add(CreatePartnerMail(tempPassword, NAPUserPasswordResetTemplate, con));
        } else {
            if (String.valueOf(partnerUser.ProfileId).contains(GSMUtilClass.getPRMSettingValue('Partner_Admin_Id'))) {
                sendEmailList.add(CreatePartnerMail(tempPassword, toAdminTemplate, con));
                sendEmailList.add(NotifyOthersMail(notifyOthersTemplate, con, partnerUser));
            } else {
                sendEmailList.add(PartnerUserWelcomeMail(tempPassword, toUserTemplate, con));
            }
        }

        if (!sendEmailList.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(sendEmailList, false);
            for (Messaging.SendEmailResult sendEmailResult: results) {
                if (!sendEmailResult.isSuccess()) {
                    for (Messaging.Sendemailerror sendEmailError: sendEmailResult.getErrors()) {
                        throw new CustomException('oh no' + sendEmailError.Message);
                    }
                } else {
                    //sawyer.saw(e);
                }
            }
        }
    }

    @AuraEnabled
    public static Map < String, String > updateUserAccess(String updatedUserJSON, String partnerContactJSON) {
        User updatedUser = (User) JSON.deserialize(updatedUserJSON, User.Class);
        Contact partnerContact = (Contact) JSON.deserialize(partnerContactJSON, Contact.Class);

        Map < String, String > mapOfReturnValues = new Map < String, String > ();
        Boolean toggle = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutonomyForContactProvisioning'); //taruni SFDC 7460

        try {
            List < String > profileIdAndName = getProfile(updatedUser);
            updatedUser.ProfileId = profileIdAndName[0];
            /*
             * SFDC- 7361 - NAP Portal Provisioning permissions adjustments
             * View Content in portal will be default on for the Partner User
             * has akamai university access should be default on 
             */
            updatedUser.Has_view_content_in_portals__c = true;
            //End of SFDC- 7361

            updatedUser.Has_Partner_Lead_View_Access__c = setLeadAccess(updatedUser);
            // taruni SFDC 7460 
            if ((partnerContact.Account != null && partnerContact.Account.Autonomy_Partner__c && toggle) || Test.isRunningTest()) {

                updatedUser.Has_CPQ_AutonomyAdmin__c = false;
                updatedUser.Has_CPQ_Autonomy_QuoteOnly__c = false;

                if (updatedUser.Can_Accept_POA__c) {
                    updatedUser.Has_CPQ_AutonomyAdmin__c = true;
                } else if (updatedUser.Has_DealRegistration_Access__c) {
                    updatedUser.Has_CPQ_Autonomy_QuoteOnly__c = true;
                }
            }
            update updatedUser;
            updateRemoveUserPermissionSet(updatedUser, partnerContact);
            User userRec = getPartnerUser(partnerContact.Id);
            mapOfReturnValues.put('partnerUserProfileName', profileIdAndName[1]);
            mapOfReturnValues.put('partnerUserRoleName', userRec.UserRole.Name);
            mapOfReturnValues.put('UpdatedUser', JSON.serialize(userRec));
        } catch (Exception e) {
            sawyer.saw(e);
            mapOfReturnValues.put('Exception', String.valueOf(e.getMessage()));
        }
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Map < String, String > getCurrentContactAndUserDetails(Id contactId) {
        Map < String, String > mapOfReturnValues = new Map < String, String > ();
        Contact partnerContact = getPartnerContact(contactId);
        Id partnerAccountId = partnerContact.Account.Id;
        User partnerUser;
        String errorMessage = '';
        Boolean isAccountConcierge = false;
        Boolean userNotPresentInDB = true;
        Boolean isSFCommunityUser = false;

        if (partnerContact != null) {
            String firstName = partnerContact.FirstName != null ? partnerContact.FirstName : '';
            String lastName = partnerContact.LastName != null ? partnerContact.LastName : '';

            firstName = firstName.replaceAll('\\s', '');
            lastName = lastName.replaceAll('\\s', '');

            Boolean firstName_Flag = Pattern.matches('\\w+', firstName);
            Boolean lastName_Flag = Pattern.matches('\\w+', lastName);

            if (!(firstName_Flag && lastName_Flag)) {
                errorMessage = GSMSettings.getValue('manageOperationsContactSpecialCharErrMsg');
                mapOfReturnValues = addErrorMessage(mapOfReturnValues, errorMessage);
                return mapOfReturnValues;
            }
        }

        if (partnerContact != null && partnerContact.Account.IsPartner) {
            partnerUser = getPartnerUser(contactId);

            if (partnerUser == null) {
                partnerUser = createPartnerUser(partnerContact);
            } else if (partnerUser.ProfileId != null && (NAPSettings.getValue('SFCommunityCustomers_ProfileId').contains(String.valueOf(partnerUser.ProfileId).subString(0, 15)))) {
                isSFCommunityUser = true;
                partnerUser = createPartnerUser(partnerContact);
            } else {
                userNotPresentInDB = false;
            }
            isAccountConcierge = partnerContact.Account.Partner_Concierge_Access__c;

        } else if (partnerContact != null && partnerContact.Account.IsPartner == false) {
            errorMessage = Label.Account_is_not_Partner_enabled;
        } else {
            errorMessage = Label.Invalid_Contact_ID;
        }
        try {

            List < SelectOptionPicklistClass > profileOptions = getUserProfileOptions(partnerUser, partnerContact, userNotPresentInDB);
            List < SelectOptionPicklistClass > roleOptions = getUserRoleOptions(partnerUser, partnerContact, userNotPresentInDB);
            Map < Id, String > idToName = new Map < Id, String > ();
            mapOfReturnValues.put('userProfile_PicklistVals', JSON.serialize(profileOptions));

            for (SelectOptionPicklistClass sopc: roleOptions) {
                idToName.put(sopc.value, sopc.label);
                if (userNotPresentInDB && sopc.label.containsIgnoreCase(NAPSettings.getValue('Default_Role'))) {
                    partnerUser.UserRoleId = sopc.value;
                }
            }
            for (SelectOptionPicklistClass sopc: profileOptions) {
                idToName.put(sopc.value, sopc.label);
            }

            mapOfReturnValues.put('userRole_PicklistVals', Json.serialize(roleOptions));
            mapOfReturnValues.put('isAccountConcierge', String.valueOf(isAccountConcierge));
            mapOfReturnValues = addErrorMessage(mapOfReturnValues, errorMessage);
            mapOfReturnValues.put('partnerContact', JSON.serialize(partnerContact));
            mapOfReturnValues.put('partnerUserProfileName', partnerUser.Profile.Name);
            mapOfReturnValues.put('partnerUserRoleName', partnerUser.UserRole.Name);
            mapOfReturnValues.put('partnerUser', JSON.serialize(partnerUser));
            mapOfReturnValues.put('idToName', JSON.serialize(idToName));
            mapOfReturnValues.put('userNotPresentInDB', String.valueOf(userNotPresentInDB));
            mapOfReturnValues.put('isSFCommunityUser', String.valueOf(isSFCommunityUser));
            mapOfReturnValues.put('userFoundFlag', String.valueOf(partnerUser != null));
            mapOfReturnValues.put('userThemeDisplayed', GSMLite_UtilClass.getUIThemeDescription());
            mapOfReturnValues.put('isUserInNap', String.valueOf(Network.getNetworkId() != null));
            //SFDC-5666
            mapOfReturnValues.put('hasTableauEditAccess', String.valueOf(isProfileEnabledForTableau()));
        } catch (Exception e) {
            sawyer.saw(e);
            mapOfReturnValues.put('Exception', String.valueOf(e));
        }

        return mapOfReturnValues;
    }
    //SFDC-5666
    public static Boolean isProfileEnabledForTableau() {
        String profilesForTableauAccess = NAPSettings.getValue('ProfilesForTableauAccess_ManageOperation');
        if (profilesForTableauAccess != null && profilesForTableauAccess.contains(String.valueOf(UserInfo.getProfileId()).subString(0, 15))) {
            return true;
        }
        return false;
    }

    public static Map < String, String > addErrorMessage(Map < String, String > mapOfReturnValues, String errorMessage) {
        if (mapOfReturnValues != null && mapOfReturnValues.containsKey('errorMessage')) {
            String previousErrrorMessage = mapOfReturnValues.get('errorMessage');
            mapOfReturnValues.put('errorMessage', previousErrrorMessage + '\n' + errorMessage);
        } else {
            mapOfReturnValues.put('errorMessage', errorMessage);
        }
        return mapOfReturnValues;
    }

    public static Map < String, Object > addErrorMessage(Map < String, Object > mapOfReturnValues, String errorMessage) {
        if (mapOfReturnValues != null && mapOfReturnValues.containsKey('errorMessage')) {
            String previousErrrorMessage = String.valueOf(mapOfReturnValues.get('errorMessage'));
            mapOfReturnValues.put('errorMessage', previousErrrorMessage + '\n' + errorMessage);
        } else {
            mapOfReturnValues.put('errorMessage', errorMessage);
        }
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Boolean deactivateSFCommunityUser(Id contactId) {
        List < User > listOfSFCommunityUsersForThisContact = [SELECT Id, ContactId, FederationIdentifier, Email, UserName, IsActive, IsPortalEnabled FROM User Where ContactId =: contactId];
        List < User > initialUpdateList = new List < User > ();
        for (User eachUser: listOfSFCommunityUsersForThisContact) {
            eachUser.FederationIdentifier = '';
            eachUser.Email = 'Invalid_' + eachUser.Email;
            eachUser.UserName = eachUser.UserName + '_Invalid';

            eachUser.IsPortalEnabled = false;
            eachUser.IsActive = false;
        }
        if (listOfSFCommunityUsersForThisContact.size() > 0) {
            try {
                update listOfSFCommunityUsersForThisContact;
            } catch (Exception e) {
                sawyer.saw(e);
                return false;
            }
        }
        return true;
    }

    @AuraEnabled
    public static Map < String, String > addUser(String userRecordJSON,
        String partnerContactJSON,
        Boolean userNotPresentInDB,
        Boolean sendEmail_Required,
        String partnerUserRoleName,
        String partnerUserProfileName) {

        User userRecord = (User) JSON.deserialize(userRecordJSON, User.Class);
        Contact partnerContact = (Contact) JSON.deserialize(partnerContactJSON, Contact.Class);

        Boolean wasUserActive = userRecord.isActive; //SFDC-8884
        userRecord.IsActive = true;
        Map < String, String > mapOfReturnValues = new Map < String, String > ();
        mapOfReturnValues.put('userNotPresentInDB', String.valueOf(userNotPresentInDB));
        Boolean toggle = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutonomyForContactProvisioning'); //taruni SFDC 7460

        try {
            // Enable All permissions for Partner Admin
            List < String > profileIdAndName = getProfile(userRecord);
            userRecord.ProfileId = profileIdAndName[0];
            String profileId = userRecord.ProfileId;
            /*
             * SFDC- 7361 - NAP Portal Provisioning permissions adjustments
             * View Content in portal will be default on for the Partner User 
             */
            userRecord.Has_view_content_in_portals__c = true;
            //End of SFDC- 7361

            // if (profileId.contains(GSMUtilClass.getPRMSettingValue('Partner_Admin_Id'))) {
            //     if (partnerContact.Account.Partner_Type__c != 'SRA Partner') {
            //         userRecord.Has_MDF_Access__c = true;
            //         userRecord.Has_DealRegistration_Access__c = true;
            //         userRecord.Has_PartnerCertification_Access__c = true;
            //         userRecord.Has_PartnerPlans_Access__c = true;
            //         userRecord.Has_Partner_Concierge_Access__c = partnerContact.Account.Partner_Concierge_Access__c;
            //     }
            //     userRecord.Can_Accept_POA__c = true;
            // } // Taruni SFDC-8684

            //taruni SFDC 7460
            if (partnerContact.Account != null && partnerContact.Account.Autonomy_Partner__c && toggle) {
                userRecord.Has_CPQ_AutonomyAdmin__c = false;
                userRecord.Has_CPQ_Autonomy_QuoteOnly__c = false;
                if (userRecord.Can_Accept_POA__c) {
                    userRecord.Has_CPQ_AutonomyAdmin__c = true;
                } else if (userRecord.Has_DealRegistration_Access__c) {
                    userRecord.Has_CPQ_Autonomy_QuoteOnly__c = true;
                }
            }

            String Level3PartnerAccountAKAMId = GSMSettings.getValue('Level3PartnerAccountAKAMId');
            if (!Level3PartnerAccountAKAMId.contains(partnerContact.Account.AKAM_Account_Id__c)) {
                userRecord.Has_view_content_in_portals__c = true;
            }

            if (userNotPresentInDB) {
                //SFDC-7818 : @nadesai : add a check for saml only flag, before resetting user password
                PulsarIDMCalloutClass callOutObject = new PulsarIDMCalloutClass(partnerContact);
                Boolean isSamlOnlyUser = callOutObject.checkIfSAMLOnlyUser();
                String tempPassword = null;
                if (!isSamlOnlyUser) {
                    tempPassword = callOutObject.resetPassword();
                }

                insert userRecord;
                userNotPresentInDB = false;

                if (!isSamlOnlyUser && tempPassword != null) {
                    sendPartnerWelcomeMails(tempPassword, partnerContact, userRecord, false);
                } else if(isSamlOnlyUser){
                    sendPartnerWelcomeMails('No Password Required, use SSO', partnerContact, userRecord, false);
                }
                mapOfReturnValues.put('successMessage', 'Portal Access has been enabled');
            } else {
                //SFDC-8884
                
                update userRecord;
                if (wasUserActive!= null && !wasUserActive){
                 EmailTemplate testTemplate; 
       			 List < Messaging.SingleEmailMessage > sendEmailList = new List < Messaging.SingleEmailMessage > ();
                 String tempPassword = 'no password req';
                        EmailTemplate emt =  [select Id, DeveloperName, Body, HtmlValue, Subject
                        from EmailTemplate
                        where DeveloperName = 'Reenable_Welcome_Email'][0];
                        testTemplate = emt;
                        sendEmailList.add(CreatePartnerMail(tempPassword, testTemplate, partnerContact));
                         if (!sendEmailList.isEmpty()) {
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(sendEmailList, false);
                        for (Messaging.SendEmailResult sendEmailResult: results) {
                            if (!sendEmailResult.isSuccess()) {
                                for (Messaging.Sendemailerror sendEmailError: sendEmailResult.getErrors()) {
                                    throw new CustomException('oh no' + sendEmailError.Message);
                                }
                            } else {
                           
                        	}	
                    	}
                	}
            }
                mapOfReturnValues.put('successMessage', 'Portal Access has been updated');
            }
            updateRemoveUserPermissionSet(userRecord, partnerContact);
            mapOfReturnValues.put('userNotPresentInDB', String.valueOf(userNotPresentInDB));
            mapOfReturnValues.put('partnerUserProfileName', profileIdAndName[1]);
            mapOfReturnValues.put('partnerUserRoleName', partnerUserRoleName);
            mapOfReturnValues.put('userRecord', JSON.serialize(userRecord));
        } catch (Exception e) {
            sawyer.saw(e);
            mapOfReturnValues = addErrorMessage(mapOfReturnValues, String.valueOf(e));
        }

        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Map < String, String > enableAccessToUser(
        String updatedUserJSON,
        String partnerContactJSON,
        Boolean userNotPresentInDB,
        String partnerUserRoleName,
        String partnerUserProfileName) {

        createPartnerUserRun = true; // SFDC-9797 @hpandey
        User updatedUser = (User) JSON.deserialize(updatedUserJSON, User.Class);
        Contact partnerContact = (Contact) JSON.deserialize(partnerContactJSON, Contact.Class);

        Map < String, String > mapOfReturnValues = new Map < String, String > ();

        try {

            PulsarIDMCalloutClass callOutObject = new PulsarIDMCalloutClass(partnerContact);
            PulsarIDMCalloutClass.UserReturnClass pulsarUserRecord;
            mapOfReturnValues.put('sendEmail_Required', String.ValueOf(true));
            if (!callOutObject.userExistsInPulsar()) {
                if (partnerContact.Phone != null && !String.isEmpty(partnerContact.Phone)) {
                    pulsarUserRecord = callOutObject.createUser();
                } else {
                    mapOfReturnValues = addErrorMessage(mapOfReturnValues, 'Phone Number Invalid/Empty. Please provide valid phone number and try again');
                }
            }
            if (partnerContact.Account.PulsarAPI_DetailsJSON__c == null || (partnerContact.Account.PulsarAPI_DetailsJSON__c != null && partnerContact.Account.PulsarAPI_DetailsJSON__c == '')) {
                callOutObject.updateAPIDetailsOnAccount(partnerContact.Account.Id);
            }
            if (PulsarUserRecord != null && PulsarUserRecord.uiIdentityId != null) {
                callOutObject.updateAKAMContactIDAndPasswordResetTime(PulsarUserRecord.uiIdentityId, partnerContact.Has_Akamai_University_Access__c);
                partnerContact.AKAM_Contact_ID__c = PulsarUserRecord.uiIdentityId; // new bug
                mapOfReturnValues.put('AKAM_Contact_ID__c', PulsarUserRecord.uiIdentityId);
            } else {
                callOutObject.updateUniversityAccess(partnerContact.Has_Akamai_University_Access__c);
            }
        } catch (Exception e) {
            sawyer.saw(e);
            String exceptionValue = String.valueOf(e);
            String userUpdateFailureTokenString = NAPSettings.getValue('User_Provisioning_Error_Tokens');
            List < String > failureTokens = userUpdateFailureTokenString.split(',');
            Boolean showAkamaiSucessLunaFailureMsg = false;
            for (String s: failureTokens) {
                if (String.valueOf(e).contains(s)) {
                    showAkamaiSucessLunaFailureMsg = true;
                }
            }
            if (showAkamaiSucessLunaFailureMsg) {
                String userProvisioningErrorPrefix = NAPSettings.getValue('User_provisioning_error_prefix');
                exceptionValue += userProvisioningErrorPrefix;
            }
            mapOfReturnValues = addErrorMessage(mapOfReturnValues, exceptionValue);
            Contact con = new Contact(id = partnerContact.id);
        }

        //mapOfReturnValues.put('isAU_Mode', String.valueOf(isAUMode));
        mapOfReturnValues.put('isAU_Mode', String.valueOf(false));
        mapOfReturnValues.put('userNotPresentInDB', String.valueOf(userNotPresentInDB));
        mapOfReturnValues.put('partnerUserRoleName', partnerUserRoleName);
        mapOfReturnValues.put('partnerUserProfileName', partnerUserProfileName);
        mapOfReturnValues.put('partnerContact.Phone', partnerContact.Phone);
        /*
         * SFDC-7423 Adding partnerContact to response, as the contact will carry the temp password
         */
        mapOfReturnValues.put('partnerContact', JSON.serialize(partnerContact));
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Map < String, String > resetUserPassword(String userRecordJSON, String contactRecordJSON) {
        User userRecord = (User) JSON.deserialize(userRecordJSON, User.Class);
        Contact contactRecord = (Contact) JSON.deserialize(contactRecordJSON, Contact.Class);
        Map < String, String > mapOfReturnValues = new Map < String, String > ();
        //Boolean isAUMode = isAUMode(userRecord,true, contactRecord.Has_Akamai_University_Access__c);
        try {
            PulsarIDMCalloutClass callOutObject = new PulsarIDMCalloutClass(contactRecord);
            //SFDC-7818 : @nadesai : Start - 
            //            check if the user has enabled saml only flag, before resetting user password
            if (callOutObject.checkIfSAMLOnlyUser()) {
                mapOfReturnValues.put('errorMessage', 'Password reset not possible as Saml Only User');
                return mapOfReturnValues;
            }
            //SFDC-7818 : @nadesai : End

            String newPassword = callOutObject.resetPassword();
            callOutObject.updateAKAMContactIDAndPasswordResetTime(null, contactRecord.Has_Akamai_University_Access__c);
            sendPartnerWelcomeMails(newPassword, contactRecord, userRecord, true);

            mapOfReturnValues.put('successMessage', Label.Password_has_been_reset_and_new_password_has_been_sent_by_email_to + ' ' + userRecord.Email);
        } catch (Exception e) {
            sawyer.saw(e);
            mapOfReturnValues = addErrorMessage(mapOfReturnValues, String.valueOf(e));
        }
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Map < String, String > disablContactAccess(String partnerContactJSON) {
        Contact partnerContact = (Contact) JSON.deserialize(partnerContactJSON, Contact.Class);
        Map < String, String > mapOfReturnValues = new Map < String, String > ();

        partnerContact.Has_Akamai_University_Access__c = false;
        partnerContact.DoNotSync__c = false;
        partnerContact.Validation_Override__c = true;
        try {
            update partnerContact;
            mapOfReturnValues.put('successMessage', 'Akamai University access has been disabled');
        } catch (Exception e) {
            sawyer.saw(e);
            mapOfReturnValues = addErrorMessage(mapOfReturnValues, e.getMessage());
        }
        mapOfReturnValues.put('partnerContactRecord', JSON.serialize(partnerContact));
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Map < String, String > disablUserAccess(String userRecordJSON) {
        User userRecord = (User) JSON.deserialize(userRecordJSON, User.Class);
        Map < String, String > mapOfReturnValues = new Map < String, String > ();

        if (userRecord != null && userRecord.IsActive) {
            userRecord.IsActive = false;
            try {
                update userRecord;
                mapOfReturnValues.put('userRecord', JSON.serialize(userRecord));
                mapOfReturnValues.put('successMessage', 'Portal Access has been disabled');
            } catch (Exception e) {
                sawyer.saw(e);
                mapOfReturnValues = addErrorMessage(mapOfReturnValues, e.getMessage());
            }
        }
        return mapOfReturnValues;
    }

    @AuraEnabled
    public static Boolean setDoNotSyncFlag(String contactRecordJSON) {
        Contact cR = (Contact) JSON.deserialize(contactRecordJSON, Contact.Class);
        Contact contactRecord = new Contact(Id = cr.Id, DoNotSync__c = true, Validation_Override__c = true);
        try {
            update contactRecord;
            return true;
        } catch (Exception e) {
            sawyer.saw(e);
        }
        return false;
    }

    @AuraEnabled
    public static Boolean deSetDoNotSyncFlag(String contactRecordJSON) {
        Contact cR = (Contact) JSON.deserialize(contactRecordJSON, Contact.Class);
        Contact contactRecord = new Contact(Id = cr.Id, DoNotSync__c = false, Validation_Override__c = true);
        try {
            update contactRecord;
            return true;
        } catch (Exception e) {
            sawyer.saw(e);
        }
        return false;
    }

    //SFDC-8760 - Start
   public static void erasePermissionsAndRevokeAccess(List<User> inactivatedPartnerUserList) {
    if(erasePermissionsAndRevokeAccessHasRun) {
        return;
    }
    erasePermissionsAndRevokeAccessHasRun = true;

    List<PermissionSetLicenseAssign> listOfPermissionSetLicences =  [SELECT Id, PermissionSetLicenseId FROM PermissionSetLicenseAssign 
                        WHERE AssigneeId =: inactivatedPartnerUserList AND PermissionSetLicenseId = :NAPSettings.getValue('PartnerAccessGroup_CPQLicenceId')];        

    PermissionSetManager psManager = new PermissionSetManager();
    List<String> permissionSetIdList = psManager.getMapOfFieldsVsPermissionSetId().values();
    List<PermissionSetAssignment> listOfPermissions = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :inactivatedPartnerUserList AND ( PermissionSetId IN :permissionSetIdList OR PermissionSetGroupId IN :permissionSetIdList )];

    try {
        delete listOfPermissions;
        delete listOfPermissionSetLicences;
    } catch(Exception e) {
        Sawyer.saw(e);
    }
    Set < String > userFieldSchema = Schema.SObjectType.User.fields.getMap().keySet();
    Set<String> contactFields = new Set<String>();
    List<Id> userIdList = new List<Id>();
    for(User eachUser : inactivatedPartnerUserList) {
        userIdList.add(eachuser.Id);
        for(String eachField : psManager.getMapOfFieldsVsPermissionSetId().keySet()) {
            if(userFieldSchema.contains(eachField.toLowerCase())) {
                eachUser.put(eachField, false);
            } else {
                contactFields.add(eachField);
            }
        }
    }

    if(contactFields.size() > 0) {
        String queryString = 'SELECT Id';
        for(String eachContactField : contactFields) {
            queryString += ', ' + eachContactField;
        }
        queryString.removeEnd(', ');
        queryString += ' FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Id IN :userIdList)';

        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact eachContact : Database.query(queryString)) {
            Boolean eachContactHasChanges = false;
            for(String eachField : contactFields) {
                if(Boolean.valueOf(eachContact.get(eachField))) {
                    eachContact.put(eachField, false);
                    eachContactHasChanges = true;
                }
            }
            contactsToUpdate.add(eachContact);
        }

        if(contactsToUpdate.size() > 0) {
            try {
                update contactsToUpdate;
            } catch(Exception e) {
                Sawyer.saw(e);
            }
        }
    }
}
//SFDC-8760 - End

}