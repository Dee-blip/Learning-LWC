({
    doInit: function(component, event, helper) {
        
        var action = component.get("c.getContactEmailAddress");
        action.setParams({
        });
        action.setCallback(this, function(response) {
            var resp=response.getReturnValue();
            //alert(resp);
            helper.createCookie('CustomerEmailID',resp, 3650);
            
        });
        $A.enqueueAction(action);
        
    }
})