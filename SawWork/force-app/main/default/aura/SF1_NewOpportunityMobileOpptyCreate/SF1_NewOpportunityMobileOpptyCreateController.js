({
  // fetch picklist values
  doInit: function(component, event, helper) {
    var accountDetails = component.get("v.accountDetails");
    component.set("v.newOpportunity.AccountId", accountDetails.Id);
    helper.fetchCurrencyIsoCode(component, event);
    helper.fetchDealType(component, event);
    //helper.fetchStageName(component, event);
  },
  // create dynmaic where clause
  populateWhereClause: function(component, event, helper) {
    var whereClause = "Partner_Name__r.Id = '" + component.get("v.newOpportunity.Partner_Involved__c.Id") + "' AND PAE_ID__r.Alias != 'ONA' AND Active__c = true";
    component.set("v.channelManagerWhereClause", whereClause);
    //helper.scrollToBottom();
  },

  moveNext: function(component, event, helper) {
    component.set("v.showOpptyForm", false);
  },

  moveToOpptyForm: function(component, event, helper) {
    component.set("v.showOpptyForm", true);
  },

  openModal: function(component, event, helper) {
    console.log('Button');
    // if(component.get("v.newOpportunity.Deal_Type__c") == "Indirect") {
    //   var cmpTarget = component.find('Modalbox');
    //   var cmpBack = component.find('ModalClose');
    //   $A.util.addClass(cmpTarget, 'slds-fade-in-open');
    //   $A.util.addClass(cmpBack, 'slds-backdrop--open');
    // }
    // else {
    //   helper.saveOppty(component, event, helper);
    //   helper.closeModal(component, event);
    // }
  },

  saveOppty: function(component, event, helper) {
    helper.saveOppty(component, event, helper);
    //helper.closeModal(component, event);
  },

  closeModal: function(component, event, helper) {
    helper.closeModal(component, event);
  },

  // try saving opportunity
  // remove Partner_Involved__c, Channel_Manager__c values if the user changes fromm indirect to direct
  validateRendering: function(component, event) {
    console.log('inside validate');
    console.log(component.get("v.newOpportunity"));
    if (component.get("v.newOpportunity.Deal_Type__c") == 'Direct' && component.get("v.newOpportunity.Partner_Involved__c") != null) {
      component.set("v.newOpportunity.Partner_Involved__c", null);
      component.set("v.newOpportunity.Channel_Manager__c", null);
    }
  },

  removePartnerInvolved: function(component, event, helper) {
    if (component.get("v.newOpportunity.Channel_Manager__c.Id") != null) {
      component.set("v.newOpportunity.Channel_Manager__c.Id", null);
    }
    if (component.get("v.newOpportunity.Channel_Manager__c") != null) {
      component.set("v.newOpportunity.Channel_Manager__c", null);
    }

    if (component.get("v.newOpportunity.Partner_Involved__c.Id") != null) {
      component.set("v.newOpportunity.Partner_Involved__c.Id", null);
    }
    if (component.get("v.newOpportunity.Partner_Involved__c") != null) {
      component.set("v.newOpportunity.Partner_Involved__c", null);
    }
  },

  removeChannelManager: function(component, event, helper) {
    component.set("v.newOpportunity.Channel_Manager__c.Id", null);
    component.set("v.newOpportunity.Channel_Manager__c", null);
  },
  //bak to open oppties
  moveBack: function(component, event) {
    var evt = $A.get("e.c:SF1_NewOpportunityMobileUtilEvent");
    evt.setParams({
      "showHome": false,
      "showAccountResults": false,
      "showWithContractBL": false,
      "showWithoutContractBL": true,
      "showOpenOpportunitiesWithBL": false,
      "accountDetails": component.get("v.accountDetails")
    });
    evt.fire();
  },

})