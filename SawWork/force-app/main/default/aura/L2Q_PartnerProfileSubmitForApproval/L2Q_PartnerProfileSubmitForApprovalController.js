({
    doInit: function (component, event, helper) {
        console.log('recordId of PP');
        console.log(component.get("v.recordId"));
        var getInitialDataVar = component.get("c.getFastTrackDetailsBeforeSubmission");
        getInitialDataVar.setParams({
            "partnerProfileId": component.get("v.recordId")
        });
        getInitialDataVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log('state: ' + state);
            if (state === "SUCCESS") {
                component.set("v.isAfterCallBack", true);
                var returnVal = response.getReturnValue();
                console.log('returnVal Fast Track: ' + returnVal);
                component.set("v.isProfileFastTracked", returnVal);
                component.set("v.fastTrackInitialValue", returnVal);

                if (returnVal) {
                    helper.submitForApprovalJS(component, event);
                }

            } else {
                var errors = response.getError();
                var returnMessage = '';
                if (errors) {
                    errors.forEach(function (ithError) {
                        returnMessage += ithError.message;
                    });
                }
                // component.set("returnMessage", returnMessage);
                // component.set("hasErrors", true);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type": "error",
                    "title": "Error",
                    "message": returnVal
                });
                resultsToast.fire();
            }
            //var dismissActionPanel = $A.get("e.force:closeQuickAction");
            //dismissActionPanel.fire();
        });
        $A.enqueueAction(getInitialDataVar);
    },

    submitForApproval: function (component, event, helper) {
        helper.submitForApprovalJS(component, event);
    }
})