// MARIT-10 or MARIT-140 Added by Ujjawal Somani on 17th Oct 2019
({
	getParentLead : function(component, event, helper) {
        var action = component.get("c.getParentLeadFromC2A");
        action.setParam('C2A_Lead_ID',component.get("v.recordId"));
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.activityData", response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
	}
})