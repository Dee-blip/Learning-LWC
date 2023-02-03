({

    openCaseCloneTab:function(component, event, helper) {
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__component",
                "attributes": {
                    "componentName": "c__SC_AMG_CloneMultipleCases"
                },
                "state": {
                    "c__caserecId": component.get("v.recordId"),
                }
            },
            focus: true
        }).then(function(response){
            workspaceAPI.setTabLabel({
                tabId: response,
                label: "Clone Case"
            });
            workspaceAPI.setTabIcon({
                tabId: response,
                icon: "action:new_case",
                iconAlt: "Clone Case"
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
})