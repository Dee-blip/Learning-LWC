({
    doInit : function(component, event, helper) {
        sforce.one.createRecord(
            component.get("v.sObjectName"),
            component.get("v.recordTypeId"),
            component.get("v.defaultFieldValues")
        );
    }
})