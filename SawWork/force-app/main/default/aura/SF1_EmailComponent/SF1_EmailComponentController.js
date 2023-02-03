({
  removeSelectedUser: function(component) {
    component.set("v.htmlDataObj.contactName", null);
  },

  doInit: function(component) {
    var associatedOppty = component.get("v.associatedOppty");
    var whereClause = '';
    if (associatedOppty.Partner_Involved__c != null) {
      whereClause += "(AccountId = '" + associatedOppty.Partner_Involved__c + "'";
    }

    if (associatedOppty.Partner_Involved__r.ParentId != null) {
      whereClause += " OR ";
      whereClause += "AccountId = '" + associatedOppty.Partner_Involved__r.ParentId + "')";
    } else {
      whereClause += ")";
    }

    if (whereClause != '') {
      whereClause += " AND "
    }

    whereClause += "Active_Partner__c = true AND Can_Accept_POA__c = 'Yes'";
    component.set("v.whereClause", whereClause);
  },

  moveBack: function(component) {
    window.history.back();
  },

  sendEmail: function(component, event, helper) {
    helper.sendEmailFromSF1(component, event, helper);
    helper.closeModal(component, event);
  },

  openModal: function(component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    $A.util.addClass(cmpBack, 'slds-backdrop--open');
  },

  // used to display products : close
  closeModal: function(component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
  },
})