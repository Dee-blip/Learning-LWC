/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for Tasks
          
Usage : Used as an implementation for the business logic , BMCServiceDesk__Task__c Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_Tasks_customization_tri_class.cls
              
*/
trigger HD_Tasks_customization_tri on BMCServiceDesk__Task__c (after insert, after update, before insert,before update) 
{
    
    //commented by ssawhney as the trigger is inactive
	/*if(Trigger.isBefore && trigger.isInsert)
    {


            HD_Tasks_customization_tri_class ins  = HD_Tasks_customization_tri_class.getInstance(trigger.new);
            ins.dataCopyproblemtoTask();
            

    }//if(Trigger.isBefore)
    */

}//End Of trigger