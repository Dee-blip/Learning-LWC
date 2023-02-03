({
  doInit: function(component, event, helper) {
    console.log('init prod view');
    helper.initProdAction(component);
    helper.nullifyCancellationFields(component, event);
    helper.nullifyCancellationPicklistFields(component, event);
  },

  navigateToManageProducts: function(component, event, helper) {
    var evt = $A.get("e.force:navigateToComponent");
    evt.setParams({
      componentDef: "c:SF1_ManageProducts",
      componentAttributes: {
        recordId: component.get("v.OppId"),
      },
    });
    evt.fire();
  },

  touchedMonCmtFld: function(component, event, helper) {
    component.set("v.splProMonComTouched", true);
  },

  // touchedMonUsgFld: function(component, event, helper) {
  //   component.set("v.splProMonUsgTouched", true);
  // },
  touchedSpecialistOneTimeFee: function(component, event, helper) {
    component.set("v.specialistOneTimeFeeTouched", true);
  },

  touchedSplForecastCat: function(component, event, helper) {
    component.set("v.splForecastCategoryTouched", true);
  },
  touchedSplCloseDate: function(component, event, helper) {
    component.set("v.splCloseDateTouched", true);
  },
  // updateSpcltMonUsgFld: function(component, event, helper) {
  //   if (!component.get("v.splProMonUsgTouched")) {
  //     component.set("v.splProMonUsgFld", component.get("v.proMonUsgFld"));
  //   }
  // },

  updateSpcltMonCmtFld: function(component, event, helper) {
    if (!component.get("v.splProMonComTouched")) {
      component.set("v.splProMonComFld", component.get("v.proMonComFld"));
    }
  },
  updateSpecialistOneTimeFee: function(component, event, helper) {
    if (!component.get("v.specialistOneTimeFeeTouched")) {
      component.set("v.specialistOneTimeFee", component.get("v.oppLineItemObj.NRR__c"));
    }
  },

  editAction: function(component, event) {
    var EditOppTab = component.find("editOnlyProdInfoId");
    var ReadOppTab = component.find("readOnlyProdInfoId");
    var delBtn = component.find("DeleteProdBtnId");
    var saveBtn = component.find("SaveProdBtnId");
    var editBtn = component.find("EditProdBtnId");
    var cancelEditBtn = component.find("CancelEditProdBtnId");
    var cancelBtn = component.find("CancelProdBtnId");
    var backBtn = component.find("BackProdBtnId");
    $A.util.removeClass(ReadOppTab, 'slds-show');
    $A.util.addClass(ReadOppTab, 'slds-hide');
    $A.util.removeClass(editBtn, 'slds-show');
    $A.util.addClass(editBtn, 'slds-hide');
    $A.util.removeClass(delBtn, 'slds-show');
    $A.util.addClass(delBtn, 'slds-hide');
    $A.util.removeClass(cancelBtn, 'slds-show');
    $A.util.addClass(cancelBtn, 'slds-hide');
    $A.util.removeClass(backBtn, 'slds-show');
    $A.util.addClass(backBtn, 'slds-hide');
    $A.util.removeClass(saveBtn, 'slds-hide');
    $A.util.addClass(saveBtn, 'slds-show');
    $A.util.removeClass(cancelEditBtn, 'slds-hide');
    $A.util.addClass(cancelEditBtn, 'slds-show');
    $A.util.removeClass(EditOppTab, 'slds-hide');
    $A.util.addClass(EditOppTab, 'slds-show');
    console.log("Proj Value in Edit== " + component.get('v.oppLineItemObj.Projected_Monthly_commit_fees__c'));
  },

  cancelEditAction: function(component, event, helper) {
    var EditOppTab = component.find("editOnlyProdInfoId");
    var ReadOppTab = component.find("readOnlyProdInfoId");
    var delBtn = component.find("DeleteProdBtnId");
    var saveBtn = component.find("SaveProdBtnId");
    var editBtn = component.find("EditProdBtnId");
    var cancelEditBtn = component.find("CancelEditProdBtnId");
    var cancelBtn = component.find("CancelProdBtnId");
    var backBtn = component.find("BackProdBtnId");
    $A.util.removeClass(EditOppTab, 'slds-show');
    $A.util.addClass(EditOppTab, 'slds-hide');
    $A.util.removeClass(cancelEditBtn, 'slds-show');
    $A.util.addClass(cancelEditBtn, 'slds-hide');
    $A.util.removeClass(saveBtn, 'slds-show');
    $A.util.addClass(saveBtn, 'slds-hide');
    $A.util.removeClass(delBtn, 'slds-hide');
    $A.util.addClass(delBtn, 'slds-show');
    $A.util.removeClass(editBtn, 'slds-hide');
    $A.util.addClass(editBtn, 'slds-show');
    $A.util.removeClass(backBtn, 'slds-hide');
    $A.util.addClass(backBtn, 'slds-show');
    $A.util.removeClass(cancelBtn, 'slds-hide');
    $A.util.addClass(cancelBtn, 'slds-show');
    $A.util.removeClass(ReadOppTab, 'slds-hide');
    $A.util.addClass(ReadOppTab, 'slds-show');
    helper.initProdAction(component);
    component.set('v.oppLineItemObj.Projected_Monthly_commit_fees__c', '');
    component.set('v.oppLineItemObj.Projected_Avg_Rev_Non_Commit__c', '');
    component.set('v.oppLineItemObj.NRR__c', '');
    console.log("Proj Value == " + component.get('v.oppLineItemObj.Projected_Monthly_commit_fees__c'));
    //component.find("ProjMonthlyname").set('v.value','v.oppLineItemObj.Projected_Monthly_commit_fees__c') ;
  },

  saveAction: function(component, event, helper) {

    //SFDC-3932

    var termValue = component.find("TermValue").get("v.value");
    var termErrorMessage = component.find("termErrorMessageId");
    var termRequired = component.get("v.termRequired");
    
    if(termRequired == true && (termValue == '' || termValue == null  )){
          component.set("v.termErrorMessage","Term is a Mandatory field");
          $A.util.removeClass(termErrorMessage, "slds-hide");
          $A.util.addClass(termErrorMessage, "slds-show");
          return;
      }
      else if(termValue < 0 || termValue > 24){
          component.set("v.termErrorMessage","Term cannot be less than 0 and greater than 24");
          $A.util.removeClass(termErrorMessage, "slds-hide");
          $A.util.addClass(termErrorMessage, "slds-show");
          return;
      }
      else{
          $A.util.removeClass(termErrorMessage, "slds-show");
          $A.util.addClass(termErrorMessage, "slds-hide");
      }

    //SFDC-3714
    component.set("v.oppLineItemObj.Specialist_Touched__c", component.get("v.splProMonComTouched"));
    component.set("v.oppLineItemObj.Specialist_Projected_Monthly_Commit__c", component.get("v.splProMonComFld"));
    component.set("v.oppLineItemObj.Projected_Monthly_commit_fees__c", component.get("v.proMonComFld"));

    // component.set("v.oppLineItemObj.Specialist_Usage_Touched__c", component.get("v.splProMonUsgTouched"));
    // component.set("v.oppLineItemObj.Specialist_Projected_Monthly_Usage__c", component.get("v.splProMonUsgFld"));
    component.set("v.oppLineItemObj.Projected_Avg_Rev_Non_Commit__c", component.get("v.proMonUsgFld"));

    component.set("v.oppLineItemObj.Specialist_Forecast_Touched__c", component.get("v.splForecastCategoryTouched"));
    component.set("v.oppLineItemObj.Specialist_Forecast_Category__c", component.get("v.splForecastCategoryFld"));

    component.set("v.oppLineItemObj.Specialist_Close_Date_Touched__c", component.get("v.splCloseDateTouched"));
    component.set("v.oppLineItemObj.Specialist_Close_Date__c", component.get("v.splCloseDateFld"));

    component.set("v.oppLineItemObj.Term__c", component.find("TermValue").get("v.value"));
    //SFDC-3714 END

    console.log("Page Object Opplines == " + JSON.stringify(component.get("v.oppLineItemObj.OpportunityLineItems")));
    var projMonthlyValue = component.get("v.oppLineItemObj.Projected_Monthly_commit_fees__c");
    var oppDetailsTab = component.find("addOppDetailsId");
    var oppCancellationValue = component.get("v.opportunityObj.Loss_Reason__c");
    var oppCancellationCompValue = component.get("v.oppCancellationLostValue");
    var baselineProdNeg = false;
    var negativeProductAction = component.get("c.checkBaselineNegativeAmount");
    var negativeValue = false;
    if (component.get("v.oppLineItemObj.Average_Renewal_Commit_MRR__c") != null ||
      component.get("v.oppLineItemObj.Average_Renewal_Usage_MRR__c") != null) {
      if (component.get("v.oppLineItemObj.Projected_Monthly_commit_fees__c") -
        component.get("v.oppLineItemObj.Average_Renewal_Commit_MRR__c") < 0)
        baselineProdNeg = true;
    }
    negativeProductAction.setParams({
      "oppId": component.get("v.opportunityObj.Id")
    });
    negativeProductAction.setCallback(this, function(response) {
      var state = response.getState();
      if (component.isValid() && state === "SUCCESS") {
        component.set("v.termValue", component.get("v.oppLineItemObj.Term__c"))
        negativeValue = response.getReturnValue();
        if (baselineProdNeg || (projMonthlyValue < 0) || negativeValue) {
          if ((oppCancellationValue == null || oppCancellationValue == " ") &&
            (oppCancellationCompValue == null || oppCancellationCompValue == "--none--")) {
            console.log('Negative Value');
            helper.loadoppSubCategoryValues(component, event);
            helper.loadoppSubCategoryToCancellationValues(component, event);
            $A.util.removeClass(oppDetailsTab, "slds-hide");
            $A.util.addClass(oppDetailsTab, "slds-show");
          } else {
            $A.util.removeClass(oppDetailsTab, "slds-show");
            $A.util.addClass(oppDetailsTab, "slds-hide");
            helper.performOppSaveAndProductCreation(component, event);
            //helper.initProdAction(component);
          }
        } else {
          $A.util.removeClass(oppDetailsTab, "slds-show");
          $A.util.addClass(oppDetailsTab, "slds-hide");
          //helper.performOppSaveAndProductCreation(component,event);
          helper.saveProd(component);
          //helper.initProdAction(component);
        }
      }
    });
    $A.enqueueAction(negativeProductAction);

    //helper.saveProd(component);
    //helper.initProdAction(component);
  },

  deleteAction: function(component, event, helper) {

    console.log("Page Object in Delete == " + JSON.stringify(component.get("v.oppLineItemObj")));
    helper.deleteProd(component);
  },

  backAction: function(component, event, helper) {
    var evntOppProductNavigate = $A.get("e.c:invokeOppProdDetailsInit");
    evntOppProductNavigate.fire();
    //$A.get('e.force:refreshView').fire();
  },

  cancelAction: function(component, event, helper) {

    console.log("Page Object == " + JSON.stringify(component.get("v.oppLineItemObj")));
    helper.cancelProd(component);
    helper.initProdAction(component);
    $A.get('e.force:refreshView').fire();
  },

  showSpinner: function(cmp, event, helper) {
    var spinner = cmp.find("ltngSpinner");
    $A.util.removeClass(spinner, "slds-hide");
    $A.util.addClass(spinner, "slds-show");

  },

  hideSpinner: function(cmp, event, helper) {
    var spinner = cmp.find("ltngSpinner");
    $A.util.removeClass(spinner, "slds-show");
    $A.util.addClass(spinner, "slds-hide");
  },

  toggleSpinner: function(cmp, event) {
    var spinner = cmp.find("ltngSpinner");
    $A.util.toggleClass(spinner, "slds-show");
  },

  hidePopUp: function(component, event) {
    var modalTab = component.find("modalId");
    $A.util.removeClass(modalTab, 'slds-show');
    $A.util.addClass(modalTab, 'slds-hide');
  },

  showPopUp: function(component, event) {
    var modalTab = component.find("modalId");
    $A.util.removeClass(modalTab, 'slds-hide');
    $A.util.addClass(modalTab, 'slds-show');
  },

  hidePopUpandDelete: function(component, event, helper) {
    var modalTab = component.find("modalId");
    $A.util.removeClass(modalTab, 'slds-show');
    $A.util.addClass(modalTab, 'slds-hide');
    helper.deleteProd(component);
  },

  showCancelPopUp: function(component, event) {
    var modalCancelTab = component.find("modalCancelId");
    $A.util.removeClass(modalCancelTab, 'slds-hide');
    $A.util.addClass(modalCancelTab, 'slds-show');
  },

  hideCancelPopUp: function(component, event) {
    var modalCancelTab = component.find("modalCancelId");
    $A.util.removeClass(modalCancelTab, 'slds-show');
    $A.util.addClass(modalCancelTab, 'slds-hide');
  },

  hideCancelPopUpandDelete: function(component, event, helper) {
    var modalCancelTab = component.find("modalCancelId");
    $A.util.removeClass(modalCancelTab, 'slds-show');
    $A.util.addClass(modalCancelTab, 'slds-hide');
    helper.cancelProd(component);
    helper.initProdAction(component);
    $A.get('e.force:refreshView').fire();
  },

  oppCategorySelection: function(component, event, helper) {
    var categoryValue = component.get("v.oppCategoryValue");
    var SubCategoryMap = component.get("v.categoryToSubcategoryMap");
    component.set("v.oppCancellationLostValue", null);
    component.set("v.oppCancellationLostValues", null);
    component.set('v.oppSubCategoryValues', SubCategoryMap[categoryValue]);
  },

  oppSubCategorySelection: function(component, event, helper) {
    var subCategoryValue = component.get("v.oppSubCategoryValue");
    var SubCategoryCancellationMap = component.get("v.SubcategoryToCancelLossReasonMap");
    component.set('v.oppCancellationLostValues', SubCategoryCancellationMap[subCategoryValue]);
  },

  oppCancellationSelection: function(component, event, helper) {
    var categoryValue = component.get("v.oppCategoryValue");
    var subCategoryValue = component.get("v.oppSubCategoryValue");
    var cancellationValue = component.get("v.oppCancellationLostValue");
    var oppDetailsErrorMessage = component.find("addOppErrorMessageId");
    var saveFooter = component.find("saveFooterId");
    var nextFooter = component.find("nextFooterId");
    var mainFooter = component.find("mainFooterId");
    var showSaveFooter = true;
    helper.nullifyCancellationFields(component, event);
    console.log("Cancellation value == " + cancellationValue);
    if (categoryValue == null || categoryValue == "--none--" ||
      subCategoryValue == null || subCategoryValue == "--none--" ||
      cancellationValue == null || cancellationValue == "--none--") {
      $A.util.removeClass(oppDetailsErrorMessage, "slds-hide");
      $A.util.addClass(oppDetailsErrorMessage, "slds-show");
    } else {
      $A.util.removeClass(oppDetailsErrorMessage, "slds-show");
      $A.util.addClass(oppDetailsErrorMessage, "slds-hide");
      if (cancellationValue == "Missing Product Feature" &&
        (component.get("v.opportunityObj.Missing_Product_Feature__c") != null ||
          component.get("v.opportunityObj.Missing_Product_Feature__c") != " ")) {
        showSaveFooter = false;
      } else if ((cancellationValue == "Competition-Product/Feature Driven") &&
        ((component.get("v.opportunityObj.Missing_Product_Feature__c") != null ||
            component.get("v.opportunityObj.Missing_Product_Feature__c") != " ") ||
          (component.get("v.opportunityObj.Competitor__c") != null ||
            component.get("v.opportunityObj.Competitor__c") != " "))) {
        showSaveFooter = false;
      } else if (cancellationValue == "Initial Out Clause" &&
        (component.get("v.opportunityObj.Initial_Out_Clause_Description__c") != null ||
          component.get("v.opportunityObj.Initial_Out_Clause_Description__c") != " ")) {
        showSaveFooter = false;
      } else if (cancellationValue == "Aggregation through a Partner (Pick Partner)" &&
        (component.get("v.opportunityObj.Aggregation_Partner__c") != null ||
          component.get("v.opportunityObj.Aggregation_Partner__c") != " ")) {
        showSaveFooter = false;
      } else if (cancellationValue == "Contract Consolidation with Akamai Customer" &&
        (component.get("v.opportunityObj.Consolidation_Account__c") != null ||
          component.get("v.opportunityObj.Consolidation_Account__c") != " ")) {
        showSaveFooter = false;
      } else if (cancellationValue == "Competition-Product/Performance Driven" &&
        (component.get("v.opportunityObj.Competitor__c") != null ||
          component.get("v.opportunityObj.Competitor__c") != " ")) {
        showSaveFooter = false;
      } else if (cancellationValue == "Competition Price Driven" &&
        (component.get("v.opportunityObj.Competitor__c") != null ||
          component.get("v.opportunityObj.Competitor__c") != " ")) {
        showSaveFooter = false;
      } else if (cancellationValue == "Will not accept Akamai Terms and Conditions" &&
        (component.get("v.opportunityObj.Unacceptable_Terms_and_Conditions__c") != null ||
          component.get("v.opportunityObj.Unacceptable_Terms_and_Conditions__c") != " ")) {
        showSaveFooter = false;
      }
    }
    if (showSaveFooter) {
      $A.util.removeClass(mainFooter, "slds-show");
      $A.util.addClass(mainFooter, "slds-hide");
      $A.util.removeClass(nextFooter, "slds-show");
      $A.util.addClass(nextFooter, "slds-hide");
      $A.util.removeClass(saveFooter, "slds-hide");
      $A.util.addClass(saveFooter, "slds-show");
    } else {
      console.log("In Next Button logic");
      $A.util.removeClass(mainFooter, "slds-show");
      $A.util.addClass(mainFooter, "slds-hide");
      $A.util.removeClass(saveFooter, "slds-show");
      $A.util.addClass(saveFooter, "slds-hide");
      $A.util.removeClass(nextFooter, "slds-hide");
      $A.util.addClass(nextFooter, "slds-show");
    }
  },

  addOppDetailsNextAction: function(component, event, helper) {
    var cancellationValue = component.get("v.oppCancellationLostValue");
    helper.hideOppPicklistAndShowCancellationFieldsSection(component, event);
    helper.hideNextFooterAndShowSaveFooter(component, event);

    if (cancellationValue == "Missing Product Feature") {
      helper.showMissingFeatureField(component, event);
    } else if (cancellationValue == "Competition-Product/Feature Driven") {
      if (component.get("v.opportunityObj.Missing_Product_Feature__c") != null ||
        component.get("v.opportunityObj.Missing_Product_Feature__c") != " ") {
        helper.showMissingFeatureField(component, event);
      }
      if (component.get("v.opportunityObj.Competitor__c") != null ||
        component.get("v.opportunityObj.Competitor__c") != " " ||
        component.get("v.opportunityObj.Competitor__c") != "undefined") {
        helper.fetchCompetitorValues(component, event);
        helper.showCompetitorField(component, event);
      }
    } else if (cancellationValue == "Initial Out Clause") {
      helper.showInitialOutOfClauseField(component, event);
    } else if (cancellationValue == "Aggregation through a Partner (Pick Partner)") {
      helper.fetchAggregationPartnerValues(component, event);
      helper.showAggregationPartnerField(component, event);
    } else if (cancellationValue == "Contract Consolidation with Akamai Customer") {
      helper.showConsolidationAccountField(component, event);
    } else if (cancellationValue == "Competition-Product/Performance Driven") {
      helper.fetchCompetitorValues(component, event);
      helper.showCompetitorField(component, event);
    } else if (cancellationValue == "Will not accept Akamai Terms and Conditions") {
      helper.showUnacceptableTermsAndConditionsField(component, event);
    } else if (cancellationValue == "Competition Price Driven") {
      helper.fetchCompetitorValues(component, event);
      helper.showCompetitorField(component, event);
    }

  },

  addOppDetailsBackAction: function(component, event, helper) {
    helper.hideCancellationFieldsSectionAndShowOppPicklist(component, event);
    helper.hideBackSaveFooterAndShowMainFooter(component, event);
    helper.hideCancellationFields(component, event);
    var cancellationErrorMessage = component.find("cancellationErrorMessageId");
    $A.util.removeClass(cancellationErrorMessage, "slds-show");
    $A.util.addClass(cancellationErrorMessage, "slds-hide");
  },

  addOppDetailsCancelAction: function(component, event, helper) {
    helper.hideAddOppDetailsSection(component, event);
    helper.nullifyCancellationFields(component, event);
    helper.nullifyCancellationPicklistFields(component, event);
    var cancellationErrorMessage = component.find("cancellationErrorMessageId");
    $A.util.removeClass(cancellationErrorMessage, "slds-show");
    $A.util.addClass(cancellationErrorMessage, "slds-hide");
    var oppDetailsErrorMessage = component.find("addOppErrorMessageId");
    $A.util.removeClass(oppDetailsErrorMessage, "slds-show");
    $A.util.addClass(oppDetailsErrorMessage, "slds-hide");
  },

  addOppDetailsSaveAction: function(component, event, helper) {
    helper.validateFieldValue(component, event);
  },


})