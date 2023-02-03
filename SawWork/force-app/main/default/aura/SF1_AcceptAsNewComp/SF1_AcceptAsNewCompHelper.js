({
	create : function(cmp) {
		var action = cmp.get("c.getCreate");
        action.setParams({
            "oppId": cmp.get("v.oppId")
        });
        action.setCallback(this, function(response) {
			var state = response.getState();
			if (cmp.isValid() && state === "SUCCESS") {
                
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": cmp.get("v.oppId"),
                    "slideDevName": 'detail'
                })
				navEvt.fire();
            }
         });
        $A.enqueueAction(action);
	},
    
})