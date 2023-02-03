/**
 * Appirio | Dharmesh Patel | Initital Development
**/
global class CommunitiesForgotPasswordController{
    public String userName {get; set;}
    public String email {get;set;}
    public Boolean displayForgotPasswordRequest {get; set;}
    public Boolean displayForgotPasswordConformation {get; set;}
    private String appendValue;
    private Boolean actionFiredOnce = false;

    public CommunitiesForgotPasswordController(){
        displayForgotPasswordRequest = true;
        displayForgotPasswordConformation = false;
        Communities_Settings__c cs = Communities_Settings__c.getInstance('Community');
        appendValue = (cs.User_Name_Append_Value__c != null) ? cs.User_Name_Append_Value__c : ''; 
    }
    
    public void ResetPassword(){
        if(email==null || email=='')
        {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email is required.'));   
        }
        else 
        {
            if (!email.toLowerCase().endsWith(appendValue.toLowerCase())) userName = email+ appendValue;
            List<User> userList=[select Id,UserName from User where UserName =: userName];
            
            if(userList!=null && userList.size()>0)
            {
                Boolean resetResponse = Site.forgotPassword(userName);
                userName = userName.replace(appendValue.toLowerCase(),'');
                if (resetResponse) {
                    displayForgotPasswordRequest = false;
                    displayForgotPasswordConformation = true;
                }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not complete request, please try again. If you still can\'t request forgot password email, contact your administrator.'));   
            }
            }
            else
            {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Email.'));   
            }
        }
    }
}