({
	init : function(component, event, helper) {
		var rId = component.get("v.recordId");
        var action = component.get("c.callUpdateMethod");   
		action.setParams
        (
            {
                projId: rId
            }
        
        );
        console.log(rId);
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
	                    toastType = 'info';                        
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