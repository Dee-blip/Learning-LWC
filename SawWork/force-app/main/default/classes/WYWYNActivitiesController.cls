/***
    WYWYNActivitiesController
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This is the Custom Controller used in WYWYNActivities Page
            
    @History
    --Developer           --Date            --Change
    Ali K      		 23/02/2011         Created this class.
                                            CR 939781 Inside Sales- Requirement    
	Ali K			 21/03/2011			Bug fix, if current User Phone is null replace text with N/A  
										CR 992937 Enhance WYWYN workflow
	Ali K			 21/03/2011			CR 992937 Enhance WYWYN workflow
										- Added code to handle requests Leads.WYWYN-Email button.											
	Ali KM			 28/04/2011			CR 1068366 WYWYN Email VF page throws Exception INVALID_EMAIL_EXCEPTION, 
										email address has bounced.
										- Added try/catch to handle this exception.										                                                                               
*/			

public class WYWYNActivitiesController
{
    private User currentUser;
    private Boolean configurationError = false;
    private Boolean initializationError = false;
    private String configurationErrorMessage;
    private String initializationErrorMessage;	
    private Boolean isLead = false;
    	
    public Contact ct {get; set;}
    public EmailTemplate emailTemplate {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}      
    public Task emailTask {get;set;}
    public Boolean showPage {get; set;}
    public Boolean emptyOAId {get; set;}    
    public Boolean firstLoaded=false;
    public static Map<String,WYWYNActivitiesSettings__c> customSettings = WYWYNActivitiesSettings__c.getAll();
    
