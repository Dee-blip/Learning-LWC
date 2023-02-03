/*
 * Ticket: SFDC-1654
 * Developer: Sharath Prasanna
 * Enhancement: External Survey Controller
 * Date: June 20 2017
 * 
 * CR: FF Upgrade 19.1
 * Developer: Sandeep Naga
 * Change: Merge External_Survey_metadata__mdt metadata into PSA_Common_Setting__mdt
 * Date: 28th Novemeber 2018
 *
*/ 


public class ExternalSurveyConsoleController {

	public String surveyId;
	public Integer sequenceNumber;
	public String questionId
	{
		get;
		
		set;
	}

	public String Message 
	{
		get
		{
			if(Message == null)
			{
				Message = '';
			}
			return Message;
		}
		set;
	}
	
	public String responseReport
	{
		get
		{
			if(responseReport == null)
			{
				responseReport = '';	
			}
			return responseReport;
		}
		set;
	}
	public String customerReport
	{
		get
		{
			if(customerReport == null)
			{
				customerReport = '';	
			}
			return customerReport;

		}
		set;
	}

	public Boolean newSurvey
	{
		get
		{
			if(newSurvey == null)
			{
				newSurvey = false;	
			}
			return newSurvey;
		}
		set;
	}

	public Boolean lockedSurvey
	{
		get
		{
			if(lockedSurvey == null)
			{
				lockedSurvey = false;	
			}
			return lockedSurvey;
		}
		set;
	}

	public Boolean closeSurvey
	{
		get
		{
			if(closeSurvey == null)
			{
				closeSurvey = false;	
			}
			return closeSurvey;
		}
		set;
	}

	public External_Survey_Question__c surveyQuestion
	{
		get
		{
			if(surveyQuestion == null)
			{
				surveyQuestion = new External_Survey_Question__c();	
			}
			return surveyQuestion;
		}
		set;

	}	

	public External_Survey_Form__c surveyForm
	{
		get
		{
			if(surveyForm == null)
			{
				surveyForm = new External_Survey_Form__c();	
			}
			return surveyForm;
		}
		set;
	}	


	//public Map<String,External_Survey_Question__c> uniqueNameToQuestion;

	public Map<String,External_Survey_Question__c> upsertQuestions; 
	public List<External_Survey_Question__c> deleteQuestions;

	public Map<String,questionWrapperClass> questionWrappers; 
	public List<questionWrapperClass> questions
	{
		get
		{
			if (questions == null)
			{
				questions = new List<questionWrapperClass>();
			}
			return questions;
		}
		set;
	}
	public ExternalSurveyConsoleController() 
	{
	}
    
