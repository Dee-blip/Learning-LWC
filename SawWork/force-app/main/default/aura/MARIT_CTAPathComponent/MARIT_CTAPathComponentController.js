({
    doInit: function (component, event, helper) {
        helper.initHelper(component, event, helper);
    },
    onrender: function (component, event, helper) {
        helper.onRenderhelper(component, event, helper);
    },
    handleSelect : function (component, event, helper) {
        helper.handleSelecthelper(component, event, helper);
    },
    refreshView: function(component, event, helper) {
        // refresh the view
        $A.get('e.force:refreshView').fire();
    },
    handleValueChange : function (component, event, helper) {
        component.set("v.oldStatusValue", event.getParam("oldValue"));
    }
})