({
	init : function(component, event, helper) {
        
        var exeAction = component.get("c.getAUURL");
            helper.serverSideCall(component,exeAction).then(
                function(response) {
                    var auURL = response;
                    console.log('SH : defaultValues :'+auURL);
                    component.set("v.urlValue", auURL);
                    component.set("v.target", '_blank');
                    component.set("v.loadComponent","true");
                    
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": auURL
                    });
                    urlEvent.fire();
                }
            ).catch(
                function(error) {
                    component.set("v.status" ,error); 
                    console.log(error);
                }
            );
	}
})