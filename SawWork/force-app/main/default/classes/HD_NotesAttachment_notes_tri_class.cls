/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for Notes & attachemnt email
          
Usage : Used as an implementation for the business logic , for trigger HD_NotesAttachment_notes_tri.trigger
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_NotesAttachment_notes_tri.trigger
              
*/
public with sharing class HD_NotesAttachment_notes_tri_class 
{
//Global Variable access
static HD_NotesAttachment_notes_tri_class instance = null;
//Attachment Object
public  List<Note> noteList = new List<Note>();

//defining Private constructor as a part of singleton Pattern
private  HD_NotesAttachment_notes_tri_class( List<Note> noteAandAttachment)
{
    
    noteList.addAll(noteAandAttachment);
    
}//Constructor

//Singleton pattern 
public  static HD_NotesAttachment_notes_tri_class getInstance(List<Note> NewVersionAttchermentObject)
{
    if( instance == null)
    {
        instance = new HD_NotesAttachment_notes_tri_class(NewVersionAttchermentObject);
    }
    return instance;
}//


/*
* This method is used to Send email when Notes or attachment is added
*
*/
public static void EmailSender( List<Note> newTriggervaluefornote)
{   
    If( newTriggervaluefornote.size() > 0 )
    {
        
    String objectApiName = 'BMCServiceDesk__Problem__c';
    List<Note> note = new List<Note>();
    note = [Select Title,ParentId, parent.type From Note WHERE  parent.type =:objectApiName  AND  ParentId =:newTriggervaluefornote[0].ParentId  LIMIT 1];
    
    String[] toAddresses = new List<String>();
    String[] ccAddresses = new List<String>();
    Messaging.Singleemailmessage  mail = new Messaging.Singleemailmessage();// invoking mail class
    try{
    
    List<BMCServiceDesk__Problem__c> problemcc = new List<BMCServiceDesk__Problem__c>();
    problemcc = [ Select Name,Owner_Email__c, CC1__c, CC2__c, CC3__c, CC4__c, CC5__c, CC6__c From BMCServiceDesk__Problem__c WHERE Id =:newTriggervaluefornote[0].ParentId LIMIT 1  ]; 
    
    List<Subject_Matter_Expert__c> sme = new List<Subject_Matter_Expert__c>();
    sme = [Select   Name, Email__c From Subject_Matter_Expert__c s WHERE  Problem__c =: newTriggervaluefornote[0].ParentId LIMIT 100];
    String emailbody = null;
    String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+newTriggervaluefornote[0].ParentId ;
    if( problemcc.size() > 0 )
    {
    //Adding Problem Owner Email
    toAddresses.add( problemcc[0].Owner_Email__c );
    mail.setSubject('New Note has been added for Problem #'+problemcc[0].Name+' has been Added');
    //Construct Email body 
    emailbody = 'New Note has been added for Problem #<a href="'+recordLink +'">'+problemcc[0].Name +'</a> has been added.'; 
    emailbody += '<br>Details for Note:';
    emailbody += '<br>Title : '+newTriggervaluefornote[0].Title;
    emailbody += '<br>Marked As Private : '+newTriggervaluefornote[0].IsPrivate;
    emailbody += '<br>Click here to view :';
    emailbody +=  ''+recordLink;
    //starting Dynamic inputs

    emailbody +='<br></br>';
    //Changed as a part of CR 2610705 - Problem Mgmt - Email templates should be consistents
    //emailbody +='Sent from Apex Class for Notes & Attachment';
    //setting HTML BODY
    
    }//if( probowner.size() > 0 )

    
    //Adding email to an string array
if( problemcc.size() > 0 ||  sme.size() > 0 )
{
    for ( Subject_Matter_Expert__c smeemail : sme) 
    {
    toAddresses.add( smeemail.Email__c );
    }
}//if( sme.size() > 0 )

//Adding CCfields from Problem object
 if (problemcc.size() > 0)
    {
    for( BMCServiceDesk__Problem__c pro : problemcc )
    {
        System.debug('Getting Problem Cc ------->'+pro.CC1__c);
        
        if(pro.CC1__c != null )
        ccAddresses.add( pro.CC1__c );
        
        if(pro.CC2__c != null)
        ccAddresses.add( pro.CC2__c );
        
        if(pro.CC3__c != null)
        ccAddresses.add( pro.CC3__c );
        
        if(pro.CC4__c != null)
        ccAddresses.add( pro.CC4__c );
        
        if( pro.CC5__c != null)
        ccAddresses.add( pro.CC5__c );
        
        if(pro.CC6__c != null)
        ccAddresses.add( pro.CC6__c );
        
    }
    }//if (problemcc.size() > 0)
 
System.debug(' Getting List Value To Addresses ---------->  '+toAddresses);
System.debug(' Getting List Value Cc Fields ---------->  '+ccAddresses);

if ( toAddresses.size() > 0)
{   
//Setting email entities    
mail.setToAddresses(toAddresses);

//Setting CC Address
if(ccAddresses.size() > 0)
mail.setCcAddresses(ccAddresses);

//mail.setEmailPriority(pString)
mail.setHtmlBody( emailbody );
Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail}); 
}//if ( toAddresses.size() > 0)
    }// try
    
    Catch( Exception e)
    {
        newTriggervaluefornote[0].addError('Somethings Not right , the developemnt Team Has been Notified !');
    }

}// public void smeEmailSender

}//public static void EmailSender( List<Attachment> newTriggervalueforattachemnt)

    //Kartikeya- CR 2545230 -   Action history date/time to be made available for reporting
    public void updateIncident(){
     
       String recordTypeIdSI = [SELECT Id FROM RecordType where Name = 'Service Incident'].Id;
       List<Id> incident_ids = new List<Id>();
       for(Note note : noteList){
       
         if(note.ParentId.getSObjectType().getDescribe().getName() == 'BMCServiceDesk__Incident__c'){
           incident_ids.add(note.ParentId);
         
         }
       }
       
       if(incident_ids.size() > 0){
         //Pranav - CR 3461621 - Error Occurs - While adding Notes for closed or Cancelled Incidents 
         //added 'AND' condition in SOQL 'and BMCServiceDesk__state__c != false'
         List<BMCServiceDesk__Incident__c> incidents = [select Last_Updated_Date_Time__c,RecordTypeId,HD_Approval_Status__c from BMCServiceDesk__Incident__c where id IN :incident_ids and BMCServiceDesk__state__c != false];
         List<BMCServiceDesk__Incident__c> updateIncidents = new List<BMCServiceDesk__Incident__c>();
         for(BMCServiceDesk__Incident__c incident: incidents){
            //System.debug(' BHASKAR - '+incident.Name);
           if(incident.RecordTypeId != recordTypeIdSI && (incident.HD_Approval_Status__c != 'Approval Pending')){
            incident.Last_Updated_Date_Time__c = System.now();
            updateIncidents.add(incident);
           }
         }
          
         update updateIncidents;
      }
    
    }// End of UpdateIncident
    
    
    public void sendEisMessage(){

       List<Id> incident_ids = new List<Id>();
       for(Note note : noteList){
       
         if(note.ParentId.getSObjectType().getDescribe().getName() == 'BMCServiceDesk__Incident__c' ){
          incident_ids.add(note.ParentId);
         
         }
       } //for note
       
       if(incident_ids.size() > 0){
         
         MAP<ID,BMCServiceDesk__Incident__c> incidentMap = new MAP<ID,BMCServiceDesk__Incident__c>(
                            [select ID,Name,BMCServiceDesk__shortDescription__c,BMCServiceDesk__Category_ID__c,BMCServiceDesk__inc_console_detail_link__c,
                            dl_SysAdmin__c,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__incidentResolution__c
                            from BMCServiceDesk__Incident__c where id IN :incident_ids and HD_Notify_DL_EIS_on_Notes_Update__c = true] );
         
         if (incidentMap.size() > 0) {
    
           BMCServiceDesk__Incident__c inci = null;
           for(Note note : noteList){
                inci = incidentMap.get(note.parentId);
                
                if( inci != null && note.isPrivate != true){

                  Messaging.Singleemailmessage  mail = HD_IncidentUtils.NoteUpdatedEmail(note.title,note.body,note.LastModifiedDate, inci);
                  Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail});  
               
                }
           } //for note (2nd note loop)
         
        }// if incidentMap
         
      }//if incident_ids.size
    
    } // method sendEisMessage
  

}//Class End