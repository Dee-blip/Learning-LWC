({
    doInit : function(component, event, helper) {
        var action = component.get("c.getCaseInitialSetupDetails");
        action.setParams({
            "caseId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var resp=response.getReturnValue();
            component.set("v.overlayText",resp[0].SOCC_Image_Banner_Category__c);
        });
        $A.enqueueAction(action);
    }
})