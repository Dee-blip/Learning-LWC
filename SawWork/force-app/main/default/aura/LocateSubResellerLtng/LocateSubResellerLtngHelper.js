({
    //getting column header with field name 
    getColumn: function(component, event, helper) {
        component.set('v.columns', [{
                label: 'Action',
                type: 'button',
                iconName :'standard:actions_and_buttons',
                typeAttributes: {
                    label: 'Link',
                    name: 'Link_Sub_Reseller',
                    title: 'Click',
                    iconName: 'utility:link',
                    variant: 'base'
                }
            },
            {label: 'ACCOUNT NAME',
                fieldName: 'linkName',
                type: 'url',
                iconName: 'standard:account',
                typeAttributes: {
                    label: {
                        fieldName: 'Name'
                    },
                    target: '_blank'
            }
            },
           {
                label: 'WEBSITE',
                fieldName: 'Website',
                type: 'url',
                typeAttributes: {
                    label: {
                        fieldName: 'Website'
                    },
                    target: '_target'
                }
            },
           {
                label: 'BILLING COUNTRY',
                fieldName: 'BillingCountry',
                type: 'text'
            },
            {
                label: 'BILLING STATE',
                fieldName: 'BillingState',
                type: 'text'
            },
            {
                label: 'ACCOUNT OWNER',
                fieldName: 'OwnerName',
                type: 'text'
            },
            {
                label: 'ACCOUNT STATUS',
                fieldName: 'Account_Status__c',
                type: 'text'
            }
        ]);
    },

    intialiZeData: function(component, event, helper, isManual) {
        component.set("v.pageUtil.spinner", true);
        helper.returnPromise(component.get('c.getuserTheme')).then(
            function(res) {  
                component.set("v.pageUtil.isClassic", res);
                return helper.returnPromise(component.get('c.getIntialsubresellerdetail'), {
                    'opptyId': component.get("v.recordId")
                });
            },
            function(reject) {    
                // promise reject code goes here 
            }
        ).then(
            function(res) {

                if (res != "undefined" && res != null & res != " ") {
                    var subResellerName = (isManual == true) ? component.find("searchSrname").get("v.value").trim() : res.subreSellerName;

                     if (!isManual && !res.isPartnertechdata) {
                        component.set("v.pageUtil.spinner", false);
                        helper.disableSearch(component);
                        helper.notificationLibnotice(component, event, helper, "error", "Error",component.get("v.clientWarError")[0] , "Toast");
                        return;
                    }

                    if (!isManual) {
                        component.find("searchSrname").set("v.value", res.subreSellerName);
                        component.set("v.opptyName",res.opptyName);
                        let isMissing = helper.checkfieldValidity(component, event, helper, component.find("searchSrname"), 3);
                        if(isMissing)
                        {
                          component.set("v.pageUtil.isloadDisabled", true);
                          return;
                        }

                     }

                    
                    return helper.returnPromise(component.get('c.getSubreseller'), {
                        "recordLimit": component.get("v.initialRows"),
                        "recordOffset": component.get("v.rowNumberOffset"),
                        'opptyId': component.get("v.recordId"),
                        'resellerName': subResellerName
                    });
                }
            },
            function(err) {
                console.error("Error in Finding Intial Sub reseller detail ==>"+err);
                component.set("v.pageUtil.spinner", false);
                helper.disableSearch(component);
                helper.notificationLibnotice(component, event, helper, "error", "Error", err, "Notice");
    
            }
        ).then(function(res) {
            if (res != "undefined" && res != null && res != " ") {
                component.set("v.totalNumberOfRows", res.totalRows);
                component.set("v.data", helper.prasetoLdcompatible(component, res.accList, "Account"));
                component.set("v.currentCount", component.get("v.initialRows"));
                if (component.get("v.totalNumberOfRows") > 10) {
                    component.set("v.pageUtil.isloadDisabled", false);
                    component.set('v.loadMoreStatus', component.get("v.clientWarError")[3]);
                } else {
                    component.set("v.pageUtil.isloadDisabled", true);
                    component.set('v.loadMoreStatus', component.get("v.clientWarError")[2]);
                }
                component.set("v.pageUtil.spinner", false);
            }
            component.set("v.pageUtil.spinner", false);
    
        }, function(err) {
            console.error("Error in Finding Sub-Reseller List==>"+err);
            component.set("v.pageUtil.spinner", false);
            helper.disableSearch(component);
            helper.notificationLibnotice(component, event, helper, "error", "Error", err, "Notice");
    
        });
    },


    returnPromise: function(action, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            if (params) {
                action.setParams(params);
            }
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());

                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        reject(errors[0].message);
                    }
                } else {
                    reject(component.get("v.clientWarError")[1]);
                }
            });
            $A.enqueueAction(action, false);
        }));
    },

    updateReseller: function(component, event, helper, linkedAccountId) {
        component.set("v.pageUtil.spinner", true);
        var action = component.get("c.updateSubreseller");
        action.setParams({
            'linkedAccountId': linkedAccountId,
            'OpportunityId': component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.pageUtil.spinner", false);
                var opptyName = component.get("v.opptyName");
                helper.notificationLibnotice(component, event, helper, "Success", " ", 'Opportunity '+'\"'+opptyName+'\"' + ' was saved.', "Toast");
                this.navigatetoURL(component, event, helper, component.get("v.recordId"));
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set("v.pageUtil.spinner", false);
                    this.notificationLibnotice(component, event, helper, "error", "Error", errors[0].message, "Notice");
                }
            } else {
                this.notificationLibnotice(component, event, helper, "error", "Error", errors[0].message, "Notice");
            }
        });
        $A.enqueueAction(action);
    },
    //navigation function for lightning/classic 
    navigatetoURL: function(component, event, helper, recordId) {
        if (component.get("v.pageUtil.isClassic")) {
            helper.fireCustomevent(component, event, helper, recordId, "force:navigateToURL");
        } else {
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }
    },