    public ExternalSurveyConsoleController(ApexPages.StandardController controller)    
    {
		surveyId = ApexPages.currentPage().getParameters().get('id');
		List<External_Survey_Question__c> surveyQuestions;
		questionWrapperClass questionWrapper;
		
		upsertQuestions = new Map<String,External_Survey_Question__c>();
		questionWrappers = new Map<String,questionWrapperClass>() ; 
		
		deleteQuestions = new List<External_Survey_Question__c>();

		sequenceNumber = 0;
		
		if(surveyId == null || (surveyId.length() != 15 && surveyId.length() != 18))
		{
			newSurvey = true;
			//survey = new External_Survey_Form__c();
		}
		else
		{			
			surveyForm = [select id,Closed__c, Closed_Date__c,  CreatedBy.Name, CreatedDate,  Frequency__c, From_Email__c,  LastModifiedBy.Name, LastModifiedDate, Locked__c, Name, Owner__c, OwnerId, Requested_By__c, Template__c,Reminder_Template__c,Reminder_Subject__c,Invitation_Subject__c from External_Survey_Form__c where id =:surveyId];
			if(surveyForm != null)
			{
					if(surveyForm.Locked__c)
					{
						lockedSurvey = true;	
					}
					if(surveyForm.Closed__c)
					{
						closeSurvey = true;
					}
                	
             		//Changes made by Sandeep for merging custom metadata
					//External_Survey_metadata__mdt metadataRecord = [select id, Customer_Filter_Field__c, Customer_Report__c, Response_Filter_Field__c, Response_Report__c from External_Survey_metadata__mdt limit 1];
			
                	Map<String,String> metadataRecord = new Map<String,String>();
                    for(PSA_Common_Setting__mdt cmd : [select DeveloperName,Value__c,Name__c from PSA_Common_Setting__mdt Where type__c='External_Survey_metadata__mdt'])
                    {
                        if(cmd.Name__c != NULL && !metadataRecord.containsKey(cmd.Name__c)){
                            metadataRecord.put(cmd.Name__c, cmd.Value__c);
                        }
                        
                    }
                	
                
					if(metadataRecord != null)
					{
						//responseReport = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + metadataRecord.Response_Report__c + '?isdtp=vw&pc0=' + metadataRecord.Response_Filter_Field__c + '&pn0=eq&pv0=' + String.valueOf(surveyForm.id).substring(0, 15);
						responseReport = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + metadataRecord.get('Response_Report__c') + '?isdtp=vw&pc0=' + metadataRecord.get('Response_Filter_Field__c')  + '&pn0=eq&pv0=' + String.valueOf(surveyForm.id).substring(0, 15);
                        
						//customerReport = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + metadataRecord.Customer_Report__c + '?isdtp=vw&pc0=' + metadataRecord.Customer_Filter_Field__c + '&pn0=eq&pv0=' + String.valueOf(surveyForm.id).substring(0, 15);
                        customerReport = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + metadataRecord.get('Customer_Report__c') + '?isdtp=vw&pc0=' + metadataRecord.get('Customer_Filter_Field__c')  + '&pn0=eq&pv0=' + String.valueOf(surveyForm.id).substring(0, 15);

					}
					surveyQuestions = [select Id, Question__c,UniqueName__c,Question_Options__c,Question_Sequence__c,Question_Type__c,Required_Question__c from External_Survey_Question__c where External_Survey_Form__c = :surveyId order by Question_Sequence__c];
					if(surveyQuestions != null && !surveyQuestions.isEmpty())
					{
						for(External_Survey_Question__c question: surveyQuestions)
						{
							questionWrapper = new questionWrapperClass(question);					
							//questions.add(questionWrapper);
							questionWrappers.put(question.UniqueName__c,questionWrapper);
							if(sequenceNumber < question.Question_Sequence__c)
							{
								sequenceNumber = Integer.valueOf(question.Question_Sequence__c);
							}
						}
						questions = questionWrappers.values();
						//sequenceNumber = surveyQuestions.size();
					}
					
				}

			}
	
    }

    public void editAddQuestion()
    {
    	questionId = ApexPages.currentPage().getParameters().get('questionId');

    	if(questionWrappers.containsKey(questionId))
    	{
    		surveyQuestion = questionWrappers.get(questionId).question;	
    	}
    	else
    	{
    		surveyQuestion = new External_Survey_Question__c();
    	}
    }

    public void saveQuestion()
    {
    	message = '';
    	questionWrapperClass questionWrapper;

    	if(surveyQuestion.UniqueName__c == null)
    	{	
    		sequenceNumber++;
    		surveyQuestion.External_Survey_Form__c = surveyId;
    		surveyQuestion.UniqueName__c = GuidUtil.NewGuid(); 
    		surveyQuestion.Question_Sequence__c = sequenceNumber;		
			questionWrapper = new questionWrapperClass(surveyQuestion);					
			
    	}
    	else
    	{
    		questionWrapper = questionWrappers.get(surveyQuestion.UniqueName__c);
	    	if(surveyQuestion.Question_Type__c == 'Text')
	    	{
	    		surveyQuestion.Question_Options__c = null;	
	    	}
	    	else
	    	{
	    		
	    		questionWrapper.options = new List<SelectOption>();
				for(String option: surveyQuestion.Question_Options__c.split('\n'))
				{
					questionWrapper.options.add(new SelectOption(option,option));
				}

	    	}

    	}
    	try
    	{
    		upsert surveyQuestion;	
    	}
    	catch(Exception e)
    	{
    		message = e.getMessage();
    	}
		questionWrappers.put(surveyQuestion.UniqueName__c,questionWrapper);
		upsertQuestions.put(surveyQuestion.UniqueName__c,surveyQuestion);
    	questions = questionWrappers.values();		
    }

