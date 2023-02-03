({
    /**
     * showToast method is used to display toast messages to users
     * @param {string} title : specify title for a message to display
     * @param {string} message : custom message to display in the toast
     * @param {string} type : error, warning, success, or info
     * @param {string} mode : 'pester', 'sticky'. The default is 'dismissible'
     */
    showToast: function (title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            duration: ' 5000',
            key: 'info_alt',
            type: type,
            mode: mode
        });
        toastEvent.fire();
    },

    /**
     * validate method is used to check if the quote conditions are valid to submit it for approval
     * quote should be primary and OA lookup should not be null
     * if quote is valid, it calls the submitAction method
     */
    validate: function (component, event) {
        var valid = true;
        var oaValue = component.get('v.simpleRecord.CPQ_Order_Approval__c');
        var primaryValue = component.get('v.simpleRecord.CPQ_Primary__c');

        if (oaValue === null || oaValue === '' || oaValue === undefined) {
            valid = false;
            var label = $A.get("$Label.c.CPQ_Approval_applicable_for_quotes_with_Order_Approval");
            $A.get("e.force:closeQuickAction").fire();
            this.showToast('Error!', label, 'error', 'sticky');

        }
        if (!primaryValue) {
            valid = false;
            var label = $A.get("$Label.c.CPQ_Approval_applicable_for_primary_quotes");
            $A.get("e.force:closeQuickAction").fire();
            this.showToast('Error!', label, 'error', 'sticky');
        }

        if (valid) {
            //if no error, then call submit action
            component.set("v.validQuote", valid);
            this.submitAction(component, event);
        }

    },
    /**
     * submitAction method is called if the quote is valid for approval submission
     * it calls the apex method to submit the qoute approval process
     */
    submitAction: function (component, event) {
        var action = component.get("c.onSubmit");
        action.setParams({ quoteId: component.get("v.recordId") });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Refresh the Record
                $A.get('e.force:refreshView').fire();
                // Close the Component
                $A.get("e.force:closeQuickAction").fire();
                // Optionally Alert user with Success Message
                this.showToast('Success!', 'Submitted for Approval', 'success', 'pester');
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
                helper.showToast('Error!', 'Submitting for Approval Failed', 'error', 'sticky');
            }
        });
        $A.enqueueAction(action);
    }
})