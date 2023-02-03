({

  openSortModal: function(component, event) {
    var cmpTarget = component.find('SortModalbox');
    var cmpBack = component.find('SortModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

  closeSortModal: function(component, event, helper) {
    helper.closeSortModal(component, event);
  },
  // return user selected values by event
  sortManager: function(component, event, helper) {
    var type = event.currentTarget.dataset.type;
    var order = event.currentTarget.dataset.order;
    helper.closeSortModal(component, event);
    var e = $A.get("e.c:SF1_NewOpportunityMobileSortEvent");
    e.setParams({
      "sortBy" : type,
      "sortOrder" : order
    });
    e.fire();
  }

})