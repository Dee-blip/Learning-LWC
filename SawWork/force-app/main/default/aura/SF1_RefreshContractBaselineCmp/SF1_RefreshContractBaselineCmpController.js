({
  doInit: function(component, event, helper) {

    var refreshBL = component.get("c.executeRefreshBaselineSF1");

    refreshBL.setParams({
      "opportunityID": component.get("v.opportunityID")
    });

    refreshBL.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      returnVal = JSON.parse(returnVal);
      if (component.isValid() && state === "SUCCESS") {
        if (returnVal.errorOccured == false) {
          component.set("v.title", "Alert!");
          component.set("v.severity", "warning");
        } else {
          component.set("v.title", "Error!");
          component.set("v.severity", "error");
        }
        component.set("v.isRefreshable", !returnVal.errorOccured);
        component.set("v.initialMessage", returnVal.returnMessage);
      }
    });
    $A.enqueueAction(refreshBL);

  },

  moveBack: function(component, event, helper) {
    sforce.one.back();
  },
  refreshContractBL: function(component, event, helper) {

    var refreshBL = component.get("c.refreshBaselineSF1");

    refreshBL.setParams({
      "contractID": component.get("v.contractID"),
      "opportunityID": component.get("v.opportunityID")
    });

    refreshBL.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      returnVal = JSON.parse(returnVal);
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.isRendered", true);
        component.set("v.returnMessage", returnVal.returnMessage);
        if (returnVal.errorOccured) {
          component.set("v.errorOccured", true);
        } else {
          component.set("v.successful", true);
        }
      }
    });
    $A.enqueueAction(refreshBL);

  },
  dontRefreshContractBL: function(component, event, helper) {

  }
})