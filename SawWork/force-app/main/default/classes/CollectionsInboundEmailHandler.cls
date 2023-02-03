/**
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 */
 
global class CollectionsInboundEmailHandler implements Messaging.InboundEmailHandler {
 private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('CollectionsEmailToCase');
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult inboundEmailResult = new Messaging.InboundEmailresult();
        
        //Daclaration and initialization
        String emailResult='';
        String emailBodyText;
        String emailSubjectText=email.subject;
        String emailSubjectCopy=email.subject;
        String caseNumber;
        Integer index;
        String taskbodytext;
        Contact con;
        User contextUser,usr,defaultUser;
        Integer i;
        Case ca = NULL;
        Boolean CasefoundFlag = FALSE;
        Boolean NoContactFoundFlag=true;
        // Getting email message Body as text 
        if(email.plainTextBody !=null)
        {
        	emailBodyText=email.plainTextBody;
        }
        else if(email.htmlBody !=null)
        {
        	emailBodyText=convertHtmlBodyToText(email.htmlBody);
        }
        else
        {
             emailBodyText ='';
        }
        // Getting the custom settings
        String CaseType=CustomSettings.CaseType__c;
        String Severity = CustomSettings.Severity__c;
        String Priority=CustomSettings.Priority__c;
        String delimiter=CustomSettings.delimiter__c;
        String ContextAlias=CustomSettings.ContextAlias__c;
        String GroupEmail=CustomSettings.GroupEmail__c;
        String CaseRecord=CustomSettings.CaseRecord__c;
        // getting related contact for fromAddress 
        for(Contact c : [select Id, AKAM_Contact_ID__c from Contact where email = :email.fromAddress])
         {
            NoContactFoundFlag=false;
            con=c;
            emailResult=emailResult+'Contact Found. Id : '+con.Id+'\n';
          }
          for(User u: [select Id, Akam_User_Id__c,Alias,email,IsActive from User where email = :email.fromAddress or Alias = :ContextAlias])
          {
              if(u.email == email.fromAddress && u.IsActive==TRUE)
                   usr = u;
              else if (u.Alias == ContextAlias)
                   defaultUser = u;
           }
           if(usr!=null)
           {
           	contextUser=usr;
           }
           else 
           {
           	contextUser=defaultUser;
           }
           emailResult=emailResult+'User Found. Id : '+contextUser.Id+'\n';
           if(emailSubjectText.indexOf(delimiter)!=-1)
           {
           	CasefoundFlag=TRUE;
           	index = emailSubjectText.lastindexof(delimiter);
           	caseNumber=getCaseNumber(emailSubjectText,delimiter);
           	emailResult=emailResult+'Case Number Found. CaseNumber : '+caseNumber+'\n';  
           	emailSubjectText = emailSubjectText.substring (index+7);
           	for (Case cas : [Select Id from Case where CaseNumber = :caseNumber ])// Get case number
              {
               	ca=cas;
              }
            if(ca!=null)  
            emailResult=emailResult+'Case Found. Id : '+ca.Id+'\n';  
            if(ca==NULL)
              CasefoundFlag=FALSE;    
           }
           if(CasefoundFlag)
           {
           	 // Create task and Attachments
	                 // if length is more than 32000 make it as an attachment
	                 if(emailBodyText.length()<32000)
	                         taskbodytext =emailBodyText;
	                 else
	                         taskbodytext =emailBodyText.substring(0,10000)+'......................... Length has exceeded the available size. The contents have been attached as file : Email contents.txt';
	                 Task ta=EmailToCase.createtask(contextUser,ca.Id,emailSubjectText,taskbodytext);
	                 if(NoContactFoundFlag==false)//add the contact only if its found
	                    ta.WhoId=con.id;
	                 insert ta;
	                 
	                //Handle Attachments for Task.
	                 handleInboundEmailAttachment(ta.Id,contextUser.Id,emailBodyText,email);
	         // Create Email Message and Attachments
	         
	                 String cText;
	                 List<EmailMessage> newEmail = new List<EmailMessage>();
	                 newEmail.add(new EmailMessage(FromAddress = email.fromaddress,Incoming = true,MessageDate = System.now(),Status ='1',ParentId = ca.Id));
		             if(email.subject!=null )
		             {
		             	newEmail[0].Subject=email.subject;
		             }
		             if(email.fromname!=null )
		             {
		                newEmail[0].FromName=email.fromname;
		             }
		             if(email.plainTextBody!=null )
		             {
		                newEmail[0].TextBody=(email.plainTextBody.length()<10000?email.plainTextBody:email.plainTextBody.substring(0,10000));
		             }
		             if(email.htmlbody!=null )
		             {
        	            newEmail[0].HtmlBody=(email.htmlbody.length()<10000?email.htmlbody:email.htmlbody.substring(0,10000));
		             }
		             if(email.toaddresses!=null && email.toaddresses.size() > 0)
		             {
		                newEmail[0].ToAddress=email.toaddresses[0];
		             }
			         if ( email.ccAddresses!=null && email.ccAddresses.size() > 0)
			         {
			            cText = '';
			            for (i = 0 ; i < email.ccAddresses.size() ; i++) 
			            {
			                cText = cText + email.ccAddresses[i]+';';
			            }
			            newEmail[0].CcAddress = cText;
			         }
			         if ( email.headers!=null && email.headers.size() > 0)
			         {
			            cText = '';
			            for (i = 0 ; i < email.headers.size() ; i++) 
			            {
			                cText = cText + email.headers[i].name+' = '+email.headers[i].value;
			            }
			            newEmail[0].headers = cText;
			         }
			        insert newEmail;
			        handleInboundEmailAttachment(newEmail[0].Id,contextUser.Id,emailBodyText,email);
			        handleInboundEmailAttachment(ca.Id,contextUser.Id,emailBodyText,email);
                  
           }
       /* Messaging.SingleEmailMessage eMsg=new  Messaging.SingleEmailMessage();
         eMsg.setSubject('Inbound Email Results');
         eMsg.setToAddresses(new String[] {'clohani@akamai.com'});
         eMsg.setPlainTextBody(emailResult);
      Messaging.sendEmail(new Messaging.Singleemailmessage[] {eMsg});*/
           return null;
    }
    
    public static void handleInboundEmailAttachment(Id parentId,Id UserId, String bodyText,Messaging.InboundEmail email)
    {
    	List<Attachment> AttList = new List<Attachment>();
	    // for binary attachemnt
	    if (email.binaryAttachments != null && email.binaryAttachments.size() > 0)
	        {
	          for(Integer i=0;i<email.binaryAttachments.size();i++)
	           {
	           	if(email.binaryAttachments[i].filename==null || email.binaryAttachments[i].filename=='')
	           	{
	               	 email.binaryAttachments[i].filename='AttachMessage'+i+'.txt';
	           	}
	           	if(email.binaryAttachments[i].body==null || email.binaryAttachments[i].body==blob.valueOf(''))
	           	{
	               	 email.binaryAttachments[i].body=blob.valueOf('AttachBody'+i);
	           	}
	            Attachment at=EmailToCase.createattach(parentId,UserId,email.binaryAttachments[i].body,email.binaryAttachments[i].filename);
	            AttList.add(at);
	          }                  
	                             
	         }
	      // For Text Attachments
	      if (email.textAttachments != null && email.textAttachments.size() > 0)
	         {
	           for(Integer i=0;i<email.textAttachments.size();i++)
	             {
	              if(email.textAttachments[i].filename==null || email.textAttachments[i].filename=='')
	              {
	               	 email.textAttachments[i].filename='AttachMessage'+i+'.txt';
	              }
	              if(email.textAttachments[i].body==null || email.textAttachments[i].body=='')
	              {
	               	 email.textAttachments[i].body='AttachBody'+i;
	              }
	              Attachment at=EmailToCase.createattach(parentId,UserId,blob.valueOf(email.textAttachments[i].body),email.textAttachments[i].filename);
	              AttList.add(at);
	             }
	          }
	      //if length of body is greater than 32000 , make it as an attachment.
	      if (bodyText.length()>=32000)
	         {
	            Attachment at=EmailToCase.createattach(parentId,UserId,blob.valueOf(bodyText),'Email contents.txt');
	            AttList.add(at);
	         }
	     if(AttList.size()>0)
	     {
             insert AttList;
	     }                     
	}
    private static String getCaseNumber(string subjecttext,String delimiter)
    {
        String caseNumber;
        integer index=subjecttext.lastindexof(delimiter);
        index += delimiter.length();
        String subjectTrimmed=subjecttext.subString(index);
        Integer colonIndex=subjectTrimmed.indexOf(':');
        caseNumber = subjecttext.substring(index,index+colonIndex);
        caseNumber=caseNumber.trim();
        return caseNumber;
    }
    private static String convertHtmlBodyToText(String htmlBody)
    {
    	String HTML_TAG_PATTERN = '<style.*?>.*?</style>'; //regular expression to match all HTML/XML tags
    	String result = htmlBody.replaceAll('<br/>', '\n');
    	 result = result.replaceAll('\n', '');
		 result = result.replaceAll('<br />', '\n');
		 result = result.replaceAll('</p>', '\n');
	    
		 pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
		 matcher myMatcher = myPattern.matcher(result); 			// get your matcher instance
		 result = myMatcher.replaceAll('');			//remove the tags     
		 myPattern = pattern.compile('<.*?>');
		 myMatcher = myPattern.matcher(result); 			// get your matcher instance
	     result = myMatcher.replaceAll('');
         return result;
    }
}