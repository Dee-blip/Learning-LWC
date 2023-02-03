({
    doInit: function (component, event, helper) {

        helper.getCurrentOpportunityAccountId(component, helper);
        //SFDC-6799-> //helper.getOpportunityList(component);

    },

    navigateToLocateAccountCmp: function (component, event, helper) {
        helper.navigateToLocateAccountCmp(component);
    },

    getOpportunityList: function (component, event, helper) {
        helper.getOpportunityList(component);
    },

    showSpinner: function (component, event, helper) {
        if (document.getElementById("oppSpinner") != null) {
            document.getElementById("oppSpinner").style.display = "block";
        }
    },

    hideSpinner: function (component, event, helper) {
        if (document.getElementById("oppSpinner") != null) {
            document.getElementById("oppSpinner").style.display = "none";
        }
    },

    create: function (component, event, helper) {
        helper.create(component);
    },

    getOrderByString: function (component, event, helper) {
        var eventValue_orderByString = event.getParam("orderByString");
        component.set("v.orderBy", eventValue_orderByString);

        var offsetDefault = "0";
        offsetDefault = parseInt(offsetDefault);
        component.set("v.offset", offsetDefault);  // resetting 1

        var listOfOpptysDefault = [];
        component.set("v.listOfOpptys", listOfOpptysDefault); // resetting 2

        //update the query at backend and fire it again

        helper.getOpportunityList(component);
    }

})