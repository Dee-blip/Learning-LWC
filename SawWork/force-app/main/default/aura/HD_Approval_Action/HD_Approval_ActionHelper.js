({
	addChangeApproverActionHelper : function(component,event,helper,submitApproval) {
		var recordId = component.get("v.recordId");
        var approverId = component.get("v.selectedApproverId");
        //alert(approverId);
        if(approverId == ''){
            //alert(approverId);
            HD_Error_Logger.createLogger(component, event, helper,
                                         'No Approver Selected',"No Approver Selected Attempt to add/change approver on incident: "+component.get("v.recordId"),
                                         true,'warning');
            return;
        }
        var changeApprover = component.get("c.addChangeApprover");
        changeApprover.setParams({incidentId: recordId, approverId: approverId });
        changeApprover.setCallback(this,function(response){
            $A.util.toggleClass(spinner, "slds-hide");
            var state= response.getState();
            if(state == "SUCCESS"){
                component.set("v.currentApprover", component.get("v.selectedApprover"));
                component.set("v.selectedApprover", "");
                component.set("v.searchQuery","");
                component.set("v.selectedApproverId","");
                if(submitApproval){
                    helper.submitApprovalHelper(component,event,helper);
                }
            } else{
            	//console.log(response);
                 //component.set("v.error",true);
                 //component.set("v.errorMessage","Cannot Change Approver");
                 var errors = response.getError();
                 let type = (errors[0].message ==='No Approver Selected') ? 'warning' : 'error';
                 /* eslint-disable-next-line */
                 HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message+ " |Attempt to add/change approver", false, type);
            }

        });
    	$A.enqueueAction(changeApprover);
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
	},

    submitApprovalHelper : function(component,event,helper){
        var recordId = component.get("v.recordId");
        var actionSubmitApproval = component.get("c.submitForApproval");
        actionSubmitApproval.setParams({incidentId : recordId, comment : 'Subbmitted'});
        actionSubmitApproval.setCallback(this,function(response){
        	$A.util.toggleClass(spinner, "slds-hide");
            var state= response.getState();
            if(state == "SUCCESS"){
                var ticketDetails = "Action: Submit Approval | Incident : "+component.get("v.recordId");
                console.log(response.returnValue);
                if(response.returnValue.search('ALREADY_IN_PROCESS') >= 0){

                    HD_Error_Logger.createLogger(component, event, helper, "Ticket already submitted", ticketDetails+ " -->Ticket already submitted", true, 'warning');
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : 'ERROR' }).fire();
                }
                else if(response.returnValue.search("Process failed") >= 0){
					HD_Error_Logger.createLogger(component, event, helper, "No Applicable Approval", ticketDetails+ " -->No Approval Process Found", true, 'error');
                    //component.set("v.errorMessage","No Applicable Approval");
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : 'ERROR' }).fire();
                }
                else{
                    component.set("v.error",true);
                    component.set("v.errorMessage","Ticket Submitted For Approval");
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                }
            }

        });
        $A.enqueueAction(actionSubmitApproval);
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    }
})