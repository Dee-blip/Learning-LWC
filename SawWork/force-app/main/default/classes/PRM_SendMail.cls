/***
    PRM_SendMail
    
    @Author: Pranav Moktali <prmoktal@akamai.com>
    
    @Description:   Offloading all sendmail methods from PRMUtilClass into this class
    * Developer		Date		Description
	* --------------------------------------------------------------------------------------------------
    Pranav Motkali	Ocr/13		CR 2226809 Luna: Change the Reset Password and acivate user feature.
    Anand Hegde March 10, 2014 CR 2560809 - SSO: Tasks for 3.39 
*/

public class PRM_SendMail {
	private static String sfPortalURL;
	private static String partnerUnivesityURL;
	private static String QuickReferenceGuideContactLink;
	private static String QuickReferenceGuideAdminLink;
	
	
    public static string populateEmailCCList(Contact PartnerCon){
        String emailCCList = '';
        Map<Id, Channel_Mapping__c> ChannelMapping_Id_Map = new Map<Id, Channel_Mapping__c>();
        for (Channel_Mapping__c cm :[SELECT Id, PAE_ID__c, PAE_ID__r.Email, PAE_ID__r.Name, PAE_ID__r.Id, PAE_ID__r.Username, MDF_Approver__c, 
                                     MDF_Approver__r.Email, MDF_Approver__r.Name, MDF_Approver__r.Id, MDF_Approver__r.Username, MDF_Approver__r.IsActive FROM Channel_Mapping__c
                                     WHERE VAR_Manager_Status__c = 'Active' AND Partner_Name__c = :PartnerCon.Account.id AND Active__c=true])
                                        ChannelMapping_Id_Map.put(cm.Id, cm);
       //System.debug('ChannelMapping_Id_Map=' + ChannelMapping_Id_Map);
        if (ChannelMapping_Id_Map.size()>0)
        {
            for (Channel_Mapping__c cm : ChannelMapping_Id_Map.values())
            {
                if (cm.PAE_ID__r.Email != null && !emailCCList.contains(cm.PAE_ID__r.Email))
                {   
                    emailCCList += cm.PAE_ID__r.Email + ',';            
                }
                if (cm.MDF_Approver__r.Email != null && !emailCCList.contains(cm.MDF_Approver__r.Email))    
                {
                    emailCCList += cm.MDF_Approver__r.Email + ',';
                }
            }
        }
        System.debug('emailCCListRAW=' + emailCCList);
        if (emailCCList != ''){
            emailCCList = emailCCList.substring(0, emailCCList.length() - 1);
            System.debug('emailCCListTrimmed=' + emailCCList);
        }
        return emailCCList;
    }
    
    public static List<User> getPortalAdminsList(Contact PartnerCon){
        List<User> partnerAdminList = new List<User>();
        for (User usr : [Select UserType, Profile.Name, ProfileId, Contact.Email, Contact.HomePhone, Contact.MobilePhone, Contact.Phone, Contact.Name, ContactId From User 
                where Contact.AccountId = : PartnerCon.Account.id AND isActive = true ORDER BY Contact.Name ASC])//and Profile.Name¬†= 'Akamai Partner Administrator'])//: PRM_Settings__c.getInstance('Partner Admin Profile').Value__c ])
                {
                    if (usr.Profile.Name == PRM_Settings__c.getInstance('Partner Admin Profile').Value__c)
                        partnerAdminList.add(usr);
                }
        return partnerAdminList;
    }
    
