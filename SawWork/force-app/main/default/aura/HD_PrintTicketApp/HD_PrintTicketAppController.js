({
	doInit : function(component, event, helper) {
        var url = window.location.href;
        var incId = url.split("#")[1];
        component.set("v.incidentId",incId);	
        component.set("v.initComplete",true); 
        component.set("v.startTime",new Date());
        console.log("Inc id: "+component.get("v.incidentId"));

	}
})