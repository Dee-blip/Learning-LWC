({
  // Get open Opportunities from controller sorted by sortOrder
  sortOpportunities: function(component, event, sortField, sortOrder) {
    var accountId = component.get('v.accountDetails.Id');
    var contractIds = component.get('v.selectedContractIDs');
    var action = component.get('c.getOpportunitiesByContractIds');
    action.setParams({
      "accountId": accountId,
      "contractIds":contractIds,
      "sortField": sortField,
      "sortOrder":sortOrder
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      //console.log(state);
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        //console.log('results: ' + JSON.stringify(results) );
        component.set("v.opportunities", results.rows);
        if (results.rows == null || results.rows.length == 0) {
          component.set("v.noOpenOpportunities", true);
        }
        else {
          component.set("v.noOpenOpportunities", false);
        }
      }
    });

    $A.enqueueAction(action);
  },
  
  openModal: function(component, event, helper) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

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
        //console.log(options);
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

  scrollTop: function(component, event) {
    var elmnt = document.getElementById("scrollableDiv");
    elmnt.scrollLeft = 0;
    elmnt.scrollTop = 0;
  },

})