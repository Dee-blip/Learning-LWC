({
    closeCase:function(component, event, helper) {
        component.set("v.showCloseCase", true);
       // component.set("v.showSpinner", true);
        
        helper.callServer(
            component,
            "c.getAMGCaseRecTypeId",
            function(response){
                var returnVal = response;
                component.set("v.recTypeIdAMG", returnVal);
            });
    },
    
    
    closeCaseModal: function(component, event, helper) {
        component.set("v.showCloseCase", false);
    },
    
    submitForm : function(component, event, helper) 
    {
        //component.set("v.showSpinner", true);
        var flds = event.getParam('fields');
        console.log('flds--->'+JSON.stringify(flds));
        
        helper.callServer(
            component,
            "c.closeCases",
            function(response){
                console.log("resp"+response);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case has been updated successfully"
                });
                toastEvent.fire();
                component.set("v.showCloseInvalid", false);
                $A.get('e.force:refreshView').fire();
                
            },
            {
                "caseId" : component.get("v.recordId"),
                "caseFieldValues" : flds
            });
    },
    closeInvalid:function(component, event, helper) {
        
        component.set("v.showCloseInvalid", true);
       // component.set("v.showSpinner", true);
    },
    
    closeInvalidModal : function(component, event, helper)
    {
        component.set("v.showCloseInvalid", false);
        
    },
    
    submitInvalid:function(component, event, helper) {
        console.log('In submitInvalid');
        event.preventDefault();
        var fields = event.getParam("fields");
        console.log('Fields///'+JSON.stringify(fields));
        var commentVal = fields.Comments__c;
        console.log('commentVal//'+commentVal);
        
        helper.callServer(
            component,
            "c.closeCaseInvalid",
            function(result)
            {
               // component.set("v.showSpinner", false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case has been updated successfully"
                });
                toastEvent.fire();
                component.set("v.showCloseInvalid", false);
                $A.get('e.force:refreshView').fire();
                
                
            },
            {
                "caseId": component.get("v.recordId"),
                "commentsData": commentVal
                
            }
        );
    },
    spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    }
    
    
})