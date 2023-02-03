/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that supports self registration of users in communities that allow self registration
 ppp
 */
public with sharing class CommunitiesSelfRegController {

    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public String communityNickname {get; set { communityNickname = value == null ? value : value.trim(); } }
    public boolean AgreeToTermsAndConditions {get; set;}
    
    public CommunitiesSelfRegController(){}
    
    private boolean isValidPassword() {
        return password.equals(confirmPassword);//CR#2501319 - password validation issue fix
    }
    
     //CR2549028 change start 1
    private boolean userFromAkamai() {
        if(email.endsWith('@akamai.com'))
            return true;
        else
            return false;
 
    }
    
    
    private boolean userFromPRM(String email) {
        List<User> userList = new List<User>();
        userList = [ SELECT Id, Username, Profile.Name  FROM User WHERE Email = :email 
                     AND Profile.UserType = 'PowerPartner' LIMIT 20];
        if(userList.size() > 0)
            return true;
        return false;
    }
    
    private boolean userExists(String email) {
        List<User> userList = new List<User>();
        userList = [ SELECT Id, Username  FROM User WHERE Email = :email LIMIT 20];
        if(userList.size() > 0)
            return true;
        return false;
    }
    //CR2549028 change end 1
    
     //here...
    
    //CR#2501319 - password validation issue fix
 private boolean isEmptyPassword() {
     return String.isEmpty(password);
       
   }

    public PageReference registerUser() {
    
    
     //CR2549028 change start 2
        // if a user from PRM is trying to sign up - provide error message saying they don't need to do it.
        if (userFromPRM(email)) {
            String hostVal = ApexPages.currentPage().getHeaders().get('Host');
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You already have a Portal Account and don\'t need to sign up. <br />Please sign in to Communities <a href=\'/CommunitiesLogin?startURL=?dc=All&criteria=ALLQUESTIONS&feedtype=RECENT&#!/feedtype=SINGLE_QUESTION_DETAIL&dc=All&criteria=ALLQUESTIONS\'>here</a>.');
            ApexPages.addMessage(msg);
            return null;
        }
        
        // if a user from Akamai Domain is trying to sign up - provide error message saying they don't need to do it.
        if (userFromAkamai()) {
            String hostVal = ApexPages.currentPage().getHeaders().get('Host');
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Akamai Employee don\'t need to sign up. <br />Please <a href=\'https://crm.akamai.com\'>Sign in</a> to your Salesforce Account.');
            ApexPages.addMessage(msg);
            return null;
        }
        
        // if a user is not from Akamai/PRM but do already have an account
        if(userExists(email)){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'An account already exists with the e-mail '+ email + '. <br />Please <a href=\'/CommunitiesLogin\'>Sign in</a> if you are a returning customer.');
            ApexPages.addMessage(msg);
            return null;
        }
        //CR2549028 change end 2
        
        
            if(isEmptyPassword()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid password.'));
            return null;
       }
    
           // it's okay if password is null - we'll send the user a random password in that case
        if (!isValidPassword()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
            ApexPages.addMessage(msg);
            return null;
        }
        
        if(!AgreeToTermsAndConditions) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must agree to Terms and Conditions.'));
            return null;
        }
        
        string appendValue;      
        String profileId;
        String accountId;
        String userName;
        String roleEnum = null;
        string rngId;
        try{
            Communities_Settings__c cs = Communities_Settings__c.getInstance('Community');
            appendValue = (cs.User_Name_Append_Value__c != null) ? cs.User_Name_Append_Value__c : '';      
            profileId = cs.Self_Registration_Community_Profile_Id__c;
            accountId = cs.Communities_User_Account_Id__c;
            userName = email + appendValue;
            // Required code from Akamai to prevent mixed DML error from user triggers
            Random_Number_Generator__c rng = new Random_Number_Generator__c();
            rng.Object__c = 'User';
            insert rng;
            rngId = rng.Id;
            rngId = 'F-US-' + rngId.substring(3,18);
        }
        catch(Exception Ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in user sign-up, please contact system administrator.'));
            return null; 
        }
        
        User u = new User();
        u.AKAM_User_Id__c = rngId;
        u.UserPermissionsChatterAnswersUser = true;
        u.Username = userName;
        u.Email = email;
        u.FirstName = firstName;
        u.LastName = lastName;
        u.CommunityNickname = communityNickname;
        u.ProfileId = profileId;
        
        String userId = Site.createPortalUser(u, accountId, password);
      
        if (userId != null) { 
            if (password != null && password.length() > 1) {
                return Site.login(userName, password, '/?feedtype=RECENT&dc=All&criteria=ALLQUESTIONS');
            }
            else {
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}