({
  //SFDC-3550
  doInit : function(component, event, helper) {
    helper.getIntermediatePageAccess(component, event, helper);
  },
  
  managePageRendering: function(component, event, helper) {
    component.set("v.currencyMismatch", event.getParam("currencyMismatch"));
    component.set("v.oldCurrency", event.getParam("oldCurrency"));
    component.set("v.previousAccountId", event.getParam("previousAccountId"));
    if (event.getParam("selectedContractIDs") != null) {
      component.set("v.selectedContractIDs", event.getParam("selectedContractIDs"));
    }
    else if(event.getParam("selectedContractIDs") == []){
      component.set("v.selectedContractIDs", []);
    }
      
    //SFDC-3550
    if(event.getParam("showWithoutContractBL")){
      component.set("v.opptyTypes",component.get("v.opptyTypeMap")["new opportunity without contract baseline"]);
    }
    else{
      component.set("v.opptyTypes",component.get("v.opptyTypeMap")["create opportunity with contract baseline"]);
    }
    component.set("v.selectedOppType", event.getParam("opptyType"));
    component.set("v.showHome", event.getParam("showHome"));
    component.set("v.showcheckFieldForWithContractBL", event.getParam("showcheckFieldForWithContractBL"));
    component.set("v.showcheckFieldForWithoutContractBL", event.getParam("showcheckFieldForWithoutContractBL"));
    component.set("v.showWithContractBL", event.getParam("showWithContractBL"));
    component.set("v.showWithoutContractBL", event.getParam("showWithoutContractBL"));
    component.set("v.showCreateOppty", event.getParam("showCreateOppty"));
    component.set("v.showCurrencySelection", event.getParam("showCurrencySelection"));
    component.set("v.showOpenOpportunitiesWithBL", event.getParam("showOpenOpportunitiesWithBL"));
    if (event.getParam("accountDetails") != '' || event.getParam("accountDetails") != null) {
      component.set("v.accountDetails", event.getParam("accountDetails"));
    }
  }
})