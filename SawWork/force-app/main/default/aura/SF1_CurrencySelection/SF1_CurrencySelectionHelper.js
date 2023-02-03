({
	isEmpty : function(val) {
		return (val ? false : true);
    },

     // var areEqual = string1.toUpperCase() === string2.toUpperCase();
    validateEvent : function (component, event) {

        var accountId = event.getParam("accountId");
        var contractIds = event.getParam("contracts");
        var currencyMisMatch = event.getParam("hasCurrencyMisMatch");
        console.log('validateEvent:currencyMistMatch=' + currencyMisMatch);

        component.get("v.opptyCurrencyPicked", "");

        //console.log('currencySelection.validateEvent, accId:' + accountId + '; contracts:' + contractIds + 'contractsSize:' + contractIds.length);

        if (!this.isEmpty(contractIds) && contractIds.length>0) { // currently contracts.length is returning lenght of the string instead of array.length
            console.log('currencySelection.validateEvent valid request.'); 
            this.getOptions(component, event);
            component.set("v.hasCurrencyMisMatch", currencyMisMatch);

        }
        else {
            console.log('currencySelection.validateEvent empty request');
            component.set("v.doneLoading", false);
            //component.set("v.hasCurrencyMisMatch", false);
        }

        //console.log('opptyBaslinePicked:' + opptyBaslinePicked + '; acc:' + acc);

        // if (opptyBaslineType == )
        // var action = component.get("c.getContractsByAccID");
        // action.setParams({acc:acc});
        // component.set("v.acc", acc); 
        // selection
        


    },

    clearAttributes : function (component, event) {

    },

	getOptions : function(component, event) {

		var action = component.get("c.getOpptyCurrencyOptions");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var optionsList = response.getReturnValue();
                //console.log("optionsList" + optionsList);
                var currencyOptions = [{
                        class: "optionClass",
                        label: "--None--",
                        value: "none",
	                    selected: "true"
                        }];
                for (var i = 0; i < optionsList.length; i++) {
                    currencyOptions.push({
                        class: "optionClass",
                        label: optionsList[i],
                        value: optionsList[i],
                        });
                    }
                //console.log(JSON.stringify(currencyOptions));
            	component.set("v.doneLoading", true);
                component.find("InputSelectDynamic").set("v.options", currencyOptions);
                //component.find("InputSelectDynamic").set("v.disabled", true);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Action State returned was: " + state);
            }
        });
        $A.enqueueAction(action);
	},

	fireCurrencyUpdateEvent: function(currencySelection) {
        //console.log("Cureency Chage Value = "+component.get("v.opptyCurrencyPicked"));
        //var currency = component.get("v.opptyCurrencyPicked");
        // Fire the event...
        var appEvent = $A.get("e.c:SF1_OnCurrencySelectionChange");
        appEvent.setParams({ "currency" : currencySelection });
        appEvent.fire();
    },

    updateCurrency: function(component, event, helper) {
	  	var selectedRadio = event.getSource().get("v.label");
        var otherCurrency = component.find("withOtherCurrency").get("v.label");
        console.log("selectedRadio=" + selectedRadio + "; otherCurrencyRadio=" + otherCurrency);

        //resultCmp = cmp.find("currency-select-result");
        //resultCmp.set("v.value", selected);
        if (selectedRadio == otherCurrency) {// if this is OtherCurrency, 
            
            var evntOppBtn = $A.get("e.c:changeCreateOpportunityButtonVisibility");
            
        	evntOppBtn.setParams({ "currencyValue" : component.get("v.opptyCurrencyPicked") });
        	console.log(evntOppBtn);
        	evntOppBtn.fire();
			component.find("InputSelectDynamic").set("v.disabled", false);
            // render the currencyDropDown.
            console.log('Currency Value == '+component.get("v.opptyCurrencyPicked"));
            component.set("v.otherCurrencyError", false);
		} else {
            component.set("v.otherCurrencyError", true);
          
            var evntCreateOppBtn = $A.get("e.c:enableCreateOpportunityButton");
            evntCreateOppBtn.fire();
            component.find("InputSelectDynamic").set("v.disabled", true);
            component.set("v.opptyCurrencyPicked", "none");
        }

        var currencySelection = component.get("v.opptyCurrencyPicked");
        console.log('inside updateCurrency.updateCurrency, pickedCurrency:' + currencySelection);
        
        this.fireCurrencyUpdateEvent(currencySelection);
		
        // var currency = component.get("v.opptyCurrencyPicked");
        // // Fire the event...
        // var appEvent = $A.get("e.c:SF1_OnCurrencySelectionChange");
        // appEvent.setParams({ "pickedCurrency" : currency });
        // //appEvent.setParams({ "acc" : acc });
        // appEvent.fire(); 
    },


})