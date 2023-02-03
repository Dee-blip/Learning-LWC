({
	doInit : function(component, event, helper) {
        var el = component.find("pgsprtdiv");
        console.log("el in change priority component: ");
        console.log(el);
    	$A.util.removeClass(el, "slds-show"); 
    	$A.util.addClass(el, "slds-hide"); 
        var opts = [ 
            		{ "class": "optionClass", label: "--None--", value: "none" },
            		{ "class": "optionClass", label: "1", value: "1" },
                 	{ "class": "optionClass", label: "2", value: "2" },
             	  	{ "class": "optionClass", label: "3", value: "3" },
             		{ "class": "optionClass", label: "4", value: "4" }
        		  ];
        
         component.find("aurapriorityinput").set("v.options", opts);
         var incId = component.get("v.recordId");
        
       
         
        var pagevalue;
        //var pagevalue = true;
        //component.set("v.pagesupport",pagevalue);
        //var action = component.get("c.getIncident");
        var action = component.get("c.getIncidentWithPriority");
            action.setParams({
        		incidentId : incId
      		});
        
        action.setCallback(this,function(data){
            var state = data.getState();
            
                if(state == 'SUCCESS'){
                   console.log(" OPTION MAP success");
                    //retVal = data.getReturnValue();
                    var incopts =  data.getReturnValue();
                    console.log(incopts);
                    var retVal = incopts.incident;
                    console.log(retVal);
                    console.log('whywhy'+retVal.BMCServiceDesk__Type__c);
                    if(retVal.BMCServiceDesk__Type__c != 'Incident')
                    {
                        console.log("OPTION MAP");
                        console.log(incopts.OptionValues);
                        var optionVals = incopts.OptionValues;
                        var selected =  incopts.slectedOpt;
                        var SRopts = [{ "class": "optionClass", label: "--None--", value: "none" }];
                        for( var key in optionVals ){
                            if(selected == optionVals[key]){
                                SRopts.push({ "class": "optionClass", label: key, value: optionVals[key], "selected" :true  })
                            }else{
                                SRopts.push({ "class": "optionClass", label: key, value: optionVals[key] })
                            }
                                
                        }
                       /* var SRopts = [ 
                        { "class": "optionClass", label: "--None--", value: "none" },
                        { "class": "optionClass", label: "High", value: "3" },
                        { "class": "optionClass", label: "Standard", value: "4" }
                      	]; */
                        component.find("aurapriorityinput").set("v.options", SRopts);
                        console.log("why?");
                       
                       
                        
                    }
                    component.set("v.pagesupport",retVal.HD_High_Customer_Impact__c);
                    component.find("aurapriorityinput").set("v.value", retVal.HD_Ticket_Priority__c);
                    if(retVal.HD_High_Customer_Impact__c == true){
                        $A.util.removeClass(el, "slds-hide"); 
                        $A.util.addClass(el, "slds-show"); 
    	                
                        
                    }
                       
                     
                }
            else if(state == 'ERROR'){
                console.log('Failed to get prioirity values');
                var errors = data.getError();
                console.log("Error in Change Priority-init") 
                console.log("---->" + errors[0].message);
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false,'error');
                return;
            }
        });
            $A.enqueueAction(action);
            
	},
    
    onPrioritySelect : function(component, event, helper) {
        var priorityCmp = component.find("aurapriorityinput");
        var priorityId = priorityCmp.get("v.value");
        var el = component.find("pgsprtdiv");
        if(priorityId == 1){
            
    		$A.util.removeClass(el, "slds-hide"); 
    		$A.util.addClass(el, "slds-show"); 
        }
        else{
            
            $A.util.removeClass(el, "slds-show"); 
    		$A.util.addClass(el, "slds-hide"); 
        }
    },
    
    changeIncPriority : function(component, event, helper) {
        var warningMessages = [];
        var index = 0;
        component.set("v.warnings"," ");
        var priorityCmp = component.find("aurapriorityinput");
        var priorityId = priorityCmp.get("v.value");
        //if(priorityId == 1){
          //  var el = component.find("pgsprt");
    		//$A.util.removeClass(el, "slds-hide"); 
    		//$A.util.addClass(el, "slds-show"); 
        //}
        //console.log('Priority ID: ');
        //console.log(priorityId);
        var pageValue = component.get("v.pagesupport");
        console.log("page value in changeIncPriority: ");
        console.log(pageValue);
        console.log("Priority Cmp: ");
        console.log(priorityCmp);
        console.log("Priority: "+priorityId);
        if(priorityId == null || priorityId == ' ' || priorityId == 'none'){
            warningMessages[index] = "Please select a valid priority";
            index++;
        }
        if(priorityId == 1 && pageValue == false){
            console.log("In error if");
            warningMessages[index] = "Please check Page Support";
            index++;
        }
        if(priorityId != 1 && pageValue == true){
            console.log("In error if");
            pageValue = false;		//automatically setting page value to false
            //warningMessages[index] = "Please un-check Page Support";
            //index++;
        }
        component.set("v.warnings",warningMessages);
        if(warningMessages.length==0){
            //component.set("v.searchQuery","");
         	var incId = component.get("v.recordId");
         	console.log("incId"+incId);
         	console.log("In Change Priority");
         	var action = component.get("c.changePriority");
            action.setParams({
        		incidentId : incId,
                priority : priorityId,
                pageSupportValue : pageValue
      		});
            console.log("priority : "+priorityId);
            action.setCallback(this,function(data){
                priorityCmp.selected = " ";
                var state = data.getState();
                if(state == 'SUCCESS'){
                	var data = data.getReturnValue();
                	console.log("return value "+data);
                	console.log(data);
                	$A.get('e.force:refreshView').fire();
          			console.log("firing refresh view event");
                    
                }
                     else if(state == 'ERROR')
                {
                    /*
                    console.log("State = ERROR");
                    var errors = data.getError();
                    if (errors) {
                        console.log("Found errors: "+errors);
                        console.log("After errors");
                        console.log(errors[0]);
                        console.log(errors[0].message);
                        if (errors[0] && errors[0].message) {
                            console.log("In if");
                            console.log("Error message: " +
                                    errors[0].message);
                            
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": errors[0].message
                            });
                            toastEvent.fire();

                            
                        }
                        else{
                             console.log("Unknown error !!");
                        var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": "Unknown error"
                            });
                            toastEvent.fire();
                        }
                    } else {
                        console.log("Unknown error");
                        var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": "Unknown error"
                            });
                            toastEvent.fire();
                    }
                    */
                    var errors = data.getError();
                    console.log("Errors object:");
                    console.log(errors);
                    console.log("Error in Change Priority") 
                    console.log("---->" + errors[0].message);
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false,'error');
            		helper.doneWaiting(component);
                    $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
                    return;
                }
                helper.doneWaiting(component);
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
    		});
            $A.enqueueAction(action);
            helper.waiting(component);
        }
        
    }
 })