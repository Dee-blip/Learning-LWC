({
    /**
     * handleRecordUpdated method is used to track when the record is loaded or changed
     * it calls validate method for LOADED changeType
     */
    handleRecordUpdated: function (component, event, helper) {
        var eventParams = event.getParams();
        if (eventParams.changeType === "LOADED") {
            helper.validate(component, event);
        } else if (eventParams.changeType === "CHANGED") {
            // record is changed
        } else if (eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if (eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }
    }
})