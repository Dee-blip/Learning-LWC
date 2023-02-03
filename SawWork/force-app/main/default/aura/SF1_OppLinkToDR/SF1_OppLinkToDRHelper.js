({
    gotoRecord : function(cmp){
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        sObjectEvent.setParams({
            "recordId": cmp.get("v.oppty.Id"),
            "slideDevName": 'detail'
        })
        sObjectEvent.fire();
    },

    linkToDR : function(cmp){
        var action = cmp.get("c.getAddOppty");
        action.setParams({
                "pid": cmp.get("v.oppty.Id"),
                "opptyId": cmp.get("v.parent_oppty_id")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var message = response.getReturnValue();
            var navEvt = $A.get("e.force:navigateToSObject");
            
            if (cmp.isValid() && state === "SUCCESS"  && message==='success') {
                
                cmp.set("v.showError",false);
                navEvt.setParams({
                    "recordId": cmp.get("v.parent_oppty_id"),
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