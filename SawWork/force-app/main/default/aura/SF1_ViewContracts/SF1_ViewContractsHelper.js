({
	closeModal : function(cmp){
        cmp.destroy();
    },

    queryAssociatedContracts : function (component, event, helper) {

        console.log('inside SF1_ViewContracts:QueryAssociatedContracts.');
        var action = component.get("c.getRenewalContractsByOpttyId");
        var params = { "opptyId": component.get("v.opptyId") };
        console.log(JSON.stringify(params));
        action.setParams(params);
        action.setCallback(this, function(response) {
            console.log(response.getState());
            if (response && response.getState() === "SUCCESS" && component.isValid()) {
                
                var recordset = response.getReturnValue();
                console.log('queryWithBaselineRows=' + JSON.stringify(recordset));
                component.set("v.contracts", recordset);

            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("Action State returned was: " + state);
            }
        });

        $A.enqueueAction(action);

    },
})