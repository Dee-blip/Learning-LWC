({
	doInit : function(component, event, helper) {
		helper.validateEvent(component, event, helper);
	},
    
    updateCurrency: function(component, event, helper) {
        helper.updateCurrency(component, event, helper);
	},

    onCurrencySelectionChange : function(component, event, helper) {
        
        var currencySelection = component.get("v.opptyCurrencyPicked");
        console.log('inside onSelectChange, pickedCurrency:' + currencySelection);
		var evntOppBtn = $A.get("e.c:changeCreateOpportunityButtonVisibility");
        evntOppBtn.setParams({ "currencyValue" : component.get("v.opptyCurrencyPicked") });
        console.log(evntOppBtn);
        evntOppBtn.fire();
        // fire the event...
        helper.fireCurrencyUpdateEvent(currencySelection);

    },
    
    handleOpptyTypeChange : function(component, event, helper) {
        var opptyBaslinePicked = event.getParam("selection");
        var withContractChange = "Create Contract Change Opportunity";
        if(opptyBaslinePicked != null && opptyBaslinePicked != '' && opptyBaslinePicked.toUpperCase() === withContractChange.toUpperCase())
        {
            component.set("v.isContractChange",true);
        }
        else{
            component.set("v.isContractChange",false);
        }
    },

    // contractChangeHandler : function(component, event, helper) {

    // },
    
})