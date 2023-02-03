({
    checkIfLeadPresent : function(component, event, helper) {
        var checkLeadAction = component.get("c.isLeadPresent");
        checkLeadAction.setParams({
            "liveChatTranscriptId": component.get("v.recordId")
        });
        
        checkLeadAction.setCallback(this, function(response) {
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                var responseVal = response.getReturnValue(); 
                if (responseVal === 'No Lead Present') {
                    component.set("v.loadMessage","Creating lead ...");
                    var action = component.get("c.createLeadFromContact");
                    action.setParams({
                        "liveChatTranscriptId": component.get("v.recordId")
                    });
                    
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        
                        if (component.isValid() && state === "SUCCESS") {
                            var responseVal = response.getReturnValue();
                            if(responseVal.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")){
                                var pat = "FIELD_CUSTOM_VALIDATION_EXCEPTION";
                                component.set("v.errorMessage",responseVal.substring(responseVal.indexOf(pat) + pat.length + 2));
                                component.set("v.isError",true);
                                component.set("v.isLoad",false);
                            } else if(responseVal.includes('Open Opportunity') || responseVal.includes('Error')) {
                                component.set("v.errorMessage",responseVal);
                                component.set("v.isError",true);
                                component.set("v.isLoad",false);
                            } else {
                                $A.get('e.force:refreshView').fire();
                                this.showC2AAfterCreation(component, event, helper, responseVal);
                            }
                        }
                        else
                        {
                            component.set("v.errorMessage","Some Error Occured");
                            component.set("v.isError",true);
                        }
                    });
                    $A.enqueueAction(action);
                } else if (responseVal.startsWith('00Q')) {
                    var action = component.get("c.linkC2AToLiveChat");
                    component.set("v.loadMessage","Linking lead ...");
                    action.setParams({
                        "liveChatTranscriptId": component.get("v.recordId"),
                        "c2aId": responseVal
                    });
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (component.isValid() && state === "SUCCESS") {
                            $A.get('e.force:refreshView').fire();
                            this.showC2AAfterCreation(component, event, helper, responseVal);
                        }
                    });
                    $A.enqueueAction(action);
                }
            }
        });
        $A.enqueueAction(checkLeadAction);
    },
    
    showC2AAfterCreation : function(component, event, helper, c2aId) {
        component.set("v.isError",false);
        component.set("v.isLoad",false);
        component.set("v.c2aRecordId", c2aId);
        component.set("v.showC2AFields", true);
    }
})