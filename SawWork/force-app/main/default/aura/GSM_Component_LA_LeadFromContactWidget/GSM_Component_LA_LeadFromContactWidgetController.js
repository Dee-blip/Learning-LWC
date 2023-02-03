({
    doInit: function(component, event, helper) 
    {
       var action = component.get("c.ShowC2AOnLoad");
        action.setParams({
            "liveChatTranscriptId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") 
            {
                var responseVal = response.getReturnValue();
                if (responseVal !== null) {
                    component.set("v.c2aRecordId", responseVal);
                    component.set("v.showC2AFields", true);
                } else {
                    component.set("v.showC2AFields", false);
                }
            }
        });
        $A.enqueueAction(action); 
    },
    
    validateAndCreateLeadFromContact : function(component, event, helper) 
    {
        component.set("v.isLoad",true);
        var validateAction = component.get("c.validateTranscriptRecord");
        validateAction.setParams({
                        "liveChatTranscriptId": component.get("v.recordId")
                    });
    
        validateAction.setCallback(this, function(response) 
        {
            var state = response.getState();
        
            if (component.isValid() && state === "SUCCESS") 
            {
                var responseVal = response.getReturnValue();
                if(responseVal.includes('Error')) {
                    component.set("v.errorMessage",responseVal);
                    component.set("v.isError",true);
                    component.set("v.isLoad",false);
                } else if(responseVal.includes('Success')) {
                    component.set("v.errorMessage","");
                    component.set("v.isError",false);
                    helper.checkIfLeadPresent(component, event, helper);
                }
            }
        });
        $A.enqueueAction(validateAction);    
    },
    closeError : function(component, event, helper) {
        component.set("v.isError",false);
    }
})