({
  saveProd: function(component) {

    console.log("Page Object in Helper == " + JSON.stringify(component.get("v.oppLineItemObj")));
    var EditOppTab = component.find("editOnlyProdInfoId");
    var ReadOppTab = component.find("readOnlyProdInfoId");
    var delBtn = component.find("DeleteProdBtnId");
    var saveBtn = component.find("SaveProdBtnId");
    var editBtn = component.find("EditProdBtnId");
    var cancelEditBtn = component.find("CancelEditProdBtnId");
    var cancelBtn = component.find("CancelProdBtnId");
    var backBtn = component.find("BackProdBtnId");
    var action = component.get("c.saveProductObj");
    $A.util.removeClass(EditOppTab, 'slds-show');
    $A.util.addClass(EditOppTab, 'slds-hide');
    $A.util.removeClass(cancelEditBtn, 'slds-show');
    $A.util.addClass(cancelEditBtn, 'slds-hide');
    $A.util.removeClass(saveBtn, 'slds-show');
    $A.util.addClass(saveBtn, 'slds-hide');
    $A.util.removeClass(delBtn, 'slds-hide');
    $A.util.addClass(delBtn, 'slds-show');
    $A.util.removeClass(backBtn, 'slds-hide');
    $A.util.addClass(backBtn, 'slds-show');
    $A.util.removeClass(cancelBtn, 'slds-hide');
    $A.util.addClass(cancelBtn, 'slds-show');
    $A.util.removeClass(editBtn, 'slds-hide');
    $A.util.addClass(editBtn, 'slds-show');
    $A.util.removeClass(ReadOppTab, 'slds-hide');
    $A.util.addClass(ReadOppTab, 'slds-show');

    action.setParams({
      "pageObject": component.get("v.oppLineItemObj")
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var message = response.getReturnValue();
      console.log("State = " + state);
      var baseLineProdFlagValue = false;

      if (component.isValid() && state === "SUCCESS" && message != null) {
        console.log("After Save Success");
        var OppLine = response.getReturnValue();
        if (OppLine.Average_Renewal_Commit_MRR__c != null ||
          OppLine.Average_Renewal_Usage_MRR__c != null) {
          component.set('v.baseLineProdFlag', "true");
          component.set('v.baseLineProdFlagValue', "color:green");
          baseLineProdFlagValue = true;
        }

        if (OppLine.Average_Renewal_Commit_MRR__c < 0) {
          component.set('v.baseLineMonthlyCommitFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.baseLineMonthlyCommitFlag', "black");
        }

        if (OppLine.Projected_Monthly_commit_fees__c < 0) {
          console.log("In baseLineMonthlyCommit < 0 === ");
          component.set('v.projectedMonthlyCommitFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.projectedMonthlyCommitFlag', "black");
        }

        if (OppLine.NRR__c < 0) {
          component.set('v.oneTimeFeeFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.oneTimeFeeFlag', "black");
        }

        if (OppLine.UnitPrice < 0) {
          component.set('v.NetMRRFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.NetMRRFlag', "black");
        }

        if (OppLine.Average_Renewal_Usage_MRR__c < 0) {
          component.set('v.baselineMonthlyUsageFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.baselineMonthlyUsageFlag', "black");
        }

        if (OppLine.Projected_Avg_Rev_Non_Commit__c < 0) {
          component.set('v.projectedMonthlyFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.projectedMonthlyFlag', "black");
        }

        if (OppLine.Net_Non_Commit__c < 0) {
          component.set('v.netMonthlyFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.netMonthlyFlag', "black");
        }

        if (OppLine.EMRI__c < 0) {
          component.set('v.EMRIFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.EMRIFlag', "black");
        }

        component.set('v.CurrencyValue', OppLine.Opportunity.CurrencyIsoCode + " ");
        component.set('v.oppLineItemObj', OppLine);
        console.log("Average_Renewal_Commit_MRR__c in Save == " + OppLine.Average_Renewal_Commit_MRR__c);
        if (OppLine.Average_Renewal_Commit_MRR__c != null)
          component.set('v.AverageRenewalCommitMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Commit_MRR__c).toFixed(2));
        else
          component.set('v.AverageRenewalCommitMRRVal', null);
        if (OppLine.Projected_Monthly_commit_fees__c != null)
          component.set('v.ProjectedMonthlycommitfeesVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Monthly_commit_fees__c).toFixed(2));
        else
          component.set('v.ProjectedMonthlycommitfeesVal', null);
        component.set('v.NRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.NRR__c).toFixed(2));
        component.set('v.UnitPriceVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.UnitPrice).toFixed(2));
        if (OppLine.Average_Renewal_Usage_MRR__c != null)
          component.set('v.AverageRenewalUsageMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Usage_MRR__c).toFixed(2));
        else
          component.set('v.AverageRenewalUsageMRRVal', null);
        if (OppLine.Projected_Avg_Rev_Non_Commit__c != null)
          component.set('v.ProjectedAvgRevNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Avg_Rev_Non_Commit__c).toFixed(2));
        else
          component.set('v.ProjectedAvgRevNonCommitVal', null);
        component.set('v.NetNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Net_Non_Commit__c).toFixed(2));
        component.set('v.EMRIVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.EMRI__c).toFixed(2));
      } else if (component.isValid() && state === "SUCCESS" && message !== 'success') {
        $A.util.removeClass(EditOppTab, 'slds-hide');
        $A.util.addClass(EditOppTab, 'slds-show');
        $A.util.removeClass(cancelEditBtn, 'slds-hide');
        $A.util.addClass(cancelEditBtn, 'slds-show');
        $A.util.removeClass(saveBtn, 'slds-hide');
        $A.util.addClass(saveBtn, 'slds-show');
        $A.util.removeClass(delBtn, 'slds-hide');
        $A.util.addClass(delBtn, 'slds-hide');
        $A.util.removeClass(backBtn, 'slds-show');
        $A.util.addClass(backBtn, 'slds-hide');
        $A.util.removeClass(cancelBtn, 'slds-show');
        $A.util.addClass(cancelBtn, 'slds-hide');
        $A.util.removeClass(editBtn, 'slds-show');
        $A.util.addClass(editBtn, 'slds-hide');
        $A.util.removeClass(ReadOppTab, 'slds-show');
        $A.util.addClass(ReadOppTab, 'slds-hide');
        alert(message);
      }

    });

    $A.enqueueAction(action);

  },

  deleteProd: function(component) {

    console.log("Page Object in Helper == " + JSON.stringify(component.get("v.oppLineItemObj")));
    var action = component.get("c.deleteProductObj");
    action.setParams({
      "pageObject": component.get("v.oppLineItemObj")
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var message = response.getReturnValue();
      console.log("State in Delete = " + state);
      if (component.isValid() && state === "SUCCESS" && message === 'success') {
        var evntOppProductNavigate = $A.get("e.c:invokeOppProdDetailsInit");
        evntOppProductNavigate.fire();

      } else if (component.isValid() && state === "SUCCESS" && message !== 'success') {
        //cmp.set("v.message",message);
        //cmp.set("v.showError",true);
      }

    });

    $A.enqueueAction(action);

  },

  cancelProd: function(component) {

    console.log("Page Object in Helper == " + JSON.stringify(component.get("v.oppLineItemObj")));
    var action = component.get("c.cancelProductObj");
    action.setParams({
      "pageObject": component.get("v.oppLineItemObj")
    });

    action.setCallback(this, function(response) {
      var state = response.getState();
      var message = response.getReturnValue();
      console.log("State = " + state);

      if (component.isValid() && state === "SUCCESS" && message === 'success') {

      } else if (component.isValid() && state === "SUCCESS" && message !== 'success') {
        //cmp.set("v.message",message);
        //cmp.set("v.showError",true);
      }

    });

    $A.enqueueAction(action);

  },

  initProdAction: function(component) {
    console.log(component.get("v.OppLineItemId") + '====');
    var baseLineProdFlagValue = false;
    //var OppLine = component.get("v.oppLineItemObj");
    component.set('v.baseLineProdFlagValue', "color:black");
    component.set('v.baseLineProdFlag', "false");
    if (component.get("v.OppLineItemId") != null) {
      // SFDC-3714
      var fetchOppLine = component.get('c.fetchOpportunityLineItemWrapperFunction');
      fetchOppLine.setParam('oppLineItemObjId', component.get("v.OppLineItemId"));
      fetchOppLine.setCallback(this, function(resp) {
        if (component.isValid()) {
          if (resp.getState() === 'SUCCESS') {
            var returnValObj = resp.getReturnValue();
            var OppLine = returnValObj['OpportunityLineItem'];
            var splForecastCategory = JSON.parse(returnValObj['SFC_PKL_Vals']);
            var splForecastCategoryFld = OppLine.Specialist_Forecast_Category__c;
            for(var key in splForecastCategory) {
              if(splForecastCategory[key].value == splForecastCategoryFld) {
                splForecastCategory[key].isSelected = true;
              }
            }
            var noneField = {label: '--None--', value: null, isSelected: false};
            splForecastCategory.unshift(noneField);
            component.set("v.splForecastCategory", splForecastCategory);

            component.set("v.isSpecialistUser", returnValObj['isSpecialistUser']);

            component.set("v.splProMonComTouched", OppLine.Specialist_Touched__c);
            component.set("v.splProMonComFld", OppLine.Specialist_Projected_Monthly_Commit__c);
            component.set("v.proMonComFld", OppLine.Projected_Monthly_commit_fees__c);

            // component.set("v.splProMonUsgTouched", OppLine.Specialist_Usage_Touched__c);
            // component.set("v.splProMonUsgFld", OppLine.Specialist_Projected_Monthly_Usage__c);
            component.set("v.proMonUsgFld", OppLine.Projected_Avg_Rev_Non_Commit__c);
            component.set("v.specialistOneTimeFee", OppLine.Specialist_NRR__c);
            component.set("v.specialistOneTimeFeeTouched", OppLine.Specialist_NRR_Touched__c);

            component.set("v.splForecastCategoryTouched", OppLine.Specialist_Forecast_Touched__c);
            component.set("v.splForecastCategoryFld", OppLine.Specialist_Forecast_Category__c);
            component.set("v.splCloseDateTouched", OppLine.Specialist_Close_Date_Touched__c);
            component.set("v.splCloseDateFld", OppLine.Specialist_Close_Date__c);
            component.set("v.termValue", OppLine.Term__c);
            //SFDC-3714 - END
            if (OppLine.Average_Renewal_Commit_MRR__c != null ||
              OppLine.Average_Renewal_Usage_MRR__c != null) {
              component.set('v.baseLineProdFlag', "true");
              component.set('v.baseLineProdFlagValue', "color:green");
              baseLineProdFlagValue = true;
            }
            if (OppLine.Average_Renewal_Commit_MRR__c < 0) {
              component.set('v.baseLineMonthlyCommitFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.baseLineMonthlyCommitFlag', "black");
            }

            if (OppLine.Projected_Monthly_commit_fees__c < 0) {
              console.log("In baseLineMonthlyCommit < 0 === ");
              component.set('v.projectedMonthlyCommitFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.projectedMonthlyCommitFlag', "black");
            }

            if (OppLine.NRR__c < 0) {
              component.set('v.oneTimeFeeFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.oneTimeFeeFlag', "black");
            }

            if (OppLine.UnitPrice < 0) {
              component.set('v.NetMRRFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.NetMRRFlag', "black");
            }

            if (OppLine.Average_Renewal_Usage_MRR__c < 0) {
              component.set('v.baselineMonthlyUsageFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.baselineMonthlyUsageFlag', "black");
            }

            if (OppLine.Projected_Avg_Rev_Non_Commit__c < 0) {
              component.set('v.projectedMonthlyFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.projectedMonthlyFlag', "black");
            }

            if (OppLine.Net_Non_Commit__c < 0) {
              component.set('v.netMonthlyFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.netMonthlyFlag', "black");
            }

            if (OppLine.EMRI__c < 0) {
              component.set('v.EMRIFlag', "red");
            } else if (baseLineProdFlagValue == false) {
              component.set('v.EMRIFlag', "black");
            }

            component.set('v.CurrencyValue', OppLine.Opportunity.CurrencyIsoCode + " ");
            component.set('v.oppLineItemObj', OppLine);
            console.log("Average_Renewal_Commit_MRR__c in Save == " + OppLine.Average_Renewal_Commit_MRR__c);
            if (OppLine.Average_Renewal_Commit_MRR__c != null)
              component.set('v.AverageRenewalCommitMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Commit_MRR__c).toFixed(2));
            else
              component.set('v.AverageRenewalCommitMRRVal', null);
            if (OppLine.Projected_Monthly_commit_fees__c != null)
              component.set('v.ProjectedMonthlycommitfeesVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Monthly_commit_fees__c).toFixed(2));
            else
              component.set('v.ProjectedMonthlycommitfeesVal', null);
            component.set('v.NRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.NRR__c).toFixed(2));
            component.set('v.UnitPriceVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.UnitPrice).toFixed(2));
            if (OppLine.Average_Renewal_Usage_MRR__c != null)
              component.set('v.AverageRenewalUsageMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Usage_MRR__c).toFixed(2));
            else
              component.set('v.AverageRenewalUsageMRRVal', null);
            if (OppLine.Projected_Avg_Rev_Non_Commit__c != null)
              component.set('v.ProjectedAvgRevNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Avg_Rev_Non_Commit__c).toFixed(2));
            else
              component.set('v.ProjectedAvgRevNonCommitVal', null);
            component.set('v.NetNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Net_Non_Commit__c).toFixed(2));
            component.set('v.EMRIVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.EMRI__c).toFixed(2));
          } else {
            console.log('request failed');
            console.log(resp);
            console.log(resp.error[0]);
          }
        }
      }, 'ALL');
      $A.enqueueAction(fetchOppLine);
    }
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

  loadoppSubCategoryValues: function(component, event) {
    var loadSubCategoryValues = component.get("c.getDependentPicklist");
    loadSubCategoryValues.setParams({
      "sobjectName": "Opportunity",
      "parentfieldName": "Opportunity_Category__c",
      "childFieldName": "Opportunity_Sub_Category__c"
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
          cancellationValues.push(key);
        }
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

  hideNextFooterAndShowSaveFooter: function(component, event) {
    var nextFooter = component.find("nextFooterId");
    var saveFooter = component.find("saveAfterNextFooterId");
    $A.util.removeClass(nextFooter, "slds-show");
    $A.util.addClass(nextFooter, "slds-hide");
    $A.util.removeClass(saveFooter, "slds-hide");
    $A.util.addClass(saveFooter, "slds-show");
  },

  showMissingFeatureField: function(component, event) {
    var missingProductFeature = component.find("missingProductFeatureId");
    $A.util.removeClass(missingProductFeature, "slds-hide");
    $A.util.addClass(missingProductFeature, "slds-show");
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

  hideCancellationFieldsSectionAndShowOppPicklist: function(component, event) {
    var oppDetailsSection = component.find("oppPicklistDetailsId");
    var cancellationFields = component.find("cancellationFieldsId");
    $A.util.removeClass(cancellationFields, "slds-show");
    $A.util.addClass(cancellationFields, "slds-hide");
    $A.util.removeClass(oppDetailsSection, "slds-hide");
    $A.util.addClass(oppDetailsSection, "slds-show");
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

  hideAddOppDetailsSection: function(component, event) {
    var addOppDetailsModal = component.find("addOppDetailsId");
    $A.util.removeClass(addOppDetailsModal, "slds-show");
    $A.util.addClass(addOppDetailsModal, "slds-hide");
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
    console.log('Inside performOppSaveAndProductCreation');
    var oppCategoryValue = component.get("v.oppCategoryValue");
    var subCategoryValue = component.get("v.oppSubCategoryValue");
    var oppCanceltnValue = component.get("v.oppCancellationLostValue");
    var missingFeatureValue = component.get("v.missingProductFeature");
    var initialOutClause = component.get("v.initialOutClause");
    var aggregationPartner = component.get("v.aggregationPartnerValue");
    var consolidationAccount = component.get("v.consolidationAccount");
    var competitor = component.get("v.competitorValue");
    var unacceptableTerms = component.get("v.unacceptableTermsAndConditions");
    var updateProdAction = component.get("c.saveProductObj");
    console.log("oppCategoryValue == " + oppCategoryValue);
    console.log("subCategoryValue == " + subCategoryValue);
    console.log("oppCanceltnValue == " + oppCanceltnValue);
    if (oppCategoryValue != null || subCategoryValue != null || oppCanceltnValue != null) {
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
        }
        if (unacceptableTerms != "--none--" && unacceptableTerms != null &&
          unacceptableTerms != " ") {
          component.set("v.opportunityObj.Unacceptable_Terms_and_Conditions__c", unacceptableTerms);
        }
      }

      var updateAction = component.get("c.updateOpportunityObj");
      updateAction.setParams({
        "pageObject": component.get("v.opportunityObj")
      });
      updateAction.setCallback(this, function(response) {
        var state = response.getState();
        var message = response.getReturnValue();
        console.log("State during Update= " + state);

        if (component.isValid() && state === "SUCCESS" && message === "success") {
          console.log("After Opp Save Success");
        } else if (component.isValid() && state === "SUCCESS" && message === "success") {}
      });
      $A.enqueueAction(updateAction);
    }
    updateProdAction.setParams({
      "pageObject": component.get("v.oppLineItemObj")
    });
    updateProdAction.setCallback(this, function(resp) {
      var state = resp.getState();
      var message = resp.getReturnValue();
      var baseLineProdFlagValue = false;
      console.log("State after Update = " + state);
      if (component.isValid() && state === "SUCCESS" && message != null) {
        var OppLine = resp.getReturnValue();
        if (OppLine.Average_Renewal_Commit_MRR__c != null ||
          OppLine.Average_Renewal_Usage_MRR__c != null) {
          component.set('v.baseLineProdFlag', "true");
          component.set('v.baseLineProdFlagValue', "color:green");
          baseLineProdFlagValue = true;
        }
        if (OppLine.Average_Renewal_Commit_MRR__c < 0) {
          component.set('v.baseLineMonthlyCommitFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.baseLineMonthlyCommitFlag', "black");
        }

        if (OppLine.Projected_Monthly_commit_fees__c < 0) {
          console.log("In baseLineMonthlyCommit < 0 === ");
          component.set('v.projectedMonthlyCommitFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.projectedMonthlyCommitFlag', "black");
        }

        if (OppLine.NRR__c < 0) {
          component.set('v.oneTimeFeeFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.oneTimeFeeFlag', "black");
        }

        if (OppLine.UnitPrice < 0) {
          component.set('v.NetMRRFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.NetMRRFlag', "black");
        }

        if (OppLine.Average_Renewal_Usage_MRR__c < 0) {
          component.set('v.baselineMonthlyUsageFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.baselineMonthlyUsageFlag', "black");
        }

        if (OppLine.Projected_Avg_Rev_Non_Commit__c < 0) {
          component.set('v.projectedMonthlyFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.projectedMonthlyFlag', "black");
        }

        if (OppLine.Net_Non_Commit__c < 0) {
          component.set('v.netMonthlyFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.netMonthlyFlag', "black");
        }

        if (OppLine.EMRI__c < 0) {
          component.set('v.EMRIFlag', "red");
        } else if (baseLineProdFlagValue == false) {
          component.set('v.EMRIFlag', "black");
        }

        component.set('v.CurrencyValue', OppLine.Opportunity.CurrencyIsoCode + " ");
        component.set('v.oppLineItemObj', OppLine);
        console.log("Average_Renewal_Commit_MRR__c in Save == " + OppLine.Average_Renewal_Commit_MRR__c);
        if (OppLine.Average_Renewal_Commit_MRR__c != null)
          component.set('v.AverageRenewalCommitMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Commit_MRR__c).toFixed(2));
        else
          component.set('v.AverageRenewalCommitMRRVal', null);
        if (OppLine.Projected_Monthly_commit_fees__c != null)
          component.set('v.ProjectedMonthlycommitfeesVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Monthly_commit_fees__c).toFixed(2));
        else
          component.set('v.ProjectedMonthlycommitfeesVal', null);
        component.set('v.NRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.NRR__c).toFixed(2));
        component.set('v.UnitPriceVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.UnitPrice).toFixed(2));
        if (OppLine.Average_Renewal_Usage_MRR__c != null)
          component.set('v.AverageRenewalUsageMRRVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Average_Renewal_Usage_MRR__c).toFixed(2));
        else
          component.set('v.AverageRenewalUsageMRRVal', null);
        if (OppLine.Projected_Avg_Rev_Non_Commit__c != null)
          component.set('v.ProjectedAvgRevNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Projected_Avg_Rev_Non_Commit__c).toFixed(2));
        else
          component.set('v.ProjectedAvgRevNonCommitVal', null);
        component.set('v.NetNonCommitVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.Net_Non_Commit__c).toFixed(2));
        component.set('v.EMRIVal', OppLine.Opportunity.CurrencyIsoCode + " " + parseFloat(OppLine.EMRI__c).toFixed(2));

        var addOppDetailsModal = component.find("addOppDetailsId");
        $A.util.removeClass(addOppDetailsModal, "slds-show");
        $A.util.addClass(addOppDetailsModal, "slds-hide");
        var EditOppTab = component.find("editOnlyProdInfoId");
        var ReadOppTab = component.find("readOnlyProdInfoId");
        var delBtn = component.find("DeleteProdBtnId");
        var saveBtn = component.find("SaveProdBtnId");
        var editBtn = component.find("EditProdBtnId");
        var cancelEditBtn = component.find("CancelEditProdBtnId");
        var cancelBtn = component.find("CancelProdBtnId");
        var backBtn = component.find("BackProdBtnId");
        var action = component.get("c.saveProductObj");
        $A.util.removeClass(EditOppTab, 'slds-show');
        $A.util.addClass(EditOppTab, 'slds-hide');
        $A.util.removeClass(cancelEditBtn, 'slds-show');
        $A.util.addClass(cancelEditBtn, 'slds-hide');
        $A.util.removeClass(saveBtn, 'slds-show');
        $A.util.addClass(saveBtn, 'slds-hide');
        $A.util.removeClass(delBtn, 'slds-hide');
        $A.util.addClass(delBtn, 'slds-show');
        $A.util.removeClass(backBtn, 'slds-hide');
        $A.util.addClass(backBtn, 'slds-show');
        $A.util.removeClass(cancelBtn, 'slds-hide');
        $A.util.addClass(cancelBtn, 'slds-show');
        $A.util.removeClass(editBtn, 'slds-hide');
        $A.util.addClass(editBtn, 'slds-show');
        $A.util.removeClass(ReadOppTab, 'slds-hide');
        $A.util.addClass(ReadOppTab, 'slds-show');
      } else if (component.isValid() && state === "SUCCESS" && message === null) {}
    });
    $A.enqueueAction(updateProdAction);
  },
})