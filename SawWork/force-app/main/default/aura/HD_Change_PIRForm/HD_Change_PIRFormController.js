({
    hideCreateForm : function(component, event, helper){
        helper.hideCreateFormHelper(component,event);
    },
    savePIR : function(component, event, helper){
        var currentChange = component.get("v.currentChangeRequest");
        
        var resultsCmp = component.find("resultsid");
        var selectedResult = resultsCmp.get("v.value");
        
        var sidCmp = component.find("sidId");
        var impDetails = sidCmp.get("v.value");
        
        var changeImplementedCmp = component.find("changeImplementedId");
        var changeImplementedValue = changeImplementedCmp.get("v.value");
        
       	var implementWinCmp = component.find("implementId");
        var implmntWinValue = implementWinCmp.get("v.value");
        
        var lessonsCmp = component.find("lessonsId");
        var lessonsValue = lessonsCmp.get("v.value");
        var chStatus = component.get("v.changeStatus");
        
        var action = component.get("c.createPIR");
        action.setParams({
            changeRequest : currentChange,
            changeDeliveredResults : selectedResult,
            serviceImpactDetails : impDetails,
            changeImplementedAsPlanned : changeImplementedValue,
            implementationWinDetails : implmntWinValue,
            additionalLessons : lessonsValue,
            statusVal : chStatus
        });
        
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                if(result){
                    


                    var updatedCMR=result;
                    component.set('v.change',updatedCMR);

                    //Refreshing the main list view
                    var incList = component.getEvent("getChangeListEvent").fire();

                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
                    

                    helper.hideCreateFormHelper(component,event);
                    helper.showSuccessToast(component, event,"PIR Created. Marking CMR to "+chStatus);
                    //helper.closeCMR(component,event,currentChange);
                }
                else{
                    helper.showErrorToast(component, event,"Error occurred while creating PIR and changing status to "+chStatus+", please contact helpdesk team");
                    console.log("In PIR Form");
                    console.log("Error here in PIR Form");
                    //report error
                }
                helper.doneWaiting(component);
            }else if (state==="ERROR"){
                component.set("v.isSpinnerEnabled",false);
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

                    helper.showErrorToast(component, event,"Error occurred while creating PIR. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event,"Error occurred while creating PIR. Please contact helpdesk team");
                }
                helper.doneWaiting(component);
            }
        });
        $A.enqueueAction(action);
        helper.waiting(component);
    }
})