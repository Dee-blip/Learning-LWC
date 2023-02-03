({
	updateRecord : function(component, event, helper) {
        
		var fundClaimId = component.get("v.fundClaimId");
        var fundClaimSpenderVar = component.get("v.fundClaimSpenderAtt");
        component.set('v.Spinner',true);
        
        component.set('v.showSuccessMessage',false);
        component.set('v.showErrorMessage',false);
        
        //Validation
        if($A.util.isEmpty(fundClaimSpenderVar) || fundClaimSpenderVar == 'null'){
            console.log("Invalid Fund Claim Spender value :"+fundClaimSpenderVar);
            alert('Please select Fund Claim Activity Spender');
            return;
        }
        console.log("Fund Claim Id : "+fundClaimId);
        console.log("Fund Claim Spender :"+fundClaimSpenderVar);
        //Calling the Apex Function
        var action = component.get("c.updateFundSpender");
        
        //Setting the Apex Parameter
        action.setParams({
            FDId : fundClaimId,
            FCSpender : fundClaimSpenderVar
        });
		console.log("Setting callback");		
        helper.toggle(component,event);
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
                //console.log(successMsg);
            } else if(state == "ERROR"){
                component.set('v.showErrorMessage',true);
            }
        });
        $A.enqueueAction(action);
	}
})