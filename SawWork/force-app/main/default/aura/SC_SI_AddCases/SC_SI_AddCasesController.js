({
    
    handleCancel : function(component, event, helper) {
        
        component.set("v.showAddCaseModal",false);
    },
    
    handleOnLink : function(component, event, helper) {
        event.preventDefault();       // stop the form from submitting
        component.set("v.showSpinner",true);
        var caseRecordId = event.getParam("fields").Case_Number__c;
        component.set("v.caseRecId",caseRecordId);
        console.log('caseRecId//'+ component.get("v.caseRecId"));
        
        var validateAndAdd = component.get("c.updateCaseWithSI");
        validateAndAdd.setParams({
            "siId" : component.get("v.recordId"),
            "caseId": component.get("v.caseRecId")
        });
        
        validateAndAdd.setCallback(this, function(result)
                                   {
                                       if(result.getState() == 'SUCCESS'){
                                           component.set("v.showSpinner",false);
                                           var res = result.getReturnValue();
                                           
                                           if(res=='Duplicate' || res=='Success'){
                                               var toastEvent = $A.get("e.force:showToast");
                                               toastEvent.setParams({
                                                   "type": "Success",
                                                   "message": "Case has been associated."
                                               });
                                               toastEvent.fire();
                                               component.set("v.showAddCaseModal",false);
                                               if( res=='Success'){
                                                   window.location.reload();
                                               }
                                           }
                                       
                                       else if(res=='Already Linked Case'){
                                           component.set("v.warningMessage",'Case is already Linked to another Incident. Do you want to override?');
                                           component.set("v.showConfirm",true); 
                                       }
                                       
                                           else{
                                               component.set("v.showSpinner",false);
                                               var toastEvent = $A.get("e.force:showToast");
                                               toastEvent.setParams({
                                                   "type": "Error",
                                                   "message": res
                                               });
                                               toastEvent.fire();
                                           }
                                   }
                                   else{
                                   component.set("v.showSpinner",false); 
    }
});
$A.enqueueAction(validateAndAdd);
},
    handleConfirm : function(component, event, helper) {
        
        component.set("v.showSpinner",true);
        
        var updateCase = component.get("c.addCaseToSI");
        updateCase.setParams({
            "siId" : component.get("v.recordId"),
            "caseId": component.get("v.caseRecId")
        });
        updateCase.setCallback(this, function(result)
                               {
                                   if(result.getState() == 'SUCCESS'){
                                       component.set("v.showSpinner",false);
                                       var res = result.getReturnValue();
                                       
                                       if(res=='Success'){
                                           var toastEvent = $A.get("e.force:showToast");
                                           toastEvent.setParams({
                                               "type": "Success",
                                               "message": "Case has been associated."
                                           });
                                           toastEvent.fire();
                                           component.set("v.showAddCaseModal",false);
                                           window.location.reload();
                                           
                                       }
                                       else{
                                           component.set("v.showSpinner",false);
                                           var toastEvent = $A.get("e.force:showToast");
                                           toastEvent.setParams({
                                               "type": "Error",
                                               "message": res
                                           });
                                           toastEvent.fire();
                                       }
                                   }
                                   else{
                                       component.set("v.showSpinner",false); 
                                   }
                               });
        $A.enqueueAction(updateCase);
    }

})