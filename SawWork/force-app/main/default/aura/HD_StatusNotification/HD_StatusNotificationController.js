({
    
    onClose: function(component, event, helper) {
        var cmpTarget = component.find('notificationContainer');

        $A.util.addClass(cmpTarget, 'slds-hide');

    },
    changeToInProgress: function(component, event, helper) {
		var action = component.get("c.changeStatusToInProgress");
        action.setParams({
        	recordId : component.get("v.recordId")
        });
         
       	action.setCallback(this,function(data){
           
            var state = data.getState();
            if(state == 'ERROR'){
                    alert("error");
                    var errors = data.getError();
            		HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message,false);
                    helper.doneWaiting(component);

                }
            var data = data.getReturnValue();
            $A.get('e.force:refreshView').fire();
            
            
    	});
        $A.enqueueAction(action);
        helper.waiting(component);  
        


    }


})