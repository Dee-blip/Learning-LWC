/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR    	DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                                       
|  14-Sep-2015      Himanshu    	2886546     Automated Process for CashApps Team.
								Called from Trigger - SC_Monacle_CaseIssue
									
|  16-Dec-2015      Himanshu    	3233511	Modified the code to handle Text Email Also.
+=====================================================================================================*/



public class SC_Billing_CashApps{

    	// Map to store the EmailMessage Id + Case Id
	public static Map<Id,Id> EmailMessageId_CaseIdMap = new Map<Id,Id>();
		
	// Map to store Case Id + List of Attachment
	public static Map<Id, List<Attachment>> caseId_AttachmentList_Map = new Map<Id, List<Attachment>>();
		
	// Final Email List to be sent
    	public static Messaging.SingleEmailMessage[] emailTobeSendList = new Messaging.SingleEmailMessage[]{};
    
    	// Map to Store Case ID + Case - Reason: We will not get Parent fields from Trigger
    	public static Map<ID, Case> incomingCaseListMap = new Map<ID, Case>();
    
    	// List to Store Case Id - Out Going Email Body
    	public static Map<ID, string> caseId_EmailBodyConstructMap = new Map<ID, string>();
    	
    	// Map to store Case Id - Subject of First Email Received
    	public static Map<ID, string> caseId_FirstIncomingEmailSubject = new Map<ID, string>();
            
	// Method for Sending Email to CashApps Team
	@future
	public static void SendEmailToCashAppsTeam(set<Id> caseIdsforCashApps){
	
		try{
		
			// Step-1 : Call Method#1 : For Case Setup
			caseSetup(caseIdsforCashApps);
		
			// Step-2 : Call Method#2 : For Creating Attachment for Original Email Message
			caseIdEmailAttachmentCal(caseIdsforCashApps);
		
			// Step-3 : Call Method#3 : For setting caseId_AttachmentList_Map
			caseIdAttachmentCal(caseIdsforCashApps);
		
			// Step-4 : Call Method#4 : Setting Up Email to be Sent
			emailSetp(false);
		
			// If any Exception is there that means File Size > 3MB. Then retry without attaching the file and Provide Links in Email Body
			try{
		
				// Step-5 : Sending Final Email
				Messaging.SendEmailResult [] r = Messaging.sendEmail(emailTobeSendList);
			}
			catch(Exception e){
		
				// Flushing the Memory
				emailTobeSendList = new Messaging.SingleEmailMessage[]{};
			
				// Step-4 : Call Method#4 : Sets Retry = true
				emailSetp(true);
		
				// Step-5 : Retry Sending  Email Again
				Messaging.SendEmailResult [] r = Messaging.sendEmail(emailTobeSendList);
			}
			finally {

				// Call the Method for Making Case Status = Closed
				closeCasebySystem();
			}
		}
		catch(Exception e){
		
			// Setting Error Message
    			string errorMessage ='Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        						'Class Name = SC_Billing_CashApps\n\n';
			errorMessage += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()+
                			'\n' + '\n\n Case Ids = ' + caseIdsforCashApps;
                                
			// Sending Mail to Sc Dev Team
			SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
        		sc_COBSupportCls.senEmailForError('Exception: In Automated Billing CashApps Process', errorMessage);

		}
		
	}
	
	// Method-1 : For Case Setup
	public static void caseSetup(set<Id> caseIdsforCashApps){
	
		for (Case eachCase : [select Id,Account.Name,AccountId from Case where Id In :caseIdsforCashApps]){
			
			incomingCaseListMap.put(eachCase.ID, eachCase);
		}
	}
	
	// Method-2 : For Setting Original Incoming Email as an Attachment
	public static void caseIdEmailAttachmentCal(set<Id> caseIdsforCashApps){
	
		// Creating key for Case Id
		string caseIdKey;
		
		// Attachment List Variable
		List<Attachment> attList;
		
		// Attachment Variable(For Converting Each Email to Attachment)
		Attachment emailASAttachment;
		
		// Variable to Set Account and Email Links
		string setEmailBodyForAccount_EmailLink;
		
		// Setting EmailMessageId_CaseIdMap, caseId_EmailBodyConstructMap
		for(EmailMessage eachIncomingEmail : [select Id,htmlbody,ParentId,MessageDate,FromAddress,FromName,Subject,textbody 
											  from EmailMessage 
											  where Incoming = true and 
											  ParentId In :caseIdsforCashApps 
											  order by MessageDate ASC]){
			
			setEmailBodyForAccount_EmailLink = null;
			
			EmailMessageId_CaseIdMap.put(eachIncomingEmail.Id, eachIncomingEmail.ParentId);
			
			// Setting caseId_FirstIncomingEmailSubject Map
			if(caseId_FirstIncomingEmailSubject.get(eachIncomingEmail.ParentId) == null)	{
			
				caseId_FirstIncomingEmailSubject.put(eachIncomingEmail.ParentId, eachIncomingEmail.Subject);
			}
			
			// Setting Map Key(Case Id)
			caseIdKey = eachIncomingEmail.ParentId;	
			
			// Create Attachment for Incoming Email
			emailASAttachment = new Attachment();
			emailASAttachment.Name = 'Original Email-'+ eachIncomingEmail.MessageDate + '.html';
			emailASAttachment.Body =  (eachIncomingEmail.textbody != null) ? Blob.valueOf(eachIncomingEmail.textbody) : null;
			
			if(caseId_AttachmentList_Map.get(caseIdKey) == null){
			
				attList = new List<Attachment>();
				attList.add(emailASAttachment);
				caseId_AttachmentList_Map.put(caseIdKey, attList);
				
				// Setting Link for Account
				//setEmailBodyForAccount_EmailLink = 'Please Click the Below Link to View Customer : \n';
				//setEmailBodyForAccount_EmailLink += URL.getSalesforceBaseUrl().toExternalForm() + '/'+ 
				//									incomingCaseListMap.get(caseIdKey).AccountId + '\n\n';
				
				// Setting Link for Case									
				setEmailBodyForAccount_EmailLink = 'Please Click the Below Link to View Case : \n';
				setEmailBodyForAccount_EmailLink += URL.getSalesforceBaseUrl().toExternalForm() + '/'+ eachIncomingEmail.ParentId +
													'\n\n';
				
				// Setting Link for Email Message									
				setEmailBodyForAccount_EmailLink += 'Please Click the Below Link to View Original Email: \n';
				setEmailBodyForAccount_EmailLink += URL.getSalesforceBaseUrl().toExternalForm() + '/'+ 	eachIncomingEmail.Id;
				setEmailBodyForAccount_EmailLink += '     From Address : '+ eachIncomingEmail.FromAddress;
					
				caseId_EmailBodyConstructMap.put(caseIdKey,setEmailBodyForAccount_EmailLink);							
			}
			else
			{
				attList = caseId_AttachmentList_Map.get(caseIdKey);
				attList.add(emailASAttachment);
				caseId_AttachmentList_Map.put(caseIdKey, attList);
				
				setEmailBodyForAccount_EmailLink = caseId_EmailBodyConstructMap.get(caseIdKey);
				setEmailBodyForAccount_EmailLink += '\n' + URL.getSalesforceBaseUrl().toExternalForm() + '/'+ 	eachIncomingEmail.Id;
				setEmailBodyForAccount_EmailLink += '     From Address : '+ eachIncomingEmail.FromAddress;
				
				caseId_EmailBodyConstructMap.put(caseIdKey,setEmailBodyForAccount_EmailLink);
			}
									  
		} // End Of Loop
	}
	
