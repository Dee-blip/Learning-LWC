({
    init: function(component, event, helper) {

        var recordId =  component.get("v.recordId");
        var action = component.get("c.cloneRecord");
        action.setParams
        (
            {
                recordId: recordId
            }
        
        );
        action.setCallback(this, function(response) {
            var state = response.getState();
            var messageToShow = '';
            var toastType = '';
            component.set("v.Spinner", false); 
            if (state === "ERROR") 
            {       
                helper.showToastMessage('error','Error occured');                
            }
            else if (state === "SUCCESS")
            {
                //console.log(result);
                var result =response.getReturnValue(); 
                if(result.startsWith('SUCCESS') )
                {
                    var newRecordId = result.split(':')[1];
                    var sObectEvent = $A.get("e.force:navigateToSObject");
                        sObectEvent .setParams({
                        "recordId": newRecordId
                      });
                    helper.showToastMessage('success','Record Successfully Cloned!!');                
                    sObectEvent.fire();                     
                    
                }
                else
                {   
                    if(result.includes('bad value for restricted picklist field')){
                        var res = result.split(":");
                        helper.showToastMessage('error','Error: Clone failed. Invalid picklist - '+res[3]+' value selected. Please create a new request using valid field values');                
                        //helper.showToastMessage('error',result);                
                    }
                    else{
                        helper.showToastMessage('error',result);                
                    }
                    
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