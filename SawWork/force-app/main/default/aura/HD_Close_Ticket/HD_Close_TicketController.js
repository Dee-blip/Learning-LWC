({
    
    doInit: function(component, event, helper) {

        var action = component.get("c.getIncident");
        action.setParams({
            incidentId : component.get("v.recordId")
                
        }); 
        action.setCallback(this,function(data){
            if(data.getState() == 'SUCCESS'){
                var response = data.getReturnValue();
                
                if(response.BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r && response.BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r.Name.includes("HR")>0)
                {
                    component.find("resolution").set("v.placeholder","DO NOT enter confidential data in the resolution field.  This field should NEVER contain confidential information such as personal, benefit, salary, vesting or employee performance information.");
                }
            }
            else if(data.getState() === 'ERROR'){
                 var errors = data.getError();
                 /* eslint-disable-next-line */
                 HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false,'error');
            }
        });
        $A.enqueueAction(action);
        
        
    },
    
    handleRecordUpdated : function(component, event, helper) {
        
   		console.log(component.get("v.incident"));
    	component.set("v.incident",component.get("v.lservice_record"));    
    },
    
    closeTicket : function(component, event, helper) {
        var warningMessages = [];
        component.set("v.warnings"," ");
        var index = 0;
        var incId = component.get("v.recordId");
        console.log("incId"+incId);
        console.log("resolution "+component.find("resolution").get("v.value"));
        var resolution = component.find("resolution").get("v.value");
        var effort = component.find("effort").get("v.value");
        
        console.log("effort"+effort);
        if(resolution == null || resolution == '' || resolution == 'undefined'){
            warningMessages[index] = "Resolution is mandatory. Please enter Resolution";
            index++;
        }
        if(effort == null || effort == '' || effort == 'undefined'){
            effort = null;
        }
        else
        {	
            var incidentGroup = component.get("v.incident").HD_Incident_Group__c;
            var reHR = new RegExp("^((([1-9][0-9])):[0-5][0-9])|(00:[1-5][0-9])|(00:0[1-9])|(0[1-9]:[0-5][0-9])");
            var re = new RegExp("^((([1-9][0-9])):[0-5][0-9])|(00:[1-5][0-9])|(0[1-9]:[0-5][0-9])");
            var reHHMM = new RegExp("^([0-9][0-9]:[0-9][0-9])");
            if(effort.length!=5 || !effort.match(reHHMM)){
                warningMessages[index] = "Effort Estimate should be in the range hh:mm format";
                index++; 
                //return;
            }
            else if((incidentGroup === 'HR' || incidentGroup === 'Corp IT') && !effort.match(reHR)){
                warningMessages[index] = "Effort Estimate should be in the range 00:01 to 99:59";
                index++;
                //return;
            }
            else if(incidentGroup !== 'HR' && incidentGroup !== 'Corp IT' && !effort.match(re)){
              console.log("Invalid effort");
                warningMessages[index] = "Effort Estimate should be in the range 00:10 to 99:59";
                index++;
                //return;
            }
            else
            {
                effort = effort.trim();
            }
        }
        
        component.set("v.warnings",warningMessages);
        console.log('warningMessages:'+warningMessages);
        if(warningMessages.length==0)
        {
                var action = component.get("c.closeIncident");
        
            action.setParams({
                recordId : incId,
                resolution : resolution,
                effortEstimate : effort
                
            });
                
            action.setCallback(this,function(data){
                var state = data.getState();
                if(state == 'SUCCESS')
                {
                    var data = data.getReturnValue();
                    console.log("return value "+data);
                    $A.get('e.force:refreshView').fire();
                    console.log("firing refresh view event");
                }
                else if(state == 'ERROR')
                {
                    /*var errors = data.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
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
                    } else {
                        console.log("Unknown error");
                        var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type": "error",
                                "message": "Unknown error"
                            });
                            toastEvent.fire();
                    }*/
                    var errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message,errors[0].message,false,'error');
                    //HD_Error_Logger.createLogger(component, event, helper, 'aba-dba-du',errors[0].message,true);
                }
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state" : state }).fire();
            });
            $A.enqueueAction(action); 
        }
   
    }
    
})