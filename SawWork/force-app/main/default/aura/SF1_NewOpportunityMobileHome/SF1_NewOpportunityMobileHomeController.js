({
  doInit: function(component, event, helper) {
    // create SF1_LookupComponent component
    console.log("receivedAccountID " + component.get("v.receivedAccountID"));
    if(component.get("v.receivedAccountID") != "") {
      helper.getAccountDetails(component);
    }
    $A.createComponent("c:SF1_LookupComponent", {
      "aura:id": "field",
      "placeholderText": "Account",
      "type": "Account",
      "valueSObject": component.getReference("v.accountDetails"),
      "fieldsToShowInSuggestion": "createddate,Owner.Name,Account_Status__c"
    }, function(newCmp) {
      if (component.isValid()) {
        component.set("v.body", newCmp);
      }
    });
  },
  //JS function called when WithoutContractBL toggle is selected/de-selected
  toggleWithoutContractBL: function(component, event) {
    var withoutContractBL = component.get("v.withoutContractBL");
    var withContractBL = component.get("v.withContractBL");
    if (withContractBL == true) {
      component.set("v.withContractBL", false);
    }
    component.set("v.withoutContractBL", !withoutContractBL);
  },
  //JS function called when WithContractBL toggle is selected/de-selected
  toggleWithContractBL: function(component, event) {
    var withContractBL = component.get("v.withContractBL");
    var withoutContractBL = component.get("v.withoutContractBL");
    if (withoutContractBL == true) {
      component.set("v.withoutContractBL", false);
    }
    component.set("v.withContractBL", !withContractBL);
  },
  // navigate to showWithoutContractBL component
  nextPage: function(component, event) {
    //following commented function is used to navigate using navigateToComponent function while not using lightning
    // var evt = $A.get("e.force:navigateToComponent");
    // evt.setParams({
    //   componentDef: "c:SF1_NewOpportunityMobileWithoutContractBL",
    //   componentAttributes: {
    //     accountDetails: component.get("v.accountDetails")
    //   }
    // });
    // evt.fire();
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    var selectedContractIDs;
    if (component.get("v.withContractBL") && (component.get("v.accountDetails.Id") == component.get("v.previousAccountId"))) {
      selectedContractIDs = component.get("v.selectedContractIDs");
    } else {
      selectedContractIDs = [];
    }
    console.log("selectedContractIDs :" + selectedContractIDs);

    evt.setParams({
      "showHome": false,
      "showCreateOppty": false,
      "showOpenOpportunitiesWithBL": false,
      "accountDetails": component.get("v.accountDetails"),
      "showWithContractBL": component.get("v.withContractBL"),
      "selectedContractIDs": selectedContractIDs,
      "showWithoutContractBL": component.get("v.withoutContractBL")
    });


    evt.fire();
  },
  // delete the dynmically created SF1_LookupComponent and re-create it
  removeAccountDetails: function(component, event) {
    component.set("v.accountDetails", null);
    component.set("v.withContractBL", false);
    component.set("v.withoutContractBL", false);
    $A.createComponent("c:SF1_LookupComponent", {
      "aura:id": "field",
      "placeholderText": "Account",
      "type": "Account",
      "valueSObject": component.getReference("v.accountDetails"),
      "fieldsToShowInSuggestion": "createddate,Owner.Name,Account_Status__c"
    }, function(newCmp) {
      if (component.isValid()) {
        component.set("v.body", newCmp);
      }
    });
  },
  // display account details
  displayRecord: function(component, event, helper) {
    var accId = component.get("v.accountDetails.Id");
    // var navEvt = $A.get("e.force:navigateToSObject");
    // navEvt.setParams({
    //   "recordId": accId,
    //   "slideDevName": "detail"
    // });
    // navEvt.fire();
    sforce.one.navigateToSObject(accId, "detail");
    /* var editRecordEvent = $A.get("e.force:editRecord");
    editRecordEvent.setParams({
      "recordId": accId
    });
    editRecordEvent.fire(); */

  }
})