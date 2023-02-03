({
    
    
    handleSave:function(component, event, helper) {
        console.log('fire debug 1:',component.find("edit"));
        console.log('fire debug 2:',component.find("edit").get("e.recordSave"));
        
        if(component.find("edit").get("e.recordSave"))
        {
            console.log('inside if ');
            component.find("edit").get("e.recordSave").fire();
        }
        
        else
        {
            var recid = component.get("v.recordId");
            var navEvt = $A.get("e.force:navigateToSObject");
            var toastEvent = $A.get("e.force:showToast");
            
            var toastMessage = 'The record is created but changes could not be saved.';
            toastMessage = toastMessage + 'Please Click on Edit manually on the record page to update the record again.';
            
            navEvt.setParams({
                "recordId": recid ,
                "slideDevName": "detail"
            });
            
            
            toastEvent.setParams({
                "title": "Save Failed!",
                "message": toastMessage,
                "duration" : 10000,
                "type" : "warning"
                
            });
            
            navEvt.fire();
            toastEvent.fire();
        }
    },
    
    cancelHandle :function(cmp, event, helper) {
        var recid = cmp.get("v.recordId");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recid ,
            "slideDevName": "detail"
        });
        navEvt.fire();
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