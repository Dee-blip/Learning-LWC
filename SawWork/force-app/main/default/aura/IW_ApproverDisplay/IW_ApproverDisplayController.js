({
	doInit : function(component, event, helper) {
        var recId = component.get("v.recordId");
        var getWatchers = component.get("c.getApprovers");
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
            
            $A.enqueueAction(getWatchers);
        }
})