// this method takes care of firing Application custom event in containmation hierchay here used for collection event at VF page
    fireCustomevent: function(component, event, helper, recordId, action) {
        var eventDef = $A.get("e.c:LocateSubResellerVFevent");
        eventDef.setParams({
            "msg": action,
            "recordId": component.get("v.recordId")
        });
        eventDef.fire();
    },
    notificationLibnotice: function(component, event, helper, variant, header, message, type) {
       if   (component.get("v.pageUtil.isClassic")) {
            component.set("v.pageUtil.isMessageVisible", true)
            component.set("v.pageUtil.messageSeverity", variant == "Success" ? "confirm":variant);
            component.set("v.pageUtil.messageTitle", header);
            component.set("v.pageUtil.colasable", false);
            component.set("v.pageUtil.messgaeDetail", message);
        }
        else {
        switch (type) {
            case "Toast":
                helper.showLibtoast(component, event, helper, variant, header, message)
                break;  
            default:
                helper.showlibNotice(component, event, helper, variant, header, message)
                break;
        }
    }
    },
    showlibNotice: function(component, event, helper, variant, header, message) {
        component.find('notifLib').showNotice({
            "variant": variant,
            "header": header,
            "message": message,
            closeCallback: function() {

            }
        });
    },
    showLibtoast: function(component, event, helper, variant, header, message) {
        component.find('notifLib').showToast({
            "title": header,
            "variant": variant,
            "message": message
        });
    },



    checkfieldValidity: function(component, event, helper, fieldDef, len) {
        var trimmedValue = fieldDef.get("v.value").trim();
        var isValuemissing = trimmedValue.length < len || fieldDef.get("v.validity").valueMissing ? true : false;
        return isValuemissing;
    },

    // get more accounts on load more button 
    getMoreAccount: function(component, rows) {
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get('c.getSubreseller');
            var recordOffset = component.get("v.currentCount");
            var recordLimit = component.get("v.initialRows");
            action.setParams({
                "recordLimit": recordLimit,
                "recordOffset": recordOffset,
                'opptyId': component.get("v.recordId"),
                'resellerName': component.find("searchSrname").get("v.value")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    resolve(response.getReturnValue());
                    recordOffset = recordOffset + recordLimit;
                    component.set("v.currentCount", recordOffset);
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        console.log("getMore accounts error" + errors[0].message);
                        reject(errors[0].message);
                    }
                    reject(component.get("v.clientWarError")[1]);
                } else {
                    reject(component.get("v.clientWarError")[1]);
                }
            });
            $A.enqueueAction(action, false);
        }));

    },

    resetData: function(component, event, helper) {

        component.set("v.data", {});
        component.set("v.enableInfiniteLoading", true);
        component.set("v.initialRows", 10);
        component.set("v.rowsToLoad", 10);
        component.set("v.totalNumberOfRows", 0);
        component.set("v.loadMoreStatus", " ")
        component.set("v.rowNumberOffset", 0);
        component.set("v.loadMoreOffset", 20);
        component.set("v.rowsToAdd", 10);
        component.set("v.currentCount", 0);

    },

   disableSearch : function(component)
   {
                          component.set("v.pageUtil.searchDisabled", true);
                         component.set("v.pageUtil.isloadDisabled", true);
                         component.find("searchSrname").set("v.disabled", true);
                         component.find("searchSrname").set("v.value", null);
                         component.find("searchSrname").set("v.placeholder", "Search not allowed !");
   },
    prasetoLdcompatible: function(component, records, objectName) {
        records.forEach(function(record) {
            record.OwnerName = record.Owner.Name;
            record.linkName = component.get("v.pageUtil.isClassic") ? '/' + record.Id : '/lightning/r/' + objectName + '/' + record.Id + '/view';
        });
        return records;
    }

})