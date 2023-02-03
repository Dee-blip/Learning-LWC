({
    doInit : function(component, event, helper) {
        var key = component.get("v.key");
        var map = component.get("v.map");
        console.log(" MAP KEY -- "+key+" --- "+map[key].approverName);
        component.set("v.value" , map[key]);
    },
    approveReject:function(component, event, helper){
        var action = event.currentTarget.id;
        //get the id for approval target object
        component.set("v.action",action);
        component.set("v.isOpen",true);
    }
})