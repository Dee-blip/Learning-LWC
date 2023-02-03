({
	openTab: function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getAllTabInfo().then(function(response) {
            var searchKey = 'Case Search'; 
            if(response.map(function (item) { return item.customTitle; }).indexOf(searchKey) == -1){
               	workspaceAPI.openTab({
                    pageReference: {
                        "type": "standard__component",
                        "attributes": {
                            "componentName": "c__IR_CaseSearchCmp"
                        },
                        "state": {}
                    },
            		focus: true
                }).then(function(response) {
                    workspaceAPI.setTabLabel({
                          tabId: response,
                          label: "Case Search"
                       });
                }).catch(function(error) {
                    console.log("ERROR: ",error);
                });
            }
       })
    }
})