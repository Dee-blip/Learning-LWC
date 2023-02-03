/**
   History
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    18/04/2017     Created this Class   SFDC-1548
        
*/
public class OpportunityConsolidatedUIController {
    private ApexPages.StandardController sc;
    private Opportunity oppty;
    private id assocLeadId{get;set;}
    public String oppId {get; set;}
    public Contact con {get;set;}
    public Task tsk {get;set;}
    

    public OpportunityConsolidatedUIController(ApexPages.StandardController sc) {
        this.sc = sc;
        oppty = (Opportunity) sc.getRecord();
        oppId = oppty.id;
        assocLeadId = oppty.Associated_Lead__c;
        system.debug('assocLeadId: '+assocLeadId);
        if(assocLeadId!=null)
            con = [Select id,FirstName,LastName,Title, name,Phone,Email,AKAM_Contact_ID__c from contact where id in (select Associated_Contact__c from lead where id=:assocLeadId)];
      
    }
    
    @AuraEnabled
    public static List<FieldSetMember>  getContact(String assocLeadId){
        system.debug(LoggingLevel.ERROR,'assocLeadId: '+assocLeadId);
        List<FieldSetMember> fsmList = getFields('Contact');
        String toSelectList = String.escapeSingleQuotes(GsmUtilClass.toSelectByFieldSet(fsmList));
        String query =  'Select '+toSelectList+' from contact where id in (select Associated_Contact__c from lead where id=:assocLeadId)';
        system.debug(LoggingLevel.ERROR,'query in getContact: '+query);
        try{
            Contact con = Database.query(query);
            for(FieldSetMember fsm: fsmList){
                fsm.setValue(con);
            }
        }catch(exception e){
            system.debug(LoggingLevel.ERROR,'e.getmessage(): '+e.getmessage());
            Error_Log__c elc = new Error_Log__c(Name='getContact', Class__c='OpportunityConsolidatedUIController', Error_Message__c=e.getMessage());
            insert elc;
            throw new AuraHandledException(e.getmessage());
        }
    
        return fsmList;
    }

    @AuraEnabled
    public static List<FieldSetMember> getCampaign(String campaignId){
        system.debug(LoggingLevel.ERROR,'campaignId in getCampaign lightening: '+campaignId);
        List<FieldSetMember> fsmList = getFields('Campaign');
        String toSelectList = String.escapeSingleQuotes(GsmUtilClass.toSelectByFieldSet(fsmList));
        String query =  'Select '+toSelectList+' from Campaign where id=:campaignId';
        system.debug(LoggingLevel.ERROR,'query in getCampaign: '+query);
        try{
            Campaign cmp = Database.query(query);
            system.debug(LoggingLevel.ERROR,'cmp in getCampaign: '+cmp);
            for(FieldSetMember fsm: fsmList){
                fsm.setValue(cmp);
            }
            
        }catch(exception e){
            system.debug(LoggingLevel.ERROR,'e.getmessage(): '+e.getmessage());
            Error_Log__c elc = new Error_Log__c(Name='getCampaign', Class__c='OpportunityConsolidatedUIController', Error_Message__c=e.getMessage());
            insert elc;
            throw new AuraHandledException(e.getmessage());
        }
        return fsmList;
    }


