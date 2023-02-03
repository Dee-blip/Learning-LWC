/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Change Request Managment

Purpose : an Implemetation for CRM
          
Usage : Used as an implementation for the business logic , Change request Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_ChangeReqMgmt_class.cls
              
*/

trigger HD_ChangeReqMgmt on BMCServiceDesk__Change_Request__c (Before Insert,after insert,Before Update,after update) 
{


   

//use this for before logics
if(trigger.isBefore)
{
    
   
    HD_ChangeReqMgmt_class changereqMgmt;
    


    //Service Outaegs with enhanced review period and Conditional Blackouts
    List<HD_Instance__mdt> blackoutsetting = new List<HD_Instance__mdt>();
    blackoutsetting = [SELECT instanceName__c from HD_Instance__mdt where DeveloperName = 'Blackout_Second_Level_Approval' Limit 1];
    Boolean runBlackout = true;
    if( blackoutsetting != null && blackoutsetting.size() >  0 && blackoutsetting[0].instanceName__c != null && blackoutsetting[0].instanceName__c == 'false'){
       runBlackout = false;
    }

    if( runBlackout){
      List<BMCServiceDesk__Change_Request__c> oldChanges = new List<BMCServiceDesk__Change_Request__c>();
      if(trigger.isUpdate){
        oldChanges = Trigger.old;
      }
      HD_CMR_BlackoutPeriod.matchCMRWithServiceOutage(Trigger.new,oldChanges); 
    }
    //settting the initial value
    if( trigger.isInsert)
    {   changereqMgmt = HD_ChangeReqMgmt_class.getInstance(trigger.new);
        changereqMgmt.InitialSaveDataSetter();
        
    } 
    
     
    
    if (trigger.isUpdate){
         
       changereqMgmt = HD_ChangeReqMgmt_class.getInstance( trigger.new,trigger.old);
       //Removing lock functionality as per PRTORES-1176
       //changereqMgmt.verifyLockedCMRUpdate();

       changereqMgmt.validateSchedulestartDateSponsorAppr();
        
        
       
       
      // changereqMgmt.PicklistToLookup('HD_Change_Impact__c','BMCServiceDesk__FKImpact__c','BMCServiceDesk__Impact__c','Impact');
      // changereqMgmt.PicklistToLookup('HD_Change_Urgency__c','BMCServiceDesk__FKUrgency__c','BMCServiceDesk__Urgency__c','Urgency');
      // changereqMgmt.setPriority();
  
    
    }
    changereqMgmt.verifyResourceEmail();
    changereqMgmt.verifyNotificationEmail();
    changereqMgmt.PicklistToLookup('HD_Change_Status__c','BMCServiceDesk__FKStatus__c','BMCServiceDesk__Status__c','Status');

}//

if(trigger.isAfter)
{
   HD_ChangeReqMgmt_class changereqMgmt;

  if(trigger.isInsert){
     changereqMgmt = HD_ChangeReqMgmt_class.getInstance( trigger.new);
     //insertInstant.editableAccessSponsor();
     
  
  }//isInsert

  if (trigger.isUpdate){
     changereqMgmt = HD_ChangeReqMgmt_class.getInstance( trigger.new,trigger.old);
    //changereqMgmt.sendEmailToRelatedListUser();  
    //changereqMgmt.sendResourceEmail();
    //changereqMgmt.editableAccessSponsor();
    //check if custom setting exists
    
    Boolean isdataLoad = false;
    HD_DataLoad__c   cr = HD_DataLoad__c.getInstance('Change Request');
    if(cr !=null){
        if(cr.Data_Load_Activity__c == true){
            isdataLoad = true;
        }
    }
    
    //if not dataLoad send email  
      if(!isdataLoad){
         changereqMgmt.sendNotification(); 
      } 
    	
    
    
   }
   
   changereqMgmt.grantEditableAccess();
 }//isAfter


}