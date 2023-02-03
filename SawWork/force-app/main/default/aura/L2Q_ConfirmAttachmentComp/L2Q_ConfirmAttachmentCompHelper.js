({
    processRequestHandler: function (component, event) {
        var elmnt = document.getElementById("scrollableDiv");
        elmnt.scrollLeft = 0;
        elmnt.scrollTop = 0;
        component.set("v.isSuccessAfterAction", false);
        component.set("v.hasErrorsAfterAction", false);
        console.log('Inside processRequestHandler');
        var processRequestHandlerVar = component.get("c.processPartnerOrderAcceptance");
        console.log('Inside processRequestHandler');
        var parameterMapJS = component.get("v.parameterMap");
        console.log(parameterMapJS);
        parameterMapJS["acceptanceDoc"] = JSON.stringify(component.get("v.acceptanceDoc"));
        if (component.get("v.PORequired") && component.get("v.acceptanceDoc.Order_Acceptance_Status__c") == "Accepted") {
            var POContentDocument = component.get("v.POContentDocument");
            if (POContentDocument != undefined && POContentDocument != null && POContentDocument != '' && POContentDocument != []) {
                parameterMapJS["POContentDocument"] = JSON.stringify(POContentDocument);
            } else {
                parameterMapJS["POContentDocument"] = null;
            }
        }
        console.log(parameterMapJS);
        processRequestHandlerVar.setParams({
            "parameterMap": parameterMapJS
        });
        processRequestHandlerVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                if (returnVal["successMessage"] != undefined && returnVal["successMessage"] != null && returnVal["successMessage"] != '') {
                    component.set("v.successMessage", returnVal["successMessage"]);
                    component.set("v.isSuccessAfterAction", true);
                } else {
                    component.set("v.hasErrorsAfterAction", true);
                    if (returnVal["errorMessage"] != undefined && returnVal["errorMessage"] != null && returnVal["errorMessage"] != '') {
                        component.set("v.errorMessage", returnVal["errorMessage"]);
                    } else {
                        component.set("v.errorMessage", 'An unexpeced error has occurred. Please contact your System Administrator');
                    }
                }
                console.log(returnVal);
            } else {
                component.set("v.hasErrors", true);
                //SFDC-8077 @nadesai
                component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state) : " + this.showErrors(response.getError()));
            }
        })
        $A.enqueueAction(processRequestHandlerVar);
    },

    //SFDC-8077 @nadesai
    showErrors: function (errorList) {
        var returnMessage = '';
        if (errorList) {
            errorList.forEach(function (ithError) {
                returnMessage += ithError.message;
            });
        }
        return returnMessage;
    },

    closeModalHelper: function (component, event) {
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('ModalClose');
        $A.util.removeClass(cmpBack, 'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    },

    uploadAttachmentsHelper: function (component) {
        console.log("uploadAttachmentsHelper");
        var action = component.get("c.getPODocuments");
        action.setParams({
            'acceptanceRecordId': component.get("v.acceptanceRecordId"),
            'contentVersionId': component.get("v.contentVersionId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                console.log(response.getReturnValue());
                component.set("v.POContentDocument", response.getReturnValue());
            } else {
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state) : " + this.showErrors(response.getError()));
            }
        });
        $A.enqueueAction(action);
    }
})