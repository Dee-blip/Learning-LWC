({
	doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var getWatchers = component.get("c.getWatchers");
            getWatchers.setParams({
                "recordIWID" : recId,
            });
            getWatchers.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var userResult = result.getReturnValue();
                    component.set("v.selectedLookUpRecords",userResult); 
                }
                else{
                    console.log('Failed with state: ' + state);
                }
            });
        
          var getWatchersAccess = component.get("c.getWatchersAccess");
            getWatchersAccess.setParams({
                "recordIWID" : recId,
            });
            getWatchersAccess.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    var userResult = result.getReturnValue();
                    component.set("v.saveAccess",userResult); 
                }
                else{
                    console.log('Failed with state: ' + state);
                }
            });
            
            $A.enqueueAction(getWatchers);
        	$A.enqueueAction(getWatchersAccess);
        },
    
    addNewWatchers: function(component, event, helper){
        var watcherList = component.get("{!v.selectedLookUpRecords}") !== undefined ? component.get("{!v.selectedLookUpRecords}") : null;
        var recId = component.get("v.recordId");
        if(watcherList !== null){
            console.log('---Watcher List---'+JSON.stringify(watcherList));
            var getWatchers = component.get("c.saveWatchers");
            getWatchers.setParams({
                "watcherList" : JSON.stringify(watcherList),
                "recId" : recId
            });
            getWatchers.setCallback(this, function(result){
                var state = result.getState();
                if (component.isValid() && state === "SUCCESS"){
                    
                    var userResult = result.getReturnValue();
                    console.log('userResult:::'+userResult);
                    component.set("v.selectedLookUpRecords",userResult);
                    $A.enqueueAction(component.get("c.doInit"));
                    $A.get('e.force:refreshView').fire();
                }
                else{
                    console.log('Failed with state: ' + state);
                }
            });
            
            $A.enqueueAction(getWatchers);
        }
    },
})