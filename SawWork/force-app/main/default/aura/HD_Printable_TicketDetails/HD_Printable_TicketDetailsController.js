({
	doInit : function(component, event, helper) {
        console.log("In init of Prinatble tickets");
        //var cmp = document.getElementById("sectionid");
        //console.log("Section component:");
        //console.log(cmp);
        var incId = component.get("v.recordId");
        console.log("Inc id in Printable Tickets: "+incId);
		var action = component.get("c.getIncidentDeatilsForPrint");
        action.setParams({
        		incidentId : incId
        });
        action.setCallback(this,function(data){
                var state = data.getState();
                var data = data.getReturnValue();
                
            if(state!= 'SUCCESS'){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false);
                return;
            }
                console.log("return value "+data);
            	console.log(data);
            console.log("Description: "+data.BMCServiceDesk__incidentDescription__c);
                component.set("v.incident",data);
    		});
        $A.enqueueAction(action);
	},
    print : function(component, event, helper) {
        $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : 'SUCCESS' }).fire();
        window.print();
	}
})