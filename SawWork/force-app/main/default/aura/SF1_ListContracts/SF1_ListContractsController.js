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
    /*
     * doInit : function(component, event, helper) {
        helper.getContracts(component);
        },
    */
    handleRenderContracts: function (component, event, helper) {
        //helper.getContracts(component, event);
        helper.validateEvent(component, event);
    },

    updateSelectedContracts: function (component, event, helper) {
        console.log('updateSelectedContracts');
       helper.updateSelectedContractsHelper(component, event, helper);
    },


    
    updateCheckbox: function (component, event, helper) {
        helper.updateCheckboxhelper(component, event, helper);
    },
    /*
    updateAllCheckboxes: function (component, event, helper) {
        helper.updateAllCheckboxeshelper(component, event, helper);
    },
    */
    gotoRecord: function (component, event) {
        //console.log('gotoRec:' + event.target.id);
        //var monkeyLove = event.getSource().getElement().getAttribute('name');

        var navigateToId = event.target.id;
        var sObjectEvent = $A.get("e.force:navigateToSObject");
        console.log('sObjectEvent=' + sObjectEvent);
        sObjectEvent.setParams({
            "recordId": navigateToId,
            "slideDevName": 'detail'
        })
        sObjectEvent.fire();
    },
    pagerecords: function (cmp, event, helper) {
        if (cmp.isValid()) {
            cmp.set("v.page", event.getParam("pagevalue"));
            helper.queryRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, false));
            // helper.fireContractChangeEvent(null, null, null);
        }
    },
    customSort: function (cmp, event, helper) {
        let fieldAPIName;
        if (cmp.isValid()) {
            console.log('cmp-->' + JSON.stringify(cmp));
            fieldAPIName = event.getParam("fieldid");
            cmp.set("v.sortField", fieldAPIName);
            cmp.set("v.page", event.getParam("pagevalue"));
            helper.queryRows(cmp, cmp.get("v.page") || 0, helper.getSortOrder(cmp, true));

        }
    },
    openModal: function (component, event) {

        var contractId = event.target.name;
        var contractsMap = component.get("v.contractsMap");
        var contractRec = contractsMap[contractId];
        //alert('contractRow=' + JSON.stringify(contractRec.Contract_Products__r));

        $A.createComponent(
            "c:SF1_ViewProducts",
            // "c:productsViewModal",
            {
                // "aura:id": "findableAuraId",
                "products": contractRec.Contract_Products__r,
                "headerMsg": contractRec.Original_Contract_Id__c
            },
            function (msgBox) {
                let targetCmp, body;
                if (component.isValid()) {
                    targetCmp = component.find('ModalDialogPlaceholder');
                    body = targetCmp.get("v.body");
                    body.push(msgBox);
                    targetCmp.set("v.body", body);
                }
            }
        );
    },
    

})