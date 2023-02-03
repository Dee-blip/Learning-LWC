/***
    OA_EmailBlast_Controller
    @author : Karteek Mekala <kmekala@akamai.com>; ALI KM <mohkhan@akamai.com>
    @Description : This is the Custom Controller for the OA_EmailBlast Page
            
    @History
    --Developer           --Date            --Change
    Ali KM       		 24/01/2011         Created this class.
                                            CR 920782 Email Blast - Order Approval object
                                            1. This page displays all attachments for the Order Approval & associated Opportunity
                                            2. This also displays a templated email and Contact lookup (this is tied to Akamai Assets Account) for sending email
                                            3. Once the email is sent; Email & selected Attachments are stored as Activity Completed task on Order Approval.
	Ali KM				 07/02/2011			Added Feature Toggle; to ensure this page works only if feature is enabled. Feature Toggle Name = RSMSignatureRequest.                                            
*/

public class OA_EmailBlast_Controller 
{
    public Attachment pdfAttachment;
    public Order_Approval__c oa {get; set;}
    public EmailTemplate emailTemplate {get; set;}  
    public List<OA_EmailBlast_AttachmentWrapper> oaAttachment {get; set;}
    public List<OA_EmailBlast_AttachmentWrapper> opptyAttachment {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}      
    public Task emailTask {get;set;}
    public String viewfilePath {get; set;}
    public String oaPDFName {get; set;}
    public String query {get; set;} 
    public Boolean showPage {get; set;}
    public Boolean emptyOAId {get; set;}
    public String OALink;   
    public List<Attachment> selectedAttachments;
    private List<Attachment> selectedAttachmentsWithBody;
    public Boolean firstLoaded=false;
    public Boolean setAsActivity=false;
    
    public static Map<String,OA_eBlast_Settings__c> customSettings = OA_eBlast_Settings__c.getAll();
    
