/*=====================================================================================================+
    Class name                :   SC_PartnerCaseCreation_Layer 
    Author                    :   Himanshu Kar
    Created                   :   26-Mar-15
    Purpose                   :   This class provides additional Validation for Partner Email to Case Functionality
                                        
    Last Modified   Developer   Purpose            
    =============   =========   =======
    06-APR-15       Himanshu    Initial Development(CR# 2920026)
       
+=====================================================================================================*/

global class SC_PartnerCaseCreation_Layer implements Messaging.InboundEmailHandler {
                
     /* Method # 1 : Standard Method for Handling Inbound Email
        @Paramter - Messaging.inboundEmail, Messaging.InboundEnvelope
        @Return Type - Messaging.InboundEmailResult
        @Called From - Automatically Called from system
        */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        try{
        
          // Call to ValidateToADD Method
          boolean IsToAddValid = (email.toAddresses <> null) ? validateToAdd(email.toAddresses) : false;
          
          	// boolean to Check Out Of Office
        	boolean isOutOfOffice = false;
        	
        	// Condition for Checking Out Of Office Reply
        	try{
      
      		// Condition for out of Office
      		if(email.subject <> null && (email.subject.toLowerCase().contains('out of office') || 
      		email.subject.toLowerCase().contains('out of the office'))){
      
      			isOutOfOffice = true;
      		}
        	} catch(exception e){}
        
          // Setting Up the Env variable(For DR)
          Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
          
          Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
      
          // If Org is Active, then process the Logic(For DR)
          if(environmentSetup.Active_Org__c) {

            // If IsToAddValid = true and not out of Office Email, email would have come from valid adress and hence create case/update case
            if(IsToAddValid && isOutOfOffice == false){
                
                // List to store all Incoming Attachments(Text + Binary)
                List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
            
                // Calling setAttachmentEmail Method
                setAttachmentEmail(email.binaryAttachments,email.textAttachments,allAttachments);
               
                // Create Case or update case Id
                Id createdCaseId = getCaseId(email);
                
                // Create Email Message
                Id createdEmailMessageId = createEmailMessage(createdCaseId,email);
                
                // Create Attachments
                createAllAttachments(createdEmailMessageId,allAttachments);
            }
        
            result.success = true;
            return result;
          }
        }
        catch(exception e){
            
            // sending Exception Email
            sendEmailForError(e.getMessage());
        }
        
        return null;
    }
    
    // Method # 2 : Method for getting Case Id
    private Id getCaseId(Messaging.inboundEmail email){
        
        // Variable for getting Case ref Id
        String caseReferenceID = null;
        
        // Variable for getting Case Id from Case ref No
        Id CaseId = null;
        
        //Scenario-1 : looks like customer has sent email with Reference Id/Thread Id in subject
        if (email.subject != null && email.subject.contains('ref:')) {
            
            caseReferenceID = email.subject.substringBetween('ref:',':ref');
            CaseId = Cases.getCaseIdFromEmailThreadId(caseReferenceID);
            
            if (caseID != null)
            	return caseId;
        }
        
        //Scenario-2 : looks like customer has sent email with Reference Id/Thread Id in Email Body
        if (email.plaintextbody != null && email.plaintextbody.contains('ref:')) {
            
            caseReferenceID = email.plaintextbody.substringBetween('ref:',':ref');
            CaseId = Cases.getCaseIdFromEmailThreadId(caseReferenceID);
            
            if (caseID != null)
            	return caseId;
        }
        
        //Scenario-3 : take substring from starting point of F-CS or FD-CS to next space. assuming user gives space after case number
        if (email.subject != null && email.subject.contains('F-CS-')){
           
           if(email.subject.contains('F-CS-')){
           		caseID = getCaseFromAkamCasePrefix(email, 'F-CS-');
           		
           	}
           	else if(email.subject.contains('FD-CS-')){ // For DR
           	
           		caseID = getCaseFromAkamCasePrefix(email, 'FD-CS-');
           	}
           	
           	if (caseID != null)
            	return caseId;
        }
        
        //Scenario-4 : If None of the condition satisfied, then get the Delimiter from Akamai Format
        		     /*  
        		     		Format-1 : [AKAM-CASE #XXXXXX]
        		     		Format-2 : {XXXXXX}
        		     		Format-3 : Case #XXXXXX:
        		     */ 
        
        List<String> delimiters  = new List<String>{'[AKAM-CASE #','{','Case #'};
        String delimiter,endDelimiter;
        
        for(String strDelimiter : delimiters){
            
            if(email.subject.indexOfIgnoreCase(strDelimiter)!=-1){
                
                if(strDelimiter == '[AKAM-CASE #'){
                    endDelimiter = ']';  
                }
                else if(strDelimiter == '{'){
                    endDelimiter = '}';
                }
                else if(strDelimiter == 'Case #'){
                    endDelimiter = ':';
                }
                delimiter = strDelimiter;
                break;
            }   
        }
        
         try{
         	
         	if(delimiter != null) {
            	
            	// Getting Complete Akam Case Id
            	string caseNumber = EmailToCaseUtility.getCaseNumber(email.subject,delimiter,endDelimiter);
 			
 			// Getting Case Id from Query	
 			caseID = [select id from Case where AKAM_Case_ID__c = :caseNumber][0].Id;
            	
            	if (caseID != null)
            		return caseId;
            } 
         }    
         catch(Exception e){ // Exception will come if No Case is present
         } 
       
	  //If no ref id or AKAM Case Id in case subject, then create new CASE
        return createPartnerCase(email);
    }
   
   // Method # 3 : Method for Creating Case
   private Id createPartnerCase(Messaging.inboundEmail email){
   
        // Fetching RecordType ID of Emerging Products Engineering
        ID partnerRecTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Partner Portal Case').getRecordTypeId();
         
        //Contact Derivation : if we find only one contact then we will associate contact and email address
        List<Contact> contactObjectList = new List<Contact>();
        contactObjectList = [select id,accountId from contact where email = :email.fromaddress ];
        
        // Variable for Case to be created
        Case newPartnerCase = new Case();
            newPartnerCase.recordTypeId   =   partnerRecTypeID;
            newPartnerCase.subject      	=   (email.subject <> null && email.subject.length() > 255) ? email.subject.substring(0, 254) : email.subject; 
       	
       	//even if user sends html email , we still take plain text version and keep it in case body
            newPartnerCase.description  	=   (email.plainTextBody  <> null && email.plainTextBody .length() > 32000) ? email.plainTextBody.substring(0, 32000) : email.plainTextBody ;
            
            newPartnerCase.origin       	=   'Email';
            newPartnerCase.Priority     	=   'Medium';
            newPartnerCase.SuppliedEmail  =   email.fromAddress;
            newPartnerCase.SuppliedName   =   email.fromName;
       	
       	// Populate Contact and Account Value	
       	if (contactObjectList.size() == 1){
           		
           		newPartnerCase.contactId = contactObjectList.get(0).id;
                	newPartnerCase.accountId = contactObjectList.get(0).accountId;
       	}
        
        Insert newPartnerCase;
        
        return newPartnerCase.Id;
            
   }
   
   // Method # 4 : Method for Creating EmailMessage
   private Id createEmailMessage(Id parentCaseId, Messaging.inboundEmail email){
   
        // Variable for creating EmailMessage
        EmailMessage newEmailMsg = new EmailMessage();
            newEmailMsg.ParentId    =   parentCaseId;
            newEmailMsg.ToAddress   =   EmailToCaseUtility.listToString(email.toAddresses);
            newEmailMsg.CcAddress   =   EmailToCaseUtility.listToString(email.ccAddresses);
            newEmailMsg.FromAddress =   email.fromAddress;
       	newEmailMsg.FromName    =   email.fromName;
            
            newEmailMsg.textbody 	= (email.plainTextBody  <> null && email.plainTextBody .length() > 100000) ? 
            					email.plainTextBody.substring(0,99999) : email.plainTextbody;
            newEmailMsg.htmlbody 	= (email.htmlbody  <> null && email.htmlbody .length() > 100000) ? 
            					email.htmlbody.substring(0,99999) : email.htmlbody;
       		
       	newEmailMsg.Subject 	=   (email.subject <> null && email.subject.length() > 255 ? email.subject.substring(0,254) : email.subject);
            newEmailMsg.MessageDate =   System.now();
            newEmailMsg.Incoming    =   true;
        	newEmailMsg.status    	=   '0';
            
        Insert newEmailMsg;
        
        return newEmailMsg.Id;
   }
   
   // Method # 5 : Method for Creating Attachments for Email Message
   private void createAllAttachments(Id createdEmailMessageId,List<Messaging.EmailFileAttachment> allIncomingAttachments){
   
        // List to store all the Attachments to be Inserted
        List<Attachment> allAttachmentInsertForEmail = new List<Attachment>();
        
        // Attachment record Variable
        Attachment eachAttachment;
        
        //Loop for all EmailFileAttachment
        for (Messaging.EmailFileAttachment eachFileAttRec : allIncomingAttachments){
        
            eachAttachment = new Attachment();
            eachAttachment.ParentId     	=   createdEmailMessageId;  
            eachAttachment.Body     	=   eachFileAttRec.Body;
            eachAttachment.Name     	=   (eachFileAttRec.filename <> null && eachFileAttRec.filename.length() > 79) ? 
                                    		eachFileAttRec.filename.substring(0,70) + '...' : eachFileAttRec.filename;
            eachAttachment.ContentType  	=   'ContentPost';
            
            allAttachmentInsertForEmail.add(eachAttachment);
        }
        
        Insert allAttachmentInsertForEmail;
   }
   
   // Method # 6 : Method For Validating To Address 
   private boolean validateToAdd(List<string> incomingToAdd){
   
        // Set to store all Partner Email From Address values
      set<string> allPartnerEmailAdd = new set<string>();
      
      string allIncomingToAdd = 'All Emails:';
            
      boolean returnFlag = allPartnerEmailAdd.addAll(SC_SupportEmail__c.getValues('1').PartnerCaseEmail__c.split(';'));
      
      // Spliting all Incoming Addresses from Array to String
      for(string eachIncomingToAdd : incomingToAdd){
      
        allIncomingToAdd += eachIncomingToAdd + ';';
      }
      
      returnFlag = false;
      
      // Comparing the Incoming Address
      for(string eachEmailAdd : allPartnerEmailAdd){
        if( allIncomingToAdd.contains(eachEmailAdd)){
            returnFlag = true;
            break;
        }
      }
       return returnFlag;     
   }
   
   // Method # 7 : Method for setting Attachments
   private void setAttachmentEmail(Messaging.InboundEmail.BinaryAttachment[] allBinaryAttachments, 
                        Messaging.InboundEmail.TextAttachment[] allTextAttachments, 
                                List<Messaging.EmailFileAttachment> allAttachments){
   
        Messaging.EmailFileAttachment eachAttchment = new Messaging.EmailFileAttachment();

            // For all Binary Attachments
            if (allBinaryAttachments != null && allBinaryAttachments.size() > 0) {
                for(Integer i = 0; i < allBinaryAttachments.size(); i++) {
                        eachAttchment = new Messaging.EmailFileAttachment();
                        eachAttchment.setFileName(allBinaryAttachments[i].filename);
                        eachAttchment.setBody(allBinaryAttachments[i].body);
                        allAttachments.add(eachAttchment);
                }
            }
            
            // For all Text Attachments
            if (allTextAttachments != null && allTextAttachments.size() > 0) {
                for(Integer i = 0; i < allTextAttachments.size(); i++) {
                        eachAttchment = new Messaging.EmailFileAttachment();
                        eachAttchment.setFileName(allTextAttachments[i].filename);
                        eachAttchment.setBody(Blob.valueOf(allTextAttachments[i].body));
                        allAttachments.add(eachAttchment);
                }
            }
   } 
   
   // Method # 8 : Get Case Id from Akam Case Id Prefix
   private Id getCaseFromAkamCasePrefix(Messaging.inboundEmail email, string AkamCaseIdPrefix){

	// Getting 1st Index of Akam Case Id Prefix
	Integer firstIndex = email.subject.indexOf(AkamCaseIdPrefix);
	
	// Getting Index of Blank Space After Akam Case Id Prefix
	Integer secondIndex = email.subject.indexOf(' ',firstIndex);
	
	List<Case> caseList = new List<Case>();
	
	//if case Id is in end , then we might not get index.
	if (secondIndex == -1){
		secondIndex = email.subject.length();
	}
	
	// Get complete Akam Case Id
	string akamCaseId = email.subject.substring(firstIndex,secondIndex);
	
	if (akamCaseId != null && akamCaseId.trim() != null){
		
		akamCaseId = akamCaseId.trim();
		caseList = [select id from Case where AKAM_Case_ID__c = :akamCaseId];
		
		if (caseList.size() > 0){
			return caseList.get(0).id;
		}
	} 
	
	return null; 
   }
   
   // Method # 9 : Method for sending Email If any Exception is therez
   private void sendEmailForError(string errMsg){
            
            // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
            SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
            
            // Setting To Address
            String[] toAdd = new String[] {};
            toAdd.add(supEmailValues.Support_Email_AutoGen__c);
            
            // Setting Subject
            string setSubject = 'Exception: In Email Service - SC_Partner_EmailToCase';
            
            // Sending Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAdd);
            mail.subject = setSubject;
            mail.plainTextBody = 'Class Name = SC_PartnerCaseCreation_Layer\n\n' + errMsg;
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }      
   
    
}