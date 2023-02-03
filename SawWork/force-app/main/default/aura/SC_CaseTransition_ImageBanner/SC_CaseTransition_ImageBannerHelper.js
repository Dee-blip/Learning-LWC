({
    getShiftName: function(component) {
        var action = component.get("c.getTargetShift");
        action.setParams({
            caseId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.targetShift", response.getReturnValue());
            }        
        });
         $A.enqueueAction(action);
    }
})