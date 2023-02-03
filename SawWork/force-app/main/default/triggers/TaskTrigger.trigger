/*****************************************************************************
 * Name             : TaskTrigger
 * Created By       : Pitamber Sharma
 * Created Date     : 03-May-2013
 * Purpose          : Activity LOE Roll up Trigger
 ****************************************************************************
 * Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.
 * Sheena Bhan			 20/10/2020		   ESESP-3767 - IRAPT - Calculate sum of Task LOE on Service Incident Activity Tasks
 */
trigger TaskTrigger on Task (after delete, after insert, after undelete, after update,before update,before insert) {
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
		TaskTriggerHandler handler = new TaskTriggerHandler();
		if(Trigger.isAfter) {
			if(Trigger.isInsert) {
				handler.onAfterInsert(Trigger.New);
			}
			if(Trigger.isUpdate) {
				handler.onAfterUpdate(Trigger.New);
			}
			if(Trigger.isDelete) {
				handler.onAfterDelete(Trigger.Old);
                // Changes by Sheena - ESESP 3767 - Calculate sum of Task LOE on Service Incident Activity Tasks
                SC_TaskTriggerHandler.onAfterDelete(Trigger.Old);
                // Changes End
                // Changes by Bhavesh - ESESP 3590 - Calculate sum of Task LOE on RCA Tasks
                SC_TaskTriggerHandler.onAfterDeleteRCA(Trigger.Old);
                // Changes End
			}
			if(Trigger.isUnDelete) {
				handler.onAfterUndelete(Trigger.New);
			}
		}
		if(Trigger.isBefore){
			List<Task> lstTask = new List<Task>();

			if(Trigger.isInsert)
			lstTask = Trigger.new;

			if(Trigger.isUpdate){
				for(Task sObjTask : trigger.new){
						if(sObjTask.Subject != trigger.oldMap.get(sObjTask.Id).Subject){
							lstTask.add(sObjTask);
						}
				}
			}   
			if(lstTask.size() > 0)
			handler.updateTypeAndInternalOnly(lstTask);    
		}
	}	
}