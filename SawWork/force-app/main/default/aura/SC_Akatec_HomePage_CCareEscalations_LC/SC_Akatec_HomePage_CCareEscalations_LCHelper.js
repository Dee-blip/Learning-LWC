({
    CcarePoller: function(component, event, helper, selectedEscOptionValue){
        component.set("v.spinner","true");
        
        var action = component.get("c.getMyEscalations");
        if (action != null){
            action.setParams({
                "QueryType":selectedEscOptionValue
            });
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    var myopenlst=response.getReturnValue();
                    console.log("esc",myopenlst);
                    component.set("v.OpenEscalation", myopenlst);
                    component.set("v.OpenCount", myopenlst.length);
                    component.set("v.spinner","false");
                    
                }
                
            });
            $A.enqueueAction(action);
        }
        
    },
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    }
})