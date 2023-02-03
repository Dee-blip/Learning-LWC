({
  performAddProductInit: function(component, event, helper) {
    console.log("oppId == " + component.get("v.oppId"));
    console.log("Opp == " + component.get("v.opportunityObj.Id"));
    if (component.get("v.opportunityObj") != null) {
      component.set("v.productNames", null);
      component.set("v.productNamesMap", null);
      component.set("v.oppLineItemObject.Product2Id", null);
      component.set("v.oppLineItemObject.PricebookEntryId", null);
      component.set("v.carrierAppValue", null);
      component.set("v.carrierAppValues", null);
      component.set("v.oppLineItemObject.OpportunityId", null);
      helper.nullifyCancellationFields(component, event);
      helper.nullifyCancellationPicklistFields(component, event);
      console.log('Opportunity Obj in Add Product == ' +
        component.get("v.opportunityObj.Missing_Product_Feature__c"));
      console.log('Opportunity Obj in Category == ' +
        component.get("v.opportunityObj.Opportunity_Category__c"));
      var prodNames = component.get('c.getInitValues');
      prodNames.setParam('oppRec', component.get("v.opportunityObj"));
      prodNames.setCallback(this, function(resp) {
        if (component.isValid()) {
          console.log(resp.getState());
          if (resp.getState() === 'SUCCESS') {
            var names = [];
            // SFDC-3714
            names.push("--None--");
            var returnValObj = resp.getReturnValue();
            var productsMap = JSON.parse(returnValObj['ProductNamesMap']);
            var splForecastCategory = JSON.parse(returnValObj['SFC_PKL_Vals']);
            console.log(returnValObj['isSpecialistUser']);
            if(returnValObj['isSpecialistUser'] == "true") {
              component.set("v.isSpecialistUser", true);
            } else {
              component.set("v.isSpecialistUser", false);
            }
            var opportunityForecastCategory = component.get("v.opportunityObj.ForecastCategoryName");
            component.set("v.splForecastCategoryFld", opportunityForecastCategory);
            for(var key in splForecastCategory) {
              if(splForecastCategory[key].value == opportunityForecastCategory) {
                splForecastCategory[key].isSelected = true;
              }
            }
            var noneField = {label: '--None--', value: null, isSelected: false};
            splForecastCategory.unshift(noneField);
            component.set("v.splForecastCategory", splForecastCategory);
            console.log(component.get("v.splForecastCategory"));
            //SFDC-3714 END
            console.log('. Value is: ' + productsMap[1]);
            for (var key in productsMap) {
              names.push(key);
            }

            component.set("v.productNames", names);
            component.set("v.productNamesMap", productsMap);
            component.set("v.oppLineItemObject.Projected_Monthly_commit_fees__c", 0);
            component.set("v.oppLineItemObject.Projected_Avg_Rev_Non_Commit__c", 0);
            component.set("v.oppLineItemObject.NRR__c", 0);
            component.set("v.oppLineItemObject.OpportunityId", component.get("v.opportunityObj.Id"));
            component.set("v.oppLineItemObject.Specialist_Close_Date__c", component.get("v.opportunityObj.CloseDate"));
          }
        } else {
          console.log('request failed');
          console.log(resp);
          console.log(resp.error[0]);
        }
      }, 'ALL');
      $A.enqueueAction(prodNames);
    }

  },
  // SFDC-3714
  touchedMonCmtFld: function(component, event, helper) {
    component.set("v.splProMonComTouched", true);
  },

  // touchedMonUsgFld: function(component, event, helper) {
  //   component.set("v.splProMonUsgTouched", true);
  // },

  touchedSplForecastCat: function(component, event, helper) {
    component.set("v.splForecastCategoryTouched", true);
  },
  touchedSplCloseDate: function(component, event, helper) {
    component.set("v.splCloseDateTouched", true);
  },
  touchedOneTimeFee: function(component, event, helper) {
    component.set("v.specialistOneTimeFeeTouched", true);
  },

  updateSpecialistOneTimeFee: function(component, event, helper) {
    if(!component.get("v.specialistOneTimeFeeTouched")) {
      component.set("v.specialistOneTimeFee", component.get("v.oppLineItemObject.NRR__c"));
    }
  },
  // updateSpcltMonUsgFld: function(component, event, helper) {
  //   if(!component.get("v.splProMonUsgTouched")) {
  //     component.set("v.splProMonUsgFld", component.get("v.proMonUsgFld"));
  //   }
  // },

  updateSpcltMonCmtFld: function(component, event, helper) {
    if(!component.get("v.splProMonComTouched")) {
      component.set("v.splProMonComFld", component.get("v.proMonComFld"));
    }
  },
  //SFDC-3714 END
  productSelection: function(component, event, helper) {
    var productName = component.get("v.oppLineItemObject.Product2Id");
    var oppCarrierApplicationValue = component.get("v.opportunityObj.Carrier_Application__c");
    console.log('Product Name = ' + component.get("v.oppLineItemObject.Product2Id"));
    component.set("v.carrierAppValue", null);
    component.set("v.oppCategoryValue", null);
    component.set("v.oppSubCategoryValue", null);
    component.set("v.oppCancellationLostValue", null);
    var errorMessage = component.find("ErrorMessageId");
    var productsMap = component.get("v.productNamesMap");
    console.log("Product Id for the name == " + productsMap[productName]);
    var addCarrierApplication = component.find("addCarrierApplicationId");
    console.log("oppCarrierApplicationValue == " + oppCarrierApplicationValue);
    if ((productName == "Network Operator - Hardware" ||
        productName == "Network Operator - Software/Services") &&
      (oppCarrierApplicationValue == null ||
        oppCarrierApplicationValue == " ")) {
      $A.util.removeClass(addCarrierApplication, 'slds-hide');
      $A.util.addClass(addCarrierApplication, 'slds-show');
      var loadCarrierApp = component.get("c.fetchPicklistValues");
      loadCarrierApp.setParams({
        "sobjectName": "Opportunity",
        "picklistFieldName": "Carrier_Application__c"
      });
      loadCarrierApp.setCallback(this, function(response) {
        var state = response.getState();
        var options = response.getReturnValue();
        if (component.isValid() && state === "SUCCESS") {
          component.set("v.carrierAppValues", options);

        }
      });
      $A.enqueueAction(loadCarrierApp);
    } else {
      $A.util.removeClass(addCarrierApplication, 'slds-show');
      $A.util.addClass(addCarrierApplication, 'slds-hide');
    }
    helper.populatePriceBookEntry(component, helper);

  },



  hideAddCarrierApplication: function(component, event, helper) {
    helper.hideCarrierApplication(component);
    component.set("v.carrierAppValue", null);
    var getAllId = component.find("boxPack");
    for (var i = 0; i < getAllId.length; i++) {
      component.find("boxPack")[i].set("v.value", false);
    }
  },

  saveCarrierApplication: function(component, event, helper) {
    var carrierAppError = component.find("v.carrierErrorMessageId");
    var carrierAppValue = component.get("v.carrierAppValue");
    var values = [];
    var getAllId = component.find("boxPack");
    var valueSelected = false;
    var selectedValues = null;
    if (!Array.isArray(getAllId)) {
      getAllId = [getAllId];
    }
    for (var i = 0; i < getAllId.length; i++) {
      if (getAllId[i].get("v.value") == true) {
        valueSelected = true;
        values.push(getAllId[i].get("v.text"));
      }
    }
    //console.log("getAllId == "+getAllId[1]);
    //console.log("Values Selected = "+values);
    if (!valueSelected) {
      console.log("If not selected");
    } else {
      for (var i = 0; i < values.length; i++) {
        if (i == 0)
          selectedValues = values[i];
        else
          selectedValues = selectedValues + ";" + values[i];

      }

      console.log("Values Selected = " + values);
      console.log("selectedValues = " + selectedValues);
      component.set("v.carrierAppValue", selectedValues);
      helper.hideCarrierApplication(component);
    }
  },

  showSpinner: function(cmp, event, helper) {
    var spinner = cmp.find("ltngSpinnerAddProd");
    $A.util.removeClass(spinner, "slds-hide");
    $A.util.addClass(spinner, "slds-show");

  },

  hideSpinner: function(cmp, event, helper) {
    var spinner = cmp.find("ltngSpinnerAddProd");
    $A.util.removeClass(spinner, "slds-show");
    $A.util.addClass(spinner, "slds-hide");
  },

  toggleSpinner: function(cmp, event) {
    var spinner = cmp.find("ltngSpinnerAddProd");
    $A.util.toggleClass(spinner, "slds-show");
  },

  saveProductAction: function(component, event, helper) {
    var projMonthlyValue = component.get("v.proMonComFld");
    var oppDetailsTab = component.find("addOppDetailsId");
    var oppCancellationValue = component.get("v.opportunityObj.Loss_Reason__c");
    var oppCancellationCompValue = component.get("v.oppCancellationLostValue");
    var prodName = component.get("v.oppLineItemObject.Product2Id");
    var ProductError = component.find("prodErrorMessageId");
    var oppCarrierAppValue = component.get("v.opportunityObj.Carrier_Application__c");
    var CarrierAppValue = component.get("v.carrierAppValue");
    var addEmergingApplication = component.find("addOpportunityInfoId");
    var addCarrierApplication = component.find("addCarrierApplicationId");
    var termRequired = component.get("v.termRequired");
    var termErrorMessage = component.find("termErrorMessageId");
    var termValue = component.find("TermValue").get("v.value");
      //alert(termValue);
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
    //helper.populatePriceBookEntry(component, event);
    console.log("Cancellation Value in Save == " + component.get("v.oppCancellationLostValue"));
    if (prodName == "--None--" || prodName == null || prodName == " ") {
      $A.util.removeClass(ProductError, "slds-hide");
      $A.util.addClass(ProductError, "slds-show");
    } else {
      $A.util.removeClass(ProductError, "slds-show");
      $A.util.addClass(ProductError, "slds-hide");
      if (((prodName == "Network Operator - Hardware" || prodName == "Network Operator - Software/Services") &&
          (oppCarrierAppValue == null && CarrierAppValue == null))) {
          $A.util.removeClass(addCarrierApplication, 'slds-hide');
          $A.util.addClass(addCarrierApplication, 'slds-show');
          var loadCarrierApp = component.get("c.fetchPicklistValues");
          loadCarrierApp.setParams({
            "sobjectName": "Opportunity",
            "picklistFieldName": "Carrier_Application__c"
          });
          loadCarrierApp.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            if (component.isValid() && state === "SUCCESS") {
              component.set("v.carrierAppValues", options);

            }
          });
          $A.enqueueAction(loadCarrierApp);
      } else {
        var negativeProductAction = component.get("c.checkBaselineNegativeAmount");
        var negativeValue = false;
        negativeProductAction.setParams({
          "oppId": component.get("v.opportunityObj.Id")
        });
        negativeProductAction.setCallback(this, function(response) {
          var state = response.getState();
          console.log("State in Check Negative= " + state);
          console.log("negativeValue in Check Negative= " + negativeValue);
          if (component.isValid() && state === "SUCCESS") {
            console.log("Negative Value == " + response.getReturnValue());
            negativeValue = response.getReturnValue();
            if (projMonthlyValue < 0 || negativeValue) {
              if ((oppCancellationValue == null ||
                  oppCancellationValue == " ") &&
                (oppCancellationCompValue == null ||
                  oppCancellationCompValue == "--none--")) {
                console.log('Negative Value');
                helper.loadoppSubCategoryValues(component, event);
                helper.loadoppSubCategoryToCancellationValues(component, event);
                $A.util.removeClass(oppDetailsTab, "slds-hide");
                $A.util.addClass(oppDetailsTab, "slds-show");
              } else {
                $A.util.removeClass(oppDetailsTab, "slds-show");
                $A.util.addClass(oppDetailsTab, "slds-hide");
                helper.performOppSaveAndProductCreation(component, event);
              }
            } else {
              //helper.populatePriceBookEntry(component,event);
              console.log("In else Product Add =====");
              $A.util.removeClass(oppDetailsTab, "slds-show");
              $A.util.addClass(oppDetailsTab, "slds-hide");
              helper.performOppSaveAndProductCreation(component, event);
            }
          }
        });
        $A.enqueueAction(negativeProductAction);

      }
    }
  },

  oppCategorySelection: function(component, event, helper) {
    var categoryValue = component.get("v.oppCategoryValue");
    var SubCategoryMap = component.get("v.categoryToSubcategoryMap");
    component.set("v.oppCancellationLostValue", null);
    component.set("v.oppCancellationLostValues", null);
    component.set('v.oppCancellationLostValues',SubCategoryMap[categoryValue]);
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
    var Value = "Missing Product Feature,Aggregated Through Partner,Contract Consolidation,Competition - Features/Performance,Competition - Price";
    var showSaveFooter = true;
    helper.nullifyCancellationFields(component, event);
    console.log("Cancellation value == " + cancellationValue);
    if (categoryValue == null || categoryValue == "--none--" || 
      cancellationValue == null || cancellationValue == "--none--") {
      $A.util.removeClass(oppDetailsErrorMessage, "slds-hide");
      $A.util.addClass(oppDetailsErrorMessage, "slds-show");
    }
      console.log("In Next Button logic");
      $A.util.removeClass(mainFooter, "slds-show");
      $A.util.addClass(mainFooter, "slds-hide");

      if(!Value.includes(cancellationValue)){

        $A.util.removeClass(nextFooter, "slds-show");
        $A.util.addClass(nextFooter, "slds-hide");
        $A.util.removeClass(saveFooter, "slds-hide");
        $A.util.addClass(saveFooter, "slds-show");

      }
      else{

          $A.util.removeClass(saveFooter, "slds-show");
          $A.util.addClass(saveFooter, "slds-hide");
          $A.util.removeClass(nextFooter, "slds-hide");
          $A.util.addClass(nextFooter, "slds-show");

      }
    
  },


  addOppDetailsNextAction: function(component, event, helper) {
    var values = "Aggregated Through Partner,Re-qualify,Contract Consolidation,Competition - Features/Performance,Competition - Price,Missing Product Feature,Onboarding Issues,Other,Poorly Qualified,Technical Incompatibility";
    var cancellationValue = component.get("v.oppCancellationLostValue");
    var additionalLossDetail = component.get("v.additionalLossValue");
    var additionalLossDetaillabel = component.find("AdditionalLossDetail");
    var AdditionalLossDetailRequired = component.get("v.AdditionalLossDetailRequired");
    console.log('additionalLossDetail:'+additionalLossDetail);

    if(AdditionalLossDetailRequired && values.includes(cancellationValue) && (additionalLossDetail == "" ||  typeof additionalLossDetail == 'undefined' )){
      console.log('Inside if');
      component.set("v.AdditionalLossDetailError", "Please provide more information about why this Loss Reason was selected.");
      $A.util.removeClass(additionalLossDetaillabel,"slds-hide");
      $A.util.addClass(additionalLossDetaillabel,"slds-show");
      return;
    }else{
      console.log('Inside else');
      $A.util.removeClass(additionalLossDetaillabel, "slds-show");
      $A.util.addClass(additionalLossDetaillabel,"slds-hide");
    }

    helper.hideOppPicklistAndShowCancellationFieldsSection(component, event);
    helper.hideNextFooterAndShowSaveFooter(component, event);

    if (cancellationValue == "Missing Product Feature") {
      helper.showMissingFeatureField(component, event);
    } else if (cancellationValue == "Competition - Features/Performance") {
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
    }else if (cancellationValue == "Aggregated Through Partner") {
      helper.fetchAggregationPartnerValues(component, event);
      helper.showAggregationPartnerField(component, event);
    } else if (cancellationValue == "Contract Consolidation") {
      helper.showConsolidationAccountField(component, event);
    } else if (cancellationValue == "Competition - Features/Performance") {
      helper.fetchCompetitorValues(component, event);
      helper.showCompetitorField(component, event);
    } else if (cancellationValue == "Competition - Price") {
      helper.fetchCompetitorValues(component, event);
      helper.showCompetitorField(component, event);
    }

  },

  handleCompetitorOnChange : function(component,event,helper) {
    var selectedCompetitor = component.get("v.competitorValue");
    if (selectedCompetitor.indexOf("Other") != -1 ) {
        helper.showOtherCompetitorField(component,event);
    }
    else {
      helper.hideOtherCompetitorField(component,event);
    }
  },

  addOppDetailsBackAction: function(component, event, helper) {
    helper.hideCancellationFieldsSectionAndShowOppPicklist(component, event);
    helper.hideBackSaveFooterAndShowMainFooter(component, event);
    helper.hideCancellationFields(component, event);
    helper.hideOtherCompetitorField(component,event);
    var cancellationErrorMessage = component.find("cancellationErrorMessageId");
    $A.util.removeClass(cancellationErrorMessage, "slds-show");
    $A.util.addClass(cancellationErrorMessage, "slds-hide");

    var otherCompetitorNameError = component.find("otherCompetitorNameErrorId");
    $A.util.removeClass(otherCompetitorNameError, "slds-show");
    $A.util.addClass(otherCompetitorNameError, "slds-hide");
  },

  addOppDetailsCancelAction: function(component, event, helper) {
    helper.hideAddOppDetailsSection(component, event);
    helper.nullifyCancellationFields(component, event);
    helper.nullifyCancellationPicklistFields(component, event);
    var cancellationErrorMessage = component.find("cancellationErrorMessageId");
    $A.util.removeClass(cancellationErrorMessage, "slds-show");
    $A.util.addClass(cancellationErrorMessage, "slds-hide");

    var otherCompetitorNameError = component.find("otherCompetitorNameErrorId");
    $A.util.removeClass(otherCompetitorNameError, "slds-show");
    $A.util.addClass(otherCompetitorNameError, "slds-hide");
  },

  addOppDetailsSaveAction: function(component, event, helper) {
    var values = "Aggregated Through Partner,Re-qualify,Contract Consolidation,Competition - Features/Performance,Competition - Price,Missing Product Feature,Onboarding Issues,Other,Poorly Qualified,Technical Incompatibility";
    var cancellationValue = component.get("v.oppCancellationLostValue");
    var additionalLossDetail = component.get("v.additionalLossValue");
    var additionalLossDetaillabel = component.find("AdditionalLossDetail");
    var selectedCompetitor = component.get("v.competitorValue");
    var otherCompetitorName = component.get("v.otherCompetitorName");
    var otherCompetitorNameError = component.find("otherCompetitorNameErrorId");
    var AdditionalLossDetailRequired = component.get("v.AdditionalLossDetailRequired");
    console.log('additionalLossDetail:'+additionalLossDetail);

    if(selectedCompetitor != null && selectedCompetitor.indexOf("Other") != -1 && otherCompetitorName == undefined) {
            $A.util.removeClass(otherCompetitorNameError, "slds-hide");
            $A.util.addClass(otherCompetitorNameError, "slds-show");
           return;
    }

    if(AdditionalLossDetailRequired && values.includes(cancellationValue) && (additionalLossDetail == "" ||  typeof additionalLossDetail == 'undefined' ) ){
      console.log('Inside if');
      component.set("v.AdditionalLossDetailError", "Please provide more information about why this Loss Reason was selected.");
      $A.util.removeClass(additionalLossDetaillabel,"slds-hide");
      $A.util.addClass(additionalLossDetaillabel,"slds-show");
      return;
    }else{
      console.log('Inside else');
      $A.util.removeClass(additionalLossDetaillabel, "slds-show");
      $A.util.addClass(additionalLossDetaillabel,"slds-hide");
    }
    helper.validateFieldValue(component, event);
  },

  backProductAction: function(component, event, helper) {
    var evntOppProductViewNavigate = $A.get("e.c:invokeOppProdDetailsInit");
    evntOppProductViewNavigate.fire();
  },

  selectCarrierApp: function(component, event, helper) {
    console.log("Selected Value == " + event.getSource().get("v.text"));
  },
})