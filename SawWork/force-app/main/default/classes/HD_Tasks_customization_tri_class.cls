/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for Tasks
          
Usage : Used as an implementation for the business logic , for trigger HD_Tasks_customization_tri.trigger
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Tasks_customization_tri.trigger
              
*/


public with sharing class HD_Tasks_customization_tri_class 
{
	
//Global variables
public static 	HD_Tasks_customization_tri_class instance = null;
public static  List<BMCServiceDesk__Task__c> taskList = null;
public static  List<BMCServiceDesk__Task__c> oldTaskList = null;

//defining Contructor for Insert 
private HD_Tasks_customization_tri_class(List<BMCServiceDesk__Task__c> newVersionTaskObject )
{
	taskList = new List<BMCServiceDesk__Task__c>();
	taskList.addAll(newVersionTaskObject);
	
}//Constructor End
/*
//defining Contructor for Insert  & Update with new & old version of object
private HD_Tasks_customization_tri_class(List<BMCServiceDesk__Task__c> newVersionTaskObject , List<BMCServiceDesk__Task__c> oldVersionTaskObject )
{
	taskList = new List<BMCServiceDesk__Task__c>();
	OldTaskList = new List<BMCServiceDesk__Task__c>();
	TaskList.addAll(newVersionTaskObject);
	OldTaskList.addAll(oldVersionTaskObject);
	
}//Constructor End

*/
//creating static method for Singleton Pattern for Insert & update with new version only
public static  HD_Tasks_customization_tri_class getInstance(BMCServiceDesk__Task__c[] newVersionTriggerObject)
{
	
	if( instance == null )
	{
		instance = new HD_Tasks_customization_tri_class(newVersionTriggerObject);
	}
	 
	
	return instance;
}//

/*
//creating static method for Singleton Pattern for Insert and Update Old and new version
public static  HD_Tasks_customization_tri_class getInstance(BMCServiceDesk__Task__c[] newVersionTriggerObject,BMCServiceDesk__Task__c[] oldVersionTriggerObject)
{
	
	if( instance == null )
	{
		instance = new HD_Tasks_customization_tri_class(newVersionTriggerObject,oldVersionTriggerObject);
	}
	 
	
	return instance;
}//
*/
//creating method for data-copy from problem to Tasks, use this function when you need to copy certain field during problem-task creation
// Use it during Insert
public void dataCopyproblemtoTask()
{

   //creating list for problem record	
   List<BMCServiceDesk__Problem__c> probList = new List<BMCServiceDesk__Problem__c>();
   //creating a List for the prob Ids from a task
   List<Id> probid =new List<Id>();
   for(BMCServiceDesk__Task__c tsk : taskList)
   {
   	probid.add( tsk.BMCServiceDesk__FKProblem__c );
   }
   
	if( taskList.size() > 0 && probid.size() > 0)
	{
	probList = [ Select BMCServiceDesk__FKCategory__c From BMCServiceDesk__Problem__c WHERE Id IN:probid LIMIT 1 ];
	for(BMCServiceDesk__Task__c bmctask :taskList  )
	{
		if( bmctask.BMCServiceDesk__FKProblem__c  != null)
		{
			for( BMCServiceDesk__Problem__c pr :  probList) 
			{
			bmctask.BMCServiceDesk__FKCategory__c = pr.BMCServiceDesk__FKCategory__c;
			bmctask.RecordTypeId = Schema.SObjectType.BMCServiceDesk__Task__c.getRecordTypeInfosByName().get('Problems Task').getRecordTypeId();
			if(bmctask.BMCServiceDesk__FKClient__c == null)  
			bmctask.BMCServiceDesk__FKClient__c = bmctask.OwnerId;
			}//for problem
			
		}//if( bmctask.BMCServiceDesk__FKProblem__c  != null) 
		
	}//for
		
	}//if

	
}//


}//End of class