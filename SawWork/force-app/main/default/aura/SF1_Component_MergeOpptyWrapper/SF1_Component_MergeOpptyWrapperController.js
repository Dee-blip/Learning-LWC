({
	  doInit: function(component, event, helper) 
	  {
   			helper.initHelper(component, event, helper);
		},

	clickOnCheckBox : function(component, event, helper) 
	{
		var eachOppId = event.target.name;
		var alreadySelected;
		
		if(component.get('v.selectedPrimaryOpportunityPlaceholder') == null)
		{
			alreadySelected = false;
		}
		else
		{
			alreadySelected = component.get('v.selectedPrimaryOpportunityPlaceholder').Id == eachOppId;
		}
		if(alreadySelected)
		{

			
			component.set('v.selectedPrimaryOpportunityPlaceholder', null);
			
		}
		else
		{
					
			// Take care of checkbox to behave like radio
			var listOfOpps = component.get('v.listOfOpportunitiesPrimary');
			var oppRecord;
			for(var i=0;i<listOfOpps.length;i++)
			{
				if(listOfOpps[i].Id == eachOppId)
				{
					oppRecord = listOfOpps[i];
					break;
				}
			} 
			component.set('v.selectedPrimaryOpportunityPlaceholder', oppRecord);
			helper.uncheckAllOtherCheckBox(component, event, helper, eachOppId, listOfOpps);
		
		
		}
		
   	},
   	clickOnSecondaryCheckBox : function(component, event, helper) 
	{
		var eachOppId = event.target.name;
		var selectedSecondaryList = component.get('v.selectedSecondaryOpportunities');

		var alreadySelected = false;
		for(var i=0;i<selectedSecondaryList.length;i++)
		{
			if(selectedSecondaryList[i].Id == eachOppId)
			{
				alreadySelected = true;
				break;
			}
		}
		
		if(alreadySelected)
		{
			var newSelectedSecondaryList = new Array();
			for(var i=0;i<selectedSecondaryList.length;i++)
			{
				if(selectedSecondaryList[i].Id != eachOppId)
				{
					newSelectedSecondaryList.push(selectedSecondaryList[i]);
				}
			}
			
			component.set('v.selectedSecondaryOpportunities', newSelectedSecondaryList);
			
		}
		else
		{
					
			// Take care of checkbox to behave like radio
			var listOfOpps = component.get('v.listOfOpportunitiesSecondary');
			var oppRecord;
			for(var i=0;i<listOfOpps.length;i++)
			{
				if(listOfOpps[i].Id == eachOppId)
				{
					selectedSecondaryList.push(listOfOpps[i]);
					break;
				}
			} 
			component.set('v.selectedSecondaryOpportunities', selectedSecondaryList);
			
		
		
		}
		var finalSelected = component.get('v.selectedSecondaryOpportunities');
		if(finalSelected.length >0)
		{
			component.set('v.disableUpdateButton', false);
		}
		else
		{
			component.set('v.disableUpdateButton', true);
		}
		
   	},

   	setPrimaryOpportunity : function(component, event, helper) 
	{
		var selectedOpp = component.get('v.selectedPrimaryOpportunityPlaceholder');
		var listOfOpps = component.get('v.listOfOpportunitiesSecondary');
		var newListOfOpps = new Array();
		for(var i=0;i<listOfOpps.length;i++)
		{
			if(listOfOpps[i].Id != selectedOpp.Id)
			{
				newListOfOpps.push(listOfOpps[i]);
			}
		}
		component.set('v.listOfOpportunitiesSecondary', newListOfOpps);
		component.set('v.selectedPrimaryOpportunity', selectedOpp);
		component.set('v.isPrimaryFlow', false);
		component.set('v.displayBackButton', true);
		component.set('v.uncheckBoxes', true);
		component.set('v.selectedSecondaryOpportunities',new Array());

   	},

   	backButton : function(component, event, helper) 
   	{
   		helper.initHelper(component, event, helper);
   	},
   	updateOpportunityFunction : function(component, event, helper) 
   	{
   		var primaryOpp = component.get('v.selectedPrimaryOpportunity');
   		var selectedSecOpp = component.get('v.selectedSecondaryOpportunities');
   		var selectedSecOppIdList = new Array();
   		for(var i=0;i<selectedSecOpp.length;i++)
   		{
   			selectedSecOppIdList.push(selectedSecOpp[i].Id);
   		}
   	 	var action = component.get('c.updateOpportunity');
    	action.setParams({
      						"sourceOppListJSONString": JSON.stringify(selectedSecOppIdList),
      						"targetOpp": primaryOpp,

    					   });
      action.setCallback(this, function(response){
      	var state = response.getState();
      
      	if (state === 'SUCCESS') 
      	{
        	var message = response.getReturnValue();
        	if(message != '')
        	{
        		component.set('v.errormessage', message+'. Click Cancel to go Back to Opportunity');
        	    component.set('v.displayNextButton', false);
        	}
        	else
        	{
        		component.set('v.successMessage', 'Opportunities merged Successfully! Click Cancel to go Back to Opportunity');
				component.set('v.isPrimaryFlow', true);
				component.set('v.dupeError', true);
        		component.set('v.errormessage', '');
        		component.set('v.displayBackButton', false);
        		component.set('v.displayNextButton', false);
        	}
    	}
	  });
	  $A.enqueueAction(action);
   	},
    goToOpportunity: function(component, event, helper) 
   	{
                var urlEvent = $A.get("e.force:navigateToSObject ");
    			urlEvent.setParams({
      				"recordId": event.currentTarget.dataset.value,
      				"slideDevName": "details"
    			});
    			urlEvent.fire();
    }


})