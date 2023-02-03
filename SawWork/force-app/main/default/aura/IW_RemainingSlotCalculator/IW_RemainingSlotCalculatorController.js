({
	doInit : function(component, event, helper) {
		var action = component.get("c.getRgionAccountSlot");
        console.log("account id " + component.get("v.recordId"));
        action.setParams({ iwId : component.get("v.recordId"), requestParam : "NA"});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var slotsRemaining = 100 - response.getReturnValue();
                slotsRemaining = Math.round(slotsRemaining*100)/100
                console.log("response received " + response.getReturnValue());
                component.set("v.slotsRemaining",response.getReturnValue());
                component.set("v.slotsUtilized",slotsRemaining);
                console.log("slotsRemaining " + response.getReturnValue());
                console.log("slotsUtilized " + slotsRemaining);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);  
	}
})