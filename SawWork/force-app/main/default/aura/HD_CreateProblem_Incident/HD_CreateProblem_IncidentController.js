({
	createProblem : function(component, event, helper) 
    {
        var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);
        if(isSafari)
        {
            var windowReference = window.open();
        }
		var action = component.get("c.cloneIncidentToProblem");
        var recordId = component.get("v.recordId");
        action.setParams({
            currentIncidentId : recordId
        });
         var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
                    
        			"message": "Creating Problem!"
    			});
    			toastEvent.fire();
    
        action.setCallback(this,function(data){
            var newId = data.getReturnValue();
            console.log(newId);
            if(newId)
            {
                //url = "/one/one.app?#/sObject/"+newId+"/view";
                var url = window.location.origin +'/' +newId;

                if(isSafari)
                {
                    windowReference.location = url;
                }
                else
                {
               		window.open(url, '_blank');   
                }
                $A.get('e.force:refreshView').fire();
            }
            else
            {
                /*
                var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
                    "title": "Error!",
                    "type": "error", 
        			"message": "Error occured while creating Problem!"
    			});
    			toastEvent.fire();
                */
                //var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, null, 'Error occurred while creating problem for Incident '+recordId,false);
 
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : (newId)?'SUCCESS':'ERROR' }).fire();
        });
        $A.enqueueAction(action);
        
    } 
})