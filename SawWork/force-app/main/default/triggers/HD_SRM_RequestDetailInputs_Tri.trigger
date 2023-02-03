/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Encrypted field for HR system

Purpose : an Implementation for Masked and encrypted field
          
Usage : Used as an implementation for the business logic , RDI field encryption
          
Test Class Asssociated : NONE

Controller (Boolean): False 

Page Used/Asssociated (default -> NONE) : NONE

Class Associated :  HD_SRM_RequestDetailInputs_Tri_ctrl.cls
               
*/
trigger HD_SRM_RequestDetailInputs_Tri on BMCServiceDesk__SRM_RequestDetailInputs__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

//Instantiating the class
HD_SRM_RequestDetailInputs_Tri_ctrl srmRDI = null;
 List<BMCServiceDesk__SRM_RequestDetailInputs__c> ls = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
//checking with context varaible weather the triggerred event is befores
//
		
Map<ID,String> fidRvalue = new Map<Id,String>();
Map<Id,String> fidObjeMap = new Map<Id,String>();
Map<String,Set<String>> objectMeta = new Map<String,Set<String>>(); 
if( trigger.isBefore )
{
   if(trigger.isInsert)	
   {
        srmRDI = HD_SRM_RequestDetailInputs_Tri_ctrl.getInstance(trigger.new);
        srmRDI.securefiledData();
        //check for looksups
        HD_RequestDetailInput_Utils.initializeLookups(trigger.new);
       	//manipulate the seekers
       	HD_RequestDetailInput_Utils.manipulateSeekers(trigger.new);
       	HD_RequestDetailInput_Utils.firstRun = false;
   }//if(trigger.isInsert)	
	
}

}//END OF TRIGGER