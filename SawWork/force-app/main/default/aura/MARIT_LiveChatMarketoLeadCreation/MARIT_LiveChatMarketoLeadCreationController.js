({
    doInit: function (component, event, helper) {
    },
    CancelMarketoLeadCreation: function (component, event, helper) {
        var p = component.get("v.parent");
        p.CancelMarketoLead();
    },
    closeError : function(component, event, helper) {
        component.set("v.showError",false);
    },
    SaveNewMarketoLead: function (component, event, helper) {
        var validationObject = helper.validaterequiredFields(component);
        if (validationObject.val) {
            helper.ShowErrorMessage(component, validationObject.msg);
        } else {
            helper.saveAndLinkMarketoLeadHelper(component, event, helper);
        }
    }
})