	// Method-2 for Retrieving all the Attachments for Email Message for Parent Case
	public static void caseIdAttachmentCal(set<Id> caseIdsforCashApps){
	
		// Creating key for Case Id
		string caseIdKey;
		
		// Attachment List Variable
		List<Attachment> attList;
		
		for(Attachment eachAttachment : [select Id,body,BodyLength,Name,ParentId from Attachment where 
										parentId In (select id from EmailMessage where parentid In : caseIdsforCashApps) ]){
			
			caseIdKey = EmailMessageId_CaseIdMap.get(eachAttachment.ParentId);
			
			if(caseId_AttachmentList_Map.get(caseIdKey) == null){
			
				attList = new List<Attachment>();
				attList.add(eachAttachment);
				caseId_AttachmentList_Map.put(caseIdKey, attList);
			}
			else
			{
				attList = caseId_AttachmentList_Map.get(caseIdKey);
				attList.add(eachAttachment);
				caseId_AttachmentList_Map.put(caseIdKey, attList);
			}
										
		} // End of For Loop
	}
	
	// Method to Setup the Single Email Message
	public static void emailSetp(boolean retry){
	
		// For Setting Attachments
		Messaging.EmailFileAttachment[] AllAttchmentForCase;
		Messaging.EmailFileAttachment eachFileAttachment;
		
		// Instantiating Each Email Per Each Case
		Messaging.SingleEmailMessage eachEmail;
        
		// Setting To Address
		String[] toAddresses = new list<string> {SC_SupportEmail__c.getValues('1').CashAppsEmail__c};
		
		// Setting EmailBody
		string emailBody = (retry == false) ? 'Please Click on the Below Links for more references :\n\n' :
								'There is some Error with the Attachments.Please Click on the Below Links for more references :\n\n';
		
		// Loop for each Case
		for(Id eachCaseId : caseId_EmailBodyConstructMap.keySet()){
		
            	AllAttchmentForCase = new Messaging.EmailFileAttachment[]{};
            
			// Getting all the Attachment for the Case
            	if(caseId_AttachmentList_Map.get(eachCaseId) <> null){
                    
				for(Attachment eachAttachment : caseId_AttachmentList_Map.get(eachCaseId) ){
			  
				  eachFileAttachment = new Messaging.EmailFileAttachment();
				  eachFileAttachment.setFileName(eachAttachment.Name);
				  eachFileAttachment.setBody(eachAttachment.Body);
				  AllAttchmentForCase.add(eachFileAttachment);  
			  
				}
             	}
			
			eachEmail = new Messaging.SingleEmailMessage();
			eachEmail.setSubject(caseId_FirstIncomingEmailSubject.get(eachCaseId));
        		eachEmail.setToAddresses( toAddresses );
        		eachEmail.setPlainTextBody(emailBody + caseId_EmailBodyConstructMap.get(eachCaseId));
        	
        		// Add Attachments to Outgoing Email if any Attachment is there and retry=false
            	if(AllAttchmentForCase.size() > 0 && retry == false)
            		eachEmail.setFileAttachments(AllAttchmentForCase);
        	
        		emailTobeSendList.add(eachEmail);
			
		} // End of For Loop
	
	}
	
	// Method to Setup the Single Email Message
	public static void closeCasebySystem(){
	
		// List to store Cases for Update the Case Status
		List<Case> caseListToUpdate = new List<Case>();
		
		// Record Variable for Loop
		Case eachCaseRec;
		
		for(Id eachIncomingCaseRecId : incomingCaseListMap.keyset()){
		
			eachCaseRec = new case(Id=eachIncomingCaseRecId, status = 'Closed-Auto', Validation_Override__c = true);
			caseListToUpdate.add(eachCaseRec);
		}
		
		// Updating the Cases
		update caseListToUpdate;
	}
	
}