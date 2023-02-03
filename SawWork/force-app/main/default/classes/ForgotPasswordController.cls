/**
 ForgotPasswordController
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : An apex page controller that exposes the site forgot password functionality. Its a stop gap arrangement until OOTB forgot 
    password feature starts triggering emails which doesnt trigger email with new password
    --Developer		      --Date			--Change.
 	  Ali KM			  12/Aug/2011		CR 1230475 PRM: Update the email template when a partner contact resets their password
 	  										- Changed the Forgot Email Template to something thats closer to SF.com OOTB forgot password email.
 	  										- Changed the fetching of User record to include checking for ContactID != null & UserType contains 'Partner'
 	  										- Changed the Site Url to look for Site.Custom Web Address instead of Site.Current URL.
  	  Ali KM			  12/Aug/2011		CR 1230475 PRM: Update the email template when a partner contact resets their passwordAli KM
  	  										- Now that the OOTB email trigger for forgot password is working, reverting the code to use that functionality.
 */
public with sharing class ForgotPasswordController {
    public String username {get; set;}   
       
    public ForgotPasswordController() {}
	
  	public PageReference forgotPassword() {
  		boolean success = Site.forgotPassword(username);
  		PageReference pr = Page.ForgotPasswordConfirm;
  		pr.setRedirect(true);
  		
  		if (success) {  			
  			return pr;
  		}
  		return null;
  	}
  	
  	 //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //public static testMethod void testForgotPasswordController() 
    //{
   //   // Instantiate a new controller with all parameters in the page
   //   ForgotPasswordController controller = new ForgotPasswordController();
   //   controller.username = 'test@salesforce.com';
   //   System.assertEquals(controller.forgotPassword(),null); 
   // }
  	/*
    public static Messaging.SingleEmailMessage createSingleEmail(String toAddress,string Subject,string bodytext,string htmltext)
    {
        String[] toAddresses = toAddress.split(',');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setToAddresses(toAddresses);
        mail.setPlainTextBody(bodytext);
        mail.setHtmlBody(htmltext);
        mail.setSubject(Subject);
        mail.setOrgWideEmailAddressId(Email_to_Case__c.getInstance('PartnerPortal').OrgWide__c);
        mail.setSaveAsActivity(false);
        return mail;
    }
    public PageReference forgotPassword() 
    {
        //boolean success = Site.forgotPassword(username);
        User usr=null;
        for(User u:[select id,Email,Username,Name from User where UserName=:username AND IsActive=TRUE AND UserType LIKE '%Partner%'])
        usr=u;
        if(usr==null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your username was not found.'));
            return null;
        }
        //string SfURL=Site.getCurrentSiteUrl(); //[select Fax from Organization][0].Fax;
        string SfURL=Site.getCustomWebAddress(); // this to fetch the netalliance URL instead of force.com url...	
        //System.debug('Site.getCustomWebAddress()=' + SfURL);
        
        // => PRM Forgot password old template.
        //EmailTemplate et=[select Body,HtmlValue,Subject from EmailTemplate where DeveloperName='Akamai_Netalliance_Reset_Password_HTML'][0];
        //string htmltext='';
        //string bodytext='';
        //if (!Test.isRunningTest()) {
        //System.ResetPasswordResult result = System.resetPassword(usr.id,false);
        //htmltext='<img src="http://wwwns.akamai.com/images/net_alliance_logo_white.jpg" alt="Company Logo" border="0"/><br/>'+et.HtmlValue.replaceAll('#UserName#', usr.Name).replaceAll('#LoginLink#', SfURL)+'<br/><br/>Username:'+usr.Username+'<br/>Password:'+result.getPassword();
        //bodytext=et.Body.replaceAll('#UserName#', usr.Name).replaceAll('#LoginLink#', SfURL)+'\nUsername:'+usr.Username+' Password:'+result.getPassword(); 
        //}
        
        
        EmailTemplate et=[select Body,HtmlValue,Subject from EmailTemplate where DeveloperName='Akamai_Netalliance_Reset_Password_New'][0];
        string htmltext='';
        string bodytext='';
        if (!Test.isRunningTest()) 
        {
	        System.ResetPasswordResult result = System.resetPassword(usr.id,false);
	        htmltext='<img src="http://wwwns.akamai.com/images/net_alliance_logo_white.jpg" alt="Company Logo" border="0"/><br/>'
	        	+ et.HtmlValue.replaceAll('#name#', usr.Name).replaceAll('#username#', usr.Username).replaceAll('#password#', result.getPassword()).replaceAll('#portal_login_link#', SfURL);
	        bodytext=et.Body.replaceAll('#name#', usr.Name).replaceAll('#username#', usr.Username).replaceAll('#password#', result.getPassword()).replaceAll('#portal_login_link#', SfURL);
        }
        //throw new CustomException('userid'+usr.id);
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        sendEmailList.add(createSingleEmail(usr.Email,et.Subject,bodytext,htmltext));
        messaging.sendEmail(sendEmailList, false);
        PageReference pr = Page.ForgotPasswordConfirm;
        //PageReference pr2= new PageReference('/'+result.getPassword());
        pr.setRedirect(true);
        
        //if (success) {            
			return pr;
        //}
        //return null;
    }
    
     public static testMethod void testForgotPasswordController() {
     
     Profile pr = [select Id from Profile where Name='Account Development - Outbound'][0];
    UserRole role = [select Id, Name from UserRole where Name='Account Development - Outbound'][0];
    User newUser = new User(alias = 'forgotp', 
                email='forgotp.test@akamai.com',
                emailencodingkey='UTF-8', 
                lastname='forgotp', 
                languagelocalekey='en_US',
                localesidkey='en_US', 
                timezonesidkey='America/Los_Angeles', 
                username='forgotp@akamai.com.tclass',
                profileid = pr.Id, 
                UserRoleId = role.Id );
    insert newUser;    
    
        // Instantiate a new controller with all parameters in the page
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = [select Username from User where id=:newUser.id][0].username;        
        controller.forgotPassword();
        //System.assertEquals(controller.forgotPassword(),null); 
    }
    */
}