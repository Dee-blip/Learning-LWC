({
    handleClick: function (component, event, helper) {
        helper.showSpinner(component);
        var action = component.get('c.refreshAccountContractAccess');
        action.setParams({
               "genericRecordID" :component.get("v.recordId")
                });
        action.setCallback(this,function(response){
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                

            var results = response.getReturnValue();
            if (results == "Success") {
                var locationURL = '/' + component.get("v.recordId");
                var theme = null;
                            var action = component.get("c.getUIThemeDescription");
                            action.setCallback(this, function(a) {
                            if (component.isValid()){
                                theme = a.getReturnValue();
                                console.log('theme '+theme);

                                if(theme == "Theme4d")
                                {
                                    var urlEvent = $A.get("e.force:navigateToURL");
                                    urlEvent.setParams({
                                    "url": locationURL
                                    });
                                    urlEvent.fire();
                        
                                }

                                else
                                    window.parent.location = '/' + component.get("v.recordId"); 
                            } 
                            
                        
                        });
                    $A.enqueueAction(action);
                }
            else{

                component.set("v.failureMessage", 'There was some Error refreshing Contract Shares.Please try again.')

            }
                helper.hideSpinner(component);
            }
        });
        $A.enqueueAction(action);
    }
})