/**
 * @description       : This component overrides new action on Chime_Contact object
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 02-24-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-14-2021   apyati   Created for SFDC-8655 
 * 2.0   24-02-2022   apyati    Added onChimeAccessChange for SFDC-9409

**/

({

    doInit: function (component, event, helper) {

        // Get the parameter from the page url
        var pageReference = component.get("v.pageReference");
        if (pageReference && pageReference.state && pageReference.state.c__chime) {
            component.set("v.chimeId", pageReference.state.c__chime);
        }
        if (pageReference && pageReference.state && pageReference.state.c__chime) {
            component.set("v.contactId", pageReference.state.c__contact);
        }

    },

    handleSubmit: function (component, event, helper) {
        component.set("v.showSpinner", true);
        event.preventDefault();      // stop the form from submitting
        const fields = event.getParam('fields');
        fields.CHIME__c = component.get("v.chimeId");
        fields.Contact__c = component.get("v.contactId");
        component.find('myRecordForm').submit(fields);
    },

    handleSuccess: function (component, event, helper) {
        component.set("v.showSpinner", false);
        $A.get('e.force:refreshView').fire();

        //redirect to CHIME form with url partmeter
        var navService = component.find("navService");
        var pageReference;
        pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: component.get("v.chimeId"),
                objectApiName: "CHIME__c",
                actionName: "view"
            },
            state: {
                c__fromContact: true
            }
        };
        navService.navigate(pageReference);

    },

    handleError: function (component, event, helper) {
        component.set("v.showSpinner", false);
    },

    onPageReferenceChanged: function () {
        $A.get('e.force:refreshView').fire();
    },

    destoryCmp: function (component) {
        component.destroy();
    },

    onChimeAccessChange: function (component, event) {
        console.log('onChimeAccessChange called');
        var target = event.getSource();
        let chimeaccess = target.get("v.value");
        if (chimeaccess) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "",
                "message": "Checking this Chime Access box will give this customer contact access to this CHIME form in the Akamai Community",
                "type": "warning"
            });
            toastEvent.fire();
        }
    }


})