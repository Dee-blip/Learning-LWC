/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR          DESCRIPTION                               

|  ===========      =========       =======         =========== 
                                                       
|  16-APR-2017      Himanshu Kar    3634021(17.4)    This batch Job process Post Mailer Activity
									- Sending Email + Mailer Contact Creation
|									- Called from CMC_postMailerActivityBatchJob (Apex Class)
									(Total# Methods - 28)				
|-----------------------------------------------------------------------------------------------------
   15-May-2017		Vamsee S		ESESP-587(17.5.1) Including Default Account's contact for sending 
|									email (Manual entered email scenario)

|  24-Aug-2018		Vamsee S 		ESESP-1543(18.9) Associate Mailer Contacts to Default account when 
									Original Account is not present.
|  07-Dec-2020      Vamsee S		ESESP-3817(21.1) Service Incident Lightning Migration

|  04-Aug-2021		Sheena			ESESP-5709(21.8) Code Optimization
+=====================================================================================================*/


global class CMC_postMailerActivityBatchJob implements Database.Batchable<SObject>, Database.stateful {

    
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                        		'Class Name = CMC_postMailerActivityBatchJob\n' + 
                                    'Method Name = processingLayer\n';
                                    
    public string errHdr = ' ******* ';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    
    //Normal Execution Query for Contact
    public String batchQuery = Null;
    
    //Test Class Query
    public String TestClass_Query ; 
    
    // Variable for Batch class
    public boolean isSynchronousCall;
    public string setMailerIdforBatch; 
    public boolean setTotalRecordsBatch = false;
    public integer totalRecordsBatch;
    
    // Map for Contact Id and Name
    Map<String,String> mConIdConName = new Map<String,String>();
    
    // Method-1 : Default Constructor
    Public CMC_postMailerActivityBatchJob(){
    	
    }
    
    
    // Method-2 : Constructor of Batch Class
    Public CMC_postMailerActivityBatchJob(string contactQuery, boolean isSynchronousCallParam, string mailerId){
    
            // Initializing the values
            System.debug('--Start of postMailerActivity --');
            this.batchQuery = contactQuery;
            this.isSynchronousCall = isSynchronousCallParam;
            this.setMailerIdforBatch = mailerId; 
            this.totalRecordsBatch = 0;
                       
            this.TestClass_Query = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ' + ' order by Createddate Limit 10';            
            
    }
   
      
    /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
   global Database.QueryLocator start(Database.BatchableContext BC){
       
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : batchQuery;
        
        return Database.getQueryLocator(batchQuery);
   }
   
   global void execute(Database.BatchableContext BC, list<SObject> scope){
   
        // List to store all Incoming Contract Header
        List<Contact> allIncomingContactData = new List<Contact>();
        allIncomingContactData = (Contact[]) scope ;
        totalRecordsBatch += allIncomingContactData.size();
        
        try{  
        		// 1. Should be invoked only once (To set Initial Count with Status on Mailer)
        		if(isSynchronousCall == false && setTotalRecordsBatch == false)
        			UpdateMailerwithTotalBatchCount(BC.getJobId(),setMailerIdforBatch);
        		system.debug('---batch execute---');
        		// 2. For Processing	
        		processAllIncomingContacts(allIncomingContactData);
        		
        		// 3. Update Mailer with no of records processed
        		if(isSynchronousCall == false)
        			UpdateMailerwithIncrementalCount(setMailerIdforBatch, totalRecordsBatch);
        		
        }
        catch(Exception e)
            {
                noOfErrors += 1;
                errorMessage += 'Mailer Id = '+ setMailerIdforBatch;
                errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                                + '\n' + errHdr + '\n';
            }
        
            
     }
     
      global void finish(Database.BatchableContext BC){
      
        string setEmailSub = 'Exception: In Batch Job - CMC_postMailerActivityBatchJob. # Of Errors : '+noOfErrors;
       
       	
          // Calling Send Email Method for Errors
         if(noOfErrors > 0){
            
            // Send Email
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
            
            // Update Status With Failed
            updateMailerFailedStatus(setMailerIdforBatch, errorMessage);
         }
         else
         {
         	// Update Status With Complete
         	updateMailerCompleteStatus(setMailerIdforBatch);
         }
       
        
      }
      
      
      
// Method-3 : For - Post MailerActivity (Sending Email + Update Mailer Contact)
public void postMailerActivity(string mailerId){
    
    System.debug('---Inside postMailerActivity Method---');
	// Step-1: Updating Mailer Status to In-Process
	updateMailerInprogressStatus(mailerId);
	
	// Query on Mailer to get the Details
	EB_AkaMailer__c mailerDetails = [select Id, CMC_24x7_Contact_Types__c,CMC_Manual_Email_Addresses__c,CMC_Template_ID__c,CMC_Subject__c,CMC_All_Customers__c,
							EB_AdditionalIssueDescription__c,AuthCon_Authorized_Contacts__c,AuthCon_Emergency_Notification_Recipient__c,AuthCon_Maint_Notification_Recipient__c,
                            (Select CMC_Filter_Condition__c,CMC_Filter_Field__c,CMC_Filter_Order__c,CMC_Filter_Value__c from CMC_Mailer_Filters__r)
							from EB_AkaMailer__c where Id = :mailerId limit 1];
	// List to store all the Contacts 
	List<contact> contactList = new List<contact>();
	
	// Map to store Contact Email + Status
	Map<string, string> contactEmail_StatusMap = new Map<string, string>();
	
	
	try{	
    		
    		// Step-2: For Checking Filter Criteria Contact or Manually Entered Email Address processing
    		if(mailerDetails.CMC_24x7_Contact_Types__c == true || mailerDetails.AuthCon_Authorized_Contacts__c == true){
	
				// Call to AccountFilteredProcess Method
				System.debug('---AccountFilteredProcess---');
				AccountFilteredProcess(mailerDetails);
			}
			else
			{
				// Call to manualEnteredEmailProcess method
				manualEnteredEmailProcess(mailerDetails);
			}
	}
	catch(Exception e)
	{
		errorMessage += '..Mailer Id = '+ setMailerIdforBatch;
		errorMessage +=  errHdr + '\n' 
				  + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
				  + '\n' + errHdr + '\n';
				  
		SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
		sc_COBSupportCls.senEmailForError('Exception: In Batch Job - CMC_postMailerActivityBatchJob', errorMessage);
		
		// Update Status With Failed
        updateMailerFailedStatus(mailerId, errorMessage);
	}
	
}

// Method-4: for - Manually Entered Email Address processing
public void manualEnteredEmailProcess(EB_AkaMailer__c mailerDetails){

	// List to store all the Valid Email List from Manual Entry of Emails
	List<String> validEmailsList = new List<String>();
	
	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,No_Of_ManualEmail_Sync_Operation__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
	Integer noOfRecordsToProcess = Integer.valueOf(cmcMetadatarec.No_Of_ManualEmail_Sync_Operation__c); // 9000
			
	//Get the valid Email address list
	validEmailsList = CMC_MailerHelper.ValidateEmailAddresses(mailerDetails.CMC_Manual_Email_Addresses__c, mailerDetails.Id, True);
	
	// Get count of Default Contact
	Integer getCountDefaultContact = countMailerContactForDefaultAccount(mailerDetails.Id);
		
	// If the Email List is < 9000, then process it synchronously else asynchronously
	if(validEmailsList.size() > 0){
		
		// Step-1 : Update Mailer Status with Count
		updateMailerTotalCountSyncOp(mailerDetails,validEmailsList.size() + getCountDefaultContact);
	
		// Step-2 : Creating and sending emails to Default Account's Contacts
		processMailerContactForDefaultAccount(mailerDetails);
        
			
		if(validEmailsList.size() <= noOfRecordsToProcess){
		
			// Call to synchronousManualEnteredEmailProcess method
			synchronousManualEnteredEmailProcess(mailerDetails,validEmailsList);
		}
		else
		{
			// Call to Queueable Interface
			ID jobID = System.enqueueJob(new CMC_AsyncpostMailerActivtyManualEmail(validEmailsList,mailerDetails.Id));
			
			try{
			
				Boolean isSuccess = FlexQueue.moveJobToFront(jobID);
			}catch(Exception e){}
        }
	}
	else
	{
		// 3. Update Mailer Status on Complete
		updateMailerCompleteStatus(mailerDetails.Id);
	}
}

 // Method-5 : for - Manually Entered Email Address processing - Synchronous
 // Sending Email + creation of Mailer Contact
public void synchronousManualEnteredEmailProcess(EB_AkaMailer__c mailerDetails, List<string> emailsForProcess){

	// 1. call to SendEmailForManualEnteredEmailAdd Method
	SendEmailForManualEnteredEmailAdd(mailerDetails,emailsForProcess, false);
	
	// 2. Create Mailer Contact
	CreateMailerContact(mailerDetails,emailsForProcess);
	
	// 3. Update Mailer Status on Complete
	updateMailerCompleteStatus(mailerDetails.Id);

} 

// Method-6 : for - sending Email(MassEmail Message)
// It is invoked when template is selected
public void SendEmailForManualEnteredEmailAdd(EB_AkaMailer__c mailerDetails, List<string> emailsForProcess, boolean forDefaultAccountContacts){

	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,CMC_Default_Contact_Id__c,Default_From_Email_Address__c from 
							CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
	string defaultContactId = cmcMetadatarec.CMC_Default_Contact_Id__c; // F-CO-2650731
	 
	// Getting Related Contact Id
	Contact conRec = [select Id from contact where AKAM_Contact_ID__c = :defaultContactId limit 1];
		
	// Map to store Batch No + Each 25 Emails
	Map<string, List<string>> batchno_each25EmailMap = new Map<string, List<string>>();
	string key;
	List<string> each25Emails;
	
	// Loop for All the incoming Emails for designing the Map
	for(integer count=0; count < emailsForProcess.size(); count++){

		key = 'Batch-'+ (count/25);
	
		if(batchno_each25EmailMap.get(key) == null){
	
			each25Emails = new List<string>();
		}
		else
		{
			each25Emails = batchno_each25EmailMap.get(key);
		}
	
		each25Emails.add(emailsForProcess[count]);
		batchno_each25EmailMap.put(key,each25Emails);
	}
	
	// For sending Email
	List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
	Messaging.SingleEmailMessage eachBatchEmail;
	
	// Loop for each Batch of Email
	for(string eachBatch : batchno_each25EmailMap.keyset()){

		eachBatchEmail = new Messaging.SingleEmailMessage();
		
		eachBatchEmail.setBccAddresses(batchno_each25EmailMap.get(eachBatch));
		eachBatchEmail.setOrgWideEmailAddressId(cmcMetadatarec.Default_From_Email_Address__c);
		eachBatchEmail.saveAsActivity = false;
		eachBatchEmail.setUseSignature(false); 
		eachBatchEmail.setSaveAsActivity(false);	
		
		if(mailerDetails.CMC_Template_ID__c != null){
		
			eachBatchEmail.setTemplateId(mailerDetails.CMC_Template_ID__c);
			eachBatchEmail.setTargetObjectId(conRec.Id);
			eachBatchEmail.setWhatId(mailerDetails.Id);	
			
		}
		else
		{
			eachBatchEmail.subject = mailerDetails.CMC_Subject__c;
            	eachBatchEmail.HtmlBody = mailerDetails.EB_AdditionalIssueDescription__c;
		}
		emailList.add(eachBatchEmail);
	
	}
	
	// send Email
	Messaging.SendEmail(emailList);
	
    //No need to update the status if mails is being sent for default account's contacts or 
    //Email is being processed in batch class
	if(!(system.isBatch() || forDefaultAccountContacts)){
		// Updating Mailer Status = Email Sent - Contact Processing
		updateMailerStatusAfterEmailSent(mailerDetails.Id);
	}

}  

// Method-7 : for - Creating Mailer Contact
public void CreateMailerContact(EB_AkaMailer__c mailerDetails, List<string> emailsForProcess){

	// List to store all Mailer Contact for Insert
	List<EB_AkaMContact__c> allMailerContactListInsert = new List<EB_AkaMContact__c>();
	EB_AkaMContact__c eachMailerContact;
	
	// Step-1: get the Default Akamai - Internal Account
	EB_AkaMAccount__c getDefaultAccount = [select Id from EB_AkaMAccount__c where EB_AkaMailer__c = :mailerDetails.Id limit 1];
	
	// Step-2 : Loop for each Email
	for(string eachEmail : emailsForProcess){
	
		eachMailerContact = new EB_AkaMContact__c();
		eachMailerContact.EB_AkaMAccount__c = getDefaultAccount.Id;
		eachMailerContact.CMC_Email_Address__c	= eachEmail;
		eachMailerContact.EB_Status__c = 'Processed';
		eachMailerContact.CMC_Contact_ExternalId__c = mailerDetails.Id + '-' + eachEmail;
		
		allMailerContactListInsert.add(eachMailerContact);
	}
	
	if(allMailerContactListInsert.size() > 0)
		Upsert allMailerContactListInsert CMC_Contact_ExternalId__c;
}  

// Method-8 : for - AccountFiltered contact processing
public void AccountFilteredProcess(EB_AkaMailer__c mailerDetails){
	
	// List to store all the Contacts 
	List<contact> contactList = new List<contact>();
	
	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,No_Of_Contact_Sync_Operation__c,No_Of_Contact_ASync_Operation__c from CMC_Settings__mdt 
							where MasterLabel = 'CMC' limit 1];
	Integer noOfRecordsToProcessSyncOp = Integer.valueOf(cmcMetadatarec.No_Of_Contact_Sync_Operation__c); // 49000
	Integer noOfRecordsToProcessASyncOp = Integer.valueOf(cmcMetadatarec.No_Of_Contact_ASync_Operation__c); // 2000
	Integer totalContacts;		
	
	// 1. Get count of Default Contact
	//Integer getCountDefaultContact = countMailerContactForDefaultAccount(mailerDetails.Id);
	
    // 2. Variable to store Contact Query
    string contactQuery;
    // Wrapper For getting SOCC data
    Contactwrapper conWrapper = new Contactwrapper();
    // Contacts list with valid emails
    List<Contact> validContactsList = new List<Contact>();
    //Contacts list with bounced emails
    List<Contact> bouncedContactsList = new List<Contact>();
    // Wrapper for getting bounced and valid contacts for 24*7 Contact Types
    FilterContactsWrapper filterConWrap = new FilterContactsWrapper();
    
    if(mailerDetails.CMC_24x7_Contact_Types__c == true){
        contactQuery = getcontactQuery(mailerDetails.Id);
        contactList = Database.Query(contactQuery);
        totalContacts=contactList.size();
        filterConWrap = calculateFilterContacts(contactList);
        validContactsList = filterConWrap.validContactsList;
        bouncedContactsList = filterConWrap.bouncedContactsList;
    }
    else if(mailerDetails.AuthCon_Authorized_Contacts__c == true){
        conWrapper = getcontactQueryforSOCC(mailerDetails);
        validContactsList =  conWrapper.validContactsList;
        bouncedContactsList =  conWrapper.bouncedContactsList;
        totalContacts = conWrapper.totalContactsCount;
        contactQuery = conWrapper.contactQuery;
    }
	
	// Step-2: Checking contact Size for deciding Synchronous or Async operation
	// if size = 49000, then invoke Async operation else send Email immediately and then invoke Async operation for Mailer Contact creation
	if(totalContacts < noOfRecordsToProcessSyncOp){
                
        	updateMailerTotalCountSyncOp(mailerDetails, totalContacts);
        	
			// Initiate Sync Transactions
			system.debug('---initiateSyncOperationForAccountProcess---');
			initiateSyncOperationForAccountProcess(validContactsList,bouncedContactsList,mailerDetails,contactQuery);
	}
	else
	{
        	
			CMC_postMailerActivityBatchJob asyncJob= new CMC_postMailerActivityBatchJob(contactQuery, false, mailerDetails.Id);
			Id jobID = Database.executeBatch(asyncJob,noOfRecordsToProcessASyncOp);
		
			try{
					// Moving the Job to 1st Position on Flex Queue
					Boolean isSuccess = FlexQueue.moveJobToFront(jobID);
			}catch(Exception e){}
	}

}

// Method-9 : for - Contact Query
public string getcontactQuery(Id mailerId){

	// Variable to store Contact Query ... will make dynamic later
	string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Contact_Type__c includes (' + '\'Technical Primary - 24X7\',' +  
					'\'Tech Secondary - 24X7\') and Email != null ' ;
	
	// string to store Limit clause
	string limitClause = ' Limit 49000';
	
	contactQuery += 'and AccountId IN (SELECT EB_Account__c FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c = ' + '\''+ mailerId + '\')' 
				 + limitClause;
	
	return contactQuery;
}

//Method-9.1 : return contact query for SOCC
    public Contactwrapper getcontactQueryforSOCC(EB_AkaMailer__c mailer){
        // Variable to store Authorized query
        string authorizedContactQuery = 'Select Id, Contact_Name__c,Contact_Name__r.IsEmailBounced, Contact_Name__r.Email, Contact_Name__r.Name, Contact_Name__r.AccountId, Contact_Name__r.AKAM_Contact_ID__c, Contact_Name__r.Account.AKAM_Account_ID__c, Contact_Name__r.SMS_Notifications__c from Authorized_Contact__c where ';
        if(mailer.AuthCon_Emergency_Notification_Recipient__c == true)
            authorizedContactQuery += 'Emergency_Email__c = true ';
        else if(mailer.AuthCon_Maint_Notification_Recipient__c == true)
            authorizedContactQuery += 'Maintenance_Email__c = true ';
        
        authorizedContactQuery += ' AND Contact_Name__c != null AND Contact_Name__r.Email != null ';

        String values;
        for(CMC_Mailer_Filter__c eachFilter: mailer.CMC_Mailer_Filters__r){
            if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name' && eachFilter.CMC_Filter_Condition__c != 'Not Equal To'){
                if(!String.isBlank(eachFilter.CMC_Filter_Value__c)){
                    values = CMC_MailerHelper.splitString(eachFilter.CMC_Filter_Value__c);
                }else{
                    List<Attachment> attachmentList = [Select Body from Attachment where ParentId =:eachFilter.Id Limit 1];
                    if(attachmentList.size() == 1){
                        values = CMC_MailerHelper.splitString(attachmentList[0].Body.toString());
                    }
                }
            }
        }
        if(!String.isBlank(values))
        	authorizedContactQuery += 'AND (Product_Interests__c includes (' +values+ ') OR Product_Interests__c = \'All\')';
        
        authorizedContactQuery += 'AND Policy_Domain__c IN (Select Policy_Domain__c from Mailer_Acc_Policy_Domain_Association__c where Mailer__c = \'' + mailer.Id +'\') Limit 49000';

        String lConId = '';
        
        // Valid Contacts List 
        List<Contact> validContactsList = new List<Contact>();
        // Bounced Contacts List
        List<Contact> bouncedContactsList = new List<Contact>();
        // All Contact Ids
        Set<Id> totalContactIds = new Set<Id>();
        Contact con;
        
        for(Authorized_Contact__c eachrec : Database.Query(authorizedContactQuery)){
            if(eachrec.Contact_Name__c != null  && !totalContactIds.contains(eachrec.Contact_Name__c)){
                lConId += '\''+eachrec.Contact_Name__c + '\',';
                totalContactIds.add(eachrec.Contact_Name__c);
                
                if(!eachrec.Contact_Name__r.IsEmailBounced){
                    
                    con = new Contact();
                    con.Id = eachrec.Contact_Name__c;
                    con.Email = eachrec.Contact_Name__r.Email;
                    con.Account = eachrec.Contact_Name__r.Account;
                    con.AccountId = eachrec.Contact_Name__r.AccountId;
                    con.Account.AKAM_Account_ID__c = eachrec.Contact_Name__r.Account.AKAM_Account_ID__c;
                    con.AKAM_Contact_ID__c = eachrec.Contact_Name__r.AKAM_Contact_ID__c;
                    con.SMS_Notifications__c = eachrec.Contact_Name__r.SMS_Notifications__c;
                    validContactsList.add(con);
                    
                    // Map to get the Contact Name from the Contact Id as Name is not writable;
                    mConIdConName.put(eachrec.Contact_Name__c,eachrec.Contact_Name__r.Name);
                    
                }
                
                else if(eachrec.Contact_Name__r.IsEmailBounced){
                    
                    con = new Contact();
                    con.Id = eachrec.Contact_Name__c;
                    con.Email = eachrec.Contact_Name__r.Email;
                    con.Account = eachrec.Contact_Name__r.Account;
                    con.AccountId = eachrec.Contact_Name__r.AccountId;
                    con.Account.AKAM_Account_ID__c = eachrec.Contact_Name__r.Account.AKAM_Account_ID__c;
                    con.AKAM_Contact_ID__c = eachrec.Contact_Name__r.AKAM_Contact_ID__c;
                    con.SMS_Notifications__c = eachrec.Contact_Name__r.SMS_Notifications__c;
                    bouncedContactsList.add(con);
                    
                    // Map to get the Contact Name from the Contact Id as Name is not writable;
                    mConIdConName.put(eachrec.Contact_Name__c,eachrec.Contact_Name__r.Name);
                }
            }
        }
        
        lConId = lConId.removeEnd(',');

        //Generating query for Contacts
        string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ' ;
        if(!String.isBlank(lConId))
        	contactQuery += 'AND Id in (' + lConId + ')';
        else
            contactQuery += 'AND Id = null';
        contactQuery += ' Limit 49000';
        
        Contactwrapper conWrap = new Contactwrapper();
        conWrap.totalContactsCount = totalContactIds.size();
        conWrap.validContactsList = validContactsList;
        conWrap.bouncedContactsList = bouncedContactsList;
        conWrap.contactQuery=contactQuery;
        
        return conWrap;
    }

    Public class Contactwrapper{
        List<Contact> validContactsList;
        List<Contact> bouncedContactsList;
        Integer totalContactsCount;
        String contactQuery;
    }

	// Commenting the methods to get the count of Contacts 

/* // Method-10 : For getting No Of Contacts
	public Integer getTotalContacts(Id mailerId){
	
	// Variable to store No Of Contacts
	integer count;
	
	// Variable to store Contact Query 
	string contactQuery = 'select count() from Contact where Contact_Type__c includes (' + '\'Technical Primary - 24X7\',' +  
					'\'Tech Secondary - 24X7\') and Email != null ' ;
	contactQuery += 'and AccountId IN (SELECT EB_Account__c FROM EB_AkaMAccount__c WHERE EB_AkaMailer__c = ' + '\''+ mailerId + '\')' ; 
	
	
	count = database.countQuery(contactQuery);
	
	return count;
}

// Method-10.1 : For getting No Of Contacts for SOCC
public Integer getTotalContactsForSOCC(EB_AkaMailer__c mailer){
    Integer count;
	// Variable to store Authorized query
        string authorizedContactQuery = 'Select Id, Contact_Name__c from Authorized_Contact__c where ';
        if(mailer.AuthCon_Emergency_Notification_Recipient__c == true)
            authorizedContactQuery += 'Emergency_Email__c = true ';
        else if(mailer.AuthCon_Maint_Notification_Recipient__c == true)
            authorizedContactQuery += 'Maintenance_Email__c = true ';
        
        authorizedContactQuery += ' AND Contact_Name__c != null AND Contact_Name__r.Email != null ';

        String values;
        for(CMC_Mailer_Filter__c eachFilter: mailer.CMC_Mailer_Filters__r){
            if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name' && eachFilter.CMC_Filter_Condition__c != 'Not Equal To'){
                if(!String.isBlank(eachFilter.CMC_Filter_Value__c)){
                    values = CMC_MailerHelper.splitString(eachFilter.CMC_Filter_Value__c);
                }else{
                    List<Attachment> attachmentList = [Select Body from Attachment where ParentId =:eachFilter.Id Limit 1];
                    if(attachmentList.size() == 1){
                        values = CMC_MailerHelper.splitString(attachmentList[0].Body.toString());
                    }
                }
            }
        }
        if(!String.isBlank(values))
        	authorizedContactQuery += 'AND (Product_Interests__c includes (' +values+ ') OR Product_Interests__c = \'All\')';
        
        authorizedContactQuery += 'AND Policy_Domain__c IN (Select Policy_Domain__c from Mailer_Acc_Policy_Domain_Association__c where Mailer__c = \'' + mailer.Id +'\') Limit 49000';

        String lConId = '';
        for(Authorized_Contact__c eachrec : Database.Query(authorizedContactQuery)){
            if(eachrec.Contact_Name__c != null)
            	lConId += '\''+eachrec.Contact_Name__c + '\',';
        }
        lConId = lConId.removeEnd(',');

        //Generating query for Contacts
        string contactQuery = 'select count() from Contact where Email != null ' ;
        if(!String.isBlank(lConId))
        	contactQuery += 'AND Id in (' + lConId + ')';
        else
            contactQuery += 'AND Id = null';
        contactQuery += ' Limit 49000';
    
    	count = database.countQuery(contactQuery);
    	return count; 
}*/

// Method-11 : for - Processing all the Contacts from Execute Method of Batch
public boolean processAllIncomingContacts(List<Contact> allIncomingContactData){

	// List to store all Filtered Contacts
	List<Contact> returnFilterContacts = new List<Contact>();
	
	// List to store all Filtered Contacts
	List<Contact> returnBouncedContacts = new List<Contact>();
	
	// List to store all Filtered Contacts
	List<Contact> returnFilterContactsPostMail = new List<Contact>();
	
	// bolean to store whether Email Has been sent successfully or not
	boolean isSuccessEmail;
	
	// Query on Mailer to get the Details
	EB_AkaMailer__c mailerDetails = [select CMC_24x7_Contact_Types__c,CMC_Manual_Email_Addresses__c,CMC_Template_ID__c,EB_Type__c,
							CMC_Subject__c,EB_AdditionalIssueDescription__c 
							from EB_AkaMailer__c where Id = :setMailerIdforBatch limit 1];
	
	// If it is Sync call, then do not process contacts else process it.
	if(isSynchronousCall == false){
	
		// Step 1: Calculate FilterContacts and Bounced Contacts
		FilterContactsWrapper filterConWrap =  new FilterContactsWrapper();
        filterConWrap = calculateFilterContacts(allIncomingContactData);
		returnFilterContacts = filterConWrap.validContactsList;
		returnBouncedContacts = filterConWrap.bouncedContactsList;
	
		// Step 2: Process Bounced Contacts before sending Email(Inserting to Mailer Exception)
		if(returnBouncedContacts.size() > 0 )
			processBouncedContacts(returnBouncedContacts, 'Already Bounced - Before Mail', setMailerIdforBatch,false);
	
		// Step 3 : Call to sendEmail Method for sending Email
		System.debug('---EB_Type__c processAllIncomingContacts---'+ mailerDetails.EB_Type__c);
		if(mailerDetails.EB_Type__c == 'Single Email'){
            system.debug('----Single Email---');
		
			isSuccessEmail = sendEmailToContacts(returnFilterContacts,mailerDetails);
		}
		else
		{
			isSuccessEmail = sendEmailToContacts(returnFilterContacts, mailerDetails, 'Process Mass Mail');
		}
	}
	else
	{
		returnFilterContacts = allIncomingContactData;
	}
	
		
	// Step 4 : Query on the Contacts again after sending email to determine if any contact is bounced
	returnFilterContactsPostMail = [select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Id IN :returnFilterContacts];
	returnFilterContacts.clear();
	returnBouncedContacts.clear();
    FilterContactsWrapper filterConWrap =  new FilterContactsWrapper();
    filterConWrap = calculateFilterContacts(returnFilterContactsPostMail);
	returnFilterContacts = filterConWrap.validContactsList;
	returnBouncedContacts = filterConWrap.bouncedContactsList;

	// Step 5 : Process Bounced Contacts after sending Email(Inserting to Mailer Exception)
	if(returnBouncedContacts.size() > 0 )
		processBouncedContacts(returnBouncedContacts, 'Bounced - After Mail', setMailerIdforBatch,true);
	
	// Step 6 : Mailer Contact creation for successful contacts
	
	if(returnFilterContacts.size() > 0 )
		CreateMailerContact(returnFilterContacts,setMailerIdforBatch);
	
	
	return isSuccessEmail;
	
}

// Method-12 : for - Filtering the Contacts from bounced
public FilterContactsWrapper calculateFilterContacts(List<Contact> allIncomingContactData){

	// List to store all Filtered Contacts
	// List<Contact> returnFilterContacts = new List<Contact>();
    
    // Valid Contacts Lists
    List<Contact> validContactsList = new List<Contact>();
    // Bounced Contact List
    List<Contact> bouncedContactsList = new List<Contact>();
	
	for(Contact eachConRec : allIncomingContactData){
	
        if(eachConRec.IsEmailBounced == false){
            
            validContactsList.add(eachConRec);
        }
        else{
            bouncedContactsList.add(eachConRec);
        }
	}
	
        FilterContactsWrapper filterConWrap = new FilterContactsWrapper();
        filterConWrap.validContactsList = validContactsList;
        filterConWrap.bouncedContactsList = bouncedContactsList;
        return filterConWrap;
}
    
    public class FilterContactsWrapper{
        List<Contact> validContactsList;
        List<Contact> bouncedContactsList;
    }

 // Commenting this method as bounced contacts are fetched from calculateFilterContacts method
/*// Method-13 : for - Filtering the bounced Contacts 
public List<Contact> calculateBouncedContacts(List<Contact> allIncomingContactData){

	// List to store all Filtered Contacts
	List<Contact> returnBouncedContacts = new List<Contact>();
	
	for(Contact eachConRec : allIncomingContactData){
	
		if(eachConRec.IsEmailBounced == true){
		
			returnBouncedContacts.add(eachConRec);	
		}	
	}
	
	return returnBouncedContacts;
}*/

// Method-14 : for - Sending Email(SingleEmail)
public boolean sendEmailToContacts(List<Contact> FilterContacts, EB_AkaMailer__c mailerDetails){

    // Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,CMC_Default_Contact_Id__c,Default_From_Email_Address__c from 
							CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
							
	// For sending Email
	List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
	Messaging.SingleEmailMessage eachEmail;
	
	// Loop for all the contacts
	for(Contact eachConRec : FilterContacts){

		eachEmail = new Messaging.SingleEmailMessage();
		eachEmail.setTargetObjectId(eachConRec.Id);
		eachEmail.setOrgWideEmailAddressId(cmcMetadatarec.Default_From_Email_Address__c);
		eachEmail.saveAsActivity = false;
		eachEmail.setSaveAsActivity(false);
		eachEmail.setUseSignature(false); 
			
		if(mailerDetails.CMC_Template_ID__c != null){
		
			eachEmail.setTemplateId(mailerDetails.CMC_Template_ID__c);
			eachEmail.setWhatId(mailerDetails.Id);
				
		}
		else
		{
			eachEmail.subject = mailerDetails.CMC_Subject__c;
            eachEmail.HtmlBody = mailerDetails.EB_AdditionalIssueDescription__c;
		}
		emailList.add(eachEmail);
		
	}
	
	// send Email
	List<Messaging.SendEmailResult> results = Messaging.SendEmail(emailList);
	
	if(!system.isBatch()){
	
		// Updating Mailer Status = Email Sent - Contact Processing
		updateMailerStatusAfterEmailSent(mailerDetails.Id);
	}
	
	try{
		return results.get(0).isSuccess();
	} catch(Exception e)
	{
		return true;
	}
		
}

// Method-15 : for - Sending Email(MassEmail)
public boolean sendEmailToContacts(List<Contact> FilterContacts, EB_AkaMailer__c mailerDetails, string processMassEmail){
	
	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,CMC_Default_Contact_Id__c,Default_From_Email_Address__c from 
							CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
	string defaultContactId = cmcMetadatarec.CMC_Default_Contact_Id__c; // F-CO-2650731
	
	// Getting Related Contact Id
	Contact conRec = [select Id from contact where AKAM_Contact_ID__c = :defaultContactId limit 1];
		
	// Map to store Batch No + Each 25 Emails
	Map<string, List<string>> batchno_each25EmailMap = new Map<string, List<string>>();
	string key;
	List<string> each25Emails;
	
	// Loop for All the incoming Emails for designing the Map
	for(integer count=0; count < FilterContacts.size(); count++){

		key = 'Batch-'+ (count/25);
	
		if(batchno_each25EmailMap.get(key) == null){
	
			each25Emails = new List<string>();
		}
		else
		{
			each25Emails = batchno_each25EmailMap.get(key);
		}
	
		each25Emails.add(FilterContacts[count].Email);
		batchno_each25EmailMap.put(key,each25Emails);
		
	}
	
	// For sending Email
	List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
	Messaging.SingleEmailMessage eachBatchEmail;
	
	// Loop for each Batch of Email
	for(string eachBatch : batchno_each25EmailMap.keyset()){

		eachBatchEmail = new Messaging.SingleEmailMessage();
		
		eachBatchEmail.setBccAddresses(batchno_each25EmailMap.get(eachBatch));
		eachBatchEmail.setTargetObjectId(conRec.Id);
		eachBatchEmail.setOrgWideEmailAddressId(cmcMetadatarec.Default_From_Email_Address__c);
		eachBatchEmail.saveAsActivity = false;
		eachBatchEmail.setUseSignature(false); 
		eachBatchEmail.setSaveAsActivity(false);
			
		if(mailerDetails.CMC_Template_ID__c != null){
		
			eachBatchEmail.setTemplateId(mailerDetails.CMC_Template_ID__c);
			eachBatchEmail.setWhatId(mailerDetails.Id);
				
		}
		else
		{
			eachBatchEmail.subject = mailerDetails.CMC_Subject__c;
            	eachBatchEmail.HtmlBody = mailerDetails.EB_AdditionalIssueDescription__c;
		}
		emailList.add(eachBatchEmail);
	
	}
	
	// send Email
	List<Messaging.SendEmailResult> results = Messaging.SendEmail(emailList);
	
	if(!system.isBatch()){
	
		// Updating Mailer Status = Email Sent - Contact Processing
		updateMailerStatusAfterEmailSent(mailerDetails.Id);
	}
	
	try{
		return results.get(0).isSuccess();
	} catch(Exception e)
	{
		return true;
	}
			
}

// Method-16 : for - Processing Bounced Contacts before sending Email(Inserting to Mailer Exception)
public void processBouncedContacts(List<Contact> bouncedContacts, string exceptionMsg, string mailerIdParam,boolean isPostBounced){

	// List of Exception for Insert
	List<EB_MailerException__c> exceptionUpsertList = new List<EB_MailerException__c>();
	EB_MailerException__c eachExceptionRec;
	
	/****** Fo Contacts Which are already bounced ***/
	// Set to store all Contact Emails
	set<Id> allContactEmailIds = new set<Id>();
	
	// Map to store Contact Id + true
	Map<string, boolean> contactId_IsExceptionExistMap = new Map<string, boolean>();
	
	// Step-1 : Query on Mailer Exception to check if a contact is already bounced. If yes then do not process it.
	// Query should be executed in Postbounced as we can not determine which contact is already bounced
	if(isPostBounced){
		
		for (EB_MailerException__c eachPreExceptionRec : [select Id,CMC_AKAM_Contact_Id__c from EB_MailerException__c where EB_Mailer__c = :mailerIdParam]){
	
			contactId_IsExceptionExistMap.put(eachPreExceptionRec.CMC_AKAM_Contact_Id__c,true);
		}
	}
	
	// Loop for each Contact
	for(Contact eachBouncedContact : bouncedContacts){
	
		eachExceptionRec = new EB_MailerException__c();
		eachExceptionRec.CMC_Email_Address__c = eachBouncedContact.email;
		eachExceptionRec.CMC_AKAM_Contact_Id__c = eachBouncedContact.AKAM_Contact_ID__c;
        eachExceptionRec.CMC_Akam_Account_Id__c = eachBouncedContact.Account.AKAM_Account_ID__c;
		eachExceptionRec.Exception_Message__c = ((eachBouncedContact.Name != null) ? eachBouncedContact.Name : mConIdConName.get(eachBouncedContact.id))  + ' : ' + exceptionMsg;
		eachExceptionRec.EB_Mailer__c = mailerIdParam;
		eachExceptionRec.EB_Type__c = 'Bounced Contact';
		eachExceptionRec.CMC_Stage__c = 'Post Mailer';
		eachExceptionRec.CMC_Mailer_External_Id__c = mailerIdParam + '-' + eachBouncedContact.AKAM_Contact_ID__c;
		
		// If there is no enrty to map, that means no contact is pre bounced. just process it. Else discard it
		if(contactId_IsExceptionExistMap.get(eachBouncedContact.AKAM_Contact_ID__c) == null)
			exceptionUpsertList.add(eachExceptionRec);
	}
	
	Upsert exceptionUpsertList CMC_Mailer_External_Id__c;
	
}

// Method-17 : for - Creating Mailer Contact(Overloading the method for Batch Processing)
public void CreateMailerContact(List<Contact> FilterContacts, string mailerId){
	// List to store all Mailer Contact for Insert
	List<EB_AkaMContact__c> allMailerContactListInsert = new List<EB_AkaMContact__c>();
	EB_AkaMContact__c eachMailerContact;
	
	// Map to store Account Id + Mailer Account Id
	Map<ID, ID> AccountId_MailerAccountIdMap = new Map<ID, ID>();
	
	// set to store all Unique Account Ids
	set<Id> allUniqueAccountIds = new set<Id>();
	
	// Step 1 : Loop for all Contacts
	for(Contact eachContact : FilterContacts){
	
		allUniqueAccountIds.add(eachContact.AccountId);
	}
	
	//Step 2 : Get Default Policy Domain Details. This is used to get default Account.
    CMC_Settings__mdt cmcSettings = [SELECT CMC_Default_Account_Id__c, CMC_Default_Policy_Domain_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
	String defaultPD = cmcSettings.CMC_Default_Policy_Domain_Id__c.split(',')[0];
	Id defaultPDAccount = [SELECT Account_Name__c FROM Policy_Domain__c WHERE AKAM_Policy_Domain_id__c =:defaultPD].Account_Name__c;

	allUniqueAccountIds.add(defaultPDAccount);


	// Step 3 : Query on Mailer Account
	for(EB_AkaMAccount__c eachMailerAccount : [select Id,EB_Account__c from EB_AkaMAccount__c 
								where EB_Account__c IN :allUniqueAccountIds and 
								EB_AkaMailer__c = :mailerId]){
	
		AccountId_MailerAccountIdMap.put(eachMailerAccount.EB_Account__c, eachMailerAccount.Id);
	}
  
	
	// Step 4 : Loop for each Contact
	for(Contact eachContact : FilterContacts){

		eachMailerContact = new EB_AkaMContact__c();
		//eachMailerContact.EB_AkaMAccount__c = AccountId_MailerAccountIdMap.get(eachContact.AccountId);
		
		//if Account is not present then use default account for contact creation.(Scenario of Data issue)
        eachMailerContact.EB_AkaMAccount__c = AccountId_MailerAccountIdMap.get(eachContact.AccountId) != null ? AccountId_MailerAccountIdMap.get(eachContact.AccountId) : AccountId_MailerAccountIdMap.get(defaultPDAccount);
        
        
		eachMailerContact.EB_Contact__c	= eachContact.Id;
		eachMailerContact.EB_Status__c = 'Processed';
		eachMailerContact.CMC_Email_Address__c = eachContact.Email;
		eachMailerContact.CMC_Contact_ExternalId__c = mailerId + '-' + eachContact.Id;
		
		allMailerContactListInsert.add(eachMailerContact);
	}

	if(allMailerContactListInsert.size() > 0){
		Database.UpsertResult[] results = database.upsert(allMailerContactListInsert, EB_AkaMContact__c.CMC_Contact_ExternalId__c, false);
    	for (Database.UpsertResult sr : results) {
   			 if (!sr.isSuccess()) {
        			for(Database.Error err : sr.getErrors()) {
            			noOfErrors += 1;
                			errorMessage += 'Mailer Id = '+ setMailerIdforBatch;
                			errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                                +'..'+err.getMessage() +
                                + '\n' + errHdr + '\n';
        			}
    		}
		}
    }
}

// Method-18 : for - Synchronous Account Process Transactions
public void initiateSyncOperationForAccountProcess(List<Contact> validContactsList, List<Contact> bouncedContactsList,EB_AkaMailer__c mailerDetails,string contactQuery){

    system.debug('---Inside --- initiateSyncOperationForAccountProcess---');
	/*// List to store all Filtered Contacts
	List<Contact> returnFilterContacts = new List<Contact>();
	
	// List to store all Filtered Contacts
	List<Contact> returnBouncedContacts = new List<Contact>(); */
	
	// bolean to store whether Email Has been sent successfully or not
	boolean isSuccessEmail;
	
	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,No_Of_Contact_Sync_Operation__c,No_Of_Contact_ASync_Operation__c from CMC_Settings__mdt 
							where MasterLabel = 'CMC' limit 1];
	Integer noOfRecordsToProcessASyncOp = Integer.valueOf(cmcMetadatarec.No_Of_Contact_ASync_Operation__c); // 2000
	
	/*// Step 1: Calculate FilterContacts and Bounced Contacts
	returnFilterContacts = calculateFilterContacts(contactList);
	returnBouncedContacts = calculateBouncedContacts(contactList);*/

	// Step 2: Process Bounced Contacts before sending Email(Inserting to Mailer Exception)
	if(bouncedContactsList.size() > 0 )
		processBouncedContacts(bouncedContactsList, 'Already Bounced - Before Mail', setMailerIdforBatch,false);
	
    System.debug('---EB_Type__c---'+mailerDetails.EB_Type__c);
	// Step 3 : Call to sendEmail Method for sending Email
	
    if(mailerDetails.EB_Type__c == 'Single Email'){
        System.debug('---Single Email---');
	
		isSuccessEmail = sendEmailToContacts(validContactsList,mailerDetails);
	}
	else
	{
		isSuccessEmail = sendEmailToContacts(validContactsList, mailerDetails, 'Process Mass Mail');
	}
      
      // If send Email is false, then process Async completely else create Mailer contact Async
      if(isSuccessEmail == false){
      
      	CMC_postMailerActivityBatchJob asyncJob= new CMC_postMailerActivityBatchJob(contactQuery, false, mailerDetails.Id);
		Database.executeBatch(asyncJob,noOfRecordsToProcessASyncOp);
      }
      else
      {
      	CMC_postMailerActivityBatchJob asyncJob= new CMC_postMailerActivityBatchJob(contactQuery, true, mailerDetails.Id);
		Database.executeBatch(asyncJob,noOfRecordsToProcessASyncOp);
      }
      
}


// Method-19 : For Updating Mailer With Inprogress Status
public void updateMailerInprogressStatus(Id mailerDetailsId){

    System.debug('---Inside updateMailerInprogressStatus Method---');
	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerDetailsId);
	
    //Update the Email preview Attachment Id
    List<Attachment> emailPreviewAttachment = [SELECT Id FROM Attachment Where ParentId =:mailerDetails.Id AND Name = 'EmailPreview.html' limit 1];
	if(emailPreviewAttachment != null && !Test.isRunningTest())
    	mailerDetails.CMC_Email_Preview_AttachmentId__c = emailPreviewAttachment[0].Id;
    	
	mailerDetails.EB_Status__c = 'In-Process';
	mailerDetails.EB_Email_Notification_Start_Time__c = system.now();
	Update mailerDetails;
	
}