    private String getCustomSettingsValue(String pName)
    {
    	return customSettings.get(pName).Value__c;
    }
    private void showErrorAndDiscontinue(String pErrorMessage)
    {
        showPage = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));    	
    }    

    // constructor
    public WYWYNActivitiesController() 
    {  
    	// ensure this works only if this feature is enabled.
    	Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('WYWYNActivitiesPageToggle');
    	if(featureToggle.Toggle__c == false)
    	{
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, featureToggle.Disabled_Alert_Message__c);
            ApexPages.addMessage(errMsg);
            emptyOAId = true;	
			showPage = false;  		
            return;
    	}
        showPage = true;
        firstLoaded = init();
    }
    // init method
    public Boolean init()
    {
    	emailTask = new Task();    	
        for(Contact cntct : [SELECT Id, Email, AccountId, Account.Name, Name, Phone, FirstName, LastName  
        					  FROM Contact        					  
        					  WHERE id=:ApexPages.currentPage().getParameters().get('id')])	  
	        ct = cntct;
	    if (ApexPages.currentPage().getParameters().get('islead')=='true')
			isLead = true;
	    if(ct == null)
	    {
	    	emptyOAId = false;
	    	initializationError=true;
	    	initializationErrorMessage = 'Oops! cant find the Contact record, please return to previous page and try again.';
	    }
	    else if(ct.Email==null)
	    {
	    	emptyOAId = true;
	    	initializationError=true;	    	
	    	initializationErrorMessage = 'This contact does not have a valid Email id, please return to contact page and update Email id.';
	    }        
        if (!initializationError)
	    {
	        for(EmailTemplate template : [SELECT Id, Subject, Body 
										  FROM EmailTemplate 
							 			  WHERE Id = :getCustomSettingsValue('EmailTemplateId')])
        		emailTemplate = template;
	        	
	        // Fetch Current User Info: 
	        for (User usr : [SELECT Id, FirstName, LastName, Phone, Email
	        				 FROM User
	        				 WHERE Id = :Userinfo.getUserId()])        	      
	        	currentUser = usr;
	        if (currentUser.Phone == null)
	        	 currentUser.Phone = 'N/A';
			if (currentUser.Email == null)
	        	 currentUser.Email = 'N/A';
	        if (emailTemplate==null)
	        {
	        	emptyOAId = true;
	        	configurationError=true;
	    		configurationErrorMessage = 'Error initializing this page, Please contact system administrator.';	    		
	        }
	    }
	    if (initializationError || configurationError)
	    {
	    	String errorMessage;
	    	if (initializationErrorMessage!=null)
	    		errorMessage = initializationErrorMessage;
	    	else
	    		errorMessage = configurationErrorMessage;
	    	showErrorAndDiscontinue(errorMessage);
	    	return false;	    	
	    }
	    //OALink = getCustomSettingsValue('Server Url') + '/' + oa.Id; 
        String emailSubjectStr = emailTemplate.Subject;         
        String emailBodyStr = emailTemplate.Body;       
        emailSubjectStr = emailSubjectStr.replace('##Subject##', getCustomSettingsValue('EmailSubject'));                 
        emailBodyStr = emailBodyStr.replaceAll('##Contact_FirstName##', ct.FirstName);
        emailBodyStr = emailBodyStr.replaceAll('##User_FirstName##',currentUser.FirstName);
        emailBodyStr = emailBodyStr.replaceAll('##User_LastName##',currentUser.LastName);
        emailBodyStr = emailBodyStr.replaceAll('##User_Phone##',currentUser.Phone);
        emailBodyStr = emailBodyStr.replaceAll('##User_Email##',currentUser.Email);  
        //if(oa.Approvals_Required__c != null)      
        //    emailBodyStr = emailBodyStr.replaceAll('##APPROVALS_REQUIRED##', oa.Approvals_Required__c);
        emailTask.Subject = emailSubjectStr;
        emailTask.Description = emailBodyStr;
		return true;
    }
    // sendEmail button method
    public PageReference sendEmail()
    {    
        String strSendEmailResult=null;    
        Boolean isError = false;
        User dmlUser = new User(id=UserInfo.getUserId());
        try
        {
        	if (emailTask.Subject.length()==0 || emailTask.Description.length()==0)       
        	{                               
            	emailTask.Subject.addError('Email Subject and Email Body cannot be empty');
            	isError=true;
        	}
            else
            {
                showPage = false;
                strSendEmailResult = this.sendEmail(ct.Id, emailTask.Subject, emailTask.Description);
                if (strSendEmailResult!=null)
                {   
                	isError=true;
                	emptyOAId = true;
                	showErrorAndDiscontinue(strSendEmailResult);
                }	
                else
                {	
                	emailTask.Subject = 'WYWYN-Email ' + emailTask.Subject;                                             
                    emailTask.WhatId = ct.AccountId;
                    emailTask.WhoId = ct.Id;
                    emailTask.OwnerId = UserInfo.getUserId();
                    emailTask.Status = 'Completed';
                    emailTask.Type__c = 'WYWYN-Email';
                    emailTask.ActivityDate = Date.today();
                    try 
                    {
                        System.runAs(dmlUser)
                        {
                            insert emailTask;
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Email was sent successfully and logged as an Activity.'));
                    }
                    catch (exception ex)
                    {
                    	isError = true;
                        throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                    }                        
               	}	                                  
            }                               
        }
        catch (exception ex)
        {
            //throw new CustomException('An error has occured during email process. Please contact system administrator. Error Details : '+ex);
            // Handle only exception that you know off .... throw back the rest 
            throw ex;  
            showPage = false;  
            isError = true;   
        }         
        if(!isError)
        {
        	if (!isLead)
        		return (new PageReference('/' + ct.id));
        	else
        		return (new PageReference('/' + ApexPages.currentPage().getParameters().get('retURL')));        		
        }
        else
        	return null; // If error,stay on the page         
    } 
    
    public PageReference cancel()
    {	
    	if (!isLead)
        	return (new PageReference('/' + ApexPages.currentPage().getParameters().get('id')));
        else
        	return (new PageReference('/' + ApexPages.currentPage().getParameters().get('retURL'))); 
    }
    
    public void reload()
    {        
    }    
    /**
           method will send email
    */
    public String sendEmail(Id pToAddress, String pSubject, String pMessage)
    {      
        Messaging.SendEmailResult[] result;
        String strExceptionMessage=null;
    	try
		{
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Set Contact as the email recipient
            mail.setTargetObjectId(pToAddress);
            mail.setSubject(pSubject);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(pMessage);
            // setSaveAsActivity to false as we are manually saving Email as Activity
            mail.setSaveAsActivity(false);
            result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        // Catch Email Exceptions
        catch(EmailException e)
        {	
        	String strEmailException = e.getDmlMessage(0);
			if (e.getDmlType(0) == StatusCode.INVALID_EMAIL_ADDRESS)
            {	     
            	strExceptionMessage =  getCustomSettingsValue('InvalidEmailErrorMessage');
                if (strEmailException.contains('bounced'))
                	strExceptionMessage = strExceptionMessage.replace('##BOUNCED_MSG##', getCustomSettingsValue('BouncedEmailErrorMessage'));
				else
					strExceptionMessage = strExceptionMessage.replace('##BOUNCED_MSG##', '');
            }   
			else if(e.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
        	{
        		strExceptionMessage = e.getMessage();
        	}
        }
        catch(Exception e1)
        {
            strExceptionMessage = e1.getMessage(); 
        }
        return strExceptionMessage;
    }
}