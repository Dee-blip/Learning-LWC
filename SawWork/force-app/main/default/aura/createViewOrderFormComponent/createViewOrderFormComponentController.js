({
	init : function(component, event, helper) {
		helper.setDataTableHeader(component);
        helper.setDataTableRows(component);
	},
    
    back: function(component, event, helper) {
        var redirectionId = component.get("v.oppId");
        if(component.get("v.oaId") != null && component.get("v.oaId") != '') {
           redirectionId = component.get("v.oaId");
        }
        window.parent.location = '/' + redirectionId;
    },
    
    openBuyAkamaiWindow: function(component, event, helper) {
    	window.open(component.get("v.redirectionURL"), '_blank');
  	},
    
    openMomentumWindow: function(component, event, helper) {
        console.log('Momentum Window');
    	var action = component.get("c.getMomentumURL");
        var errorSection = component.find("momentumURLErrorId");
        action.setParams({
          "opportunityId": component.get("v.oppId"),
          "recordTypeId": component.get("v.recTypeId"),
          "stageName": component.get("v.oppStage"),
          "getField": component.get("v.field")
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          console.log(state);
          if (state == 'SUCCESS') {
            var returnVal = response.getReturnValue();
            console.log(returnVal);
            console.log('returnVal');
            console.log('User Theme == '+component.get("v.userTheme"));
            if (returnVal != null && returnVal != '') {
                console.log('returnVal === '+returnVal);
                if(returnVal.includes('com')) {
                	window.open(returnVal, '_blank');
                } else {
                	component.set("v.errorMessage", returnVal);
                    $A.util.removeClass(errorSection, 'slds-hide');
        			$A.util.addClass(errorSection, 'slds-show');
                }
            } else {
              var toastMessage = 'An unexpected error occurred. Please, contact your System Administrator';
              component.set("v.errorMessage", toastMessage);
              $A.util.removeClass(errorSection, 'slds-hide');
        	  $A.util.addClass(errorSection, 'slds-show');
            }
          }
        });
        $A.enqueueAction(action);
  	},
})