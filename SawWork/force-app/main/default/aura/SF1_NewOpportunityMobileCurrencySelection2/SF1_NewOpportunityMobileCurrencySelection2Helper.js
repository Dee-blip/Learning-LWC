({
  // fetch Picklist values for CurrencyIsoCode
  fetchCurrencyIsoCode: function(component, event) {
    var loadPicklistValues = component.get("c.loadPicklistValues");
    loadPicklistValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "CurrencyIsoCode"
    });
    loadPicklistValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.CurrencyIsoCode", JSON.parse(options));
      }
    });
    $A.enqueueAction(loadPicklistValues);

    //Set The Default CurrencyIsoCode
    var loadUserDefaultCurrency = component.get("c.getDefaultUserCurrency");
    loadUserDefaultCurrency.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.newCurrency", returnVal);
      }
    });
    $A.enqueueAction(loadUserDefaultCurrency);

  },
  // getOpportunityCurrencyValues: function(component, event) {
  //   var loadPicklistValues = component.get("c.getOpportunityCurrencyValues");
  //
  //   loadPicklistValues.setCallback(this, function(response) {
  //     var state = response.getState();
  //     var options = response.getReturnValue();
  //     if (component.isValid() && state === "SUCCESS") {
  //       component.set("v.oppty", options);
  //       console.log(options);
  //     }
  //   });
  //   $A.enqueueAction(loadPicklistValues);
  // },
})