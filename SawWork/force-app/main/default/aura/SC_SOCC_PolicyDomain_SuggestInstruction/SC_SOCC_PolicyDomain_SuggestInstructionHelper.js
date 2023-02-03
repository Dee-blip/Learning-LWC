({
    //Generic toast message method
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode,duration_in_ms) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Saved!',
            duration:duration_in_ms,
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    
    //Togger spinner visibility
    toggle: function (component, event) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    }
})