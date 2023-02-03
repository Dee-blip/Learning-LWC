({
    initialize: function (component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({ "qsToEvent": helper.qsToEventMap }).fire();
        $A.get("e.siteforce:registerQueryEventMap").setParams({ "qsToEvent": helper.qsToEventMap2 }).fire();
        component.set('v.extraFields', helper.getExtraFields(component, event, helper));
        helper.getCountryList(component);
    },

      handleChecked : function(component){
        var isChecked = component.get("v.usePolicy");
        var label = $A.get("$Label.c.Hello_Akamai_Policy_Label");
        if(isChecked){
            component.set("v.usePolicy",false);
            component.set("v.registerMessage","");
        }else{
            component.set("v.usePolicy",true);
            component.set("v.registerMessage",'You need to select '+label+' to Register');
        }
        
    },
    handleSelfRegister: function (component, event, helper) {
        helper.handleSelfRegister(component, event, helper);
    },

    cancelSelfRegister: function (component, event, helper) {
        helper.cancelSelfRegisterHelper(component, event, helper);
    },

    setStartUrl: function (component, event) {
        var startUrl = event.getParam('startURL');
        if (startUrl) {
            component.set("v.startUrl", startUrl);
        }
    },

    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },

    onKeyUp: function (component, event, helper) {
        //checks for "enter" key
        if (event.getParam('keyCode') === 13) {
            helper.handleSelfRegister(component, event, helper);
        }
    },

    closeModel: function (component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        helper.closeModel(component, event, helper);
    },
    /*
    onChangeCountry: function (component, event, helper) {
        var countryval = event.getSource().get("v.value");
        if (countryval == 'USA' || countryval == 'Canada') {
            component.set("v.showState", false);
        } else {
            component.set("v.showState", true);
        }
    },*/
})