    private String getCustomSettingsValue(String pName)
    {
    	return customSettings.get(pName).Value__c;
    }
    private void showErrorAndDiscontinue(String pErrorMessage)
    {
        showPage = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));    	
    }    
    private List<Attachment> getSelectedAttachmentsWithBody()
    {
    	if(selectedAttachmentsWithBody != null)
    		return selectedAttachmentsWithBody;
    	else
    	{
    		selectedAttachmentsWithBody = [select Id, 
    											  Name, 
    											  Body 
    									   from Attachment 
    									   where Id IN : selectedAttachments];
    		return selectedAttachmentsWithBody;
    	}
    }
    // constructor
    public OA_EmailBlast_Controller() 
    {  
    	// ensure this works only if this feature is enabled.
    	Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('RSMSignatureRequest');
    	if(featureToggle.Toggle__c == false)
    	{
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, featureToggle.Disabled_Alert_Message__c);
            ApexPages.addMessage(errMsg);
            emptyOAId = true;	
			showPage = false;  		
            return;
    	}
        viewfilePath = '/servlet/servlet.FileDownload?file';
        showPage = true;
        firstLoaded = init();
    }
    public Boolean init()
    {
    	emailTask = new Task();
        oaAttachment = new List<OA_EmailBlast_AttachmentWrapper>();
        opptyAttachment = new List<OA_EmailBlast_AttachmentWrapper>();
        for(Order_Approval__c o : [select Id, 
        								  Name, 
        								  Approvals_Required__c, 
        								  CCG__c, 
        								  Associated_Opportunity__r.Name, 
        								  Legal__c, 
        								  Deal_Desk__c, 
        								  //Start Modified By Chandra For CR 693820
        								  New_Churn__c, 
        								  //End Modified By Chandra For CR 693820
        								  Account_Territory__c, 
        								  Associated_Opportunity__c, 
        								  Associated_Account__c, 
        								  Associated_Opportunity_Sales_Stage__c, 
        								  Opportunity_Owner__c, 
        								  Type__c, 
        								  AKAM_OrderApproval_ID__c,
        								  Send_To_Contact__c 
        							from Order_Approval__c 
        							where id=:ApexPages.currentPage().getParameters().get('id')])	  
	        oa = o;
	    if(oa == null)
	    {
	    	showErrorAndDiscontinue('Oops! cant find the Order Approval record, please return to previous page and try again.');
	    	emptyOAId = false;
	    	return false;	
	    }
        for(EmailTemplate template : [select Subject, 
        									 Id, 
        									 Body 
        							  from EmailTemplate 
        				 			  where Id = :getCustomSettingsValue('Email Template Id')])
        	emailTemplate = template;
        oaPDFName = getCustomSettingsValue('OA PDF Name').replaceAll('##AKAM_OrderApproval_ID__c##', oa.AKAM_OrderApproval_ID__c);
        OALink = getCustomSettingsValue('Server Url') + '/' + oa.Id; 
        String emailSubjectStr = emailTemplate.Subject;         
        String emailBodyStr = emailTemplate.Body;
        oa.Send_To_Contact__c = getCustomSettingsValue('RSM Distribution List ContactId');
        emailTask.Subject = emailSubjectStr.replace('##ORDER_APPROVAL_NAME##', oa.Name);
        emailBodyStr = emailBodyStr.replaceAll('##SENDER##',Userinfo.getName());           
        emailBodyStr = emailBodyStr.replaceAll('##ORDER_APPROVAL_NAME##', oa.Name);        
        emailBodyStr = emailBodyStr.replaceAll('##OPPORTUNITY_NAME##', oa.Associated_Opportunity__r.Name);        
        emailBodyStr = emailBodyStr.replaceAll('##ACCOUNT_NAME##', oa.Associated_Account__c);  
        if(oa.Approvals_Required__c != null)      
            emailBodyStr = emailBodyStr.replaceAll('##APPROVALS_REQUIRED##', oa.Approvals_Required__c);        
        else
            emailBodyStr = emailBodyStr.replaceAll('##APPROVALS_REQUIRED##', 'None');
        if(oa.CCG__c != null)               
            emailBodyStr = emailBodyStr.replaceAll('##CCG_NUM##', oa.CCG__c);        
        else
            emailBodyStr = emailBodyStr.replaceAll('##CCG_NUM##', ' ');    
        if(oa.Deal_Desk__c != null)                      
            emailBodyStr = emailBodyStr.replaceAll('##DEAL_DESK_NUM##', oa.Deal_Desk__c);        
        else
            emailBodyStr = emailBodyStr.replaceAll('##DEAL_DESK_NUM##', ' ');    
        if(oa.Legal__c != null)                  
            emailBodyStr = emailBodyStr.replaceAll('##LEGAL_NUM##', oa.Legal__c);                                
        else
            emailBodyStr = emailBodyStr.replaceAll('##LEGAL_NUM##', ' ');                                
        emailTask.Description = emailBodyStr.replace('##ORDER_APPROVAL_LINK##', OALink);    
        
        OA_EmailBlast_AttachmentWrapper oaW;
        for (Attachment a : [Select a.Name, a.Id, a.CreatedBy.Name, a.LastModifiedDate, a.ParentId, a.Parent.Name FROM Attachment a where ParentId = :oa.Id OR ParentId = :oa.Associated_Opportunity__c Order By a.LastModifiedDate DESC])
        {
                oaW = new OA_EmailBlast_AttachmentWrapper(a);
                oaAttachment.add(oaW);
        }
        if(oaAttachment.size()==0)
        {
        	emptyOAId = true;	
            showPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));              
        }
        else
			oaAttachment.get(0).checked = true; // check the checkbox for topmost item ie. based on LastModifiedDate.	
        return true;    
    }
    
    public PageReference sendEmail()
    {   
        selectedAttachments = new List<Attachment>(); 
        String toEmailAddress=null;    
        Boolean isError = false; 
        if (oaAttachment.size()==0)
        {
        	isError = true;
            showPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));
        }
        else    
        {
                for (OA_EmailBlast_AttachmentWrapper a : oaAttachment)
                {
                        if(a.checked)
                                selectedAttachments.add(a.attach);
                }
                try
                {
                        if(selectedAttachments.size() > 0)
                        {                                
                                if(oa.Send_To_Contact__c == null)
                                	oa.Send_To_Contact__c.addError('Please select a valid Contact'); 
                                else if (emailTask.Subject.length()==0)                                      
                                        emailTask.Subject.addError('Email Subject cannot be Empty');
                                else if (emailTask.Description.length()==0)
                                        emailTask.Description.addError('Email Body cannot be Empty');
                                else
                                {
                                        showPage = false;
                                        setAsActivity = this.sendEmail(oa.Send_To_Contact__c, emailTask.Subject, emailTask.Description, oa.Id, oaPDFName);
                                        
                                        if (setAsActivity)
                                        {                                               
                                                emailTask.WhatId = oa.Id;
                                                emailTask.WhoId = oa.Send_To_Contact__c;
                                                emailTask.OwnerId = UserInfo.getUserId();
                                                emailTask.Status = 'Completed';
                                                try 
                                                {
                                                    insert emailTask;
                                                }
                                                catch (exception ex)
                                                {
                                                	isError = true;
                                                    throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                                                }                                                
                                                // Need to get the Id of the task that was just created
                                                for(Task tsk : [select Id from Task where Id = :emailTask.Id])
                                                	emailTask = tsk;
                                                // Attach all the attachments to the New Task
                                                List<Attachment> tskAttachmentList = new List<Attachment>();
                                                // PDF Attachment
                                                pdfAttachment.ParentId = emailTask.id;
                                                tskAttachmentList.add(pdfAttachment);                                                
                                                for(Attachment att:this.getSelectedAttachmentsWithBody())
                                                {
                                                    Attachment tempAttachment = new Attachment();
                                                    tempAttachment.Name = att.Name;
                                                    tempAttachment.Body = att.Body;
                                                    tempAttachment.ParentId = emailTask.Id;
                                                    tskAttachmentList.add(tempAttachment);
                                                }
                                                try 
                                                {
                                                    insert tskAttachmentList;
                                                }
                                                catch (exception ex)
                                                {
                                                	isError = true;
                                                    throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                                                }
                                                
                                                                                
                                        }
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully Sent Email with ' + (selectedAttachments.size()+1) + ' attachment(s).'));
                                }                       
                        }
                        else
                        {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Attachments selected'));
                                isError = true;
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
        } 
        if(!isError)
        	return (new PageReference('/' + oa.id));
        else
        	return null; // If error,stay on the page        
    } 
    
    public PageReference cancel()
    {	
        //return (new PageReference('/' + oa.id));
        return (new PageReference('/' + ApexPages.currentPage().getParameters().get('id')));    
    }
    
    public void reload()
    {        
    }    
    /**
           method will send email
    */ 
    public Boolean sendEmail(Id pToAddress, String pSubject, String pMessage, Id oaId, String oaPDFName)
    {      
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(pToAddress);
            mail.setSubject(pSubject);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(pMessage);
            // Loggin activity manually
            mail.setSaveAsActivity(false);
            // Attachments
            pdfAttachment = renderAsPDF(oaId, oaPDFName);
            Messaging.Emailfileattachment pdfEmailFileAttachment= new Messaging.Emailfileattachment();
            pdfEmailFileAttachment.setBody(pdfAttachment.Body);
            pdfEmailFileAttachment.setFileName(pdfAttachment.Name);            
            List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
            //efaList.add(pdfEmailFileAttachment);
            for(Attachment a:this.getSelectedAttachmentsWithBody())
            {
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(a.Name);
                    efa.setBody(a.Body);
                    efaList.add(efa);
            }
            // adding the default attachment to the end of list
            efaList.add(pdfEmailFileAttachment);
            mail.setFileAttachments(efaList);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            return true;
    }
    
    public Attachment renderAsPDF(Id oaId, String oaPDFName)
    {
        PageReference pdf =  Page.attachmentAsPDF;
        pdf.getParameters().put('id',oaId); 
        pdf.setRedirect(true);        
        // Take the PDF content
        Blob b = pdf.getContent();        
        Attachment att = new Attachment();
        att.Name = oaPDFName;
        att.Body = b;
        return att;
    }
}