({
    fetchC2ADropDownValuesHelper : function(component) {
        var loadPicklistValues = component.get("c.loadPicklistValues");
        loadPicklistValues.setParams({
            "sobjectName": "Lead",
            "picklistFieldName": "Product_Line__c"
        });
        
        loadPicklistValues.setCallback(this, function(response) {
            var state = response.getState();
            var options = response.getReturnValue();
            console.log(' Product Line Options = '+options);
            if (component.isValid() && state == "SUCCESS") {
                component.set("v.productLines", options);
            }
            
        });
        $A.enqueueAction(loadPicklistValues);
        
        //loadSDRLeadTypePicklistValues
        
        var loadSDRLeadTypePicklistValues = component.get("c.loadSDRLeadTypePicklistValues");
        
        
        loadSDRLeadTypePicklistValues.setCallback(this, function(res) {
            var stateLT = res.getState();
            var optionsLT = res.getReturnValue();
            console.log('Lead Type Options = '+optionsLT);
            if (component.isValid() && stateLT == "SUCCESS") {
                component.set("v.leadType", optionsLT);
            }
        });
        $A.enqueueAction(loadSDRLeadTypePicklistValues);
    },
    validUserCheckHelper :  function(component) {
        var validUserCheck = component.get("c.isValidUserCheck");
        
        validUserCheck.setCallback(this, function(response) {
            var state = response.getState();
            var validUserCheckResult= response.getReturnValue();
            if (component.isValid() && state == "SUCCESS") {
                if(validUserCheckResult){
                    component.set("v.showPage",true); 
                }
                else
                {
                    component.set("v.showPage",false);
                }
                component.set("v.afterInit",true);
                console.log('Show Page '+component.get("v.showPage"));
            }
        });
        $A.enqueueAction(validUserCheck);
    },
    SDRUserCheckHelper : function(component) {
        var sdrUserCheck = component.get("c.isSDRUserCheck");
        
        sdrUserCheck.setCallback(this, function(response) {
            var state = response.getState();
            var sdrUserCheckResult= response.getReturnValue();
            if (component.isValid() && state == "SUCCESS") {
                if(sdrUserCheckResult){
                    component.set("v.showSDRLeadType",true); 
                }
                else
                {
                    component.set("v.showSDRLeadType",false);
                }
                component.set("v.afterInit",true);
                console.log('Show SDR Page '+component.get("v.showSDRLeadType"));
            }
        });
        $A.enqueueAction(sdrUserCheck);
    },
    showCancelButtonBasedOnThemeHelper: function (component) {
        var theme = null;
        var action = component.get("c.getUIThemeDescription");
        action.setCallback(this, function(a) {
            if (component.isValid()){
                theme = a.getReturnValue();
                console.log('theme '+theme);
                component.set("v.showCancelButton",true);
                if(theme == "Theme4d" || theme == "Theme4t") {
                    component.set("v.showCancelButton",false);
                }
            }
        });
        $A.enqueueAction(action);
    },
    createC2AHelper : function (component) {
        // This method is responsible for creating self gen C2A for parent record if none exists.
        var performSaveOperation = component.get("c.insertNewLead");
        var ErrDetailsData = component.find("ErrorMessageId");
        var leadRec = component.get("v.newlead");
        var prductLineValue = component.get("v.productSelected");
        var leadTypeValue = component.get("v.leadTypeSelected");
        
        console.log('Contact ID = '+component.get("v.contactId") + ' Notes = '+component.get("v.Notes")+ 'Lead Type '+leadTypeValue);
        performSaveOperation.setParams({
            "ProductLine" : component.get("v.productSelected"), 
            "Notes" : component.get("v.Notes"),
            "personRecordId" :component.get("v.contactId"),
            "LeadType" : leadTypeValue
        });
        performSaveOperation.setCallback(this, function(response) {
            var state = response.getState();
            var message = response.getReturnValue();
            if (message == "This person is both Email Opt Out and Do Not Call.") {      
                component.set("v.isDoNotCallEmailSet", true);           
                return;     
            }
            if (message.includes("Open Opportunity")) {      
                component.set("v.showError", true);    
                component.set("v.errorMsg", message);       
                return;     
            }
            console.log('state in Save == '+state +'Message '+message);
            if (component.isValid() && state === "SUCCESS")
            {
                var results = response.getReturnValue();
                var returnVals = results.split(":");
                var successSection = component.find("SuccessId");
                console.log('Return value  '+returnVals[0] +'Message '+returnVals[1]);
                
                if (returnVals[0] === "Success") {
                    
                    component.set("v.successMessage", 'Lead Created Successfully.')
                    
                    $A.util.removeClass(ErrDetailsData, 'slds-show');
                    $A.util.addClass(ErrDetailsData, 'slds-hide');
                    $A.util.removeClass(successSection, 'slds-hide');
                    $A.util.addClass(successSection, 'slds-show');
                    
                    var locationURL = '/' + returnVals[1];    
                    
                    var theme = null;
                    var action = component.get("c.getUIThemeDescription");
                    action.setCallback(this, function(a) {
                        if (component.isValid()){
                            theme = a.getReturnValue();
                            console.log('theme '+theme);
                            if(theme == "Theme4t")
                            {
                                var urlEvent = $A.get("e.force:navigateToURL");
                                urlEvent.setParams({
                                    "url": locationURL
                                });
                                urlEvent.fire();
                                
                            } else
                                window.parent.location = '/' + returnVals[1]; 
                        } 
                    });
                    $A.enqueueAction(action);
                } else {
                    console.log(' Inside Error part '+results);
                    component.set("v.ErrorMessage",results);
                    $A.util.removeClass(ErrDetailsData, 'slds-hide');
                    $A.util.addClass(ErrDetailsData, 'slds-show'); 
                    $A.util.removeClass(successSection, 'slds-show');
                    $A.util.addClass(successSection, 'slds-hide');
                }
            }
        });
        $A.enqueueAction(performSaveOperation);
    },
    goToLeadOrContactOnCancel : function(component) {
        var locationURL = '/' + component.get("v.contactId");  
        var theme = null;
        var action = component.get("c.getUIThemeDescription");
        action.setCallback(this, function(a) {
            if (component.isValid()){
                theme = a.getReturnValue();
                console.log('theme '+theme);
                if(theme == "Theme4t") {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": locationURL
                    });
                    urlEvent.fire();
                } else
                    window.parent.location = '/' + component.get("v.contactId");
            } 
        });
        $A.enqueueAction(action);
    },
    hideSpinnerHelper : function(component) {
        var spinner = component.find("ltngSpinner");
        $A.util.removeClass(spinner, "slds-show");
        $A.util.addClass(spinner, "slds-hide");
    }
})