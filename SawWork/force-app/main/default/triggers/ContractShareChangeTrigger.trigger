trigger ContractShareChangeTrigger on Contract_Share__ChangeEvent (after insert) {
    
 Set<Id> csInsertRecordIdSet = new Set<Id>();
 //Set<Id> csDeleteRecordIdSet = new Set<Id>();
 Map<Id,Id> parentContractToUserIdMap = new Map<Id,Id>();
 List<String> csDeleteRecordsIds = new List<String>();
    for(Contract_Share__ChangeEvent csEvent : Trigger.New)
    {
       EventBus.ChangeEventHeader header = csEvent.ChangeEventHeader;
       List<Id> csDeleteRecordIdSet = csEvent.ChangeEventHeader.getRecordIds();
        if(header.changeType == 'CREATE')
         {
            
             List<Id> csRecordIdInsertList = csEvent.ChangeEventHeader.getRecordIds();
             csInsertRecordIdSet.addAll(csRecordIdInsertList);
             ContractSharing.addMergeContractHeaderShare(csInsertRecordIdSet);
         }
        if(header.changeType == 'DELETE')
         {
            csDeleteRecordsIds.addAll(csEvent.ChangeEventHeader.getRecordIds());
             ContractSharing.removeMergeContractHeaderShare(csDeleteRecordsIds);
            system.debug('Related Map '+csDeleteRecordsIds);

         }
            
    }
 

}