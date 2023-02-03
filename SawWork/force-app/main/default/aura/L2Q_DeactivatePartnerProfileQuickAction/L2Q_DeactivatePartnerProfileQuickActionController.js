({
    deactivatePartnerProfileJs: function (component, event, helper) {
        console.log('Here deactivatePartnerProfile');
        var deactivatePartnerProfileVar = component.get("c.deactivatePartnerProfile");
        deactivatePartnerProfileVar.setParams({
            "partnerProfileId": component.get("v.recordId")
        });
        deactivatePartnerProfileVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log('state: ' + state);
            if (state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                console.log('returnVal: ' + returnVal);
                if (returnVal.includes("Error")) {
                    console.log('Here: ');
                    // component.set("returnMessage", returnVal);
                    // component.set("hasErrors", true);
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "error",
                        "title": "Error",
                        "message": returnVal
                    });
                    resultsToast.fire();
                }
                else {
                    console.log('Here: ' + returnVal);
                    // component.set("returnMessage", returnVal);
                    // component.set("hasErrors", false);
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "type": "success",
                        "title": "Success",
                        "message": returnVal
                    });
                    resultsToast.fire();
                    //SFDC-6889 reload after 2 seconds
                    setTimeout(function () { window.location.reload() }, 2000);
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
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
        });
        $A.enqueueAction(deactivatePartnerProfileVar);
    }
})