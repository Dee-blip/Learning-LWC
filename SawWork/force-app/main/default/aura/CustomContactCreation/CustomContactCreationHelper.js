({
    /* 
     * Function will check that none of the required fields is empty.
     * If any required field is left blank, corresponding error message
     * will be sent
     **/
    validaterequiredFields: function (component) {
        var conFields =  component.get("v.newContact");
        var requiredEmailField = conFields.Email;
        var requiredLastNameField = conFields.LastName;
        var requiredAccountField = conFields.AccountId;
        var isPSAFormVisible = component.get("v.displayPSAForm");
        var firstName = conFields.FirstName;//MARIT-1201
        var isFirstNameMandatory = component.get("v.isFirstNameMandatory");//MARIT-1201
        
        //Trimming spaces
        if(typeof firstName !== "undefined"){
            firstName = firstName.trim();
        }
        if(typeof requiredLastNameField !== "undefined"){
            requiredLastNameField = requiredLastNameField.trim();
        }
        if(typeof requiredEmailField !== "undefined"){
            requiredEmailField = requiredEmailField.trim();
        }
      
        //MARIT-1201
        if (isFirstNameMandatory && (firstName === '' || firstName === undefined)) {
            return {
                'val' : true,
                'msg' : 'First name field must not be empty'
            }
        } else if (requiredLastNameField === '' || requiredLastNameField === undefined) {
            return {
                'val' : true,
                'msg' : 'Last name field must not be empty'
            }
        } else if (requiredEmailField === '' || requiredEmailField === undefined) {
            return {
                'val' : true,
                'msg' : 'Email address field must not be empty'                
            }
        } else if (requiredAccountField === null || requiredAccountField.length === 0) {
            // we cannot check for requiredAccountField as undefined alone because if we remove the account id from a
            // populated account id field in UI, it is not undefined. in that case we will check for its length.
            return {
                'val' : true,
                'msg' : 'Account field must not be empty'
            }
        } else if (isPSAFormVisible) {
            var requiredCurrencyIsoCodeField = conFields.CurrencyIsoCode;
            if (requiredCurrencyIsoCodeField === '' || requiredCurrencyIsoCodeField === undefined) {
                return {
                    'val' : true,
                    'msg' : 'Currency Iso Code field must not be empty'
                }
            }
        } 
        return {
            'val' : false 
        }
    },
    
    getParameterByName: function(component, event, name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    
    saveNewContactAfterValidation: function (component) {
        component.set("v.showError", false);
        var recId = component.get("v.contactRecordType").Id;
        var action = component.get("c.CheckOrCreateNewContact");
        action.setParams({ newCon : component.get("v.newContact"), recordId : recId});
        component.set("v.displaySpinner", true);
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.displaySpinner", false);
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                if (res.message === "Lead Exists") {
                    var leadId = res.id;
                    // If lead exists we will display the appropriate buttons 
                    // as per the scenarios in MARIT-204.
                    component.set("v.displayLeadExistsButtons", true);
                    component.set("v.displayContactExistsButtons", false);
                    component.set("v.displayForm", false);
                    component.set("v.navigatedId", leadId);
                    component.set("v.displayStandardButtons", false);
                } else if(res.message === "Contact Exists") {
                    var contactId = res.id;
                    // If contact exists we will display the appropriate buttons 
                    // as per the scenarios in MARIT-204.
                    component.set("v.displayLeadExistsButtons", false);
                    component.set("v.displayForm", false);
                    component.set("v.displayContactExistsButtons", true);
                    component.set("v.navigatedId", contactId);
                    component.set("v.displayStandardButtons", false);
                } else if (res.id === 'Creation failed'){
                    this.DisplayError(component, res);
                } else {
                    // If contact inserted successfully, navigate to this contact.
                    this.navigateToObject(component, res.id);
                    component.set("v.newContact",{'sobjectType':'Contact',
                                                  'FirstName': '',
                                                  'LastName': '',
                                                  'Email': '',
                                                  'AccountId': '',
                                                  'Title': '',
                                                  'Phone': '',
                                                  'Phone_Custom__c':'',
                                                  'Title_Level__c': '',
                                                  'adg_Department__c':''
                                                 });
                }
            }
            else if (state === "ERROR")
            {
                var errors = response.getError();
                if (errors) {
                    var message = errors[0].message.split('EXCEPTION, ').pop();
                    this.ShowErrorMessage(component, message); 
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    ConvertL2C : function (component) {
        component.set("v.displaySpinner", true);
        var action = component.get("c.ConvertExistingLeadToContact");
        action.setParams({ existingEmail : component.get("v.newContact.Email")});
        
        action.setCallback(this, function(response) {
            component.set("v.displaySpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                if (res.message === "Lead not found") {
                    this.ShowErrorMessage(component, res.id);
                    return;
                } else if (res.message === "Conversion failed") {
                    this.ShowErrorMessage(component, res.id); 
                    return;
                } else if (res.message === "Conversion successful")
                var address = window.location.origin + '/' + res.id;
                var urlEvent = $A.get("e.force:navigateToURL");
                if(urlEvent) {
                    urlEvent.setParams({
                        "url": address
                    });
                    
                    urlEvent.fire();
                } else {
                    window.location = address;
                }
            }
            else if (state === "ERROR")
            {
               var errors = response.getError();
                if (errors) {
                    this.ShowErrorMessage(component, errors[0].message); 
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    IgnoreAndCreateContact : function (component) {
        component.set("v.displaySpinner", true);
        var recId = component.get("v.contactRecordType").Id;
        var action = component.get("c.IgnoreAndCreateNewContact");
        action.setParams({ newContact : component.get("v.newContact"), recordId : recId});
        action.setCallback(this, function(response) {
            component.set("v.displaySpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                if (res.message === "Creation Success") {
                	this.navigateToObject(component, res.id);
                } else if (res.message === "Creation failed") {
                    this.ShowErrorMessage(component, res.id); 
                }
            }
            else if (state === "ERROR")
            {
                var errors = response.getError();
                if (errors) {
                    var message = errors[0].message.split('EXCEPTION, ').pop();
                    this.ShowErrorMessage(component, message); 
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    navigateToObject : function (component, id) {
        if (id === "") {
            id = component.get("v.navigatedId");
        }
        let address = component.get("v.returnURL");
        if(address != null && address.includes("newcontactid")) {
            address = address.replace("newcontactid", id);
        }else{
            address = window.location.origin + '/' + id;
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        if(urlEvent) {
            urlEvent.setParams({
                "url": address
            });
            
            urlEvent.fire();
        } else {
            window.location = address;
        }
    },
    
    ShowErrorMessage : function (component, message) {
        component.set("v.showError", true);
        component.set("v.errorMessage", message);
    },

    DisplayError : function (component, res) {
        var displaymsg = '';
        if (res.message.includes('STRING_TOO_LONG')) {
            displaymsg = res.message.split('STRING_TOO_LONG,').pop();
            displaymsg = displaymsg.split(':')[0];
            displaymsg += ' value too large'
        } else if (res.message.includes('EXCEPTION, ')) {
            displaymsg = res.message.split('EXCEPTION, ').pop();
        } else if (res.message.includes('REQUIRED_FIELD_MISSING')) {
            displaymsg = res.message.split('REQUIRED_FIELD_MISSING, ').pop();
            displaymsg = displaymsg.split(':')[1].replace('[','').replace(']','');
            displaymsg = 'Required Field Missing: ' + displaymsg;
        } else {
            displaymsg = res.message;
        }
        component.set("v.showError", true);
        this.ShowErrorMessage(component, displaymsg);
    },

    // Call this before page load to get the contact record type and based on that display the form
    getContactRecordType : function (component) {
        var recordTypeId = component.get("v.pageReference").state.recordTypeId;
        var action = component.get("c.FetchRecordBasedOnId");
        action.setParams({ recordId : recordTypeId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                
                component.set("v.contactRecordType", res);
                if (component.get("v.contactRecordType.DeveloperName") === 'PSA_Resource')
                {
                    component.set("v.displayPSAForm", true);
                    component.set("v.newContact.CurrencyIsoCode", 'USD');
                } else {
                    component.set("v.displayPSAForm", false);
                }
            }
            else if (state === "ERROR")
            {
                return 'Failed';
            }
        });
        $A.enqueueAction(action);
    },
    setAccountIDIfPresent : function (component, event, helper) {
        var value = helper.getParameterByName(component , event, 'inContextOfRef');
        var context = JSON.parse(window.atob(value));
        if (context.attributes.recordId !== undefined) {
            component.set("v.newContact.AccountId", context.attributes.recordId);
        } else {
            component.set("v.newContact.AccountId", null);
        }
      
        if (context.attributes.returnURL !== undefined) {
            component.set("v.returnURL", context.attributes.returnURL);
        } else {
            component.set("v.returnURL", null);
        } 
    },
    checkProfileForFirstName : function(component) { //MARIT-1201

        var action = component.get("c.checkProfileForFirstName");
        var res = false;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                res = response.getReturnValue();
                component.set("v.isFirstNameMandatory", res);
            }
            else if (state === "ERROR")
            {
                return 'Failed';
            }
          return "Passed";
        });
        $A.enqueueAction(action);

    },
    getIgnoreAndCreateButtonProfiles : function (component) {
        var action = component.get("c.checkProfileToShowIgnoreAndCreateButton");
        var res = false;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                res = response.getReturnValue();
                component.set("v.showIgnoreAndCreateButton", res);
            }
            else if (state === "ERROR")
            {
                return 'Failed';
            }
            return "Failed";
        });
        $A.enqueueAction(action);
    }
})