({
  doInit: function(component, event, helper) {
    console.log('Hi');
    helper.getLightningTableData(component);
  },

  init: function(component, event, helper) {
    helper.getLightningTableData(component);
    helper.setDataTableData(component);
  },

  updateColumnSorting: function(component, event, helper) {
    var fieldName = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    component.set("v.sortedBy", fieldName);
    component.set("v.sortedDirection", sortDirection);
    helper.sortData(component, fieldName, sortDirection);
  },

  getSelectedName: function(component, event) {
    var selectedRows = event.getParam('selectedRows');
    for (var i = 0; i < selectedRows.length; i++) {
      console.log(selectedRows[i].Id);
    }
  },

  handleRowActionMyApprovals: function(component, event, helper) {
    var action = event.getParam('action');
    var row = event.getParam('row');
    console.log(JSON.stringify(row));
    console.log(action.name);
    if (action.name == 'reassign') {
      var myApprovalData = component.get("v.myApprovalData");
      var reassignmentApprovalId = myApprovalData[row.id].approvalId;

      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": reassignmentApprovalId
      });
      navEvt.fire();

    } else if (action.name == 'approveReject') {
      console.log('approveReject function');
    }
  },

  handleMyApprovalSearch: function(component, event, helper) {
    var searchText = component.get("v.searchText");
    helper.showSearchResults(component, 'myApprovals');
  },

  handleDelegatedApprovalSearch: function(component, event, helper) {
    var searchText = component.get("v.searchText");
    helper.showSearchResults(component, 'delegatedApproval');
  },

  manageAll: function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef: "c:GsmLite_ManageAllCmp"
      // componentAttributes: {
      //   myApprovalData: component.get("v.myApprovalData"),
      //   myApprovalColumns: component.get("v.myApprovalColumns"),
      //   delegatedApprovalData: component.get("v.delegatedApprovalData"),
      //   delegatedApprovalColumns: component.get("v.delegatedApprovalColumns")
      // }
    });
    evt.fire();

    // var urlEvent = $A.get("e.force:navigateToURL");
    // urlEvent.setParams({
    //   "url": "/one/one.app#eyJjb21wb25lbnREZWYiOiJjOkdzbUxpdGVfTWFuYWdlQWxsQ21wIiwiYXR0cmlidXRlcyI6e319"
    //   // "url": "/c/manageAllApp.app"
    //
    // });
    // urlEvent.fire();

  },
})