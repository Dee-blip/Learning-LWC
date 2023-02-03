/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Problem Managment Workaround

Purpose : TO notify all when ever new Workaround is added
          
Usage : used as  business logic , for problem managment Workaround Module
          
Test Class Asssociated : HD_Test_Problem_Workaround

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_Poblem_workaround_tri_class
              
*/

trigger HD_Poblem_workaround_tri on Problem_workaround__c (after insert, after update, before insert, 
before update) {

HD_Poblem_workaround_tri_class prbtri = null;
prbtri = HD_Poblem_workaround_tri_class.getInstance(trigger.new);

//problem Lis Ids
List<Id> ProbIds = new List<Id>();

if(trigger.isAfter) 
{
	if(trigger.isInsert)
	{  
		HD_Poblem_workaround_tri_class.EmailSender( HD_Poblem_workaround_tri_class.probWork ); 
	}
	
	//
	
	for( Problem_workaround__c wrk : trigger.new)
	{
		ProbIds.add(wrk.Problem__c );
	}
	
	if(ProbIds.size() > 0)
	HD_Poblem_workaround_tri_class.updateProblemStatustoWorkaroundIdentified(ProbIds); 
	
}//

}// End of trigger