({
	//SFDC-3550
    getOpptyTypes : function(component, event, helper) {
        var action = component.get("c.getOpptyTypesBasedOnContractBaseline");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                if(response.getReturnValue() != null)
                    component.set("v.opptyTypeMap",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getIntermediatePageAccess : function(component, event, helper) {
        var action = component.get("c.skipIntermediatePageForOpptyCreation");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res != null && res.skipIntermediatePage == true){
                    var amgCloseDate = new Date();
                    amgCloseDate.setDate(amgCloseDate.getDate() + res.amgCloseDateDays);
                    var evt = $A.get("e.force:createRecord");
                    evt.setParams({
                        'entityApiName':'Opportunity',
                        "defaultFieldValues": {
                            'StageName':'2. Explore Options',
                            'Deal_Type__c':'Direct',
                            'CloseDate':amgCloseDate
                        }
                    });
                    evt.fire();
                }else{
                    helper.getOpptyTypes(component, event, helper); //SFDC-3550
                    component.set("v.showIntermediatePage",true);
                }
            }
        });
        $A.enqueueAction(action);
    }
})