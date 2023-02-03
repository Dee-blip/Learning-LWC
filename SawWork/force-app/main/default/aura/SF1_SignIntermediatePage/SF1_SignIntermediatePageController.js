({
    doInit : function(component, event, helper) {
        var fetchOrderApproval = component.get('c.returnOrderApprovalDetails');
        var orderAppRec = null;
        fetchOrderApproval.setParams({
            "orderAppId"  : component.get("v.recordId") 
        });
        console.log("Record Id = "+component.get("v.recordId"));
        fetchOrderApproval.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") { 
                orderAppRec = response.getReturnValue();
                console.log("orderAppRec = "+orderAppRec.Id + " && "+
                            orderAppRec.Account_Primary_Country__c + " && "+
                            orderAppRec.E_Sign_Admin_Override__c);
                window.location.href = "/apex/OrderApprovalButtonPage?recordId="+orderAppRec.Id+
                                "&fromButton=SendForESignature&accountPrimaryCountry="+
                                orderAppRec.Account_Primary_Country__c+"&eSignOverride="+
                                orderAppRec.E_Sign_Admin_Override__c+"&orderExpiryDate="+
                                orderAppRec.Order_Expires_Unless_Duly_Executed_By__c;
            }
        });
        $A.enqueueAction(fetchOrderApproval);

    }
})