    public void deleteQuestion()
    {
    	message = '';
    	questionId = ApexPages.currentPage().getParameters().get('questionDeleteId');

    	surveyQuestion = questionWrappers.get(questionId).question;	
		
		if(upsertQuestions.containsKey(surveyQuestion.UniqueName__c))
		{
			upsertQuestions.remove(surveyQuestion.UniqueName__c);
		}
		questionWrappers.remove(surveyQuestion.UniqueName__c);
		if(surveyQuestion.Id != null)
		{
			try
			{
				delete surveyQuestion;
			}
			catch(Exception e)
			{
				message = e.getMessage();
			}

		}
		questions = questionWrappers.values();			
    }

    //public void saveSurveyQuestions()
    //{

    //	if(deleteQuestions != null && !deleteQuestions.isEmpty())
    //	{
    //		try
    //		{
    //			delete deleteQuestions;
    //		}
    //		catch(Exception e)
    //		{
    //			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error in deleting: ' + e.getMessage()));
    //		}
    //	}
    	
    //	if(upsertQuestions != null && !upsertQuestions.isEmpty())
    //	{
    //		try
    //		{
    			
    //			upsert upsertQuestions.values();
    //		}
    //		catch(Exception e)
    //		{
    //			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error in upsert: ' + e.getMessage()));
    //		}    		
    //	}
    //}

    public PageReference saveForm()
    {
    	Message = '';

    	PageReference pg = null;
    	Boolean isUpdate = true;
    	try
    	{
    		if(surveyForm.id == null)
    		{
    			isUpdate = false;
    		}

    		surveyForm.Owner__c = 'Customer Experience';
    		upsert surveyForm;	
    		if(!isUpdate)
    		{
			    pg = new PageReference('/apex/ExternalSurveyConsole?id='+surveyForm.id);
			    pg.setRedirect(true);
    		}		    
    		Message = 'Saved!';

    	}
    	catch(Exception e)
    	{
    		
    		//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error in upsert: ' + e.getMessage()));
    		Message = e.getMessage(); 
    	}
    	return pg;
    	
    }

    public void closeSurvey()
    {
    	if(! surveyForm.Closed__c)
    	{
    		surveyForm.Closed__c = true;
    		surveyForm.Closed_Date__c = Date.today();
    		update surveyForm;
    	}    	
    }

    public PageReference cloneSurvey()
    {
    	PageReference pg = null;
    	message = '';
    	External_Survey_Form__c newSurvey = new External_Survey_Form__c();
    	try
    	{
		    	newSurvey = surveyForm.clone(false,true,false,false);
		    	newSurvey.Closed__c = false;
		    	newSurvey.Locked__c = false;
		    	newSurvey.Closed_Date__c = null;
		    	upsert newSurvey;

		    	List<External_Survey_Question__c> newQuestions = new List<External_Survey_Question__c>();
		    	External_Survey_Question__c newQuestion;
				List<External_Survey_Question__c> questionsList = new List<External_Survey_Question__c>();
				questionsList = [Select Id, Question__c,UniqueName__c,Question_Options__c,Question_Sequence__c,Question_Type__c,Required_Question__c from External_Survey_Question__c where External_Survey_Form__c = :surveyForm.Id];

				if(questionsList != null && !questionsList.isEmpty() )
				{
					for(External_Survey_Question__c q: questionsList)
					{
						newQuestion = q.clone(false,true,false,false);
						newQuestion.External_Survey_Form__c = newSurvey.Id;
						newQuestion.UniqueName__c = GuidUtil.NewGuid();
						newQuestions.add(newQuestion);

					}
					upsert newQuestions;
				}
			    pg = new PageReference('/apex/ExternalSurveyConsole?id='+newSurvey.id);
			    pg.setRedirect(true);

    	}
    	catch(Exception e)
    	{
    		message = e.getMessage();
    	}		
		return pg;	
    }
    @remoteAction	
	public static List<Contact> queryContacts(String emails,String filterOption)
	{
		if(emails == null)
		{
			return null;
		}
		List <String> emailAddresses = new List <String>();		
		List<Contact> queriedContacts; 
		for(String option: emails.split('\n'))
		{			
			option = option.trim();
			if(!String.isBlank(option) && !(!option.contains('@') && filterOption == 'Email'))
			{
				emailAddresses.add(option);	
			}			
		}
		String query = 'select id,name, email,AKAM_Contact_ID__c from Contact where ' + filterOption + ' in :emailAddresses and HasOptedOutOfEmail = false';
		queriedContacts = Database.query(query);
		return queriedContacts;
		
	}

