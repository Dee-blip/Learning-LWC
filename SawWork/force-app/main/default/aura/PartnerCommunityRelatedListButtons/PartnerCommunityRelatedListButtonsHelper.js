({
	
    serverSideCall : function(component,action) {
        var spinner = component.find("pageSpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        return new Promise(function(resolve, reject) { 
            action.setCallback(this, 
                               function(response) {
                                   var spinner = component.find("pageSpinner");
                                   $A.util.toggleClass(spinner, "slds-hide");
                                   var state = response.getState();
                                   if (state === "SUCCESS") {
                                       resolve(response.getReturnValue());
                                   } else {
                                       reject(new Error(response.getError()));
                                   }
                               }); 
            $A.enqueueAction(action);
        });
    }
    
})