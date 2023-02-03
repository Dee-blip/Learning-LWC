({
  doInit: function(component, event, helper) {
    // create SF1_LookupComponent component
    if(component.get("v.selectedContractIDs").length > 0) {
      var setOfContractIDs = new Set(component.get("v.selectedContractIDs"));
      if(setOfContractIDs.has(component.get("v.contract.Id"))) {
        component.set("v.selectThisContract", true);
      }
    }
    if (component.get("v.contractType") == 'secondaryContractTile') {
      console.log("Each Contract Details in Contract Tile: ");
      console.log(component.get("v.renewalContract"));
    }
  },

  fireModalEvent: function(component, event, helper) {
    var productsToShow = event.target.name;
    console.log(productsToShow);
    var evt = $A.get("e.c:SF1_NewOpportunityMobileModalEvent");
    evt.setParams({
      "itemsToShow": productsToShow
    });
    evt.fire();
  },

  toggleHandler: function(cmp, event) {
    var cmpTarget = cmp.find('opptyTile');
    var toggle = cmp.get('v.toggleContract');
    var chevronup = cmp.find('chevronup');
    var chevrondown = cmp.find('chevrondown');
    if (toggle == false) {
      toggle = true;
      $A.util.addClass(cmpTarget, 'slds-is-open');

      //$A.util.removeClass(chevrondown,'slds-visible');
      //$A.util.addClass(chevrondown, 'slds-hidden');

      //$A.util.removeClass(chevronup,'slds-hidden');
      //$A.util.addClass(chevronup, 'slds-visible');
    } else {
      toggle = false;
      $A.util.removeClass(cmpTarget, 'slds-is-open');

      //$A.util.removeClass(chevronup,'slds-visible');
      //$A.util.addClass(chevronup, 'slds-hidden');

      //$A.util.removeClass(chevrondown,'slds-hidden');
      //$A.util.addClass(chevrondown, 'slds-visible');
    }
    cmp.set('v.toggleContract', toggle);
  },

  returnValuesToParent: function(component, event, helper) {
    var selectThisContract = component.get("v.selectThisContract");
    component.set("v.selectThisContract", selectThisContract);

    var evt = $A.get("e.c:SF1_NewOpportunityMobileContractEvent");
    evt.setParams({
      "isPushContract": selectThisContract,
      "selectedContractId": component.get("v.contract.Id")
    });
    evt.fire();
  },

  selectThisContract: function(component, event, helper) {
    var selectContract = component.get("v.selectThisContract");
    component.set("v.selectThisContract", !selectContract);
  }
})