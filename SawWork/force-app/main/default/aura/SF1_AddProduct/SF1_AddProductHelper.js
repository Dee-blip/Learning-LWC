({
  hideCarrierApplication: function(component) {
    var addCarrierApplication = component.find("addCarrierApplicationId");
    $A.util.removeClass(addCarrierApplication, 'slds-show');
    $A.util.addClass(addCarrierApplication, 'slds-hide');
  },

  loadOppCategoryValues: function(component, event) {
    var loadCategoryValues = component.get("c.fetchPicklistValues");
    loadCategoryValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "Opportunity_Category__c"
    });
    loadCategoryValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.oppCategoryValues", options);
      }
    });
    $A.enqueueAction(loadCategoryValues);
  },

  loadoppSubCategoryValues: function(component, event) {
    var loadSubCategoryValues = component.get("c.getDependentPicklist");
    loadSubCategoryValues.setParams({
      "sobjectName": "Opportunity",
      "parentfieldName": "Opportunity_Category__c",
      "childFieldName": "Loss_Reason__c"
    });
    loadSubCategoryValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        var subCategoryMap = response.getReturnValue();
        var categories = [];
        for (var key in subCategoryMap) {
          categories.push(key);
          console.log('Category = ' + key);
          console.log('Sub-Category = ' + subCategoryMap[key]);
        }
        component.set("v.oppCategoryValues", categories);
        component.set("v.categoryToSubcategoryMap", subCategoryMap);
      }
    });
    $A.enqueueAction(loadSubCategoryValues);
  },

  loadoppSubCategoryToCancellationValues: function(component, event) {
    var loadSubCategoryCancellationValues = component.get("c.getDependentPicklist");
    loadSubCategoryCancellationValues.setParams({
      "sobjectName": "Opportunity",
      "parentfieldName": "Opportunity_Sub_Category__c",
      "childFieldName": "Loss_Reason__c"
    });
    loadSubCategoryCancellationValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        var cancellationMap = response.getReturnValue();
        var cancellationValues = [];
        for (var key in cancellationMap) {
          console.log('Subcategory in Cancellation = ' + key);
          cancellationValues.push(key);
        }
        //component.set("v.oppCancellationLostValues",cancellationValues);
        component.set("v.SubcategoryToCancelLossReasonMap", cancellationMap);
      }
    });
    $A.enqueueAction(loadSubCategoryCancellationValues);
  },

  hideOppPicklistAndShowCancellationFieldsSection: function(component, event) {
    var oppDetailsSection = component.find("oppPicklistDetailsId");
    var cancellationFields = component.find("cancellationFieldsId");
    $A.util.removeClass(oppDetailsSection, "slds-show");
    $A.util.addClass(oppDetailsSection, "slds-hide");
    $A.util.removeClass(cancellationFields, "slds-hide");
    $A.util.addClass(cancellationFields, "slds-show");
  },

  hideCancellationFieldsSectionAndShowOppPicklist: function(component, event) {
    var oppDetailsSection = component.find("oppPicklistDetailsId");
    var cancellationFields = component.find("cancellationFieldsId");
    $A.util.removeClass(cancellationFields, "slds-show");
    $A.util.addClass(cancellationFields, "slds-hide");
    $A.util.removeClass(oppDetailsSection, "slds-hide");
    $A.util.addClass(oppDetailsSection, "slds-show");
  },

  hideNextFooterAndShowSaveFooter: function(component, event) {
    var nextFooter = component.find("nextFooterId");
    var saveFooter = component.find("saveAfterNextFooterId");
    $A.util.removeClass(nextFooter, "slds-show");
    $A.util.addClass(nextFooter, "slds-hide");
    $A.util.removeClass(saveFooter, "slds-hide");
    $A.util.addClass(saveFooter, "slds-show");
  },

  hideBackSaveFooterAndShowMainFooter: function(component, event) {
    var mainFooter = component.find("mainFooterId");
    var backSaveFooter = component.find("saveAfterNextFooterId");
    $A.util.removeClass(backSaveFooter, "slds-show");
    $A.util.addClass(backSaveFooter, "slds-hide");
    $A.util.removeClass(mainFooter, "slds-hide");
    $A.util.addClass(mainFooter, "slds-show");
  },

  hideCancellationFields: function(component, event) {
    var missingProductFeature = component.find("missingProductFeatureId");
    var initialClause = component.find("initialOutClauseId");
    var aggregationPartner = component.find("aggregationPartnerId");
    var consolidationAccount = component.find("consolidationAccountId");
    var competitor = component.find("oppCompetitorId");
    var unacceptableTermsAndConditions = component.find("unacceptableTermsandConditionsId");
    $A.util.removeClass(missingProductFeature, "slds-show");
    $A.util.addClass(missingProductFeature, "slds-hide");
    $A.util.removeClass(initialClause, "slds-show");
    $A.util.addClass(initialClause, "slds-hide");
    $A.util.removeClass(aggregationPartner, "slds-show");
    $A.util.addClass(aggregationPartner, "slds-hide");
    $A.util.removeClass(consolidationAccount, "slds-show");
    $A.util.addClass(consolidationAccount, "slds-hide");
    $A.util.removeClass(competitor, "slds-show");
    $A.util.addClass(competitor, "slds-hide");
    $A.util.removeClass(unacceptableTermsAndConditions, "slds-show");
    $A.util.addClass(unacceptableTermsAndConditions, "slds-hide");
  },

  nullifyCancellationFields: function(component, event) {
    component.set("v.missingProductFeature", null);
    component.set("v.initialOutClause", null);
    component.set("v.aggregationPartnerValue", null);
    component.set("v.consolidationAccount", null);
    component.set("v.competitorValue", null);
    component.set("v.unacceptableTermsAndConditions", null);
  },

  nullifyCancellationPicklistFields: function(component, event) {
    component.set("v.oppCategoryValue", null);
    component.set("v.oppSubCategoryValue", null);
    component.set("v.oppCancellationLostValue", null);
  },

  showMissingFeatureField: function(component, event) {
    var missingProductFeature = component.find("missingProductFeatureId");
    $A.util.removeClass(missingProductFeature, "slds-hide");
    $A.util.addClass(missingProductFeature, "slds-show");
  },

   showOtherCompetitorField: function(component, event) {
    var otherCompetitorField = component.find("otherCompetitorNameId");
    $A.util.removeClass(otherCompetitorField, "slds-hide");
    $A.util.addClass(otherCompetitorField, "slds-show");
  },

  hideOtherCompetitorField: function(component, event) {
    var otherCompetitorField = component.find("otherCompetitorNameId");
    $A.util.removeClass(otherCompetitorField, "slds-show");
    $A.util.addClass(otherCompetitorField, "slds-hide");
  },

  showCompetitorField: function(component, event) {
    var competitor = component.find("oppCompetitorId");
    $A.util.removeClass(competitor, "slds-hide");
    $A.util.addClass(competitor, "slds-show");
  },

  showInitialOutOfClauseField: function(component, event) {
    var initialOutOfClause = component.find("initialOutClauseId");
    $A.util.removeClass(initialOutOfClause, "slds-hide");
    $A.util.addClass(initialOutOfClause, "slds-show");
  },

  showAggregationPartnerField: function(component, event) {
    var aggregationPartner = component.find("aggregationPartnerId");
    $A.util.removeClass(aggregationPartner, "slds-hide");
    $A.util.addClass(aggregationPartner, "slds-show");
  },

  showConsolidationAccountField: function(component, event) {
    var consolidationAccount = component.find("consolidationAccountId");
    $A.util.removeClass(consolidationAccount, "slds-hide");
    $A.util.addClass(consolidationAccount, "slds-show");
  },

  showUnacceptableTermsAndConditionsField: function(component, event) {
    var unacceptableTermsAndConditions = component.find("unacceptableTermsandConditionsId");
    $A.util.removeClass(unacceptableTermsAndConditions, "slds-hide");
    $A.util.addClass(unacceptableTermsAndConditions, "slds-show");
  },

  hideAddOppDetailsSection: function(component, event) {
    var addOppDetailsModal = component.find("addOppDetailsId");
    $A.util.removeClass(addOppDetailsModal, "slds-show");
    $A.util.addClass(addOppDetailsModal, "slds-hide");
  },

  fetchCompetitorValues: function(component, event) {
    var loadCompetitorValues = component.get("c.fetchPicklistValues");
    loadCompetitorValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "Competitor__c"
    });
    loadCompetitorValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.competitorValues", options);

      }
    });
    $A.enqueueAction(loadCompetitorValues);
  },

  fetchAggregationPartnerValues: function(component, event) {
    var loadAggregationPartnerValues = component.get("c.fetchPicklistValues");
    loadAggregationPartnerValues.setParams({
      "sobjectName": "Opportunity",
      "picklistFieldName": "Competitor__c"
    });
    loadAggregationPartnerValues.setCallback(this, function(response) {
      var state = response.getState();
      var options = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.aggregationPartnerValues", options);

      }
    });
    $A.enqueueAction(loadAggregationPartnerValues);
  },

  validateFieldValue: function(component, event) {
    var cancellationValue = component.get("v.oppCancellationLostValue");
    var cancellationErrorMessage = component.find("cancellationErrorMessageId");
    var hidePopUp = false;
    if (cancellationValue == "Missing Product Feature") {
      var missingFeatureValue = component.get("v.missingProductFeature");
      if (missingFeatureValue == null || missingFeatureValue == " ") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Competition-Product/Feature Driven") {
      var competitorValue = component.get("v.competitorValue");
      var missingFeatureValue = component.get("v.missingProductFeature");
      if (competitorValue == null || competitorValue == " " ||
        competitorValue == "--none--" || missingFeatureValue == null ||
        missingFeatureValue == " ") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Initial Out Clause") {
      var initialOutClause = component.get("v.initialOutClause");
      if (initialOutClause == null || initialOutClause == " ") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Aggregation through a Partner (Pick Partner)") {
      var aggregationPartner = component.get("v.aggregationPartnerValue");
      if (aggregationPartner == null || aggregationPartner == " " ||
        aggregationPartner == "--none--") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Contract Consolidation with Akamai Customer") {
      var consolidationAccount = component.get("v.consolidationAccount");
      if (consolidationAccount == null || consolidationAccount == " ") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Competition-Product/Performance Driven") {
      var competitor = component.get("v.competitorValue");
      if (competitor == null || competitor == " " || competitor == "--none--") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Will not accept Akamai Terms and Conditions") {
      var unacceptableTerms = component.get("v.unacceptableTermsAndConditions");
      if (unacceptableTerms == null || unacceptableTerms == " ") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else if (cancellationValue == "Competition Price Driven") {
      var competitor = component.get("v.competitorValue");
      if (competitor == null || competitor == " " || competitor == "--none--") {
        $A.util.removeClass(cancellationErrorMessage, "slds-hide");
        $A.util.addClass(cancellationErrorMessage, "slds-show");
      } else {
        hidePopUp = true;
        $A.util.removeClass(cancellationErrorMessage, "slds-show");
        $A.util.addClass(cancellationErrorMessage, "slds-hide");
      }
    } else {
      var addOppDetailsModal = component.find("addOppDetailsId");
      $A.util.removeClass(addOppDetailsModal, "slds-show");
      $A.util.addClass(addOppDetailsModal, "slds-hide");
    }
    if (hidePopUp) {
      console.log("In Hide section");
      var addOppDetailsModal = component.find("addOppDetailsId");
      $A.util.removeClass(addOppDetailsModal, "slds-show");
      $A.util.addClass(addOppDetailsModal, "slds-hide");
    }
  },

  performOppSaveAndProductCreation: function(component, event) {
    var oppCategoryValue = component.get("v.oppCategoryValue");
    var subCategoryValue = component.get("v.oppSubCategoryValue");
    var oppCanceltnValue = component.get("v.oppCancellationLostValue");
    var carrierAppnValue = component.get("v.carrierAppValue");
    var missingFeatureValue = component.get("v.missingProductFeature");
    var initialOutClause = component.get("v.initialOutClause");
    var aggregationPartner = component.get("v.aggregationPartnerValue");
    var consolidationAccount = component.get("v.consolidationAccount");
    var competitor = component.get("v.competitorValue");
    var unacceptableTerms = component.get("v.unacceptableTermsAndConditions");
    var insertAction = component.get("c.insertProductObj");
    var prodName = component.get("v.oppLineItemObject.Product2Id");
    var productsMap = component.get("v.productNamesMap");
    var prodEvnt = $A.get("e.c:goToProductDetail");
    var fetchPricebook = component.get("c.fetchPricebookEntry");
    var termValue = component.get("v.oppLineItemObject.Term__c");
    var AdditionalLossDetail = component.get("v.additionalLossValue");
    var otherCompetitorName = component.get("v.otherCompetitorName");

    component.set("v.opportunityObj.Loss_Cancellation_Description__c", AdditionalLossDetail);

    console.log("oppCategoryValue == " + oppCategoryValue);
    console.log("subCategoryValue == " + subCategoryValue);
    console.log("oppCanceltnValue == " + oppCanceltnValue);
    console.log("prodName == " + prodName);
    if (prodName == "Web Performance - Alta/WAA") {
      console.log("In Web Performance Logic");
      component.set("v.oppLineItemObject.Quantity__c", 1);
    }
    component.set("v.oppLineItemObject.Product2Id", productsMap[prodName]);
    if (oppCategoryValue != null || subCategoryValue != null || oppCanceltnValue != null || carrierAppnValue != null) {
      if (oppCanceltnValue != null) {
        component.set("v.opportunityObj.Opportunity_Category__c", oppCategoryValue);
        component.set("v.opportunityObj.Opportunity_Sub_Category__c", subCategoryValue);
        component.set("v.opportunityObj.Loss_Reason__c", oppCanceltnValue);
        if (missingFeatureValue != "--none--" && missingFeatureValue != null &&
          missingFeatureValue != " ") {
          component.set("v.opportunityObj.Missing_Product_Feature__c", missingFeatureValue);
        }
        if (initialOutClause != "--none--" && initialOutClause != null &&
          initialOutClause != " ") {
          component.set("v.opportunityObj.Initial_Out_Clause_Description__c", initialOutClause);
        }
        if (aggregationPartner != "--none--" && aggregationPartner != null &&
          aggregationPartner != " ") {
          component.set("v.opportunityObj.Aggregation_Partner__c", aggregationPartner);
        }
        if (consolidationAccount != "--none--" && consolidationAccount != null &&
          consolidationAccount != " ") {
          component.set("v.opportunityObj.Consolidation_Account__c", consolidationAccount);
        }

        if (competitor != "--none--" && competitor != null && competitor != " ") {
          component.set("v.opportunityObj.Competitor__c", competitor);
          if(otherCompetitorName !=null || otherCompetitorName != undefined) {
            component.set("v.opportunityObj.Other_Competitor_Name__c", otherCompetitorName);
          }
        }
        if (unacceptableTerms != "--none--" && unacceptableTerms != null &&
          unacceptableTerms != " ") {
          component.set("v.opportunityObj.Unacceptable_Terms_and_Conditions__c", unacceptableTerms);
        }
      }
      if (carrierAppnValue != "--none--" && carrierAppnValue != null && carrierAppnValue != " ") {
        component.set("v.opportunityObj.Carrier_Application__c", carrierAppnValue);
      }
      var updateAction = component.get("c.updateOpportunityObj");
      console.log('=========SaketTest========');
      console.log(component.get("v.opportunityObj"));
      console.log(component.get("v.opportunityObj").Opportunity_Category__c);
      console.log(component.get("v.opportunityObj").Loss_Reason__c);
      updateAction.setParams({
        "pageObject": component.get("v.opportunityObj")
      });
      updateAction.setCallback(this, function(response) {
        var state = response.getState();
        var message = response.getReturnValue();
        console.log("State during Update= " + state);
        console.log("State during Update message= " + message);
        console.log('=========SaketTestEnd========');
        if (component.isValid() && state === "SUCCESS" && message === "success") {
          console.log("After Opp Save Success");
        } else if (component.isValid() && state === "SUCCESS" && message === "success") {}
      });
      $A.enqueueAction(updateAction);
    }

    // SFDC-3714 @Nagaraj Desai
    var splProMonComTouched = component.get("v.splProMonComTouched");
    var splProMonComFld = component.get("v.splProMonComFld");
    var proMonComFld = component.get("v.proMonComFld");

    component.set("v.oppLineItemObject.Projected_Monthly_commit_fees__c", proMonComFld);
    component.set("v.oppLineItemObject.Specialist_Projected_Monthly_Commit__c", splProMonComFld);
    component.set("v.oppLineItemObject.Specialist_Touched__c", splProMonComTouched);

    // var splProMonUsgTouched = component.get("v.splProMonUsgTouched");
    // var splProMonUsgFld = component.get("v.splProMonUsgFld");
    var proMonUsgFld = component.get("v.proMonUsgFld");
    component.set("v.oppLineItemObject.Projected_Avg_Rev_Non_Commit__c", proMonUsgFld);
    //component.set("v.oppLineItemObject.Specialist_Projected_Monthly_Usage__c", splProMonUsgFld);
    //component.set("v.oppLineItemObject.Specialist_Usage_Touched__c", splProMonUsgTouched);

    component.set("v.oppLineItemObject.Specialist_Forecast_Touched__c", component.get("v.splForecastCategoryTouched"));
    component.set("v.oppLineItemObject.Specialist_Forecast_Category__c", component.get("v.splForecastCategoryFld"));

    component.set("v.oppLineItemObject.Specialist_Close_Date_Touched__c", component.get("v.splCloseDateTouched"));
    component.set("v.oppLineItemObject.Specialist_Close_Date__c", component.get("v.splCloseDateFld"));

    component.set("v.oppLineItemObject.Term__c", termValue);
    // SFDC-3714 @Nagaraj Desai End

    console.log('Line Item Obj');
    console.log(component.get("v.oppLineItemObject"));
    console.log("Insert Product line");
    console.log("Price Book Entry == " + component.get("v.oppLineItemObject.PricebookEntryId"));

    insertAction.setParams({
      "pageObject": component.get("v.oppLineItemObject")
    });
    insertAction.setCallback(this, function(response) {
      var state = response.getState();
      var message = response.getReturnValue();
      console.log("State after insert = " + state);
      if (component.isValid() && state === "SUCCESS" && message != null) {
        console.log("After Product without Opp Save Success");
        prodEvnt.setParams({
          "OppLineItemId": message
        });
         // Clear the previous values
         component.set("v.splForecastCategoryFld",null);
         component.set("v.splProMonComTouched",null);
         component.set("v.splProMonComFld",null);
         component.set("v.proMonComFld",null);
        prodEvnt.fire();
      } else if (component.isValid() && state === "SUCCESS" && message === null) {}
    });
    $A.enqueueAction(insertAction);
  },

  populatePriceBookEntry: function(component, event) {
    var fetchPricebook = component.get("c.fetchPricebookEntry");
    var prodName = component.get("v.oppLineItemObject.Product2Id");
    var productsMap = component.get("v.productNamesMap");
    fetchPricebook.setParams({
      "productId": productsMap[prodName],
      "currencyCode": component.get("v.opportunityObj.CurrencyIsoCode")
    });
    fetchPricebook.setCallback(this, function(response) {
      var state = response.getState();
      var message = response.getReturnValue();
      if (component.isValid() && state === "SUCCESS" && message != null) {
        console.log('Result of FetchPriceBook = ' + message);
        component.set("v.oppLineItemObject.PricebookEntryId", message);
      } else if (component.isValid() && state === "SUCCESS" && message === null) {}
    });
    $A.enqueueAction(fetchPricebook);
  },
})