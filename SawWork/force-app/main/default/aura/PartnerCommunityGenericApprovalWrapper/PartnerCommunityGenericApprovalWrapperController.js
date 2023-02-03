({
	doInit : function(component, event, helper) {
		
        var recordId = component.get("v.recordId");
        console.log('Record id :'+recordId);
        //component.set("v.loadComponent",'true');
        helper.serverSideCall(component, event, helper, "c.getRecordAPIName",{recordId:recordId}).then(
            function(response) {
                console.log('Approval response received');
                console.log(response);
                component.set("v.sObjectAPIName",response);
                if (response == 'SFDC_MDF__c' || response == 'SFDC_MDF_Claim__c') {
                    console.log('load approval component');
                    component.set("v.loadComponent",'true');
                }
            }
        ).catch(
            function(error) {
                console.log(error);
                //helper.showToast(component,event,helper,"Error!","Error.","error",true);
            }
        );
	}
})