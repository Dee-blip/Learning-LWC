({
	cloneIncidentController : function(component, event, helper) {
        if (event !== null && typeof event.getParam === 'function' && event.getParam("quickAction") && event.getParam("quickAction") !== 'Clone') {
            return;
        }
        
        var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);
        if(isSafari)
        {
            var windowReference = window.open();
        }
        var action = component.get("c.cloneIncident");
        var recordId = component.get("v.recordId");
        console.log(recordId);
        action.setParams({
            currentIncidentId : recordId
        });
        
        var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
                    
        			"message": "Cloning the ticket!"
    			});
    			toastEvent.fire();
        
        action.setCallback(this,function(data){
            
            var ele = component.find("Accspinner");
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");    
            var newId = data.getReturnValue();
            
          if(newId)
            {
                var url = "/lightning/r/BMCServiceDesk__Incident__c/"+newId+"/view";
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
                var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
                    "title": "Error!",
                    "type": "error", 
        			"message": "Error occured while cloning the ticket!"
    			});
    			toastEvent.fire();
            }
           
    		$A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : (newId)?'SUCCESS':'ERROR' }).fire();
        });
        $A.enqueueAction(action);
        helper.waiting(component);
	}
 		
		
	
})