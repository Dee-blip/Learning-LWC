({	
    serverSideCall : function(component,event,helper,method,params) {
        return new Promise(function(resolve, reject) {
            console.log('SH : Helper from parent component');
            var spinner = component.find("pageSpinner");
        	$A.util.toggleClass(spinner, "slds-hide");
            var action = component.get(method);
        	if(params){
            	action.setParams(params);
        	}
            action.setCallback(this, 
                               function(response) {
                                   $A.util.toggleClass(spinner, "slds-hide");
                                   var state = response.getState();
                                   if (state === "SUCCESS") {
                                       resolve(response.getReturnValue());
                                   } else {
                                       reject(response.getError());
                                   }
                               });
            $A.enqueueAction(action);
        });
    },
    
    showToast : function(component, event, helper,title,message,type,dismissible) {
        console.log('Showing toast');
        var mode;
        if (dismissible)
            mode = 'dismissible';
        else
            mode = 'sticky'; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "mode" : mode,
            "type" : type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    },

    showErrorMessage : function(component, event, helper,error) {
        let errorData = JSON.parse(JSON.stringify(error));
        let messageObj = JSON.parse(errorData[0].message);
        let message = messageObj.message;
        let dismissible = messageObj.dismissible;
        console.log('message :'+message);
        console.log('dismissible :'+dismissible);
        helper.showToast(component, event, helper,'Error\!',message,'error',dismissible);
    },

    navigateToFlow : function(component, event, helper, inputParams, flowName) {
        console.log("Navigate to flow (parent)");
        var newEvent = $A.get("e.force:navigateToComponent");
        newEvent.setParams({
            componentDef: "c:PartnerCommunityFlowLoader",
            componentAttributes: {
                flowParams : inputParams,
                contactName : flowName
            }
        });
        newEvent.fire();
    }
})