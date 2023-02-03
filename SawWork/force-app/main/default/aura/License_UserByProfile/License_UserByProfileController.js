({
	afterScriptsLoaded : function(component, event, helper) {
		helper.doInit(component,event,helper);
    },
    
    initAction : function(component, event, helper) {
        var listUsers = component.get("c.listUsers");
        listUsers.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == "SUCCESS")
            {
                var response = resp.getReturnValue();
                console.log(response);   
                component.set("v.userlist", response);
            }
            else if(state == "RUNNING")
            {
                
            }
                else if(state == "ERROR")
                {
                    var error = resp.getError();
                    if(error)
                    {
                        console.log(error);
                    }
                }
        });
        $A.enqueueAction(listUsers);   
    },
    
    gotoURL : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        console.log('evt'+evt);
        evt.setParams({
            componentDef: "c:License_UsageChart",
            //componentAttributes :{ }
        });
       
        evt.fire();
    },
    // this function automatic call by aura:waiting event  
   showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
   },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    },
    
    callRecord : function(component, event, helper){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": event.target.id,//"005A0000001YVypIAG",
            "slideDevName": "related"
        });
        navEvt.fire();
    }
})