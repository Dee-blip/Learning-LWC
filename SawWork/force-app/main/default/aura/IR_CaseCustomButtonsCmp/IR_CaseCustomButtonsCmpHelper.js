({
	handleSubmit : function(component, event, helper) {
		var buttonId = event.getSource().getLocalId();
        var action = component.get("c.handleButtonClick");
        component.set("v.showSpinner", true );
        action.setParams({
            pAction: buttonId,
            pCaseId: component.get("v.recordId")
        }); 

        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.showSpinner", false );
                var result = response.getReturnValue();
                //e.g. 0:Unknown Error, 1:Successfully updated the Case Owner
                //0 is failure and 1 is success
                helper.showToast(component, event, helper, result.split(':')[0], result.split(':')[1]);
            }
            else if (state === "ERROR") {
                component.set("v.showSpinner", false );
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                helper.showToast(component, event, helper, 'error', 'Something went wrong! Please contact administrator.');
            }
        })

        $A.enqueueAction(action);
	},

    showToast : function(component, event, helper, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : (type == 0 ? 'Error Message' : 'Success'),
            message: message,
            duration: '5000',
            key: 'info_alt',
            type: (type == 0 ? 'error' : 'success'),
            mode: 'dismissible '
        });
        toastEvent.fire();
    }
})