({
  init: function(component, event, helper) {
    helper.getLightningTableData(component, event, helper);
    helper.setDataTableHeader(component);
  },

  updateColumnSorting: function(component, event, helper) {
    var fieldName = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    component.set("v.sortedBy", fieldName);
    component.set("v.sortedDirection", sortDirection);
    helper.sortData(component, fieldName, sortDirection);
  },
  // used to display products : open
  openReassignModal: function(component, event, helper) {
    // component.set("v.modalTitle", "Reassign Approval Request/s");
    component.set("v.openModalMode", "reassign");
    helper.openModal(component, event);
  },
  openApproveModal: function(component, event, helper) {
    // component.set("v.modalTitle", "Approve/ Reject Account Reassignment Request/s");
    component.set("v.openModalMode", "approve");
    helper.openModal(component, event);
  },
  openRejectModal: function(component, event, helper) {
    // component.set("v.modalTitle", "Approve/ Reject Account Reassignment Request/s");
    component.set("v.openModalMode", "reject");
    helper.openModal(component, event);
  },
  refreshComponent: function(component, event, helper) {
    // helper.getLightningTableData(component, event, helper);
    // component.set("v.sortedDirection", "asc");
    // component.set("v.searchText", "");
    // component.set("v.reassignTo", null);
    // component.set("v.selectedApprovalIds", null);
    $A.get('e.force:refreshView').fire();

  },
  // used to display products : close
  closeModal: function(component, event) {
    var componentTarget = component.find('Modalbox');
    var componentBack = component.find('ModalClose');
    $A.util.removeClass(componentBack, 'slds-backdrop--open');
    $A.util.removeClass(componentTarget, 'slds-fade-in-open');
  },
  getSelectedIds: function(component, event) {
    var selectedRows = event.getParam('selectedRows');
    var selectedIds = [];
    for (var i = 0; i < selectedRows.length; i++) {
      selectedIds.push((selectedRows[i].approvalId).substr(1));
      console.log((selectedRows[i].approvalId).substr(1));
    }
    component.set("v.selectedApprovalIds", selectedIds);
  },

  reassign: function(component, event, helper) {
    component.set("v.returnMessage", "");
    component.set("v.recievedSuccess", false);
    component.set("v.recievedError", false);

    helper.reassignMultipleApprovals(component, event, helper);
  },

  approve: function(component, event, helper) {
    component.set("v.returnMessage", "");
    component.set("v.recievedSuccess", false);
    component.set("v.recievedError", false);

    helper.approveMultipleApprovals(component, event, helper);
  },

  reject: function(component, event, helper) {
    component.set("v.returnMessage", "");
    component.set("v.recievedSuccess", false);
    component.set("v.recievedError", false);

    helper.rejectMultipleApprovals(component, event, helper);
  },

})