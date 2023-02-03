({
  doInit: function(component, event, helper) {
    console.log('OverRide');
    var overRide = component.get("c.overrideCutOffSF1");
    overRide.setParams({
      accountReassignmentID: component.get("v.recordId")
    });
    overRide.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      console.log(state);
      if (component.isValid() && state === "SUCCESS") {
          console.log(JSON.parse(returnVal));
          var returnObj = JSON.parse(returnVal);
          component.set("v.returnMessage", returnObj.returnMessage);
          component.set("v.errorOccured", returnObj.errorOccured);
          if(returnObj.errorOccured == 'false') {
            component.set("v.successful", true);
          }
      }
    });
    $A.enqueueAction(overRide);
  },

  back: function(component, event, helper) {
    sforce.one.back();
  },
})