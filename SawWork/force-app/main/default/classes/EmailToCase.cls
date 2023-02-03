/**
 * Email to case.
 * When email is sent to a particular address, a case is created
 * and a email is sent to case creater and queue with a unique subject.
 * All the subsequent email trasfers with attachments are tracked by case as tasks
 *
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N	12/2010		Created Class
   Vinayendra T N 	12/2010 	Moved email sending logic from workflow to Code.
   Vinayendra T N 	2/2011 		Removed html tags from email and Further optimzed the class
   Vinayendra T N	11/2011		Gave a null pointer exception for Associated Email when case number is not present
 **/
global class EmailToCase
{
    public static Case createcase(string subjecttext,string bodytext,User usr,string casetype,string sev,string priority,string fromemail,string recordid)
    {
        Case ca = new Case();
        ca.Subject=subjecttext;
        ca.Description=bodytext;
        ca.OwnerId = usr.id;
        ca.Email_to_case__c=true;
        ca.Origin='Email';
        ca.Type=casetype;
        ca.Severity__c = sev;
        ca.Priority=priority;
        ca.Associated_Email__c=fromemail;
        ca.RecordTypeId=recordid;
        ca.AKAM_Created_By__c=usr.Alias;
        ca.AKAM_Created_Date__c=Datetime.now();
        ca.AKAM_Modified_By__c=usr.Alias;
        ca.AKAM_Modified_Date__c=Datetime.now();
        ca.AKAM_System__c='FORCE';
        return ca;
    }
    public static Attachment createattach(string parentid,string ownerid,blob attachbody,string filename)
    {
        Attachment at=new Attachment();
        at.ParentId=parentid;
        at.OwnerId = ownerid;
        at.Body=attachbody;
        if(filename.length()>=80)
        	at.Name= filename.substring(0,40)+'....'+filename.substring(filename.length()-30,filename.length());
        else
        	at.Name= filename;
        at.ContentType='ContentPost';
        return at;
    }
    public static Task createtask(User usr,string taskwhatid,string subjecttext,string bodytext)
    {
        Task ta=new Task();
        ta.OwnerId=usr.id;
        ta.WhatId=taskwhatid;
        ta.Subject=subjecttext;
        ta.Type__c='Email';
        ta.Description =bodytext;
        ta.Status='Completed';
        ta.AKAM_Created_By__c=usr.Alias;
        ta.AKAM_Created_Date__c=Datetime.now();
        ta.AKAM_Modified_By__c=usr.Alias;
        ta.AKAM_Modified_Date__c=Datetime.now();
        ta.AKAM_System__c='FORCE';        
        return ta;
    }
    public static String getCaseNumber(string subjecttext,integer s)
    {
        String match;
        Integer l;
        Integer mleft;
        Integer mright;
        s += 6;
        l = subjecttext.length();
        match = subjecttext.substring(s,l);
        mleft=match.indexof('[');
        mright=match.indexof(']');
        match=match.substring(mleft+1,mright);
        match=match.trim();
        return match;
    }
    public static void init(Messaging.InboundEmail email,Email_to_Case__c CustomSettings)
    {
    	       
               String bodytext;
               if ( email.plainTextBody != null)
                  bodytext = email.plainTextBody;
               else if( email.htmlBody != null )
               {
               	    string result = email.htmlBody.replaceAll('<br/>', '\n');
               	    result = result.replaceAll('\n', '');
					result = result.replaceAll('<br />', '\n');
					result = result.replaceAll('</p>', '\n');
					//regular expression to match all HTML/XML tags
					string HTML_TAG_PATTERN = '<style.*?>.*?</style>';
					// compile the pattern     
					pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
					// get your matcher instance
					matcher myMatcher = myPattern.matcher(result);
					//remove the tags     
					result = myMatcher.replaceAll('');
					myPattern = pattern.compile('<.*?>');
					// get your matcher instance
					myMatcher = myPattern.matcher(result);
					//remove the tags     
					result = myMatcher.replaceAll('');
               	    bodytext = result;
               }
               else
                  bodytext ='';
               String subjecttext = email.subject;
               String subjecttextcopy = email.subject;
               String match;
               Integer s;
               string CaseType=CustomSettings.CaseType__c;
               string Severity = CustomSettings.Severity__c;
               string Priority=CustomSettings.Priority__c;
               Boolean NoContactFoundFlag=true;
               string delimiter=CustomSettings.delimiter__c;
               String taskbodytext;
               String ContextAlias=CustomSettings.ContextAlias__c;
               String GroupEmail=CustomSettings.GroupEmail__c;
               // Get the record type of the case
               String CaseRecord=CustomSettings.CaseRecord__c;
               Boolean CasefoundFlag = FALSE;
                // get the contact corresponding to the email address
               Contact con;
               integer i;
                for(Contact c : [select Id, AKAM_Contact_ID__c from Contact where email = :email.fromAddress])
                {
                  NoContactFoundFlag=false;
                  con=c;
                }
                // if user exists in database, make the user owner of create task/case/attach or use the context user as owner
                User user,usr,defaultUsr;
               for(User u: [select Id, Akam_User_Id__c,Alias,email,IsActive from User where email = :email.fromAddress or Alias = :ContextAlias])
               {
                    if(u.email == email.fromAddress && u.IsActive==TRUE)
                    usr = u;
                    else if (u.Alias == ContextAlias)
                    defaultUsr = u;
               }
               
               if(usr!=null)
               user=usr;
               else
               user=defaultUsr;
               Case ca = NULL;
  
               if (subjecttext.lastindexof(delimiter) != -1)
               { 
				 CasefoundFlag=TRUE;
                 s = subjecttext.lastindexof(delimiter);
                 //public string getCaseNumber(string subjecttext,integer s)
                 match=EmailToCase.getCaseNumber(subjecttext,s);
                 subjecttext = subjecttext.substring (0,s);

                 //public static Task createtask(string ownerid,string taskwhatid,boolean NoContactFoundFlag,string taskwhoid,string subject,string subjecttext,string bodytext)
                 for (Case cas : [Select Id from Case where CaseNumber = :match ])// Get case number
                 {
                 	ca=cas;
                 }
                 //If case is not found and then a new case must be created.
                 if(ca==NULL)
                 CasefoundFlag=FALSE;       
               }
               else
               {
               	 String SubjectTruc=subjecttext;
               	 String BodyTruc=bodytext;
               	 //check if subject is present
               	 SubjectTruc = SubjectTruc.replaceAll('FW: ', '');
               	 SubjectTruc = SubjectTruc.replaceAll('Fw: ', '');
               	 SubjectTruc = SubjectTruc.replaceAll('Re: ', '');
               	 SubjectTruc = SubjectTruc.replaceAll('RE: ', '');
               	 String SubjectLike='%'+SubjectTruc+'%';
               	 if(SubjectTruc.length()>2)
               	 {
	               	 for (Case cas : [Select Id,Associated_Email__c,Description from Case where Subject Like :SubjectLike and RecordTypeId=:CaseRecord ])// Get case number
	                 {
	                 	ca=cas;
	                 }
               	 }
                 if(ca!=null)
                 {
         			//The case creator`s email id is in the To/From/cc list of recieved email.
         			//The cc address has momentum-help email id
                 	Boolean CaFound=false;
                 	Boolean GroupFound=false;
                 	if(ca.Associated_Email__c!=null && ca.Associated_Email__c!='')
                 	{
	                 	if(email.fromaddress==ca.Associated_Email__c)
	                 		CaFound=true;
	                 	
	                 	if(email.toaddresses!=null && email.toaddresses.size() > 0)
			            {
			            	 if(email.toaddresses[0].contains(ca.Associated_Email__c))
			            	 	CaFound=true;
			            	 if(email.toaddresses[0].contains(GroupEmail))
					        	GroupFound=true;
			            }
			            if ( email.ccAddresses!=null && email.ccAddresses.size() > 0){
				            
				            for (i = 0 ; i < email.ccAddresses.size() ; i++) {
				                if(email.ccAddresses[i].contains(ca.Associated_Email__c))
				                 CaFound=true;
				                if(email.ccAddresses[i].contains(GroupEmail))
						         GroupFound=true;
				         }
			           
			      		 }
                 	}
			        if(CaFound==true && GroupFound==true)
			        {
			        	//Throw new CustomException('here2');
			        	//The case description is found in the received email.
			        	string descrip;
			        	if(ca.Description.length()<=1000)
			        		descrip=ca.Description;
			        	else
			        		descrip=ca.Description.substring(ca.Description.length()-1000,ca.Description.length());
			        	
			        	if(BodyTruc.contains(descrip))
			        	{
			        		Task ta=null;
			        			
			        		for(Task tas:[select LastModifiedDate from Task where WhatId=:ca.id ])
			        		{
			        			if(tas.LastModifiedDate > (datetime.now().addDays(-2)))
			        				CasefoundFlag=TRUE;
			        		}
			        		
			        	}
			        }
                 }
               }
               // If case is not found then create a new case
               if(CasefoundFlag==FALSE)
               {
               	subjecttext = subjecttextcopy;
               	// if length is more than 32000 make it as an attachment
                if(bodytext.length()<32000)
                         taskbodytext =bodytext;
                else
                         taskbodytext =bodytext.substring(0,10000)+ '.....................Length has exceeded the available size. The contents have been attached as file : Email contents.txt';
                //public static Case createcase(string subjecttext,string bodytext,string ownerid,string casetype,string sev,string priority,string fromemail,string recordid)
                ca = createcase(subjecttext,taskbodytext,user,CaseType,Severity,Priority,email.fromAddress,CaseRecord);
                if(NoContactFoundFlag==false)//add the contact only if its found
                	ca.ContactId=con.id;
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;
                ca.setOptions(dmo);
                insert ca;
                	// if length is more than 32000 make it as an attachment
	                if(email.plainTextBody!=null && email.plainTextBody.length()>=32000)
	                         email.plainTextBody =email.plainTextBody.substring(0,10000)+ '.....................Length has exceeded the available size. The contents have been attached as file : Email contents.txt';
	                   //add the email
	                 String cText;
	                 EmailMessage[] newEmail = new EmailMessage[0];
	                 newEmail.add(new EmailMessage(FromAddress = email.fromaddress,
		             Incoming = true,
		             MessageDate = System.now(), 
		             Status ='1',   
		             ParentId = ca.Id));
		             if(email.subject!=null )
		             newEmail[0].Subject=email.subject;
		             if(email.fromname!=null )
		             newEmail[0].FromName=email.fromname;
		             if(email.plainTextBody!=null )
		             newEmail[0].TextBody=(email.plainTextBody.length()<10000?email.plainTextBody:email.plainTextBody.substring(0,10000));
		             if(email.htmlbody!=null )
		             newEmail[0].HtmlBody=(email.htmlbody.length()<10000?email.htmlbody:email.htmlbody.substring(0,10000));
		             if(email.toaddresses!=null && email.toaddresses.size() > 0)
		             newEmail[0].ToAddress=email.toaddresses[0];
			         if ( email.ccAddresses!=null && email.ccAddresses.size() > 0){
			            cText = '';
			            for (i = 0 ; i < email.ccAddresses.size() ; i++) {
			                cText = cText + email.ccAddresses[i]+';';
			            }
			            newEmail[0].CcAddress = cText;
			         }
			         if ( email.headers!=null && email.headers.size() > 0){
			            cText = '';
			            for (i = 0 ; i < email.headers.size() ; i++) {
			                cText = cText + email.headers[i].name+' = '+email.headers[i].value;
			            }
			            newEmail[0].headers = cText;
			         }
			        insert newEmail;
                      //Handle Attachments
                      List<Attachment> AttList = new List<Attachment>();
                      // for binary attachemnt
                        if (email.binaryAttachments != null && email.binaryAttachments.size() > 0)
                         {
                            
                            for(i=0;i<email.binaryAttachments.size();i++)
                             {
                             if(email.binaryAttachments[i].filename==null ||  email.binaryAttachments[i].filename=='')
	                         	email.binaryAttachments[i].filename='AttachMessage'+i+'.txt';
	                         if(email.binaryAttachments[i].body==null || email.binaryAttachments[i].body==blob.valueOf(''))
	                         	email.binaryAttachments[i].body=blob.valueOf('AttachBody'+i);
                             Attachment at=createattach(ca.Id,user.id,email.binaryAttachments[i].body,email.binaryAttachments[i].filename);
                             AttList.add(at);
                             }
                             
                         }
                         // For Text Attachments
	                      if (email.textAttachments != null && email.textAttachments.size() > 0)
	                      {
	                            
	                            for(i=0;i<email.textAttachments.size();i++)
	                             {
	                             if(email.textAttachments[i].filename==null || email.textAttachments[i].filename=='')
	                            	 email.textAttachments[i].filename='AttachMessage'+i+'.txt';
	                             if(email.textAttachments[i].body==null || email.textAttachments[i].body=='')
	                             	 email.textAttachments[i].body='AttachBody'+i;
	                             Attachment at=createattach(ca.Id,user.id,blob.valueOf(email.textAttachments[i].body),email.textAttachments[i].filename);
	                             AttList.add(at);
	                             }
	                             
	                      }
                         //if length of body is greater than 32000 , make it as an attachment.
                         if (bodytext.length()>=32000)
                         {
                            
                             Attachment at=createattach(ca.Id,user.id,blob.valueOf(bodytext),'Email contents.txt');
                             AttList.add(at);
                             
                         }
                         if(AttList.size()>0)
                                insert AttList;
                          String[] cca=new String[] {};
                          if(email.ccAddresses!=null && email.ccAddresses.size()>0)
                          ccA=email.ccAddresses;
                          if(email.toAddresses!=null && email.toAddresses.size()>0)
                      	  {
                      	  	for(String toA:email.toAddresses)
                          	ccA.add(toA);
                      	  }
                      	  //Send email
                          CaseTriggerClass.EmailToCaseSendEmail(new Case[] {ca},CustomSettings,ccA);
                          //Add reporter to case team
               			  Id reporterTeamRoleId;
						  for(CaseTeamRole ctr: [select Id from CaseTeamRole where Name='Reporter'])
							reporterTeamRoleId = ctr.Id;
						  List<CaseTeamMember> ctmInsertList = new List<CaseTeamMember>(); 
						  ctmInsertList.add(CaseTriggerClass.AddUserToCaseTeam(ca.Id, user.id, reporterTeamRoleId));
						  try{
						  	insert ctmInsertList;
						  }
						  catch(Exception e){
						  	if(!e.getMessage().contains('DUPLICATE_VALUE')){
						  		throw e;
						  	} 
						  }
               }
               else
               {
	                 // if length is more than 32000 make it as an attachment
	                 if(bodytext.length()<32000)
	                         taskbodytext =bodytext;
	                 else
	                         taskbodytext =bodytext.substring(0,10000)+'......................... Length has exceeded the available size. The contents have been attached as file : Email contents.txt';
	                 Task ta=createtask(user,ca.Id,subjecttext,taskbodytext);
	                 if(NoContactFoundFlag==false)//add the contact only if its found
	                    ta.WhoId=con.id;
	                 insert ta;
	                 
	                 //Handle Attachments.
	                 List<Attachment> AttList = new List<Attachment>();
	                        //public static Attachment createattach(string parentid,string ownerid,blob attachbody,string filename)
	                        // for binary attachemnt
	                        if (email.binaryAttachments != null && email.binaryAttachments.size() > 0)
	                         {
	                            
	                            for(i=0;i<email.binaryAttachments.size();i++)
	                             {
	                             if(email.binaryAttachments[i].filename==null || email.binaryAttachments[i].filename=='')
	                            	 email.binaryAttachments[i].filename='AttachMessage'+i+'.txt';
	                             if(email.binaryAttachments[i].body==null || email.binaryAttachments[i].body==blob.valueOf(''))
	                             	 email.binaryAttachments[i].body=blob.valueOf('AttachBody'+i);
	                             Attachment at=createattach(ta.Id,user.id,email.binaryAttachments[i].body,email.binaryAttachments[i].filename);
	                             AttList.add(at);
	                             }
	                             
	                         }
	                         // For Text Attachments
	                         if (email.textAttachments != null && email.textAttachments.size() > 0)
	                         {
	                            
	                            for(i=0;i<email.textAttachments.size();i++)
	                             {
	                             if(email.textAttachments[i].filename==null || email.textAttachments[i].filename=='')
	                            	 email.textAttachments[i].filename='AttachMessage'+i+'.txt';
	                             if(email.textAttachments[i].body==null || email.textAttachments[i].body=='')
	                             	 email.textAttachments[i].body='AttachBody'+i;
	                             Attachment at=createattach(ta.Id,user.id,blob.valueOf(email.textAttachments[i].body),email.textAttachments[i].filename);
	                             AttList.add(at);
	                             }
	                             
	                         }
	                         //if length of body is greater than 32000 , make it as an attachment.
	                         if (bodytext.length()>=32000)
	                         {
	                            
	                             Attachment at=createattach(ta.Id,user.id,blob.valueOf(bodytext),'Email contents.txt');
	                             AttList.add(at);
	                             
	                         }
	                         if(AttList.size()>0)
	                                insert AttList;
                  }
         
    }
    
    
}