        @AuraEnabled
    public static lightningTableWrapper getTaskEvents(String conId,integer lim, lightningTableWrapper ltw)
    { 
        system.debug(LoggingLevel.ERROR,'conId in task:: '+conId+' lim: '+lim);
        if(conId != null)
        {
            List<Task> allTasks = new List<Task>();
            List<taskEventWrapper> te = new List<taskEventWrapper>();
            Map<Id,Task> myMap = new Map<Id,Task>(); 
                    for (task t: [Select  Id, WhoId, WhatId, Subject, Priority,
                                                Associated_AKAM_Lead_ID__c, 
                                                Associated_AKAM_Contact_ID__c, 
                                                Associated_AKAM_Campaign_ID__c, Type__c,
                                                owner.Name, LastModifiedDate, isClosed,
                                                activitydate, who.name, what.name, status,Description,CreatedBy.Name,
                                                AccountId From Task
                                                WHERE //whoid= :myLead.Associated_Contact__c AND
                                                whoid != null AND
                                                whoid = :conId
                                                /*AND isClosed=false*/ order by activitydate desc LIMIT :lim
                                                ])
                    {
                     myMap.put(t.Id, t);
                     allTasks.add(t);
                     taskEventWrapper tew = new taskEventWrapper(t);
                     te.add(tew);
                    }
                    system.debug(LoggingLevel.ERROR,'te.size(): '+te.size());
                      //load current events
                    if(ltw.eventLimit!=0)
                     for (Event e: [Select  Id, WhoId, WhatId, Subject,
                                                StartDateTime, 
                                                Associated_AKAM_Lead_ID__c, 
                                                Associated_AKAM_Contact_ID__c, 
                                                Associated_AKAM_Campaign_ID__c, Type__c,
                                                owner.Name, LastModifiedDate,
                                                activitydate, who.name, what.name,Description,CreatedBy.Name,
                                                AccountId From Event
                                                WHERE //whoid= :myLead.Associated_Contact__c AND
                                                whoid != null AND
                                                whoid = :conId
                                                /*AND StartDateTime > :System.now()*/ order by activitydate  desc LIMIT :ltw.eventLimit
                                                ])
                    {
                     taskEventWrapper tew = new taskEventWrapper(e);
                     te.add(tew);
                    }
                    system.debug(LoggingLevel.ERROR,'te: '+te.size());
             ltw.taskEventWrapperRecords = te;   
             //ltw.eventOffset = ltw.eventOffset+ltw.eventLimit;
             
            return ltw;
        }
        else
            return null;
    }
        @AuraEnabled public static lightningTableWrapper getRecords(String conId,decimal pageNumber, Integer pageSize,Integer eventOffset,Integer eventLimit){     
       
        
        
         lightningTableWrapper ltw = new lightningTableWrapper();
        integer taskLimit = Integer.valueOf(GsmUtilClass.getGSMSettingValue('consolidatedUITaskLimit'));
        integer totalEventLimit = Integer.valueOf(GsmUtilClass.getGSMSettingValue('consolidatedUIEventLimit'));
        integer totalNoOfRec = taskLimit+totalEventLimit;
        system.debug(LoggingLevel.ERROR,'taskLimit: '+taskLimit);  
        system.debug(LoggingLevel.ERROR,'eventLimit: '+totalEventLimit);  

        ltw.eventLimit = Integer.valueOf(totalEventLimit);
        ltw = getTaskEvents(conId, taskLimit,ltw);
        return ltw;
    }

    public class lightningTableWrapper {
    @AuraEnabled
    public Integer eventLimit { get;set; }
   @AuraEnabled
    public List<taskEventWrapper> taskEventWrapperRecords { get;set; }
    }

    public class taskEventWrapper
    {
         @AuraEnabled public ID Id{get; set;}
         @AuraEnabled public String Priority {get; set;}
         @AuraEnabled public string subject{ get; set;}
         @AuraEnabled public string TEtype{ get; set;}
         @AuraEnabled public string who{ get; set;}
         @AuraEnabled public string what{ get; set;}
         @AuraEnabled public Boolean task{ get; set;}
         @AuraEnabled public date ActivityDate{ get; set;}
         @AuraEnabled public string Status{ get; set;}
         @AuraEnabled public string Owner{ get; set;}
         @AuraEnabled public string Creator{ get; set;}
         @AuraEnabled public string LastModified{ get; set;}
         @AuraEnabled public string Description{ get; set;}
         
         //build signatures
         public taskEventWrapper(Task t)
         {
            id = t.id;
            Priority = t.priority;
            subject = t.subject;
            TEtype = t.Type__c;
            Owner = t.owner.Name;
            ActivityDate = t.ActivityDate;
            who = t.who.name;
            what = t.what.name;
            task=true;
            status= t.status;
            Creator = t.CreatedBy.Name;
            Description = t.Description;
          }
          public taskEventWrapper(Event e)
          {
            id = e.id;
            Priority = '';
            subject = e.subject;
            TEtype = e.Type__c;
            Owner = e.owner.Name;
            ActivityDate = e.ActivityDate;
            who = e.who.name;
            what = e.what.name;
            task=false;
            status= '';
            Creator= e.CreatedBy.Name;
            Description = e.Description;
          }
    }
    @AuraEnabled
    public static List<FieldSetMember> getFields(String sObjectName) {
        system.debug(LoggingLevel.ERROR,'sObjectName in ui cont: '+sObjectName);
        Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().FieldSets.getMap();
        Schema.FieldSet fs = null;
        for(Schema.FieldSet fst : fsMap.values()){
            if (fst.getDescription().containsIgnoreCase('OpportunityConsolidatedUI')) 
             fs = fst;
        }
        List<FieldSetMember> fset = new List<FieldSetMember>();
        if(fs!=null){
            List<Schema.FieldSetMember> fieldSet = fs.getFields();
            for (Schema.FieldSetMember f: fieldSet) {
                    fset.add(new FieldSetMember(f));
            }
        }
        system.debug(LoggingLevel.ERROR,'fset in ui cont: '+fset);
        return fset;
    }

}