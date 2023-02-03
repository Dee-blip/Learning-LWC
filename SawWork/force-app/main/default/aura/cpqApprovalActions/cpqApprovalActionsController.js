({
    /**
     * doInit method is used to perform logic upon component initialization
     * checks for logged in user CPQ_Permission
     *  
     */
    doInit: function (component, event, helper) {

        // server call to check CPQ permission of user
        var action = component.get("c.checkCPQPermission");
        action.setParams({ customPermissionApiName : 'CPQ_Permission' });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                // console.log('permission: ',result);
                component.set('v.hasCPQPermission', result);

            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    },
    
    /**
     * handleRecordUpdated method is used to track when the record is loaded or changed
     * it gets the required fields value from recordData on LOADED changeType
     */
    handleRecordUpdated: function (component, event, helper) {

        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
            //get the AA field value if set
            var key = 'v.simpleRecord.' + component.get('v.objectField');
            var value = component.get(key);
            component.set('v.cpqApprovalId', value);

            var recordType = component.get('v.simpleRecord.RecordTypeId');
            // console.log('--recordtype: ' + recordType);
            component.set('v.recordTypeId', recordType);

        } else if (eventParams.changeType === "CHANGED") {
            // record is changed
        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if (eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }

    },

    /**
     * executeAction method is called when user clicks on Approve/Reject button
     * it generates a URL based on type of AD: Quote term, OM Approval (AA)
     * it calls the navigateToApprovalPage hepler method to navigate user to the generated URL
     */
    executeAction: function (component, event, helper) {
        //method to handle approve or reject actions from UI

        var approvalId = component.get('v.cpqApprovalId');
        var actionType = event.getSource().getLocalId();

        //check if AD type: AA or QT
        if (approvalId != null && approvalId != undefined) {
            //handle AA type: navigate to the AA managed package vf page in a sub-tab
            var vfURL = "/apex/sbaa__" + actionType + "?id=" + approvalId;
            // console.log("--VF URL: ", vfURL);
            helper.navigateToApprovalPage(component, vfURL, actionType);

        } else {
            //handle Quote Term AD type
            var pageReference = {
                type: 'standard__component',
                attributes: {
                    componentName: 'c__cpqQuoteTermApprovalComponent',
                },
                state: {
                    "c__action": actionType,
                    "c__recordId": component.get('v.recordId'),
                    "c__recordTypeId": component.get('v.recordTypeId')
                }
            };
            var navService = component.find("navService");
            navService.generateUrl(pageReference)
                .then(urlResponse => {
                    helper.navigateToApprovalPage(component, urlResponse, actionType);
                })
                .catch(err => {
                    console.log(err);
                });

        }

    },

})