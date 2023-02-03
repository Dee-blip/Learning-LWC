/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for Note & attachment Email
          
Usage : Used as an implementation for the business logic , Note Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_NotesAttachment_notes_tri_class.cls
              
*/
trigger HD_NotesAttachment_notes_tri on Note (after insert, after update, before insert,before update) 
{
    if(Trigger.isAfter  )
    {

    System.debug('KKKKK ');
      HD_NotesAttachment_notes_tri_class triclass = HD_NotesAttachment_notes_tri_class.getInstance(trigger.new);
      if(Trigger.isInsert){
        HD_NotesAttachment_notes_tri_class.EmailSender( triclass.noteList ); 
      }
    
      //Kartikeya- CR 2545230 -  Action history date/time to be made available for reporting
      triclass.updateIncident();
      triclass.sendEisMessage();
    }//if(Trigger.isAfter)

  

}//Trigger End