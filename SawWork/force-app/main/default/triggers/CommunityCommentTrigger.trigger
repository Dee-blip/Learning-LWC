/*
Author          : Sumukh SS/Sharath
Description     : Trigger for Community Comment Functionality JARVIS


Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
15 Mar 2021				Authors				 	    					  Initial Development
------------------------------------------------------------------------------------------------------------------
*/

trigger CommunityCommentTrigger on Community_Comments__c (before insert, 
  before update, 
  before delete, 
  after insert, 
  after update, 
  after delete, 
  after undelete) 
{

    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('Community_Comments__c');
    }
}