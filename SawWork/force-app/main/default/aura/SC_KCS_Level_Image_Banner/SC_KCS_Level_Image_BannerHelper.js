({
    getShiftName: function(component) {
        var action = component.get("c.Get_User_Details");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.User_KCS_details", response.getReturnValue());
            }        
        });
         $A.enqueueAction(action);
    }
})