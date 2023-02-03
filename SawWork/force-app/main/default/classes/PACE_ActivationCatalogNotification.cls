global class PACE_ActivationCatalogNotification implements Schedulable {
	global void execute(SchedulableContext sc)
	{
		Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
		boolean isProduction = !org.IsSandbox;

		EmailTemplate template = [select Body from EmailTemplate where Name = 'Activation Catalog - Notification' LIMIT 1];
		String mailContent = template.Body;
		String baseURL = System.URL.getSalesforceBaseUrl().toExternalForm();

		List<Messaging.SingleEmailMessage>  emailsList = new List<Messaging.SingleEmailMessage>();
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

		//getting scope so mailers are sent only for next month
		Integer currentMonth = System.now().month();
		Integer currentYear = System.now().year();
		Integer nextMonth, nextYear;

		if(currentMonth == 12){
			nextMonth = 1;
			nextYear = currentYear + 1;
		}
		else {
			nextMonth = currentMonth + 1;
			nextYear = currentYear;
		}

		for(Launch_Item__c catalogUpdate : [select Product_Manager__c, Product_Manager__r.Email, Program__r.Product_Manager__c, Program__r.Product_Manager__r.Email, Program__c, Program__r.Program_Manager__c, Program__r.Program_Manager__r.Email, Id, SIR_Meeting_Date__c, SIR_Meeting_Date__r.Name, SIR_Meeting_Date__r.Review_Date__c, Name, Product_Phase__c, Package_Design_Document__c, PLU__c, PLU__r.Name, PLU__r.PLU_Month__c from Launch_Item__c where PLU__c in (select Id from PLU__c where Archive__c = false) and FISCAL_MONTH(PLU__r.PLU_Date__c) =: nextMonth and FISCAL_YEAR(PLU__r.PLU_Date__c) =: nextYear])
		{
			String mailBody = mailContent;
			mailBody = mailBody.replace('#GoLive', String.valueOf(catalogUpdate.PLU__r.Name));
			mailBody = mailBody.replace('#ActivationMonth', catalogUpdate.PLU__r.Name);
			mailBody = mailBody.replace('#CatalogName', '<a href="'+baseURL+'/'+catalogUpdate.Id+'">'+catalogUpdate.Name+'</a>');
			mailBody = mailBody.replace('#ProductPhase', catalogUpdate.Product_Phase__c);
			mailBody = mailBody.replace('#CatalogUpdateLink', baseURL+'/'+catalogUpdate.Id);
			mailBody = mailBody.replaceAll('#ActivationName', catalogUpdate.PLU__r.Name);

			String cpdDoc = String.isBlank(catalogUpdate.Package_Design_Document__c) ? '' : catalogUpdate.Package_Design_Document__c;
			
			mailBody = mailBody.replace('#CPDDoc', cpdDoc);

			mailBody = mailBody.replace('#CatalogItem', catalogUpdate.Name + ' Catalog Item');	
			

			String subject = catalogUpdate.PLU__r.Name + ' Confirmation Required';
			List<String> receipients = new List<String>();
			if(catalogUpdate.Product_Manager__c != null && catalogUpdate.Product_Manager__r.Email != null)
				receipients.add(isProduction ? catalogUpdate.Product_Manager__r.Email : catalogUpdate.Product_Manager__r.Email + '.qa');

			if(catalogUpdate.Program__c != null && catalogUpdate.Program__r.Product_Manager__c != null && catalogUpdate.Program__r.Product_Manager__r.Email != null)
				receipients.add(isProduction ? catalogUpdate.Program__r.Product_Manager__r.Email : catalogUpdate.Program__r.Product_Manager__r.Email + '.qa');

			if(catalogUpdate.Program__c != null && catalogUpdate.Program__r.Program_Manager__c != null && catalogUpdate.Program__r.Program_Manager__r.Email != null)
				receipients.add(isProduction ? catalogUpdate.Program__r.Program_Manager__r.Email : catalogUpdate.Program__r.Program_Manager__r.Email + '.qa');

			if(receipients.isEmpty()){
				continue;
			}

			prepareEmailList(subject, mailBody, receipients, emailsList, ccRecepients, isProduction);
		}

		if(!emailsList.isEmpty())
			Messaging.sendEmail(emailsList);

	}

	private void prepareEmailList(String subject, String htmlBody, String[] receipients, List<Messaging.SingleEmailMessage>  emailsList, String[] ccAddresses, Boolean isProduction)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(receipients);
        mail.emailPriority = 'Highest';
        mail.setSenderDisplayName('PACE Mailer');
        mail.setSubject(subject);
        mail.setCcAddresses(ccAddresses);

		//if(!isProduction){
		//	mail.setBccAddresses(new List<String>{'mpadakan@akamai.com', 'bmurumul@akamai.com', 'jmelywn@akamai.com', 'usomani@akamai.com'});
		//}
        //Email body for html compliant mail client
        mail.setHtmlBody('<div style="font-family:Calibri">' + htmlBody + '</div>');
        emailsList.add(mail);
    }
}