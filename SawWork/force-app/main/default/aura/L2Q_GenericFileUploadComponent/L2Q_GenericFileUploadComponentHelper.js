({
    uploadAttachmentsHelper: function (component) {
        console.log("uploadAttachmentsHelper");
        var action = component.get("c.getTheAttachedFileList");
        action.setParams({
            'recordId': component.get("v.recordId")
        });
      
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var returnVal = response.getReturnValue();
                if (returnVal.length == 0) {
                    component.set("v.noFileAttached", true);
                } else {
                    component.set("v.noFileAttached", false);
                }
                component.set("v.listOfAttachedFiles", returnVal);
            } else {
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state)")
            }
        });
        $A.enqueueAction(action);
    }
})