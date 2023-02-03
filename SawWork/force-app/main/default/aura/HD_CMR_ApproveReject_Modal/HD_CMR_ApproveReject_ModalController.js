({
    myAction : function(component, event, helper) {
        
    },
    close:function(component, event, helper) {
        component.set("v.isOpen",false);
    },
    approveOrReject:function(component, event, helper) {
        
        component.set("v.isSpinnerEnabled",true);
        
        var processWorkItemId=component.get("v.processWorkItemId");
        var approveOrReject=component.get("v.action");
        var comments = component.get("v.comments");
        var cmrObject=component.get("v.change");
        
        var action = component.get("c.approveOrRejectCMR");
        var response="";
        
        action.setParams({
            "workingItemId" : processWorkItemId,
            "comments" : comments,
            "actionToBePerformed" : approveOrReject,
            "currentCMR" : cmrObject,
        });
        
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                if(result){

                    //Change the updated CMR Data
                    var updatedCMR=result;
                    component.set('v.change',updatedCMR);

                    //Refreshing the main list view
                    var incList = component.getEvent("getChangeListEvent").fire();


                    component.set("v.isOpen",false);
                    //refresh the component
                    // Disable the spinner
                    component.set("v.isSpinnerEnabled",true);
                    if(approveOrReject=="Approve"){
                        helper.showSuccessToast(component, event, helper,"CMR is approved successfully");
                    }else if(approveOrReject == "Reject"){
                        helper.showWarningToast(component, event, helper,"CMR is rejected successfully");
                    }else if(approveOrReject == "Recall"){
                        
                        helper.showWarningToast(component, event, helper,"CMR is recalled successfully");
                    }

                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
                    
                }else{
                    //throw error message
                    //// Disable the spinner
                    component.set("v.isSpinnerEnabled",true);
                    component.set("v.isOpen",false);
                    helper.showErrorToast(component, event, helper,"Error occurred while approving/rejecting/recalling cmr. Please contact helpdesk team");
                }
                
            }else if(state==="ERROR"){
                component.set("v.isSpinnerEnabled",true);
                component.set("v.isOpen",false);
                var errorMessage="";
                var errors=data.getError();
                if (errors) {
                    var error=errors[0];
                    for(var temp in error){
                        var temp1=error[temp];
                        try{
                            errorMessage=errorMessage+" "+temp1[0].message;
                        }catch(err ){
                            continue;
                        }
                    }
                    helper.showErrorToast(component, event, helper,"Error occurred while approving/rejecting/recalling cmr. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while approving/rejecting/recalling cmr. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
    }
})