({
    performInit : function(component) {
        var fetchOpp = component.get('c.fetchOpportunity');
        var netMRRCurrValue = null;
        var theme = null;
        var action = component.get("c.getUIThemeDescription");
		fetchOpp.setParam('oppId',component.get("v.recordId"));
        var oppObjId = component.get("v.recordId");
        component.set('v.contractEndedValue',null);
        component.set('v.contractEndedValues',null);
        var viewBackOppButton = component.find("oppBackBtnId") ;
        
        action.setCallback(this, function(a) {
            if (component.isValid()){
            	theme = a.getReturnValue();
            	console.log("Status == "+a.getState());
                console.log("Theme after Call== "+theme);
                if(theme == 'Theme4d') {
                	var urlEvent = $A.get("e.force:navigateToURL");
                	urlEvent.setParams({
                    "url": "/apex/addProductPageMerged?oppId="+oppObjId,
                    "isredirect": "true"
                	});
            		urlEvent.fire();	
                } else {
                	fetchOpp.setCallback(this, function(resp){
                    	if (component.isValid()){
                        	if (resp.getState() === 'SUCCESS'){
                              console.log('callback fetch Opp success and component is valid');
                              var oppRec = resp.getReturnValue();
                             if(oppRec.MRR__c < 0) {
                                      component.set('v.MRRValue',"true");
                                  } else {
                                      component.set('v.MRRValue',"false");    
                                  }
                                  component.set('v.myCurr',oppRec.MRR__c);
                                  //SFDC-5573
                                  component.set('v.accountName',oppRec.Account.Name);
                                  component.set('v.oppForecastCategory',oppRec.ForecastCategoryName);
                                  component.set('v.oppCloseDate',oppRec.CloseDate);
                                  if(oppRec.Opportunity_Revenue_Impact__c < 0) {
                                      component.set('v.EMRIPositive',"true");
                                  } else {
                                      component.set('v.EMRIPositive',"false");
                                  }
                                  if(!oppRec.Churn_No_Paper__c) {
                                      component.set('v.ContractValue',"No");
                                  }
                                  console.log("oppRec.MRR__c == "+oppRec.MRR__c);
                                  if(oppRec.MRR__c != 0)
                                      component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " "+ parseFloat(oppRec.MRR__c).toFixed(2));
                                  else
                                      component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " 0.00");    
                                  console.log('oppRec.Opportunity_Revenue_Impact__c === '
                                              +oppRec.Opportunity_Revenue_Impact__c);
                                  if(oppRec.Opportunity_Revenue_Impact__c != 0 && 
                                     oppRec.Opportunity_Revenue_Impact__c != null) {
                                      component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " "+ 
                                      parseFloat(oppRec.Opportunity_Revenue_Impact__c).toFixed(2));
                                  } else {
                                      component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " 0.00" );    
                                  }
    							  console.log('From Button == '+component.get('v.from'));
                                  if(component.get('v.from') == 'related'){
                                        console.log('From Button if == '+component.get('v.from'));
                                        $A.util.removeClass(viewBackOppButton, 'slds-hide');
            							$A.util.addClass(viewBackOppButton, 'slds-show');
                                  } else {
                                        $A.util.removeClass(viewBackOppButton, 'slds-show');
            							$A.util.addClass(viewBackOppButton, 'slds-hide');
                                  }

                                  component.set('v.oppObj',oppRec);
                                  component.set('v.CurrencyOppValue',oppRec.CurrencyIsoCode + " ");
                             
                            } else {
                                console.log('request failed');
                                console.log(resp);
                                console.log(resp.error[0]);
                            }
                		} else {
                    		console.log('component unavailable on callback');
                		}	
                    },'ALL');
            		$A.enqueueAction(fetchOpp);   
                }
                                         
            }
        });
        $A.enqueueAction(action);
		console.log("Theme == "+theme);
    },
    
    churnCancelControllerAction : function(component,event) {
    	var updateAction = component.get("c.noContractChanges");
        console.log('Opp Id = '+component.get("v.recordId"));
        updateAction.setParams({
            	"oppId"  : component.get("v.recordId")
        });
        updateAction.setCallback(this, function(response) {
            var state = response.getState();
            var oppRec = response.getReturnValue();
            console.log("State during No Contract Changes = "+state);
            if (component.isValid() && state === "SUCCESS" && oppRec!=null) {   
                console.log("After Opp Save Success");
                if(oppRec.MRR__c < 0) {
                        component.set('v.MRRValue',"true");
                } else {
                	component.set('v.MRRValue',"false");      
                }
                component.set('v.myCurr',oppRec.MRR__c);
                if(oppRec.Opportunity_Revenue_Impact__c < 0) {
                	component.set('v.EMRIPositive',"true");
                } else {
                    component.set('v.EMRIPositive',"false");
                }
                if(!oppRec.Churn_No_Paper__c) {
                	component.set('v.ContractValue',"No");
                } 
                console.log(component.get("v.MRRValue"));
				component.set('v.oppObj',oppRec);
                component.set('v.CurrencyOppValue',oppRec.CurrencyIsoCode + " ");
                if(oppRec.MRR__c != 0)
                	component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " "+ parseFloat(oppRec.MRR__c).toFixed(2));
                else
                	component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " 0.00");    
                if(oppRec.Opportunity_Revenue_Impact__c != 0) {
                	component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " "+ parseFloat(oppRec.Opportunity_Revenue_Impact__c).toFixed(2));
                }
                else {
                    component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " 0.00" );
                }
            } else {
            	console.log('request failed');
                console.log(response);
                console.log(response.error[0]);    
            }
        });
        $A.enqueueAction(updateAction); 
    },
    
    showContractEndedModal : function(component,event) {
        var contractEndedModal = component.find("modalContractEndedFieldId") ;
        var names = [];
        names.push("Yes");
        names.push("No");
        component.set("v.contractEndedValues",names);
        $A.util.removeClass(contractEndedModal, 'slds-hide');
        $A.util.addClass(contractEndedModal, 'slds-show');
    },
    
    churnCancelUpdate : function(component,event) {
		var updateAction = component.get("c.performChurnCancelOnOppLines");
        console.log('Opp Id = '+component.get("v.recordId"));
        var contractValueBool = false;
        if(component.get('v.contractEndedValue') == "Yes") {
           contractValueBool = true; 
        }
        updateAction.setParams({
        	"oppObject"  : component.get("v.oppObj"), 
            "contractValue" : contractValueBool
        });
        updateAction.setCallback(this, function(response) {
            var state = response.getState();
            var oppRec = response.getReturnValue();
            console.log("State during No Contract Changes = "+state);
            if (component.isValid() && state === "SUCCESS" && oppRec!=null) { 
                component.set('v.contractEndedValue',null);
                console.log("After Opp Save Success");
                if(oppRec.MRR__c < 0) {
                        component.set('v.MRRValue',"true");
                }
                else {
                  component.set('v.MRRValue',"false");  
                }
                component.set('v.myCurr',oppRec.MRR__c);
                if(oppRec.Opportunity_Revenue_Impact__c < 0) {
                	component.set('v.EMRIPositive',"true");
                } else {
                    component.set('v.EMRIPositive',"false");
                }
                if(!oppRec.Churn_No_Paper__c) {
                	component.set('v.ContractValue',"No");
                }
                console.log(component.get("v.MRRValue"));
				component.set('v.oppObj',oppRec);
                component.set('v.CurrencyOppValue',oppRec.CurrencyIsoCode + " ");
                if(oppRec.MRR__c != 0)
                	component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " "+ parseFloat(oppRec.MRR__c).toFixed(2));
                else
                	component.set('v.MRRObjValue',oppRec.CurrencyIsoCode + " 0.00");    
                if(oppRec.Opportunity_Revenue_Impact__c != 0) {
                	component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " "+ parseFloat(oppRec.Opportunity_Revenue_Impact__c).toFixed(2));
                }
                else {
                    component.set('v.EMRIValue',oppRec.CurrencyIsoCode + " 0.00" );
                }
                //$A.get('e.force:refreshView').fire();
                var contractEndedModal = component.find("addOppMainDetailsId") ;
        		$A.util.removeClass(contractEndedModal, 'slds-show');
        		$A.util.addClass(contractEndedModal, 'slds-hide');
                var saveButtonSection = component.find("saveAfterNextFooterId");
                $A.util.removeClass(saveButtonSection, 'slds-show');
        		$A.util.addClass(saveButtonSection, 'slds-hide');
                var nextButtonSection = component.find("nextFooterId");
                $A.util.removeClass(nextButtonSection, 'slds-hide');
        		$A.util.addClass(nextButtonSection, 'slds-show');
                var errorSection = component.find("cancellationErrorMessageId");
                $A.util.removeClass(errorSection, 'slds-show');
        		$A.util.addClass(errorSection, 'slds-hide');
                var cancellationFieldsSection = component.find("cancellationFieldsId");
                $A.util.removeClass(cancellationFieldsSection, 'slds-show');
        		$A.util.addClass(cancellationFieldsSection, 'slds-hide');
                var oppPicklistFieldsSection = component.find("oppPicklistDetailsId");
                $A.util.removeClass(oppPicklistFieldsSection, 'slds-hide');
        		$A.util.addClass(oppPicklistFieldsSection, 'slds-show');
            } else {
            	console.log('request failed');
                console.log(response);
                console.log(response.error[0]);    
            }
        });
        $A.enqueueAction(updateAction); 
	},
    
    nullifyCancellationFields : function(component,event){
        component.set("v.missingProductFeature",null); 
        component.set("v.initialOutClause",null); 
        component.set("v.aggregationPartnerValue",null); 
        component.set("v.consolidationAccount",null); 
        component.set("v.competitorValue",null); 
        component.set("v.unacceptableTermsAndConditions",null);
        component.set("v.contractEndedValue",null);
    },
    
    nullifyCancellationPicklistFields : function(component,event){
    	component.set("v.oppCategoryValue",null);
        component.set("v.oppSubCategoryValue",null);
        component.set("v.oppCancellationLostValue",null);
        component.set("v.oppCancellationLostValues",null);
        component.set("v.oppSubCategoryValues",null);
        component.set("v.oppCategoryValues",null);
    },
    
    showContractEndedWithOppModal : function(component,event) {
        var contractEndedModal = component.find("addOppMainDetailsId") ;
        var names = [];
        names.push("Yes");
        names.push("No");
        component.set("v.contractEndedValues",names);
        $A.util.removeClass(contractEndedModal, 'slds-hide');
        $A.util.addClass(contractEndedModal, 'slds-show');
    },
    
   //  loadoppSubCategoryValues : function(component,event) {
   //      var loadSubCategoryValues = component.get("c.getDependentPicklist");
   //      loadSubCategoryValues.setParams({
   //          "sobjectName" : "Opportunity",
   //          "parentfieldName":"Opportunity_Category__c",
   //          "childFieldName":"Opportunity_Sub_Category__c"
   //      });
   //      loadSubCategoryValues.setCallback(this, function(response) {
   //      var state = response.getState();
   //      var options = response.getReturnValue();
   //      component.set("v.oppSubCategoryValue","Lost Customer");
   //      component.set("v.oppCategoryValue","Contract Ended");
   //      if (component.isValid() && state === "SUCCESS") {   
   //          var subCategoryMap = response.getReturnValue();
   //          var categories = [];
   //          var subCategories = [];
   //          categories.push("Contract Ended");
   //          subCategories.push("Lost Customer");
   //          for ( var key in subCategoryMap ) {
   //              if(key != "Contract Ended")
   //          		categories.push(key);
   //              console.log('Category = '+key);
   //          }
   //          for(i=0;i < subCategoryMap["Contract Ended"].length; i++) {
   //          	if(subCategoryMap["Contract Ended"][i] != "Lost Customer")    
   //              	subCategories.push(subCategoryMap["Contract Ended"][i]);    
   //          }
			// component.set("v.oppCategoryValues",categories);    
   //      	component.set("v.categoryToSubcategoryMap",subCategoryMap);   
   //          component.set("v.oppSubCategoryValues",subCategories);
   //          console.log('Category Selected = '+component.get("v.oppCategoryValue"));
   //      }
   //      });
   //      $A.enqueueAction(loadSubCategoryValues);
   //  },
    
    loadoppCategoryToCancellationValues : function(component,event) {
        var loadCategoryCancellationValues = component.get("c.getDependentPicklist");
        loadCategoryCancellationValues.setParams({
            "sobjectName" : "Opportunity",
            "parentfieldName":"Opportunity_Category__c",
            "childFieldName":"Loss_Reason__c"
        });
        loadCategoryCancellationValues.setCallback(this, function(response) {
        var state = response.getState();
        var options = response.getReturnValue();
        if (component.isValid() && state === "SUCCESS") {   
            var cancellationMap = response.getReturnValue();
            var cancellationValues = [];
            for ( var key in cancellationMap ) {
                //console.log('Subcategory in Cancellation = '+key);
            	cancellationValues.push(key);
            }
            
            var categories = [];
            var categoryValue = "Customer Churn";
            categories.push(categoryValue);
            component.set("v.oppCategoryValues",categories); 
            component.set("v.oppCategoryValue",categoryValue);
           
            var lossreason = [];
            for(let i=0;i < cancellationMap[categoryValue].length; i++) 
            {
                lossreason.push(cancellationMap[categoryValue][i]);    
            }
            component.set("v.oppCancellationLostValue",null);
            component.set('v.oppCancellationLostValues',lossreason);  
        }
        });
        $A.enqueueAction(loadCategoryCancellationValues);
    },
    
    showCancellationFields : function(component,event) {
    	var cancellationValue = component.get("v.oppCancellationLostValue");
        if(cancellationValue == "Missing Product Feature" && 
           	   (component.get("v.oppObj.Missing_Product_Feature__c") != null ||
            	component.get("v.oppObj.Missing_Product_Feature__c") != " ")) {
            	var missingProductFeature = component.find("missingProductFeatureId");
        		$A.util.removeClass(missingProductFeature, "slds-hide");
        		$A.util.addClass(missingProductFeature, "slds-show");   
        } 
        else if(cancellationValue == "Competition-Product/Feature Driven") {
            if(component.get("v.oppObj.Missing_Product_Feature__c") != null ||
               component.get("v.oppObj.Missing_Product_Feature__c") != " ") {
            	var missingProductFeature = component.find("missingProductFeatureId");
        		$A.util.removeClass(missingProductFeature, "slds-hide");
        		$A.util.addClass(missingProductFeature, "slds-show");    
            }
            if(component.get("v.oppObj.Competitor__c") != null ||
               component.get("v.oppObj.Competitor__c") != " ") {
            	var competitor = component.find("oppCompetitorId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");    
            }
        }
        else if(cancellationValue == "Initial Out Clause" &&
               (component.get("v.oppObj.Initial_Out_Clause_Description__c") != null ||
           		component.get("v.oppObj.Initial_Out_Clause_Description__c") != " ")){
            	var initialOutOfClause = component.find("initialOutClauseId");
        		$A.util.removeClass(initialOutOfClause, "slds-hide");
        		$A.util.addClass(initialOutOfClause, "slds-show");    
        }
        else if(cancellationValue == "Aggregation through a Partner (Pick Partner)" &&
               (component.get("v.oppObj.Aggregation_Partner__c") != null ||
           		component.get("v.oppObj.Aggregation_Partner__c") != " ")){
            	var aggregationPartner = component.find("aggregationPartnerId");
        		$A.util.removeClass(aggregationPartner, "slds-hide");
        		$A.util.addClass(aggregationPartner, "slds-show");    
        }
        else if(cancellationValue == "Contract Consolidation with Akamai Customer" &&
               (component.get("v.oppObj.Consolidation_Account__c") != null ||
           		component.get("v.oppObj.Consolidation_Account__c") != " ")){
            	var consolidationAccount = component.find("consolidationAccountId");
        		$A.util.removeClass(consolidationAccount, "slds-hide");
        		$A.util.addClass(consolidationAccount, "slds-show");    
        }
        else if(cancellationValue == "Competition-Product/Performance Driven" &&
               (component.get("v.oppObj.Competitor__c") != null ||
           		component.get("v.oppObj.Competitor__c") != " ")){
            	var competitor = component.find("oppCompetitorId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");     
        }
        else if(cancellationValue == "Competition Price Driven" &&
               (component.get("v.oppObj.Competitor__c") != null ||
           		component.get("v.oppObj.Competitor__c") != " ")){
            	var competitor = component.find("oppCompetitorId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");    
        }
        else if(cancellationValue == "Will not accept Akamai Terms and Conditions" &&
               (component.get("v.oppObj.Unacceptable_Terms_and_Conditions__c") != null ||
           		component.get("v.oppObj.Unacceptable_Terms_and_Conditions__c") != " ")){
            	var showSaveFooter = false;     
        }
    },
    
    showSaveButtonAndHideNextButtonSection : function(component,event) {
        var saveButtonSection = component.find("saveAfterNextFooterId");
        var nextButtonSection = component.find("nextFooterId");
        var cancellationFieldsSection = component.find("cancellationFieldsId");
        var oppFieldsSection = component.find("oppPicklistDetailsId");
        $A.util.removeClass(nextButtonSection, 'slds-show');
        $A.util.addClass(nextButtonSection, 'slds-hide');
        $A.util.removeClass(oppFieldsSection, 'slds-show');
        $A.util.addClass(oppFieldsSection, 'slds-hide');
        $A.util.removeClass(saveButtonSection, 'slds-hide');
        $A.util.addClass(saveButtonSection, 'slds-show');
        $A.util.removeClass(cancellationFieldsSection, 'slds-hide');
        $A.util.addClass(cancellationFieldsSection, 'slds-show');
    },
    
    hideCancellationFields : function(component,event){
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
    
    fetchCompetitorValues : function(component,event){
    	var loadCompetitorValues = component.get("c.fetchPicklistValues");
        	loadCompetitorValues.setParams({
            	"sobjectName" : "Opportunity",
            	"picklistFieldName":"Competitor__c"
        	});
            loadCompetitorValues.setCallback(this, function(response) {
                var state = response.getState();
                var options = response.getReturnValue();
                if (component.isValid() && state === "SUCCESS") 
                {   
                    component.set("v.competitorValues",options);
                    
                }
            });
        $A.enqueueAction(loadCompetitorValues);
    },
    
    fetchAggregationPartnerValues : function(component,event){
    	var loadAggregationPartnerValues = component.get("c.fetchPicklistValues");
        	loadAggregationPartnerValues.setParams({
            	"sobjectName" : "Opportunity",
            	"picklistFieldName":"Competitor__c"
        	});
            loadAggregationPartnerValues.setCallback(this, function(response) {
                var state = response.getState();
                var options = response.getReturnValue();
                if (component.isValid() && state === "SUCCESS") 
                {   
                    component.set("v.aggregationPartnerValues",options);
                    
                }
            });
        $A.enqueueAction(loadAggregationPartnerValues);
    },

    getUserDetails : function(component,event,helper) {
        var action = component.get("c.getUserProfileName");
        action.setCallback(this, function(response) {
            var res = response.getReturnValue();
            if(res.includes('Sales - Carrier')){
                component.set("v.termRequired",true);
                //alert(component.get("v.termRequired"));
            }
            if(res.includes('Sales -'))
            {
              component.set("v.AdditionalLossDetailRequired",true);
            }
        });
        $A.enqueueAction(action);
    }
    
    
    
})