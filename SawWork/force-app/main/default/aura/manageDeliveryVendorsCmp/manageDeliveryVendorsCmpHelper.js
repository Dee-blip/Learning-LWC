({
	addDVRecord : function(component,event) {
        var deliveryVendors = component.get("v.deliverVendorList");
        //Add New Account Record
        deliveryVendors.push({
            'sobjectType': 'Delivery_Vendor__c',
            'Name': '',
            'Vendor_Traffic_Share__c': '',
            'Traffic_Share__c': component.get("v.tsRecId")
        });
        component.set("v.deliverVendorList", deliveryVendors);
	},
    
    validateVendorList: function(component, event) {
        //Validate all account records
        var isValid = true;
        var vendorList = component.get("v.deliverVendorList");
        for (var i = 0; i < vendorList.length; i++) {
            if (vendorList[i].Vendor_Traffic_Share__c == '') {
                isValid = false;
                alert('Delivery Traffic Share cannot be blank on row number ' + (i + 1));
            } else if(vendorList[i].Delivery_Vendor__c == '--None--') {
                isValid = false;
                alert('Please Select a value for Delivery Vendor on row number ' + (i + 1));
            } else if(vendorList[i].Can_Akamai_get_more_traffic__c == '--None--') {
                isValid = false;
                alert('Please Select a value for Can Akamai Get More Traffic on row number ' + (i + 1));
            }
        }
        return isValid;
    },
     
    saveVendorsList: function(component, event, helper) {
        //Call Apex class and pass account list parameters
        var action = component.get("c.saveVendors");
        action.setParams({
            "vendorList": component.get("v.deliverVendorList"),
            "deletevendorList": component.get("v.deleteDeliverVendorList")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                if(returnVal == 'success') {
                	window.location.href = '/' + component.get("v.tsRecId");
                } else {
                	alert(returnVal);	
                }
            }
        }); 
        $A.enqueueAction(action);
    },

    customVendorsList: function(component, event, helper) {
        //Call Apex class and get vendorlist        
        var action = component.get("c.fetchVendorList");
 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                component.set("v.vendorValues", returnVal);
            }
        }); 
        $A.enqueueAction(action);
    },
})