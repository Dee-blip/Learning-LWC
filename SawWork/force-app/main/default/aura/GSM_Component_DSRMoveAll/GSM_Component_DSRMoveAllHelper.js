({
	searchOpportunitiesHelper : function(component, event, helper) 
	{
		
		

		var action = component.get("c.searchOpportunity");
    	action.setParams({
      						'nameString': component.get('v.searchKeyword'),
      						'existingOppId': component.get('v.existingOpportunityId'),
      
    					});

    	action.setCallback(this, function(response) {
      
      	var state = response.getState();
      	var returnVal = response.getReturnValue();
      
      	if (component.isValid() && state === "SUCCESS") 
      	{
          
          	component.set("v.opportunityList", returnVal);
          	if(returnVal.length == 0)
          	{
          		component.set("v.opportunityListisEmpty",true);
          	}
          	else
          	{
          		component.set("v.opportunityListisEmpty",false);
          	}
          	
          	component.set('v.selectedOpportunity',null);
        
       	}
      
    	});
    	$A.enqueueAction(action);
    },

    setMessage: function(component, message, severity, title)
    {
    	component.set("v.displayMessage", message);
	    component.set("v.messageSeverity", severity);
	    component.set("v.messageTitle",title);
    }
})