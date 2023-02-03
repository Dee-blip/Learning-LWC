({
  doInit: function(component, event, helper) {
    var getAccount = component.get("c.getAccountDetails");
    getAccount.setParams({
      accountId: component.get("v.recordId")
    });
    getAccount.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        //component.set("v.accountDetails", JSON.parse(returnVal));

        var urlEvent = $A.get("e.force:navigateToURL");
        var url = "/apex/OpportunityCreateNew?accid=" + component.get("v.recordId");
        console.log(url);
        urlEvent.setParams({
          "url": url
        });
        urlEvent.fire();

        // var evt = $A.get("e.force:navigateToComponent");
        // evt.setParams({
        //   componentDef: "c:SF1_NewOpportunityMobileHomeWrapper",
        //   componentAttributes: {
        //     accountDetails: JSON.parse(returnVal)
        //   }
        // });
        // evt.fire();
      }
    });
    $A.enqueueAction(getAccount);

  }
})