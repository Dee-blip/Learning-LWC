({
    doInit: function (component, event, helper) {
        var currentCV = component.get("v.contentVersionId");
        if (currentCV == undefined || currentCV == null || currentCV == "") {
            var sPageURL = decodeURIComponent(window.location.search.substring(1));
            var sURLVariables = sPageURL.split('&');
            var sParameterName;
            var contentVersionId;
            var retUrl;
            for (var i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === 'id') {
                    contentVersionId = sParameterName[1];
                }
                if (sParameterName[0] === 'retUrl') {
                    retUrl = sParameterName[1];
                }
            }
            component.set("v.contentVersionId", contentVersionId);
            component.set("v.retUrl", retUrl);
        }
        console.log("contentVersionId : " + component.get("v.contentVersionId"));
        console.log("retUrl : " + component.get("v.retUrl"));
        var getDataVar = component.get("c.getDownloadURL");
        getDataVar.setParams({
            "contentVersionId": component.get("v.contentVersionId")
        });
        getDataVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (component.isValid() && state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                console.log(returnVal);
                if (returnVal["errorMessage"] == undefined || returnVal["errorMessage"] == null || returnVal["errorMessage"] == '') {
                    console.log(returnVal["fileDownloadUrl"]);
                    window.open(returnVal["fileDownloadUrl"]);
                    helper.closeCurrentWindow(component);// SFDC-7295
                }
                else {
                    component.set("v.errorMessage", returnVal["errorMessage"]);
                }
            }
        });
        $A.enqueueAction(getDataVar);
    },
})