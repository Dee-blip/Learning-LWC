({
    /**
    * handleConfirm method is called when user clicks on Confirm button
    * it calls the apex method to recall the qoute approval process
    */
    handleConfirm: function (component, event, helper) {
        component.set("v.confirmed", true);
        var action = component.get("c.onRecall");
        action.setParams({ quoteId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Refresh the Record
                $A.get('e.force:refreshView').fire();
                // Close the Component
                $A.get("e.force:closeQuickAction").fire();
                // Optionally Alert user with Success Message
                helper.showToast('Approvals Recalled', 'You will need to resubmit', 'warning', 'pester');
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
                // Refresh the Record
                $A.get('e.force:refreshView').fire();
                // Close the Component
                $A.get("e.force:closeQuickAction").fire();
                // Optionally Alert user with Success Message
                helper.showToast('Error!', 'Recall Failed', 'error', 'sticky');
            }
        });
        $A.enqueueAction(action);
    },

    /**
    * handleClose method is called when user clicks on Cancel button
    * it closes the quick action screen
    */
    handleClose: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})