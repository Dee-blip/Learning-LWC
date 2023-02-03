({
    redirectToFlow: function (component, event, helper) {
        var lookupFieldValue = component.get("v.lookupFieldValue");
        var redirectionUrl = component.get("v.redirectionUrl");
        if (lookupFieldValue != null && lookupFieldValue != '') {
            redirectionUrl += lookupFieldValue
        }
        window.location = redirectionUrl;
    },
    moveBack: function (component, event, helper) {
        window.history.back();
    }
})