// Method-20 : For Updating Total Emails/Contacts (sync Operation)
public void updateMailerTotalCountSyncOp(EB_AkaMailer__c mailerDetails, Integer totalNoOfrecords){

	mailerDetails.CMC_Total_Emails_Contacts__c = Decimal.valueOf(totalNoOfrecords);
	Update mailerDetails;
}

// Method-21 : For Updating Mailer With Complete Status
public void updateMailerCompleteStatus(Id mailerDetailsId){ 

	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerDetailsId,EB_Status__c = 'Processed');
	mailerDetails.EB_Email_Notification_End_Time__c = system.now();
	Update mailerDetails;
	
	// Call to sendEemail Method for Incident Creator
	senEmailToIncidentCreator(true,mailerDetailsId);
	
}

// Method-22 : For Updating Mailer With Failed Status
public void updateMailerFailedStatus(Id mailerDetailsId, string exceptionMsg){

	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerDetailsId,EB_Status__c = 'Email Sent - Failed to Process Contacts');
	mailerDetails.EB_Email_Notification_End_Time__c = system.now();
	mailerDetails.EB_MailerFailReason__c = exceptionMsg;
	Update mailerDetails; 
	
	// Call to sendEemail Method for Incident Creator
	senEmailToIncidentCreator(false,mailerDetailsId);
	
}

