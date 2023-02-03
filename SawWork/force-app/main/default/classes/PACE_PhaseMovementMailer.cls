/*
	Class: PACE_PhaseMovementMailer
	Purpose: Scheduled job to trigger emails to intimate about phase movement. Details: Refer JIRA Story PACEENGG-36
	Author: Gaurav Jain (gjain@akamai.com)
*/

global class PACE_PhaseMovementMailer implements Schedulable {
	List<String> nonEOSEOLPrograms;
	PACECustomSettings__c userMailIds;
	String emails;
	List<String> receipients;
	String salesforceBaseURL;
	String replyToEmailId;
	Boolean isProduction;

	//Start of execution of scheduled job
	global void execute(SchedulableContext sc) {
		//Get Email addresses from custom settings
		userMailIds = PACECustomSettings__c.getInstance('PACE_Batch_mail');

		Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
		isProduction = !org.IsSandbox;
    
    	//If email ids are not present in custom setting, return
	    if (userMailIds.Value__c == null) {
	      return;
	    }

	    emails = userMailIds.Value__c;
	    //Split Emails separated by comma
	    receipients = emails.split(',');
	    if(!isProduction){
	    	for(Integer i = 0; i < receipients.size(); i++){
	    		receipients[i] = receipients[i] + '.qa';
	    	}
	    }
	    PACECustomSettings__c replyToMail = PACECustomSettings__c.getInstance('Batch_ReplyToEmail');

	    if(replyToMail!= null && replyToMail.Value__c != null)
	    {
	    	replyToEmailId = replyToMail.Value__c;
	    }

	    salesforceBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
		nonEOSEOLPrograms = new List<String>();
		nonEOSEOLPrograms.add('New Program');
		nonEOSEOLPrograms.add('PACE Program PM Readonly Record Type');
		nonEOSEOLPrograms.add('PACE Program PM Readonly Record Type EC go');
		nonEOSEOLPrograms.add('PACE Program Record Type');
		sendEmails();
	}

	private void sendEmails()
	{
		List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
		sendMailForNonEOLEOSProgram(emailsList);
		sendMailForEOLEOSProgram(emailsList);
		// Commenting the below code to stop mail sent if tier is blank. PACEENGG-171
		// sendMailForBlankTierPrograms(emailsList);
		if(emailsList.size() > 0)
			Messaging.sendEmail(emailsList);
	}

	private void sendMailForNonEOLEOSProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		sendMailForLaunchPhaseProgram(emailsList);
		sendMailForDevelopmentPhaseProgram(emailsList);
		sendMailForConceptPhaseProgram(emailsList);
		sendMailForDefinitionPhaseProgram(emailsList);
		sendMailForResourceStatus(emailsList);
		sendMailForScheduleReason(emailsList);
		sendMailForResourceReason(emailsList);
		mailsForPhaseContractDatesValidation(emailsList);
	}

	private void sendMailForLaunchPhaseProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Launch phase and both Planned/Actual LA and Planned/Actual GA dates are in the past, then send mail to mark the program complete.
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where Program_Phase__c = 'Launch' and Planned_LA__c < TODAY and Planned_GA__c < TODAY and Mail_exception__c = false and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> has gone past LA and GA. So please mark your program as "Complete".</p><p>If the dates in Salesforce are incorrect and your new dates are within the 30-day tolerance window of your last PRB-approved phase contract, please update the planned/actual GA and LA dates in Salesforce. If the new dates are out of tolerance, please <a href="https://docs.google.com/a/akamai.com/forms/d/e/1FAIpQLScd5xjaQ2c5ZI50M9tfBt_Sgc_rDNdyy_D4rIKUWYR48LSYpQ/viewform">schedule</a> an Exception Review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForDevelopmentPhaseProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Development phase and if Planned/Actual LC date is in the past, then send mail to move phase to Launch
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where Program_Phase__c = 'Development' and Planned_LC__c < TODAY and Mail_exception__c = false and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> has gone past LC. So please move your program phase to Launch.</p><p>If the date in Salesforce is incorrect and your new date is within the 30-day tolerance window of your last PRB-approved phase contract, please update the planned/actual LC date in Salesforce. If the new date is out of tolerance, please <a href="https://docs.google.com/a/akamai.com/forms/d/e/1FAIpQLScd5xjaQ2c5ZI50M9tfBt_Sgc_rDNdyy_D4rIKUWYR48LSYpQ/viewform">schedule</a> an Exception Review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForConceptPhaseProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		sendMailForPlannedCC(emailsList);
		sendMailForSkippedCC(emailsList);
	}

	private void sendMailForSkippedCC(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Concept phase and skipped CC is true an status is in progress, send mail
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where Program_Phase__c = 'Concept' and Skipped_CC__c = true and Mail_exception__c = false and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> can skip CC. So please move your program phase to Definition.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForPlannedCC(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Concept phase and Planned/Actual CC date is in the past, then send mail to move phase to Definition
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where Program_Phase__c = 'Concept' and Planned_CC__c < TODAY and Mail_exception__c = false and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> has gone past CC. So please move your program phase to Definition.</p><p>If the date is incorrect in Salesforce, please go ahead and edit the Planned/Actual CC date.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}

		//When program is at Concept phase and if either Original or Planned/Actual CC date is blank and if program was created before 10 days
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id, Original_CC__c, Planned_CC__c from PACE_Program__c where Program_Phase__c = 'Concept' and Skipped_CC__c = false and (Planned_CC__c = null or Original_CC__c = null) and Pace_Tier__c != null and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			//notify user which CC date is blank. Original or Planned or both
			String CCdatesBlankStatement = ' Original CC date ';
			if(prog.Planned_CC__c == null){
				CCdatesBlankStatement = ' Planned CC date ';
			}
			if(prog.Planned_CC__c == null && prog.Original_CC__c == null){
				CCdatesBlankStatement = ' Planned CC and Original CC dates ';
			}

			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>Please capture' + CCdatesBlankStatement + 'for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> in Salesforce.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)`
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForDefinitionPhaseProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		
	    //List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Definition phase and if Planned/Actual EC date is in the past, then send mail to move phase to Development
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where Program_Phase__c = 'Definition' and Planned_EC__c < TODAY and Mail_exception__c = false and RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> has gone past EC. So please move your program phase to Development.</p><p>If the date is incorrect in Salesforce, please go ahead and edit the Planned/Actual EC date.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForResourceStatus(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If resource status or schedule status is blank.
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Id from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Pace_Tier__c != null and Status__c='In Progress' and (Resource_Status__c=null or Schedule_Status__c=null)])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>Resource status and Schedule status cannot be left blank in Salesforce. Please capture the resource status and schedule status for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a>.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForScheduleReason(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If resource status or schedule status is blank.
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Schedule_Reason__c, Id from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Pace_Tier__c != null and (Schedule_Status__c='At Risk' or Schedule_Status__c='Off Track')])
		{
			if(String.isBlank(prog.Schedule_Reason__c))
			{
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>When Schedule status is Yellow or Red, it is necessary to add reason to it. So please capture schedule reason for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> in Salesforce.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForResourceReason(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If resource status or schedule status is blank.
		for(PACE_Program__c prog:[select Program_Manager__r.FirstName, Program_Manager__r.Email, Product_Manager__r.Email, Name, Resource_Reason__c, Id from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Pace_Tier__c != null and (Resource_Status__c='At Risk' or Resource_Status__c='Off Track')])
		{
			if(String.isBlank(prog.Resource_Reason__c))
			{
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>When Resource status is Yellow or Red, it is necessary to add reason to it. So please capture resource reason for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> in Salesforce.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailForEOLEOSProgram(List<Messaging.SingleEmailMessage>  emailsList)
	{
		sendMailForBlankECDate(emailsList);
		sendMailforPastECDate(emailsList);
	}

	private void sendMailForBlankECDate(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Launch phase and both Planned/Actual LA and Planned/Actual GA dates are in the past, then send mail to mark the program complete.
		for(PACE_Program__c prog:[select Name, Product_Manager__r.Email, Program_Manager__r.FirstName, Program_Manager__r.Email from PACE_Program__c where RecordType.Name not in :nonEOSEOLPrograms and (Original_EC__c=null or Planned_EC__c=null) and Status__c='In Progress' and CreatedDate < :Date.today() - 9])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>Please capture EC date for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> in Salesforce. <p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void sendMailforPastECDate(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Launch phase and both Planned/Actual LA and Planned/Actual GA dates are in the past, then send mail to mark the program complete.
		for(PACE_Program__c prog:[select Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName from PACE_Program__c where RecordType.Name not in :nonEOSEOLPrograms and Planned_EC__c<TODAY and Status__c='In Progress' and Program_Phase__c='Definition'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>As per Salesforce, <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> has gone past EC. So please move your program phase to Development.</p><p>If the date is incorrect in Salesforce, please go ahead and edit the Planned/Actual EC date.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, true);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	private void mailsForPhaseContractDatesValidation(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    //Loop through all the programs that match the following criteria:
	    //If a program is at Launch phase and both Planned/Actual LA and Planned/Actual GA dates are in the past, then send mail to mark the program complete.
		for(PACE_Program__c prog:[select Id, Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName, Planned_LC__c, Phase_contract_LC_Date__c from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Phase_contract_LC_Date__c != null and Planned_LC__c != null and Mail_exception__c=false])
		{	
			//if(prog.Planned_LC__c > prog.Phase_contract_LC_Date__c - 30)
			if(prog.Phase_contract_LC_Date__c.daysBetween(prog.Planned_LC__c) > 30)
			{
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>The Planned/Actual LC date for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> is beyond the tolerance limit of 30 days. Please schedule an exception review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}

		for(PACE_Program__c prog:[select Id, Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName, Planned_Actual_SC__c, Phase_contract_SC_Date__c from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Planned_Actual_SC__c !=null and Phase_contract_SC_Date__c != null and Mail_exception__c=false])
		{	
			//if(prog.Planned_Actual_SC__c > prog.Phase_contract_SC_Date__c - 30)
			if(prog.Phase_contract_SC_Date__c.daysBetween(prog.Planned_Actual_SC__c) > 30)
			{
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>The Planned/Actual SC date for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> is beyond the tolerance limit of 30 days. Please schedule an exception review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}

		for(PACE_Program__c prog:[select Id, Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName, Planned_LA__c, Phase_contract_LA_Date__c from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Phase_contract_LA_Date__c != null and Planned_LA__c !=  null and Mail_exception__c=false])
		{	
			if(prog.Phase_contract_LA_Date__c.daysBetween(prog.Planned_LA__c) > 30)
			{	
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>The Planned/Actual LA date for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> is beyond the tolerance limit of 30 days. Please schedule an exception review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}

		for(PACE_Program__c prog:[select Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName, Planned_GA__c, Phase_contract_GA_Date__c from PACE_Program__c where RecordType.Name in :nonEOSEOLPrograms and Status__c='In Progress' and Phase_contract_GA_Date__c != null and Planned_GA__c != null and Mail_exception__c=false])
		{	
			//if(prog.Planned_GA__c > prog.Phase_contract_GA_Date__c - 30)
			if(prog.Phase_contract_GA_Date__c.daysBetween(prog.Planned_GA__c) > 30)
			{
				String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>The Planned/Actual GA date for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> is beyond the tolerance limit of 30 days. Please schedule an exception review.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
				prepareEmailList(htmlText, receipients, emailsList, prog, true);
			}
		}

		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}

	// Commenting the below code to stop mail sent if tier is blank. PACEENGG-171
	/*
	private void sendMailForBlankTierPrograms(List<Messaging.SingleEmailMessage>  emailsList)
	{
		//List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
	    
	    //Loop through all the programs that match the following criteria:
	    //If a program is in progress and created at-least 10 days ago and have tier as blank, then send mail.
		for(PACE_Program__c prog:[select Name, Product_Manager__r.Email, Program_Manager__r.Email, Program_Manager__r.FirstName from PACE_Program__c where Pace_Tier__c = null and Status__c='In Progress'])
		{
			String htmlText = '<p>Hi ' + prog.Program_Manager__r.FirstName + ',</p><p>The Tier for <a href="' + salesforceBaseURL +'/' + prog.Id +'">' + prog.Name + '</a> is blank in Salesforce. Please request a Tier for your program through the <a href="https://docs.google.com/a/akamai.com/forms/d/e/1FAIpQLScd5xjaQ2c5ZI50M9tfBt_Sgc_rDNdyy_D4rIKUWYR48LSYpQ/viewform">PRB request form</a>.<p>Please ignore this email if you have already submitted a request for Tier.</p><p>Please reach out to Product Ops (Mail to: Prb-facilitator@akamai.com) for any queries.</p><p>Thanks,</p><p>Product Operations</p>';
			prepareEmailList(htmlText, receipients, emailsList, prog, false);
		}
		//if(emailsList.size() > 0)
		//	Messaging.sendEmail(emailsList);
	}
	*/

	private void prepareEmailList(String htmlBody, String[] receipients, List<Messaging.SingleEmailMessage>  emailsList, PACE_Program__c program, Boolean sendToManagers)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(isProduction){
        	mail.setToAddresses(receipients);
        	if(sendToManagers){
        		mail.setToAddresses(new List<String>{program.Program_Manager__r.Email});
        		mail.setCCAddresses(new List<String>{program.Product_Manager__r.Email, 'prb-facilitator@akamai.com'});
        	}
        }
        if(!isProduction){
        	mail.setToAddresses(receipients);
        	if(sendToManagers){
        		mail.setToAddresses(new List<String>{program.Program_Manager__r.Email + '.qa'});
        		mail.setCCAddresses(new List<String>{program.Product_Manager__r.Email + '.qa', 'prb-facilitator@akamai.com.qa'});
        	}
        	//mail.setBCCAddresses(new List<String>{'mpadakan@akamai.com'});
        	mail.setBCCAddresses(new List<String>{'hverma@akamai.com', 'PaceMailBox@akamai.com'});

        }
        if(Test.isRunningTest()){
        	mail.setToAddresses(new List<String>{'mpadakan@akamai.com.qa'});
        	mail.setCCAddresses(new List<String>{'mpadakan@akamai.com.qa'});
        	mail.setBCCAddresses(new List<String>{});
        }
        
        mail.setSenderDisplayName('PACE Mailer');
        mail.setSubject('Action required for ' + program.Name + ' in Salesforce');
        if(replyToEmailId != null)
 	       mail.setReplyTo(replyToEmailId);
        //Email body for html compliant mail client
        mail.setHtmlBody(htmlBody);
        emailsList.add(mail);
    }
}