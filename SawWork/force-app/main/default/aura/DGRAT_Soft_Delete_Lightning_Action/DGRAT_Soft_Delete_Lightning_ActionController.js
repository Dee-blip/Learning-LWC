({
    doInit: function(component, event, helper){
        console.log('Hello');
        helper.isDeletedHelper(component, event);
    },
    softdelete : function(component, event, helper) {
        helper.toggleDeleteHelper(component, event);
    },
    cancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})