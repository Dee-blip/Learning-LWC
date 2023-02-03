({
	doInit : function(component, event, helper) 
	{
		
		var action = component.get("c.getDSRCount");
    	action.setParams({
      						'existingOppId': component.get('v.existingOpportunityId'),
      
    					});

    	action.setCallback(this, function(response) {
      
      	var state = response.getState();
      	var returnVal = response.getReturnValue();
      
      	if (component.isValid() && state === "SUCCESS") 
      	{
            if( returnVal == '0')
            {
				helper.setMessage(component,'There are no DSRs associated with this Opportunity','error','Error');
            }
            else
            {
          		component.set("v.dsrCount", returnVal);   
       		}
       	}
      
    	});
    	$A.enqueueAction(action);
      
    },
	searchOpportunitiesKey : function(component, event, helper) 
	{
		
		// Enter key pressed
		if(event.getParams().keyCode == 13)
		{
          helper.searchOpportunitiesHelper(component, event, helper);
        }
      
    },
    searchOpportunities : function(component, event, helper) 
	{
		helper.searchOpportunitiesHelper(component, event, helper);
	},
    moveAllDSRs: function(component, event, helper) 
    {
		 var selectedOpportunityId = component.get('v.selectedOpportunity').Id;
		 var selectedOpportunityName = component.get('v.selectedOpportunity').Name;
		 var action = component.get("c.moveAllDSRbyOpportunity");
    	action.setParams({
      						'newOpportunityId': selectedOpportunityId,
      						'existingOppId': component.get('v.existingOpportunityId')
    					});

    	action.setCallback(this, function(response) {
      
      	var state = response.getState();
      	var returnVal = response.getReturnValue();
      
      	if (component.isValid() && state === "SUCCESS") 
      	{
            if( returnVal.includes('Error'))
            {
            	component.set('v.selectedOpportunity',null);
				helper.setMessage(component,returnVal,'error', 'Error');
            }
            else if(returnVal == "")
            {
          		helper.setMessage(component,'You have moved '+component.get('v.dsrCount')+' DSR(s) to ','confirm', 'Success'); 
       		}
       	}
      
    	});
    	$A.enqueueAction(action);
	 },

	 onRadio : function(component, event, helper) 
	 {
	 	var selected = event.getSource().get("v.name");
	 	component.set('v.selectedOpportunity',selected);
	 }
})