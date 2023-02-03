({
    submitForApprovalJS: function (component, event) {
        var submitForApprovalVar = component.get("c.submitPartnerProfileForApproval");
        var hasFastTrackChangedVar = false;
        if (component.get("v.fastTrackInitialValue") != component.get("v.isProfileFastTracked")) {
            hasFastTrackChangedVar = true;
        }
        submitForApprovalVar.setParams({
            "partnerProfileId": component.get("v.recordId"),
            "fastTrack": component.get("v.isProfileFastTracked"),
            "hasFastTrackChanged": hasFastTrackChangedVar,
        });
        submitForApprovalVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log('state: ' + state);
            if (state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                console.log('returnVal Fast Track: ' + returnVal);
                if (returnVal != undefined && returnVal != '' && returnVal != "SUCCESS") {
                    component.set("v.hasErrors", true);
                    component.set("v.returnMessage", returnVal);
                }
                else {
                    component.set("v.hasErrors", false);
                    component.set("v.returnMessage", returnVal);
                    //reload after 2 seconds
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
            //var dismissActionPanel = $A.get("e.force:closeQuickAction");
            //dismissActionPanel.fire();
        });
        $A.enqueueAction(submitForApprovalVar);
    }
})