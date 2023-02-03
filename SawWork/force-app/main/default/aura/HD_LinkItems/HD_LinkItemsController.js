({
	doInit : function(component, event, helper) {
		
        var action = component.get("c.getIncident");
            action.setParams({
        		incidentId : component.get("v.recordId")
      		});
        action.setCallback(this,function(data){
   			var retVal = data.getReturnValue();
            var isIncident;
            if(retVal.BMCServiceDesk__Type__c=='Service Request')
            {
                isIncident=false;
            }
            else
            {
                isIncident=true;
            }
            component.set("v.isInc",isIncident);
        });
            $A.enqueueAction(action);
	
	}
})