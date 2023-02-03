({
    setToastFailure: function(sMsg){
        var type = "Error"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            message: sMsg,
            type : type,
            duration:'5000',
        });
        toastEvent.fire();
    },
    setToastSuccess: function(sMsg){
        var type = "Success"; 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            message: sMsg,
            type : type,
            duration:'5000',
        });
        toastEvent.fire();
    },
    
    navigateToDetail: function(recordId){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    
    waiting: function(component, event, helper) {
        component.set("v.HideSpinner", true);
    },
    
    doneWaiting: function(component, event, helper) {
        component.set("v.HideSpinner", false);
    },
    
    closeModalHelper: function(component, event, helper){
        component.set("v.showCommentPopUp",false);
        var modal = component.find("modalDiv");
        $A.util.addClass(modal, "hideModal");
        var modal = component.find("modalBackDropDiv");
        $A.util.addClass(modal, "removeBackDrop");
    },
    
   onButtonAction :function(component, event, helper,btnValue,commentBody) {
        helper.closeModalHelper(component, event, helper);
        helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
        var toastMsg = "";
       
       if(btnValue === "Approve"){
           toastMsg = "Approved";
       }
       else if(btnValue === "Reject"){
           toastMsg = "Rejected";
       }
       else if(btnValue === "Escalate"){
           toastMsg = "Escalated";
       }
        var btnAction = component.get("c.handleButtonEvent");
        btnAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : btnValue,
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : commentBody,
            "internalProd" : '',
            "iwClassification" : ''
        });
        btnAction.setCallback(this, function(result){
            var state = result.getState();
            console.log(' stattess :: ' , result);
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                component.set("v.show",showComp); 
                helper.setToastSuccess(toastMsg);
                let button = event.getSource();
                button.set('v.disabled',true);
                helper.doneWaiting(component, event, helper);
                //$A.enqueueAction(component.get("c.doInit"));
                	helper.navigateToDetail(recId);
                    $A.get('e.force:refreshView').fire();
            }
            else if (state === "ERROR") {
                helper.doneWaiting(component, event, helper);
                var errors = result.getError();
                console.log("Unknown error"+errors[0].fieldErrors.length);
                var errorMsg = "";
                if (errors) {
                    for(var i=0;i<errors.length;i++){
                        if(errors[i].pageErrors.length !== undefined){
							errorMsg += errors[i].pageErrors[0].message+"::";
                        }
                        else if(errors[i].fieldErrors.length !== undefined){
                            errorMsg += errors[i].fieldErrors[0].message+"::";
                        }
                        	
                    }
					errorMsg = errorMsg.substring(0, errorMsg.length - 2);
                    component.set("v.controllerError",errorMsg);
                    helper.setToastFailure(errorMsg);
                } 
                else {
                    console.log("IW-"+btnValue+" Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(btnAction);
    },
    
})