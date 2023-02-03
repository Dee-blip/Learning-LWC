({
    doInit: function(component, event, helper) {
        helper.fetchC2ADropDownValuesHelper(component);
        helper.validUserCheckHelper(component);
        helper.SDRUserCheckHelper(component);
		helper.showCancelButtonBasedOnThemeHelper(component);
        component.set("v.enableButton", true);
    },
    checkAndCreateLead : function(component, event, helper) {
        component.set("v.enableButton", true);
        var p = component.get("v.parent");
        var productLine = component.get("v.productSelected");
        var leadTypeValue = component.get("v.leadTypeSelected");
        var note = component.get("v.Notes");
        p.SetActivityParameters(productLine, leadTypeValue, note);
        p.parentCheckLead();
    },
    goToContact: function(component, event, helper) {
        helper.goToLeadOrContactOnCancel(component);
    },
    setLeadExistsComponent: function(cmp, event, helper) {
        helper.hideSpinnerHelper(cmp);
    },
    createC2ALeadComponent: function(component, event, helper) {
        helper.createC2AHelper(component);
    },
    showSpinner: function(cmp, event, helper) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
    hideSpinner : function(cmp,event,helper){
        helper.hideSpinnerHelper(cmp);
    },
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-show");
    },
    toggleButton: function (component) {
        var productLine = component.get("v.productSelected");
        var leadType = component.get("v.leadTypeSelected");
        if(productLine !== "--none--" && leadType !== "--none--"){
            component.set("v.enableButton", false);
        } else{
            component.set("v.enableButton", true);
        }
    }
})