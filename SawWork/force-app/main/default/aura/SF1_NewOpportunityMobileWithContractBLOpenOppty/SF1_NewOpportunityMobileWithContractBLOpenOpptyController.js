({
  doInit: function(component, event, helper) {
    // Get open Opportunities from controller sorted by Name in Asc order
    //console.log("selectedContractIDs in Open " + component.get("v.selectedContractIDs"));
    helper.sortOpportunities(component, event, "Name", "ASC");
    // Fetch currency Picklist values
    console.log("oppty : init : " + component.get("v.currencyMismatch"));
    helper.fetchCurrencyIsoCode(component, event);
  },

  // Sort opportunities based on values recieved from SF1_NewOpportunityMobileSortEvent
  sortOpportunities: function(component, event, helper) {
    var sortBy = event.getParam("sortBy");
    var sortOrder = event.getParam("sortOrder");
    var orderBy = sortBy + " " + sortOrder;
    helper.sortOpportunities(component, event, sortBy, sortOrder);
    helper.scrollTop(component, event);
  },

  manageModalRendering: function(component, event, helper) {
      component.set("v.openModalOnClick", true);
      component.set("v.contractsToShow", event.getParam("itemsToShow"));
      helper.openModal(component, event, helper);
  },

  closeModal: function(component, event) {
    component.set("v.openModalOnClick", false);
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    component.set("v.openModalOnClick", false);
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

  // used to open currency modal
  openCurrencyModal: function(cmp, event) {
    var cmpTarget = cmp.find('CurrencyModalbox');
    var cmpBack = cmp.find('CurrencyModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

  // used to close currency modal
  closeCurrencyModal: function(cmp, event) {
    var cmpTarget = cmp.find('CurrencyModalbox');
    var cmpBack = cmp.find('CurrencyModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
  },

  // create new Opportunity
  openCurrencyComponent : function(component, event) {
    //console.log("here");
    console.log(component.get("v.currencyMismatch"));
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
      "showHome": false,
      "showWithContractBL": false,
      "showWithoutContractBL": false,
      "showOpenOpportunitiesWithBL" : false,
      "showCreateOppty": false,
      "showCurrencySelection": true,
      "accountDetails": component.get("v.accountDetails"),
      "selectedContractIDs": component.get("v.selectedContractIDs"),
      "currencyMismatch" : component.get("v.currencyMismatch"),
      "oldCurrency" : component.get("v.oldCurrency")
    });
		evt.fire();
  },

  // Back to SF1_NewOpportunityMobileWithContractBL component
  moveBack : function(component, event) {
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
      "showHome": false,
      "showWithContractBL": true,
      "showWithoutContractBL": false,
      "showOpenOpportunitiesWithBL" : false,
      "showCreateOppty": false,
      "selectedContractIDs": component.get("v.selectedContractIDs"),
      "accountDetails": component.get("v.accountDetails")
    });
    evt.fire();
  },
})