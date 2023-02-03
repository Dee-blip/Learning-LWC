({
	doInit : function(component, event, helper) {
		//component.set("v.accountId", component.get("v.iwRequestDetails.Account__c"));
	},
    updateAccount : function(component, event, helper){        
        var accountDetailsTemp = component.find("accountDetails");
        accountDetailsTemp.set("v.recordId",component.get("v.iwRequestDetails.Account__c"));
        console.log(component.get("v.recordId"));
        component.set("v.accountId", component.get("v.iwRequestDetails.Account__c"));
        accountDetailsTemp.reloadRecord();                  
    }
})