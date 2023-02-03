({
    doInit : function(component) {
        var action = component.get("c.getIncType");
        var ticketId = component.get("v.recordId");
        console.log("Ticket Id: "+ticketId);
        action.setParams({
            incId : ticketId    
        });
        
        action.setCallback(this,function(data){
            var dataValue = data.getReturnValue();
            console.log('Data received');
            console.log(dataValue);
            component.set("v.incType",dataValue);
            console.log("Set inc type: ");
            console.log(component.get("v.incType"));
        });
        $A.enqueueAction(action);
    },
    handleForceRefreshViewForLWC: function (component) {
        component.find("clientDetailLWC").fireRefresh();
    }
})