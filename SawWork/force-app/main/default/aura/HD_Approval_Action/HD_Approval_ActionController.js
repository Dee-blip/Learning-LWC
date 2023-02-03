({
	getValidActions : function(component, event, helper) {
    	var recordId = component.get("v.recordId");
        var actionCurrentApprover = component.get("c.getCurrentApprover");
        actionCurrentApprover.setParams({incidentId: recordId});
        actionCurrentApprover.setCallback(this,function(response){
            var result = response.getReturnValue();
            //console.log(result);
            if(typeof result.Approver__r != 'undefined'){
           		component.set("v.currentApprover",result.Approver__r.Name);
        	}
        });

        $A.enqueueAction(actionCurrentApprover);
        //console.log($A.util);
	},

    resetError : function(component, event, helper){
      component.set("v.error",false);
      component.set("v.errorMessage","");
    },

    submitApproval : function(component, event, helper){
        var approverId = component.get("v.selectedApproverId");
        //alert(approverId);
        if(approverId != ''){

            helper.addChangeApproverActionHelper(component,event,helper,true);
			return;
        }
    	helper.submitApprovalHelper(component, event, helper);

	},

    recallApproval: function(component,event,helper){
        var recordId = component.get("v.recordId");
        var action = component.get("c.recallForApproval");
        action.setParams({incidentId : recordId, comment : 'Subbmitted'});
        action.setCallback(this,function(response){
        	$A.util.toggleClass(spinner, "slds-hide");
            var state = response.getState();
            if(state == "SUCCESS"){
                component.set("v.error",true);
                component.set("v.errorMessage","Approval Reaclled");
                $A.get('e.force:refreshView').fire();
            }else if(state == "ERROR"){
                var ticketDetails = "Action: Recall Approval | Incident : "+component.get("v.recordId");
                var errors = response.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, ticketDetails+ " -->Ticket already submitted", true, 'warning');
                //component.set("v.errorMessage",errors[0].message);
                //console.log(errors);
            }
            $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();

        });
        $A.enqueueAction(action);
     	var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },

    approverSelected: function(component, event, helper){
   		var selectedValue = event.currentTarget.dataset.id;
        var selectedName = event.currentTarget.dataset.name;
        component.set("v.selectedApprover",selectedName);
		component.set("v.selectedApproverId",selectedValue);
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",selectedName);
    },


    performSearch: function(component, event, helper) {

        var value = event.target.value;

    	//var elem = $A.util.getElement("approverSearch");
    	//var value= $A.util.getElementAttributeValue(elem,"value").trim();
        var resultsFinal=component.get("v.allApprovers");
        var results = [];
        var action = component.get("c.allApproversSearch");
        action.setParams({
            param : value
        });
        action.setCallback(this,function(response){
            if(response.getState() == 'SUCCESS'){
                var data = response.getReturnValue();
                var resultsFinal = data;
                for(let key in resultsFinal){
                    if(resultsFinal[key].Name.match(reg) || resultsFinal[key].Email.match(reg) ){
                        results.push({name:resultsFinal[key].Name,id:resultsFinal[key].Id,email:resultsFinal[key].Email});
                    }
            	}
           		component.set("v.results",results);
        	}
        });

        if(value == null || value == '' || value.length<3){
        	results = [];
            component.set("v.results",[]);
        } else{
            $A.enqueueAction(action);
        	var reg = new RegExp(value.trim(), 'i');
            /*for(key in resultsFinal){
               	if(resultsFinal[key].Name.match(reg) || resultsFinal[key].Email.match(reg) ){
                	results.push({name:resultsFinal[key].Name,id:resultsFinal[key].Id,email:resultsFinal[key].Email});
                }
            } */
        }
        //component.set("v.results",results);
    },

    addChangeApproverAction: function(component, event, helper) {
        helper.addChangeApproverActionHelper(component,event,helper, false);
    }
})