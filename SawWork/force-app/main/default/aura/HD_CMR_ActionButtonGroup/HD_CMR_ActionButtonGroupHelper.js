({
	helperMethod : function() {
		
	},
    submitForApproval : function(component, event, helper) {
        
        var changeId=component.get("v.change.Id");
        var action = component.get("c.submitForApproval");
        var response="";
        component.set("v.isSpinnerEnabled",true);
        action.setParams({
            "cmrId" : changeId,
            "comment" : "",
        });
        
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                if(result){
                    // disable the spinner
                    //Change the updated CMR Data
                    var updatedCMR=result;
                    component.set('v.change',updatedCMR);

                    //Refreshing the main list view
                    var incList = component.getEvent("getChangeListEvent").fire();

                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
                    helper.showSuccessToast(component, event, helper,"CMR is submitted for approval successfully.")
                }else{
                    //throw error message
                    // disable the spinner
                    helper.showErrorToast(component, event, helper,"Error occurred while submitting for approval, please contact helpdesk team.");
                    component.set("v.isSpinnerEnabled",false);
                }
                
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
                    helper.showErrorToast(component, event, helper,"Error occurred while approving/rejecting cmr. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while approving/rejecting cmr. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    
    clone : function(component, event, helper){
        console.log("In clone");
        var cmr=component.get("v.change");
        var action = component.get("c.getFieldValues");
        action.setParams({
            "currentCMR" : cmr
        });
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                if(result){
                     var createRecordEvent = $A.get("e.force:createRecord");
            		createRecordEvent.setParams({
                        "entityApiName": "BMCServiceDesk__Change_Request__c",
          				"defaultFieldValues": result,
                    });
                    createRecordEvent.fire();
                }
                else{
                    console.log("Error here");
                    //report error
                }
            }
            else{
                console.log("State is not success");
            }
        });
        $A.enqueueAction(action);
    },
    
    close : function(component, event, helper,status){
		var cmr=component.get("v.change");
        var cmrStatus = cmr.BMCServiceDesk__FKStatus__c;
        var action = component.get("c.getPIR");
        component.set("v.isSpinnerEnabled",true);
        
        action.setParams({
            "currentCMR" : cmr
        });
        action.setCallback(this,function(data){
            var state=data.getState();
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                if(result){
                    //PIR is present, change the status to Closed
                    var fetchedChange = result;
                    
                    if(fetchedChange.Post_Implementation_RollUp__c<1){
                       //If PIR is not present open PIR form and close the CMR
                      component.set("v.isSpinnerEnabled",false); 
                      component.set("v.PIRStatus",status);
                      component.set("v.renderCreateForm",true);
                      
                    } 
                    else{
                        
                    	 helper.closeCMR(component,event,helper,fetchedChange,status);
                           
                    }
                    
                }
                else{
                    console.log("Error here");
                    //report error
                }
            }
            else{
                console.log("State is not success");
            }
        });
        $A.enqueueAction(action);      
    },
    
    closeCMR : function(component, event, helper, fetchedChange,status){
         var action = component.get("c.changeCMRStatus");
         var state = status;
         var success_msg =  "CMR has been CLOSED successfully";
         var failure_msg =  "Error occurred while closing CMR, please contact helpdesk team."
        if (status == "CHANGE FAILED"){
            success_msg =  "CMR has been marked as CHANGE FAILED successfully";
            failure_msg =  "Error occurred while marking as CHANGE FAILED, please contact helpdesk team."
        }
        action.setParams({
            "currentCMR" : fetchedChange,
            "status"	: state
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
                    
                    // disable the spinner
                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
        			
                    helper.showSuccessToast(component, event, helper,success_msg);
                }
                else{
                   helper.showErrorToast(component, event, helper, failure_msg);
                    component.set("v.isSpinnerEnabled",false);
                }
            }
            else if (state==="ERROR"){
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
                    helper.showErrorToast(component, event, helper,failure_msg+" Error: "+errorMessage);
                }else{
                    helper.showErrorToast(component, event, helper, failure_msg);
                }
            }
            
        });
        $A.enqueueAction(action);
    },
    inProgress : function(component, event, helper) {
        var change=component.get("v.change");
        var action = component.get("c.changeCMRStatus");
        var status="IN PROGRESS";
        component.set("v.isSpinnerEnabled",true);
        action.setParams({
            "currentCMR" : change,
            "status" : status,
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
                    
                    // disable the spinner
                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
        			
                    helper.showSuccessToast(component, event, helper,"CMR is marked as In Progress successfully.")
                }else{
                    //throw error message
                    // disable the spinner
                    helper.showErrorToast(component, event, helper,"Error occurred while marking In Progress, please contact helpdesk team.");
                    component.set("v.isSpinnerEnabled",false);
                }
                
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
                    helper.showErrorToast(component, event, helper,"Error occurred while marking In Progress. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while marking In Progress. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    cancel : function(component, event, helper) {
        var change=component.get("v.change");
        var action = component.get("c.changeCMRStatus");
        var status="CANCELLED";
        component.set("v.isSpinnerEnabled",true);
        action.setParams({
            "currentCMR" : change,
            "status" : status,
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
                    
                    // disable the spinner
                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
                    
                    helper.showSuccessToast(component, event, helper,"CMR is cancelled successfully.")
                }else{
                    //throw error message
                    // disable the spinner
                    helper.showErrorToast(component, event, helper,"Error occurred while cancelling cmr, please contact helpdesk team.");
                    component.set("v.isSpinnerEnabled",false);
                }
                
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
                    helper.showErrorToast(component, event, helper,"Error occurred while marking In Progress. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while marking In Progress. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
    },completed : function(component, event, helper) {
        var change=component.get("v.change");
        var action = component.get("c.changeCMRStatus");
        var status="COMPLETED";
        component.set("v.isSpinnerEnabled",true);
        action.setParams({
            "currentCMR" : change,
            "status" : status,
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
                    
                    // disable the spinner
                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
        			
                    helper.showSuccessToast(component, event, helper,"CMR is marked as Completed successfully.")
                }else{
                    //throw error message
                    // disable the spinner
                    helper.showErrorToast(component, event, helper,"Error occurred while marking as Completed, please contact helpdesk team.");
                    component.set("v.isSpinnerEnabled",false);
                }
                
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
                    helper.showErrorToast(component, event, helper,"Error occurred while marking Completed. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while marking Completed. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
	},changeFailed : function(component, event, helper) {
        var change=component.get("v.change");
        var action = component.get("c.changeCMRStatus");
        var status="CHANGE FAILED";
        component.set("v.isSpinnerEnabled",true);
        action.setParams({
            "currentCMR" : change,
            "status" : status,
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
                    
                    // disable the spinner
                    component.set("v.isSpinnerEnabled",false);
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
        			
                    helper.showSuccessToast(component, event, helper,"CMR is marked as Completed successfully.")
                }else{
                    //throw error message
                    // disable the spinner
                    helper.showErrorToast(component, event, helper,"Error occurred while marking as Completed, please contact helpdesk team.");
                    component.set("v.isSpinnerEnabled",false);
                }
                
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
                    helper.showErrorToast(component, event, helper,"Error occurred while marking Completed. Error: "+errorMessage+". Please contact helpdesk team");
                }else{
                    helper.showErrorToast(component, event, helper,"Error occurred while marking Completed. Please contact helpdesk team");
                }
            }
        });
        
        $A.enqueueAction(action);
	},
    
    showErrorToast : function(component, event, helper,errorMessage) {
		var errorMessageTemp=errorMessage;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error',
            message: errorMessageTemp,
            messageTemplate: 'Mode is pester ,duration is 5sec and Message is overrriden',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },

    showWarningToast : function(component, event, helper,errorMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Warning',
            message: errorMessage,
            messageTemplate: 'Mode is pester ,duration is 3sec and Message is overrriden',
            messageTemplateData:'' ,
            duration:' 3000',
            key: 'info_alt',
            type: 'warning',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    showSuccessToast : function(component, event, helper,successMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: successMessage,
            messageTemplate: 'Mode is pester ,duration is 3sec and Message is overrriden',
            duration:' 3000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    }
    
})