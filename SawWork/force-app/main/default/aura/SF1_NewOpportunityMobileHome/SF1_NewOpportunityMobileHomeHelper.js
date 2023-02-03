({
  getAccountDetails: function(component) {
    var getAccount = component.get("c.getAccountDetails");
    getAccount.setParams({
      accountId: component.get("v.receivedAccountID")
    });
    getAccount.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.accountDetails", JSON.parse(returnVal));
      }
    });
    $A.enqueueAction(getAccount);
    component.set("v.receivedAccountID", "");
  }
})