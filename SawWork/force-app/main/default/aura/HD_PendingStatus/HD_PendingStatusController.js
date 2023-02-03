({
	doInit : function(component, event, helper) {
        var input = component.find('toggle-checkbox');
        console.log("input: ");
        console.log(input);
        console.log("value:")
        console.log(input.get("v.value"));
        var incId = component.get("v.recordId");
        var action = component.get("c.isPendingStatus");
        action.setParams({
            incidentId : incId
        });
        action.setCallback(this,function(data){
			console.log("In callback");
            var el = component.find("toggle-div");
            var isPending = data.getReturnValue();
            console.log("isPending: "+isPending);
            if(isPending){
                console.log("isPending=true");
                console.log("Initial value:"+input.get("v.value"));
                input.set("v.value",true);
                console.log("Changed value:"+input.get("v.value"));
                //$A.util.removeClass(el, "slds-hide"); 
    			//$A.util.addClass(el, "slds-show"); 
            }
            else{
                console.log("isPending = false");
                input.set("v.value",false);
                $A.util.removeClass(el, "slds-show"); 
    			$A.util.addClass(el, "slds-hide"); 
            }
            helper.doneWaiting(component);
        });
        $A.enqueueAction(action);
        helper.waiting(component);
	},
    
    onChange : function(component, event, helper) {
        var input = component.find('toggle-checkbox');
        var value = input.get("v.value");
        var incId = component.get("v.recordId");
        console.log("value:"+value);
        var action = component.get("c.resumeTicket");
        action.setParams({
            incidentId : incId
        });
        action.setCallback(this,function(data){
            console.log("In callback");
            var el = component.find("toggle-div");
            var state = data.getState();
            if(state == 'SUCCESS'){
                console.log("Initial value onchange:"+input.get("v.value"));
                input.set("v.value",false);
                console.log("Changed value onchange:"+input.get("v.value"));
                //$A.util.removeClass(el, "slds-show"); 
    			//$A.util.addClass(el, "slds-hide");
                $A.get('e.force:refreshView').fire();
            }
            else{
                console.log('Failed in resume ticket');
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
            helper.doneWaiting(component);
        });
        $A.enqueueAction(action);
        helper.waiting(component);
        
	}
})