/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 23-jun-2015

Base Line : used as apart of requirment for RF incident periodic email updates

Purpose : an implementation for periodic Email Updated batch apex
          
Usage : used as an implementation for the periodic email based on status
          
Test Class Asssociated : 

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : 

Custom settings : HD_TicketStatusAlert @ this class exclusivly uses the custome setting for batch job processing


batch seeting for Custom settings :  {"batch_params":[{"distributionlistemail":"hbarapat@akamai.com,kahegde@akamai.com","recordlink":"/apex/BMCServiceDesk__RemedyforceConsole?objectName=Incident__c&record_id=","queryorclause":""}]}

To run the apex in scheduled manner :
***************************************
HD_TicketStatusAlert_batchapex ticketbatch = new HD_TicketStatusAlert_batchapex(false);
ID batchprocessid = system.scheduleBatch(ticketbatch,'HD Ticket status job',2); //scheduled for 2 min
System.debug(' -------> '+ticketbatch);

CronTrigger ct = [SELECT Id, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :batchprocessid];
System.assertEquals(0, ct.TimesTriggered);
System.debug('Next fire time: ' + ct.NextFireTime);


              
*/
global with sharing class HD_TicketStatusAlert_batchapex implements Database.Batchable<sObject> {

	//defined this flag to set execption raise condition
   public static Boolean RUNNING_TEST_SETTING = false;	
   global  String Query;
   //the email should be replaced by EaE Ops email
   public static String[] utiltoemail = new String[]{'hbarapat@akamai.com'};
   //Single Mail Messaging email Util
   public static List<Messaging.Singleemailmessage> lstMail = new List<Messaging.Singleemailmessage>();

	//defining Constructor
	public HD_TicketStatusAlert_batchapex(boolean testrunflag) {
		RUNNING_TEST_SETTING = testrunflag;
	}//

	global Database.Querylocator start( Database.Batchablecontext bc)
	{
		//getting query OR clause filter values
	  List<String> queryorclauseCustomsettingsList = String.valueof(hdbatchjobsValues('queryorclause')).split(',');
	  if ( queryorclauseCustomsettingsList.size() > 0 )
	  {
	  System.debug(' -----> Entering GenerateQuery Method ');
	  Query =  GenerateQuery(queryorclauseCustomsettingsList);
	  }
	  else
	  {
	   System.debug(' -----> Entering hard coded query ');
	  Query = 'Select Id, Name,BMCServiceDesk__Type__c, BMCServiceDesk__Client_Name__c, BMCServiceDesk__Category_ID__c, HD_Owner_user_queue__c, BMCServiceDesk__Status_ID__c from BMCServicedesk__Incident__c,HD_Queue_name__c Where BMCServiceDesk__Status_ID__c = \'UNASSIGNED\' ORDER BY Name DESC LIMIT 1000';
	  }
      
      return database.getQueryLocator( Query );	
	}//start

    global void execute( Database.Batchablecontext bc,List<sObject> scope)
    {
    	String incidentLink = System.Url.getSalesforceBaseUrl().toExternalForm();
    	List<String> toAddress = new List<String>();
    	List<BMCServicedesk__Incident__c> InciList = new List<BMCServicedesk__Incident__c>();

    try{

    	//Checking for test condition to modify to zero
		System.debug('Running Test'+Test.isRunningTest());
       for(Sobject s: scope)
       {
          BMCServicedesk__Incident__c inc = (BMCServicedesk__Incident__c) s;
          System.debug('Incident details :----> ' +inc);
         InciList.add(inc);

       }//for(Sobject s: scope)

       //getting more than one value in the dustribution list from Custom Settings, HD_BATCH_JOB
       List<String> DistributiontoaddressCustomsettings = String.valueof(hdbatchjobsValues('distributionlistemail')).split(',');
       System.debug(' JSON string toaddress split-------> '+DistributiontoaddressCustomsettings);
       if(DistributiontoaddressCustomsettings.size() > 0 )
       {
       toAddress.addAll(DistributiontoaddressCustomsettings);
       System.debug('toAddress details------>'+toAddress.size() +' Content: '+toAddress);
       if( toAddress.size() > 0 && InciList.size() > 0)
       {
       incidentlink += String.valueof(hdbatchjobsValues('recordlink'));
       periodicEmail(toAddress,incidentLink,InciList);
       }//if( toAddress.size() > 0 && InciList.size() > 0)
       }//if(DistributiontoaddressCustomsettings.size() > 0 )

       	system.debug('-----> Mail List size() '+lstMail.size());
		//Sending mail Outside of the Loop
		if( lstMail.size() > 0)
		{   
			system.debug('-----> Calling SendEmail method ');
			Messaging.sendEmail(lstMail);
		}

    	}//try
    	catch(Exception le){
    		emailUtil('HD_TicketStatusAlert_batchapex Exception', '[]Exception: '+le.getMessage()+'\n[]StackTrace: '+le.getstacktraceString(), utiltoemail);
    	}

    }//execute

    global void finish( Database.Batchablecontext bc )
	{

	AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
	// Send an email to the Apex job's submitter notifying of job completion.
   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
   //Change the email to EaE Ops
   String[] toAddresses = new String[] {};
   toAddresses.addAll(utiltoemail);
   mail.setToAddresses(toAddresses);
   mail.setSubject('HD_TicketStatusAlert_batchapex ' + a.Status);
   mail.setPlainTextBody
   ('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
   if ( a.NumberOfErrors  > 0 )
   {
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   }//if ( a.NumberOfErrors  > 0 )

	}//finish


	/*
* Usage@ Used for sending email to the particular record owner
* Purpose@ To send email on periodic basis
* Query : 'Select Id, Name,BMCServiceDesk__Type__c, BMCServiceDesk__Client_Name__c, BMCServiceDesk__Category_ID__c, HD_Owner_user_queue__c, BMCServiceDesk__Status_ID__c from BMCServicedesk__Incident__c Where BMCServiceDesk__Status_ID__c = \'UNASSIGNED\' LIMIT 1000 ';
*/
private static void periodicEmail(List<String> toAddress,String incidentlink, List<BMCServicedesk__Incident__c> inciList )
{
	Messaging.Singleemailmessage mail = getEmail();
	try{
	if( toAddress.size() > 0)
	{
	mail.setToAddresses(toAddress);
	
	mail.setSubject('HelpDesk Periodic Email Alert for UNASSIGNED Tickets');
	//Creating Html Email Body
	string htmlemailBody ='The Following Tickets are under UNASSIGNED State :'+ inciList.size();
		   htmlemailBody +='<hr></hr>';
		   htmlemailBody +='<table style="width:100%">';
		   htmlemailBody +='<tr><th>Name</th><th>Type</th><th>Client</th><th>Category</th><th>Owner</th><th>Status</th></tr>';

		   if(inciList.size() > 0)
		   {
           for(BMCServicedesk__Incident__c inc : inciList)
           {
             htmlemailBody +='<tr><th><a href="'+incidentlink+''+inc.Id+'">'+inc.Name+'</a></th><th>'+inc.BMCServiceDesk__Type__c+'</th><th>'+inc.BMCServiceDesk__Client_Name__c+'</th><th>'+inc.BMCServiceDesk__Category_ID__c+'</th><th>'+inc.HD_Owner_user_queue__c+'</th><th>'+inc.BMCServiceDesk__Status_ID__c+'</th></tr>';
           }//for(BMCServicedesk__Incident__c)
           } //if(inciList.size() > 0)    

		   htmlemailBody +='</table>';
	       htmlemailBody +='<hr></hr>'; 
	       //htmlemailBody +='<br/>Note: This is a consolidate email for UNASSIGNED Status , kindly ignore the mail.';	//Removed as per CR 3103651 - Remedyforce, remove the Note text from the batch email
	
	mail.setHtmlBody( htmlemailBody );
	//adding the mail message in to the Lists
	lstMail.add(mail);
	
	}//

 //Messaging.sendEmail( new Messaging.Singleemailmessage[] {mail} );
}//try
catch( Emailexception ee )
{
	emailUtil('HD_TicketStatusAlert_batchapex, periodicEmail()-method Exception', '[]Exception: '+ee.getMessage()+'\n[]StackTrace: '+ee.getstacktraceString(), utiltoemail);
}
	
}//private static periodicEmail()

/*
* Usage@ Used for sending email 
* Purpose@ To send email on periodic basis
*
*/
private static void emailUtil( String subject, String message,List<String> to)
{
	try
	{
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
   List<String> toAddresses = new List<String>();
   toAddresses.addAll(to);
   if(toAddresses.size() > 0)
   {
   mail.setToAddresses(toAddresses);
   mail.setSubject( subject );
   mail.setPlainTextBody(message);
   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   }//if(toAddresses.size() > 0)
	}//try
	catch( Emailexception ex ){
		System.debug('[]Exception: In emailUtil Method of HD_Problem_Pending_Periodic_batchapex');
		System.debug('[]Exception:'+ex.getMessage());
		System.debug('[]Exception:'+ex.getStackTraceString());
	}
}//private static void emailUtil( String subject, String message,List<String> to)

/*
* Usage@ Used to extract value from the HD_BATCH_JOB hierarchy custom settings
* purpose@ to get the batch setting value stored in the form so json string
*/
private string hdbatchjobsValues(String keyValue)
{
	String key = keyValue;
	String value = null;
try
	{	
	HD_BATCH_JOB__c hdbatchjob = HD_BATCH_JOB__c.getOrgDefaults();
	 	
	//Json Extract process		
	String jsonval = hdbatchjob.HD_TicketStatusAlert_batchapex__c;
	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(jsonval);
	List<Object>  batch_params = (List<Object>) m.get('batch_params');
	Map<String,Object>  batch_paramsmap = (Map<String,Object>) batch_params[0];
	System.debug('Days--->'+batch_paramsmap.get( key.trim() ));                
	value = String.valueOf(batch_paramsmap.get(key));	
	}
	catch (Exception e) 
	{
		emailUtil('HD_TicketStatusAlert_batchapex Exception in hdbatchjobsValues() method for class HD_TicketStatusAlert_batchapex', '[]Exception: '+e.getMessage()+'\n[]StackTrace: '+e.getstacktraceString(), utiltoemail);
	}
	
	return value;
}//private string hdbatchjobsValues(String keyValue)

//Solving too many email invocations
public static  Messaging.Singleemailmessage getEmail()
{
	Messaging.SingleEmailMessage mailMessage = new Messaging.SingleEmailMessage();
	mailMessage.setSaveAsActivity(false);
	return mailMessage;

}//

//Query Generator method 
private static String GenerateQuery(List<String> queryorclausefilterstring)
{
	String qry = 'Select Id, Name,BMCServiceDesk__Type__c, BMCServiceDesk__Client_Name__c, BMCServiceDesk__Category_ID__c, HD_Owner_user_queue__c, BMCServiceDesk__Status_ID__c,HD_Queue_name__c from BMCServicedesk__Incident__c Where  BMCServiceDesk__Status_ID__c = \'UNASSIGNED\' AND ( HD_Queue_name__c like \'Help%\' ';
	
	if( queryorclausefilterstring.size() > 0 )
	{
		qry +='OR ';
      for(String ORfilterString : queryorclausefilterstring )
      {
        qry += ' HD_Queue_name__c = \''+ORfilterString+'\' ';
        qry +='OR';
      }//for(String ORfilterString : queryorclausefilterstring )
        System.debug('after loop query ---> '+qry);
        system.debug('----> '+qry.endsWith('OR'));
        qry.removeEnd('OR');
        if( qry.endsWith('OR'))
        {
        	qry = qry.removeEnd('OR');
          //qry = qry.substring(0,qry.length()-2);
        }
        qry +=' )';
	}//
    qry += ' ORDER BY Name DESC LIMIT 1000';
    System.debug('generated query -------> '+qry);
	return qry;

}//privat static GenerateQuery(List<String> queryorclausefilterstring)

}//END of class