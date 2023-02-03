({
  doInit: function(component, event, helper) {
    helper.getInitialValues(component);
  },

  moveBack: function(component) {
    window.history.back();
  },

  toggleShouldReassign: function(component) {
    component.set("v.shouldReassign", !component.get("v.shouldReassign"));
  },

  requestReassignment: function(component, event, helper) {
    component.set("v.showMessage", false);
    helper.reassignAccount(component, helper);
  },

  moveToAccount: function(component) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": component.get("v.accountID"),
      "slideDevName": "related"
    });
    navEvt.fire();
  },

  showPendingReassignment: function(component) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": component.get("v.pendindReassignmentID"),
      "slideDevName": "related"
    });
    navEvt.fire();
  },

})