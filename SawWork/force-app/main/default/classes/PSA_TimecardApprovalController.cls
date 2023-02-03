//FFPSA-488 18.6 Sujay : Added changes as part of showing Delegated Timecards in the page

public with sharing class PSA_TimecardApprovalController {
    public PSA_TimecardApprovalController() 
    {
    }
    
    //18.6
    public User loggedInUser 
    {
        get
        {
            if(loggedInUser == NULL)
            {
                loggedInUser = [SELECT Id,Name 
                                FROM USER 
                                WHERE Id =:UserInfo.getUserId()];
            }
            return loggedInUser;
        }
        set;
    }


  @RemoteAction 
  public static String getAccess()
  {
    PSA_Mobile_Pages__mdt mDRecord = [select Approval_Batch_Limit__c,Approval_Query_Limit__c,Approval_Rendered_Limit__c,Error_Message_Timeout__c,Tooltip_Timeout__c from PSA_Mobile_Pages__mdt limit 1];

    PSA_Mobile_Access__c mobileAccess = PSA_Mobile_Access__c.getInstance(UserInfo.getUserId());
    Boolean access;
    if(mobileAccess == null)
    {
      mobileAccess = PSA_Mobile_Access__c.getInstance(UserInfo.getProfileId());      
    }    
    
    if(mobileAccess == null)
    {
      mobileAccess = PSA_Mobile_Access__c.getOrgDefaults();
    }
    access = mobileAccess == null ? false: mobileAccess.Has_Access__c;

    JSONGenerator gen = JSON.createGenerator(true);
            
        gen.writeStartObject();        
            gen.writeObjectField('access', access);        
            gen.writeObjectField('metadata', mDRecord);        
        gen.writeEndObject();

    return PSA_TimeEntryController.encodeBase64(gen.getAsString());
  }

  @RemoteAction
    public static String getTimecards(Integer queryLimit,Integer renderedTimecardsLimit,Integer offsetVal,String projectId,String accountId)
    {        
        
        String queryString;
        List<id> tid= new List<id>();
        List<pse__Timecard_Header__c> th = new List<pse__Timecard_Header__c>();
        
        /*
        //18.6 to alter the TC based on Delegated/Actual Timecards.
        List<pse__Timecard_Header__c> tcOfDelegated = new List<pse__Timecard_Header__c>();
        List<pse__Timecard_Header__c> tcOfLoggedInUser = new List<pse__Timecard_Header__c>();
        */
        
        //18.6 to store a map of TcId : Actor ID and Actor Name
        Map<Id, Id> mapTcIdToActor = new Map<Id, Id>();
        
        //18.6 to store a map of ActorId : ActorName
        Map<Id, String> mapActorIdToActorName = new Map<Id, String> ();
        
        /*
        //store Delegated Timecard Information
        Set<Id> pwisOfDelegated = new Set<Id>();
        */
        
        //18.6 Adding below Query to pick all the Delegated TC's 
        Set<Id> delgUserIds =  new Set<Id>();
        for(User usr : [SELECT Id,Name, DelegatedApproverId 
                        FROM User 
                        WHERE DelegatedApproverId = :UserInfo.getUserId()]){
             
            delgUserIds.add(usr.Id);
        }
         
        //List<ProcessInstanceWorkItem> pwis = [select id,processInstance.targetobjectId from ProcessInstanceWorkItem where actorid = :UserInfo.getUserId() and processinstance.status = 'pending'  order by createddate limit :queryLimit offset :offsetVal];
        //List<ProcessInstanceWorkItem> pwis = [select id,processInstance.targetobjectId from ProcessInstanceWorkItem where actorid = :UserInfo.getUserId() and processinstance.status = 'pending'  order by createddate limit :queryLimit];
        
        //18.6 Added a filter to pick Delegated TCs for below SOQL Modified SOQL
        List<ProcessInstanceWorkItem> pwis = [select id, ActorId, Actor.Name, processInstance.targetobjectId from ProcessInstanceWorkItem where (actorId = :delgUserIds OR actorid = :UserInfo.getUserId()) and processinstance.status = 'pending' order by CreatedDate limit :queryLimit];
        
        /*
        //18.6 Itereate over loop and store DelegatedRecords on top of the List.
        for(ProcessInstanceWorkItem piwi: pwis){
            if(delgUserIds.contains(piwi.ActorId)){
                pwisOfDelegated.add(piwi.processInstance.targetobjectId);
            }
        }
        */
        
        if (pwis != null && pwis.size() > 0)
        {
            for(ProcessInstanceWorkItem pwi: pwis)
            {
                tid.add(pwi.processInstance.targetobjectId);
                
                //18.6 to store a map of TcId : Actor ID and Actor Name 
                mapTcIdToActor.put(pwi.processInstance.targetobjectId, pwi.ActorId);
                //mapTcIdToActor.get(pwi.processInstance.targetobjectId).add(String.valueOf(pwi.ActorId));

                //18.6 adding a check to store a map of TcId : Actor ID and ActorId : Actor Name
                if(pwi.ActorId != UserInfo.getUserId() && !mapActorIdToActorName.containsKey(pwi.ActorId)) {
                    mapActorIdToActorName.put(pwi.ActorId, pwi.Actor.Name);
                }
                
            }

        }
        if(tid != null && tid.size() > 0)
        {
            queryString = 'select id,name,pse__resource__r.name,pse__resource__c,pse__project__c,pse__project__r.name,pse__project__r.pse__account__r.name,pse__project__r.pse__account__c,pse__assignment__r.name,pse__start_date__c,pse__end_date__c,pse__Total_hours__c,pse__Milestone__r.Name,pse__Project_Methodology_Object__r.Name,pse__Status__c,pse__Billable__c,pse__Monday_Hours__c ,pse__Monday_Notes__c,pse__Tuesday_Hours__c, pse__Tuesday_Notes__c,pse__Wednesday_Hours__c,pse__Wednesday_Notes__c,pse__Thursday_Hours__c,pse__Thursday_Notes__c,pse__Friday_Hours__c, pse__Friday_Notes__c,pse__Saturday_Hours__c,pse__Saturday_Notes__c,pse__Sunday_Hours__c, pse__Sunday_Notes__c,pse__Additional_Notes__c from pse__Timecard_Header__c where id in : tid and ((pse__Assignment__c = null and pse__Project__r.pse__Allow_Timecards_Without_Assignment__c = true) or pse__Assignment__c != null)';
            if(projectId != null && projectId != '')
            {
                queryString += ' and pse__project__r.id = :projectId ';
            }
            if(accountId != null && accountId != '')
            {
                queryString += ' and pse__project__r.pse__Account__r.id =  :accountId ';
            }
            queryString += ' order by submitted_date__c ';
            th = Database.query(queryString);
            
        }        
        
        Map<Id,String> accountFilter = new Map<Id,String>();
        Map<Id,Map<String,String>> projectFilter = new Map<Id,Map<String,String>>();
        Map<Id,String> resourceFilter = new Map<Id,String>();
        
        if(th != null && th.size() > 0)
        {          
            //18.6 commented as filter should take complete size of the list
            //for(Integer index = 0; index < th.size() && index < renderedTimecardsLimit;index++)
            for(Integer index = 0; index < th.size() ; index++)
            {
                pse__Timecard_Header__c timecard = th.get(index);

                if(!accountFilter.containsKey(timecard.pse__project__r.pse__account__c))
                {
                    accountFilter.put(timecard.pse__project__r.pse__account__c,timecard.pse__project__r.pse__account__r.name);
                }
                if(!projectFilter.containsKey(timecard.pse__project__c))
                {                    
                    projectFilter.put(timecard.pse__project__c, new Map<String,String>());
                    projectFilter.get(timecard.pse__project__c).put('Name',timecard.pse__project__r.name);
                    projectFilter.get(timecard.pse__project__c).put('Account',timecard.pse__project__r.pse__account__c);
                }
                if(!resourceFilter.containsKey(timecard.pse__resource__c))
                {
                    resourceFilter.put(timecard.pse__resource__c,timecard.pse__resource__r.name);
                }

            }
        
            JSONGenerator gen = JSON.createGenerator(true);

            gen.writeStartObject(); 
                
                gen.writeFieldName('Objects');
                
                    gen.writeStartArray();        
                
                        gen.writeStartObject();        
                            gen.writeObjectField('timecards', th);        
                        gen.writeEndObject();

                        gen.writeStartObject();        
                            gen.writeObjectField('accounts', accountFilter);        
                        gen.writeEndObject();

                        gen.writeStartObject();        
                            gen.writeObjectField('projects', projectFilter);        
                        gen.writeEndObject();

                        gen.writeStartObject();        
                            gen.writeObjectField('resources', resourceFilter);        
                        gen.writeEndObject();

                        gen.writeStartObject();        
                            gen.writeObjectField('totalCount', th.size());        
                        gen.writeEndObject();
                        
                        //18.6 added below for idetifying Delegated Timecards
                        gen.writeStartObject();        
                            gen.writeObjectField('mapTcIdToActor', mapTcIdToActor);        
                        gen.writeEndObject();
            
                        gen.writeStartObject();        
                            gen.writeObjectField('mapActorIdToActorName', mapActorIdToActorName);        
                        gen.writeEndObject();
            
                        
                    gen.writeEndArray();
                
            gen.writeEndObject();
            
            return PSA_TimeEntryController.encodeBase64(gen.getAsString());
        }
        //system.assertEquals(1,2);
        return 'No Records';
            
    }

    @remoteAction
    public static String ApproveSelectedTC(String action,String comments,String selectedTC,Integer limitSize)
    {
        List<id> tcidsJs = selectedTC.split(',');
        List<id> tcids = new List<id>();
        List<pse__Timecard_Header__c> tcs = new List<pse__Timecard_Header__c>();
        Integer successCount = 0;
        if (action == 'Approve')
        {
                  tcs = [SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Rejected' and pse__Status__c!='Saved' and Id in :tcidsJs order by submitted_date__c asc, pse__Total_Hours__c  desc Limit :limitSize ];


        }
        else
        {
                   tcs = [SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Rejected' and pse__Status__c!='Saved' and Id in :tcidsJs order by submitted_date__c desc, pse__Total_Hours__c asc Limit :limitSize ];
        }
        
    
        for(pse__Timecard_Header__c t: tcs)
        {
            tcids.add(t.id);
        }
        List<ProcessInstanceWorkitem> piwItem = [Select Id,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.Status = 'Pending' and ProcessInstance.TargetObjectId in:tcids ];
        Approval.ProcessWorkitemRequest req2;
        //creating a ProcessWorkitemRequest list to approve or reject TC
        List<Approval.ProcessWorkitemRequest> listReq = new List<Approval.ProcessWorkitemRequest>();
        //the result of the ProcessWorkitemRequest is stored in  ProcessResult 
        List<Approval.ProcessResult> result2 = new List<Approval.ProcessResult>();
        Map<String,String> idToErrors = new Map<String,String>();
        for(ProcessInstanceWorkitem piw1:piwItem)
        {
            req2 = new Approval.ProcessWorkitemRequest();
            if (comments != null )
            {
                req2.setComments(comments);                
            }
            req2.setAction(action);
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req2.setWorkitemId(piw1.Id);
            listReq.add(req2);
            
        }
        try
        {
               //approving or rejecting the TCs. the results are stored in result2   
              result2 =  Approval.process(listReq,False);

        }
        catch (Exception e)
        {
            return 'Failed';
        }   
        if(result2!=NULL)
        {
            //Iterating over the result list, for every failure, create a table row in the ErrorMessages variable
            for (Integer index = 0;index < result2.size(); index++)
            {
                Approval.ProcessResult result1 = result2.get(index);
                if(!result1.isSuccess())
                {
                    idToErrors.put(piwItem[index].ProcessInstance.TargetObjectId,result1.getErrors()[0].getMessage() );
                    //errors += 'Error: '+ result1.getErrors()[0].getMessage() ;
                }
                else
                {
                    successCount++;
                }
            }
        }

        if(tcids != null && !tcids.isEmpty())
        {
            PSA_TimeEntryController.insertHistoryRecords(tcids,action); 
        }
        JSONGenerator gen = JSON.createGenerator(true);
            
            gen.writeStartObject();        
                gen.writeObjectField('SuccessCount', successCount);        
                gen.writeObjectField('errors', idToErrors);        
            gen.writeEndObject();
                    
        return PSA_TimeEntryController.encodeBase64(gen.getAsString());
        

    }


}