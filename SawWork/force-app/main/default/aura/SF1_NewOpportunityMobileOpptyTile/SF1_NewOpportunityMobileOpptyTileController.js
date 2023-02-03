({
  // open modal
  openModal: function(component, event) {
    var opptyId = event.target.name;
    var action = component.get("c.getRenewalContractsByOpttyId");
    action.setParams({
      "opptyId": opptyId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        component.set("v.contractsToShow", results);
        console.log("results of contracts recieved in Oppty Tile: " + JSON.stringify(results));
        component.set("v.contractFetchFailed", false);

        component.set("v.openModalOnClick", true);
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('ModalClose');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');

      } else {
        component.set("v.contractFetchFailed", true);

        component.set("v.openModalOnClick", false);
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('ModalClose');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');

      }
    });
    $A.enqueueAction(action);
  },

  fireModalEvent: function(component, event, helper) {
    var opptyId = event.target.name;
    var action = component.get("c.getRenewalContractsByOpttyId");
    action.setParams({
      "opptyId": opptyId
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        component.set("v.contractsToShow", results);
        console.log("results of contracts recieved in Oppty Tile: " + JSON.stringify(results));
        component.set("v.contractFetchFailed", false);

        var evt = $A.get("e.c:SF1_NewOpportunityMobileModalEvent");
        evt.setParams({
          "itemsToShow": results
        });
        evt.fire();

      } else {
        component.set("v.contractFetchFailed", true);
      }
    });
    $A.enqueueAction(action);

  },

  // expand and collapse opportunity tile with contract BL
  toggleHandler: function(cmp, event) {
    var cmpTarget = cmp.find('opptyTile');
    var toggle = cmp.get('v.toggle');
    var chevronup = cmp.find('chevronup');
    var chevrondown = cmp.find('chevrondown');
    if (toggle == false) {
      toggle = true;
      $A.util.addClass(cmpTarget, 'slds-is-open');

    } else {
      toggle = false;
      $A.util.removeClass(cmpTarget, 'slds-is-open');
    }
    cmp.set('v.toggle', toggle);
  },
  // display opportunity details
  displayOppty: function(component, event, helper) {
    var opptyId = component.get("v.oppty.Id");
    // var navEvt = $A.get("e.force:navigateToSObject");
    // navEvt.setParams({
    //   "recordId": opptyId,
    //   "slideDevName": "detail"
    // });
    // navEvt.fire();
    sforce.one.navigateToSObject(opptyId, "detail");
  },
})