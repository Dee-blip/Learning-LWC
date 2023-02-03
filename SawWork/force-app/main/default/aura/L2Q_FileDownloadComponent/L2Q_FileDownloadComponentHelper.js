({
    deleteDuplicates: function (component, contentDocumentId) {
        var deleteContentDoc = component.get("c.deleteDuplicateContentDocument");
        deleteContentDoc.setParams({
            "contentDocumentId": contentDocumentId
        });
        deleteContentDoc.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                console.log(returnVal);
                var retUrl = component.get("v.retUrl");
                if (retUrl != undefined && retUrl != null && retUrl != '') {
                    window.location = '/partners/s/detail/' + retUrl;
                } else {
                    window.close();
                    window.history.go(-2);
                }
            }
        });
        $A.enqueueAction(deleteContentDoc);
    },

    closeCurrentWindow: function (component) {
        var retUrl = component.get("v.retUrl");
        if (retUrl != undefined && retUrl != null && retUrl != '') {
            window.location = '/partners/s/detail/' + retUrl;
        } else {
            window.close();
            window.history.go(-2);
        }
    }
})