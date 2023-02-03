({
    init: function(component, event, helper) {

		var recordId = 	component.get("v.recordId");
        var action = component.get("c.prepareDefaultJsonString");   
        var objectName = "pse__Project_Methodology__c";
		action.setParams
        (
            {
                recordId: recordId,
                objectType: objectName
            }
        
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            var messageToShow = '';
            var toastType;
            if (state === "ERROR") 
            {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Info Message',
                        message: 'Error occured',
                        messageTemplate: 'Error occured',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();                
                
            }
            else if (state === "SUCCESS")
            {
				var result =response.getReturnValue(); 
                result = JSON.parse(result);
                if(result == 'Nothing Found')
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Info Message',
                        message: 'Error occured',
                        messageTemplate: 'Error occured',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();                
                }
                else
                {	
                        var createRecordEvent = $A.get("e.force:createRecord");
                        createRecordEvent.setParams({
                            "entityApiName": objectName,
                            "defaultFieldValues": result
                        });
                        createRecordEvent.fire();                
                    
                }
                
            }
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