({
    changePassPhrase : function(component, event, helper) 
    {
        let recordId = component.get("v.recordId");
        var url = '/apex/SC_PassphraseRenewal?Id='+recordId;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url
        });
        urlEvent.fire();
    }
})