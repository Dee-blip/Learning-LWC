global without sharing class WelinaSelfRegisterController {
    
    public WelinaSelfRegisterController() {}
    
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
     public static String[] getCountryPicklistVal() {
        List<String> countryList = new List<String>();
        for(Country_List__mdt c : [Select Label, Id, Check_State__c From Country_List__mdt where Label != null]) {
            countryList.add(c.Label);
        }
        return countryList;
    }

    @AuraEnabled
     public static String selfRegister(String firstname ,String lastname, String email,String companyName,String countryName,String linkedIn, String password, String confirmPassword, String accountId, String regConfirmUrl, String extraFields, String startUrl, Boolean includePassword) {
        Integer timeoutValue = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('welinaUserCreationRetryTimeout'));
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
            if (countryName == null || String.isEmpty(countryName)) {
                return 'Country is required.';
            }
            List<User> userRec = new List<User>([Select id,email from user where email = :email limit 1]);
            
            List<Contact> contactRec = new List<Contact>([Select id,AccountId,email,Active_Portal_Login__c from Contact where email = :email limit 1]);
            
            
            
            String errorMsg;
            
            if(userRec.size() > 0 || (contactRec.size() >0 && contactRec[0].Active_Portal_Login__c)){//communityUserRec.size() >0 || 
                
                if(userRec.size() > 0){
                    errorMsg = 'Email ID is already registered.';
                    
                }
                
                if(contactRec.size() >0 && contactRec[0].Active_Portal_Login__c){
                    errorMsg = 'Email ID already exists as a contact with Active Luna Login. Please click on Customer/Partner/Employee link on login page and use LUNA credentials to login.';
                }
                return errorMsg;
            }
            else{
                
                if(contactRec.size() == 0){
                    //Insert Contact
                    list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
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
                        c.MailingCountry = countryName;
                        c.MailingCity = 'TBD';
                        c.MailingStreet = 'TBD';
                        update c;
                        System.debug(LoggingLevel.INFO,'Contact created with '+'email : '+c.email+' and id : '+c.id); 
                        //create user
                        createUser(c.Id, null, firstname, lastname, email);
                    }
                    else{
                        c = new Contact();
                        c.RecordTypeId = contactRT;
                        c.FirstName = firstname;
                        c.LastName = lastname;
                        c.Email = email;
                        c.LinkedIn__c = linkedIn;
                        c.AccountId = communityMetaDataVal[0].DefaultAccountIdForNewContact__c;//'0018G000002lCyIQAU';//
                        c.MailingCountry = countryName;
                        c.MailingCity = 'TBD';
                        c.MailingStreet = 'TBD';
                        System.debug('before contact insert'+c);
                        insert c;
                        Error_Log__c leadAuditLog1 = new Error_Log__c(Name=c.Id, Class__c='WelinaSelf.Createcon', Error_Message__c='con  created');	
                        insert leadAuditLog1;
                        System.debug(LoggingLevel.INFO,'Contact created with '+'email : '+c.email+' and id : '+c.id); 
                        System.debug('invoke Createuser');
                        //create user
                        createUser(c.Id, c.AccountId, firstname, lastname, email);
                    }
                    
                }else{
                    System.debug(contactRec[0]);
                    createUser(contactRec[0].Id, contactRec[0].AccountId, firstname, lastname, email);
                }
                
                return null;
            }
        }
        catch (Exception ex) {
             Database.rollback(sp);
            Error_Log__c leadAuditLog2 = new Error_Log__c(Name='WelinaSelf.CreateconFail', Class__c='WelinaSelf.CreateconFail', Error_Message__c='con  created failed' + ex.getMessage()+' email : '+email);	
            insert leadAuditLog2;
            System.debug(LoggingLevel.ERROR,'Contact not created '+ex.getMessage());
            //after 45s timeout calling createUserHelper to create User in case of exception 
            Long startTime = DateTime.now().getTime();
            Long finishTime = DateTime.now().getTime();
            if(!Test.isRunningTest()){
                while ((finishTime - startTime) < timeoutValue*3) {
                    finishTime = DateTime.now().getTime();
                }
            }
            list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
            Id contactRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
                            
            if(ex.getMessage().contains('INVALID_EMAIL_ADDRESS'))
            {
               return ex.getMessage(); 
            }else{
               return createContactHelper(contactRT,firstname,lastname,email,countryName,linkedIn,communityMetaDataVal,1);
            }
        }
    }
    
    public static string createContactHelper(Id contactRT,String firstname ,String lastname, String email,String countryName,String linkedIn, list<SFCommunity_NQLB_Topics__mdt> communityMetaDataVal, integer retryCount){
        Integer timeoutValue = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('welinaUserCreationRetryTimeout'));
        Integer retryCountLimit = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('userCreationRetryCountLimit'));
        Error_Log__c leadAuditLog3 = new Error_Log__c(Name='Debug logs', Class__c='Debug Logs', Error_Message__c='inside helper method count : '+retryCount);	
        insert leadAuditLog3;
        try{
            Contact c;
            c = MARIT_ContactHandler.convertExisitingLead(email);
            if(c != null){
                c.RecordTypeId = contactRT;
                c.FirstName = firstname;
                c.LastName = lastname;
                c.Email = email;
                c.LinkedIn__c = linkedIn;
                c.MailingCountry = countryName;
                c.MailingCity = 'TBD';
                c.MailingStreet = 'TBD';
                update c;
                System.debug(LoggingLevel.INFO,'Contact created with '+'email : '+c.email+' and id : '+c.id); 
                //create user
                createUser(c.Id, null, firstname, lastname, email);
            }
            else{
                c = new Contact();
                c.RecordTypeId = contactRT;
                c.FirstName = firstname;
                c.LastName = lastname;
                c.Email = email;
                c.LinkedIn__c = linkedIn;
                c.AccountId = communityMetaDataVal[0].DefaultAccountIdForNewContact__c;//'0018G000002lCyIQAU';//
                c.MailingCountry = countryName;
                c.MailingCity = 'TBD';
                c.MailingStreet = 'TBD';
                insert c;
                Error_Log__c leadAuditLog1 = new Error_Log__c(Name=c.Id, Class__c='WelinaSelf.Createcon', Error_Message__c='con  created');	
                insert leadAuditLog1;
                System.debug(LoggingLevel.INFO,'Contact created with '+'email : '+c.email+' and id : '+c.id); 
                System.debug('invoke Createuser');
                //create user
                createUser(c.Id, c.AccountId, firstname, lastname, email);
            }
            return null;
        }catch(Exception ex){
            Error_Log__c leadAuditLog2 = new Error_Log__c(Name='WelinaSelf.CreateconFail Exception', Class__c='WelinaSelf.CreateconFail', Error_Message__c='con  created failed' + ex.getMessage()+' email : '+email+' retryCount : '+retryCount+' retry count limit : '+retryCountLimit);	
            insert leadAuditLog2;
            system.debug('----Contact Creation Error---ex.getMessage()-----'+ex.getMessage());
            if(retryCount<=retryCountLimit){
                Error_Log__c leadAuditLog4 = new Error_Log__c(Name='Debug logs', Class__c='Debug Logs', Error_Message__c='inside retry count if condition in helper method');	
            	insert leadAuditLog4;
                Long startTime = DateTime.now().getTime();
                Long finishTime = DateTime.now().getTime();
                if(!Test.isRunningTest()){
                    while ((finishTime - startTime) < timeoutValue*((Integer.valueof((math.random() * 4)))+1)) {
                        finishTime = DateTime.now().getTime();
                    }
                }
                retryCount+=1;
                return createContactHelper(contactRT,firstname,lastname,email,countryName,linkedIn,communityMetaDataVal,retryCount);
            }else{
                return ex.getMessage();
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
                    fieldDetail.put('value', '');
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
    /*
    public static String getHomeNetworkURL(){
        Id myNetworkId = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt limit 1].CommunityNetworkId__c;
        string networkURL = Network.getLoginUrl(myNetworkId);
        integer lastIdex = networkURL.indexOf('login');   
        networkURL = networkURL.substring(0,lastIdex);
        return networkURL;
        
    }*/
    
   @future
    public static void createUser(Id contactId, Id accountId, string firstName, string lastName, string email) {
        Integer timeoutValue = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('welinaUserCreationRetryTimeout'));
        try {
            profile guestProfile = [SELECT id,name from profile where name ='SFWelinaGuests'];
            User u = new User();
            u.Username = Email;
            u.contactId = contactId;
            u.Registered_Community_Website__c = 'WelinaPlaygroundLogin';
            u.ProfileId = guestProfile.Id;//'00e8G000000DfbG'; // SFWelinaGuests
            u.Email = Email;
            u.FirstName = firstname;
            u.LastName = lastname;
            u.languagelocalekey = 'en_US';
            u.localesidkey = UserInfo.getLocale();
            u.emailEncodingKey = 'UTF-8';
            u.timeZoneSidKey = UserInfo.getTimezone().getID();
            u.alias = lastname.length() > 3 ? 'CCM-'+(FirstName.substring(0,1) + LastName.substring(0,2)) : 'CCM-'+(FirstName.substring(0,1) + LastName); 
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.CommunityNickname = nickname;
            insert u;
            System.resetPassword(u.Id, true);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,ex.getMessage());
            //after 45s timeout calling createUserHelper to create User in case of exception 
            Long startTime = DateTime.now().getTime();
            Long finishTime = DateTime.now().getTime();
            while ((finishTime - startTime) < timeoutValue*3) {
                finishTime = DateTime.now().getTime();
            }
            createUserHelper(contactId,firstName,lastName,email,1);
        } 
    }

    public static void createUserHelper(Id contactId, string firstName, string lastName, string email, integer retryCount){
        Integer timeoutValue = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('welinaUserCreationRetryTimeout'));
        Integer retryCountLimit = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('userCreationRetryCountLimit'));
    	try{
        	profile guestProfile = [SELECT id,name from profile where name ='SFWelinaGuests'];
            User u = new User();
            u.Username = Email;
            u.contactId = contactId;
            u.Registered_Community_Website__c = 'WelinaPlaygroundLogin';
            u.ProfileId = guestProfile.Id;//'00e8G000000DfbG'; // SFWelinaGuests
            u.Email = Email;
            u.FirstName = firstname;
            u.LastName = lastname;
            u.languagelocalekey = 'en_US';
            u.localesidkey = UserInfo.getLocale();
            u.emailEncodingKey = 'UTF-8';
            u.timeZoneSidKey = UserInfo.getTimezone().getID();
            u.alias = lastname.length() > 3 ? 'CCM-'+(FirstName.substring(0,1) + LastName.substring(0,2)) : 'CCM-'+(FirstName.substring(0,1) + LastName); 
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.CommunityNickname = nickname;
            insert u;
            System.resetPassword(u.Id, true);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR,ex.getMessage()+'user creation error!!!'+'email : '+email+'retry count : '+retryCount); 
            //after random timeout calling createUserHelper to create User in case of exception 
            if(retryCount<=retryCountLimit){
                Long startTime = DateTime.now().getTime();
                Long finishTime = DateTime.now().getTime();
                while ((finishTime - startTime) < timeoutValue*((Integer.valueof((math.random() * 4)))+1)) {
                    finishTime = DateTime.now().getTime();
                }
                retryCount+=1;
                createUserHelper(contactId,firstName,lastName,email,retryCount);
            }
        }
    }
}