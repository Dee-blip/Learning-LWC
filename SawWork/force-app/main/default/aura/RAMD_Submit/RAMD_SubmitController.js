({
	init: function(component, event, helper) {

        var recordId =  component.get("v.recordId");
        //var accontId = component.get("v.accountId");    
        
    },
    
    handleRecordUpdated: function(component, event, helper){
        var eventParams = event.getParams();
        var recId = component.get("v.recordId");
        if(eventParams.changeType === "LOADED" && recId) {
            var accId = component.get("v.pcpDetails.Account__c");
            console.log(typeof(accId));
            console.log('accountId :: RAMD'+ accId);
            component.set("v.accountId",accId);
        }

        //commenting
        
        var recordId =  component.get("v.recordId");
        var accontId = component.get("v.accountId");
        var action = component.get("c.recordSubmit");
        action.setParams
        (
            {
                accId: accontId,
                recId: recordId
            }
        
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            var messageToShow = '';
            var toastType;
            console.log(' submit state : ' + state);
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
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Info Message',
                        message: result,
                        messageTemplate: 'Error occured',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();  
                
            }
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();
            $A.get('e.force:refreshView').fire();
            
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