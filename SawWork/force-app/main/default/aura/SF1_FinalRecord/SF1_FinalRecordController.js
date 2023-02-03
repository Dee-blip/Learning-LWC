({
	gotoRecord : function(cmp){
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": cmp.get("v.recordId"),
            "slideDevName": 'detail'
        })
        sObjectEvent.fire();
    }
})