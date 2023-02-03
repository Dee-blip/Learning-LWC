/*=====================================================================================================+
    Class name          :   SC_TaskCreation_InboundEmail
    Author              :   Vijetha V
    Created             :   28-Jul-13
    Purpose             :   This class is called from Sibel system and is used to create a Task and related Attachments under a Case.
    Last Modified       :   06-Aug-13
    Purpose             :   Initial Development
 
+=====================================================================================================*/


global class SC_TaskCreation_InboundEmail implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
        if(environmentSetup.Active_Org__c)
        {
			Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
			
			// List to store all Incoming Task Fields
			List<string> allTaskFieldList = new List<string>();
			
			//Parse the email to obtain the values of the new task
			String emailBody = email.plainTextBody.substringBetween( '$$START$$', '$$END$$');
			String activityBody = emailBody.substringBetween( '##ACTIVITY##', '##ENDACTIVITY##');
			allTaskFieldList.add(activityBody.substringBetween( 'TYPE#', '#ENDTYPE'));
			System.debug('Type is ..'+activityBody.substringBetween( 'TYPE#', '#ENDTYPE'));
			allTaskFieldList.add(activityBody.substringBetween( 'COMMENT#', '#ENDCOMMENT'));
			allTaskFieldList.add(activityBody.substringBetween( 'DESCRIPTION#', '#ENDDESCRIPTION'));
			allTaskFieldList.add(activityBody.substringBetween( 'STATUS#', '#ENDSTATUS'));
			allTaskFieldList.add(activityBody.substringBetween( 'DUE#', '#ENDDUE'));
			allTaskFieldList.add(activityBody.substringBetween( 'CASEID#', '#ENDCASEID'));
			
			try {
				//Create a new task and populate fields
				Id parentCaseID=createTask(allTaskFieldList);
							
				//List of attachments
				List<Attachment> attachmentList= new List<Attachment>();
				
				//Extract attachments, if any and create Attachment object
				if (email.textAttachments != NULL) {
				
					for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
						System.debug('..Inside for loop');
						Attachment attach = new Attachment();
						attach.Name = tAttachment.fileName;
						attach.Body = Blob.valueOf(tAttachment.body);
						attach.ParentId = parentCaseId;
						attachmentList.add(attach);
					}
				}
				
				if(attachmentList.size()>0) {
					insert attachmentList;
				}
				
				system.debug('$$Done!');
			}
			catch(Exception e) {
				system.debug('...In Exception...'+e.getMessage());
				
				SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
				  // Setting To Address
					String[] toAdd = new String[] {};
					toAdd.add(supEmailValues.Support_Email_AutoGen__c);
					String SerName = 'Email Service Name : SC_EmailService_Task Creation Charaka \n'+
						'Apex Class Name : SC_TaskCreation_InboundEmail \n'+
						'Method Name : createTask';
					
					// Setting Email Body
					string body = 'Exception: in Email service for Charaka Task Creation In Salesforce with below Details:\n' + 
									SerName + 
									'..............Original Email Body................\n' +
									emailBody + '\n..............End Of Original Email Body................\n\n' + '...........Exception Details...............\n' +
									e.getmessage();
									
					// Sending Email
					Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
						mail.setToAddresses(toAdd);
						mail.subject = 'Exception: In Email Service - Charaka Task Creation ';
						mail.plainTextBody = body;
						Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
			}
			
			result.success=true;
			return result;	
		}
		return null;
	}
    
    /*Method for creating Task
    @Paramter - List<string>
    @Return Type - Id 
    @Called From - handleInboundEmail Method
    */
    public id createTask(List<String> taskFields) {
    
        // Derivation for Case Id
        List<Case> caseRes = new List<Case>();
        if(taskFields.get(5) != NULL) {
            caseRes = [select Id,OwnerId from Case where caseNumber = :taskFields.get(5)];
        }
        
        // Fetch Default Task Owner from Custom Setting - SC_SupportEmail__c
        string getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        
        // Fetch User Id from User Alias
        List<User> userRec = new  List<User>();
        userRec = [select Id from user where alias = :getOwnerAlias limit 1];
        
        //Stores Case Owner
        String OwnerStr = caseRes[0].OwnerId;
        
        Task newTask= new Task();
        newTask.type__c         =   taskFields.get(0);
        newtask.Subject         =   taskFields.get(1);
        newTask.description     =   taskFields.get(2);
        newTask.status          =   taskFields.get(3);
        newTask.activityDate    =   (taskFields.get(4).equals('')) ? null : formatDate(taskFields.get(4));
        newTask.whatID          =   caseRes[0].Id;
        newtask.OwnerId			=  (OwnerStr.startsWith('005')) ? OwnerStr : userRec[0].Id ;
        
        //insert task
           
        insert newTask;
        System.debug('new task id..'+newTask.id);
        return newTask.id;
    }
	public Date formatDate(String sdate) {
		
		List<String> splitDate=sdate.split('/'); //index 0 - month, index 1 - date, index 2 - year
		String newDate = splitDate[2]+'-'+splitDate[0]+'-'+splitDate[1];
		Date retDate=Date.valueOf(newDate);
		return retDate;
	}
}