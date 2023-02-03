({
    doInit : function(component, event, helper) {
        helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
        console.log("----Inside Cancel visibility Do Init---"+component.get("{!v.showCancel}"));
        var buttonVisibility = component.get("c.getButtonVisibility");
        buttonVisibility.setParams({
            "recordIWID" : recId,
        });
        buttonVisibility.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                console.log("----button visibility---"+showComp);
                console.log("----Inside Result---"+component.get("{!v.showCancel}"));
                var isBtnVisibile = "false";
                if(showComp.indexOf("Edit") > -1){
                    component.set("v.showEdit","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("Submit") > -1){
                    component.set("v.showSubmit","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("Approve") > -1){
                    component.set("v.showApprove","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("Reject") > -1){
                    component.set("v.showReject","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("Escalate") > -1){
                    component.set("v.showEscalate","true");
                    //component.set("v.showCancel","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("Cancel") > -1){
                    console.log("----Inside Cancel visibility---");
                    component.set("v.showCancel","true");
                    isBtnVisibile = "true";
                }
                if(showComp.indexOf("statusAppr") > -1){
                    component.set("v.showApprove","true");
                    component.set("v.isApproveDisabled","true"); 
                }
                if(showComp.indexOf("statusRej") > -1){
                    component.set("v.showReject","true");
                    component.set("v.isRejectDisabled","true"); 
                }
                if(showComp.indexOf("escAppr") > -1){
                    component.set("v.showEscalate","true");
                    component.set("v.showApprove","true");
                    component.set("v.isApproveDisabled","true");
                    component.set("v.isEscalateDisabled","true");
                }
                if(showComp.indexOf("escRej") > -1){
                    component.set("v.showReject","true");
                    component.set("v.showEscalate","true");
                    component.set("v.isRejectDisabled","true");
                    component.set("v.isEscalateDisabled","true");
                }
                if(showComp.indexOf("statusEsc") > -1){
                    component.set("v.showEscalate","true");
                    component.set("v.isEscalateDisabled","true");
                }
                if(showComp.indexOf("statusCanl") > -1){
                    component.set("v.showCancel","true");
                    component.set("v.isCancelDisabled","true");
                }
                if(!isBtnVisibile){
                    component.set("v.noActionRequiredMsg","true");
                }
                console.log("----Inside Cancel visibility---"+component.get("{!v.showCancel}"));
                $A.get('e.force:refreshView').fire();
                helper.doneWaiting(component, event, helper);
                
            }
            else if (state === "ERROR") {
                helper.doneWaiting(component, event, helper);
                var errors = result.getError();
                var errorMsg = "Fail to load button component ";
                console.log("---Err--"+JSON.stringify(result));
                if (errors) {
                    for(var i=0;i<errors.length;i++){
                        errorMsg += errors[i].message+"::";
                    }
                    errorMsg = errorMsg.substring(0, errorMsg.length - 2);
                    component.set("v.controllerError",errorMsg);
                    helper.setToastFailure(errorMsg);
                } 
                else {
                    console.log("IW-Button Visibility Unknown error");
                }
            }
        });
        $A.enqueueAction(buttonVisibility);
        
    },
    onSubmit :function(component, event, helper) {
        helper.waiting(component, event, helper);
        
        var recId = component.get("v.recordId");
        var submitAction = component.get("c.handleButtonEvent");
        submitAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : "submit",
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : "",
            "internalProd" : '',
            "iwClassification" : ''
        });
        submitAction.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                if(showComp === 'true'){
                    component.set("v.showSubmit",showComp);
                     helper.setToastSuccess("Submitted.");
                    let button = event.getSource();
                    button.set('v.disabled',true);
                    component.set("v.showSubmit","false");
                    component.set("v.showEscalate","false");
                    helper.doneWaiting(component, event, helper);
                    helper.navigateToDetail(recId);
                    //$A.get('e.force:refreshView').fire();
                }
                else if(showComp === 'NoPermission'){
                     helper.doneWaiting(component, event, helper);
                     helper.setToastVar("Error: You don't have permission to submit this request."); 
                }
                else{
                    helper.doneWaiting(component, event, helper);
                    helper.setToastFailure("Error: Request can't be submitted. Requested LOE exceeds the available LOE budget for the selected account. An email has been sent for Investment Work Admins to address the situation.");
                }
 
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
                    console.log("IW-Submit Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(submitAction);
        
    },
    onApprove :function(component, event, helper) {
        //helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
       // helper.doneWaiting(component, event, helper);
        component.set("v.buttonClickedValue","Approve");
        component.set("v.showCommentPopUp",true);
        /*
        var approveAction = component.get("c.handleButtonEvent");
        approveAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : "approve",
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : ""
        });
        approveAction.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                component.set("v.showApprove",showComp);
                helper.setToastSuccess("Approved.");
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
                    
                    console.log("IW-Approve Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(approveAction);*/
    },
    onReject :function(component, event, helper) {
        //helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
        component.set("v.buttonClickedValue","Reject");
        component.set("v.showCommentPopUp",true);
        /*var rejectAction = component.get("c.handleButtonEvent");
        rejectAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : "reject",
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : ""
        });
        rejectAction.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                component.set("v.showReject",showComp); 
                helper.setToastSuccess("Rejected.");
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
                    console.log("IW-Reject Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(rejectAction);*/
    },
    onEscalate :function(component, event, helper) {
        //helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
        component.set("v.buttonClickedValue","Escalate");
        component.set("v.showCommentPopUp",true);
        /*var escalateAction = component.get("c.handleButtonEvent");
        escalateAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : "escalate",
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : ""
        });
        escalateAction.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                component.set("v.showSubmit",showComp);
                 helper.setToastSuccess("Escalated.");
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
                    console.log("IW-Escalate Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(escalateAction);*/
    },
    onCancel :function(component, event, helper) {
        helper.waiting(component, event, helper);
        var recId = component.get("v.recordId");
        var cancelAction = component.get("c.handleButtonEvent");
        cancelAction.setParams({
            "recordIWID" : recId,
            "buttonEvent" : "cancel",
            "LOEHrs":"-1",
            "LOEMins":"-1",
            "Account":"None",
            "Comment" : "",
            "internalProd" : '',
            "iwClassification" : ''
        });
        cancelAction.setCallback(this, function(result){
            var state = result.getState();
            if (component.isValid() && state === "SUCCESS"){
                var showComp = result.getReturnValue();
                component.set("v.showCancel",showComp);
                 helper.setToastSuccess("Cancelled.");
                let button = event.getSource();
                button.set('v.disabled',true);
                helper.doneWaiting(component, event, helper);
                //$A.enqueueAction(component.get("c.doInit"));
                helper.navigateToDetail(recId);
                //$A.get('e.force:refreshView').fire();
                
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
                    console.log("IW-Cancel Button Unknown error");
                }
            }
        });
        
        $A.enqueueAction(cancelAction);
    },
    
    closeModal :function(component, event, helper){
		console.log("closeModal");
		helper.closeModalHelper(component, event, helper);
    },
    
    updateIW :function(component, event, helper) {
        var commentBody = component.get("{!v.CommentBody}");
        var buttonValue = component.get("{!v.buttonClickedValue}");
        console.log("--commentBody--"+commentBody);
        console.log("--buttonValue--"+buttonValue);
		var temporalDivElement = document.createElement("div");
    	// Set the HTML content with the body
    	temporalDivElement.innerHTML = commentBody;
    	// Retrieve the text property of the element (cross-browser support)
    	var plainText = temporalDivElement.textContent || temporalDivElement.innerText || "";
        console.log("--commentBody Text--"+plainText);
        plainText = plainText.trim();
        
        if((buttonValue === "Reject" || buttonValue === "Escalate") && plainText === ""){
            helper.setToastFailure("Error: Comments is required for Rejection and Esclation");
        }
        else{
          helper.onButtonAction(component, event, helper,buttonValue,commentBody);  
        }
        
	},
    
})