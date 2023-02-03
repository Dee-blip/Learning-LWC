trigger ChatterPulseUserStatusUpdates on User (before update) {
    
    //SFDC-1314 - Code scanner fixes 
    Set<Id> setOfUserIdsWithChangedCurrentStatus = new Set<Id>();
    for(User userObj : Trigger.new)
    {
    	if(userObj.CurrentStatus!=Trigger.oldMap.get(userObj.Id).CurrentStatus)
    		setOfUserIdsWithChangedCurrentStatus.add(userObj.Id);
    }

    if(setOfUserIdsWithChangedCurrentStatus.size()>0)
    ChatterPulseUser.PulseAdd(setOfUserIdsWithChangedCurrentStatus);

}