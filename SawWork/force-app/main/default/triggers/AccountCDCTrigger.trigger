trigger AccountCDCTrigger on AccountChangeEvent (after insert) {
    List<EventBus.ChangeEventHeader> changeEventHeaders = new List<EventBus.ChangeEventHeader>();
    List<EventBus.ChangeEventHeader> changeUpdateEventHeaders = new List<EventBus.ChangeEventHeader>(); //SFDC-6594
    for (AccountChangeEvent event : Trigger.New) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
		changeEventHeaders.add(header);
        //SFDC-6594
        if(header.changetype == 'UPDATE')
            changeUpdateEventHeaders.add(header);
    }   
    if(changeEventHeaders.size() > 0 && (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('SyncDataFromSalesforceToSiebel') || Test.isRunningTest())) {
       CDCEventHandler.handlePublishEvent(changeEventHeaders); 
    }
    //SFDC-6594
    if(changeUpdateEventHeaders.size()>0){
        CDCEventHandler.handleAccountOwnerUpdate(changeUpdateEventHeaders);
    }
}