    public static String generatePortalAdminString(List<User> portalAdminList)
    {
        string strPortalAdminStringPartial = '';
        string strPortalAdminStringComplete = '';
        string strPortalAdminTemplate = '<br /><br />Name: #partnerAdminName#<br />';
        strPortalAdminTemplate += '<br />Email Id: #partnerEmail#<br />';
        strPortalAdminTemplate += '<br />Phone: #partnerPhone#<br />';
        strPortalAdminTemplate += '<br />Mobile Phone: #partnerMobilePhone#<br />';
        //strPortalAdminTemplate += '<br />Home Phone: #partnerHomePhone#<br />';
        for (User usr : portalAdminList)
        {
            strPortalAdminStringPartial = strPortalAdminTemplate;
            strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerAdminName#', usr.Contact.Name);
            if (usr.Contact.Email != null)
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerEmail#', usr.Contact.Email);
            else 
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerEmail#', 'NA');
            if (usr.Contact.Phone != null)
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerPhone#', usr.Contact.Phone);
            else 
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerPhone#', 'NA');
            if (usr.Contact.MobilePhone != null)
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerMobilePhone#', usr.Contact.MobilePhone);
            else 
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerMobilePhone#', 'NA');
            /*
            if (usr.Contact.HomePhone != null)
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerHomePhone#', usr.Contact.HomePhone);
            else 
                strPortalAdminStringPartial = strPortalAdminStringPartial.replaceAll('#partnerHomePhone#', 'NA');
            */ 
            strPortalAdminStringComplete = strPortalAdminStringComplete +  strPortalAdminStringPartial;                     
        }
        return strPortalAdminStringComplete;
    }
    
