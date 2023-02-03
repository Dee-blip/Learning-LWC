({
	getValueFromLwc : function(component, event) {
        var myEvent ;
        console.log('inside trg ent ' , event.getParam('val2') );
        
        component.set("v.inputValue",event.getParam('val1'));
        component.set("v.productName",event.getParam('val2'));
        component.set("v.cliName",event.getParam('val3'));
		if(component.get('v.strParentId')) {
            myEvent = $A.get("e.c:PSA_ProjectContractSelectToVFEvent");
            myEvent.setParams({
                currentRecId: component.get('v.inputValue'),
                productName: component.get('v.productName'),
                cliName: component.get('v.cliName')
            });
            myEvent.fire();
        }
	},

	// sendDataVFPage : function(component, event, helper) {
    //     console.log('current rec details ===> '+JSON.stringify(component.get('v.recordFields')));
    //     console.log('Parent Id  ===> '+component.get('v.strParentId'));
    //     if(component.get('v.strParentId')) {
    //         var myEvent = $A.get("e.c:PSA_ProjectContractSelectToVFEvent");
    //         myEvent.setParams({
    //             currentRecId: component.get('v.strParentId'),
    //             CurrentRecDetails: component.get('v.recordFields')
    //         });
    //         myEvent.fire();
    //     }
    // },
})