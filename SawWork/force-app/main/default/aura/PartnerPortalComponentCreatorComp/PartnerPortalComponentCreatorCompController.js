({
    doInit : function(component) {
        
                
        let componentName = "c:"+component.get("v.lightningComponentName");
        let lightningFlowName = '';
        lightningFlowName = component.get("v.lightningFlowName");
        
        if (lightningFlowName !== '' && lightningFlowName !== null) {
            componentName = 'c:PartnerPortalFlowWrapper';
        }
        $A.createComponent(
            componentName,
            {
                "lightningFlowName": lightningFlowName
            },
            
            function(formComp, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    let body = component.get("v.body");
                    body.push(formComp);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
        
    }
})