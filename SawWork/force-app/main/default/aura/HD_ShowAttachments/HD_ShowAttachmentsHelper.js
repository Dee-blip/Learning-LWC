({
    doInitHelper : function(component,event) { //added the helper for better reusability	
        var action = component.get("c.showAttachments");
        action.setParams({
            incidentId : component.get("v.recordId")
        });
        action.setCallback(this,function(data){
            var state = data.getState();
            if(state == 'SUCCESS'){
                var retVal = data.getReturnValue();
                component.set("v.attachments",retVal.attachments);
                component.set("v.files",retVal.files);
                component.set('v.loadingFlag',false);
            }else if(state == 'ERROR'){
                var errors = data.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false);
                return;
            }
        });
        $A.enqueueAction(action);
    },
    toggledeleteactionSpinner : function(component,event) {
        var spinner =  component.find('delete_action');  
        console.log(spinner)
        $A.util.toggleClass(spinner, "slds-hide");
    },
    
    deleteActionHelper : function(component,event,helper){
        var getClickButtonId = event.getSource().get("v.value");
        this.toggledeleteactionSpinner(component, event );
        //alert(getClickButtonId);
        var delete_action = component.get("c.showAttachmentsDeleteOption");
        delete_action.setParams({
        		attORFileId : getClickButtonId
      		});
        delete_action.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS"){
                var deleted_resp = resp.getReturnValue();
                console.log(deleted_resp);
                this.toggledeleteactionSpinner(component, event);
                this.doInitHelper(component, event);//calling the created helper method for rerenderign the data
            }//SUCCESS
            else if(state === 'ERROR')
            {
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                        this.toggledeleteactionSpinner(component, event);
                        HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false);
                    }
                } else {
                    console.log("Unknown error");
                }  
            }//ERROR
        });
       $A.enqueueAction(delete_action);

    }
})