/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 22-jul-2014

Base Line : used as apart of requirment for Problem Managment periodic emails updtes using batch apex

Purpose : an implementation for periodic Email Updated batch apex
          
Usage : used as an implementation for the periodic email based on Last Updated Date
          
Test Class Asssociated : 

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : 

Custom settings : HD_BATCH_JOB @ this class exclusivly uses the custome setting for batch job processing
              
*/
global class HD_Problem_Pending_Periodic_batchapex implements Database.batchable<sObject>
{
	//defined this flag to set execption raise condition
   public static Boolean RUNNING_TEST_SETTING = false;	
   global  String Query;
   //the email should be replaced by EaE Ops email
   public static String[] utiltoemail = new String[]{'hbarapat@akamai.com'};
   //Single Mail Messaging email Util
   public static List<Messaging.Singleemailmessage> lstMail = new List<Messaging.Singleemailmessage>();
   
  //defining Constructor
  public HD_Problem_Pending_Periodic_batchapex( boolean testrunflag ){
  	RUNNING_TEST_SETTING = testrunflag;
  }

global Database.Querylocator start( Database.Batchablecontext bc)
	{
		Query = 'select Id,Name,Owner_formulafield__c,Title_Summary__c,BMCServiceDesk__Problem_Description__c,Owner_Email__c,Service_Owners__r.email,BMCServiceDesk__Status__c,LastModifiedDate from BMCServiceDesk__Problem__c WHERE BMCServiceDesk__Status__c != \'PROBLEM INITIATED\' AND BMCServiceDesk__Status__c != \'CLOSED\' LIMIT 10000';
    	return database.getQueryLocator( Query );	
	}//Start
	
global void execute( Database.Batchablecontext bc,List<sObject> scope)
	{
	try
		{
			
		Integer dayslimit = Integer.valueOf(hdbatchjobsValues('periodicdays'));
		
		String problemLink = System.Url.getSalesforceBaseUrl().toExternalForm();
		
		//Checking for test condition to modify to zero
		System.debug('Running Test'+Test.isRunningTest());
		if(Test.isRunningTest())
			{
				dayslimit = 0;
			}
		
		for(Sobject s: scope)
		{
			List<String> toAddress = new List<String>();
			BMCServiceDesk__Problem__c prb = (BMCServiceDesk__Problem__c) s;
			Datetime dts = Datetime.valueOf( prb.LastModifiedDate) ;
			
			Integer days = Integer.valueOf(( System.now().getTime() - dts.getTime() )/(1000*60*60*24));
            System.debug('The Problem #'+prb.Name+' is pending by Number of days ------->'+days+', grace Limit is '+dayslimit );
            System.debug('The Problem #'+prb.Name+' details Service_Owners__r :'+prb.Service_Owners__r.Email+' Owner_Email__c : '+prb.Owner_Email__c  );
                       
            //toAddress.add( prb.Owner_Email__c );

            //if the negative test is running
		    if(RUNNING_TEST_SETTING == false)
		    {
		    	toAddress.add( prb.Owner_Email__c );
		    	if(prb.Service_Owners__r.Email != null)
		    	{ 	toAddress.add( prb.Service_Owners__r.Email ); }
		    }
		    else if(RUNNING_TEST_SETTING == true) 
		    {
		    	toAddress.add( 'test' );
		    }
		    System.debug('toAddress details------>'+toAddress.size() +' Content: '+toAddress);			
		    			
			if( days >= dayslimit)
			{
			periodicEmail(toAddress, prb.Name , prb.Owner_formulafield__c , prb.Title_Summary__c, prb.BMCServiceDesk__Problem_Description__c, problemLink+'/'+prb.Id);
			}
			//clearing the toAddress List
 	       toAddress.clear();
		}//for(Sobject s: scope)
		
		system.debug('-----> Mail List size() '+lstMail.size());
		//Sending mail Outside of the Loop
		if( lstMail.size() > 0)
		{   
			system.debug('-----> Calling SendEmail method ');
			Messaging.sendEmail(lstMail);
		}
		
		}//try
		catch( Emailexception le)
		{
			emailUtil('HD_Problem Batch Process Exception', '[]Exception: '+le.getMessage()+'\n[]StackTrace: '+le.getstacktraceString(), utiltoemail);
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
   mail.setSubject('HD_Problem Batch Process ' + a.Status);
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
* Query : 'select Id,Name,Owner_formulafield__c,Title_Summary__c,BMCServiceDesk__Problem_Description__c,Owner_Email__c,BMCServiceDesk__Status__c from BMCServiceDesk__Problem__c LIMIT 1000 ';
*/
private static void periodicEmail(List<String> toAddress, String problemName,String OwnerName,String title, String description,String problemLink )
{
	
	Messaging.Singleemailmessage mail = getEmail();
	try{
	if( toAddress.size() > 0)
	{
	mail.setToAddresses(toAddress);
	
	mail.setSubject('Problem #'+problemName+' is not being updated a while, and is Pending');
	//Creating Html Email Body
	string htmlemailBody ='A Problem with #<a href="'+problemLink+'">'+problemName+'</a>, having owner <a href="'+problemLink+'">'+OwnerName+'</a> is not being updated from a while, and is Pending.';
		   htmlemailBody +='<hr></hr>'; 
	       htmlemailBody +='<br/>Title: '+title; 
	       htmlemailBody +='<br/>Description: '+description; 
	       htmlemailBody +='<br/>Problem Link : '+problemLink;
	       htmlemailBody +='<hr></hr>'; 
	       htmlemailBody +='<br/>Note: If already updated the problem, kindly ignore the mail.';
	
	
	mail.setHtmlBody( htmlemailBody );
	//adding the mail message in to the List
	lstMail.add(mail);
	
	}//

 //Messaging.sendEmail( new Messaging.Singleemailmessage[] {mail} );
}//try
catch( Emailexception ee )
{
	emailUtil('HD_Problem Batch Process, periodicEmail()-method Exception', '[]Exception: '+ee.getMessage()+'\n[]StackTrace: '+ee.getstacktraceString(), utiltoemail);
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
	String jsonval = hdbatchjob.HD_Problem_Pending_Periodic_batchapex__c;
	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(jsonval);
	List<Object>  batch_params = (List<Object>) m.get('batch_params');
	Map<String,Object>  batch_paramsmap = (Map<String,Object>) batch_params[0];
	System.debug('Days--->'+batch_paramsmap.get( key.trim() ));                
	value = String.valueOf(batch_paramsmap.get(key));	
	}
	catch (Exception e)
	{
		emailUtil('HD_Problem Batch Process Exception in hdbatchjobsValues() method for class HD_Problem_Pending_Periodic_batchapex', '[]Exception: '+e.getMessage()+'\n[]StackTrace: '+e.getstacktraceString(), utiltoemail);
	}
	
	return value;
}//private string hdbatchjobsValues(String keyValue)

//Solving too many email invocations
public static  Messaging.Singleemailmessage getEmail()
{
	Messaging.SingleEmailMessage mailMessage = new Messaging.SingleEmailMessage();
	mailMessage.setSaveAsActivity(false);
	return mailMessage;

}

}//END OF Class