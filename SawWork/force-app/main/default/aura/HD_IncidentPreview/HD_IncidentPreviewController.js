({
	
    updateincidentEvent : function(component, event){
        var newincident = component.get("v.newincident");
        var eventparam = event.getParam("incident");
        component.set("v.newincident",eventparam);
        console.log('They Fired me !'+event.getName());
    }
})