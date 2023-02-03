/*Customer Community Component*/
global without sharing class LightningSelfRegisterController {
    
    public LightningSelfRegisterController() {
        
    }
    
    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    @TestVisible 
    private static boolean siteAsContainerEnabled(String communityUrl) {
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(communityUrl,'');
        return authConfig.isCommunityUsingSiteAsContainer();
    }
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
            Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static String selfRegister(String firstname ,String lastname, String email,String companyName,String countryName,String stateName,String linkedIn, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {
        Savepoint sp = null;
        try {
            sp = Database.setSavepoint();
            
            if (firstname == null || String.isEmpty(firstname)) {
                return 'First Name is required.';
            }
            
            if (lastname == null || String.isEmpty(lastname)) {
                return Label.Site.lastname_is_required;
            }
            
            if (email == null || String.isEmpty(email)) {
                return Label.Site.email_is_required;
            }
            if (companyName == null || String.isEmpty(companyName)) {
                return 'Company Name is required.';
            }
            if (countryName == null || String.isEmpty(countryName)) {
                return 'Country is required.';
            }
            if (stateName == null || String.isEmpty(stateName)) {
                return 'State is required.';
            }
            
            List<SC_Community_Registration__c> communityUserRec = new List<SC_Community_Registration__c>([Select Id, Email__c, IsApproved__c,Reject__c from SC_Community_Registration__c where Email__c = :email limit 1]);
            
            List<User> userRec = new List<User>([Select id,email from user where email = :email limit 1]);
            
            List<Contact> contactRec = new List<Contact>([Select id,email,Active_Portal_Login__c from Contact where email = :email limit 1]);
            
            profile guestProfile = [SELECT id,name from profile where name ='SFCommunityGuest'];
            
            String errorMsg;
            
            if(userRec.size() > 0 || communityUserRec.size() >0 || (contactRec.size() >0 && contactRec[0].Active_Portal_Login__c)){
                
                if(userRec.size() > 0){
                    errorMsg = Label.JV_Email_Already_Registered;
                    
                }
                
                if(contactRec.size() >0 && contactRec[0].Active_Portal_Login__c){
                    errorMsg = Label.JV_Luna_Login_Exists;
                }
                
                else if(communityUserRec.size() >0 && !communityUserRec[0].IsApproved__c && !communityUserRec[0].Reject__c){
                    errorMsg = Label.JV_Email_Under_Processing;
                    
                }
                return errorMsg;
            }
            else{
                
                SC_Community_Registration__c communityUser = new SC_Community_Registration__c ();
                
                communityUser.Email__c = email;
                communityUser.First_Name__c = firstname;
                communityUser.Last_Name__c = lastname;
                communityUser.LinkedIn_URL__c = linkedIn;
                communityUser.Company_Name__c = companyName;
                communityUser.Country__c = countryName;
                communityUser.State__c  = stateName;
                communityUser.UserPreferencesHideS1BrowserUI__c = true; // If using site to host the community the user should not hit s1 after logging in from mobile.
                String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
                nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
                communityUser.CommunityNickname__c = nickname;
                if (includePassword) {    
                    if (!isValidPassword(password, confirmPassword)) {
                        return Label.site.passwords_dont_match;
                    }
                    communityUser.Password__c = password;
                    communityUser.Confirm_Password__c = confirmPassword;
                    //validatePassword(u, password, confirmPassword);
                }
                else {
                    password = '';
                }
                
                insert communityUser;
                
                if(contactRec.size() == 0){
                    //Insert Contact
                    list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
                    
                    Id contactRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
                    
                    list<Contact> contactList = new List<Contact>();
                    
                    list<Id> contactIdList = new List<Id>();
                    
                    Contact c;
                    c = MARIT_ContactHandler.convertExisitingLead(email);
                    if(c != null){
                        c.RecordTypeId = contactRT;
                        c.FirstName = firstname;
                        c.LastName = lastname;
                        c.Email = email;
                        c.LinkedIn__c = linkedIn;
                        //c.AccountId = communityMetaDataVal[0].DefaultAccountIdForNewContact__c;
                        c.MailingCountry = countryName;
                        c.MailingState = stateName;
                        c.MailingCity = 'TBD';
                        c.MailingStreet = 'TBD';
                        //c.Validation_Override__c = true;
                        update c;
                    }
                    else{
                        c = new Contact();
                        c.RecordTypeId = contactRT;
                        c.FirstName = firstname;
                        c.LastName = lastname;
                        c.Email = email;
                        c.LinkedIn__c = linkedIn;
                        c.AccountId = communityMetaDataVal[0].DefaultAccountIdForNewContact__c;
                        c.MailingCountry = countryName;
                        c.MailingState = stateName;
                        c.MailingCity = 'TBD';
                        c.MailingStreet = 'TBD'; 
                        //c.Validation_Override__c = true;
                        insert c;
                    }
                    
                }
                
                return null;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
            String insertErrorMessage;
            system.debug('----Contact Creation Error---ex.getMessage()-----'+ex.getMessage());
            if(ex.getMessage().contains('Please enter a valid state for the selected country.')){
                insertErrorMessage = Label.JV_Invalid_State_For_Selected_Country;
                return insertErrorMessage; 
            }
            if(ex.getMessage().contains('Please enter a valid country')){
                insertErrorMessage = Label.JV_Invalid_Country;
                return insertErrorMessage; 
            }
            if(ex.getMessage().contains('INVALID_EMAIL_ADDRESS')){
                insertErrorMessage = Label.JV_Invalid_Email;
                return insertErrorMessage;
            }
            else{
                insertErrorMessage = Label.JV_Registration_Failed + ex.getMessage();
                return insertErrorMessage;
            }
            
        }
    }
    
    @AuraEnabled
    public static List<Map<String,Object>> getExtraFields(String extraFieldsFieldSet) { 
        List<Map<String,Object>> extraFields = new List<Map<String,Object>>();
        Schema.FieldSet fieldSet = Schema.SObjectType.SC_Community_Registration__c.fieldSets.getMap().get(extraFieldsFieldSet);
        if(!Test.isRunningTest()) {
            if (fieldSet != null) {
                for (Schema.FieldSetMember f : fieldSet.getFields()) {
                    Map<String, Object> fieldDetail = new Map<String, Object>();
                    fieldDetail.put('dbRequired', f.getDBRequired());
                    fieldDetail.put('fieldPath', f.getFieldPath());
                    fieldDetail.put('label', f.getLabel());
                    fieldDetail.put('required', f.getRequired());
                    fieldDetail.put('type', f.getType());
                    fieldDetail.put('value', '');   // client will populate
                    extraFields.add(fieldDetail);
                }}}
        return extraFields;
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);   
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    } 
    
    @AuraEnabled
    public static String getHomeNetworkURL(){
        Id myNetworkId = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt limit 1].CommunityNetworkId__c;
        string networkURL = Network.getLoginUrl(myNetworkId);
        integer lastIdex = networkURL.indexOf('login');   
        networkURL = networkURL.substring(0,lastIdex);
        return networkURL;
        
    }
}