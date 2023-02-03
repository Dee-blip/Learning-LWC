({
    doInit : function(component, event, helper) {
        var loadOppDetails = component.get("c.fetchOpportunity");
        var loadCurrencyValues = component.get("c.loadCurrencyPicklist");
        loadOppDetails.setParams({
            "oppId" : component.get("v.recordId")
        });
        loadOppDetails.setCallback(this, function(response) {
            var state = response.getState();
            var oppRec = response.getReturnValue();
            if (component.isValid() && state === "SUCCESS"){   
                component.set("v.opportunityObj",oppRec);
                loadCurrencyValues.setParams({
                    "sobjectName" : "Opportunity",
                    "picklistFieldName":"CurrencyIsoCode"
                });
                loadCurrencyValues.setCallback(this, function(response) {
                    var state = response.getState();
                    var options = response.getReturnValue();
                    console.log('options = '+options);
                    console.log('currency = '+oppRec.CurrencyIsoCode);
                    var currencyCodes = [];
                    currencyCodes.push(oppRec.CurrencyIsoCode);
                    if (component.isValid() && state === "SUCCESS"){ 
                        for (let i = 0; i < options.length; i++) { 
                            console.log('option = '+options[i]);
                            if(options[i] != oppRec.CurrencyIsoCode) {
                            	currencyCodes.push(options[i]);    
                            }
                        }
                        component.set("v.currencyValues",currencyCodes);
                    }
                });
                $A.enqueueAction(loadCurrencyValues);
            }
        });
        $A.enqueueAction(loadOppDetails);
    },
    
    confirm : function(component, event, helper) {
        var checkErrorDetails = component.get("c.checkErrors");
        var performSaveOperation = component.get("c.convertCurrency");
        var ErrDetailsData = component.find("ErrorMessageId");
        checkErrorDetails.setParams({
            "pageObject" : component.get("v.opportunityObj")
        });
        checkErrorDetails.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if (component.isValid() && result === "Success"){   
                performSaveOperation.setParams({
                    "pageObject" : component.get("v.opportunityObj")
                });
                performSaveOperation.setCallback(this, function(response) {
                    var state = response.getState();
                    var message = response.getReturnValue();
                    console.log('state in Save == '+result);
                    if (component.isValid() && state === "SUCCESS" && message == "Success"){ 
                        $A.util.removeClass(ErrDetailsData, 'slds-show');
                        $A.util.addClass(ErrDetailsData, 'slds-hide');
                        var navEvent = $A.get("e.force:navigateToSObject");
                        navEvent.setParams({
                            recordId: component.get("v.opportunityObj").Id,
                            slideDevName: "detail"
                        });
                        navEvent.fire(); 
                        //$A.get('e.force:refreshView').fire();
                    } else {
                    	component.set("v.ErrorMessage",'An internal error has occured while processing your request. Please contact Salesforce IT operations for further assistance');
                		$A.util.removeClass(ErrDetailsData, 'slds-hide');
                		$A.util.addClass(ErrDetailsData, 'slds-show');    
                    }
                });
                $A.enqueueAction(performSaveOperation);
            } else {
                component.set("v.ErrorMessage",result);
                $A.util.removeClass(ErrDetailsData, 'slds-hide');
                $A.util.addClass(ErrDetailsData, 'slds-show');
                console.log("Error == "+component.get("v.ErrorMessage"));
            }
        });
        $A.enqueueAction(checkErrorDetails);
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
    }
})