	@remoteAction
	public static String sendMail(List<Id> contacts,Id surveyId)
	{

		try
		{
				External_Survey_Form__c survey = [select id, Locked__c,From_Email__c,Frequency__c from External_Survey_Form__c where id=:surveyId];

				List<External_Survey_Question__c> questionsList = new List<External_Survey_Question__c>();
				questionsList = [select id from External_Survey_Question__c where External_Survey_Form__c = :surveyId];
				
				if(questionsList == null || questionsList.isEmpty())
				{
					return 'Add Questions to the Survey!';
				}

				List<External_Survey_Taken__c> takers = new List<External_Survey_Taken__c>();
				External_Survey_Taken__c surveyTaker;

				List<External_Survey_Response__c> responses = new List<External_Survey_Response__c>();
				External_Survey_Response__c response;

				Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
				Messaging.Singleemailmessage objEmail;

				for(Id contactId: contacts)
				{
					surveyTaker = new External_Survey_Taken__c();
					surveyTaker.External_Survey_Form__c = surveyId;
					surveyTaker.Contact__c = contactId;
					surveyTaker.Unique_Token__c = generateRandomString(20);
					surveyTaker.Reminder_Email_Due_Date__c = Date.today().addDays(Integer.valueOf(survey.Frequency__c)) ;
					
					surveyTaker.Dummy_due_date__c = Datetime.now().addHours(1).addMinutes(10);
					takers.add(surveyTaker);

				}	

				insert takers;

				OrgWideEmailAddress orgWideEmail = [select Id from OrgWideEmailAddress where DisplayName = :survey.From_Email__c limit 1];
				EmailTemplate template = [select  DeveloperName, Id from EmailTemplate where DeveloperName = 'External_Survey_Template' limit 1];

				for(External_Survey_Taken__c taker :takers)
				{
					for(External_Survey_Question__c question : questionsList)
					{
						response = new External_Survey_Response__c ();
						response.External_Survey_Question__c = question.id;
						response.External_Survey_Taken__c = taker.Id;				
						responses.add(response);
					}
		             objEmail = new Messaging.Singleemailmessage();
		             if(orgWideEmail != null)
		             {
		             	objEmail.setOrgWideEmailAddressId(orgWideEmail.Id);	
		             }
		             if(template != null)
		             {
		             	objEmail.setTemplateId(template.Id);	
		             }
		             
		             objEmail.setTargetObjectId(taker.Contact__c);
		             objEmail.setWhatId(taker.Id);
		             objEmail.setSaveAsActivity(false) ;
		             mailsToBeSent.add(objEmail);

				}

				insert responses;
				Messaging.sendEmail(mailsToBeSent,false);	
				if(!survey.Locked__c)
				{
					survey.Locked__c = true;
					update survey;	
				}


		}
		catch(Exception e)
		{
			return e.getMessage();
		}
				         
		return 'Survey Sent Successfully!';
	}

	public static String generateRandomString(Integer len) 
	{
    	final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    	String randStr = '';
    	while (randStr.length() < len) 
    	{
       		Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
       		randStr += chars.substring(idx, idx+1);
    	}
    	return randStr; 
	}

	public class questionWrapperClass
	{
		public External_Survey_Question__c question{get;set;}
		
		public List<SelectOption> options{get;set;}

		public String sequence{get;set;}
		public questionWrapperClass(External_Survey_Question__c questionToAdd)
		{
			question = questionToAdd;
			if(question.Question_Type__c == 'Radio' || question.Question_Type__c == 'Checkbox' || question.Question_Type__c == 'Picklist')
			{
				options = new List<SelectOption>();
				for(String option: questionToAdd.Question_Options__c.split('\n'))
				{
					options.add(new SelectOption(option,option));
				}
				sequence = '' + question.Question_Sequence__c;				
			}
		}
	}
}