/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for SRM

Purpose : an Implemetation for Note & attachment Related List
          
Usage : Used as an implementation for the business logic , Note Object
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : 
* Modification Log ===============================================================
* Date 				      Author 				      Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
public with sharing class HD_Notes_Attachment_component_controller {

    public static String RecordId{get;set;}
    public List<NotesandAttachment> noteattachemntLIst{get;set;}
    
    //Constructor
    public List<NotesandAttachment> getNoteAttachment() {
     
     System.debug('--->ID '+RecordId);
     noteattachemntLIst = new List<NotesandAttachment>();       
    //Getting Notes
    List<note> noteLst = getNotesList(RecordId);
    if(noteLst.size() > 0 )
    {
      for(note nt:noteLst)
      {
        NotesandAttachment ntch = new NotesandAttachment();
        ntch.id = nt.id;
        ntch.type = 'Note';
        ntch.Title = nt.title;
        //getting USername
        ntch.CreatedBy = nt.createdBy.Name;
        
        ntch.LastModified= date.valueOf(nt.lastmodifieddate);        
        noteattachemntLIst.add(ntch);
      }//for
    }//if(noteLst.size() > 0 )
    
     List<attachment> attaLst = getAttachmentList(RecordId);
     if(attaLst.size() > 0 )
    {
      for(attachment nt:attaLst)
      {
        NotesandAttachment ntch = new NotesandAttachment();
        ntch.id = nt.id;
        ntch.type = 'Attachment';
        ntch.Title = '';
        //getting USername
        ntch.CreatedBy = nt.createdBy.Name;
        
        ntch.LastModified= date.valueOf(nt.lastmodifieddate);
        noteattachemntLIst.add(ntch);
      }//for
    }//if(attaLst.size() > 0 )
     
    return  noteattachemntLIst;   
    }//

    //getting Notes 
     private List<note> getNotesList(Id strid)
     {
        List<note> noteList = new List<note>();
        noteList = [select id, title, body,createdbyid, CreatedBy.Name,createdDate,lastmodifieddate from note where parentid=:strid];
        System.debug('----> '+noteList+' --FOR-->'+strid);
      return noteList;
     }//

     //getting Notes 
     private List<Attachment> getAttachmentList(Id strid)
     {
        List<Attachment> attachList = new List<Attachment>();
        attachList = [select id, Name, createdbyid, CreatedBy.Name,createdDate,lastmodifieddate from Attachment where parentid=:strid];
                System.debug('----> '+attachList+' --FOR-->'+strid);
      return attachList;
     }//
     
     //starting Fallback code for Action
     public String Idtobedeleted{get;set;}
     //creating Action for deleting the record
     public Pagereference deleteNote()
     { 
     try
     {
     if(Idtobedeleted != null)
     {
     System.Debug('Executing deleteNote() Action --->'+Idtobedeleted);
     Id ntacchId = Idtobedeleted;
     Schema.SObjectType objType = ntacchId.getSobjectType();
     if(String.valueof(objType) == 'Note')
     {
     Note nt = new Note();
     nt.Id = Idtobedeleted;
     delete nt;
     }
     else if(String.valueof(objType) == 'Attachment')
     {
     Attachment at = new Attachment();
     at.Id = Idtobedeleted;
     delete at;
     }//else
     
     }//if
     
     }//try
     catch(exception e)
     {
     System.debug('[]Exception: '+e.getMessage());
     }//catch
     
     return null;
     }

     public Pagereference refreshNotesAttachment()
     {
        try{
            getNoteAttachment();
        }
        
        catch(exception e)
        {
            System.debug('Something went Wrong!'+e.getMessage());
        }

        return null;
     }//refreshNotesAttachment

    //creating a wrapper Class for Notes and attchment 
    public class NotesandAttachment
    {   
        public id Id{get;set;}
        public String Type{get;set;}
        public String Title{get;set;}
        public String CreatedBy{get;set;}
        public Date LastModified{get;set;}

    }//wrappercalss
}