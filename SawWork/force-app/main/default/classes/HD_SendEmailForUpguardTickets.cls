/*
*
*Template: Apex Class
*Version: 1.0
*@author: Nikhil Karn @ Akamai Technologies Ltd.
*Created Date : 13th March, 2018
*Purpose : an implementation for email trigger if ticket count is more then specific number
*Number Of methods: 5
*Test Class Associated : HD_Test_SendEmailForUpguardTicketsJobs
*Controller (Boolean): False
*Page Used/Associated (default -> NONE) : NONE
*Trigger Associated : [  ]
*Class used : 
*@Last Modified By:
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
public  class HD_SendEmailForUpguardTickets {

	public static Integer siLimit = null;
	public static String whereClause = null;
	public static List<String> status = null;
	public static List<String> categories = null;
	public static List<String> subscriberEmails=null;
	public static List<BMCServiceDesk__Incident__c> incidents=null;
	public static Boolean isCriteriaEmpty=false;


	/*
	*@author:Nikhil Karn
	*@created date: 13th March, 2018
	*@details: This method is getting called by HD_SendEmailForUpguardTicketsJobs class in execute method 
	*			and fetch all the trigger jobs from custom metadata type from HDEmailAlertForTicketsExcceding__mdt
	*@Last Modified By:
	*@Last Modified Date:
	*@Last Modified Reason:
	*
	*/
	public static void runEmail(){

		//fetching all email triggers defined in custom metadata type HDEmailAlertForTicketsExcceding__mdt 
		List<HDEmailAlertForTicketsExcceding__mdt> customMetaData=[SELECT Categories__c, isActive__c, Status_of_Service_Incident__c ,TotalExccedCount__c,Subscriber_Emails__c,WHERE_Clause__c FROM HDEmailAlertForTicketsExcceding__mdt WHERE isActive__c=true];

		if(!customMetaData.isEmpty()){
			for(HDEmailAlertForTicketsExcceding__mdt emailAlertCustMetaData:customMetaData){
				if(emailAlertCustMetaData.isActive__c){//checking if particular email alert job is active or not
					try{
						sendEmail(emailAlertCustMetaData);
						}catch(Exception e){
							System.debug('Exception occurred in HD_SendEmailForUpguardTickets>runEmail method: '+e.getStackTraceString());
							status = null;
							categories = null;
							continue;
						}
						}else{
							break;
						}
						status = null;
						categories = null;
					}
				}
			}


	/*
	*@author:Nikhil Karn
	*@created date: 13th March, 2018
	*@Input Parameters: HDEmailAlertForTicketsExcceding__mdt
	*@details: This method is reposible to query the incident results for an email alert job and also to filter out the conditions
	*@Last Modified By:
	*@Last Modified Date:
	*@Last Modified Reason:
	*
	*/
	@TestVisible private static void sendEmail(HDEmailAlertForTicketsExcceding__mdt emailAlertCustMetaData){
		siLimit = emailAlertCustMetaData.TotalExccedCount__c.intValue();
		whereClause=emailAlertCustMetaData.WHERE_Clause__c;
		if(!String.isEmpty(emailAlertCustMetaData.Status_of_Service_Incident__c)){
			status = emailAlertCustMetaData.Status_of_Service_Incident__c.split(',');
		}
		if(!String.isEmpty(emailAlertCustMetaData.Categories__c)){
			categories = emailAlertCustMetaData.Categories__c.split(',');
		}
		subscriberEmails = emailAlertCustMetaData.Subscriber_Emails__c.split(',');

		if(!(String.isEmpty(whereClause)&&status==null&&categories==null)){//if all the conditions is null then mail will not triggered
			incidents = Database.query(getQuery(whereClause,status,categories));
			if(incidents.size()>=siLimit){
				sendMails();
			}
		}
	}



	/*
	*@author:Nikhil Karn
	*@created date: 13th March, 2018
	*@details: This method is responsible to set up the email configuration and sending email to respective subscriber
	*@Last Modified By:
	*@Last Modified Date:
	*@Last Modified Reason:
	*
	*/
	@TestVisible private static void sendMails(){
		Messaging.reserveSingleEmailCapacity(10);
		Map<String,OrgWideEmailAddress> owa = new Map<String,OrgWideEmailAddress>();
		for(OrgWideEmailAddress orgEmail :[select id, Address from OrgWideEmailAddress LIMIT 500]){
			owa.put(orgEmail.Address, orgEmail);   
		}

		Id sfNoReplyAddressId = null;
		if(owa.containsKey('sf-no-reply@akamai.com')){
			sfNoReplyAddressId = owa.get('sf-no-reply@akamai.com').id;
		}
		List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = subscriberEmails;
		if(sfNoReplyAddressId != null){
			mail.setOrgWideEmailAddressId(sfNoReplyAddressId);
		}
		mail.setToAddresses(toAddresses);
		mail.setReplyTo('sf-no-reply@akamai.com');

		String emailSubject='Alert for Exceeded number of tickets';
		mail.setSubject(emailSubject);
		mail.setHtmlBody(getContent());
		mailList.add(mail);

		Messaging.sendEmail(mailList);		        
	}

	/*
	*@author:Nikhil Karn
	*@created date: 13th March, 2018
	*@details: This method is responsible to provide dynamic email body template for an email alert.
	*@Last Modified By:
	*@Last Modified Date:
	*@Last Modified Reason:
	*
	*/
	@TestVisible private static String getContent(){
		String parsedLaunchConsole=null;
		Integer counter=1;
		String tempContent='<head><style>  .Completed{background-color:#8FFF67;} .Failed{background-color:red;color:white} .Aborted{background-color:#00ccff;} </style></head>';
		if(status==null||categories==null){
			tempContent='<p>Hi,</p><p>You are receiving this email alert because there are more than '+siLimit+' tickets in open status with below categories.</p>';
			}else{
				tempContent='<p>Hi,</p><p>You are receiving this email alert because there are more than '+siLimit+' tickets in open status for '+categories+' categories.</p><p>Below are the summary of the tickets:</p>';
			}
			tempContent += '<table bordercolor="black" border=0 bgcolor="#DADADA"><thead><tr><th>S. No.</th><th>Name</th><th>Status</th><th>Created Date</th><th>Category</th><th>Owner</th><th>Launch Console</th></tr>';
			Boolean bgColor=true;
			for(BMCServiceDesk__Incident__c incident:incidents){
				parsedLaunchConsole=incident.Launch_Console__c.replace('<a href="','<a href="'+URL.getSalesforceBaseURL().toExternalForm());
				if(bgColor){
					tempContent +='<tr align="center" bgcolor="#EFEFEF"><td>'+counter+'</td><td>'+incident.name+'</td><td>'+incident.BMCServiceDesk__FKStatus__r.name+'</th><td>'+incident.SI_Created_Date_International_format__c+'</td><td>'+incident.BMCServiceDesk__Category_ID__c+'</td><td>'+incident.HD_Owner_user_queue__c+'</td><td>'+parsedLaunchConsole+'</td></tr></thead>';
					bgColor=false;
					}else{
						tempContent +='<tr align="center" bgcolor="#EEEEEE"><td>'+counter+'</td><td>'+incident.name+'</td><td>'+incident.BMCServiceDesk__FKStatus__r.name+'</th><td>'+incident.SI_Created_Date_International_format__c+'</td><td>'+incident.BMCServiceDesk__Category_ID__c+'</td><td>'+incident.HD_Owner_user_queue__c+'</td><td>'+parsedLaunchConsole+'</td></tr></thead>';
						bgColor=true;
					}
					counter=counter+1;
				}
				tempContent += '</table>';
				return tempContent;
			}

	/*
	*@author:Nikhil Karn
	*@created date: 13th March, 2018
	*@details: This Method is responsible to provide dynamic query to fetch incident lists based on provided criteria.
	*@Last Modified By:
	*@Last Modified Date:
	*@Last Modified Reason:
	*
	*/
	@TestVisible private static String getQuery(String whereClause,List<String> status,List<String> categories){
		String query=null;
		Integer finalLimit=siLimit+10;
		if(String.isEmpty(whereClause)){
			query='SELECT Id, BMCServiceDesk__FKStatus__r.name, NAME,HD_Owner_user_queue__c, BMCServiceDesk__Category_ID__c, BMCServiceDesk__FKClient__r.name, CreatedDate, SI_Created_Date_International_format__c, Launch_Console__c FROM BMCServiceDesk__Incident__c WHERE BMCServiceDesk__Category_ID__c IN :categories AND BMCServiceDesk__FKStatus__r.name IN :status ORDER BY CreatedDate limit '+ String.valueOf(finalLimit);
			}else{
				query='SELECT Id, BMCServiceDesk__FKStatus__r.name, NAME,HD_Owner_user_queue__c, BMCServiceDesk__Category_ID__c, BMCServiceDesk__FKClient__r.name, CreatedDate, SI_Created_Date_International_format__c, Launch_Console__c FROM BMCServiceDesk__Incident__c WHERE '+ whereClause +' AND BMCServiceDesk__Category_ID__c IN :categories AND BMCServiceDesk__FKStatus__r.name IN :status ORDER BY CreatedDate limit '+ String.valueOf(finalLimit);
			}
			if(categories==null){
				query=query.replace('AND BMCServiceDesk__Category_ID__c IN :categories','');
				query=query.replace('BMCServiceDesk__Category_ID__c IN :categories','');
			}
			if(status==null){
				query=query.replace('AND BMCServiceDesk__FKStatus__r.name IN :status','');
			}
			return query;
		}	
	}