/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-23-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-23-2021   apyati   Initial Version
**/
({
    doInit: function (component) {

        console.log('doInit');

        let url = window.location.href;
        if (url.includes('RELATED_LIST_ROW')) {
            component.set("v.source", 'account');
        } else {
            component.set("v.source", 'plan');
        }
    },

    handleCancel: function (component) {

        // $A.get("e.force:closeQuickAction").fire();
        //$A.get('e.force:refreshView').fire();

        let recId, objName;
        if (component.get("v.source") === 'account') {
            recId = component.get("v.planRecord.Account__c");
            objName = "Account";
        }
        else {
            recId = component.get("v.recordId");
            objName = "Account_Plan__c";
        }

        let navService = component.find("navService");
        let pageReference;
        pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: objName,
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
    },

    handleSuccess: function (component) {
        //$A.get('e.force:refreshView').fire();
        let recId, objName;
        if (component.get("v.source") === 'account') {
            recId = component.get("v.planRecord.Account__c");
            objName = "Account";
            console.log('navigate to account' + recId);
        }
        else {
            console.log('navigate to plan');
            recId = component.get("v.recordId");
            objName = "Account_Plan__c";
        }

        let navService = component.find("navService");
        let pageReference;
        pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: objName,
                actionName: "view"
            }
        };
        navService.navigate(pageReference);
        $A.get('e.force:refreshView').fire();

    },

    handleSubmit: function (component, event) {

        component.set("v.showSpinner", true);
        event.preventDefault();
        let fields = event.getParam('fields');
        console.log('fields' + JSON.stringify(fields));
        component.find('myRecordForm').submit(fields);

    },

    destoryCmp: function (component) {
        component.destroy();
    },

    onPageReferenceChanged: function () {
        $A.get('e.force:refreshView').fire();
    },


})