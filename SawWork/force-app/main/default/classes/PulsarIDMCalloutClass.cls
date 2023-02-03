public class PulsarIDMCalloutClass extends RestEasyClient {
    public APIDetailsClass apiDeets;
    public Contact myContact;
    private static HttpResponse LatestHttpResponse; //SFDC-6740
    private static HttpRequest LatestHttpRequest; //SFDC-6740
    private static Boolean callLogged; //SFDC-6740

    public PulsarIDMCalloutClass() {
        super(new AkamaiEdgeAuthStrategy());
    }

    public PulsarIDMCalloutClass(Contact contactRecord) {
        super(new AkamaiEdgeAuthStrategy());
        if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UsePulsarAPI_DetailsJSON') &&
            !String.isBlank(contactRecord.Account.PulsarAPI_DetailsJSON__c)) {
            this.apiDeets = (APIDetailsClass) JSON.deserialize(
                contactRecord.Account.PulsarAPI_DetailsJSON__c, APIDetailsClass.Class);
        }
        this.myContact = contactRecord;
        if (this.apiDeets == null || String.isBlank(this.apiDeets.accountSwitchKey)) {
            this.apiDeets = new APIDetailsClass();
            this.apiDeets.accountSwitchKey = getAccountSwitchKey(contactRecord.Account.AKAM_Account_ID__c);
        }

    }

    public virtual class GenericPulsarResponse {
        public String type;
        public String title;
        public Integer status;
        public String detail;
        public String instance;
        public List < String > errors;
        public String incidentId;
        public String solution;
        public String code;
        public Integer httpStatus;

        public Boolean hasErrors() {
            return ((this.httpStatus != null && this.httpStatus >= 300) ||
                (this.status != null && this.status >= 300) || !String.isBlank(this.incidentId));
        }

        public Boolean is404Error() {
            return ((this.httpStatus != null && this.httpStatus == 404) ||
                (this.status != null && this.status == 404));
        }

        public String printError() {
            return String.format(
                '{0}: {1} - {2} ({3})',
                new List < String > {
                    '' + (this.httpStatus != null ? String.valueOf(this.httpStatus) : (this.status != null ? String.valueOf(this.status) : '')),
                    this.title,
                    (this.detail != null ? this.detail : (this.code != null ? this.code : '')),
                    ((this.errors != null && !this.errors.isEmpty()) ? String.join(this.errors, ',') : '')
                }
            );
        }
    }

    public class OpenIdentityResponse extends GenericPulsarResponse {
        public PulsarIdentity identity;
        public List < String > groupAccesss;
        public PulsarAuthorization authorization;

        public List < PulsarService > services;
    }

    public class PulsarIdentity {
        public string openIdentityId;
        public Map < String, String > actions;
        public String uiUserName;
        public String uiIdentityId;
        public String activeCredentialCount;
        public String clientName;

        public String clientDescription;
        public String locked;
        public String allowAccountSwitch;
        public String useLunaUserAccess;
        public String createdDate;
        public String createdBy;
    }

    public class AuthGrantClass {
        public Integer groupId;
        public Integer roleId;
        public String groupName;
        public String roleName;
    }

    public class APIDetailsClass {
        public String accountSwitchKey;
        public Integer groupId;
        public Integer roleId;
        public String groupName;
        public String roleName;

        public AuthGrantClass toAuthGrant() {
            AuthGrantClass singleAuthGrant = new AuthGrantClass();
            singleAuthGrant.groupId = this.groupId;
            singleAuthGrant.groupName = this.groupName;
            singleAuthGrant.roleId = this.roleId;
            singleAuthGrant.roleName = this.roleName;

            return singleAuthGrant;
        }

        public APIDetailsClass(AuthGrantClass singleAuthGrant, String accountSwitchKeyParam) {
            this.accountSwitchKey = accountSwitchKeyParam;
            this.groupId = singleAuthGrant.groupId;
            this.groupName = singleAuthGrant.groupName;
            this.roleId = singleAuthGrant.roleId;
            this.roleName = singleAuthGrant.roleName;
        }

        public APIDetailsClass() {}
    }

    public class OptionsClass {
        public Boolean passwordExpiry;
        public Boolean newUserNotification;
        public List < String > upgrade;
        public List < String > proactive;

        public OptionsClass() {
            this.upgrade = new List < String > ();
            this.proactive = new List < String > ();
            this.passwordExpiry = true;
            this.newUserNotification = false;
        }
    }

    public class NotificationClass {
        public Boolean enableEmailNotifications;
        public OptionsClass options;
        public NotificationClass() {
            this.enableEmailNotifications = false;
            options = new OptionsClass();
        }
    }

    public class PulsarUserRecord {
        public String firstName;
        public String lastName;
        public String uiUserName;
        public String email;
        public String phone;
        public Boolean tfaEnabled;
        public String state;
        public String country;
        public List < AuthGrantClass > authGrants;
        public NotificationClass notifications;
        public PulsarUserRecord() {
            authGrants = new List < AuthGrantClass > ();
            notifications = new NotificationClass();
        }

        public PulsarUserRecord(Contact contactRecord) {
            this.firstName = contactRecord.FirstName;
            this.lastName = contactRecord.LastName;
            this.email = contactRecord.Email;
            this.uiUserName = contactRecord.Email;
            this.phone = contactRecord.Phone;
            this.state = contactRecord.MailingState;
            this.country = contactRecord.MailingCountry;
            this.tfaEnabled = true;
            this.notifications = new NotificationClass();
            this.authGrants = new List < AuthGrantClass > ();
        }

        public PulsarUserRecord(Contact contactRecord, AuthGrantClass authGrantsParam) {
            this.firstName = contactRecord.FirstName;
            this.lastName = contactRecord.LastName;
            this.email = contactRecord.Email;
            this.uiUserName = contactRecord.Email;
            this.phone = contactRecord.Phone;
            this.state = contactRecord.MailingState;
            this.country = contactRecord.MailingCountry;
            this.tfaEnabled = true;
            this.notifications = new NotificationClass();
            this.authGrants = new List < AuthGrantClass > ();

            if (authGrantsParam != null) {
                this.authGrants.add(authGrantsParam);
            }
        }

    }

    public class ResetPasswordPulsarResponse extends GenericPulsarResponse {
        public String newPassword;
    }

    public class UserReturnClass extends GenericPulsarResponse {
        public String uiIdentityId;
        public String firstName;
        public String lastName;
        public String uiUserName;
        public String email;
        public String accountId;
        public String phone;
        public String timeZone;
        public Boolean tfaEnabled;
        public String state;
        public String country;
        public String contactType;
        public String preferredLanguage;
        public String passwordExpiryDate;
        public String address;
        public String userPassword;
        public String tfaConfigured;
        public String isLocked;

        public List < AuthGrantClass > authGrants;
        public NotificationClass notifications;
        public UserReturnClass() {
            authGrants = new List < AuthGrantClass > ();
            notifications = new NotificationClass();
        }
    }

    public class AccountSwitchKeyClass {
        public String accountName;
        public String accountSwitchKey;
    }

    public class GroupClass {
        public Integer groupId;
        public String groupName;
    }

    public class RoleClass {
        public Integer roleId;
        public String roleName;
    }

    public class PulsarGrantScope {
        public String name;
        public String description;
    }

    public class PulsarService {
        public String serviceId;
        public String serviceName;
        public String description;
        public String endpoint;
        public String documentationUrl;
        public String multiGroupAllowed;
        public List < PulsarGrantScope > grantScopes;
    }

    public class PulsarAuthorization {
        public String serviceProvierId;
        public String serviceProviderName;
        public String authorizationId;
        public String openIdentityId;
        public String name;
        public String description;
        public String baseURL;
        public String accessToken;
        public List < PulsarService > services;
    }

    //SFDC-7818
    public class PasswordPolicy {
        public String pwclass;
        public String minLength;
        public String minLetters;
        public String minDigits;
        public String caseDif;
        public String minNonAlpha;
        public String maxRepeating;
        public String minReuse;
        public String rotateFrequency;

        public PasswordPolicy() {}

        public Boolean isSAML_ONLY_User() {
            return this.pwclass == 'saml_only';
        }
    }

    //SFDC-7818
    public Boolean checkIfSAMLOnlyUser() {
        String jsonResponse = getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_SAML_ONLY_USER')
            .replaceAll('UI_IDENTITY_ID', this.myContact.AKAM_Contact_ID__c).replaceAll('Account_Switch_Key', this.apiDeets.accountSwitchKey));

        PasswordPolicy ppol = (PasswordPolicy) JSON.deserialize(jsonResponse, PasswordPolicy.Class);
        if (ppol != null && ppol.pwclass != null) {
            return ppol.isSAML_ONLY_User();
        }
        logLatestGetCall();
        throw new CustomException('Could Not Check if SAML ONLY User');
    }

    public String getOpenIdentityId() {
        String jsonResponse = getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_Open_Identity_Id')
            .replaceAll('ACCESS_TOKEN', this.authStrategy.getConnectorDetails().Access_Token__c));

        OpenIdentityResponse oir = (OpenIdentityResponse) JSON.deserialize(jsonResponse, OpenIdentityResponse.class);
        if (oir.identity != null && oir.identity.openIdentityId != null) {
            return oir.identity.openIdentityId;
        }
        logLatestGetCall(); //SFDC-6740
        throw new CustomException('Could not fetch open identity id:' + oir.printError());
    }

    public String getAccountSwitchKey(String searchParam) {
        String jsonResponse = getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_ACTSWTCH_Key')
            .replaceAll('OPEN_IDENTITY_ID', NAPSettings.getValue('openIdentityId'))
            .replaceAll('ACCOUNT_SWITCH_KEY', searchParam));
        if (jsonResponse == null || jsonResponse == '[]') {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('Account Switch Key could not be fetched for this account.');
        } else if (jsonResponse.startsWith('[')) {
            List < AccountSwitchKeyClass > actKeys = (List < AccountSwitchKeyClass > ) Json.deserialize(
                jsonResponse, List < AccountSwitchKeyClass > .Class);

            String internalSwitchKey, resellerSwitchKey, catchAllKey;
            for (AccountSwitchKeyClass actKey: actKeys) {
                if (actKey.accountName.contains('Reseller')) {
                    resellerSwitchKey = actKey.accountSwitchKey;
                } else if (actKey.accountName.contains('Internal')) {
                    internalSwitchKey = actKey.accountSwitchKey;
                }
                catchAllKey = actKey.accountSwitchKey;
            }

            if (!String.isBlank(resellerSwitchKey)) {
                return resellerSwitchKey;
            }
            if (!String.isBlank(internalSwitchKey)) {
                return internalSwitchKey;
            }
            if (!String.isBlank(catchAllKey)) {
                return catchAllKey;
            }
        } else {
            GenericPulsarResponse gpr = (GenericPulsarResponse) Json.deserialize(jsonResponse, GenericPulsarResponse.Class);
            logLatestGetCall(); //SFDC-6740
            if (gpr != null && gpr.hasErrors()) {
                throw new CustomException('Account Switch Key could not be retrieved:' + gpr.printError());
            } else {
                throw new CustomException('Account Switch Key could not be retrieved:' + jsonResponse);
            }
        }
        logLatestGetCall(); //SFDC-6740
        throw new CustomException('Account Switch Key could not be retrieved:' + jsonResponse);
        return null;

    }

    public UserReturnClass createUser() {
        AuthGrantClass singleAuthGrant = getAuthGrantDetails(apiDeets.accountSwitchKey);
        this.apiDeets = new APIDetailsClass(singleAuthGrant, apiDeets.accountSwitchKey);
        String jsonResponse = getPostResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Create_User')
            .replaceAll('ACCOUNT_SWITCH_KEY', apiDeets.accountSwitchKey), new PulsarUserRecord(myContact, singleAuthGrant));
        if (jsonResponse != null && jsonResponse.startsWith('{')) {
            UserReturnClass usrc = (UserReturnClass) JSON.deserialize(jsonResponse, UserReturnClass.Class);
            if (usrc.hasErrors()) {
                logLatestGetCall(); //SFDC-6740
                throw new CustomException('Create User failed with:' + usrc.printError());
            }
            return usrc;
        }
        logLatestGetCall(); //SFDC-6740
        throw new CustomException('Create User failed with:' + jsonResponse);
        return null;
    }

    public String createUser(String accountSwitchKey, PulsarUserRecord contactAPIRecord) {
        return getPostResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Create_User')
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey), contactAPIRecord);
    }

    public String resetPassword() {
        return resetPassword(myContact.AKAM_Contact_ID__c, this.apiDeets.accountSwitchKey);
    }

    public String resetPassword(String uiIdentityId, String accountSwitchKey) {
        String jsonResponse = getPostResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Reset_Password')
            .replaceAll('OPEN_IDENTITY_ID', uiIdentityId)
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey), '');

        if (jsonResponse != null && jsonResponse.startsWith('{')) {
            ResetPasswordPulsarResponse rsp = (ResetPasswordPulsarResponse) JSON.deserialize(jsonResponse, ResetPasswordPulsarResponse.class);

            if (rsp != null && rsp.status != null && rsp.status >= 400) {
                logLatestGetCall(); //SFDC-6740
                throw new CustomException('Reset Password failed with:' + rsp.status + ':' + rsp.title + ' - ' + rsp.errors);
            }

            if (rsp == null || String.isBlank(rsp.newPassword)) {
                logLatestGetCall(); //SFDC-6740
                throw new CustomException('User does not exist in pulsar for reset password.');
            }

            return rsp.newPassword;
        } else {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('User does not exist in pulsar for reset password.' + jsonResponse);
        }
        return null;
    }

    public Boolean userExistsInPulsar() {
        return userExistsInPulsar(myContact.AKAM_Contact_ID__c, this.apiDeets.accountSwitchKey);
    }

    public Boolean userExistsInPulsar(String uiIdentityId, String accountSwitchKey) {
        String jsonResponse = getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_User')
            .replaceAll('UI_IDENTITY_ID', uiIdentityId)
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey));

        if (jsonResponse == null || jsonResponse == '[]') {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('User does not exist' + jsonResponse);
        }
        else if (jsonResponse.startsWith('{')) {
            UserReturnClass usrc = (UserReturnClass) Json.deserialize(jsonResponse, UserReturnClass.class);
            if (usrc.hasErrors() && !usrc.is404Error()) {
                throw new CustomException('User could not be found in Luna:' + usrc.printError());
            }
            return usrc.uiIdentityId == uiIdentityId;
        }
        return false;
    }

    public String getGroupUsers(String groupId, String accountSwitchKey) {
        return getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_Group_Users')
            .replaceAll('GROUP_ID_PLACEHOLDER', groupId)
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey));
    }

    public String getGroupDetails(String accountSwitchKey) {
        return getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_Groups')
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey));
    }

    public String getRoleDetails(String accountSwitchKey) {
        return getGetResult(NAPSettings.getValue('NAP_Pulsar_Endpoint_Get_Roles')
            .replaceAll('ACCOUNT_SWITCH_KEY', accountSwitchKey));
    }

    public AuthGrantClass getAuthGrantDetails(String accountSwitchKey) {
        AuthGrantClass singleAuthGrant = new AuthGrantClass();
        String jsonResponse = getGroupDetails(accountSwitchKey);

        if (jsonResponse == null || jsonResponse == '[]') {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('Groups could not be retrieved: ' + jsonResponse);
        }

        if (jsonResponse.startsWith('[')) {
            List < GroupClass > listOfGroups = (List < GroupClass > ) JSON.deserialize(jsonResponse, List < GroupClass > .Class);
            singleAuthGrant.groupId = listOfGroups.get(0).groupId;
            singleAuthGrant.groupName = listOfGroups.get(0).groupName;
        } else if (jsonResponse.startsWith('{')) {
            GenericPulsarResponse gpr = (GenericPulsarResponse) Json.deserialize(jsonResponse, GenericPulsarResponse.Class);
            logLatestGetCall(); //SFDC-6740
            if (gpr != null && gpr.hasErrors()) {
                throw new CustomException('Groups could not be retrieved: ' + gpr.printError());
            } else {
                throw new CustomException('Groups could not be retrieved:' + jsonResponse);
            }
        } else {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('Groups could not be retrieved:' + jsonResponse);
        }

        String roleDetailsJSON = getRoleDetails(accountSwitchKey);
        if (roleDetailsJSON == null || roleDetailsJSON == '[]') {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('Roles could not be retrieved: ' + roleDetailsJSON);
        }
        if (roleDetailsJSON.startsWith('[')) {
            List < RoleClass > listOfRoles = (List < RoleClass > ) JSON.deserialize(roleDetailsJSON, List < RoleClass > .Class);
            for (RoleClass eachRole: listOfRoles) {
                if (eachRole.roleName.contains('NAP SSO Only')) {
                    singleAuthGrant.roleId = eachRole.roleId;
                    singleAuthGrant.roleName = eachRole.roleName;
                }
            }
        } else if (roleDetailsJSON.startsWith('{')) {
            GenericPulsarResponse gpr = (GenericPulsarResponse) Json.deserialize(roleDetailsJson, GenericPulsarResponse.Class);
            logLatestGetCall(); //SFDC-6740
            if (gpr != null && gpr.hasErrors()) {
                throw new CustomException('Roles could not be retrieved: ' + gpr.printError());
            } else {
                throw new CustomException('Roles could not be retrieved:' + roleDetailsJSON);
            }
        } else {
            logLatestGetCall(); //SFDC-6740
            throw new CustomException('Roles could not be retrieved:' + roleDetailsJSON);
        }
        return singleAuthGrant;
    }

    public void updateAKAMContactIDAndPasswordResetTime(String akamContactId, Boolean hasUniverstityAccess) {
        Contact iCon = new Contact(id = myContact.Id);
        if (akamContactId != null) {
            iCon.AKAM_Contact_ID__c = akamContactId;
        }
        iCon.Has_Akamai_University_Access__c = hasUniverstityAccess;
        iCon.Active_Portal_Login__c = true;
        iCon.Last_Password_Reset_Time__c = DateTime.now();
        iCon.Last_Password_Reset_By__c = UserInfo.getName();
        iCon.Validation_Override__c = true;
        update iCon;
    }

    public void updateUniversityAccess(Boolean hasUniverstityAccess) {
        Contact iCon = new Contact(id = myContact.Id);

        iCon.Has_Akamai_University_Access__c = hasUniverstityAccess;
        iCon.Active_Portal_Login__c = true;
        iCon.Validation_Override__c = true;
        update iCon;
    }

    public void updateAPIDetailsOnAccount(String accountId) {
        if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UsePulsarAPI_DetailsJSON')) {
            Account acc = new Account();
            acc.Id = accountId;
            acc.PulsarAPI_DetailsJSON__c = JSON.serialize(this.apiDeets);
            acc.Validation_Override__c = true;
            update acc;
        }
    }

    public String getGetResult(String urlParams) {
        Http h = new Http();
        if (urlParams.contains(' ')) {
            urlParams = urlParams.replaceAll(' ', '%20');
        }

        HttpRequest hReq = buildGet(urlParams);
        HttpResponse res = h.send(hReq);

        LatestHttpResponse = res; //SFDC-6740
        LatestHttpRequest = hReq; //SFDC-6740
        callLogged = false; //SFDC-6740 : reset the flag for availing logging
        return res.getBody();
    }

    //SFDC-6740 : This function is used to capture the latest getCalls : capturing only errored get calls 
    public void logLatestGetCall() {
        if (callLogged != null && !callLogged) {
            new Promise(new CalloutLog(LatestHttpRequest, LatestHttpResponse)).execute();
            callLogged = true;
        }
    }

    public String getPostResult(String apiType, Object reqBody) {
        Http h = new Http();
        HttpRequest hReq = buildPost(apiType, reqBody);

        HttpResponse res = h.send(hReq);

        new Promise(new CalloutLog(hReq, res)).execute();
        return res.getBody();
    }

    public HttpRequest buildGet(String endpointWithoutHostWithQueryParams) {
        HttpRequest hRequest = buildHttpRequest(
            this.authStrategy.getConnectorDetails().Named_Credential__c + endpointWithoutHostWithQueryParams, 'GET', null, 'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;
    }

    public HttpRequest buildPost(String endpointWithoutHostWithQueryParams, Object reqBody) {
        HttpRequest hRequest = buildHttpRequest(
            this.authStrategy.getConnectorDetails().Named_Credential__c + endpointWithoutHostWithQueryParams, 'POST', reqBody, 'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;

    }

}