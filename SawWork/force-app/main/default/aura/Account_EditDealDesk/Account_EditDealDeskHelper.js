({
	
    updateAccount: function(component){
        var accountId = component.get("v.accountId");
        var dealDeskSpecialInstructions = component.get("v.dealDeskSpecialInstructions");
        component.set('v.Spinner',true);
        
        component.set('v.showSuccessMessage',false);
        component.set('v.showErrorMessage',false);
        
        //Validation
        if($A.util.isEmpty(dealDeskSpecialInstructions) || dealDeskSpecialInstructions == 'null'){
            console.log("Invalid dealDeskSpecialInstructions value :"+dealDeskSpecialInstructions);
            alert('Please select Deal Desk Special Instructions');
            console.log('v.dealDeskSpecialInstructions'+component.get("v.dealDeskSpecialInstructions"));
            //Does not work in classic view
            /*$A.get('e.force:refreshView').fire();
            $A.enqueueAction(action);*/
            component.set('v.Spinner',false);
            return;
        }
        console.log("accountId : "+accountId);
        console.log("dealDeskSpecialInstructions :"+dealDeskSpecialInstructions);
        //Calling the Apex Function
        var action = component.get("c.updateAccountRecord");
        
        //Setting the Apex Parameter
        action.setParams({
            accId : accountId,
            ddSpecialInstructions : dealDeskSpecialInstructions
        });
		console.log("Setting callback");		
        this.toggle(component,event);
        //Setting the Callback
        action.setCallback(this,function(a){
            //get the response state
            console.log('Response :'+a.getReturnValue());
            component.set('v.Spinner',false);
            
            var state = a.getState();
            console.log('State :'+state);
            
            //check if result is successfull
            if(state == "SUCCESS"){
                //Change alert to page msg.
                component.set('v.showSuccessMessage',true);
                window.location.href=component.get("v.accountUrl");
                //console.log(successMsg);
            } else if(state == "ERROR"){
               
        	    var errors = a.getError();
            	if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        
                        component.set('v.errorMsg',errors[0].message);
                        }
                } else {
                    console.log("Unknown error");
                
      		  }
                component.set('v.showErrorMessage',true);
            }
        });
        $A.enqueueAction(action);
    },    
    toggle: function (cmp, event) {
        var spinner = cmp.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    }
})