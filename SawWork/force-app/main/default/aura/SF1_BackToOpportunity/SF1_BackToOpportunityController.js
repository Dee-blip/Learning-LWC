({
	Navigate : function(component, event, helper) {
         var sObjectEvent = $A.get("e.force:navigateToSObject");
		     sObjectEvent.setParams({
                    "recordId": component.get("v.recordId"),
                    "slideDevName": 'detail'
		    })
             
             sObjectEvent.fire();
             $A.get('e.force:refreshView').fire();
            }
})