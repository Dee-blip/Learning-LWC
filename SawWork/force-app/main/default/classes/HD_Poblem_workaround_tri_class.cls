/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Problem Managment Workaround logic

Purpose : TO notify all when ever new Workaround is added
          
Usage : used as  business logic , for problem managment Workaround Module
          
Test Class Asssociated : HD_Test_Problem_Workaround

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Poblem_workaround_tri
 * Modification Log ===============================================================
 * Date 		     Author 			 Modification
 * Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/

public with sharing class HD_Poblem_workaround_tri_class 
{

//global variable

public static HD_Poblem_workaround_tri_class instance = null;
public  static List<Problem_workaround__c> probWork = new  List<Problem_workaround__c>(); 

private  HD_Poblem_workaround_tri_class(List<Problem_workaround__c>  workObjIns)
{
	probWork.addAll(workObjIns);
}//Constructor

public static HD_Poblem_workaround_tri_class getInstance(List<Problem_workaround__c> InstanceTrigger)
{
	if( instance == null )
	{
		instance = new HD_Poblem_workaround_tri_class(InstanceTrigger);
	}
	
	return instance;
	
}//singleton class



//Send Mail Function 
public static void EmailSender( Problem_workaround__c[] newTriggervalueforProbWrk)
{   
	String[] toAddresses = new List<String>();
	String[] ccAddresses = new List<String>();
	Messaging.Singleemailmessage  mail = new Messaging.Singleemailmessage();// invoking mail class
	try{
	
	List<BMCServiceDesk__Problem__c> problemcc = new List<BMCServiceDesk__Problem__c>();
	problemcc = [ Select CC1__c, CC2__c, CC3__c, CC4__c, CC5__c, CC6__c From BMCServiceDesk__Problem__c WHERE Id =:newTriggervalueforProbWrk[0].Problem__c LIMIT 1  ]; 
	
	List<Subject_Matter_Expert__c> sme = new List<Subject_Matter_Expert__c>();
	sme = [Select   Name, Email__c From Subject_Matter_Expert__c s WHERE  Problem__c =: newTriggervalueforProbWrk[0].Problem__c LIMIT 100];
	
	//Adding Problem Owner Email
    toAddresses.add( newTriggervalueforProbWrk[0].Problem_owner_email__c );
	
	//Adding email to an string array
if( problemcc.size() > 0 ||  sme.size() > 0 )
{
 	for ( Subject_Matter_Expert__c smeemail : sme)  
	{
	toAddresses.add( smeemail.Email__c );
	}
}//if( sme.size() > 0 )

//Adding CCfields from Problem object
 if (problemcc.size() > 0)
	{
	for( BMCServiceDesk__Problem__c pro : problemcc )
	{
		System.debug('Getting Problem Cc ------->'+pro.CC1__c);
		
		if(pro.CC1__c != null )
		ccAddresses.add( pro.CC1__c );
		
		if(pro.CC2__c != null)
		ccAddresses.add( pro.CC2__c );
		
		if(pro.CC3__c != null)
		ccAddresses.add( pro.CC3__c );
		
		if(pro.CC4__c != null)
		ccAddresses.add( pro.CC4__c );
		
		if( pro.CC5__c != null)
		ccAddresses.add( pro.CC5__c );
		
		if(pro.CC6__c != null)
		ccAddresses.add( pro.CC6__c );
		
	}
	}//if (problemcc.size() > 0)
 
System.debug(' Getting List Value To Addresses ---------->  '+toAddresses);
System.debug(' Getting List Value Cc Fields ---------->  '+ccAddresses);

if ( toAddresses.size() > 0)
{	
//Setting email entities	
mail.setToAddresses(toAddresses);

//Setting CC Address
if(ccAddresses.size() > 0)
mail.setCcAddresses(ccAddresses);

//mail.setEmailPriority(pString)
mail.setSubject('New Workaround '+ +' for Problem #'+newTriggervalueforProbWrk[0].Problem_Name__c+' has been Added');

String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+newTriggervalueforProbWrk[0].Problem__c;

//Construct Email body 
String emailbody = 'New Workaround '+  +' for Problem #<a href="'+recordLink +'">'+newTriggervalueforProbWrk[0].Problem_Name__c +'</a> has been added by <a href="'+ recordLink+'">'+newTriggervalueforProbWrk[0].Created_By_Name__c +'</a><br></br>';

emailbody += '<br>Title/Summary : '+newTriggervalueforProbWrk[0].Title_Summary__c;
emailbody += '<br>Workaround : '+newTriggervalueforProbWrk[0].Workaround__c; 
emailbody += '<br></br>Click here to view :';
emailbody +=  ''+recordLink;
//starting Dynamic inputs

emailbody +='<br></br>';
//Changed as a part of CR 2610705 - Problem Mgmt - Email templates should be consistent
//emailbody +='Sent from Apex Class.';
//setting HTML BODY
mail.setHtmlBody( emailbody );
Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail}); 
}//if ( toAddresses.size() > 0)
	}// try
	
	Catch( Exception e)
	{
		System.debug('Exception[]: '+e.getMessage());
		newTriggervalueforProbWrk[0].addError('Somethings Not right , the developemnt Team Has been Notified !');
		
	}

}// public void smeEmailSender

private static List<BMCServiceDesk__Status__c> fetchStatus(String CategoryName)
{
	List<BMCServiceDesk__Status__c> statusList = new List<BMCServiceDesk__Status__c>();
	return [Select Id from BMCServiceDesk__Status__c Where Name =:CategoryName Limit 1];
}


//
@future(Callout=true)
public static void updateProblemStatustoWorkaroundIdentified(List<Id> ProbIdList)
{
	
	List<Id> ProbIds = new List<Id>();
	ProbIds.addAll(ProbIdList);
	if(ProbIds.size() > 0)
	{
	//getting the List for Status
	List<BMCServiceDesk__Status__c> statusList = new List<BMCServiceDesk__Status__c>();
	statusList.addAll(fetchStatus('WORKAROUND IDENTIFIED'));
    
    if(statusList.size() > 0) 
    {

  	//creating Problem List
	List<BMCServiceDesk__Problem__c> proList = new List<BMCServiceDesk__Problem__c>();		
	proList = [ Select Id,BMCServiceDesk__FKStatus__c  from BMCServiceDesk__Problem__c Where Id IN :ProbIds ];
	System.debug('----------> Problem : '+ proList);
    
	for(BMCServiceDesk__Problem__c pr :proList )
		{
		for(BMCServiceDesk__Status__c  st : statusList)
			{
				pr.BMCServiceDesk__FKStatus__c = st.Id;
			}//
		
		//update pr;
		}//for
		update proList;
	}//if(statusList.size() > 0) 
}//if(ProbIds.size() > 0)
	
}//future method

}