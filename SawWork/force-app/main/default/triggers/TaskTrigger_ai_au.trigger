/***
TaskTrigger_ai_au 
@author Karteek Mekala <kmekala@akamai.com> 
@Description : This trigger is called on 'after insert, after update'
- The "Task.TaskType" is updated according to the Profile of the "Task.Owner"
- The "Order.Approvals Required" and "Order Owners" are updated according to the "Task.Type", "Task.Owner" and "Task.Legal Followup Needed"

@History
--Developer           --Date            --Change
Karteek Kumar M       04/08/10          CR 694234 China CDN, TAPP, Edgesuite transition team, PS, Aproval Process
Send an email to the Task Owner if it is a PS Approval Activity
- Added a new function for this : SendOrderApprovalTaskCreationNotifications()
Karteek Kumar M       29/11/10          CR 886789 Fix bug with Task AKAM fields
Removing firstRunFlaglogc for Akam System fields function
Also removing isUpdateCauseFlag func.
Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
- By-passing the trigger code for connection user.                                            
Ruchika Sharma        10/14/2014         CR 2762544 - Lead Life Cycle : Automated Activities  
- Added logic to call stampLastActivity method on LeadButtonsClass
Suhas Jain            21/05/2018        - FFPSA-490 Alerting to project owner when BED extended

Sandeep Dhariwal      21/05/2018        - Removed the apttus related code as part of SFDC-2688

Sheena Bhan       03/01/2020    - ESESP-2869: Added logic to update 'User Set-up' Milestone.
Sheena Bhan       10/02/2020    - ESESP-3152: Populating the Next Task Due field for AMG cases.
Vandhana Krishnamurthy 10/05/2020   - ESESP-3524 : S2ET
Sharath Prasanna    14/07/2020    - ESESP-3536: Task to Siebel Issue Activity sync. This runs on insert and update of tasks
Sheena Bhan		  20/10/2020	- ESESP-3767: Populating the 'Total Incident LOE (Hours)' field on SI.
Vandhana		10/08/2021      ESESP-4359 Elevate/Escalate on Account
Tejaswini       25/04/2022     - ESESP-6444 : Salesforce automation for case closure - SOCC
_____________________________________________________________________________________________________________________________

*/  

