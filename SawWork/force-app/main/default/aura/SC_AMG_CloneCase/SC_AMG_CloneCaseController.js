({
   
    spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    },
    
    
   closeModal:function(component, event, helper) {
	
       component.set("v.confirmationModal", false);
       component.set("v.showClone", false);
       
   },
    
    cloneSingleCase:function(component, event, helper) {
        
        console.log('In New JS');
        helper.callServer(
            component,
            "c.cloneCaseRec",
            function(result)
            {
                var newCaseId = result; 
                console.log('newSingleCaseid/// In success'+newCaseId)
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": "Success",
                    "message": "The Case record has been created successfully."
                });
                toastEvent.fire();
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    "recordId": newCaseId
                });
                editRecordEvent.fire();
                component.set("v.confirmationModal", false);
                component.set("v.showClone", false);
                $A.get('e.force:refreshView').fire();
          
                
            },
            {
                "caseId": component.get("v.caserecId")
            }
        );
   },
   
    
    
    
    
})