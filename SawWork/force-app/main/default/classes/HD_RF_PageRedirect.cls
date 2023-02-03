/* 
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Uses as part of Client/Staff redirection

Purpose : used as global redirector for Client/Staff
          
Usage :  Used as a  global Routing Logic for Landing page in Remedyforce
          
Class/Trigger Asssociated : NONE

Controller (Boolean): True

Page Used/Asssociated (default -> NONE) : HDRFRedirect.page

Other Component Used : HD_REDIRECT_CONTROL_URL_SETTING (Custom Settings)

*/ 
public with sharing class HD_RF_PageRedirect {

//Declaring Boolean Flag for Code Execute
public static boolean HD_REDIRECT_ENABLED = FALSE; 

//declaring variable to capture User Id
public  String UserId = null;
//List for getting User details
private List<User> userObjectList = new List<User>();


//defining the fails safe URL
public static String FailSafeUrl = '/servlet/servlet.Integration?lid=01rG0000000VHua&ic=1';

//Start of constructor
public HD_RF_PageRedirect(){

	UserId = Userinfo.getUserId();
	// putting limit 1 in the query since the one user will be using this page at a time.
	userObjectList =  [ Select Id,User_Profile_Name__c, Name, BMCServiceDesk__IsStaffUser__c From User Where Id =: UserId Limit 1  ];
		
}//END of constructor


//Start of Action Method for VF Page, executes when page loads.
public Pagereference Redirect()
{
	System.Pagereference redirect = null;
	//By default all the urls will go to SDE Home
	String redirecturl = FailSafeUrl;
	 
	try {

   //Getting custome Setting info
   HD_REDIRECT_CONTROL_URL_SETTING__c HD_INCIDENT_CONSOLE = HD_REDIRECT_CONTROL_URL_SETTING__c.getInstance('HD_INCIDENT_CONSOLE');
   HD_REDIRECT_CONTROL_URL_SETTING__c HD_RF_HOME = HD_REDIRECT_CONTROL_URL_SETTING__c.getInstance('HD_RF_HOME');
   HD_REDIRECT_CONTROL_URL_SETTING__c redirect_enabled = HD_REDIRECT_CONTROL_URL_SETTING__c.getInstance('HD_INCIDENT_CONSOLE_REDIRECT');
   HD_REDIRECT_CONTROL_URL_SETTING__c HD_staff_profile = HD_REDIRECT_CONTROL_URL_SETTING__c.getInstance('HD_staff_profile');
   String All_profiles = 'All Profiles';
   boolean HD_INCIDENT_CONSOLE_REDIRECT = Boolean.valueOf(redirect_enabled.Value__c);
   redirecturl = 	HD_RF_HOME.Value__c;	

	 //Check weather new routing settings are enabled or not
	if ( HD_INCIDENT_CONSOLE_REDIRECT == true )
	{
		
	 System.debug('User Id Got ------>'+UserId);
	 
	 if(userObjectList.size() != 0) 
	 {
	 	for ( User user : userObjectList ) 
	 	{
	 	
	 	 if( (user.BMCServiceDesk__IsStaffUser__c == true) && ( String.valueOf(HD_staff_profile.Value__c).contains(user.User_Profile_Name__c) || ( String.valueOf(HD_staff_profile.Value__c).equalsIgnoreCase(All_profiles)   )  )  )
	 		{
	 			redirecturl = HD_INCIDENT_CONSOLE.Value__c ;
	 		}
	
	 		 else
	 		{
	 		    redirecturl = HD_RF_HOME.Value__c ;
	 		}
	 		
		 		
	 	  }//for ( User user : usr )
	  }//if(usr.size() != 0)
	 
	} //if ( HD_REDIRECT_ENABLED == true )
	else
	{
		System.debug('Helpdesk Redirect controller id Disabled: ----> '+HD_INCIDENT_CONSOLE_REDIRECT );
	}
	
	 //logic for redirection to the specified URl base on user
	  redirect = new Pagereference( redirecturl );
	 
	}//try
	
	catch (exception e)
	{
		System.debug('[]Exception:'+e.getMessage() );
		System.debug('[]Exception line:'+e.getLineNumber() );
		System.debug('[]Exception Stack Trace:'+e.getStackTraceString() );
		
		//redirecting the user to failsafe Url SDE Home Page
		redirect = new Pagereference( FailSafeUrl );
		return redirect;
	}//try outer
	
	 
	return  redirect ;
}//End of Redirect()


}