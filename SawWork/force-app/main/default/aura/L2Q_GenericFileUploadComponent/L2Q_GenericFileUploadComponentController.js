({
    init: function (component, event, helper) {
        var fileDownloadUrl = '/partners/s/file-download-page?retUrl=' + component.get("v.recordId") + '&id=';
        component.set("v.fileDownloadUrl", fileDownloadUrl);
        var action = component.get("c.getShowComponentOnLayout");
        action.setParams({
            'recordId': component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var returnVal = response.getReturnValue();
                component.set("v.showComponentOnLayout", returnVal);
                if (returnVal) {
                    helper.uploadAttachmentsHelper(component);
                }
            } else {
                component.set("v.hasErrors", true);
                component.set("v.errorMessage", "An Internal Error Occurred. Please contact your system Administrator! (Error in state)")
            }
        });
        $A.enqueueAction(action);
    },
    handleUploadFinished: function (component, event, helper) {
        helper.uploadAttachmentsHelper(component);
    }
})