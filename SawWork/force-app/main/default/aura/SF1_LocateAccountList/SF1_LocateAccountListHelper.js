({
    linkAcc : function(cmp) {
        console.log("Inside linkAcc Function",cmp.get("v.acc.Id"));
        var action = cmp.get("c.AddAccount");
         action.setParams({
            "pid": cmp.get("v.acc.Id"),
              "oid":cmp.get("v.opp_id")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var retval  = response.getReturnValue();
            //var retnum = opp.length;
 
            if (cmp.isValid() && state === "SUCCESS" && retval==="Success") 
            {
             //cmp.set("v.optty", response.getReturnValue());
             console.log("Success",retval);
             var sObjectEvent = $A.get("e.force:navigateToSObject");
             sObjectEvent.setParams({
                    "recordId": cmp.get("v.opp_id"),
                    "slideDevName": 'detail'
            })
             
             sObjectEvent.fire();
             $A.get('e.force:refreshView').fire();
            }
            
            else
            {  
                cmp.set("v.message",response.getReturnValue());
                cmp.set("v.ShowError",true);
            }
           
                           
            
        });
        $A.enqueueAction(action);
        
    }
})