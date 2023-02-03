({
	doInit : function(component, event, helper) {
        helper.performInit(component);
        helper.nullifyCancellationFields(component,event);
        helper.nullifyCancellationPicklistFields(component,event);
        helper.getUserDetails(component,event,helper);
    },
    
    OppDetailsActive : function(component, event) { 
		var OppDetailsTab = component.find("OppDetId") ;
        var ProdDetailsTab = component.find("prodDetId");
        var OppDetailsData = component.find("oppDetBodyId") ;
        var prodDetailsData = component.find("prodDetBodyId");
        $A.util.addClass(OppDetailsTab, 'slds-active');
        $A.util.removeClass(ProdDetailsTab, 'slds-active');
        $A.util.removeClass(prodDetailsData, 'slds-show');
        $A.util.removeClass(OppDetailsData, 'slds-hide');
        $A.util.addClass(OppDetailsData, 'slds-show');
        $A.util.addClass(prodDetailsData, 'slds-hide');
        console.log("Opp Active");
    },
    
    prodDetailsActive : function(component, event) { 
		var OppDetailsTab = component.find("oppDetId") ;
        var ProdDetailsTab = component.find("prodDetId") ;
        var OppDetailsData = component.find("oppDetBodyId") ;
        var prodDetailsData = component.find("prodDetBodyId") ;
        $A.util.addClass(ProdDetailsTab, 'slds-active');
        $A.util.removeClass(OppDetailsTab, 'slds-active');
        $A.util.removeClass(OppDetailsData, 'slds-show');
        $A.util.removeClass(prodDetailsData, 'slds-hide');
        $A.util.addClass(prodDetailsData, 'slds-show');
        $A.util.addClass(OppDetailsData, 'slds-hide');
        console.log("Prod Active");
    },
    
    handleproductDetailViewEvent : function(component, event,helper) { 
        console.log("In hanle Product Detail View Event");
        console.log(event.getParam("OppLineItemId") + "   ---");
        component.set('v.oppLineObjId',event.getParam("OppLineItemId"));
        var mainOppTab = component.find("mainTabId") ;
        var prodDetViewOppTab = component.find("productDetailViewTabId") ;
        var addProductTab = component.find("addProductDetailId") ;
        $A.util.removeClass(mainOppTab, 'slds-show');
        $A.util.addClass(mainOppTab, 'slds-hide');
        $A.util.removeClass(addProductTab, 'slds-show');
        $A.util.addClass(addProductTab, 'slds-hide');
        $A.util.removeClass(prodDetViewOppTab, 'slds-hide');
        $A.util.addClass(prodDetViewOppTab, 'slds-show');
        var evntProductDetail = $A.get("e.c:invokeProductDetailInit");
        evntProductDetail.fire();
    },
    
    handleOppProdDetailsEvent : function(component, event,helper) { 
        var mainOppTab = component.find("mainTabId") ;
        var prodDetViewOppTab = component.find("productDetailViewTabId") ;
        var addProdTab = component.find("addProductDetailId") ;
        $A.util.removeClass(prodDetViewOppTab, 'slds-show');
        $A.util.addClass(prodDetViewOppTab, 'slds-hide');
        $A.util.removeClass(addProdTab, 'slds-show');
        $A.util.addClass(addProdTab, 'slds-hide');
        helper.performInit(component);
        //$A.get('e.force:refreshView').fire();
    	$A.util.removeClass(mainOppTab, 'slds-hide');
        $A.util.addClass(mainOppTab, 'slds-show');
    	
    },
    
    showSpinner: function(cmp, event, helper) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        
    },
    
    hideSpinner : function(cmp,event,helper){
        var spinner = cmp.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("ltngSpinner");
        $A.util.toggleClass(spinner, "slds-show");
    },
    
    hidePopUp : function(component, event) { 
        var modalTab = component.find("modalId") ;
        $A.util.removeClass(modalTab, 'slds-show');
        $A.util.addClass(modalTab, 'slds-hide');
    },
    
    addProductAction : function(component, event) { 
        var mainOppTab = component.find("mainTabId") ;
        var addProdTab = component.find("addProductDetailId") ;
        var prodDetViewOppTabFromAddProd = component.find("productDetailViewTabId") ;
        $A.util.removeClass(mainOppTab, 'slds-show');
        $A.util.addClass(mainOppTab, 'slds-hide');
        $A.util.removeClass(prodDetViewOppTabFromAddProd, 'slds-show');
        $A.util.addClass(prodDetViewOppTabFromAddProd, 'slds-hide');
        var evntAddProduct = $A.get("e.c:invokeAddProductInit");
        evntAddProduct.fire();
        $A.util.removeClass(addProdTab, 'slds-hide');
        $A.util.addClass(addProdTab, 'slds-show');
    },
    
    downAction : function(component, event) {
        var mainButtonDownId = component.find("mainButtonWithDownId") ;
        var mainButtonUpId = component.find("mainButtonWithUpId") ;
        var contractButtons = component.find("ContractChangesId") ;
        $A.util.removeClass(mainButtonDownId, 'slds-show');
        $A.util.addClass(mainButtonDownId, 'slds-hide');
        $A.util.removeClass(mainButtonUpId, 'slds-hide');
        $A.util.addClass(mainButtonUpId, 'slds-show');
        $A.util.removeClass(contractButtons, 'slds-hide');
        $A.util.addClass(contractButtons, 'slds-show');
    },
    
    upAction : function(component, event) {
        var mainButtonDownId = component.find("mainButtonWithDownId") ;
        var mainButtonUpId = component.find("mainButtonWithUpId") ;
        var contractButtons = component.find("ContractChangesId") ;
        $A.util.removeClass(mainButtonUpId, 'slds-show');
        $A.util.addClass(mainButtonUpId, 'slds-hide');
        $A.util.removeClass(contractButtons, 'slds-show');
        $A.util.addClass(contractButtons, 'slds-hide');
        $A.util.removeClass(mainButtonDownId, 'slds-hide');
        $A.util.addClass(mainButtonDownId, 'slds-show');
    },
	
	noContractChangesAction : function(component, event) { 
        var modalContractTab = component.find("modalNoContractChangesId") ;
        $A.util.removeClass(modalContractTab, 'slds-hide');
        $A.util.addClass(modalContractTab, 'slds-show');
    },
    
    hideModalNoContractChanges : function(component, event) { 
        var modalContractTab = component.find("modalNoContractChangesId") ;
        $A.util.removeClass(modalContractTab, 'slds-show');
        $A.util.addClass(modalContractTab, 'slds-hide');
    },
    
    hideModalNoContractChangesAndSaveAction : function(component,event,helper) { 
        helper.churnCancelControllerAction(component,event);
        var modalContractTab = component.find("modalNoContractChangesId") ;
        $A.util.removeClass(modalContractTab, 'slds-show');
        $A.util.addClass(modalContractTab, 'slds-hide');
    },
    
    churnCancelAction : function(component,event,helper) {
        var oppCancellationValue = component.get("v.oppObj.Loss_Reason__c");
        var contractEndedValue = component.get("v.contractEndedValue");
        /*if(oppCancellationValue != null) {
            helper.showContractEndedModal(component,event);
        } else {
            helper.loadoppSubCategoryValues(component,event);
            helper.loadoppSubCategoryToCancellationValues(component,event);
        	helper.showContractEndedWithOppModal(component,event);    
        }*/
        //helper.loadoppSubCategoryValues(component,event);
        helper.loadoppCategoryToCancellationValues(component,event);
        helper.showContractEndedWithOppModal(component,event);   
    },
    
    hideModalContractEndedFieldAndSaveAction : function(component,event,helper) {
        var contractVal = component.get('v.contractEndedValue');
        var contractEndedModal = component.find("modalContractEndedFieldId");
        var contractEndedError = component.find("addOppErrorContractMessageId");
        if(contractVal == null || contractVal == "--none--"){
        	$A.util.removeClass(contractEndedError, 'slds-hide');
        	$A.util.addClass(contractEndedError, 'slds-show');	    
        }else {
            $A.util.removeClass(contractEndedError, 'slds-show');
        	$A.util.addClass(contractEndedError, 'slds-hide');
        	helper.churnCancelUpdate(component,event);
        	$A.util.removeClass(contractEndedModal, 'slds-show');
        	$A.util.addClass(contractEndedModal, 'slds-hide');    
        }
        
    },
    
    hideModalContractEndedField : function(component,event,helper) {
        component.set('v.contractEndedValue',null);
        var contractEndedModal = component.find("modalContractEndedFieldId");
        $A.util.removeClass(contractEndedModal, 'slds-show');
        $A.util.addClass(contractEndedModal, 'slds-hide');
    },
    
    oppCategorySelection : function(component,event,helper) {
        console.log("Category Selection Value == "+component.get("v.oppCategoryValue"));
        var categoryValue = component.get("v.oppCategoryValue");
        var LossReasonMap = component.get("v.categoryToCancelLossReasonMap");
        var lossreason = [];
        lossreason.push("--None--");
        for(let i=0;i < LossReasonMap[categoryValue].length; i++) {
        	lossreason.push(LossReasonMap[categoryValue][i]);    
        }
        component.set("v.oppCancellationLostValue",null);
        component.set('v.oppCancellationLostValues',lossreason);
    },
    
    // oppSubCategorySelection : function(component,event,helper) {
    //     var subCategoryValue = component.get("v.oppSubCategoryValue");
    //     var SubCategoryCancellationMap = component.get("v.SubcategoryToCancelLossReasonMap");
    //     component.set('v.oppCancellationLostValues',SubCategoryCancellationMap[subCategoryValue]);
    // },
    
    addOppDetailsCancelAction : function(component,event,helper) {
    	var contractEndedModal = component.find("addOppMainDetailsId") ;
        var errorSection = component.find("addOppErrorMessageId");
        $A.util.removeClass(contractEndedModal, 'slds-show');
        $A.util.addClass(contractEndedModal, 'slds-hide');
        $A.util.removeClass(errorSection, 'slds-show');
        $A.util.addClass(errorSection, 'slds-hide');
        helper.nullifyCancellationFields(component,event);
        helper.nullifyCancellationPicklistFields(component,event);
        component.set('v.contractEndedValue',null);
    },
    
    addOppDetailsNextAction : function(component,event,helper) {

        var categoryValue = component.get("v.oppCategoryValue");
        
        var cancellationValue = component.get("v.oppCancellationLostValue");

        var additionalDescription = component.get("v.additionalLossDetail");
        
        var errorSection = component.find("addOppErrorMessageId");
        var contractEndedValue = component.get("v.contractEndedValue");
        if(cancellationValue == null || cancellationValue == '--None--' ||
           categoryValue == null || categoryValue == '--None--' ) {
        	$A.util.removeClass(errorSection, 'slds-hide');
        	$A.util.addClass(errorSection, 'slds-show');	    
        } else {
            $A.util.removeClass(errorSection, 'slds-show');
        	$A.util.addClass(errorSection, 'slds-hide');
            helper.showCancellationFields(component,event);
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
                    helper.fetchCompetitorValues(component,event);
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
                helper.fetchAggregationPartnerValues(component,event);
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
                helper.fetchCompetitorValues(component,event);
            	var competitor = component.find("oppCompetitorId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");     
        	}
            else if(cancellationValue == "Competition Price Driven" &&
               (component.get("v.oppObj.Competitor__c") != null ||
           		component.get("v.oppObj.Competitor__c") != " ")){
                helper.fetchCompetitorValues(component,event);
            	var competitor = component.find("oppCompetitorId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");    
        	}
            else if(cancellationValue == "Will not accept Akamai Terms and Conditions" &&
               (component.get("v.oppObj.Unacceptable_Terms_and_Conditions__c") != null ||
           		component.get("v.oppObj.Unacceptable_Terms_and_Conditions__c") != " ")){
            	var competitor = component.find("unacceptableTermsandConditionsId");
       		    $A.util.removeClass(competitor, "slds-hide");
        		$A.util.addClass(competitor, "slds-show");      
        	}
            helper.showSaveButtonAndHideNextButtonSection(component,event);
        }
    },
    
    addOppDetailsBackAction : function(component,event,helper) {
        helper.hideCancellationFields(component,event);
        var saveButtonSection = component.find("saveAfterNextFooterId");
        var nextButtonSection = component.find("nextFooterId");
        var cancellationFieldsSection = component.find("cancellationFieldsId");
        var oppFieldsSection = component.find("oppPicklistDetailsId");
        var errorSection = component.find("cancellationErrorMessageId");
        var errorSectionCanFields = component.find("addOppErrorMessageId");
        $A.util.removeClass(nextButtonSection, 'slds-hide');
        $A.util.addClass(nextButtonSection, 'slds-show');
        $A.util.removeClass(oppFieldsSection, 'slds-hide');
        $A.util.addClass(oppFieldsSection, 'slds-show');
        $A.util.removeClass(saveButtonSection, 'slds-show');
        $A.util.addClass(saveButtonSection, 'slds-hide');
        $A.util.removeClass(cancellationFieldsSection, 'slds-show');
        $A.util.addClass(cancellationFieldsSection, 'slds-hide');
        $A.util.removeClass(errorSection, 'slds-show');
        $A.util.addClass(errorSection, 'slds-hide');
        $A.util.removeClass(errorSectionCanFields, 'slds-show');
        $A.util.addClass(errorSectionCanFields, 'slds-hide');
    },
    
    addOppDetailsSaveAction : function(component,event,helper) {
        var cancellationValue = component.get("v.oppCancellationLostValue");
        var categoryValue = component.get("v.oppCategoryValue");
        var additionalLossDetail = component.get("v.additionalLossDetail");
        var cancellationErrorMessage = component.find("cancellationErrorMessageId");
        var contractEndedValue = component.get("v.contractEndedValue");
        var hidePopUp = false;
        if(cancellationValue == "Missing Product Feature") {
            var missingFeatureValue = component.get("v.missingProductFeature");
            if(missingFeatureValue == null || missingFeatureValue == " " ||
               contractEndedValue == null || contractEndedValue == " " ||
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 
                component.set("v.oppObj.Missing_Product_Feature__c",missingFeatureValue);
            }
        }
        else if(cancellationValue == "Competition-Product/Feature Driven") {
           var competitorValue = component.get("v.competitorValue");
           var missingFeatureValue = component.get("v.missingProductFeature");
            if(competitorValue == null || competitorValue == " " || competitorValue == "--none--"
               || missingFeatureValue == null || missingFeatureValue == " " ||
               contractEndedValue == null || contractEndedValue == " " ||
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 	
                component.set("v.oppObj.Missing_Product_Feature__c",missingFeatureValue);
                component.set("v.oppObj.Competitor__c",competitorValue);
            } 
        }
        else if(cancellationValue == "Initial Out Clause") {
            var initialOutClause = component.get("v.initialOutClause");
            if(initialOutClause == null || initialOutClause == " " ||
               contractEndedValue == null || contractEndedValue == " " ||
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 
                component.set("v.oppObj.Initial_Out_Clause_Description__c",initialOutClause);
            }
        }
        else if(cancellationValue == "Aggregation through a Partner (Pick Partner)") {
            var aggregationPartner = component.get("v.aggregationPartnerValue");
            if(aggregationPartner == null || aggregationPartner == " " || 
               aggregationPartner == "--none--" || contractEndedValue == null 
               || contractEndedValue == " " || contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide");
                component.set("v.oppObj.Aggregation_Partner__c",aggregationPartner);
            }
        }
        else if(cancellationValue == "Contract Consolidation with Akamai Customer") {
            var consolidationAccount = component.get("v.consolidationAccount");
            if(consolidationAccount == null || consolidationAccount == " " || 
               contractEndedValue == null || contractEndedValue == " " || 
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 
                component.set("v.oppObj.Consolidation_Account__c",consolidationAccount);
            }
        }
        else if(cancellationValue == "Competition-Product/Performance Driven") {
            var competitor = component.get("v.competitorValue");
            if(competitor == null || competitor == " " || competitor == "--none--" ||
               contractEndedValue == null || contractEndedValue == " " || 
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 	
                component.set("v.oppObj.Competitor__c",competitor);
            }
        }
        else if(cancellationValue == "Will not accept Akamai Terms and Conditions") {
            var unacceptableTerms = component.get("v.unacceptableTermsAndConditions");
            if(unacceptableTerms == null || unacceptableTerms == " " || 
               contractEndedValue == null || contractEndedValue == " " || 
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 
                component.set("v.oppObj.Unacceptable_Terms_and_Conditions__c",unacceptableTerms);
            }
        } 
        else if(cancellationValue == "Competition Price Driven") {
            var competitor = component.get("v.competitorValue");
            if(competitor == null || competitor == " " || competitor == "--none--" ||
               contractEndedValue == null || contractEndedValue == " " ||
               contractEndedValue == "--none--"){
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show"); 	   
            } else {
                hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide"); 	
                component.set("v.oppObj.Competitor__c",competitor);
            }
        } else {
            if(contractEndedValue == null || contractEndedValue == " " ||
               contractEndedValue == "--none--") {
            	$A.util.removeClass(cancellationErrorMessage, "slds-hide");
        		$A.util.addClass(cancellationErrorMessage, "slds-show");    
            } else {
             	hidePopUp = true;
                $A.util.removeClass(cancellationErrorMessage, "slds-show");
        		$A.util.addClass(cancellationErrorMessage, "slds-hide");    
            }
        }
        
        if(hidePopUp) {
        	component.set("v.oppObj.Opportunity_Category__c",categoryValue);				
            component.set("v.oppObj.Loss_Reason__c",cancellationValue);	
            component.set("v.oppObj.Loss_Cancellation_Description__c",additionalLossDetail);
            helper.churnCancelUpdate(component,event);
            
        	helper.nullifyCancellationFields(component,event);
        	helper.nullifyCancellationPicklistFields(component,event);
        	//component.set('v.contractEndedValue',null);
        }
    },
  
    navigateToOpp : function(component,event,helper) {
        var opptyId = component.get("v.recordId");
    	sforce.one.navigateToSObject(opptyId,'detail');
    },
})