// Method-23 : For Updating Mailer With Total Count + In-Process Status
public void UpdateMailerwithTotalBatchCount(Id JobId, Id mailerId){

	setTotalRecordsBatch = true;
	Integer totalJobItems = 0;
	
	if(!Test.isRunningTest()){
		AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus
        			from AsyncApexJob where Id = :JobId limit 1]; 
        	
        	totalJobItems = a.TotalJobItems;
    }
    else{
    	totalJobItems = 5;
    }
        			
      // Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,No_Of_Contact_Sync_Operation__c,No_Of_Contact_ASync_Operation__c from CMC_Settings__mdt 
							where MasterLabel = 'CMC' limit 1];
	Integer noOfRecordsPerBatch = Integer.valueOf(cmcMetadatarec.No_Of_Contact_ASync_Operation__c); // 2000
	Integer totalRecords = noOfRecordsPerBatch * totalJobItems;
	
	// Update Mailer
	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerId, EB_Status__c = 'In-Process');
	mailerDetails.CMC_IS_50000_Limit_Crossed__c = true;
	mailerDetails.CMC_Total_Emails_Contacts__c = Decimal.valueOf(totalRecords);
	Update mailerDetails;
}

// Method-24 : For Updating Mailer With Incremental Count
public void UpdateMailerwithIncrementalCount(Id mailerId, Integer eachBatchsize){
	
	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerId, 
						CMC_No_of_Processed_Contacts__c = Decimal.valueOf(eachBatchsize));
	Update mailerDetails;
}

