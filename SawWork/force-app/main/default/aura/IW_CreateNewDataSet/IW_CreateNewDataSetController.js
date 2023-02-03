({
	init : function(component, event, helper) {
        console.log('call method :: createRegionRecs');
        var action = component.get("c.createRegionRecs");   
		//action.setParams();
        console.log('in doInt for Create new Data set');
        action.setCallback(this, function(response) { 
                var state = response.getState();
            	var messageToShow = '';
            	var toastType;
                if (state === "ERROR") 
                {
					messageToShow = "Error!!";
                    toastType = 'error';
                    
                }
                else if (state === "SUCCESS")
                {
                    messageToShow = response.getReturnValue();
                    if(messageToShow.includes('Exception'))
                    {
                        toastType = 'error';	
                    }
                    else
                    {
	                    toastType = 'Success';                        
                    }   

                }
				var toastEvent = $A.get("e.force:showToast");
		        toastEvent.setParams
                (
                    {
                        title : 'Message',
                        message: messageToShow,
                        messageTemplate: messageToShow,
                        key: 'info_alt',
                        type: toastType,
                        mode: 'sticky'
		        	}
                );
        		toastEvent.fire();                
	            var dismissActionPanel = $A.get("e.force:closeQuickAction");
				dismissActionPanel.fire();
            
            
         });
        $A.enqueueAction(action);     

	}
})