({
	doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        console.log('You are on'+device);
        
        if(device==='PHONE')
        {
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
            componentDef: "c:SF1_LocateAccountCmp",
            componentAttributes: {
               
                "recordId":component.get("v.recordId")
            }
        });
             evt.fire();    
        }
        else
        {
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
            componentDef: "c:LTNG_LocateAccountCmp",
            componentAttributes: {
               
                "recordId":component.get("v.recordId")
            }
        });
    evt.fire();    
        }
	}
})