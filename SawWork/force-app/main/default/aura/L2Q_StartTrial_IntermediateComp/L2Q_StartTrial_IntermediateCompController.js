({
  init: function(component, event, helper) {
    helper.setDataTableHeader(component);
    helper.setDataTableRows(component);

    var errorMessage = component.get("v.errorMessage");
    if (errorMessage != null && errorMessage != '') {
      component.set("v.hasErrors", true);
    } else if (component.get("v.objectType") == "Lead" || component.get("v.objectType") == "Contact") {
      window.open(component.get("v.redirectionURL"), '_blank');
      window.history.back();
    }

  },

  back: function(component, event, helper) {
    window.history.back();
  },

  openBuyAkamaiWindow: function(component, event, helper) {
    window.open(component.get("v.redirectionURL"), '_blank');
  },

  openModal: function(component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

  startManualTrial: function(component, event, helper) {
    helper.startManualTrial(component);
    helper.closeModal(component, event);
  },

  closeModal: function(component, event, helper) {
    helper.closeModal(component, event);
  },
  updateColumnSorting: function(component, event, helper) {
    var fieldName = event.getParam('fieldName');
    var sortDirection = event.getParam('sortDirection');
    component.set("v.sortedBy", fieldName);
    component.set("v.sortedDirection", sortDirection);
    helper.sortData(component, fieldName, sortDirection);
  },
  //Open URL in New Browser Tab
    handleOpenInNewWindow: function () {
      window.open("https://ac.akamai.com/docs/DOC-83411", '_blank');
    }
})