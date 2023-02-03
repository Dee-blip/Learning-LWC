({
    doInit: function (component, event, helper) {
        let taskAction = component.get("c.getOpenTasks");
        taskAction.setParams({
            recordId: component.get("v.recordId")

        });
        taskAction.setCallback(this, function (data) {
            if (data.getState() === 'SUCCESS') {
                component.set("v.hasOpenTasks", data.getReturnValue()?.length > 0);
                let action = component.get("c.getIncident");
                action.setParams({
                    incidentId: component.get("v.recordId")

                });
                action.setCallback(this, function (res) {
                    if (res.getState() === 'SUCCESS') {
                        let response = res.getReturnValue();

                        if (response.BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r && response.BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r.Name.includes("HR") > 0) {
                            component.find("resolution").set("v.placeholder", "DO NOT enter confidential data in the resolution field.  This field should NEVER contain confidential information such as personal, benefit, salary, vesting or employee performance information.");
                        }
                    }
                    else if (res.getState() === 'ERROR') {
                        let errors = res.getError();
                        /* eslint-disable-next-line */
                        HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');
                    }
                });
                $A.enqueueAction(action);
            }
            else if (data.getState() === 'ERROR') {
                let errors = data.getError();
                /* eslint-disable-next-line */
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');
            }
        });
        $A.enqueueAction(taskAction);

    },
    resolveTicket: function (component, event, helper) {
        var warningMessages = [];
        var re;
        var reHHMM = new RegExp("^([0-9][0-9]:[0-9][0-9])");
        component.set("v.warnings", " ");
        var index = 0;
        var incId = component.get("v.recordId");
        console.log("incId" + incId);
        console.log("resolution " + component.find("resolution").get("v.value"));
        var resolution = component.find("resolution").get("v.value");
        var effort = component.find("effort").get("v.value");
        console.log("effort" + effort);
        /* eslint-disable-next-line */
        if (resolution == null || resolution == '' || resolution == 'undefined') {
            warningMessages[index] = "Resolution is mandatory. Please enter Resolution";
            index++;
        }
        /* eslint-disable-next-line */
        if (effort == null || effort == '' || effort == 'undefined') {
            warningMessages[index] = "Please enter Effort Estimate";
            index++;
        }
        /* eslint-disable-next-line */
        if (!effort || effort.length !==  5 || !effort.match(reHHMM)) {
            warningMessages[index] = "Effort Estimate should be in the range hh:mm format";
            index++;
        }
        else {
            re = new RegExp("^((([1-9][0-9])):[0-5][0-9])|(00:[1-5][0-9])|(00:0[1-9])|(0[1-9]:[0-5][0-9])");     //PRTORES-2004 Change of Effort Estimate by Amogh
            if (!effort.match(re)) {
                console.log("Invalid effort");
                warningMessages[index] = "Effort Estimate should be in the range 00:01 to 99:59";
                index++;
            }
        }

        component.set("v.warnings", warningMessages);
        console.log('warningMessages:' + warningMessages);
        if (warningMessages.length === 0) {
            let action = component.get("c.addResolution");
            action.setParams({
                recordId: incId,
                resolution: resolution,
                effortEstimate: (effort = effort.trim()),
                closeTasks: (component.get("v.hasOpenTasks") ? component.find("taskCloseConfirm").get('v.checked') : false).toString()
            });

            action.setCallback(this, function (data) {
                let state = data.getState();
                if (state === 'SUCCESS') {
                    let retVal = data.getReturnValue();
                    console.log("return value " + retVal);
                    $A.get('e.force:refreshView').fire();
                    console.log("firing refresh view event");
                }
                else if (state === 'ERROR') {


                    /* var errors = data.getError();
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
                    let errors = data.getError();
                    /* eslint-disable-next-line */
                    HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message, false, 'error');

                }
                $A.get("e.c:HD_ActionAuditEvent").setParams({ "state": state }).fire();

            });
            $A.enqueueAction(action);
        }

    }

})