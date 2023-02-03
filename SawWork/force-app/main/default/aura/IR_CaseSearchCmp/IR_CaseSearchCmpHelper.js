({
	init : function(component, event, helper) {
		var action = component.get('c.getPicklistValues');
        action.setParams({
            objectApiName: 'Case',
            fieldApiName: 'Status' 
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                component.set("v.statusPicklist", resultData);
            }
        });
        $A.enqueueAction(action);
	}
})