({
    init: function (component, event, helper) {
        console.log('init' + component.get("v.contractId"));
        var contractVar = component.get("c.setRequiredData");
        contractVar.setParams({
            "ContractIdd": component.get("v.contractId"),

        });
        contractVar.setCallback(this, function (response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var returnVal = response.getReturnValue();
                var returnValObj = JSON.parse(returnVal);
                component.set("v.listOfHirarchyItems", returnValObj);
                console.log(returnValObj);
            }
        });
        $A.enqueueAction(contractVar);
    },
    backToContract: function (component, event, helper) {
        let windowLocationJSON = JSON.stringify(window.location);
        if (windowLocationJSON.includes("lightning.force.com")) {
            sforce.one.navigateToSObject(component.get("v.contractId"));
        } else {
            windowLocationJSON = JSON.stringify(window.parent.location);
            if (windowLocationJSON.includes("/partners/")) {
                window.parent.location = '/partners/' + component.get("v.contractId");
            } else {
                window.parent.location = '/' + component.get("v.contractId");
            }
        }
    }
})