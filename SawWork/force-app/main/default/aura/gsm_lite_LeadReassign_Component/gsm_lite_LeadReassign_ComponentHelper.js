({
    performInit: function(component,event) {

        //var netMRRCurrValue = null;
        //var theme = null;
        //var action = component.get("c.getUIThemeDescription");
        var self = this;
        console.log('compy');
        console.log(JSON.stringify(component.get("v.recordId")));
        console.log(component.get("v.homeURL"));
        console.log(component.get("v.errorSelection"));

        if (!$A.util.isEmpty(component.get("v.errorSelection")) && component.get("v.errorSelection") != 'null') {
            console.log("errorSelection :" + component.get("v.errorSelection"));
            self.setErrorMessage(component.get("v.errorSelection"), self, component, true);
            return;
        }
        if ($A.util.isEmpty(component.get("v.recordId")) || component.get("v.recordId") == 'null') {
            console.log("Invalid Lead Id :" + component.get("v.recordId"));
            self.setErrorMessage("Invalid Lead Id", self, component, true);
            return;
        }


        var leadTypes = [{
                'label': 'Run Reassignment rules',
                'value': 'RunRules'
            },
            {
                'label': 'Reassign to User',
                'value': 'assignUser'
            },
            {
                'label': 'Reassign to Queue',
                'value': 'assignQ'
            },
        ];
        var akamaiPartnerInvolvedTypes = [{
                'label': 'Run Reassignment rules',
                'value': 'RunRules'
            },
            {
                'label': 'Reassign to User',
                'value': 'assignUser'
            },
            {
                'label': 'Reassign to Queue',
                'value': 'assignQ'
            },
                         {
                'label': 'Reassign to Partner User',
                'value': 'assignPU'
            },
        ];
        var partnerTypes = [
            {
                'label': 'Reassign to Partner User',
                'value': 'assignPU'
            },
        ];
        component.set('v.reassignReasonValue', null);
        
        console.log('fromVf');
        console.log(component.get("v.fromVf"));
        if (component.get("v.fromVf")) {
            console.log('inside fromVf');
            var fetchld = component.get('c.fetchLead');
            fetchld.setParams({
                'leadIds': JSON.stringify(component.get("v.recordId"))
            });
            fetchld.setCallback(this, function(resp) {
                if (component.isValid()) {
                    if (resp.getState() === 'SUCCESS') {
                        var leadRec = resp.getReturnValue();
                        component.set('v.leadObj', leadRec);
                        component.set('v.ownerId', leadRec[0].OwnerId);
                        if (leadRec[0].RecordType.Name=='Partner Lead') {
                          component.set('v.isPartnerLead',true);
                          component.set('v.changeOwneroptions', partnerTypes);
                          component.set('v.value','assignPU');
                          component.set('v.partnerAccountId',leadRec[0].Partner_Involved__c);
                          self.showUserModal(component,event,'assignPU');
                        }else if (leadRec[0].Partner_Involved__c != null) {
                          component.set('v.isPartnerLead',true);
                          component.set('v.changeOwneroptions', akamaiPartnerInvolvedTypes);
                          component.set('v.value','assignPU');
                          component.set('v.partnerAccountId',leadRec[0].Partner_Involved__c);
                          self.showUserModal(component,event,'assignPU');
                        }
                        else {
                          component.set('v.isPartnerLead',false);
                          component.set('v.changeOwneroptions', leadTypes);
                        }
                    } else {
                        console.log('request failed');
                        console.log(resp);
                        var errors = resp.getError();

                        if (errors) {
                            var msg;
                            if (errors[0] && errors[0].message) {
                                console.log('error message');
                                console.log(errors[0].message);
                                msg = errors[0].message;

                            } else if (errors[0] && errors[0].pageErrors) {
                                console.log('pageErrors message');
                                console.log(errors[0].pageErrors[0].message);
                                // DML Error

                                // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）

                                msg = errors[0].pageErrors[0].message;

                            }
                            self.setErrorMessage(msg, self, component, true);


                        }
                    }
                } else {
                    console.log('component unavailable on callback');
                }
            }, 'ALL');
            $A.enqueueAction(fetchld);
        } else {
            console.log('inside fromQA');
            var fetchldQa = component.get('c.fetchLeadQA');
            fetchldQa.setParams({
                'leadIds': component.get("v.recordId")
            });
            fetchldQa.setCallback(this, function(resp) {
                if (component.isValid()) {
                    if (resp.getState() === 'SUCCESS') {
                        console.log('callback fetch lead success and component is valid');
                        var leadRec = resp.getReturnValue();

                        //component.set('v.reassignReasonValue',leadRec.Reassign_Reason__c);
                        component.set('v.leadObj', leadRec);
                        component.set('v.ownerId', leadRec[0].ownerId);
                        console.log('record type is : '+leadRec[0].RecordType.Name);
                        //if (leadRec[0].RecordType.Name=='Partner Lead') {
                        if (leadRec[0].RecordType.Name=='Partner Lead') {
                          component.set('v.isPartnerLead',true);
                          component.set('v.changeOwneroptions', partnerTypes);
                          component.set('v.value','assignPU');
                          component.set('v.partnerAccountId',leadRec[0].Partner_Involved__c);
                          self.showUserModal(component,event,'assignPU');
                        }else if (leadRec[0].Partner_Involved__c != null) {
                          component.set('v.isPartnerLead',true);
                          component.set('v.changeOwneroptions', akamaiPartnerInvolvedTypes);
                          component.set('v.value','assignPU');
                          component.set('v.partnerAccountId',leadRec[0].Partner_Involved__c);
                          self.showUserModal(component,event,'assignPU');
                        }
                        else {
                          component.set('v.isPartnerLead',false);
                          component.set('v.changeOwneroptions', leadTypes);
                        }
                    } else {
                        console.log('request failed');
                        console.log(resp);
                        var errors = resp.getError();

                        if (errors) {
                            var msg;
                            if (errors[0] && errors[0].message) {
                                console.log('error message');
                                console.log(errors[0].message);
                                msg = errors[0].message;

                            } else if (errors[0] && errors[0].pageErrors) {
                                console.log('pageErrors message');
                                console.log(errors[0].pageErrors[0].message);
                                // DML Error

                                // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）

                                msg = errors[0].pageErrors[0].message;

                            }
                            self.setErrorMessage(msg, self, component, true);

                        }
                    }
                } else {
                    console.log('component unavailable on callback');
                }
            }, 'ALL');
            $A.enqueueAction(fetchldQa);
        }
    },
    //MARIT-934
    reAssignCTAProfileCheck : function(component){
        var self=this;
        var reassignaction = component.get('c.fetchUserProfile');
        reassignaction.setParams({
            'leadIds': component.get("v.recordId")
        });
        reassignaction.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(!result){
                    self.setErrorMessage('You do not have access to reassign a CTA, please reach out to Marketing Operations for assistance',self,component,true);
                }
            }
            
        });
        $A.enqueueAction(reassignaction);
    },
    setErrorMessage: function(msg, self, component, hide) {
        component.set("v.message", msg);
        console.log('error in message');
        console.log(component.get("v.message"));
        console.log(!$A.util.isEmpty(component.get("v.message")));
        if (!$A.util.isEmpty(component.get("v.message"))) {

            var messageIdModal = component.find("messageId");
            self.hideShowModal(messageIdModal, false);
            if (hide) {
                var changeIdModal = component.find("changeId");
                self.hideShowModal(changeIdModal, true);
            }

        }
    },

    hideShowModal: function(idModal, hide) {
        console.log('hide');
        console.log(hide);
        console.log(idModal);
        if (hide) {
            $A.util.removeClass(idModal, 'slds-show');
            $A.util.addClass(idModal, 'slds-hide');
        } else {
            $A.util.removeClass(idModal, 'slds-hide');
            $A.util.addClass(idModal, 'slds-show');

        }

    },
    backToLead: function(component, event)

    {
        var action = component.get("c.getUIThemeDescription");
        action.setCallback(this, function(a) {
            if (component.isValid()) {
                var theme = a.getReturnValue();
                console.log("Status == " + a.getState());
                console.log("Theme after Call== " + theme);
                console.log("homeURL");
                console.log(component.get("v.homeURL"));
                var id = component.get("v.recordId");
                if (theme == 'Theme4d' || theme == 'Theme4t') {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    console.log('urlEvent');
                    console.log(urlEvent)
                    urlEvent.setParams({
                        "url": component.get("v.homeURL"),
                        "isredirect": "true"
                    });
                    urlEvent.fire();
                } else {

                    window.location.href = component.get("v.homeURL");
                }
            }
        });
        $A.enqueueAction(action);


    },

    showUserModal: function(component, event, changeValue) {
        console.log('Inside show user model');
        var userIdModal = component.find("userId");
        var partnerAccountId = component.get('v.partnerAccountId');
        //var types = [];
        var types = [{
                value: "User",
                label: "User"
            },
            {
                value: "Group",
                label: "Queue"
            }
        ];
        console.log('selectedOwnerType');
        console.log(changeValue);
        if (changeValue == 'assignUser') {
            component.set("v.selectedOwnerType", "User");
            component.set("v.fieldToShowInSuggestion", "User.FirstName");
            component.set("v.queueWhereClause", ' IsActive = true ');
        }
        else if (changeValue == 'assignPU') {
            var partnerAccountId = component.get('v.partnerAccountId');
            console.log('Lead owner partner account : '+partnerAccountId);
            component.set("v.selectedOwnerType", "User");
            component.set("v.fieldToShowInSuggestion", "User.FirstName");
            console.log('contact.accountId =\''+partnerAccountId+'\' and Has_Partner_Lead_Access__c = true');
            component.set("v.queueWhereClause", 'contact.accountId = \''+partnerAccountId+'\' and Has_Partner_Lead_Access__c = true and IsActive = true');
            
        } else {
            component.set("v.selectedOwnerType", "Group");
            component.set("v.fieldToShowInSuggestion", "Name");
            var action = component.get('c.getLeadQueues');
            var ids = [];
            action.setCallback(this, function(resp) {
                if (component.isValid()) {
                    if (resp.getState() === 'SUCCESS') {
                        console.log('callback fetch lead success and component is valid');
                        console.log('queueIds');
                        console.log(resp.getReturnValue());
                        ids = resp.getReturnValue();
                        console.log('ids');
                        console.log(ids);
                        component.set("v.queueWhereClause", 'id in (' + ids + ')');
                        console.log('v.queueWhereClause');
                        console.log(component.get('v.queueWhereClause'));
                    } else {
                        console.log('request failed');
                        console.log(resp);
                        console.log(resp.error[0]);
                    }
                } else {
                    console.log('component unavailable on callback');
                }
            }, 'ALL');
            $A.enqueueAction(action);
        }
        //types.push("User");
        //        types.push("Queue");
        //types.push("Partner User");
        var self = this;
        self.hideShowModal(userIdModal, false);

    },

    saveAction: function(component, event) {
        var userInput = component.get("v.value");
        var saveld = component.get('c.save');
        var self = this;
        if ((userInput == 'assignUser' || userInput == 'assignPU' || userInput == 'assignQ') && ($A.util.isEmpty(component.get("v.ownerId")) || component.get("v.ownerId") == 'null')) {
            console.log("errorSelection :" + component.get("v.errorSelection"));
            self.setErrorMessage('Please select User/Queue', self, component, false);
            return;
        }

        console.log('ownerId in save: ' + component.get("v.ownerId"));
        console.log(component.get("v.reassignReasonValue"));
        saveld.setParams({
            'userValue': component.get("v.value"),
            'reassignReasonValue': component.get("v.reassignReasonValue"),
            'leadIds': component.get("v.recordId"),
            'OwnerId': component.get("v.ownerId")
        });
        saveld.setCallback(this, function(resp) {
            if (component.isValid()) {
                if (resp.getState() === 'SUCCESS') {
                    console.log('callback fetch lead success and component is valid');
                    /*var action = component.get("c.getUIThemeDescription");
                        action.setCallback(this, function(a) {*/
                    console.log('fromVF in save');
                    console.log(component.get("v.fromVf"));

                    if (component.get("v.fromVf")) {
                        console.log('coming in VF');
                        //Call will be from detail classic or list lightening browser/classic
                        window.location.href = component.get("v.homeURL");

                        /*if(theme == 'Theme4d') {
                                                var urlEvent = $A.get("e.force:navigateToURL");
                                                 urlEvent.setParams({
                                                    "url": component.get("v.homeURL"),
                                    "isredirect": "true"
                                                  });
                                                urlEvent.fire();  
                                            }*/
                    } else {
                        console.log('coming in QA');
                        var id = component.get("v.recordId");
                        console.log(id);
                        // sforce.one.back(true);
                        /*Can't use it as page doesn't refresh
                         * Ref: https://success.salesforce.com/issues_view?id=a1p3A000000mCpKQAU&title=force-navigatetosobject-does-not-display-the-updated-data-when-standard-edit-is-overridden-for-a-record*/
                        var urlEvent = $A.get("e.force:navigateToSObject");
                        urlEvent.setParams({
                            'recordId': id,
                            'isredirect': true,
                        });
                        urlEvent.fire();
                        //MARIT-666
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }

                } else {
                    console.log('request failed');
                    console.log(resp);
                    //console.log(resp.error[0]);
                    var errors = resp.getError();

                    if (errors) {
                        var msg;
                        if (errors[0] && errors[0].message) {
                            console.log('error message');
                            console.log(errors[0].message);
                            msg = errors[0].message;
                            
                            if( msg.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")) {
                                msg = msg.split(',')[1];
                            }

                        } else if (errors[0] && errors[0].pageErrors) {
                            console.log('pageErrors message');
                            console.log(errors[0].pageErrors[0].message);
                            // DML Error

                            // （This sample code is corner-cutting. It does not consider the errors in multiple records and fields.）

                            msg = errors[0].pageErrors[0].message;

                        }
                        self.setErrorMessage(msg, self, component, true);
                    }
                }

            } else {
                console.log('component unavailable on callback');
            }
        }, 'ALL');
        $A.enqueueAction(saveld);
    }

})