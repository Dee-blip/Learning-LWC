public class TaskTriggerFrameworkHandler extends ApexTriggerHandlerAbstractClass {
    
    public override void beforeInsertBeforeUpdateTrigger() {

        TaskTriggerClass.updateSubjectForQuickActivity(Trigger.new);

        String taskWhatId;
        /* On Create, stamp the AKAM System fields */
        List<Task> AKAM_System_FieldsList = new List<Task>();
        List<Task> updateAssocFieldsTaskList = new List<Task>();

        for(sObject task:Trigger.new)
        {
            Task tsk = (Task)task;
            // On Create, stamp the AKAM System fields if they are null.
            if((Trigger.isInsert) && (tsk.AKAM_Created_By__c == null || tsk.AKAM_Created_Date__c == null || tsk.AKAM_System__c == null))
                AKAM_System_FieldsList.add(tsk);
            
            taskWhatId = tsk.WhatId;
            
            // L2q team code
            if(taskWhatId != Null && (!taskWhatId.startsWith(Schema.Sobjecttype.Case.getKeyPrefix()))){
            
                // Update the Assoc fields if Task.What Id has changed, or if this is an insert. 
                if(Trigger.isInsert || (tsk.WhatId != ((Task)Trigger.oldMap.get(tsk.Id)).WhatId) )
                    updateAssocFieldsTaskList.add(tsk);
            }
        }

        if(!AKAM_System_FieldsList.isEmpty())
            TaskTriggerClass.AKAM_System_Fields(AKAM_System_FieldsList);
        if(updateAssocFieldsTaskList.size() > 0 )
            TaskTriggerClass.UpdateAssocFields(updateAssocFieldsTaskList);

        /* Order Approval Activity */   
        Id oaRecTypeId = TaskTriggerClass.GetOaRecTypeId();
        //List<Task> orderApprovalActivities = new List<Task>();
        /* SFDC-4178
        for(sObject task:Trigger.new)
        {
            Task tsk = (Task)task;
            if(tsk.RecordTypeId == oaRecTypeId)
            {
                // Force users to assign PS Approval tasks to PS Approvers
                //Common code removeal - Need move clarity
                if(tsk.subject != null && tsk.Subject.contains('PS Approval required for Order Approval') && [select Id, Professional_Services_Approver__c from User where Id=:tsk.OwnerId].Professional_Services_Approver__c != true)
                    tsk.OwnerId.addError('A Proffesional Services Approval Task must be assigned to a Proffesional Services Approver.');
                orderApprovalActivities.add(tsk);
            }
        }
        if(orderApprovalActivities.size()>0)
            OrderApprovalClass.OrderApprovalActivity_UpdateTask(orderApprovalActivities);
        */

        if(Trigger.isUpdate)
        {
            //SFDC-2266
            String TaskSubject = GsmUtilClass.getGSMSettingValue('cmgReviewTaskSubject');
            List<Task> ClosedTasks = new List<Task>();
            for(sObject task:Trigger.new)
            {
                Task eachTask = (Task)task;
                if(eachTask.WhatId != null && ((Task)Trigger.oldMap.get(eachTask.Id)).Status != ((Task)Trigger.newMap.get(eachTask.Id)).Status && ((Task)Trigger.newMap.get(eachTask.Id)).Status == 'Completed' && String.valueOf(eachTask.WhatId.getSObjectType()) == 'Opportunity' && eachTask.Subject == TaskSubject)
                {
                    ClosedTasks.add(eachTask);
                }
            }
            if(ClosedTasks.size() > 0)
            TaskTriggerClass.closedTasksWithNullContractAcceptedDate(ClosedTasks);
        }
        
        if(Trigger.isUpdate){
                List<Task> reassignTaskList = new List<Task>();
                List<Id> whatIdList = new List<Id>();
                for(sObject tsk: Trigger.new){
                    Task task = (Task)tsk;
                    system.debug(LoggingLevel.ERROR,'task.Subject in bi trigger:: '+task.Subject+' task.status: '+task.status+' condition:: ');
                    //SFDC-4326- putting null check
                    if(task.Subject!=null && task.Subject.equalsIgnoreCase(GsmUtilClass.getGSMSettingValue('cmgReviewTaskSubject')) && task.status!=null && task.status.equalsIgnoreCase('Deferred')){
                        reassignTaskList.add(task);
                        whatIdList.add(task.whatId);
                    }
                }
            
            
            if(!reassignTaskList.isEmpty())
                TaskTriggerClass.updateReviewTaskOwner(reassignTaskList,whatIdList);
        }
        
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger() {
        if (Trigger.isDelete)
           TaskTriggerClass.beforeDeleteCheck(Trigger.old);
    }
    
    public override void afterInsertAfterUpdateTrigger() {

        if( Trigger.isInsert ){
        //TaskTriggerClass.sendEmailNotification(Trigger.New); 
        // SFDC-2338, MARIT-488 : removing calling to update activity as the code moved to TaskTriggerMarketingHandler
            //TaskTriggerClass.updateActivityCount(Trigger.New, 'Insert');
        }

        /*CR 2762544: rsharma: Start of code Addition
            Below code updates the last activity details on lead object when the task is inserted
            Few tasks are related with lead through Associated_AKAM_Lead_ID__c and few through Associated_AKAM_Account_ID__c And Associated_AKAM_Contact_ID__c
        */
        Id oaRecTypeId = TaskTriggerClass.GetOaRecTypeId();
        /* SFDC-4178
        List<Task> dealDeskOAActivities = new List<Task>();

        if(Trigger.isInsert){

            //List<Task> taskList = new List<Task>(); //Commented by Vivek as this functionality is no longer in use.
            String marketoAliases = GSMUtilClass.getGSMSettingValue('Marketo_Aliases');
            
            for (SObject tk:Trigger.new) {
                //SFDC-1034
                Task t = (Task)tk;
                if (t.Record_Type_RO__c == 'Standard_Activity' && !marketoAliases.containsIgnoreCase(t.akam_created_by__c)) {
                    taskList.add(t);
                } //Commented by Vivek as this functionality is no longer in use.

                if(t.RecordTypeId == oaRecTypeId && t.Task_Type__c == 'Deal Desk')
                {
                    system.debug('Taks Details for DD'+t);
                    dealDeskOAActivities.add(t);  
                }
            }
            //SFDC-1034
            if(!taskList.isEmpty()) //Commented by Vivek as this functionality is no longer in use.
                TaskTriggerClass.stampLastActivityOnAssociatedLead(taskList,(MAP<Id,Task>)Trigger.newMap);
            
        }

        */
        
        //Boolean firstRunFlagFor = L2Q_TaskTriggerClass.firstRunFlagForStampTQLSLACounter;
        Set<Id> taskRecordTypes = new Set<Id>();
        taskRecordTypes.add(Schema.SObjectType.Task.getRecordTypeInfosByName().get('Standard Activity').getRecordTypeId());
        taskRecordTypes.add(Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Rep Activity').getRecordTypeId());

        //if(dealDeskOAActivities.size()>0)
        //    OrderApprovalClass.DealDeskActivity_UpdateTask(dealDeskOAActivities);
        /*CR 2762544: rsharma: End of code Addition*/
        
        //Order Approval Activities
        //TaskTriggerClass.orderApprovalActivities(Trigger.New, Trigger.OldMap);


        SF1_NotificationSenderUtil.sendChatterFeedOnTaskCommentChange((List<Task>)Trigger.new, (Map<Id,Task>)Trigger.oldMap, (Boolean)Trigger.isInsert);
        
        //SFDC-2266
        if(Trigger.isUpdate) {

            Map<Id, Task> mapOfOpptyIdvsTask = new Map<Id, Task>();
            for(Task task: (List<Task>)newList) {
                system.debug(LoggingLevel.ERROR,'task.Subject in bi trigger:: '+task.Subject+' task.status: '+task.status+' condition:: '+GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject')+' Completed');
                if(task.Subject != null 
                    && task.Subject.equalsIgnoreCase(GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject')) 
                    && task.status.equalsIgnoreCase('Completed') 
                    && task.whatId != null 
                    && (task.whatId).getSObjectType() == Schema.Opportunity.SObjectType) {
                    // SFDC-2591
                        mapOfOpptyIdvsTask.put(task.whatId, task);
                    // END SFDC-2591
                    //create task for review
                    system.debug(LoggingLevel.ERROR,'will create task '+task.WhatId);
                }
            }
            // SFDC-2591
            if(mapOfOpptyIdvsTask.size() > 0) {
                TaskTriggerClass.validateRiskOfTransaction(mapOfOpptyIdvsTask);
            }
            // END SFDC-2591
        }

    }
    
    public override void afterDeleteAfterUndeleteTrigger() {
        // SFDC-2338, MARIT-488 : removing calling to update activity as the code moved to TaskTriggerMarketingHandler
        /*if(Trigger.old != null)
            TaskTriggerClass.updateActivityCount(Trigger.old, 'Delete'); 
        */
    }
}