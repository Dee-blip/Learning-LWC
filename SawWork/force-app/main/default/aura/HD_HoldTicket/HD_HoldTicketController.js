({
	doInit : function(component, event, helper) {
        var el = component.find("statusnotediv");
        console.log("el in hold ticket component: ");
        console.log(el);
    	$A.util.removeClass(el, "slds-show"); 
    	$A.util.addClass(el, "slds-hide"); 
		var opts = [ 
            		{ "class": "optionClass", label: "--None--", value: "none" },
            		{ "class": "optionClass", label: "ON HOLD", value: "ON HOLD" },
                 	{ "class": "optionClass", label: "PENDING CMR", value: "PENDING CMR" },
             	  	{ "class": "optionClass", label: "PENDING HARDWARE", value: "PENDING HARDWARE" },
             		{ "class": "optionClass", label: "PENDING SOFTWARE", value: "PENDING SOFTWARE" },
            		{ "class": "optionClass", label: "PENDING USER RESPONSE", value: "PENDING USER RESPONSE" },
            		{ "class": "optionClass", label: "PENDING OTHER TEAMS", value: "PENDING OTHER TEAMS" },
            		{ "class": "optionClass", label: "PENDING APPROVAL", value: "PENDING APPROVAL" },
            		{ "class": "optionClass", label: "PENDING OTHERS", value: "PENDING OTHERS" },
                    { "class": "optionClass", label: "PENDING THIRD PARTY", value: "PENDING THIRD PARTY" } 
        		  ];
        
         component.find("aurastatusinput").set("v.options", opts);
	},
    
    onStatusSelect : function(component, event, helper) {
        var statusCmp = component.find("aurastatusinput");
        var statusName = statusCmp.get("v.value");
        var el = component.find("statusnotediv");
        if(statusName == "PENDING OTHERS"){
            console.log("Status is Pending Others");
    		$A.util.removeClass(el, "slds-hide"); 
    		$A.util.addClass(el, "slds-show"); 
        }
        else{
            
            $A.util.removeClass(el, "slds-show"); 
    		$A.util.addClass(el, "slds-hide"); 
        }
        
    },
    
    onHold : function(component, event, helper){
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        var statusCmp = component.find("aurastatusinput");
        var statusName = statusCmp.get("v.value");
        //var note=$A.util.getElement("statusNoteInput").value;
        var note=component.find("aurastatusnoteinput").get("v.value");
        console.log("Note: "+note);
        if(statusName == null || statusName == ' ' || statusName == 'none'){
            warningMessages[index] = "Please select a status";
            index++;
        }
        
        if(statusName == "PENDING OTHERS"&& (note == null || note == '')){
			console.log("Please enter additional information");
            warningMessages[index] = "Please provide additional information for this status";
            index++;
        }
        
        component.set("v.warnings",warningMessages);
        if(warningMessages.length==0){
            var incId = component.get("v.recordId");
         	console.log("incId"+incId);
         	console.log("In onHold");
            var action = component.get("c.holdTicket");
            action.setParams({
        		incidentId : incId,
                status : statusName,
                holdnote: note
      		});
            
            console.log("status : "+statusName);
            action.setCallback(this,function(data){
                //component.find("aurastatusinput").value = " ";
                //component.find("aurastatusnoteinput").value = " ";
                //$A.util.getElement("aurastatusnoteinput").value = " "
                var state = data.getState();
                if(state == 'SUCCESS'){
                	var data = data.getReturnValue();
                	console.log("return value "+data);
                	console.log(data);
                	$A.get('e.force:refreshView').fire();
          			console.log("firing refresh view event");
                    
                }else if(data.getState() == 'ERROR'){
                    console.log('Failed in hold ticket');
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message, false, 'error');
               }
                 helper.doneWaiting(component);
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
        });
            $A.enqueueAction(action);
            helper.waiting(component);
    }
}
})