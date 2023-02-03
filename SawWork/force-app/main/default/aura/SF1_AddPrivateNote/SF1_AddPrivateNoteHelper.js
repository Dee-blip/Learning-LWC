({
    accessAllowedToCurrentUserProfile : function(cmp)
    {
        var action = cmp.get("c.accessAllowedToCurrentUserProfile");
        action.setParams({
        
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var accessAllowed = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.accessAllowed",accessAllowed);
            }
            
        });
        $A.enqueueAction(action);
    },
    getPageObject : function(cmp)
    {
        var action = cmp.get("c.getPageObject");
        action.setParams({
            "recordID" : cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var pageObject = response.getReturnValue();
            if (cmp.isValid() && state === "SUCCESS") 
            {   
                cmp.set("v.pageObject",pageObject);
            }
            
        });
        $A.enqueueAction(action);
    },
    saveTheNote : function(cmp)
    {
        
        var action = cmp.get("c.saveNote");
        action.setParams({
            "pageObject"  : cmp.get("v.pageObject")
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var message = response.getReturnValue();
            var navEvt = $A.get("e.force:navigateToSObject");
                
            if (cmp.isValid() && state === "SUCCESS" && message==='success') 
            {   
                   cmp.set("v.showError",false);
                   navEvt.setParams({
                        "recordId": cmp.get("v.recordId"),
                        "slideDevName": "detail"
                	});
                   
                   navEvt.fire();
                   $A.get('e.force:refreshView').fire();
            }
            else if(cmp.isValid() && state === "SUCCESS" && message!=='success')
            {
                cmp.set("v.message",message);
                cmp.set("v.showError",true);
            }
            
        });
        
        $A.enqueueAction(action); 
    }
})