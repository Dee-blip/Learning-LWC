/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for SME
          
Usage : Used as an implementation for the business logic , Subject_Matter_Expert__c Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_Subject_Matter_Expert_tri_Class.cls
              
*/

trigger HD_Subject_Matter_Expert_tri on Subject_Matter_Expert__c (before insert, before update) {

//Global Assignment 
public static HD_Subject_Matter_Expert_tri_Class smecls = null;

if( trigger.isBefore )
{
	
    Subject_Matter_Expert__c[] sme = trigger.new;
    smecls = HD_Subject_Matter_Expert_tri_Class.getInstance( sme );
	if(trigger.isInsert || trigger.isUpdate)
	{
			smecls.beforeEventProcess();  
	}

}





}//