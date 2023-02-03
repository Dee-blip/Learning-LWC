({
	refreshDraftInv : function(component, event, helper) {
		var refresh = component.get("c.refreshDraftInvoice");
        refresh.setParams({
            draftInvoiceId: component.get("v.recordId")
        }); 

        component.set('v.spinner', true);
        refresh.setCallback(this, function(response){
            var state = response.getState();
            if(state=='SUCCESS'){
                var result = response.getReturnValue();
                var type = Object.keys(result)[0];
                helper.showToast(component, event, helper, type, result[type]);
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error! Please contact administrator.");
                }
                helper.showToast(component, event, helper, 'error', 'Something went wrong!  Please contact administrator.');
            }
        component.set('v.spinner', false);
        });
        $A.enqueueAction(refresh);
	},

    showToast : function(component, event, helper, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : (type == 'error' ? 'Error Message' : 'Success'),
            message: message,
            duration: '5000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    }
})