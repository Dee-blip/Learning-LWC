public without sharing class TaskTriggerMarketingHandler extends ApexTriggerHandlerAbstractClass {

    public static Map<String, Id> recordTypeNameToIDMap = new Map<String, Id>();
    Id liveChatRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Live Chat').getRecordTypeId();

	    public override void beforeInsertBeforeUpdateTrigger() {
            if(Trigger.isInsert){
            	ISDC_TaskTriggerHandler.beforeInsertTask(Trigger.new);
        	}
            //MARIT-961
            List<Task> taskListToGetManagers = new List<Task>();
            Map<Id, String> ownerIDToManagerNameMap = new Map<Id, String>();
            List<Id> profileToEditDriftTasks = MarketingUtilClass.getMarketingSettingsValue('ProfilesToEditDriftTasks').split(',');
            Set<Id> profileAllowedToEditDriftTasks = new Set<Id>();
            profileAllowedToEditDriftTasks.addAll(profileToEditDriftTasks);
            
            
            List<RecordType> leadRecordTypeList = [select Id,Name from RecordType where sObjectType='Task'];
            for(RecordType rc: leadRecordTypeList){
                recordTypeNameToIDMap.put(rc.Name, rc.Id);
            }
            
            for(SObject so: newList){
                Task newTask = (Task)so;
                Task oldTask = Trigger.isUpdate ? (Task)oldMap.get(newTask.Id) : null;
                String ownerId = newTask.OwnerId;
                
                //copy over type tom custom type__c field
                if(Trigger.isInsert && newTask.Subject == 'Conversation in Drift'){
                    newTask.RecordTypeId = liveChatRecordTypeId;
                    if(newTask.Type == 'Live Chat'){
                        newTask.Type__c = newTask.Type;
                    }
                     //to-do later on asavie code will be merged here
                }
                //check user's profile if not admin/drift should not edit task created by Drift
                if(Trigger.isUpdate){
                    if(oldTask.Subject == 'Conversation in Drift' && !profileAllowedToEditDriftTasks.contains(userinfo.getProfileId()) && !(Util.hasChanges('WhoId',oldTask,newTask))){
                    newTask.addError('You cannot modify the task created for Drift Conversation');
                }
                }

                if((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('OwnerId',oldTask,newTask))) && 
                    (newTask.recordTypeId == recordTypeNameToIDMap.get('Managed Security Activity') || newTask.recordTypeId == recordTypeNameToIDMap.get('Standard Activity')) && 
                    ownerId.startsWith('005') ){
                        taskListToGetManagers.add(newTask);
                        ownerIDToManagerNameMap.put(newTask.OwnerId, null);
                }
            }            

            if(taskListToGetManagers != null && !taskListToGetManagers.isEmpty()){ //MARIT-961
                MARIT_TaskTriggerClass.getManagersForNewOners(taskListToGetManagers, ownerIDToManagerNameMap);
            }
        }
	    public override void beforeDeleteBeforeUndeleteTrigger() {
        }
    	public override void afterInsertAfterUpdateTrigger() {
            List<Id> taskMigrateToOpenCTADrift = new List<Id>();
            List<Id> stampOwnerOnCTA = new List<Id>();
            if(Trigger.isInsert){
                MARIT_TaskTriggerClass.innerUpdateActivityCount(Trigger.New, 'Insert');
            }
            for(SObject so: newList){   
                Task newTask = (Task)so;    
                Task oldTask = Trigger.isUpdate ? (Task)oldMap.get(newTask.Id) : null;  
                if(Trigger.isInsert && newTask.Subject == 'Conversation in Drift'){ 
                    taskMigrateToOpenCTADrift.add(newTask.Id);  
                }   
                
                if(Trigger.isUpdate && newTask.Subject == 'Conversation in Drift' && Util.hasChanges('WhoId',oldTask,newTask)){ 
                    stampOwnerOnCTA.add(newTask.Id);    
                }   
             }  
             //drift code to stamp the assigned to value of task on the cta
             if(stampOwnerOnCTA != null && !stampOwnerOnCTA.isEmpty()){ 
                MARIT_TaskTriggerClass.stampOwnerOnCTAFromAssignedTo(stampOwnerOnCTA);  
            }  
            //drift code to migrate the task to open cta if exists on person record 
            if(taskMigrateToOpenCTADrift != null && !taskMigrateToOpenCTADrift.isEmpty()){  
                MARIT_TaskTriggerClass.migrateTaskToOpenCTAFromPerson(taskMigrateToOpenCTADrift);   
            }
        }
	    public override void afterDeleteAfterUndeleteTrigger() {
            if(Trigger.old != null) {
            	MARIT_TaskTriggerClass.innerUpdateActivityCount(Trigger.old, 'Delete');
            }
        }
}