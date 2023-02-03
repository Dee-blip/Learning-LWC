/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for SME
          
Usage : Used as an implementation for the business logic , for trigger HD_Subject_Matter_Expert_tri.trigger
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Subject_Matter_Expert_tri.trigger
              
*/


public with sharing class HD_Subject_Matter_Expert_tri_Class {

//global Variables
private static HD_Subject_Matter_Expert_tri_Class instance = null;

//list for object
private static List<Subject_Matter_Expert__c> SmeObj = null;

private HD_Subject_Matter_Expert_tri_Class( List<Subject_Matter_Expert__c> smeObjInst)
{
	SmeObj = smeObjInst;
	
}//Constructor

public static HD_Subject_Matter_Expert_tri_Class getInstance( List<Subject_Matter_Expert__c> triggerInstance )
{
	if( instance == null)
	{
		instance = new HD_Subject_Matter_Expert_tri_Class(triggerInstance);
		
	}

	return instance;
}//Lazy loading of instance

/*
USED FOR THE IMPMEMENTATION FOR THE BEFORE TRIGGER
*/
public void beforeEventProcess() 
{
	System.debug('---> []Entering beforeEventProcess() method ');
	if(SmeObj.size() > 0)
	{
	 
	 for( Subject_Matter_Expert__c sme : SmeObj)
	  {
	  //	smeExistsforProblemValidationRule( sme.Problem__c , sme.User__c);
        addCCValuesFromTheParentProblem( sme.Problem__c );
	  }//For Loop
			
	}//if
}//public void beforeEventProcess() 

/*
//Validation rule for Subject_Matter_Expert__c Object
public void smeExistsforProblemValidationRule(String ProblemId, String UserId )
{
	System.debug('[]Entering smeExistsforProblemValidationRule(String ProblemId, String UserId) method');
	Subject_Matter_Expert__c[] sub = [ Select Id From Subject_Matter_Expert__c  WHERE Problem__c =:ProblemId AND User__c =:UserId LIMIT 1 ];
	if( sub.size() > 0 )
	{
		SmeObj[0].addError('SME(Subject Matter Expert) for this Problem already exists');
	}
}//
*/

//Get CC feild values from the parent problem
public static void addCCValuesFromTheParentProblem( String ProblemId )
{
	try{
 BMCServiceDesk__Problem__c[] problemforSME  =  [ Select Id, CC1__c, CC2__c, CC3__c, CC4__c, CC5__c, CC6__c From BMCServiceDesk__Problem__c b WHERE Id =: ProblemId LIMIT 1  ];	
 if( problemforSME.size() > 0 )
 {
 for( BMCServiceDesk__Problem__c problem : problemforSME )
 {
 	for( Subject_Matter_Expert__c sme : SmeObj)
 	{
 		sme.CC1__c = problem.CC1__c;
 		sme.CC2__c = problem.CC2__c;
 		sme.CC3__c = problem.CC3__c;
 		sme.CC4__c = problem.CC4__c;
 		sme.CC5__c = problem.CC5__c;
 		sme.CC6__c = problem.CC6__c;
 		sme.unique_check__c = problem.Id+''+sme.User__c;
 	}
 	
 }
 
 }//if
	
}//try
catch(Exception e)
{
	SmeObj[0].addError('SME Already Exists !');
}
	
}//public static void addCCValuesFromTheParent()

}