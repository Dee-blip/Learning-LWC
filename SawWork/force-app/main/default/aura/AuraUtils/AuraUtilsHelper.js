({
    isLightningExperience: function() {
        
        var toast = $A.get("e.force:showToast");
        if (toast){
            return true;
        } else {
            return false;
        }
    },
    
    
    callServer : function(component,method,callback,params) {
        
        var compEventStart = component.getEvent("Loading");
        var compEventFinish = component.getEvent("DoneLoading");
        compEventStart.fire();
        
        
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // pass returned value to callback function
                callback.call(this,response.getReturnValue());  
            } else if (state === "ERROR") 
            {
                var error = response.getError();
                console.log('Error -> '+JSON.stringify(error));
                 let toastParams = {
                    title: "Error",
                    message: "An unknown error has occurred",
                    type: "error"
                };
                
                console.log(JSON.stringify(error[0].message));
                    if (error[0] &&error[0].message) {
                    	toastParams.message = error[0].message;
                    }
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams(toastParams);
                toastEvent.fire();
            }
            compEventFinish.fire();
        });
        
        $A.enqueueAction(action);
    },
    
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) 
    {    
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Message',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    }
    
})