    public static void sendPartnerWelcomeMails_Luna(String tempPassword, Contact con, User partnerUser){
        EmailTemplate toAdminTemplate, notifyOthersTemplate, toUserTemplate;
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        
        init_sendMail();
        
        for (EmailTemplate et : [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where DeveloperName IN ('Akamai_Netalliance_Welcome_Admin_Luna_HTML', 'Akamai_Netalliance_Welcome_User_Luna_HTML', 'Akamai_Netalliance_Welcome_Admin_Notify_Luna_HTML')]){
            if (et.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_Luna_HTML')
                toAdminTemplate = et;
            else if (et.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_Notify_Luna_HTML')
                notifyOthersTemplate = et;
            else if (et.DeveloperName == 'Akamai_Netalliance_Welcome_User_Luna_HTML')
                toUserTemplate = et;
        }
        if(Util.isPartnerAdminProfile(partnerUser)){
            if (toAdminTemplate == null || notifyOthersTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerAdminWelcomeMail(tempPassword,toAdminTemplate,con,partnerUser));
            if(!Test.isRunningTest()) {
                sendEmailList.add(NotifyOthersMail(notifyOthersTemplate, con, partnerUser));
            }
        } else {
            if (toUserTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerUserWelcomeMail(tempPassword,toUserTemplate,con,partnerUser));
        }
        if(!sendEmailList.isEmpty()){
            Messaging.sendEmail(sendEmailList, false);
        }
    }
    
    public static void sendPartnerWelcomeMails_AU(string tempPassword, Contact con){
    	EmailTemplate AUWelcomeTemplate;
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        init_sendMail();
	    
	    for(EmailTemplate et: [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where DeveloperName = 'Akamai_University_Welcome_User_Luna_HTML']){
	    	AUWelcomeTemplate = et;
	    }
	    if (AUWelcomeTemplate == null){
            	throw new CustomException('Template not found');
        }
        sendEmailList.add(AkamaiUniversityUserWelcomeMail(tempPassword, AUWelcomeTemplate, con));
        
         if(!sendEmailList.isEmpty()){
            Messaging.sendEmail(sendEmailList, false);
        }
	}
    
    public static void sendPartnerWelcomeMails_OneTime(String tempPassword, Contact con, Boolean isPartnerAdmin){
        EmailTemplate toAdminTemplate, toUserTemplate;
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        
        init_sendMail();
        
        for (EmailTemplate et : [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where DeveloperName IN ('Akamai_Netalliance_Welcome_Admin_OneTime_HTML', 'Akamai_Netalliance_Welcome_User_OneTime_HTML')]){
            if (et.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_OneTime_HTML')
                toAdminTemplate = et;
            else if (et.DeveloperName == 'Akamai_Netalliance_Welcome_User_OneTime_HTML')
                toUserTemplate = et;
        }
        if(isPartnerAdmin){
            if (toAdminTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerWelcomeMail_OneTime(tempPassword,toAdminTemplate,con));
        } else {
            if (toUserTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerWelcomeMail_OneTime(tempPassword,toUserTemplate,con));
        }
        if(!sendEmailList.isEmpty()){
            Messaging.sendEmail(sendEmailList, false);
        }
    }
    
	/*
    	Below are the methods with partner user provisioning without Luna
    */
    
    public static string resetAndSendMails_SF(User partnerUser,Contact con){
    	EmailTemplate toAdminTemplate, notifyOthersTemplate, toUserTemplate;
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        init_sendMail();
        
	    System.ResetPasswordResult result;
	    String tempPassword = 'testPassword';
	    partnerUser=[select id,Name,FirstName,LastName,Alias,Email,Username,ProfileId,UserRoleId,IsActive,UserRole.Name,Profile.Name from User where id=:partnerUser.id];
	    for (EmailTemplate et : [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where DeveloperName IN ('Akamai_Netalliance_Welcome_User_HTML', 'Akamai_Netalliance_Welcome_Admin_HTML', 'Akamai_Netalliance_Welcome_Admin_Notify_HTML')])
	    {
	        if (et.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_HTML')
	            toAdminTemplate = et;
	        else if (et.DeveloperName == 'Akamai_Netalliance_Welcome_Admin_Notify_HTML')
	            notifyOthersTemplate = et;
	        else if (et.DeveloperName == 'Akamai_Netalliance_Welcome_User_HTML')
	            toUserTemplate = et;
	    }
	    
    	if (!Test.isRunningTest()){
			result = System.resetPassword(partnerUser.id,false);
			tempPassword = result.getPassword();
    	}
	    if(Util.isPartnerAdminProfile(partnerUser)){
            if (toAdminTemplate == null || notifyOthersTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerAdminWelcomeMail(tempPassword,toAdminTemplate,con,partnerUser));
            if(!Test.isRunningTest()) {
                sendEmailList.add(NotifyOthersMail(notifyOthersTemplate, con, partnerUser));
            }
        } else {
            if (toUserTemplate == null){
            	throw new CustomException('Template not found');
            }
            sendEmailList.add(PartnerUserWelcomeMail(tempPassword,toUserTemplate,con,partnerUser));
        }
        if(!sendEmailList.isEmpty()){
        	if (!Test.isRunningTest())
            	Messaging.sendEmail(sendEmailList, false);
        }
        
		return 'true';
	}
	
	/*
		Takes only 1 input - optionsMap.
		Typical example for an optionsMap (Case sensitive?)
			{
				'tempPassword'	=>	'not1234',
				'name'			=>	'Ford Prefect',
				'email'			=>	'ford.prefect@42.com',
				'userType'		=>	'NAP'
			}
			
		Following are the valid 'userType':
			-	'NAP'	(For a NAP user)
			-	'AU'	(For Akamai University Only user)
	*/
    public static void sendPasswordResetMail(Map<String,String> optionsMap){
    	String tempPassword, email, name, userType;
        String loginUnderscoreUnderscoreC ;
        String emailTextBody, emailHTMLBody, emailToList, emailCCList;
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate toNAPuserTemplate, toAUuserTempalate, resetPassTemplate;
        init_sendMail();
        /* Set options */
        tempPassword = String.isBlank(optionsMap.get('tempPassword')) ? '' : optionsMap.get('tempPassword');
        email = String.isBlank(optionsMap.get('email')) ? '' : optionsMap.get('email');
        name = String.isBlank(optionsMap.get('name')) ? '' : optionsMap.get('name');
        loginUnderscoreUnderscoreC = String.isBlank(optionsMap.get('loginUnderscoreUnderscoreC')) ? email : optionsMap.get('loginUnderscoreUnderscoreC');
        userType = String.isBlank(optionsMap.get('userType')) ? 'NAP' : optionsMap.get('userType');
        
        for (EmailTemplate et : [select Id,DeveloperName,Body,HtmlValue,Subject from EmailTemplate where DeveloperName IN ('Akamai_Netalliance_Luna_Password_Reset_HTML','Akamai_University_Luna_Password_Reset_HTML')])
	    {
	        if (et.DeveloperName == 'Akamai_Netalliance_Luna_Password_Reset_HTML')
	            toNAPuserTemplate = et;
	        else if (et.DeveloperName == 'Akamai_University_Luna_Password_Reset_HTML')
	            toAUuserTempalate = et;
	    }
	    
	    if (toNAPuserTemplate == null || toAUuserTempalate == null || String.isBlank(tempPassword) || String.isBlank(email) || String.isBlank(name)){
        	throw new CustomException('Template not found');
	    }
	    
	    resetPassTemplate = (userType == 'NAP') ? toNAPuserTemplate : toAUuserTempalate;
        emailToList = email;
        emailCCList = '';
		/*
        TODO
        	-	replace username(?)
        	-	replace org url (?) 
       */        
        System.Debug('==loginUnderscoreUnderscoreC sendPasswordResetMail in PRM_SendMail loginUnderscoreUnderscoreC' + loginUnderscoreUnderscoreC);
        emailTextBody = resetPassTemplate.Body.replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#PartnerUniversityLink#',partnerUnivesityURL).replaceAll('#user#', name).replaceAll('#username#', loginUnderscoreUnderscoreC).replaceAll('#password#', tempPassword);
        emailHTMLBody = resetPassTemplate.HtmlValue.replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#PartnerUniversityLink#',partnerUnivesityURL).replaceAll('#user#', name).replaceAll('#username#', loginUnderscoreUnderscoreC).replaceAll('#password#', tempPassword);
        sendEmailList.add(GsmUtilClass.createSingleEmail(emailToList,emailCCList,resetPassTemplate.Subject,emailTextBody,emailHTMLBody));
	    
        if(!sendEmailList.isEmpty()){
        	if (!Test.isRunningTest())
            	Messaging.sendEmail(sendEmailList, false);
        }
    }
   	
   	private static void init_sendMail()
    {
    	// To avoid test method fails as Partner User cannot access organization data.
        if (Test.isRunningTest())
        {
        	sfPortalURL = 'test.salesforce.com';
        	
        }
        else
        {
        	sfPortalURL = [select Fax from Organization limit 1][0].Fax;
        }
        partnerUnivesityURL = Util.getCsodSamlUrl();
	    QuickReferenceGuideAdminLink = sfPortalURL + '?startUrl=/069G0000000XXoa'; // move this to custom setting -> ?startUrl....
	    QuickReferenceGuideContactLink = sfPortalURL + '?startUrl=/069G0000000XXp9';
        
    }

    private static Messaging.SingleEmailMessage PartnerAdminWelcomeMail(String tempPassword,EmailTemplate toAdminTemplate, Contact con, User partnerUser){
        String emailTextBody, emailHTMLBody, emailToList, emailCCList, pUsername;
        Messaging.SingleEmailMessage partnerAdminMail;
        
        pUsername = Util.isLunaConnectionActive() ? con.Login__c : partnerUser.Username;
        emailToList = partnerUser.Email;
        emailCCList = '';
        System.Debug('==loginUnderscoreUnderscoreC PRM_SendMail PartnerAdminWelcomeMail pUsername ' + pUsername + 'conLogin__c ' + con.Login__c);
       	emailTextBody = toAdminTemplate.Body.replaceAll('#user#',partnerUser.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
		                       	.replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideAdminLink#',QuickReferenceGuideAdminLink);
        emailHTMLBody = toAdminTemplate.HtmlValue.replaceAll('#user#', partnerUser.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
		                        .replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideAdminLink#',QuickReferenceGuideAdminLink);
        partnerAdminMail = GsmUtilClass.createSingleEmail(emailToList,emailCCList,toAdminTemplate.Subject,emailTextBody,emailHTMLBody);
        
        return partnerAdminMail;
    }
    
    private static Messaging.SingleEmailMessage NotifyOthersMail(EmailTemplate notifyOthersTemplate, Contact con, User partnerUser){
        String emailTextBody, emailHTMLBody, emailToList, emailCCList;
        Messaging.SingleEmailMessage notifyOthersMail;
        
        emailToList = con.Account.Owner.Email;
        emailCCList = PRM_SendMail.populateEmailCCList(con);
	    emailHTMLBody = notifyOthersTemplate.HtmlValue.replaceAll('#portalUserFullName#', con.Name);
	    emailHTMLBody = emailHTMLBody.replaceAll('#portalUserCompanyName#', con.Account.Name);
	    emailTextBody = notifyOthersTemplate.Body.replaceAll('#portalUserFullName#', con.Name);
	    emailTextBody = emailTextBody.replaceAll('#portalUserCompanyName#', con.Account.Name);
	    
	    if (con.Phone !=null){
	    	emailHTMLBody = emailHTMLBody.replaceAll('#portalUserPhoneNo#', con.Phone);
	    	emailTextBody = emailTextBody.replaceAll('#portalUserPhoneNo#', con.Phone);
	    } else {
	        emailHTMLBody = emailHTMLBody.replaceAll('#portalUserPhoneNo#', 'NA');
	        emailTextBody = emailTextBody.replaceAll('#portalUserPhoneNo#', 'NA');
	    }
	    if (partnerUser.Email !=null){
	    	emailHTMLBody = emailHTMLBody.replaceAll('#portalUserEmail#', partnerUser.Email);
	    	emailTextBody = emailTextBody.replaceAll('#portalUserEmail#', partnerUser.Email);
	    } else {
	        emailHTMLBody = emailHTMLBody.replaceAll('#portalUserEmail#', 'NA');
	        emailTextBody = emailTextBody.replaceAll('#portalUserEmail#', 'NA');
	    }
        notifyOthersMail = GsmUtilClass.createSingleEmail(emailToList,emailCCList,notifyOthersTemplate.Subject,emailTextBody,emailHTMLBody);
        return notifyOthersMail;
    }
    
   private static Messaging.SingleEmailMessage PartnerUserWelcomeMail(String tempPassword,EmailTemplate toUserTemplate, Contact con, User partnerUser){
        String emailTextBody, emailHTMLBody, emailToList, emailCCList, pUsername;
        Messaging.SingleEmailMessage partnerUserMail;
        String strPortalAdmin = getPortalAdminString(con);
        //SFDC-7653 - @nadesai
        String strPortalAdminHeader = '<br />Please find below list of ' + NAPSettings.getValue('NAPRebrand_Type1') + ' for ' + con.Account.Name + '.';
        
        pUsername = Util.isLunaConnectionActive() ? con.Login__c : partnerUser.Username;
        System.Debug('==loginUnderscoreUnderscoreC PRM_SendMail PartnerUserWelcomeMail pUsername ' + pUsername + 'conLogin__c ' + con.Login__c);
        emailToList = partnerUser.Email;
        emailCCList = '';
	    emailHTMLBody = toUserTemplate.HtmlValue.replaceAll('#user#', partnerUser.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
	                        .replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideContactLink#',QuickReferenceGuideContactLink);
	    emailTextBody = toUserTemplate.Body.replaceAll('#user#', partnerUser.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
	                        .replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideContactLink#',QuickReferenceGuideContactLink);
	    if (String.isBlank(strPortalAdmin)){
	        emailHTMLBody = emailHTMLBody.replaceAll('#PORTALADMINS#',' ');
	        emailTextBody = emailTextBody.replaceAll('#PORTALADMINS#',' ');
	    } else {
	    	emailHTMLBody = emailHTMLBody.replaceAll('#PORTALADMINS#',strPortalAdminHeader + strPortalAdmin);
	        emailTextBody = emailTextBody.replaceAll('#PORTALADMINS#',strPortalAdminHeader + strPortalAdmin);
	    }
        partnerUserMail = GsmUtilClass.createSingleEmail(emailToList,emailCCList,toUserTemplate.Subject,emailTextBody,emailHTMLBody);
        return partnerUserMail;
    }
    
    private static Messaging.SingleEmailMessage PartnerWelcomeMail_OneTime(String tempPassword, EmailTemplate emailTemplate, Contact con){
        String emailTextBody, emailHTMLBody, emailToList, emailCCList, pUsername;
        Messaging.SingleEmailMessage partnerAdminMail;
        
        pUsername = con.Login__c;
        System.Debug(' ==loginUnderscoreUnderscoreC PartnerWelcomeMail_OneTime pUsername' + pUsername);
        emailToList = con.Email;
        emailCCList = '';
       	emailTextBody = emailTemplate.Body.replaceAll('#user#',con.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
		                       	.replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideAdminLink#',QuickReferenceGuideAdminLink);
        emailHTMLBody = emailTemplate.HtmlValue.replaceAll('#user#', con.Name).replaceAll('#username#', pUsername).replaceAll('#password#', tempPassword)
		                        .replaceAll('#OrgFaxLink#',sfPortalURL).replaceAll('#QuickReferenceGuideAdminLink#',QuickReferenceGuideAdminLink);
        partnerAdminMail = GsmUtilClass.createSingleEmail(emailToList,emailCCList,emailTemplate.Subject,emailTextBody,emailHTMLBody);
        
        return partnerAdminMail;
    }
    
    private static Messaging.SingleEmailMessage AkamaiUniversityUserWelcomeMail(String tempPassword, EmailTemplate AUWelcomeTemplate, Contact con){
        String emailTextBody, emailHTMLBody, emailToList, emailCCList;
        Messaging.SingleEmailMessage auWelcomeMail;
		String CsodUrl = Util.getCsodSamlUrl();
		
        emailToList = con.Email;
        emailCCList = '';
	    
        System.Debug('==loginUnderscoreUnderscoreC AkamaiUniversityUserWelcomeMail PRM_SendMail con.login__c'+con.Login__c);
	    emailHTMLBody = AUWelcomeTemplate.HtmlValue.replaceAll('#user#', con.Name).replaceAll('#PartnerUniversityLink#',partnerUnivesityURL).replaceAll('#username#', con.Login__c).replaceAll('#password#', tempPassword)
	                        .replaceAll('#OrgFaxLink#',CsodUrl);
	    emailTextBody = AUWelcomeTemplate.Body.replaceAll('#user#', con.Name).replaceAll('#PartnerUniversityLink#',partnerUnivesityURL).replaceAll('#username#', con.Login__c).replaceAll('#password#', tempPassword)
	                        .replaceAll('#OrgFaxLink#',CsodUrl);
        auWelcomeMail = GsmUtilClass.createSingleEmail(emailToList,emailCCList,AUWelcomeTemplate.Subject,emailTextBody,emailHTMLBody);
        return auWelcomeMail;
    }
    
    private static String getPortalAdminString(Contact PartnerCon){
        String strPortalAdmin = '';
        List<User> partnerAdminList = PRM_SendMail.getPortalAdminsList(PartnerCon);
        if (!partnerAdminList.isEmpty()){
            strPortalAdmin = generatePortalAdminString(partnerAdminList);
        }
        return strPortalAdmin;
    }    

}