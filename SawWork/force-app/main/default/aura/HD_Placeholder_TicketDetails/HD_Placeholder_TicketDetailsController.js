({
    doInit : function(component, event, helper) {
        var action = component.get("c.getIncType");
        var ticketId = component.get("v.recordId");
        console.log("Ticket Id: "+ticketId);
        action.setParams({
            incId : ticketId    
        });
        
        action.setCallback(this,function(data){
        	var data = data.getReturnValue();
            console.log('Data received');
            console.log(data);
            component.set("v.incType",data);
            console.log("Set inc type: ");
            console.log(component.get("v.incType"));
    });
        $A.enqueueAction(action);
    }
})