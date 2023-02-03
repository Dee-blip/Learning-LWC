/*
* File Name: HD_IncidentDetailController
* Description : Controller class for the Incident details screen
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Dec 12th, 2019	Aneesh Budnar			PRTORES - 1518 - Added from addresses to the From Dropdown by reading from Email conversion settings
*/
public with sharing class  HD_IncidentDetailController {
    //comment this
    /*
    @AuraEnabled
    public static List<BMCServiceDesk__Incident__c> getIncidents() {
        return [Select Id, Name, BMCServiceDesk__IncidentType__c ,OwnerId, HD_Ticket_Priority__c ,BMCServiceDesk__Category_ID__c From BMCServiceDesk__Incident__c];
    }
    */
    //public static Datetime systemStartTime ;
    private static Map<String,BMCServiceDesk__Status__c> statusListMap = new Map<String,BMCServiceDesk__Status__c>() ;
    
    static
    {
        
        for(BMCServiceDesk__Status__c status: [select Id,Name from BMCServiceDesk__Status__c limit 1000])
          {
            statusListMap.put(status.Name,status);
          }
    }
    //wrapper class
    public class Data{

        @AuraEnabled
        public String summary;
        @AuraEnabled
        public String resolution;
        @AuraEnabled
        public String username;
        @AuraEnabled
        public String owner;
        @AuraEnabled
        public String testValue;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String requestTitle;
        @AuraEnabled
        public String shortDescription;
        public Data(){
            this.summary = 'test summary';
            this.resolution = 'test resolution';
            this.username  = 'kahegde@akamai.com';
            this.owner = 'Triage';
            this.testValue = null;
            this.type = 'Incident';
            this.name = '00273004';
            this.requestTitle = 'test title';
            this.shortDescription = 'test short description';
        }
    }
    
    public class IncidentAndOptions {
      @AuraEnabled  
      public  BMCServiceDesk__incident__c incident = new BMCServiceDesk__incident__c();
      @AuraEnabled
      public  MAP<String,String>  OptionValues = new MAP<String,String>();
      @AuraEnabled  
      public  String selectedOpt;  
        
    }
    
    
    @AuraEnabled
    public static Data getTicketDetails(String recordId){
        return HD_DetailControllerUtils.getTicketDetails(recordId);
    }
    
    @AuraEnabled
    public static Map<String,String> getClientInfo(String recordId) {
        return HD_DetailControllerUtils.getClientInfo(recordId);
    }

    @AuraEnabled
    public static BMCServiceDesk__Incident__c updateOwner(String recordId,String ownerId)
    {
        try
        {
            
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.id = recordId;
        if(ownerId == null)
        {
            inc.OwnerId = System.Userinfo.getUserId();
            
        }
        else
        {
            inc.OwnerId = ownerId;
        }
        inc.BMCServiceDesk__FKStatus__c = statusListMap.get('ASSIGNED').Id ;
        update inc;
        System.debug(inc);
        return inc;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage());
            //return null;
        }
    }
    
    @AuraEnabled
    public static List<BMCServiceDesk__Task__c> getOpenTasks(String recordId)
    {
        return [SELECT Id, BMCServiceDesk__FKStatus__c FROM BMCServiceDesk__Task__c WHERE BMCServiceDesk__Status_ID__c != 'CLOSED' AND BMCServiceDesk__FKIncident__c  = :recordId ];
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c addResolution(String recordId, String resolution, String effortEstimate, String closeTasks)
    {
        try{
            BMCServiceDesk__Incident__c inc;
            inc = [select BMCServiceDesk__FKClient__r.username, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__incidentResolution__c, BMCServiceDesk__FKStatus__c, Effort_Estimation__c, BMCServiceDesk__closeTasks__c  from bmcservicedesk__incident__c where id = :recordId];
            inc.BMCServiceDesk__incidentResolution__c = resolution;
            inc.Effort_Estimation__c = effortEstimate;
            if(!String.isEmpty(closeTasks)) {
            	inc.BMCServiceDesk__closeTasks__c = Boolean.valueOf(closeTasks);
            }
            inc.BMCServiceDesk__FKStatus__c = statusListMap.get('RESOLVED').Id ;
            System.debug('BMCServiceDesk__FKStatus__c  '+inc.BMCServiceDesk__FKStatus__c );
            System.debug('Effort_Estimation__c  '+inc.Effort_Estimation__c);
            System.debug('inc:'+inc);
            update inc;  
            System.debug('resolution '+inc);
            return inc;
        }catch(Exception e){
             throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c closeIncident(String recordId, String resolution, String effortEstimate)
    {
        try{
            BMCServiceDesk__Incident__c inc;
            inc = [select BMCServiceDesk__FKClient__r.username, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__incidentResolution__c, BMCServiceDesk__FKStatus__c, Effort_Estimation__c  from bmcservicedesk__incident__c where id = :recordId];
            inc.BMCServiceDesk__incidentResolution__c = resolution;
            inc.Effort_Estimation__c = effortEstimate;
            inc.BMCServiceDesk__FKStatus__c = statusListMap.get('CLOSED').Id ;
            System.debug('BMCServiceDesk__FKStatus__c  '+inc.BMCServiceDesk__FKStatus__c );
            System.debug('Effort_Estimation__c  '+inc.Effort_Estimation__c);
            System.debug('inc:'+inc);
            update inc;
            System.debug('resolution '+inc);
            return inc;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
 
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c transferIncident(String recordId,String queueName,String duration,String addedNote, String categoryId){
        try{
            System.debug('User info'+System.Userinfo.getUserId());
            BMCServiceDesk__Incident__c inc = [Select OwnerId, HD_OwnerLocked__c,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKCategory__c from BMCServiceDesk__Incident__c where Id = :recordId];
            //BMCServiceDesk__Incident__c inc = record;
            //Group newQueue = [Select Id, Name from Group where Type = 'Queue' and Name = :queueName LIMIT 1];
            Id queueId = (Id)queueName;
            System.debug('inc owner'+inc.OwnerId);
            System.debug('Queue Id:'+queueId);
            System.debug('Category Id:'+categoryId);
            if(categoryId != '' && categoryId != null && categoryId != inc.BMCServiceDesk__FKCategory__c ){
               id catId = (Id)categoryId;
                inc.BMCServiceDesk__FKCategory__c = catId;
            }
            inc.HD_Routing_Settings__c = 'Override Routing';
            //
            if(queueId == null)
            {
                //return;
                
                inc.OwnerId = System.Userinfo.getUserId();
            }
            else
            {
                 inc.HD_OwnerLocked__c=false;
                inc.OwnerId = queueId; 
                //inc.BMCServiceDesk__FKStatus__c = 'a6bR000000092H4';//replace this, get ID with query
            }
       
            BMCServiceDesk__IncidentHistory__c currentNote = new BMCServiceDesk__IncidentHistory__c();
            currentNote.BMCServiceDesk__FKIncident__c=inc.Id;
            currentNote.BMCServiceDesk__FKUser__c=System.Userinfo.getUserId();
            currentNote.BMCServiceDesk__duration__c=duration;
            currentNote.BMCServiceDesk__description__c='Notes';
            currentNote.BMCServiceDesk__note__c=addedNote;
            BMCServiceDesk__Action__c actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'ESCALATION_NOTE' LIMIT 1];
            currentNote.BMCServiceDesk__FKAction__c=actionList.Id;
            currentNote.HD_Action__c='ESCALATION_NOTE';
            System.debug('Current note: '+currentNote);
            insert currentNote;
    
            update inc;
            System.debug('Incident in controller: '+inc);
            //inc.HD_OwnerLocked__c=true;
            //update inc;
            return inc;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static Map<String,Id> getAllQueues(){
        //List<Group> allIncQueues = [Select Id, Name from Group g where g.Id IN (SELECT QueueId FROM QueueSobject where SobjectType = 'BMCServiceDesk__Incident__c')]; //filter by name for deprecated
        List<Group> allIncQueues = [Select Id, Name from Group g where (NOT(Name like '%deprecated%' or Name like '%DONOTUSE%')) and g.Id IN (SELECT QueueId FROM QueueSobject where SobjectType = 'BMCServiceDesk__Incident__c')];
        Map<String,Id> queueMap = new Map<String,Id>();
        for(Group queue : allIncQueues ){
            queueMap.put(queue.Name, queue.Id);
        }
        return queueMap;
    }
    
    
    
    /*
    @AuraEnabled
    public static Map<String, Id> getAllStaffs(){
        List<User> staffUsers = [Select ID, name from User where IsActive=true and BMCServiceDesk__IsStaffUser__c=true order by name asc]; 
        Map<String,Id> staffUsersMap = new Map<String,Id>();
        for(User u : staffUsers){
            staffUsersMap.put(u.name,u.id);
        }
        return staffUsersMap;
    }*/
    //remove this --
    //this functio is in user, renaming is required
    @AuraEnabled
    public static List<User> getAllStaffs(){
        List<User> staffUsers = [Select ID, name, Email  from User where IsActive=true and BMCServiceDesk__IsStaffUser__c=true order by name asc]; 
        
        return staffUsers;
    }
    
    
     @AuraEnabled
    public static Map<String,Id> getAllCategories(){
        List<BMCServiceDesk__Category__c> catList = [Select ID,Name, BMCServiceDesk__parentTree__c  ,BMCServiceDesk__AvailableForIncidents__c, BMCServiceDesk__inactive__c FROM BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c = true and BMCServiceDesk__inactive__c = false];
        System.debug('catList: '+catList);
        Map<String,Id> catMap = new Map<String,Id>();
        for(BMCServiceDesk__Category__c cat : catList ){
            System.debug('Catgeory: '+cat.Name+'--->'+cat.Id);
            catMap.put(cat.Name+':::'+cat.BMCServiceDesk__parentTree__c, cat.Id);
        }
        System.debug('catMap: '+catMap);
        return catMap;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c changeCategory(String incidentId,String categoryName){
        try{
        System.debug('In controller change category');
        BMCServiceDesk__Incident__c inc = [Select Id,OwnerId,BMCServiceDesk__FKCategory__c, BMCServiceDesk__Category_ID__c  from BMCServiceDesk__Incident__c where Id = :incidentId];
        //Group newQueue = [Select Id, Name from Group where Type = 'Queue' and Name = :queueName LIMIT 1];
        Id catId1 = (Id)categoryName;
        System.debug('old category'+inc.BMCServiceDesk__FKCategory__c+'-->'+inc.BMCServiceDesk__Category_ID__c);
        System.debug('new category:'+catId1);
        if(catId1 != null)
        {
            inc.HD_Routing_Settings__c = 'Default Routing';
            inc.BMCServiceDesk__FKCategory__c = catId1;
            update inc;
            
        }
        System.debug('Incident in controller: '+inc);
        return inc;
         }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c changePriority(Id incidentId,String priority, Boolean pageSupportValue){
        try{
        BMCServiceDesk__Incident__c inc = [Select Id,Name,HD_Ticket_Priority__c,HD_High_Customer_Impact__c,BMCServiceDesk__FKUrgency__c  from BMCServiceDesk__Incident__c where Id = :incidentId];
        //replace this
        HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(priority);
        inc.HD_Ticket_Priority__c = priority;
        //inc.HD_High_Customer_Impact__c = pageSupportValue;
        if(inc.HD_Ticket_Priority__c == '1'){
            BMCServiceDesk__Urgency__c sev1Urgency = [Select Id, Name from BMCServiceDesk__Urgency__c where Name = 'Severity 1' LIMIT 1];
            inc.BMCServiceDesk__FKUrgency__c  = sev1Urgency.Id;
            inc.HD_High_Customer_Impact__c = true;
        }
        else{
            inc.HD_High_Customer_Impact__c = false;
        }
        update inc;
        return inc;
             }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    /*@author: Nikhil Karn
     *@desc: This method is to update or mark the incident as system admin incident
     *@creationDate:09/01/2018
     *@lastModifiedDate:09/01/2018
     *@lsatModifiedBy: Nikhil Karn
     * */
     @AuraEnabled
    public static BMCServiceDesk__Incident__c convertIncidentToSysAdminIncident(Id incidentId,Boolean uiSbi,Boolean dlEIS,Boolean ntfyCreation,Boolean ntfyStatus,Boolean ntfyNotes,Boolean whitehatincid){
        
        System.debug('Inside convertIncidentToSysAdminIncident method------>>>');
        try{
            
            BMCServiceDesk__Incident__c inc = [Select Id,Name,HD_System_Admin_Incident__c ,Notify_dl_sysadmin_on_creation__c ,HD_Notify_DL_EIS_on_Notes_Update__c ,Notify_dl_sysadmin_on_status_change__c ,HD_WhiteHat_Incident__c   from BMCServiceDesk__Incident__c where Id = :incidentId];
            System.debug('Queried Incident inside convertIncidentToSysAdminIncident method:'+inc);
            inc.HD_System_Admin_Incident__c = uiSbi;
            inc.Notify_dl_sysadmin_on_creation__c = ntfyCreation;
            inc.HD_Notify_DL_EIS_on_Notes_Update__c = ntfyNotes;
            inc.Notify_dl_sysadmin_on_status_change__c = ntfyStatus;
            inc.HD_WhiteHat_Incident__c = whitehatincid;
            
    
            update inc;
            return inc;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
                
     @AuraEnabled
    public static Boolean getPageSupport(Id incidentId){
        return HD_DetailControllerUtils.getPageSupport(incidentId);
        }
        
    @AuraEnabled 
    public static List<BMCServiceDesk__Incident__c>  getIncidentRecords(Id IncId,String ticketNumber){
       return HD_DetailControllerUtils.getIncidentRecords(IncId,ticketNumber);
    }
    
    @AuraEnabled
    public static void linkIncidents2(Id incidentId,List<Id> linkToIds)
    {
        try
        {
            List<BMCServiceDesk__Incident__c> linkTo = [select BMCServiceDesk__FKIncident__c from BMCServiceDesk__Incident__c where Id in :linkToIds];
            System.debug('linkTo '+linkTo);
            List<BMCServiceDesk__Incident__c> updatedIncList = new List<BMCServiceDesk__Incident__c>();
            System.debug('!!');
            for(BMCServiceDesk__Incident__c linkToInc : linkTo)
            {
                linkToInc.BMCServiceDesk__FKIncident__c = incidentId;
                updatedIncList.add(linkToInc);
            }
            System.debug('updatedIncList'+updatedIncList);
             update updatedIncList;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage()); 
        }
         
    }

    
     
    @AuraEnabled
    public static String getIncType(Id incId){
        return HD_DetailControllerUtils.getIncType(incId);
    }
    
    //add try-catch
    @AuraEnabled
    public static BMCServiceDesk__Incident__c holdTicket(Id incidentId,String status, String holdnote){
        try{
            System.debug('In holdTicket');
            BMCServiceDesk__Incident__c inc = [Select Id, BMCServiceDesk__FKStatus__c, HD_HoldNote__c from BMCServiceDesk__Incident__c where Id =:incidentId LIMIT 1];
            BMCServiceDesk__Status__c statusObj = [Select Id, Name from BMCServiceDesk__Status__c where Name =: status LIMIT 1];
            System.debug('Status ID: '+statusObj.Id);
            inc.BMCServiceDesk__FKStatus__c = statusObj.Id;
            inc.HD_HoldNote__c = holdnote;
            update inc;
            return inc;
          }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
          }
    }
    
    //add try-catch
    @AuraEnabled
    public static Id addClientNote(Id incidentID, String note){
      try{
            BMCServiceDesk__Action__c actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'CLIENT_NOTE' LIMIT 1];
            BMCServiceDesk__IncidentHistory__c currentNote = new BMCServiceDesk__IncidentHistory__c();
            currentNote.BMCServiceDesk__FKIncident__c=incidentID;
            currentNote.BMCServiceDesk__FKUser__c=System.Userinfo.getUserId();
            //currentNote.BMCServiceDesk__duration__c=duration;
            currentNote.BMCServiceDesk__description__c='Client Notes';
            currentNote.BMCServiceDesk__note__c=note;
            currentNote.BMCServiceDesk__FKAction__c=actionList.Id;
            currentNote.HD_Action__c='CLIENT_NOTE';
            System.debug('Current note: '+currentNote);
            insert currentNote;
            return currentNote.id;
         }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
          }   
    }
    
    @AuraEnabled
    public static List<EmailTemplate> getEmailTemplates(){
     List<EmailTemplate> temp = [SELECT Id, Name, FolderId, Folder.DeveloperName,Markup,Subject
            FROM EmailTemplate where (Folder.DeveloperName ='SDE_Emails' or Folder.DeveloperName like 'HD_%') and TemplateType = 'visualforce' order by Name];
     List<EmailTemplate> templates = new List<EmailTemplate>();
        for(EmailTemplate t: temp)
        {
            
            if(t.Markup.deleteWhitespace().containsIgnoreCase('relatedToType=\"BMCServiceDesk__Incident__c\"'))
            {
                templates.add(t);
            }
        } 
     return templates;
    }
    
    @AuraEnabled
    public static void saveFile(Id incId, String fileName, String base64Data, String contentType) { 
        
        System.debug('In controller save file');
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        System.debug('base64Data'+base64Data);
 
        
    }
    
    public class fileClass
    {
        public String fileName;
        public String fileType;
        public String fileContents;
    }
 
    @AuraEnabled
    public static void sendEmailNew(
        Id incidentId,
        String[] fromAddress,
        String[] toAddresses,
        String[] ccAddresses,
        String[] bccAddresses,
        String templateId,
        String subject,
        String body,
        List<String> documentId,
        List<String> fileName){
     try
     {
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail; 
        objEmail = new Messaging.Singleemailmessage();
        System.debug('template'+templateId);
        Messaging.Emailfileattachment attach = new Messaging.Emailfileattachment();
        
        if(String.isBlank(templateId))
        {
           objEmail.setSubject(subject);
           objEmail.setPlainTextBody(body);
           objEmail.setHtmlBody('<pre style="font-family:Arial;">'+body+'</pre>');           
        }
        else
        {
           Id recipient = [select Id from User where email =:toAddresses[0]  order by name desc limit 1].Id;
           objEmail.setTemplateId(templateId);
           
           objEmail.setTargetObjectId(recipient);
           objEmail.setSaveAsActivity(false) ;
           objEmail.setWhatId(incidentId);

            BMCServiceDesk__Incident__c inc =  [Select Id, BMCServiceDesk__Additional_email_information__c  From BMCServiceDesk__Incident__c where ID = :incidentId LIMIT 1];
                
           if(inc.BMCServiceDesk__Additional_email_information__c != body)
           {
               System.debug('incId  Body'+body);
                inc.BMCServiceDesk__Additional_email_information__c = body;
                update inc;
           }
           
           
        }
         
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
         
        List <ContentVersion> cntVer= [SELECT Id, ContentBodyId, VersionData FROM ContentVersion where ContentDocumentId in :documentId AND IsLatest = true];

        for (Integer i=0;i<cntVer.size();i++)
        {
          Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
          efa.setFileName(fileName[i]);
          efa.setBody(cntVer[i].VersionData);
          fileAttachments.add(efa);
        }
        objEmail.setFileAttachments(fileAttachments);
         Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandBox;
        //Demo
        // String address = 'bmcsd_emailconversationlistener@f-2kwei1xf6xs0m6j26p69qzm95y6qfzk0eg9wjl3yd96x0ij06l.0s-cpfxuak.cs54.apex.sandbox.salesforce.com';
        //Prod 
        //String address = 'akamaihd-tix@akamai.com';
        //QA
        // String address = 'bmcsd_emailconversationlistener@l-1jbyudbld6hpy2o1gecjn2uj6iw0465a72m7jrvvi3r9d2ww42.5b-scyuam.cs52.apex.sandbox.salesforce.com';
       String address;
        if(isSandbox)
        { 
            address = [SELECT Id, SettingValue__c FROM HD_Instance__mdt WHERE DeveloperName = 'Sandbox_EmailConversationListener' LIMIT 1].SettingValue__c;  // PRTORES-2290 HD send email component configurable in sandboxes  
        }
         else
         {
             address = 'akamaihd-tix@akamai.com';
         }
         ccAddresses.add(address);
         if(fromAddress != null && fromAddress.size() > 0) {
             List<OrgWideEmailAddress> orgWideAdd = [select Id from OrgWideEmailAddress where Address = :fromAddress[0]];
             if(orgWideAdd != null && orgWideAdd.size() > 0) {
                objEmail.setOrgWideEmailAddressId(orgWideAdd[0].Id);
             }
         }
         
         objEmail.setToAddresses(toAddresses);
         objEmail.setccAddresses(ccAddresses);
         objEmail.setBccAddresses(bccAddresses);
            
         mailsToBeSent.add(objEmail);
         Messaging.sendEmail(mailsToBeSent,false);
     }
        
        catch(Exception e)
        {
            
                throw new AuraHandledException(e.getMessage());

            
            
        }
    }
    
    /*@AuraEnabled
    public static void reopenTicketTwoStepClose(Id incId){
        BMCServiceDesk__Incident__c  incident = [select id, name, BMCServiceDesk__FKStatus__c,BMCServiceDesk__Status_ID__c, Effort_Estimation__c from BMCServiceDesk__Incident__c where id = :incId];
        if(incident.BMCServiceDesk__Status_ID__c == 'RESOLVED'){
            List<BMCServiceDesk__Status__c> statusList = [select Id,name from BMCServiceDesk__Status__c];
            Map<String,BMCServiceDesk__Status__c> statusMap = new Map<String,BMCServiceDesk__Status__c>();
            for(BMCServiceDesk__Status__c status : statusList ){
                statusMap.put(status.name, status);
            }
            
            
            //BMCServiceDesk__Incident__c incident =  new BMCServiceDesk__Incident__c();
            //incident.id = incId;
            incident.BMCServiceDesk__FKStatus__c = statusMap.get('REOPENED').id;
            incident.Effort_Estimation__c = null;   
            update incident;
        }else{
            return;
        } 
    }*/
    
    /*@AuraEnabled
    public static void reopenTicketDefault(Id incId){
        BMCServiceDesk__Incident__c  incident = [select id, name, BMCServiceDesk__FKStatus__c,BMCServiceDesk__Status_ID__c, Effort_Estimation__c from BMCServiceDesk__Incident__c where id = :incId];
        if(incident.BMCServiceDesk__Status_ID__c == 'CLOSED' || incident.BMCServiceDesk__Status_ID__c == 'CANCELED' ){
            List<BMCServiceDesk__Status__c> statusList = [select Id,name from BMCServiceDesk__Status__c];
            Map<String,BMCServiceDesk__Status__c> statusMap = new Map<String,BMCServiceDesk__Status__c>();
            for(BMCServiceDesk__Status__c status : statusList ){
                statusMap.put(status.name, status);
            }
            
            
            //BMCServiceDesk__Incident__c incident =  new BMCServiceDesk__Incident__c();
            //incident.id = incId;
            incident.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
            incident.Effort_Estimation__c = null;   
            update incident;
        }else{
            return;
        } 
    }*/
    
    @AuraEnabled
    public static void reopenTicket(ID incId){
        try{
            BMCServiceDesk__Incident__c  incident = [select id, name, BMCServiceDesk__FKStatus__c,BMCServiceDesk__Status_ID__c, Effort_Estimation__c from BMCServiceDesk__Incident__c where id = :incId];
            List<BMCServiceDesk__Status__c> statusList = [select Id,name from BMCServiceDesk__Status__c LIMIT 500];
            Map<String,BMCServiceDesk__Status__c> statusMap = new Map<String,BMCServiceDesk__Status__c>();
            for(BMCServiceDesk__Status__c status : statusList ){
                statusMap.put(status.name, status);
            }
            if(incident.BMCServiceDesk__Status_ID__c == 'CLOSED' || incident.BMCServiceDesk__Status_ID__c == 'CANCELED' ){
                incident.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
            }else if(incident.BMCServiceDesk__Status_ID__c == 'RESOLVED'){
                incident.BMCServiceDesk__FKStatus__c = statusMap.get('REOPENED').id;
            }else{
                return;
            } 
            incident.Effort_Estimation__c = null;   
            update incident;
        }catch(Exception e){
             throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static String addChangeApprover(String incidentId, String approverId){
        try{
           Id incId = (ID)incidentId;
            if(approverId == null){
                throw new AuraHandledException('No Approver Selected');
            }
            Id appId = (ID)approverId;
            BMCServicedesk__Incident__c inc = [select id, Approver__c from bmcservicedesk__incident__c where id = :incId];
            inc.Approver__c = appId;
            update inc;
            return 'Success'; 
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*@AuraEnabled
    public static List<User> allApprovers(){
      
        List<User> staffUsers = [Select ID, name, Email  from User where IsActive=true and BMCServiceDesk__IsStaffUser__c=true order by name asc]; 
        
        return staffUsers;
    }*/
    @AuraEnabled
    public static List<User> allApproversSearch(String param){
        
        String pattern = '%'+ param + '%';      
        List<User> staffUsers = [Select ID, name, Email  from User where (name like :pattern or email like :pattern) and IsActive=true  order by name asc limit 20]; 
        
        return staffUsers;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c getCurrentApprover(ID incidentId){
        return HD_DetailControllerUtils.getCurrentApprover(incidentId);
    }
    
    @AuraEnabled
    public static String submitForApproval(ID incidentId, String comment){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(comment);
        req1.setObjectId(incidentID);
        req1.setSubmitterId(UserInfo.getUserId());
        try{
            Approval.ProcessResult result =  Approval.process(req1);
            if(result.isSuccess())
            {
                return 'isSuccess';
            }else {
                return 'isFailure';
            }
        }catch(Exception e){
            System.debug(e.getMessage());
            //System.debug(e.getTypeName());
            return e.getMessage();
        }
        
    }
    @AuraEnabled
    public static void recallForApproval(ID incidentId, String comment){
        ProcessInstanceWorkitem[] workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :incidentId 
                                               AND ProcessInstance.Status = 'Pending'];
        if(workItems.size() == 0){
            throw new AuraHandledException('No Approvals to Recall');
        }
        try{
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Removed');
            pwr.setWorkItemId(workItems[0].id);
            Approval.ProcessResult result = Approval.process(pwr);
        }catch(Exception e){
            throw new AuraHandledException('Only Submitters can Recall Approvals');
        }
        
    }
    
    
    
    @AuraEnabled
    public static List<ProcessInstanceWorkitem> getPendingApprovals(ID incidentId){
        try
        {
            ProcessInstanceWorkitem[] workItems = [SELECT Id,Actor.name,CreatedBy.Name,CreatedDate FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :incidentId 
                                             AND ProcessInstance.Status = 'Pending'];
            System.debug('workItems'+workItems);
            return workItems;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c getIncident(String incidentId){
       return HD_DetailControllerUtils.getIncident(incidentId);
    }
      

    @AuraEnabled
    public static IncidentAndOptions getIncidentWithPriority(String incidentId){
       return HD_DetailControllerUtils.getIncidentWithPriority(incidentId);
    }
    
    //add try-catch
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c updateCCText(Id incidentId, String CCText){
      try{
           BMCServiceDesk__Incident__c inc =  [Select Id, Name, CCText__c, BMCServiceDesk__IncidentType__c ,OwnerId, HD_Ticket_Priority__c ,BMCServiceDesk__Category_ID__c From BMCServiceDesk__Incident__c where ID = :incidentId][0];
           inc.CCText__c = CCText;
           update inc;
           return inc;
      }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
          }  
    }
    
    //add try-catch
     @AuraEnabled
    public static String  saveActionNote(String incidentId,String txt,String timespent){
     
      try{
            BMCServiceDesk__Action__c NoteAction = [Select Id from BMCServiceDesk__Action__c where Name = 'Internal Note'][0];
            BMCServiceDesk__IncidentHistory__c newHist =  new BMCServiceDesk__IncidentHistory__c();
            newHist.BMCServiceDesk__FKAction__c = NoteAction.Id;
            newHist.BMCServiceDesk__duration__c = timespent;
            newHist.BMCServiceDesk__FKIncident__c = incidentId;
            newHist.BMCServiceDesk__note__c   = txt; 
            newHist.BMCServiceDesk__FKUser__c   = UserInfo.getUserId(); //Adding this line for stamping current logged inn User          
            insert newHist;
            System.debug(' Success -- '+newHist.Id);
            BMCServiceDesk__Incident__c inc = [Select Id from BMCServiceDesk__Incident__c where Id =:incidentId LIMIT 1];
            update inc;
            return 'SUCCESS '+newHist.Id;
       }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
          }  
        
    }
    
    
    @AuraEnabled
    public static String getHost(){
        return System.URL.getSalesforceBaseURL().getHost();
    }
    
     @AuraEnabled
    public static String getURL(){
        //return System.URL.getSalesforceBaseURL().toExternalForm();
        return System.URL.getCurrentRequestUrl().toExternalForm();
    }

    @AuraEnabled
    public static String getContentForceURL(){
        //String instanceName = [SELECT Id, InstanceName FROM Organization limit 1].InstanceName;
        String instanceName = [SELECT Label,instanceName__c FROM HD_Instance__mdt where Label = 'settings' limit 1].instanceName__c;
        System.debug(instanceName);
        String s = System.URL.getSalesforceBaseURL().toExternalForm().substringBetween('/','.');
        s=s.substring(1, s.length());
        //System.debug(System.URL.getSalesforceBaseURL().toExternalForm().substringBetween('/','.'));
        //System.debug(s+instanceName);
        //return  System.URL.getSalesforceBaseURL().toExternalForm();
        return s+'--c.'+instanceName;  
        
    }
    
    @AuraEnabled
    
    public static BMCServiceDesk__Incident__c getIncidentDeatilsForPrint(Id incidentId){
        return HD_DetailControllerUtils.getIncidentDeatilsForPrint(incidentId);
    }
    
    //add try-catch
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c updateEmailConfig(Id incidentId, String emailKey, Boolean val){
        try{
            BMCServiceDesk__Incident__c inc = [Select Id, Name, CCText__c, BMCServiceDesk__IncidentType__c ,OwnerId, HD_Ticket_Priority__c ,BMCServiceDesk__Category_ID__c,HD_High_Customer_Impact__c,BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c,Notify_dl_sysadmin_on_status_change__c, Exclude_Client_Notifications__c,Notify_dl_sysadmin_on_creation__c,HD_Notify_DL_EIS_on_Notes_Update__c,HD_System_Admin_Incident__c  From BMCServiceDesk__Incident__c where ID = :incidentId][0];
            System.debug(' ABCDEF  -- ky  '+emailKey+' Val - '+val);
            if( emailKey == 'clientNotification'){ inc.Exclude_Client_Notifications__c = val; }
            else if( emailKey == 'onCreation' ) { inc.Notify_dl_sysadmin_on_creation__c = val; }  
            else if( emailKey == 'onStatusChange' ) {inc.Notify_dl_sysadmin_on_status_change__c = val ;}  
            else if( emailKey == 'onNoteUpdate' ) { inc.HD_Notify_DL_EIS_on_Notes_Update__c = val;}  
               
            update inc;
            return inc;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static Boolean isAccessableRecord(Id incidentId){
         
      return HD_DetailControllerUtils.isAccessableRecord(incidentId);
    }
    
    
    @AuraEnabled 
    public static BMCServiceDesk__Category__c[] getCategories() {
        return [SELECT Id,Name,BMCServiceDesk__FKParentCategory__c,BMCServiceDesk__parentTree__c, BMCServiceDesk__FKParentCategory__r.Name,BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c FROM BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c = true and BMCServiceDesk__inactive__c = false order by Name];
        
    }
    
    @AuraEnabled 
    public static List<BMCServiceDesk__Category__c> searchCategories(String searchText) {
        
        Map<Id,BMCServiceDesk__Category__c> categoryMap = new Map<Id,BMCServiceDesk__Category__c>();
        List<BMCServiceDesk__Category__c> searchedCategories = new List<BMCServiceDesk__Category__c>();
        Set<BMCServiceDesk__Category__c> returnCategories = new Set<BMCServiceDesk__Category__c>();

        for(BMCServiceDesk__Category__c cat : [SELECT Id,Name,BMCServiceDesk__FKParentCategory__c,BMCServiceDesk__FKParentCategory__r.Name FROM BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c = true and BMCServiceDesk__inactive__c = false order by Name])
        {
            categoryMap.put(cat.Id, cat);
            if(cat.Name.containsIgnoreCase(searchText))
            {
                searchedCategories.add(cat);
            }
        }
        for(BMCServiceDesk__Category__c cat : searchedCategories)
        {   
                returnCategories.add(cat);
            
            BMCServiceDesk__Category__c c = cat;
            
            while(c.BMCServiceDesk__FKParentCategory__c!=null && categoryMap.get(c.BMCServiceDesk__FKParentCategory__c)!=null)
            {
                returnCategories.add(categoryMap.get(c.BMCServiceDesk__FKParentCategory__c));
                c = categoryMap.get(c.BMCServiceDesk__FKParentCategory__c);
            }
               
            
        }
        return new List<BMCServiceDesk__Category__c>(returnCategories);
        
    }
   
    @AuraEnabled 
    public static boolean isPendingStatus(Id incidentId){
        return HD_DetailControllerUtils.isPendingStatus(incidentId);
    }   
   
    @AuraEnabled
    public static void resumeTicket(Id incidentId){
        try{
            BMCServiceDesk__Incident__c incident = [Select BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where Id=:incidentId limit 1];
            incident.BMCServiceDesk__FKStatus__c = statusListMap.get('ASSIGNED').Id ;
            update incident;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class FilesAttachment{
        @AuraEnabled
        public List<Attachment> attachments;
        @AuraEnabled
        public List<ContentDocumentLink> files;
    }
    @AuraEnabled
    public static FilesAttachment showAttachments(Id incidentId){
        try{
            FilesAttachment filesAttachments = new FilesAttachment();
            filesAttachments.attachments =[SELECT Id, ContentType, BodyLength, CreatedDate, Description, ParentId, Name FROM Attachment where ParentId =: incidentId and isDeleted = false limit 1000];
            filesAttachments.files =[SELECT LinkedEntityId, ContentDocument.Id,ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.ContentSize, ContentDocument.FileType, Id FROM ContentDocumentLink where LinkedEntityId=:incidentId and isDeleted = false limit 1000];
            return filesAttachments;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }//

        @AuraEnabled
    public static String showAttachmentsDeleteOption(Id attORFileId){ //This is new functionality to delete attachments/files via id.
        String result = '{"operation":"DELETE",Id:"",SUCCESS:false}';
        try{
            
            String sobjectType = attORFileId.getSObjectType().getDescribe().getName();
            system.debug('object type ---> '+ sobjectType);
            if( sobjectType.equalsIgnoreCase('Attachment') )
            {
                Attachment[] attac = [select id from Attachment where id =:attORFileId ];
                // Delete the Attachment
                Database.DeleteResult[] drList = Database.delete(attac, false);
                
                // Iterate through each returned result
                for(Database.DeleteResult dr : drList) {
                    if (dr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully deleted ID: ' + dr.getId());
                        result = '{"operation":"DELETE",Id:"'+ dr.getId() +'",SUCCESS:'+ true +'}';
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : dr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                            throw new AuraHandledException(err.getMessage());
                        }
                    }
                }
                
            }else if (sobjectType.equalsIgnoreCase('ContentDocument'))
            {
                ContentDocument[] cntDoc = [select id from ContentDocument where id =:attORFileId ];
                 // Delete the Attachment
                Database.DeleteResult[] drList = Database.delete(cntDoc, false);
                
                // Iterate through each returned result
                for(Database.DeleteResult dr : drList) {
                    if (dr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully deleted ID: ' + dr.getId());
                        result = '{"operation":"DELETE",Id:"'+ dr.getId() +'",SUCCESS:'+ true +'}';
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : dr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Account fields that affected this error: ' + err.getFields());
                            throw new AuraHandledException(err.getMessage());
                        }
                    }
                }
            }//else
            
            return result;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }//
    
    /**
     * Returns the Org wide addresses valid for the logged in user by reading the settings from Remedyforce Administration(Email settings)
     */
    @AuraEnabled
    public static String getOrgWideAddresses() {
        List<OrgWideEmailAddress> orgWideAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 500];
        List<OrgWideEmailAddress> validAddresses = new List<OrgWideEmailAddress>();
        Map<Id,List<String>> orgWideAddressAccessMap = HD_DetailControllerUtils.getOrgWideAddressSettingFromSysProps();
        System.debug('Map:'+orgWideAddressAccessMap);
        for(OrgWideEmailAddress orgWideAddress : orgWideAddresses) {
            if(orgWideAddressAccessMap.containsKey(orgWideAddress.Id) &&
              (orgWideAddressAccessMap.get(orgWideAddress.Id).contains('ALL PROFILES') ||
               orgWideAddressAccessMap.get(orgWideAddress.Id).contains(UserInfo.getProfileId()))) {
                validAddresses.add(orgWideAddress);
            }
        }
               
        return JSON.serialize(validAddresses);
    }
}//CLASS END