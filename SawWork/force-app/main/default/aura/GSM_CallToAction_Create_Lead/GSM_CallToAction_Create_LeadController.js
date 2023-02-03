({
    doInit: function(component, event, helper) {
        component.set("v.showContactComponent",true);
    },
    checkLead : function(component, event, helper) { 
        helper.checkIfLeadExists(component);
    },
    redirectLead : function(component, event, helper) {
        helper.createActivtyAndRedirect(component);
    },
    setActivityValues : function(cmp, event) {
        // setting the activity values to be created. We are getting the details from the child component using event parameters
        var params = event.getParam('arguments');
        if (params) {
            cmp.set("v.productSelected", params.ProductLine);
            cmp.set("v.leadTypeSelected", params.LeadType);
            cmp.set("v.Notes", params.Notes);
        }
    },
    showSpinner: function(cmp, event, helper) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        
    },
    hideSpinner : function(cmp,event,helper){
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-show");
    }

})