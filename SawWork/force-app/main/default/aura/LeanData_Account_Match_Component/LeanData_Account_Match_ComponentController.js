({
    doInit: function(component,event,helper) {
        var performCheck = component.get('c.checkRecords');
        var WarnComponent = component.find("WarnMessageId");
        var recordId = component.get('v.recordId');
        var objectName = component.get('v.sObjectName');
        var homeURL = component.get('v.homeURL');
        performCheck.setParams({
            "sObjectName":objectName,
            "recordIds":homeURL!=null?JSON.stringify(recordId):[recordId]
        });
        performCheck.setCallback(this,function(response){
            var state = response.getState();
            var message = response.getReturnValue();
            if(component.isValid() && state == 'SUCCESS')
            {
                
                var result = response.getReturnValue();
                if(result == 'Success')
                {
                    component.set("v.disableAcceptButton","false");
                	component.set("v.hasInitWarnings","false");
                }
                else
                {
                    var err=  result.split('|')[0];
                    component.set("v.hasInitWarnings","true");
                    if(err == 'Error')
	                    component.set("v.disableAcceptButton","true");
                    else
                        component.set("v.disableAcceptButton","false");
                    
                    result= result.split('|')[1];
                    
                }
                    
                component.set("v.InitErrors",result);
            }
            
        });
        $A.enqueueAction(performCheck);
    },
	updateAccount : function(component, event, helper) {
        var performSaveOperation = 	component.get('c.updateMultipleAccountControl');
        var ErrDetailsData = component.find("ErrorMessageId");
        var successSection = component.find("SuccessId");
        var homeURL = component.get('v.homeURL');
        var recordId = component.get('v.recordId');
        var objectName = component.get('v.sObjectName');
        performSaveOperation.setParams({
            "sObjectName":objectName,
            "recordIds": homeURL!=null?JSON.stringify(recordId):[recordId]
        });
        
        performSaveOperation.setCallback(this,function(response){
            var state = response.getState();
            var message = response.getReturnValue();
            if(component.isValid() && state == 'SUCCESS')
            {
                var result = response.getReturnValue();
                console.log("Result:"+result);
                if(result == 'Success')
                {
                    component.set("v.successMessage", 'Account Updated Successfully.')

                    $A.util.removeClass(ErrDetailsData, 'slds-show');
                    $A.util.addClass(ErrDetailsData, 'slds-hide');
                    $A.util.removeClass(successSection, 'slds-hide');
                    $A.util.addClass(successSection, 'slds-show');
                    
                    var locationURL = '/' + recordId;
                    var theme = null;
                    var action = component.get("c.getUIThemeDescription");
                    console.log(action);
                    action.setCallback(this, function(a) {
                        if (component.isValid()){
                            theme = a.getReturnValue();
                            if(theme == "Theme4t")
                            {
                                var urlEvent = $A.get("e.force:navigateToURL");
                                urlEvent.setParams({
                                    "url": homeURL!=null?homeURL:locationURL
                                });
                                urlEvent.fire();
                                
                            }
                            
                            else{
                                if(homeURL!= null)
                                {
                                    window.location = homeURL;
                                }
                                else
                                {
	                                window.parent.location = '/' + recordId;
                                }
                                
                            }
                        } 
                    });
                    $A.enqueueAction(action);
                }
                else
                {
                    component.set("v.ErrorMessage",message);
                    $A.util.removeClass(ErrDetailsData, 'slds-hide');
                    $A.util.addClass(ErrDetailsData, 'slds-show'); 
                    $A.util.removeClass(successSection, 'slds-show');
                    $A.util.addClass(successSection, 'slds-hide');
                }
            }
        });
        $A.enqueueAction(performSaveOperation);
		
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