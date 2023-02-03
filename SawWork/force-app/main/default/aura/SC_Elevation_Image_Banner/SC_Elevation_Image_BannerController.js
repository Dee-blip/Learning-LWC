({
    redirectToElevRec: function (component) {
        var caseAccountId; var state;
        var action = component.get("c.returnCaseAccountId");
        action.setParams({
            "caseId": component.get("v.recordId")
        });

        action.setCallback(this, function (response) {
            state = response.getState();
            if (state === "SUCCESS") {
                caseAccountId = response.getReturnValue();
                if (caseAccountId != null) {
                    // Create Case Record With Default Values
                    $A.get("e.force:navigateToURL").setParams({
                        "url": '/lightning/r/Account/' + caseAccountId + '/related/Elevations__r/view'
                    }).fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})