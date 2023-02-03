({
	initializeHelper: function(component) {
        var action = component.get("c.getStartURL");
        action.setCallback(this, function(resp){
            var startURL = resp.getReturnValue();
            window.open(startURL, "_top");
        });
        $A.enqueueAction(action);
    },
})