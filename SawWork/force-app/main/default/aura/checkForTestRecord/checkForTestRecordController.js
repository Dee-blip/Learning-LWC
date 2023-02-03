({
	init : function(component, event, helper) {
        var rId = component.get("v.recordId");
        console.log('The ID is: ' + rId);
            helper.callController(component);            
	}
    
})