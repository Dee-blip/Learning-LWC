({
  doInit: function(component, event, helper) {
    // helper.getUiThemeDisplayed(component);
    var getUiThemeDisplayed = component.get("c.getUIThemeDescription");

    getUiThemeDisplayed.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        if (returnVal === 'Theme4t') {
          var evt = $A.get("e.force:navigateToComponent");
          evt.setParams({
            componentDef: "c:SF1_AccountReassignment",
            componentAttributes: {
              accountID: component.get("v.recordId")
            }
          });
          evt.fire();
        } else {
          //var url = '/one/one.app#/alohaRedirect/apex/AccountReassignment2?id=' + component.get("v.recordId");
          var url = '/apex/AccountReassignment2?id=' + component.get("v.recordId"); // SFDC-2408 changes by Nagaraj Desai
          //alert(url);

          var urlEvent = $A.get("e.force:navigateToURL");
          urlEvent.setParams({
            "url": url
          });
          urlEvent.fire();
        }
      }
    });
    $A.enqueueAction(getUiThemeDisplayed);

  },

})