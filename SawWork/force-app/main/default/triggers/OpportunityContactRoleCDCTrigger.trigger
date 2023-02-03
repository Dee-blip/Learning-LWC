trigger OpportunityContactRoleCDCTrigger on OpportunityContactRoleChangeEvent (after insert) {
    Set<Id> ocrIds = new Set<Id>();
    for(OpportunityContactRoleChangeEvent ocrEvent : Trigger.New){
        list<Id> ocrIdList = ocrEvent.ChangeEventHeader.getRecordIds();
        ocrIds.addAll(ocrIdList);
    }
    if(!ocrIds.isEmpty()){
        OpportunityContactRoleCDCTriggerClass.handleEvents(ocrIds);
    }
}