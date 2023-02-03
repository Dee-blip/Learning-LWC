@isTest(seeAllData = false)
private class L2Q_ManagePartnerOperationsTestClass {

    @testSetUp static void insertCustomSettingsAndCreateData() {

        System.runAs(utilTestClass.getTestRunUser()) {

            // SFDC-6405
            Account partnerAccount = (Account) new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Partner_Type__c, 'ADS Partner')
                .put(Account.Partner_Status__c, 'Partner')
                .put(Account.Partner_Tier__c, 'Registered')
                //.put(Account.Partner_Tier__c, 'Standard')
                .put(Account.POA_Email_List__c, 'fdajkldf@akamai.com')
                .put(Account.Partner_Reach__c, 'AMER')
                .create()
                .getRecord();

            partnerAccount.IsPartner = true;
            partnerAccount.IsPartnerCustom__c = true;
            partnerAccount.Validation_Override__c = true;
            update partnerAccount;

            List < Contact > partnerContacts = (List < Contact > ) new SobjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, partnerAccount.Id)
                .put(Contact.Subscribed_to_Library__c, true)
                .put(Contact.Active_Partner__c, true)
                .count(1)
                .create()
                .getRecords();

            new SobjectBuilder(API_Connector_Object__c.sObjectType)
                .eagerPopulate()
                .put(API_Connector_Object__c.Name, 'PulsarSQAForTestClass')
                .create();
        }
    }

    static testmethod void testNAPSettings() {
        Set < String > fieldsToBeTranslated = NAPSettings.getValues('PartnerProfileFieldsToBeTranslated');
        Integer fileLifeValue = NAPSettings.getInt('ContentDeliveryFileLifeValue');
        NAPSettings.getSet('PPProductFamily_Cloud_Security');
    }

    static testmethod void testAkamaiUniversityAccess() {
        List < Contact > partnerContacts = [SELECT Id, Name, FirstName, LastName, Email, MailingState, MailingCountry, Phone, Partner_User__c, Company__c, NetAlliance_User_Profile__c, DoNotSync__c, Validation_Override__c, AKAM_Contact_ID__c, Active_Portal_Login__c, Has_Akamai_University_Access__c, Login__c, Account.Id, Account.Name, Account.OwnerId, Account.Owner.Name, Account.Owner.Email, Account.IsPartner, Account.AKAM_Account_ID__c, Account.Partner_Type__c, Account.PulsarAPI_DetailsJSON__c, Account.Current_Licenses__c, Account.Maximum_Licenses__c, Account.Partner_Concierge_Access__c
            FROM Contact LIMIT 1
        ]; //Added limit as part of SDFC 7172

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'userExistsInPulsar_Negative',
            'PulsarAPI_GroupDetails_Positive',
            'PulsarAPI_RoleDetails_Positive',
            'PulsarAPI_CreateUser_Positive',
            'PulsarAPI_CreateUser_Positive'
        }));
        Map < String, String > initialDataMap = L2Q_ManagePartnerOperationsController.getCurrentContactAndUserDetails(partnerContacts.get(0).Id);
        User userRecord = (User) JSON.deserialize(initialDataMap.get('partnerUser'), User.Class);
        Contact mainPartnerContact = (Contact) JSON.deserialize(initialDataMap.get('partnerContact'), Contact.Class);

        mainPartnerContact.Has_Akamai_University_Access__c = true;

        Map < String, String > returnMap = L2Q_ManagePartnerOperationsController.enableAccessToUser(JSON.serialize(userRecord), JSON.serialize(mainPartnerContact), true, initialDataMap.get('partnerUserRoleName'), initialDataMap.get('partnerUserProfileName'));

        //System.AssertEquals(null, returnMap.get('errorMessage'));
        Map < String, Object > errorMap = new Map < String, Object > ();
        errorMap = L2Q_ManagePartnerOperationsController.addErrorMessage(errorMap, 'First Error');
        errorMap = L2Q_ManagePartnerOperationsController.addErrorMessage(errorMap, 'Second Error');

        Test.stopTest();
    }

    static testmethod void testNAP_Access() {
        List < Contact > partnerContacts = [SELECT Id, Name, FirstName, LastName, Email, MailingState, MailingCountry, Phone, Partner_User__c, Company__c, NetAlliance_User_Profile__c, DoNotSync__c, Validation_Override__c, AKAM_Contact_ID__c, Active_Portal_Login__c, Has_Akamai_University_Access__c, Login__c, Account.Id, Account.Name, Account.OwnerId, Account.Owner.Name, Account.Owner.Email, Account.IsPartner, Account.AKAM_Account_ID__c, Account.Partner_Type__c, Account.PulsarAPI_DetailsJSON__c, Account.Current_Licenses__c, Account.Maximum_Licenses__c, Account.Partner_Concierge_Access__c
            FROM Contact LIMIT 1
        ]; //Added limit as part of SDFC 7172

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'PulsarAPI_SAMLONLYUSER',
            'PulsarAPI_resetPassword_Positive'
        }));
        Map < String, String > initialDataMap = L2Q_ManagePartnerOperationsController.getCurrentContactAndUserDetails(partnerContacts.get(0).Id);
        User userRecord = (User) JSON.deserialize(initialDataMap.get('partnerUser'), User.Class);
        Contact mainPartnerContact = (Contact) JSON.deserialize(initialDataMap.get('partnerContact'), Contact.Class);

        mainPartnerContact.Has_Akamai_University_Access__c = true;
        userRecord.Has_MDF_Access__c = true;
        userRecord.Has_DealRegistration_Access__c = true;
        userRecord.Can_Accept_POA__c = true;
        userRecord.Has_view_content_in_portals__c = true;
        // userRecord.Has_PartnerPlans_Access__c = true;
        // userRecord.Has_PartnerCertification_Access__c = true;
        // userRecord.View_Pricing_Details__c = true;
        // userRecord.Has_Partner_Concierge_Access__c = true;
        // userRecord.Has_Start_Trial_Access__c = true;
        // userRecord.Has_View_Trial_Access__c = true;
        userRecord.ProfileId = Id.valueOf(NAPSettings.getValue('PartnerCommunityUserProfileId'));
        userRecord.isActive = true;

        Map < String, String > returnMap = L2Q_ManagePartnerOperationsController.addUser(JSON.serialize(userRecord), JSON.serialize(mainPartnerContact), true, false, initialDataMap.get('partnerUserRoleName'), initialDataMap.get('partnerUserProfileName'));
        userRecord = (User) JSON.deserialize(returnMap.get('userRecord'), User.Class);
        returnMap = L2Q_ManagePartnerOperationsController.updateUserAccess(JSON.serialize(userRecord), JSON.serialize(mainPartnerContact));

        Map < String, Object > errorMap = new Map < String, Object > ();
        errorMap = L2Q_ManagePartnerOperationsController.addErrorMessage(errorMap, 'First Error');
        errorMap = L2Q_ManagePartnerOperationsController.addErrorMessage(errorMap, 'Second Error');
        L2Q_ManagePartnerOperationsController.sendPartnerWelcomeMails('', mainPartnerContact, userRecord, false);

        userRecord.isActive = true;
        //L2Q_ManagePartnerOperationsController.disablUserAccess(JSON.serialize(userRecord));
        L2Q_ManagePartnerOperationsController.getPortalAdminString(mainPartnerContact);
        L2Q_ManagePartnerOperationsController.replaceAdmins('test', 'test', 'test');
        List < EmailTemplate > emt = [select Id, DeveloperName, Body, HtmlValue, Subject
            from EmailTemplate
            where DeveloperName IN('Akamai_Netalliance_Welcome_Admin_Luna_HTML', 'Akamai_Netalliance_Welcome_Admin_Notify_Luna_HTML')
        ];
        L2Q_ManagePartnerOperationsController.PartnerUserWelcomeMail('test', emt.get(0), mainPartnerContact);
        L2Q_ManagePartnerOperationsController.NotifyOthersMail(emt.get(1), mainPartnerContact, userRecord);
        // userRecord.FirstName = 'NewTestFirstName';
        // userRecord.LastName = 'NewTestLastName';
        // userRecord.Email = 'NewTestLastName@email.com';
        // userRecord.Username = 'NUT@akamai.com';
        // insert userRecord;
        List < String > profiles = L2Q_ManagePartnerOperationsController.getProfile(userRecord);
        try {
            L2Q_ManagePartnerOperationsController.updateRemoveUserPermissionSet(userRecord, mainPartnerContact);
        } catch (Exception e) {}
        try {
            Boolean bool = L2Q_ManagePartnerOperationsController.deactivateSFCommunityUser(mainPartnerContact.Id);
        } catch (Exception e) {}

        Test.stopTest();
    }

    static testmethod void testResetPassword() {
        List < Contact > partnerContacts = [SELECT Id FROM Contact LIMIT 1]; //Added limit as part of SDFC 7172

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'PulsarAPI_SAMLONLYUSER',
            'PulsarAPI_resetPassword_Positive'
        }));
        Map < String, String > initialDataMap = L2Q_ManagePartnerOperationsController.getCurrentContactAndUserDetails(partnerContacts.get(0).Id);
        User userRecord = (User) JSON.deserialize(initialDataMap.get('partnerUser'), User.Class);
        Contact mainPartnerContact = (Contact) JSON.deserialize(initialDataMap.get('partnerContact'), Contact.Class);

        Map < String, String > returnMap = L2Q_ManagePartnerOperationsController.resetUserPassword(initialDataMap.get('partnerUser'), initialDataMap.get('partnerContact'));
        PulsarIDMCalloutClass tempObj = new PulsarIDMCalloutClass();
        tempObj.myContact = partnerContacts.get(0);
        tempObj.updateUniversityAccess(true);

        PulsarIDMCalloutClass.OpenIdentityResponse gpr = new PulsarIDMCalloutClass.OpenIdentityResponse();
        gpr.printError();
        Test.stopTest();
    }

    static testmethod void testCreateUserFunctionality() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'PulsarAPI_SAMLONLYUSER',
            'PulsarAPI_resetPassword_Positive'
        }));
        PulsarIDMCalloutClass tempObj = new PulsarIDMCalloutClass();
        PulsarIDMCalloutClass.PulsarUserRecord pur = new PulsarIDMCalloutClass.PulsarUserRecord();
        tempObj.createUser('AccountSwitchKey', pur);
        Test.stopTest();
    }

    static testmethod void testOtherFunctionalities() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'PulsarAPI_SAMLONLYUSER',
            'PulsarAPI_resetPassword_Positive'
        }));
        PulsarIDMCalloutClass tempObj = new PulsarIDMCalloutClass();
        PulsarIDMCalloutClass.PulsarUserRecord pur = new PulsarIDMCalloutClass.PulsarUserRecord();
        tempObj.getGroupUsers('groupId', 'AccountSwitchKey');
        tempObj.logLatestGetCall();
        Test.stopTest();
    }

    static testmethod void disableContactAndUserRecords() {

        // Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
        //         'PulsarAPI_AccountSwitchKeyResponse'
        //         ,'PulsarAPI_resetPassword_Positive'
        // }));
        //
        // PulsarIDMCalloutClass callOutObject = new PulsarIDMCalloutClass(mainPartnerContact);
        //
        // // Map<String, String> returnMap_ResetPassword = L2Q_ManagePartnerOperationsController.resetUserPassword(JSON.serialize(userRecord), JSON.serialize(mainPartnerContact));
        // Test.stopTest();
        List < Contact > partnerContacts = [SELECT Id, Name, FirstName, LastName, Email, MailingState, MailingCountry, Phone, Partner_User__c, Company__c, NetAlliance_User_Profile__c, DoNotSync__c, Validation_Override__c, AKAM_Contact_ID__c, Active_Portal_Login__c, Has_Akamai_University_Access__c, Login__c, Account.Id, Account.Name, Account.OwnerId, Account.Owner.Name, Account.Owner.Email, Account.IsPartner, Account.AKAM_Account_ID__c, Account.Partner_Type__c, Account.PulsarAPI_DetailsJSON__c, Account.Current_Licenses__c, Account.Maximum_Licenses__c, Account.Partner_Concierge_Access__c
            FROM Contact LIMIT 1
        ]; //Added limit as part of SDFC 7172
        Contact mainPartnerContact = partnerContacts.get(0);
        Map < String, String > returnMap = L2Q_ManagePartnerOperationsController.disablContactAccess(JSON.Serialize(mainPartnerContact));
        Boolean isSuccess = L2Q_ManagePartnerOperationsController.setDoNotSyncFlag(JSON.Serialize(mainPartnerContact));
        isSuccess = L2Q_ManagePartnerOperationsController.deSetDoNotSyncFlag(JSON.Serialize(mainPartnerContact));
        Map < String, String > initialDataMap = L2Q_ManagePartnerOperationsController.getCurrentContactAndUserDetails(partnerContacts.get(0).Id);
        L2Q_ManagePartnerOperationsController.updateUserAccess(initialDataMap.get('partnerUser'), initialDataMap.get('partnerContact'));
        returnMap = L2Q_ManagePartnerOperationsController.disablUserAccess(initialDataMap.get('partnerUser'));
        User userRecord = (User) JSON.deserialize(initialDataMap.get('partnerUser'), User.Class);
        String temp = L2Q_ManagePartnerOperationsController.generatePortalAdminString(userRecord);
        PulsarIDMCalloutClass.PulsarUserRecord pulsar_Record1 = new PulsarIDMCalloutClass.PulsarUserRecord();
        PulsarIDMCalloutClass.PulsarUserRecord pulsar_Record = new PulsarIDMCalloutClass.PulsarUserRecord(mainPartnerContact);
        PulsarIDMCalloutClass.UserReturnClass pulsar_Record2 = new PulsarIDMCalloutClass.UserReturnClass();
        PulsarIDMCalloutClass calloutObjectTemp = new PulsarIDMCalloutClass();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CalloutMock(new List < String > {
            'PulsarAPI_AccountSwitchKeyResponse',
            'PulsarAPI_OpenIdentityId_Positive'
        }));
        PulsarIDMCalloutClass calloutObject = new PulsarIDMCalloutClass(mainPartnerContact);
        String openIdentityIdVar = calloutObject.getOpenIdentityId();
        Test.stopTest();
        //calloutObject.updateUniversityAccess(true);

        PulsarIDMCalloutClass.APIDetailsClass tempAPIDetailsClassObject = new PulsarIDMCalloutClass.APIDetailsClass();
        tempAPIDetailsClassObject.groupId = 1234;
        tempAPIDetailsClassObject.roleId = 1234;
        tempAPIDetailsClassObject.groupName = '1234';
        tempAPIDetailsClassObject.roleName = '1234';
        PulsarIDMCalloutClass.AuthGrantClass tempVar = tempAPIDetailsClassObject.toAuthGrant();
        L2Q_ManagePartnerOperationsController.SelectOptionPicklistClass objNew = new L2Q_ManagePartnerOperationsController.SelectOptionPicklistClass('Label', 'Value');

    }
}