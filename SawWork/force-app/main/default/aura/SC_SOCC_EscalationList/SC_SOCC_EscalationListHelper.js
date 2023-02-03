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
    
    //Create new Escalation List - calling SC_SOCC_EsclationList_CreateEdit in subtab
    createEditEscalationList : function(component, event, helper){
        let pageReference = {
            "type": "standard__component",
            "attributes": {
                "componentName": "c__SC_SOCC_EscalationList_CreateEdit"
            },
            "state": {
                "c__pdId": component.get("v.pdId"),
                "c__operation": 'New'
            }
        };
        var workspaceAPI = component.find("workspace");
        //check if in console
        workspaceAPI.isConsoleNavigation().then(function(res) {
            if(res){
                workspaceAPI.getEnclosingTabId().then(function(enclosingTabId) {
                    workspaceAPI.openSubtab({
                        parentTabId: enclosingTabId,
                        pageReference: pageReference
                    }).then(function(subtabId) {
                        console.log("The new subtab ID is:" + subtabId);
                    }).catch(function(error) {
                        console.log("error");
                    });
                });
            }
            else{
                let navService = component.find("navService");
                event.preventDefault();
                navService.navigate(pageReference);
            }
        })
        .catch(function(err) {
            console.log(err);
        });
    },
    
    // this function is automatically called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.mainSpinner", true); 
    },
     
    // this function is automatically called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.mainSpinner", false);
    }
})