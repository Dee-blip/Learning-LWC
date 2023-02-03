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
					helper.setToastVar(component, "Error: " + messageToShow);                    
                }
                else if (state === "SUCCESS")
                {
                    messageToShow = response.getReturnValue();
                    if(messageToShow.includes('Exception'))
                    {
                        toastType = 'error';
                        helper.setToastVar(component, "Error: " + messageToShow);
                    }
                    else
                    {
	                    toastType = 'Success';  
                        helper.setToastVarSuccess(component, messageToShow);
                        window.location.href = '/lightning/o/Inv_Workbox_Region_Quarter_Mapping__c/list?filterName=Recent';
                    }   

                }
                console.log("toastType: " + toastType + " messageToShow: "  + messageToShow);
				/*var toastEvent = $A.get("e.force:showToast");
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
        		toastEvent.fire(); ?*/               
	            //var dismissActionPanel = $A.get("e.force:closeQuickAction");
				//dismissActionPanel.fire();
            
            
         });
        $A.enqueueAction(action);     

	},
    
    cancelDialog :function(component, event, helper){
        window.location.href = '/lightning/o/Inv_Workbox_Region_Quarter_Mapping__c/list?filterName=Recent';
    },
    	showSpinner : function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
   	},
    
	 // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
       component.set("v.Spinner", false);
    }
})