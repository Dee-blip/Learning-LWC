({
  doInit: function(component, event, helper) {
    var getUiThemeDisplayed = component.get("c.getUIThemeDescription");

    getUiThemeDisplayed.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        if (returnVal === 'Theme4t') {
          var evt = $A.get("e.force:navigateToComponent");
          evt.setParams({
            componentDef: "c:SF1_SendForOrderAcceptance",
            //componentDef: "c:SF1_TestScrollableDiv",
            componentAttributes: {
              orderApprovalId: component.get("v.recordId")
            }
          });
          evt.fire();
        } else {

          var urlEvent = $A.get("e.force:navigateToURL");
          urlEvent.setParams({
            //"url": "/one/one.app#/alohaRedirect/apex/CFA_SendEmail?id=" + component.get("v.recordId")
            "url": "/apex/CFA_SendEmail?id=" + component.get("v.recordId") // SFDC-2408 changes by Nagaraj Desai
          });
          urlEvent.fire();

        }
      }
    });
    $A.enqueueAction(getUiThemeDisplayed);
  },

})