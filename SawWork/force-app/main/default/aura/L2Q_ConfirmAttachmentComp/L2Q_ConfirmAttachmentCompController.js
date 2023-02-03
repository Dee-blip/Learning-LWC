({
    init: function (component, event, helper) {

        var getDataVar = component.get("c.getInitialDataMap");
        getDataVar.setParams({
            "contentVersionId": component.get("v.contentVersionId"),
            "themeDisplayed": component.get("v.themeDisplayed")
        });
        getDataVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                console.log(returnVal);
                component.set("v.afterInitialCallback", true);
                component.set("v.parameterMap", returnVal);
                if (returnVal["errorMessage"] != undefined && returnVal["errorMessage"] != null && returnVal["errorMessage"] != "") {
                    component.set("v.hasErrors", true);
                    component.set("v.errorMessage", returnVal["errorMessage"]);
                } else {
                    var acceptanceDocJS = JSON.parse(returnVal["acceptanceDoc"]);
                    component.set("v.acceptanceRecordId", acceptanceDocJS.Id);
                    console.log(acceptanceDocJS.Id);
                    component.set("v.acceptanceDoc", acceptanceDocJS);
                    component.set("v.orderFileName", returnVal["orderFileName"]);
                    component.set("v.fileDownloadURL", returnVal["fileDownloadURL"]);
                    if (returnVal["PORequired"] == "true") {
                        component.set("v.PORequired", true);
                        if (returnVal["POContentDocument"] != undefined && returnVal["POContentDocument"] != null && returnVal["POContentDocument"] != '') {
                            component.set("v.POContentDocument", JSON.parse(returnVal["POContentDocument"]));
                            component.set("v.POFileAttachedFlag", true);
                        }
                    } else {
                        component.set("v.PORequired", false);
                    }
                }
            } else {
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state) : " + helper.showErrors(response.getError()));
            }
        })
        $A.enqueueAction(getDataVar);
    },

    handleUploadFinished: function (component, event, helper) {
        helper.uploadAttachmentsHelper(component);
    },
    //SFDC-7692
    poaListViewJS: function () {
        window.parent.location = '/partners/s/recordlist/Partner_Order_Acceptance_Document__c/Default?Partner_Order_Acceptance_Document__c-filterId=00BG0000007Nr0LMAS';
    },

    rejectOrderForm: function (component, event, helper) {
        helper.closeModalHelper(component, event);
        component.set("v.acceptanceDoc.Order_Acceptance_Status__c", "Rejected");
        helper.processRequestHandler(component, event);
    },

    acceptOrderForm: function (component, event, helper) {
        component.set("v.acceptanceDoc.Order_Acceptance_Status__c", "Accepted");
        helper.processRequestHandler(component, event);
    },

    openModal: function (component, event, helper) {
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('ModalClose');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');
    },

    closeModal: function (component, event, helper) {
        helper.closeModalHelper(component, event);
    },

    backToOpportunity: function (component, event, helper) {
        window.location.href = '/partners/' + component.get("v.acceptanceDoc.Opportunity__c");
    },

    deletePOFile: function (component, event, helper) {
        var conDocId = component.get("v.POContentDocument.Id");
        if (conDocId != undefined && conDocId != null & conDocId != "") {
            console.log("uploadAttachmentsHelper");
            var action = component.get("c.deletePODocument");
            action.setParams({
                'contentDocumentId': conDocId
            });
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state == "SUCCESS") {
                    var returnVal = response.getReturnValue();
                    console.log(returnVal);
                    component.set("v.POContentDocument", null);
                    component.set("v.POFileAttachedFlag", false);
                } else {
                    component.set("v.PORequired", false);
                    component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state) : " + helper.showErrors(response.getError()));
                }
            });
            $A.enqueueAction(action);
        } else {
            alert("Upload a file to delete it");
        }
    },
    uploadPOFileJS: function (component, event, helper) {
        window.location.href = '/partners/apex/CFA_ConfirmAttachmentIntermediatePage?acceptanceRecordId=' + component.get("v.acceptanceRecordId") + '&contentVersionId=' + component.get("v.contentVersionId");
    },

    viewFileJS: function (component, event, helper) {
        var fileCV = component.get("v.POContentDocument.LatestPublishedVersionId");
        if (fileCV != undefined && fileCV != null & fileCV != "") {
            window.open(component.get("v.fileDownloadURL") + fileCV);
        } else {
            alert("Upload a file to view it");
        }
    }
})