// Method-25 : For Updating Mailer Status to Email Sent - Contact Processing
public void updateMailerStatusAfterEmailSent(Id mailerId){

	EB_AkaMailer__c mailerDetails = new EB_AkaMailer__c(Id = mailerId, 
									Email_Sent_End_Time__c = system.now(),
									EB_Status__c = 'Email Sent - Processing Contact');
	Update mailerDetails;
}

// Method - 26: For Creating and sending emails to Default Account's(Akamai-Asset) Contact
public void processMailerContactForDefaultAccount(EB_AkaMailer__c mailerDetails){

	// List to store all Related Contact for Akamai-Asset Account
	List<Contact> conListForDefaultAccount = new List<Contact>();
	
	// Getting data from Custom Metadata
	string getAkamAccountId = [select CMC_Default_Account_Id__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1].CMC_Default_Account_Id__c;
	
					
	conListForDefaultAccount = [select Id,Email,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact 
								where Contact_Type__c includes ('Technical Primary - 24X7','Tech Secondary - 24X7') 
								and Email != null and IsEmailBounced = False
								and Account.AKAM_Account_ID__c = :getAkamAccountId];
	
    // Creation of Mailer Contacts
	CreateMailerContact(conListForDefaultAccount, mailerDetails.Id);
    
    //Sending email
    List<String> defaultContactEmails = new List<String>();
    for(Contact eachContact : conListForDefaultAccount){
        defaultContactEmails.add(eachContact.Email);
    }
    
    //Call the existing send email method
    SendEmailForManualEnteredEmailAdd(mailerDetails,defaultContactEmails, true);
}

