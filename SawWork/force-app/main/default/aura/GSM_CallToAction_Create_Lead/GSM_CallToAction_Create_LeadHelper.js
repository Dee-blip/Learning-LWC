({
    checkIfLeadExists : function(component) {
        // We can use this as a async function to be called during component initialization 
        // By the time user will enter details in the controls, async method will check whether lead exists/not
        // This is something we can keep in mind for the future.
        var leadAction = component.get("c.callToActionLeadExists");
        leadAction.setParams({
            "genericRecordID" :component.get("v.recordId"),
            "changeOwner" :false
        });
        
        leadAction.setCallback(this, function(data) {
            var state = data.getState();
            
            if (component.isValid() && state == "SUCCESS"){
                var leadId = null;
                var result = data.getReturnValue();
                console.log('Show Page '+result +'generic Record '+component.get("v.recordId"));
                var returnVal = result.split(":");
                console.log('Return val 0 '+returnVal[0]);
                // returnVal[0] == 0 means that there is no C2A exists with status :  New/ InProcess, We can create a C2A in this case
                // else we need to redirect which might later on creates activity. 
                if(returnVal[0] == 0) {
                    if(returnVal[1] == 'Contact') {
                        console.log('Inside Contact');
                        this.parentCreateLead(component);
                    }
                } else if(returnVal[0] == '1' || returnVal[0] == '2') {
                    this.showLeadRedirectMessage(component, returnVal[1]);
                }
            }
        });
        $A.enqueueAction(leadAction);
    },
    createActivtyAndRedirect: function(component) {
        var recordId = component.get("v.c2aRecordId");
        var locationURL = '/' + recordId;    
        var theme = null;
        
        var action = component.get("c.creteActivityAndGetUITheme");
        action.setParams({
            "productSelected" :component.get("v.productSelected"),
            "leadTypeSelected" :component.get("v.leadTypeSelected"),
            "Notes" :component.get("v.Notes"),
            "WhatId" : recordId
        });
        action.setCallback(this, function(a) {
            if (component.isValid()){
                theme = a.getReturnValue();
                console.log('theme '+theme);
                if(theme == "Theme4t")
                {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": locationURL
                    });
                    urlEvent.fire();}
                else
                    window.parent.location = '/' + recordId; 
            } 
        });
        $A.enqueueAction(action);
    },
    parentsetLeadExists : function(component) {
        var childComp = component.find('ContactToLeadCreateComponent');
        childComp.setLeadExists();
    },
    parentCreateLead : function(component) {
        var childComp = component.find('ContactToLeadCreateComponent');
        childComp.createC2ALead();
    },
    showLeadRedirectMessage : function (component, c2aId) {
        component.set("v.showContactComponent",false); 
        component.set("v.showSDRReassignMessage",true); 
        component.set("v.c2aRecordId",c2aId);
        this.parentsetLeadExists(component);
    }
})