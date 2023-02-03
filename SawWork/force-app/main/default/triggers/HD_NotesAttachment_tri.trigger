/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for Note & attachment Email
          
Usage : Used as an implementation for the business logic , Attachment Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_NotesAttachment_tri_class.cls
              
*/
trigger HD_NotesAttachment_tri on Attachment (after insert, after update, before insert, before update) {



String SobjectName;
Boolean probf = false;
Boolean incf = false;
for(Attachment tri:trigger.new)
{
  
  //getting Object Name from the RECORD ID
  SobjectName = tri.ParentId.getSObjectType().getDescribe().getName();
  if(SobjectName=='BMCServiceDesk__Problem__c')
  {
    probf=true;
  }
  else if(SobjectName=='BMCServiceDesk__Incident__c')
  {
    incf=true;
  }

}

  if( SobjectName == 'BMCServiceDesk__Problem__c' ||  SobjectName == 'BMCServiceDesk__Incident__c' )
  {
  System.debug('----------> Entering Problem Attachment Trigger');
    if(Trigger.isAfter)
    {
      
        HD_NotesAttachment_tri_class triclass = HD_NotesAttachment_tri_class.getInstance(trigger.new);
      
      if(Trigger.isInsert && probf)    
      {
        
        HD_NotesAttachment_tri_class.EmailSender( triclass.attachmentList ); 
        
      }//if(Trigger.isInsert) 
      
     //Kartikeya- CR 2545230 -     Action history date/time to be made available for reporting
      if(incf)
      {
        triclass.updateIncident(); 
      }   

    }//if(Trigger.isAfter)
  }//if( SobjectName == 'BMCServiceDesk__Problem__c' )


  
  

}//Trigger End