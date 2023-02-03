trigger IW_TriggerRQMap on Inv_Workbox_Region_Quarter_Mapping__c (	
	before insert, 
    before update,
    before delete,
    after insert, 
    after update,
    after delete,
    after undelete) {
        
        
	if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {


   ApexTriggerHandlerAbstractClass.createHandler('Inv_Workbox_Region_Quarter_Mapping__c');
    }
    
    /************************** Before Insert/Update Actions *********************************/
    /*if(Trigger.isBefore){
        
        if(Trigger.isInsert)
		{
            InvWB_RQMapHandler rqMap = new InvWB_RQMapHandler();
            rqMap.rQMapRecordsBeforeInsert(Trigger.new);
        }
        
        if(Trigger.isUpdate)
		{
            InvWB_RQMapHandler rqMap = new InvWB_RQMapHandler();
            rqMap.rQMapRecordsBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        
    }*/
    
    
}