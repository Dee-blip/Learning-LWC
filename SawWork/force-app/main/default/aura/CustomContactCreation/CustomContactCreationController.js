({
    doInit: function (component, event, helper) {
        helper.getContactRecordType(component);
        helper.setAccountIDIfPresent(component, event, helper);
        helper.checkProfileForFirstName(component);//MARIT-1201
    },
    handlePageChange : function(component, event, helper) {
        helper.getContactRecordType(component);
        helper.setAccountIDIfPresent(component, event, helper);
    },
    SaveNewContact: function (component, event, helper) {
        var validationObject = helper.validaterequiredFields(component);
        if (validationObject.val) {
            helper.ShowErrorMessage(component, validationObject.msg);
        } else {
            helper.getIgnoreAndCreateButtonProfiles(component);
            helper.saveNewContactAfterValidation(component);
        }
    },

    NavigateToExistingContact: function (component, event, helper) {
        helper.navigateToObject(component, '');
    },

    NavigateToExistingLead: function (component, event, helper) {
        helper.navigateToObject(component, '');
    },

    GoBack: function (component, event, helper) {
        component.set("v.displayContactExistsButtons", false);
        component.set("v.displayForm", true);
        component.set("v.displayStandardButtons", true);
    },

    ConvertLeadToContact: function (component, event, helper) {
        helper.ConvertL2C(component);
    },

    IngnoreandCreate: function (component, event, helper) {
        helper.IgnoreAndCreateContact(component);
    },
    CancelContactCreation: function (component, event, helper) {
        helper.navigateToObject(component, '003');
        component.set("v.displayForm", true);
        component.set("v.displayStandardButtons", true);
        component.set("v.displayContactExistsButtons", false);
        // Refresh the view on cancel
        $A.get('e.force:refreshView').fire();
    }
})