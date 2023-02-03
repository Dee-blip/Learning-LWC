({
    doInit : function(component, event, helper) {
        
        helper.doInit(component, event, helper);
    },

    handleCancel: function() {
        $A.get("e.force:closeQuickAction").fire();
    },

    handleDisable: function(component, event, helper) {
        helper.handleDisable(component, event, helper);
    },
})