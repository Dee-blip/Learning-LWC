({
    checkLogStatus:function (component,helper){  

        var myFunction = function() {
            console.log('Inside myFunction');
            let uniqueIdentifierValue = component.get("v.uniqueIdentifier");
            let action = component.get("c.getLogStatus");
            action.setParams({
                "uniqueIdentifierText": uniqueIdentifierValue
            })
            console.log('the value of uniqueIdentifierValue is '+uniqueIdentifierValue);
            action.setCallback(this, function(response) {
                console.log("Inside myServerSideFunction callback");
                console.log("the return value is: "+response.getReturnValue());
                if (response.getReturnValue() != null) {
                    component.set("v.spinner",false);
                    $A.get("e.force:closeQuickAction").fire();
                    console.log("Success: " + response.getReturnValue());
                    if(response.getReturnValue() === 'Success')
                        helper.showToast('Success', 'Incident Updated Successfully');
                    else if(response.getReturnValue() === 'Failed')
                        helper.showToast('Error', 'Incident Update Failed. Please retry');
                } else {
                    setTimeout($A.getCallback(myFunction), 1000);
                }
            });
            $A.enqueueAction(action);
        }
        myFunction();
    },
 
    showToast : function(type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : type,
            message: message,
            duration:' 5000',
            key: 'info_alt',
            type: type,
            mode: 'pester'
        });
        toastEvent.fire();
    }  
})