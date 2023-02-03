({
	saveAndLinkMarketoLeadHelper : function(component, event, helper) {
        var action = component.get("c.SaveMarketoLeadAndLinkToChat");
        component.set("v.isLoad", true);
        action.setParams({ 
            newLead : component.get("v.newLead"), 
            liveChatId : component.get("v.livechatId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var returnmsg = JSON.parse(response.getReturnValue());
                if (returnmsg.Id.includes("already exists in the system.: [Email]")) {
                    component.set("v.showError", true);
                    component.set("v.isLoad", false);
                    component.set("v.errorMessage", "A Person with this email id already exists in the system.Please use Salesforce Global Search to find the record with this email.");
                } else if (returnmsg.Id.includes("INVALID_EMAIL_ADDRESS")) {
                    component.set("v.showError", true);
                    component.set("v.isLoad", false);
                    component.set("v.errorMessage", "Invalid Email entered. Kindly enter a valid email address.");
                }
                else if(returnmsg.Id.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")){
                    component.set("v.showError", true);
                    component.set("v.isLoad", false);
                    var pat = "FIELD_CUSTOM_VALIDATION_EXCEPTION";
                    component.set("v.errorMessage",returnmsg.Id.substring(returnmsg.Id.indexOf(pat) + pat.length + 2));
                } 
                else {
                    var p = component.get("v.parent");
                    component.set("v.isLoad", false);
                    p.hideCreateLeadSection(returnmsg.Id, returnmsg.Name);
                }
            }
        });
        $A.enqueueAction(action);
	},
    /* 
     * Function will check that none of the required fields is empty.
     * If any required field is left blank, corresponding error message
     * will be sent
     **/
    validaterequiredFields: function (component) {
        var leadFields =  component.get("v.newLead");
        var requiredEmailField = leadFields.Email;
        var requiredfirstName = leadFields.FirstName;
        var requiredLastNameField = leadFields.LastName;
        var requiredCompanyField = leadFields.Company;
        var requiredPhoneField = leadFields.Phone;
        var requiredCountryField = leadFields.Country;
        var requiredStateField = leadFields.State;
        
        //Trimming spaces
        if(typeof requiredfirstName !== "undefined"){
            requiredfirstName = requiredfirstName.trim();
        }
        if(typeof requiredLastNameField !== "undefined"){
            requiredLastNameField = requiredLastNameField.trim();
        }
        if(typeof requiredEmailField !== "undefined"){
            requiredEmailField = requiredEmailField.trim();
        }
        if(typeof requiredCompanyField !== "undefined"){
            requiredCompanyField = requiredCompanyField.trim();
        }
        if(typeof requiredPhoneField !== "undefined"){
            requiredPhoneField = requiredPhoneField.trim();
        }
        if(typeof requiredCountryField !== "undefined"){
            requiredCountryField = requiredCountryField.trim();
        }
        if(typeof requiredStateField !== "undefined"){
            requiredStateField = requiredStateField.trim();
        }
        
        if (requiredfirstName === '' || requiredfirstName === undefined) {
            return {
                'val' : true,
                'msg' : 'First name field must not be empty'
            }
        } else if (requiredLastNameField === '' || requiredLastNameField === undefined) {
            return {
                'val' : true,
                'msg' : 'Last name field must not be empty'
            }
        } else if (requiredCompanyField === '' || requiredCompanyField === undefined) {
            return {
                'val' : true,
                'msg' : 'Company field must not be empty'
            }
        } else if (requiredPhoneField === '' || requiredPhoneField === undefined) {
            return {
                'val' : true,
                'msg' : 'Phone field must not be empty'                
            }
        } else if (requiredEmailField === '' || requiredEmailField === undefined) {
            return {
                'val' : true,
                'msg' : 'Email address field must not be empty'                
            }
        } else if (requiredCountryField === '' || requiredCountryField === undefined) {
            return {
                'val' : true,
                'msg' : 'Country field must not be empty'                
            }
        } else if (requiredStateField === '' || requiredStateField === undefined) {
            return {
                'val' : true,
                'msg' : 'State field must not be empty'                
            }
        }
        return {
            'val' : false 
        }
    },
    ShowErrorMessage : function (component, message) {
        component.set("v.showError", true);
        component.set("v.errorMessage", message);
    }
})