/**
 * @description       : 
 * @author            : apyati
 * @group             : GSM
 * @last modified on  : 08-23-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-05-2021   apyati   Initial Version
**/
({
    doInit: function (component, event, helper) {

        console.log('doInit');

        //Get Account Id from the url 
        let value = helper.getParameterByName(component, event, 'inContextOfRef');
        let context = JSON.parse(window.atob(value));
        let parentid = context.attributes.recordId;
        component.set("v.parentrecordId", parentid);
        console.log('parentId' + component.get("v.parentrecordId"));
        if (parentid) {
            let action = component.get("c.hasActivePlans");
            action.setParams({
                recordId: component.get("v.parentrecordId")
            });
            action.setCallback(this, function (response) {
                let state = response.getState();
                if (state === "SUCCESS") {
                    if (response.getReturnValue()) {
                        component.set("v.newPlanLayout", false);
                        component.set("v.alertMessage", response.getReturnValue());
                    } else {
                        component.set("v.newPlanLayout", true);
                    }
                } else {
                    let toastEvent = $A.get("e.force:showToast");
                    let errors = response.getError();

                    let errmessage = 'Unknown error';
                    if (errors && Array.isArray(errors) && errors.length > 0) {
                        errmessage = errors[0].message;
                    }
                    console.error(errmessage);
                    toastEvent.setParams({
                        Title: 'title',
                        type: 'error',
                        message: errmessage
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }

    },

    handleCancel: function (component) {

        // $A.get("e.force:closeQuickAction").fire();
        //$A.get('e.force:refreshView').fire();

        var navService = component.find("navService");
        var pageReference;
        pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: component.get("v.parentrecordId"),
                objectApiName: "Account",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);

        $A.get('e.force:refreshView').fire();


    },


    onPageReferenceChanged: function () {
        $A.get('e.force:refreshView').fire();
    },
     
    destoryCmp: function (component) {
        component.destroy();
    },

    handleNext: function (component) {
        component.set("v.showAlert", false);
        component.set("v.newPlanLayout", true);
    },

    handleSubmit: function (component, event) {
        component.set("v.showSpinner", true);
        event.preventDefault();
        let fields = event.getParam('fields');
        component.find('myRecordForm').submit(fields);
    },

    handleSuccess: function (component, event) {

        let payload = event.getParams().response;
        var cretedPlanID = payload.id;

        //$A.get("e.force:closeQuickAction").fire();
        //$A.get('e.force:refreshView').fire();

        let navService = component.find("navService");
        let pageReference;
        pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: cretedPlanID,
                objectApiName: "Account_Plan__c",
                actionName: "view"
            }
        };
        navService.navigate(pageReference);
        $A.get('e.force:refreshView').fire();

    },


    handleError: function (component, event) {
        component.set("v.showSpinner", false);
        let error = event.getParam("error");
        let errRecs = error.body.output.errors;
        let errMessage = 'Unknown error';
        if (errRecs && errRecs.length > 0) {
            errMessage = errRecs[0].message;
        }
        console.error(errMessage);
        component.find("notifLib").showToast({ "variant": "error", "title": "Unexpected Error Here", "message": errMessage });
    }

});