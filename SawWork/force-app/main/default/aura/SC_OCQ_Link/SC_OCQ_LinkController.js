({
	doInit : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        var action = component.get("c.getOCQLink");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var returnURL = response.getReturnValue();
                if(returnURL != null){
                    var completeURL = returnURL + "&KBid=" + recordId;
                    component.set("v.OCQLink", completeURL);
                }
            	else
                    helper.showToastMessage(component, event, helper,'Error','No URL present in the OCQ Link to redirect.','Error','dismissible');
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Something went wrong with OCQ Link component.','Error','sticky');
        });
        $A.enqueueAction(action);
	}
})