// Method - 27: For Creating Mailer Contact for Default Account(Akamai-Asset)
public Integer countMailerContactForDefaultAccount(Id mailerId){

	// List to store all Related Contact for Akamai-Asset Account
	List<Contact> conListForDefaultAccount = new List<Contact>();
	
	// Getting data from Custom Metadata
	string getAkamAccountId = [select CMC_Default_Account_Id__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1].CMC_Default_Account_Id__c;
	
					
	conListForDefaultAccount = [select Id,Email,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact 
								where Contact_Type__c includes ('Technical Primary - 24X7','Tech Secondary - 24X7') 
								and Email != null and IsEmailBounced = False
								and Account.AKAM_Account_ID__c = :getAkamAccountId];
								
	return conListForDefaultAccount.size();
}


// Method - 28: Method for Sending Email on Completion of Mailer
// Called from - updateMailerCompleteStatus,updateMailerFailedStatus
public void senEmailToIncidentCreator(boolean isSuccess, Id mailerId){

	// Getting data from Custom Metadata
	CMC_Settings__mdt cmcMetadatarec = [select Id,Default_From_Email_Address__c from 
							CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
    
    // Query on Mailer tt o get the Details
	EB_AkaMailer__c mailerDetails = [select Id, createdBy.Email, Name, EB_Type__c, CMC_IRAPT_SI_Number__r.Name,EB_Status__c ,CMC_Total_Emails_Contacts__c 
							from EB_AkaMailer__c where Id = :mailerId limit 1];

	// Setting Subject
	string emailSubject = (isSuccess) ? 'Send Mailer Successfully Processed ' : 'Send Mailer Failed ';
	emailSubject += '- Mailer Name: ' + mailerDetails.Name;
	
	// Setting Email Body
	string emailBody = (isSuccess) ? 'The following mailer has been processed successfully, all emails have been sent. \n\n' :
						'The following mailer has been failed\n\n';
	
	// Setting To Address
	String[] toAdd = new String[] {};
	toAdd.add(mailerDetails.createdBy.Email);
	
	// Setting Email Body
	emailBody += 'Mailer Name: ' + mailerDetails.Name + '\n';
	emailBody += 'Mailer Type : ' + mailerDetails.EB_Type__c + '\n';
	emailBody += 'SI#	: ' + mailerDetails.CMC_IRAPT_SI_Number__r.Name + '\n';
	emailBody += 'Status : ' + mailerDetails.EB_Status__c + '\n';
	emailBody += 'Processed# : ' + mailerDetails.CMC_Total_Emails_Contacts__c + '\n';
	
	// Sending Email
	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	mail.setToAddresses(toAdd);
    mail.setOrgWideEmailAddressId(cmcMetadatarec.Default_From_Email_Address__c);
	mail.subject = emailSubject;
	mail.plainTextBody = emailBody;
	Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 

} 

    
}