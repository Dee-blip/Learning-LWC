global class PACE_SIRNotifications implements Schedulable {

	global void execute(SchedulableContext sc)
	{	
		//checking if sandbox or production to modify email address to send to
		Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
		boolean isProduction = !org.IsSandbox;

		//getting base URL so we can add link to program in the mail
		String salesforceURL = System.URL.getSalesforceBaseUrl().toExternalForm();

		//generating table which has the details of last 3 review calendar dates
		String htmlTable = '<table style="border-collapse: collapse;"><col width="150"><col width="150"><col width="150"><col width="150"><tr><th style="border: 1px solid black;">SIR Name</th><th style="border: 1px solid black;">SIR Date</th><th style="border: 1px solid black;">Cut-off date to Submit the Finalized CPD*</th><th style="border: 1px solid black;">Cut-off Date to Schedule an SIR</th></tr>';
		for(PACE_Review_Calendar__c sirRecord: [select Cut_off_Date_for_Package_Submission__c, Cut_off_Date_to_Schedule_Catalog_Update__c, Name, Review_Date__c from PACE_Review_Calendar__c where Review_Date__c >= TODAY and Review_Type__c = 'SIR Meeting' order by Review_Date__c asc LIMIT 3])
		{
			String packageSubmissionCutOff = '';
			String catalogUpdateCutOff = '';
			if(sirRecord.Cut_off_Date_for_Package_Submission__c != null)
			{
				packageSubmissionCutOff = String.valueOf(sirRecord.Cut_off_Date_for_Package_Submission__c);
			}

			if(sirRecord.Cut_off_Date_to_Schedule_Catalog_Update__c != null)
			{
				catalogUpdateCutOff = String.valueOf(sirRecord.Cut_off_Date_to_Schedule_Catalog_Update__c);
			}

			htmlTable += '<tr style="text-align:left"><td style="border: 1px solid black; text-align: center">' + sirRecord.Name + '</td><td style="border: 1px solid black; text-align: center">' + String.valueOf(sirRecord.Review_Date__c) + '</td><td style="border: 1px solid black; text-align: center">' +  packageSubmissionCutOff + '</td><td style="border: 1px solid black; text-align: center">' + catalogUpdateCutOff + '</td></tr>';
		}
		htmlTable += '</table>';

		//fetching email template
		EmailTemplate template = [select Body, Subject, Name from EmailTemplate where Name = 'SIR Calendar - Notification' LIMIT 1];
		String emailTemplate = template.Body;

		//replace email template placeholder #htmltable with review calendar table
		emailTemplate = emailTemplate.replace('#htmlTable', htmlTable);

		//email list will hold all the emails to be sent to individual program managers
		List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();

		//fetching CC recepeints. note this should be only PROD OPS 
		PACECustomSettings__c ccUserMailIds = PACECustomSettings__c.getInstance('SIR_CC_Receipients');
		String emails = ccUserMailIds.Value__c;
		List<String> ccRecepients = emails.split(',');

		if(!isProduction){
			for(Integer i =0; i < ccRecepients.size(); i++){
    			ccRecepients[i] = ccRecepients[i] + '.qa';
    		}
    		//ccRecepients.add('bmurumul@akamai.com');
    		//ccRecepients.add('jmelwyn@akamai.com');
    		//ccRecepients.add('mpadakan@akamai.com');
    		ccRecepients.add('PaceMailBox@akamai.com');
    		ccRecepients.add('mpadakan@akamai.com');
		}

		//recepeints  (program and product manager) and email template for each program
		List<String> receipients = new List<String>();
		String tempTemplate;

		for(PACE_Program__c program: [select Id, Product_Manager__r.Email, Program_Manager__r.Email, Name from PACE_Program__c where Status__c='In Progress' and Program_Phase__c in ('Definition', 'Development') and Bu__c != 'Luna'])
		{	
			receipients.clear();

			tempTemplate = emailTemplate.replace('#programLink', '<a href="' + salesforceURL + '/' + program.Id + '">' + program.Name + '</a>');

			if(program.Product_Manager__r.Email != null)
				receipients.add(isProduction ? program.Product_Manager__r.Email : program.Product_Manager__r.Email + '.qa');

			if(program.Program_Manager__r.Email != null)
				receipients.add(isProduction ? program.Program_Manager__r.Email : program.Program_Manager__r.Email + '.qa');

			prepareEmailList(template.Subject, tempTemplate, receipients, emailsList, ccRecepients, isProduction);

		}

		//send only if email list has atleast one email
		if(!emailsList.isEmpty())
			Messaging.sendEmail(emailsList);
	}

	private void prepareEmailList(String subject, String htmlBody, String[] receipients, List<Messaging.SingleEmailMessage>  emailsList, String[] ccAddresses, boolean isProduction)
    {

    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    	mail.setToAddresses(receipients);
    	mail.setCcAddresses(ccAddresses);
        mail.setSenderDisplayName('PACE Mailer');
        mail.setSubject(subject);
        mail.setHtmlBody('<div style="font-family:Calibri">' + htmlBody + '</div>');
        mail.emailPriority = 'Highest';
        emailsList.add(mail);
        
    }
}