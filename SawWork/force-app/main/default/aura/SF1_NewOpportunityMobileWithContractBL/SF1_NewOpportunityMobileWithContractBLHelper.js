({
  // Get contracts from controller sorted by "sortField" in "sortOrder" order
  sortContracts: function(component, event, sortField, sortOrder) {
    var account = component.get('v.accountDetails');
    var action = component.get('c.getActiveContractsWithProductsByAcc');
    action.setParams({
      "accountJsonData": JSON.stringify(account),
      "sortField": sortField,
      "sortOrder": sortOrder
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var contractList = results.rows;
        component.set("v.contracts", contractList);

        if (contractList.length == 0) {
          component.set("v.noContracts", true);
        } else {
					component.set("v.noContracts", false);
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

  checkForCurrencyMismatch : function(component, event) {
    var contractList = component.get("v.contracts");

    var contractsMap = {};
    var setOfCurrencies = new Set();
    for (var i = 0; i < contractList.length; i++) {
        contractsMap[contractList[i].Id] = contractList[i];
    }
    var selectedContractIDs = component.get("v.selectedContractIDs");
    var initialCurrency = contractsMap[selectedContractIDs[0]].Currency__c;

    for (var i = 0; i < selectedContractIDs.length; i++) {
        if (contractsMap[selectedContractIDs[i]].Currency__c != initialCurrency) {
            return true;
        }
    }

    return false;
  },

  scrollTop: function(component, event) {
    var elmnt = document.getElementById("scrollableDiv");
    elmnt.scrollLeft = 0;
    elmnt.scrollTop = 0;
  },

  checkForSelectedContracts : function(component, event) {
    var allSelectedContracts = component.get("v.selectedContractIDs");
    if(allSelectedContracts.length > 0) {
      component.set("v.noSelectedContracts", false);
    }
    else {
      component.set("v.noSelectedContracts", true);
    }
  },

})