({
	setErrorMessage : function(component, event, helper) {
        console.log("Inside Parent Event Handler ");
		var ShowMessage = event.getParam("message");
        var ErrorFlag   = event.getParam("ShowError");
        component.set("v.message", ShowMessage);
        component.set("v.ShowError",ErrorFlag);
	},
    
})