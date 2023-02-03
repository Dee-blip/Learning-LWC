({
	init : function(component, event, helper) {
        
        helper.customVendorsList(component, event);
        var action = component.get("c.fetchDeliveryVendors");
        action.setParams({
            "tsObjId": component.get("v.tsRecId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
            	var returnVal = response.getReturnValue();
                console.log('DVs = '+returnVal);
                if (returnVal != null && returnVal != '') {
                	component.set("v.deliverVendorList", returnVal);
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    addRow : function(component, event, helper) {
        helper.addDVRecord(component, event);
	},
    
    removeRow: function(component, event, helper) {
        //Get the account list
        var vendorList = component.get("v.deliverVendorList");
        var deleteVendorList = component.get("v.deleteDeliverVendorList");
        //Get the target object
        var selectedItem = event.currentTarget;
        //Get the selected item index
        var index = selectedItem.dataset.record;
        console.log('Selected Item = '+vendorList[index].Id);
        if(vendorList[index].Id != null && vendorList[index].Id != '') {
        	deleteVendorList.push(vendorList[index]);	    
        }
        vendorList.splice(index, 1);
        component.set("v.deliverVendorList", vendorList);
        component.set("v.deleteDeliverVendorList", deleteVendorList);
        console.log('Delete Item = '+component.get("v.deleteDeliverVendorList"));
    },
    
    save: function(component, event, helper) {
        if (helper.validateVendorList(component, event)) {
            var vendorList = component.get("v.deliverVendorList");
            var trafficShareSum = 0.00;
            for (var i = 0; i < vendorList.length; i++) {
                trafficShareSum += parseFloat(vendorList[i].Vendor_Traffic_Share__c);
            }
            if(trafficShareSum > 100) {
                var trafficShareModal = component.find("trafficShareWarningId");
                $A.util.removeClass(trafficShareModal, 'slds-hide');
                $A.util.addClass(trafficShareModal, 'slds-show');
            } else {
                helper.saveVendorsList(component, event);
            }
        }
    },
    
    goBack: function(component, event, helper) {
        window.location.href = '/' + component.get("v.tsRecId");
    },

    submit: function(component, event, helper) {
        var trafficShareModal = component.find("trafficShareWarningId");
        $A.util.removeClass(trafficShareModal, 'slds-show');
        $A.util.addClass(trafficShareModal, 'slds-hide');
        helper.saveVendorsList(component, event);
    },
    
    hideWarning: function(component, event, helper) {
        var trafficShareModal = component.find("trafficShareWarningId");
        $A.util.removeClass(trafficShareModal, 'slds-show');
        $A.util.addClass(trafficShareModal, 'slds-hide');
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
    },

})