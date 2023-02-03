({
	doInit: function(component, event, helper) {
		// Get contracts from controller sorted by Effective_End_Date__c in Asc order
		helper.sortContracts(component, event, "Effective_End_Date__c", "ASC");
    helper.checkForSelectedContracts(component, event);
	},

	// modify selectedContractIDs based on values recieved from SF1_NewOpportunityMobileContractEvent event
	populateSelectedContracts: function(component, event, helper) {
    var allSelectedContracts = component.get("v.selectedContractIDs");
		var setOfContractIDs = new Set(allSelectedContracts);
    var isPushContract = event.getParam("isPushContract");
    var selectedContractId = event.getParam("selectedContractId");

    if(isPushContract && !setOfContractIDs.has(selectedContractId)) {
      allSelectedContracts.push(selectedContractId);
    }
    else if(!isPushContract) {
      var index = allSelectedContracts.indexOf(selectedContractId);
      allSelectedContracts.splice(index, 1);
    }

    helper.checkForSelectedContracts(component, event);
    component.set("v.selectedContractIDs", allSelectedContracts);
	},

	manageModalRendering: function(component, event, helper) {
			component.set("v.openModalOnClick", true);
			component.set("v.productsToShow", event.getParam("itemsToShow"));
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

	// Sort contracts based on values recieved from SF1_NewOpportunityMobileSortEvent
	sortContracts: function(component, event, helper) {
		var sortBy = event.getParam("sortBy");
		var sortOrder = event.getParam("sortOrder");
    helper.sortContracts(component, event, sortBy, sortOrder);
		helper.scrollTop(component, event);
	},

	// fire SF1_NewOpportunityMobileUtilEvent to show Home
	moveBack : function(component, event) {
    //console.log('Back');
    console.log(component.get("v.selectedContractIDs"));
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
        "showHome" : true,
				"showcheckFieldForWithContractBL": true,
				"showcheckFieldForWithoutContractBL": false,
        "showAccountResults" : false,
        "showWithoutContractBL" : false,
				"showWithContractBL" : false,
        "showCreateOppty" : false,
        "selectedContractIDs" : component.get("v.selectedContractIDs"),
        "accountDetails" : component.get("v.accountDetails"),
				"previousAccountId" : component.get("v.accountDetails.Id")
    });
    evt.fire();
  },

	// fire SF1_NewOpportunityMobileUtilEvent to show Open Opportunities for selected contracts
	showOpenOpportunitiesWithBL: function(component, event, helper) {
    //console.log('Back');
		var currencyMismatch = helper.checkForCurrencyMismatch(component, event);
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
        "showHome" : false,
        "showAccountResults" : false,
        "showWithoutContractBL" : false,
				"showWithContractBL" : false,
				"showOpenOpportunitiesWithBL" : true,
				"selectedContractIDs": component.get("v.selectedContractIDs"),
        "showCreateOppty" : false,
        "accountDetails" : component.get("v.accountDetails"),
        "currencyMismatch" : currencyMismatch,
				"oldCurrency" : component.get("v.contracts[0].Currency__c")
    });
    evt.fire();
  },

	// used to display products : open
	openModal: function(cmp, event) {
    var cmpTarget = cmp.find('Modalbox');
    var cmpBack = cmp.find('ModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

	// used to display products : close
  closeModal: function(cmp, event) {
    var cmpTarget = cmp.find('Modalbox');
    var cmpBack = cmp.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
  },

	//used to expand and collapse contract tile
  toggleHandler: function(cmp, event) {
    var cmpTarget = cmp.find('opptyTile');
    var toggle = cmp.get('v.toggleContract');
    var chevronup = cmp.find('chevronup');
    var chevrondown = cmp.find('chevrondown');
    if (toggle == false) {
      toggle = true;
      $A.util.addClass(cmpTarget, 'slds-is-open');
    } else {
      toggle = false;
      $A.util.removeClass(cmpTarget, 'slds-is-open');
    }
    cmp.set('v.toggleContract', toggle);
  },

})