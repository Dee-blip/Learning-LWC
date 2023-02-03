/* History:
 * =========================
 * @author 	Ruchika Sharma, 	21st May 2017   SFDC-1632,SFDC-1723
 	SendEmail_Soasta_DPM: Async Queuebale class to query all the accounts that were created in given duration and send mail
 */
 //there would not be more num of records than 50k, hence queueable is better. As with it we can have 100 concurrent Queueable as compared to 5 batches.
public class SendEmail_Soasta_DPM implements Queueable {
	
	String reportLink;
	String soastaEmailDL;
	String soastaUserAlias;
	private final String batchJobType = 'Soasta Accounts With Pool User Email';
	public SendEmail_Soasta_DPM() {
		reportLink = GsmUtilClass.getGSMSettingValue('Soasta_Report_Link');
		system.debug(LoggingLevel.ERROR,'Soasta Email reportLink: '+reportLink);
		soastaEmailDL = GsmUtilClass.getGSMSettingValue('Soasta_Email_DL');
		system.debug(LoggingLevel.ERROR,'Soasta Email soastaEmailDL: '+soastaEmailDL);
		soastaUserAlias = GsmUtilClass.getGSMSettingValue('soasta_user_alias');
	}

   	public void execute(QueueableContext context) {

   		String res = '';
   		Integer acc = 0;
		acc = [select count() from Account Where Owner.Alias = :soastaUserAlias];
		system.debug(LoggingLevel.ERROR,'Soasta Email accList: '+acc);
		if(acc!=0 || Test.isRunningTest()){
			OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'crm-noreply@akamai.com'];
			EmailNotificationConfig emailNotificationConf = new EmailNotificationConfig(batchJobType);
	   		String[] toAddresses = new list<string> ();
	   		//toAddresses.addAll(soastaEmailDL.split(','));
	   		toAddresses.addAll(emailNotificationConf.getBusinessUserToAddress().split(','));
	   		
	   		Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
	   		if ( owea.size() > 0 ) {
	    		email.setOrgWideEmailAddressId(owea.get(0).Id);
			}
			reportLink=URL.getSalesforceBaseUrl().toExternalForm() + '/'+reportLink;
            EmailTemplate emTemplate = emailNotificationConf.getTemplate();
            email.setHtmlBody(emTemplate.HtmlValue.replace('#REPORT_LINK#',reportLink));
        	email.setPlainTextBody(emTemplate.Body.replace('#REPORT_LINK#',reportLink));
        	email.setSubject(emTemplate.Subject);    
			email.setToAddresses( toAddresses );
			try {
				Messaging.SendEmailResult [] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
				if(resultMail[0].isSuccess())
      				res = '1:Mail send to '+toAddresses+' \n';
   				else
      				res = '0:'+resultMail[0].getErrors().get(0).getMessage();
   				
    			}catch(EmailException e){
        			// IF MESSAGE CONTAINS "UNVERIFIED_SENDER_ADDRESS":
			        system.debug(LoggingLevel.ERROR,'e: '+e);
			        	if(e.getMessage().contains('UNVERIFIED_SENDER_ADDRESS'))
			            	res =  '0: Email address not verified yet';
			            else
			            	res = '0: some error has occurred '+e.getMessage();
			    }

		    }else
		    	res = '1:No Accounts with DPM Pool User. \n';
		Util.updateCronRunWithResult(batchJobType, res);

	}
		
}