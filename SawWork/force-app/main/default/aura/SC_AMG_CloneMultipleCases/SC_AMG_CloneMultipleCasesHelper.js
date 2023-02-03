({
closeCaseTab:function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            console.log('focused//'+response);
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        }).catch(function(error) {
            console.log(error);
        });
    }
})