({
	init : function(component, event, helper) {
		var rId = component.get("v.recordId");
        var action = component.get("c.callClone");   
		action.setParams
        (
            {
                testId: rId
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
                    else if((messageToShow.length === 15 || messageToShow.length === 18) && messageToShow.startsWith('aQn'))
                    {
                        
                        toastType = 'success';	
						var sObectEvent = $A.get("e.force:navigateToSObject");
					    sObectEvent.setParams
                        (
                            {
						    	"recordId": messageToShow
					   		}
                        );
                        messageToShow = 'Test Cloned!'
				       sObectEvent.fire(); 	
                       
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

	},
	showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
   	},
    
	 // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    }    
})