({
  getInitialValues: function(component) {
    var getInitialVals = component.get("c.getInitialValues");
    getInitialVals.setParams({
      "sobjectName": "Account_Reassignment__c",
      "picklistFieldName": "Reason_Code__c",
      accountId: component.get("v.accountID")
    });
    getInitialVals.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        var initialVals = JSON.parse(returnVal);
        if (initialVals.pendingAccountReassignmentDetails != null) {
          var pendingAccountReassignmentDetails = JSON.parse(initialVals.pendingAccountReassignmentDetails);
          component.set("v.initialErrorFlag", true);
          component.set("v.returnMessage", pendingAccountReassignmentDetails.returnMessage);
          component.set("v.pendindReassignmentID", pendingAccountReassignmentDetails.accReassignId);
        } else {
          component.set("v.accountDetails", JSON.parse(initialVals.accountDetails));
          component.set("v.reasonCodeList", JSON.parse(initialVals.pickListValues));
          if (initialVals.isBusinessOpsUser == 'true') {
            component.set("v.renderReassign", true);
          } else {
            component.set("v.renderReassign", false);
          }
        }
        component.set("v.afterInitialQuery", true);
      }
    });
    $A.enqueueAction(getInitialVals);
  },

  reassignAccount: function(component, helper) {
    var reassignAcc = component.get("c.reassignAccount");
    reassignAcc.setParams({
      "accountId": component.get("v.accountID"),
      "assignTo": component.get("v.assignTo"),
      "reasonCode": component.get("v.reasonCode"),
      "reasonForChange": component.get("v.reasonForChange"),
      "reassignFlag": component.get("v.shouldReassign")
    });
    reassignAcc.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        var returnVal = JSON.parse(options);
        if (returnVal.errorOccured == 'true') {
          component.set("v.errorOccured", true);
        } else {
          component.set("v.errorOccured", false);
        }
        component.set("v.returnMessage", returnVal.returnMessage);
        if (returnVal.errorOccured == 'false') {
          // set new account details
          component.set("v.accountDetails", JSON.parse(returnVal.accountDetails));
          // navigate to account reassignment record details
          var navEvt = $A.get("e.force:navigateToSObject");
          navEvt.setParams({
            "recordId": returnVal.accReassignId,
            "slideDevName": "related"
          });
          navEvt.fire();
        } else {
          component.set("v.reasonCode", null);
        }
        component.set("v.showMessage", true);

        //component.set("v.reasonCodeList", JSON.parse());
      }
    });
    $A.enqueueAction(reassignAcc);
  },

})