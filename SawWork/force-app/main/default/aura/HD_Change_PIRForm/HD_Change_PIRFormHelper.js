({
	hideCreateFormHelper : function(component, event){
      	//helper.clearFields(component);
		var renderEvent = $A.get("e.c:hd_renderCreateFormEvent");
       	renderEvent.setParams({"renderForm":false}).fire();
    },
    waiting: function(component) {
        var ele = component.find("Accspinner");
        console.log("waiting called");
        $A.util.addClass(ele,"slds-show");
        $A.util.removeClass(ele,"slds-hide");
     },
     
      doneWaiting: function(component) {
            var ele = component.find("Accspinner");
          	console.log(ele);
            $A.util.addClass(ele,"slds-hide");
            $A.util.removeClass(ele,"slds-show");
     },
    closeCMR : function(component, event,fetchedChange){
        console.log("In PIR Form closeCMR");
         var action1 = component.get("c.changeCMRStatus");
         var state = component.get("v.changeStatus");
        
         var success_msg =  "CMR has been CLOSED successfully";
         var failure_msg =  "Error occurred while closing CMR, please contact helpdesk team."
        if (status == "CHANGE FAILED"){
            success_msg =  "CMR has been marked as CHANGE FAILED successfully";
            failure_msg =  "Error occurred while marking as CHANGE FAILED, please contact helpdesk team."
        }
        action1.setParams({
            "currentCMR" : fetchedChange,
            "status"	: state
        });
        action1.setCallback(this,function(data){
            console.log("In callback close PIR");
            var state=data.getState();
            console.log(state);
            if(state==="SUCCESS"){
                var result=data.getReturnValue();
                console.log("Result in PIR close: "+result);
                if(result){
                    console.log('In if(result)');
                    var updatedCMR=result;
                    component.set('v.currentChangeRequest',updatedCMR);
                    
                    //Refreshing the main list view
                    var incList = component.getEvent("getChangeListEvent").fire();
                    
                    
                    //refresh the component
                    var cmpEvent = component.getEvent('refreshPreview');
                    cmpEvent.setParams({"change":updatedCMR}).fire();
        			
                    this.showSuccessToast(component, event,success_msg);
                }
                else{
                    console.log("In else-1");
                    this.showErrorToast(component, event,failure_msg);
                    //component.set("v.isSpinnerEnabled",false);
                }
                this.doneWaiting(component);
            }
            else if (state==="ERROR"){
                console.log("In error else")
                //component.set("v.isSpinnerEnabled",false);
                var errorMessage="";
                var errors=data.getError();
                if (errors) {
                    console.log("In if(erros)");
                    var error=errors[0];
                    for(var temp in error){
                        var temp1=error[temp];
                        try{
                            errorMessage=errorMessage+" "+temp1[0].message;
                        }catch(err ){
                            continue;
                        }
                    }
                    this.showErrorToast(component, event,failure_msg+" Error: "+errorMessage);
                }else{
                    console.log("In final else");
                    this.showErrorToast(component, event,failure_msg);
                }
                this.doneWaiting(component);
            }
            
        });
        $A.enqueueAction(action1);
        this.waiting(component);
    },
    showErrorToast : function(component, event,errorMessage) {
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

    showWarningToast : function(component, event,errorMessage) {
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
    showSuccessToast : function(component, event,successMessage) {
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