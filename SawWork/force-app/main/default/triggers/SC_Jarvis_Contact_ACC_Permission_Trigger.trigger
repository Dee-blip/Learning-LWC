/*
Author          : Sharath
Description     : Trigger for Acc Permission Functionality JARVIS


Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
15 Mar 2021				Authors				 	    					  Initial Development
------------------------------------------------------------------------------------------------------------------
*/

trigger SC_Jarvis_Contact_ACC_Permission_Trigger on Jarvis_Contact_ACC_Permission__c (before insert, 
before update, 
before delete, 
after insert, 
after update, 
after delete, 
after undelete) 
{
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('Jarvis_Contact_ACC_Permission__c');
    }

}