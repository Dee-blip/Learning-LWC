({
    /*doInit: function(component, event, helper) {
        component.find("contactRecordCreator").getNewRecord(
            "Contact", // objectApiName
            null, // recordTypeId
            false, // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newContact");
                var error = component.get("v.newContactError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    console.log("Record template initialized: " + rec.apiName);
                }
            })
        );
    },*/
    doInit : function(component, event, helper) {
        helper.performInit(component);
    },
    handleLoad : function(component, event, helper) {
        component.set('v.showSpinner', false);
        $A.enqueueAction(component.get("c.showRequiredFields"));
    },

    handleSubmit : function(component, event, helper) {
        console.log('in handleSubmit');
        event.preventDefault();
        var parsedJSON = helper.isFormValid(component, event);
        console.log('parsedJSON');
        console.log(parsedJSON);
        if(!parsedJSON){
                console.log('calling parsedJSON');
                event.preventDefault();
            }
            else{
                console.log('calling else');
                component.find('recEdit').submit();
                component.set('v.disabled', true);
                component.set('v.showSpinner', true);
            }
        
    },

    handleError : function(component, event, helper) {
        component.set('v.showSpinner', false);
        component.set('v.disabled', false);
    },

    handleSuccess : function(component, event, helper) {
        component.set('v.showSpinner', false);
        component.set('v.saved', true);
        //window.location.href = '/partners/s/detail/'+component.get("v.recordId");
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    },
    
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    showRequiredFields: function(component, event, helper){
        console.log('showRequiredFields');
        
    $A.util.removeClass(component.find("paeForecastOverrideField"), "none");
        $A.util.removeClass(component.find("paeForecastOverride"), "none");
  },
    isFormValid: function (cmp, evt, helper) {
        console.log('isFormValid called');
        var requiredFields = [];
        requiredFields = cmp.find('paeForecastOverrideField') || [];
        console.log(requiredFields);
        console.log(requiredFields.length);
        var isValid = true;
        var listOfReqFields = [];
        requiredFields.forEach(e => {
        console.log('inside for each');
        console.log(e.get('v.value'));
        console.log(e.get('v.fieldName'));
        //console.log(e.get('v.value').trim().length);
        if (e.get('v.value')=='' ) {
            isValid = false;
            listOfReqFields.push(e.get('v.fieldName'));
            console.log(listOfReqFields);
          }
        });

        var action = cmp.get("c.fieldAPINameToLabel");
        console.log('in fieldAPINameToLabel action');
        action.setParams({
          "fieldAPINames": listOfReqFields
        });
        action.setCallback(this, function(response){
        var state = response.getState();
        console.log('state :', state);
        if(cmp.isValid() && state === "SUCCESS"){
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
  return isValid;
}
})