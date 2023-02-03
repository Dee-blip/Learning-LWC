({// get currency picklist values from controller
  fetchCurrencyIsoCode: function(component, event) {

    var loadUserDefaultCurrency = component.get("c.getDefaultUserCurrency");
    loadUserDefaultCurrency.setCallback(this, function(response) {
      var state = response.getState();
      var returnVal = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.newOpportunity.CurrencyIsoCode", returnVal);
      }
    });
    $A.enqueueAction(loadUserDefaultCurrency);
    
    var loadPicklistValues = component.get("c.loadPicklistValues");
    loadPicklistValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "CurrencyIsoCode"
    });
    loadPicklistValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.CurrencyIsoCode", JSON.parse(options));
      }
    });
    $A.enqueueAction(loadPicklistValues);

    //Set The Default CurrencyIsoCode

  },

  closeModal: function(component, event) {
    var cmpTarget = component.find('Modalbox');
    var cmpBack = component.find('ModalClose');
    $A.util.removeClass(cmpBack, 'slds-backdrop--open');
    $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
    component.set("v.openModalOnClick", false);
  },

  saveOppty: function(component, event, helper) {
    //scroll to top
    var elmnt = document.getElementById("scrollableDiv");
    elmnt.scrollLeft = 0;
    elmnt.scrollTop = 0;
    var newOpportunity = component.get("v.newOpportunity");
    var accountDetails = component.get("v.accountDetails");

    var selectedOppType = component.get("v.selectedOppType");
    if(selectedOppType != '--None--' && selectedOppType != null && selectedOppType != ""){
        newOpportunity.Opportunity_Type__c = selectedOppType;
    }
      
    newOpportunity.AccountId = accountDetails.Id;
    
    // check validity
    if (newOpportunity.Name != '' && newOpportunity.AccountId != '' && newOpportunity.CurrencyIsoCode != '' && newOpportunity.Deal_Type__c != '' && newOpportunity.StageName != '' && newOpportunity.CloseDate != '') {
      if (newOpportunity.Deal_Type__c == 'Direct') {
        delete newOpportunity['Partner_Involved__c'];
        delete newOpportunity['Channel_Manager__c'];
      } else if (newOpportunity.Deal_Type__c == 'Indirect') {
        if(newOpportunity.Partner_Involved__c == null || newOpportunity.Partner_Involved__c.Id == null) {
          component.set("v.allFieldsNotSet", false);
          component.set("v.channelManagerFieldNotSet", false);
          component.set("v.partnerInvolvedFieldNotSet", true);
          return;
        }

        if(newOpportunity.Channel_Manager__c == null || newOpportunity.Channel_Manager__c.Id == null) {
          component.set("v.allFieldsNotSet", false);
          component.set("v.partnerInvolvedFieldNotSet", false);
          component.set("v.channelManagerFieldNotSet", true);
          return;
        }

        newOpportunity.Partner_Involved__c = newOpportunity.Partner_Involved__c.Id;
        newOpportunity.Channel_Manager__c = newOpportunity.Channel_Manager__c.Id;
      }
      component.set("v.partnerInvolvedFieldNotSet", false);
      component.set("v.channelManagerFieldNotSet", false);
      component.set("v.allFieldsNotSet", false);
      helper.insertOppty(component, event);
    } else {
      component.set("v.partnerInvolvedFieldNotSet", false);
      component.set("v.channelManagerFieldNotSet", false);
      component.set("v.allFieldsNotSet", true);
    }
  },
  // get DealType picklist values from controller
  fetchDealType: function(component, event) {
    var loadPicklistValues = component.get("c.loadPicklistValues");
    loadPicklistValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "Deal_Type__c"
    });
    loadPicklistValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.DealType", JSON.parse(options));
      }
    });
    $A.enqueueAction(loadPicklistValues);
  },
  // get StageName picklist values from controller
  fetchStageName: function(component, event) {
    var loadPicklistValues = component.get("c.loadPicklistValues");
    loadPicklistValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "StageName"
    });
    loadPicklistValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.StageName", JSON.parse(options));
      }
    });
    $A.enqueueAction(loadPicklistValues);
  },

  // call insertNewOpportunity controller function
  insertOppty: function(component, event) {
    var oppty = component.get("v.newOpportunity");
    var action = component.get("c.insertNewOpportunity");
    var opptyJSON = JSON.stringify(oppty);

    action.setParams({
      "opptyJsonData": opptyJSON
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var results = response.getReturnValue();
        var returnVals = results.split(":");
        if (returnVals[0] === "SUCCESSFUL") {
              //var navEvt = $A.get("e.force:navigateToSObject");
              //navEvt.setParams({
              //                   "recordId": returnVals[1],
              //                   "slideDevName": "detail"
              //                 });
              //navEvt.fire();
          sforce.one.navigateToSObject(returnVals[1]);
        } else {
          component.set("v.insertFailed", true);
          component.set("v.failureMessage", returnVals[1]);
        }
      }
    });
    $A.enqueueAction(action);
  }
})