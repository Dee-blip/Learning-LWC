({
	serverSideCall : function(component,event,helper,method,params) {
        return new Promise(function(resolve, reject) {
            console.log('SH : Helper from parent component');
            console.log('Adding spinner')
            //var spinner = helper.asArray(component.find("pageSpinner"));
            var spinner = component.find("pageSpinner");
        	$A.util.toggleClass(spinner, "slds-hide");
            var action = component.get(method);
        	if(params){
            	action.setParams(params);
        	}
            action.setCallback(this, 
                               function(response) {
                                   console.log('Removing spinner');
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
    }
})