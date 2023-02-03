({
	doLink : function(component, event, helper) {
		console.log('Inside Account List Controller to link');
        helper.linkAcc(component);
	},
    gotoRecord : function(component, event, helper) {
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": component.get("v.acc.Id"),
            "slideDevName": 'detail'
        })
        sObjectEvent.fire();
    }	
})