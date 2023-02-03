/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-18-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-19-2021   apyati   Initial Version
**/
({

    isEmpty: function (val) {
        return (val ? false : true);
    },

    isOwnerCreated: function (component) {

        var ownerID = component.get("v.newOppty.OwnerId");
        var createdById = component.get("v.newOppty.CreatedById");
        console.log('inside isOwnerCreated... ownerID:' + ownerID + '; createdById:' + createdById);
        if (ownerID === createdById) {
            return true;
        }
            return false;

    },

    withoutBaselineCheck: function (component, event) {
        var withoutBaselineType, contractChange, acc, opptyBaslinePicked;
        acc = event.getParam("acc");
        opptyBaslinePicked = event.getParam("selection");
        console.log('selected' + opptyBaslinePicked);
        if (opptyBaslinePicked != null)
            component.set("v.opptyTypes", component.get("v.opptyTypeMap")[opptyBaslinePicked.toLowerCase()]); //SFDC-3550
        //var withBaseLineType = "Create Opportunity with Contract Baseline";
        withoutBaselineType = "New Opportunity without Contract Baseline";
        contractChange = "Create Contract Change Opportunity";
        component.set("v.acc", acc);
        //console.log('equals to opptyBaslineType? :' + opptyBaslineType  + '; withBaseLineType: ' withBaseLineType);
        if (!this.isEmpty(acc) && !this.isEmpty(opptyBaslinePicked) && (opptyBaslinePicked.toUpperCase() === withoutBaselineType.toUpperCase())) {
            console.log('OpptyFlowHelper.withoutBaselineCheck qualifies');
            component.set("v.withoutBaseLine", true);
        }
        else {
            console.log('OpptyFlowHelper.withoutBaselineCheck does NOT qualifies');
            component.set("v.withoutBaseLine", false);
            // @todo:  Fire the even tot fold the Oppty List from HERE...
            //this.fireContractChangeEvent(null, null);
        }

        if (!this.isEmpty(opptyBaslinePicked) && (opptyBaslinePicked.toUpperCase() === contractChange.toUpperCase())) {
            component.set("v.contractChange", true);
            component.set("v.showContracts", false);
        }
        else {
            component.set("v.contractChange", false);
        }

        //console.log('opptyBaslinePicked:' + opptyBaslinePicked + '; acc:' + acc);

        // if (opptyBaslineType == )
        // var action = component.get("c.getContractsByAccID");
        // action.setParams({acc:acc});
        // component.set("v.acc", acc);
        // selection

    },

    //SFDC-3903
    getParameterByName: function (component, event, name) {
        var url, regex, results;
        name = name.replace(/[[]]/g, "\\$&");
        url = window.location.href;
        regex = new RegExp("[?&]" + name + "(=1.([^&#]*)|&|#|$)");
        results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },


    //SFDC-3550
    getOpptyTypes: function (component) {
        var state, action;
        action = component.get("c.getOpptyTypesBasedOnContractBaseline");
        action.setCallback(this, function (response) {
            state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if (response.getReturnValue() != null)
                    component.set("v.opptyTypeMap", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getIntermediatePageAccess: function (component, event, helper) {
        var action, amgCloseDate, evt, res;
        action = component.get("c.skipIntermediatePageForOpptyCreation");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                res = response.getReturnValue();
                if (res != null && res.skipIntermediatePage === true) {
                    amgCloseDate = new Date();
                    amgCloseDate.setDate(amgCloseDate.getDate() + res.amgCloseDateDays);
                    evt = $A.get("e.force:createRecord");
                    evt.setParams({
                        'entityApiName': 'Opportunity',
                        "defaultFieldValues": {
                            'StageName': '2. Explore Options',
                            'Deal_Type__c': 'Direct',
                            'CloseDate': amgCloseDate.toISOString()
                        }
                    });
                    evt.fire();
                } else {
                    helper.getOpptyTypes(component, event, helper); //SFDC-3550
                    component.set("v.showIntermediatePage", true);
                }
            }
        });
        $A.enqueueAction(action);
    },

    createOpptyRec: function (component, event, helper) {
        //var recordsPresent = component.get("v.noRecordsPresent");
        var selectedCurrency = component.get("v.otherCurrency");
        var selectedContractProducts = component.get("v.selectedContractProducts");

        var selectedOptyType = component.get("v.selectedOppType")
        var opptyId, action, errors, msg;

        console.log('createOpptyRec currency' + selectedCurrency);
        console.log('createOpptyRec type' + selectedOptyType);
        console.log('createOpptyRec' + JSON.stringify(selectedContractProducts));

        //component.find("createRenewalOppty").set("v.disabled", true);  No need to disable the button.  

        action = component.get("c.createRenewalOpportunityWithProducts");
        action.setParams({
            selectedContractIds: selectedContractProducts,
            selectedCurrency: selectedCurrency,
            selectedOpptyType: selectedOptyType
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            console.log("state:" + state);

            if (component.isValid() && state === "SUCCESS") {
                console.log("NEWOPPTY=" + JSON.stringify(response.getReturnValue()));
                component.set("v.newOppty", response.getReturnValue());
                this.showToast(component, event, helper);
                //component.find("createOppty").set("v.disabled", false);
                opptyId = component.get("v.newOppty.Id");

                /* We are commenting this out because force:recordedit is broken 
                if (this.isOwnerCreated(component)) {
                    console.log("isOWNERCREATED REC...");
                    //this.editRecord(opptyId);
                    this.gotoRecord(opptyId,"Detail"); 
                    
                } else {
                    console.log("NOT OWNER CREATED REC...");
                    
                    this.gotoRecord(opptyId, "Detail");
                    //this.editRecord(opptyId); 
                }*/

                this.gotoRecord(opptyId, "Detail");

                console.log("AT THE END... ");
            }
            else if (state === "ERROR") {

                console.log('error' + JSON.stringify(response.getError()));

                errors = response.getError();
                msg = '';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        msg = errors[0].message;
                    }
                } else {
                    console.log("Unknown error");
                    msg = "Unknown error";
                }
                this.showError(msg);
            } else {
                console.log("Action State returned was: " + state);
            }
        });
        $A.enqueueAction(action);

    },

    gotoRecord: function (recId, slideDevName) {//component,event, slideDevName){ // slideDevName=> detail, related,
        //console.log('gotoRec:' + event.target.id);
        //var monkeyLove = event.getSource().getElement().getAttribute('name');

        //var navigateToId = component.get("v.newOppty.Id");
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        console.log('sObjectEvent=' + sObjectEvent);
        sObjectEvent.setParams({
            "recordId": recId, //navigateToId,
            "slideDevName": slideDevName
        });
        sObjectEvent.fire();

    },

    editRecord: function (recId) {
        var newEvent = $A.get("e.force:navigateToComponent");
        newEvent.setParams({
            componentDef: "c:SF1_OpptyEdit",
            componentAttributes: {
                "recordId": recId
            }
        });
        newEvent.fire();

    },

    showToast: function () { // msg

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully."
        });
        toastEvent.fire();

    },

    //SFDC-3550
    showError: function (msg) {
        var toastEvent;
        console.log('showerror called');
        toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type": "error",
            "message": msg
        });
        toastEvent.fire();
    },

    fireRecordCreateEvent: function () { //SF1_RedirectToRecord recordCreated
        var appEvent = $A.get("e.c:SF1_RedirectToRecord");
        appEvent.setParams({ "recordCreated": true });
        appEvent.fire();
    },

})