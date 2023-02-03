({
	linkTask : function(component, event, helper) 
    {
		/*var urlEvent = $A.get("e.force:navigateToURL");
        var recordId=component.get("v.recordId");
        var url = "/apex/BMCServiceDesk__StdLayoutBtnToolbarPage?Id="+recordId+"&action=CreateIncidentTaskLink&incidentId="+recordId;
    	urlEvent.setParams({
    	"url": url
  	 	});
  	 	urlEvent.fire();*/
        
        var recordId = component.get("v.recordId");
        var actionUrl = component.get("c.getPage");
        
        actionUrl.setParams({
            currentId : recordId
        });
        actionUrl.setCallback(this,function(response){

            //window.open(response.getReturnValue(), '_blank'); 
            var urlEvent = $A.get("e.force:navigateToURL");
    		urlEvent.setParams({
        		"url":response.getReturnValue()                         
    		});
    		urlEvent.fire();  
            
            var toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
        		"message": "Creating and linking Task to Incident!"
    		});
    		toastEvent.fire();
            
    	});
        $A.enqueueAction(actionUrl);
        
        $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : 'SUCCESS' }).fire();
    }
})