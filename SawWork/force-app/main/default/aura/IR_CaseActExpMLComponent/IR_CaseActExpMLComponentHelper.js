({
	fetchManualLists : function(component, event, helper) {
		var action = component.get("c.getManualLists");
        var caseRecordId = component.get("v.recordId");
        action.setParams({
            caseId: caseRecordId 
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            //SUCCESS, ERROR or INCOMPLETE
            if(state=='SUCCESS'){
                var manualLists = response.getReturnValue();
                component.set('{!v.activeManualLists}', manualLists['active']);
                component.set('{!v.expiredManualLists}', manualLists['expired']);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error! Please contact administrator.");
                }
            }
        })

        $A.enqueueAction(action);
	},

    setSectionHeight: function(component){
    	var scrollableDiv = component.find("scrollable");

        var amlHeight = component.get("v.activeManualLists").length > 1 ? 300 : (component.get("v.activeManualLists").length)*200;
        var emlHeight = component.get("v.expiredManualLists").length > 1 ? 300 : (component.get("v.expiredManualLists").length)*200;
        var borderStyle = 'border-top: 1px solid rgb(221, 219, 218);border-bottom: 1px solid rgb(221, 219, 218);';
        var amlStyle = 'height:'+amlHeight+'px;'+borderStyle;
        var emlStyle = 'height:'+emlHeight+'px;'+borderStyle;
        if (component.get("v.activeManualLists").length > 0 && scrollableDiv != undefined)
        	scrollableDiv[0].getElement().setAttribute('style', amlStyle);
        if (component.get("v.expiredManualLists").length > 0 && scrollableDiv != undefined)
        	scrollableDiv[1].getElement().setAttribute('style', emlStyle);
	}
})