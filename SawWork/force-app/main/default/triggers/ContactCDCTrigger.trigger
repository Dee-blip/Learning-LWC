trigger ContactCDCTrigger on ContactChangeEvent (after insert) {
	List<EventBus.ChangeEventHeader> changeEventHeaders = new List<EventBus.ChangeEventHeader>();
    for (ContactChangeEvent event : Trigger.New) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
		changeEventHeaders.add(header);      
    }   
    if ((changeEventHeaders.size() > 0) && (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('SyncDataFromSalesforceToSiebel') || Test.isRunningTest())) {
       CDCEventHandler.handlePublishEvent(changeEventHeaders); 
    }
}