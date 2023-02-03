({
  doInit: function(component, event, helper) {
    // get the open opportunities based sorted by Name in ASC order
    //console.log("accountDetails: " + component.get("v.accountDetails"));
    helper.sortOpportunities(component, event, "Name", "ASC");
  },
  //handle sorting based on values from sorting component
  sortOpportunities: function(component, event, helper) {
    var sortBy = event.getParam("sortBy");
		var sortOrder = event.getParam("sortOrder");
		//console.log("sortBy = " + orderBy);
    helper.sortOpportunities(component, event, sortBy, sortOrder);
    helper.scrollTop(component, event);
  },
  // skip to create new opportunity
  skipToCreate: function(component, event, helper) {
    //SFDC-3550
    var selectedOppType = component.get("v.selectedOppType");
    if(selectedOppType == '--None--' || selectedOppType == null || selectedOppType == ""){
        component.set("v.isTypeMissing",true);
        return;
    }
    component.set("v.isTypeMissing",false);
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
		evt.setParams({
      "showHome": false,
      "showCreateOppty": true,
      "showWithContractBL": false,
      "showWithoutContractBL": false,
      "showOpenOpportunitiesWithBL" : false,
      "accountDetails": component.get("v.accountDetails"),
      "opptyType":selectedOppType
		});
		evt.fire();
  },

  // move back to Home
  moveBack : function(component, event) {
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
      "showHome": true,
      "showcheckFieldForWithContractBL": false,
      "showcheckFieldForWithoutContractBL": true,
      "showCreateOppty": false,
      "showWithContractBL": false,
      "showWithoutContractBL": false,
      "showOpenOpportunitiesWithBL" : false,
      "accountDetails": component.get("v.accountDetails")
    });
    evt.fire();
  },
  setOpptyType : function(component, event, helper) {
    component.set("v.selectedOppType",event.getParam("opptyType"));
  }
})