trigger TaskTrigger_ai_au on Task (after insert, after update) 
{
    
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)
           && MSAzureHandler.varActivateMSAzureCode){
               List<Task> lMSTasks = new List<Task>();
               Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
               Id manageSecurityActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();
               for(Task varTask: Trigger.New){
                   if((varTask.RecordTypeId == serviceActivityRT 
                       ||varTask.RecordTypeId == manageSecurityActivityRT) 
                      && varTask.WhatId != null
                      && String.valueOf(varTask.WhatId).startsWith('500')){
                          lMSTasks.add(varTask);
                      }
               }
               if(!lMSTasks.isEmpty()){
                   MSAzureHandler msAzureHandlerInstance = new MSAzureHandler();
                   msAzureHandlerInstance.creatPayloadForActivityUpdate(lMSTasks, Trigger.oldMap);
               }
           }
        
        //Changes by Suhas for FFPSA-490
        if((Trigger.isAfter ) &&  (Trigger.isUpdate || Trigger.isInsert))
        {
            try
            {
                //Changes by Sharath for Siebel Issue Activity sync
                SC_Utility__mdt siebelSync = [Select Value_Text__c  from SC_Utility__mdt where 
                                              Active__c = true and developername = 'CaseIssueActivateSync' limit 1];
                if(siebelSync.Value_Text__c.equalsIgnoreCase('true') || Test.isRunningTest())
                {
                    //Check for recursion                
                    system.debug('Trigger.isUpdate: '+ Trigger.NewMap.keySet());
                    if(SC_SiebelIssueSync.taskIds.addAll(Trigger.NewMap.keySet()))
                    {
                        //make the flag false
                        system.debug('Trigger.isUpdate: '+ Trigger.isUpdate);
                        //SC_SiebelIssueSync.siebelSyncRecursionCheck = false;     
                        //call the checkForNOCCCase method: The parameters passed: NewMap, Oldmap and isInsert Boolean flag 
                        SC_SiebelIssueSync syncIssueObject = new SC_SiebelIssueSync();
                        syncIssueObject.checkForNOCCCase(Trigger.NewMap,Trigger.OldMap, Trigger.isInsert);
                    }
                    
                }            
                PSA_ProjectActions.notifyBED(Trigger.New, Trigger.Old, Trigger.isInsert, Trigger.oldMap);
            }
            Catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Error in notifying for BED',e.getMessage());
            }
            
        }
        //Changes by Suhas for FFPSA-490
        
        // JAVRIS Changes
        if(Trigger.isAfter && Trigger.isInsert) {
            SC_JARVIS_CustomerTouchpoints.handleJarvisCaseActivity(Trigger.new);
            //Changes for ESESP-6444
            SC_TaskTriggerHandler.updateTicketPushTask(Trigger.new);
        }
        
        // changes by Vandhana - S2ET
        if(Trigger.isInsert)
        {
            Id secServActivityRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
            List<Task> s2ETSchedDepTasks = new List<Task>();
            
            for(Task varTask: Trigger.new)
            {
                if(Trigger.isInsert && varTask.RecordTypeId == secServActivityRecTypeId && varTask.WhatId != NULL 
                   && String.valueOf(varTask.WhatId).startsWith('500') && varTask.Assigned_Division__c != 's2etautogen'
                   && varTask.Type__c == 'Scheduled Deployment'
                  )
                {
                    s2ETSchedDepTasks.add(varTask);
                }
            }
            
            if(!s2ETSchedDepTasks.isEmpty())
            {
                SC_CaseTriggerHelperClass2.createS2ETTaskSchedDeploy(s2ETSchedDepTasks);
            }
        }
        // end of changes by Vandhana - S2ET

        // changes by Vandhana for Elevate/Escalate on Account (ESESP-4359)
        if(Trigger.isInsert)
        {
            Id elevationActivityRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Elevation_Activity').getRecordTypeId();
            Map<Id,Id> mapTaskIdElevationId = new Map<Id,Id>();
            Map<Id,Task> mapElevationTask = new Map<Id,Task>();
            
            Schema.DescribeSObjectResult descSObjRes = Schema.getGlobalDescribe().get('Elevation__c').getDescribe() ;
            String elevationKeyPrefix = descSObjRes.getKeyPrefix();
            
            for(Task varTask: Trigger.new)
            {
                if(Trigger.isInsert && varTask.RecordTypeId == elevationActivityRecTypeId 
                   && varTask.WhatId != NULL && String.valueOf(varTask.WhatId).startsWith(elevationKeyPrefix)
                  )
                {
                    mapElevationTask.put(varTask.Id,varTask);
                    mapTaskIdElevationId.put(varTask.Id,varTask.WhatId);
                }
            }
            
            if(!mapElevationTask.isEmpty() && !mapTaskIdElevationId.isEmpty())
            {
                SC_TaskTriggerHandler.notifyAccountDLElevateTask(mapElevationTask,mapTaskIdElevationId);
            }
        }
    }
    
    //Changes by Sheena for ESESP-2869
    if(Trigger.isUpdate)
    {
        map<string,Task> caseTaskMap = new map<string, task>();
        
        for(Task tsk: Trigger.new)
        {
            if(tsk.Status!= trigger.oldmap.get(tsk.id).status  && tsk.WhatId != null && tsk.Type__c=='Task' 
               && String.valueOf(tsk.WhatId).startsWith('500') && tsk.subject=='User Setup')
            {
                caseTaskMap.put(tsk.WhatId, tsk); 
            }
        }
        
        if(!caseTaskMap.isEmpty())
        {
            TaskTriggerHandler.updateUserSetupMilestone(caseTaskMap, true, Trigger.oldMap);
        }
    }
    
    if(Trigger.isInsert)
    {
        map<string,Task> caseTaskMap = new map<string, task>();
        
        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null && tsk.Type__c=='Task' && String.valueOf(tsk.WhatId).startsWith('500') && tsk.subject=='User Setup')
            {
                caseTaskMap.put(tsk.WhatId, tsk); 
            }
        }
        
        if(!caseTaskMap.isEmpty())
        {
         TaskTriggerHandler.updateUserSetupMilestone(caseTaskMap,false,NULL);   
        }                      
    }   
    
    // Changes End
    
    
    /*********** ESESP-3152: Populating the Next Task Due field for AMG cases **********/
    
    if(Trigger.isInsert)
    {        
        Set<Id> csIds = new Set<Id>();
        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null  && String.valueOf(tsk.WhatId).startsWith('500'))
            {
                csIds.add(tsk.WhatId);
            }
        }
        if(!csIds.isEmpty())
        {
            TaskTriggerHandler.addNextTaskDue(csIds);
        }
        
    }
    
    if(Trigger.isUpdate)
    {
        Set<Id> csIds = new Set<Id>();
        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null && String.valueOf(tsk.WhatId).startsWith('500') && (tsk.ActivityDate != Trigger.oldMap.get(tsk.Id).ActivityDate || (tsk.Status != Trigger.oldMap.get(tsk.Id).Status && tsk.Status=='Completed')))
            {
                csIds.add(tsk.WhatId);
            }
        }
        
        if(!csIds.isEmpty())
        {
           
            TaskTriggerHandler.addNextTaskDue(csIds);
        }
    }
    
    /*********** ESESP-3767: Logic to Populate the 'Total Incident LOE (Hours)' field on SI.**********/
    if(Trigger.isInsert)
    {        
        List<Task> taskList = new List<Task>();
        Id SIActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident Activity').getRecordTypeId();
        String siObjPrefix = Schema.getGlobalDescribe().get('SC_SI_Service_Incident__c').getDescribe().getKeyPrefix();
        
        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null  && tsk.RecordtypeId == SIActivityId && tsk.LOE_hours__c!=null && String.valueOf(tsk.WhatId).startsWith(siObjPrefix))
            {
                taskList.add(tsk);
            }
        }
        if(!taskList.isEmpty())
        {
            SC_TaskTriggerHandler.addIncidentLoe(taskList);
        }
        
    }
    
    if(Trigger.isUpdate)
    {
        List<Task> taskList = new List<Task>();
        Id SIActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident Activity').getRecordTypeId();
        String siObjPrefix = Schema.getGlobalDescribe().get('SC_SI_Service_Incident__c').getDescribe().getKeyPrefix();

        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null  && tsk.RecordtypeId == SIActivityId && tsk.LOE_hours__c!=null && tsk.LOE_hours__c!=Trigger.oldMap.get(tsk.Id).LOE_hours__c && String.valueOf(tsk.WhatId).startsWith(siObjPrefix))
            {
                taskList.add(tsk);
            }
        }
        if(!taskList.isEmpty())
        {
            SC_TaskTriggerHandler.addIncidentLoe(taskList);
        }
    }
   // Changes End    
   
   // /*********** ESESP-3590: Logic to Populate the 'Total LOE (Hours)' field on RCA.**********/
    if(Trigger.isInsert)
    {        
        List<Task> taskList = new List<Task>();
        Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
        String caseObjPrefix = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();
        
        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null  && tsk.RecordtypeId == rcaActivityId && tsk.LOE_hours__c!=null && String.valueOf(tsk.WhatId).startsWith(caseObjPrefix))
            {
                taskList.add(tsk);
            }
        }
        System.debug('+++++'+taskList);
        if(!taskList.isEmpty())
        {
            SC_TaskTriggerHandler.addCaseLoeRCA(taskList);
        }
        
    }
    
    if(Trigger.isUpdate)
    {
        List<Task> taskList = new List<Task>();
        Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
        String caseObjPrefix = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();

        for(Task tsk: Trigger.new)
        {
            if(tsk.WhatId != null  && tsk.RecordtypeId == rcaActivityId && tsk.LOE_hours__c!=null && tsk.LOE_hours__c!=Trigger.oldMap.get(tsk.Id).LOE_hours__c && String.valueOf(tsk.WhatId).startsWith(caseObjPrefix))
            {
                taskList.add(tsk);
            }
        }
        if(!taskList.isEmpty())
        {
            SC_TaskTriggerHandler.addCaseLoeRCA(taskList);
        }
    }
   // Changes End
}