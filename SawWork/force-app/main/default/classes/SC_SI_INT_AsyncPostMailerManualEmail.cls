/*=====================================================================================================+
Date        : 01 Feb 2021
Purpose     : This batch Job process Post Mailer Activity - Sending Email + Mailer Contact Creation
			  - Called from SC_SI_INT_Tool_Controller
Test Class  : SC_SI_INT_Tool_Test
			
+=====================================================================================================*/


global class SC_SI_INT_AsyncPostMailerManualEmail implements Queueable {

	// Setting Error Message
    	public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                        		'Queueable Class Name = CMC_AsyncpostMailerActivityForManualEmail\n';
                                    
      // List to store all the Valid Email List from Manual Entry of Emails
    	public List<String> validEmailsList;
    	
    	// For Getting Mailer Id
    	public string getMailerId;
    	
    	// Constructer for setting the Parameters
    	Public SC_SI_INT_AsyncPostMailerManualEmail(List<String> allEmailBatch, string mailerId){
    	
    		this.validEmailsList = allEmailBatch;
    		this.getMailerId = mailerId;
    	}
    	
    	// Execute Method for Queuable Interface
      public void execute(QueueableContext context) {
    		
    		string errHdr = ' ******* ';
    	
    		try{
    		
    			processData();
    		}
    		catch(Exception e)
            {
                	errorMessage +=  errHdr + '\n' 
                                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                                + '\n' + errHdr + '\n';
                                
            	SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            	sc_COBSupportCls.senEmailForError('Exception: In Batch Job - SC_SI_INT_Tool_BatchJob', errorMessage);
                
                // Update Status With Failed
                SC_SI_INT_Tool_BatchJob asyncJob = new SC_SI_INT_Tool_BatchJob();
            	asyncJob.updateMailerFailedStatus(getMailerId,errorMessage);
            }
	}
	
	// Method for processing the Request
	public void processData(){
	
		// Query on Mailer to get the Details
		EB_AkaMailer__c mailerDetails = [select CMC_24x7_Contact_Types__c,CMC_Manual_Email_Addresses__c,CMC_Template_ID__c,
								CMC_Subject__c,EB_AdditionalIssueDescription__c 
								from EB_AkaMailer__c where Id = :getMailerId limit 1];
								
		// Getting data from Custom Metadata
		CMC_Settings__mdt cmcMetadatarec = [select Id,No_Of_ManualEmail_ASync_Operation__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
		Integer noOfRecordsToProcess = Integer.valueOf(cmcMetadatarec.No_Of_ManualEmail_ASync_Operation__c);
							
		// List to store Emails to be processed by each Batch
		List<string> emailsTobeProcessed = new List<string>();
	
        // Variable to store Loop Iterator
        Integer loopRunIterator = (validEmailsList.size() < noOfRecordsToProcess) ? validEmailsList.size() : noOfRecordsToProcess;
        
		// Loop for all incoming emails - For adding Emails
		for(Integer count = 0 ; count < loopRunIterator ; count++){
	
			emailsTobeProcessed.add(validEmailsList[count]);
		}
		
		// Loop for all incoming emails - For Removing Emails
		for(Integer count = 0 ; count < loopRunIterator ; count++){
			
			validEmailsList.remove(0);
		}
		 				
		// 1. call to sendEmailForManualEnteredEmailAdd Method
		SC_SI_INT_Tool_BatchJob asyncJob = new SC_SI_INT_Tool_BatchJob();
		asyncJob.sendEmailForManualEnteredEmailAdd(mailerDetails, emailsTobeProcessed, false);
	
		// 2. Create Mailer Contact
		asyncJob.createMailerContact(mailerDetails, emailsTobeProcessed);
		
		
		if(validEmailsList.size() !=0){
			ID jobID = System.enqueueJob(new SC_SI_INT_AsyncPostMailerManualEmail(validEmailsList,mailerDetails.Id));
			
			// Moving the Job to position 1. If exception is there, nothing to do as Job is already in process
			try{
				Boolean isSuccess = FlexQueue.moveJobToFront(jobID);
			}catch(Exception e){}
		}
		else
		{
			asyncJob.updateMailerCompleteStatus(mailerDetails.Id);
		}
				
	
	}
                                    
}