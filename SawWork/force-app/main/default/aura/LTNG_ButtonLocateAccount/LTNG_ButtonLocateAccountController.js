({
	doLink : function(cmp, event, helper) {
		console.log('Inside Account List Controller to link of the LTNG Component');
        var accid=cmp.get("v.acc_id");
        var oppid=cmp.get("v.opp_id");
        console.log("Account id:"+accid);
        console.log("Optty id:"+oppid);
        var action = cmp.get("c.AddAccount");
         action.setParams({
            "pid": cmp.get("v.acc_id"),
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
             $A.get('e.force:refreshView').fire();
            }
            
            else
            {  
                
                console.log('FAILED in Linking Account');
                var evt = $A.get("e.c:LTNG_EVT_SetError");
                evt.setParams({ "ShowError": true,
                                "message":response.getReturnValue() 
                              });
                evt.fire();
            }
           
                           
            
        });
        $A.enqueueAction(action);
	}
})