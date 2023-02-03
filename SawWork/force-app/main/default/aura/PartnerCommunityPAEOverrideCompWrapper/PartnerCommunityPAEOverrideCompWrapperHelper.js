({
	performInit : function(component) {
        var fetchPma = component.get('c.fetchPMA');
        fetchPma.setParam('pmaId',component.get("v.recordId"));
        fetchPma.setCallback(this, function(resp){
                    	if (component.isValid()){
                        	if (resp.getState() === 'SUCCESS'){
                              console.log('callback fetch pma success and component is valid');
                              var pmaRec = resp.getReturnValue();
                                console.log(pmaRec);
                             if(pmaRec.PAE_Forecast_Override__c) {
                                        component.set('v.PAE_Forecast_DR',pmaRec.PAE_Forecast_DR__c);
                                 		component.set('v.PAE_Forecast_Monthly_Bookings',pmaRec.PAE_Forecast_Monthly_Bookings__c);
		                                component.set('v.PAE_Forecast_Closed_Deals',pmaRec.PAE_Forecast_Closed_Deals__c);
                                 		component.set('v.PAE_Forecast_Total_Contract_Value',pmaRec.PAE_Forecast_Total_Contract_Value__c);
                                  } else {
                                      component.set('v.PAE_Forecast_DR',pmaRec.Forecast_DR__c);
                                      component.set('v.PAE_Forecast_Monthly_Bookings',pmaRec.Forecast_Monthly_Bookings__c);
                                      component.set('v.PAE_Forecast_Closed_Deals',pmaRec.Forecast_Closed_Deals__c);
                                      component.set('v.PAE_Forecast_Total_Contract_Value',pmaRec.Forecast_Total_Contract_Value__c);
                                  }
                             	//component.set("v.pmaRec".pmaRec);
                            } else {
                                console.log('request failed');
                                console.log(resp);
                                console.log(resp.error[0]);
                            }
                		} else {
                    		console.log('component unavailable on callback');
                		}	
                    },'ALL');
            		$A.enqueueAction(fetchPma); 
    },
    isFormValid: function (cmp, evt) {
      console.log('isFormValid called');
      const requiredFields = cmp.find('paeForecastOverrideField') || [];
      console.log(requiredFields);
      console.log(requiredFields.length);
      var isValid = true;
      var listOfReqFields = [];
      requiredFields.forEach(e => {
        console.log('inside for each');
        console.log(e.get('v.value'));
        console.log(e.get('v.fieldName'));
        //console.log(e.get('v.value').trim().length);
      if (e.get('v.value')=='' || (e.get('v.fieldName')=='PAE_Forecast_Override__c' && e.get('v.value') == false)) {
            isValid = false;
          listOfReqFields.push(e.get('v.fieldName'));
        console.log(listOfReqFields);
        }
      });

      console.log('outside');
      console.log(listOfReqFields);
        var action = cmp.get("c.fieldAPINameToLabel");
        console.log('in fieldAPINameToLabel action');
        action.setParams({
          "fieldAPINames": listOfReqFields
        });
        action.setCallback(this, function(response){
            console.log('in callback fieldAPINameToLabel');
            var state = response.getState();
        console.log('state :', state);
            if(cmp.isValid() && state === "SUCCESS"){
                    console.log(response.getReturnValue());
                    var fieldDescribe = [];
                    var errString='';
                    fieldDescribe = response.getReturnValue();
                    console.log('fieldDescribe');
                    console.log(fieldDescribe);
                    for (var i = 0; i < fieldDescribe.length; i++) {
                        errString +=  fieldDescribe[i] + ' is a *Required Field';
                        cmp.set("v.errorMessage", errString);
                        cmp.set("v.hasError", true);
                        errString += '<br/>';
                     }
                    console.log('errString');
                    console.log(errString);
            }
          
        });
        $A.enqueueAction(action);
        console.log(isValid);
        return isValid;
}
})