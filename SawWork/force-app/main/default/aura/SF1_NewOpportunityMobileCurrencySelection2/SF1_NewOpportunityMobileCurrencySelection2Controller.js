({

  doInit: function(component, event, helper) {
    // Fetch currency Picklist values
    if (component.get("v.currencyMismatch") == true) {
      component.set("v.withoutContractCurrency", true);
    }
    helper.fetchCurrencyIsoCode(component, event);
    // helper.getOpportunityCurrencyValues(component, event);
  },

  moveBack: function(component, event) {
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
      "showHome": false,
      "showWithContractBL": false,
      "showWithoutContractBL": false,
      "showOpenOpportunitiesWithBL": true,
      "selectedContractIDs": component.get("v.selectedContractIDs"),
      "showCreateOppty": false,
      "currencyMismatch" : component.get("v.currencyMismatch"),
      "accountDetails": component.get("v.accountDetails"),
      "oldCurrency" : component.get("v.oldCurrency")
    });
    evt.fire();
  },

  skipToCreate: function(component, event, helper) {
    //SFDC-3550
    var selectedOppType = component.get("v.selectedOppType");
    if(selectedOppType == '--None--' || selectedOppType == null || selectedOppType == ""){
        component.set("v.isTypeMissing",true);
        return;
    }
    component.set("v.isTypeMissing",false);
    var action = component.get("c.createRenewalOpportunityFromContracts");
    var selectedContractIds = component.get("v.selectedContractIDs");
    var selectedCurrency;
    if(component.get("v.withContractCurrency")) {
      selectedCurrency = component.get("v.oldCurrency");
    }
    else {
      selectedCurrency = component.get("v.newCurrency");
    }
    action.setParams({
      "selectedContractIds": selectedContractIds,
      "selectedCurrency": selectedCurrency,
      "isContractCurrencyMismatch": true,
      "selectedOpptyType": selectedOppType
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      var result = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        if (result != null && result.Id != null) {
          sforce.one.navigateToSObject(result.Id, "detail");
        }
      }
    });
    $A.enqueueAction(action);
  },

  // used to toggle between withContractCurrency
  toggleWithContractCurrency: function(component, event) {
    var withContractCurrency = component.get("v.withContractCurrency");
    var withoutContractCurrency = component.get("v.withoutContractCurrency");
    if (withoutContractCurrency == true) {
      component.set("v.withoutContractCurrency", false);
    }
    component.set("v.withContractCurrency", !withContractCurrency);
  },

  // used to toggle between withoutContractCurrency
  toggleWithoutContractCurrency: function(component, event) {
    var withContractCurrency = component.get("v.withContractCurrency");
    var withoutContractCurrency = component.get("v.withoutContractCurrency");
    if (withContractCurrency == true) {
      component.set("v.withContractCurrency", false);
    }
    component.set("v.withoutContractCurrency", !withoutContractCurrency);
  },
  setOpptyType : function(component, event, helper) {
    component.set("v.selectedOppType",event.getParam("opptyType"));
  }
})