({
    init : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response){
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Close Cases"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "action:close",
                iconAlt: "Close Cases"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        helper.callServer(
            component,
            "c.getAMGCaseRecTypeId",
            function(response){
                var returnVal = response;
                component.set("v.recTypeId", returnVal);
            });
        
    },
    
    
    closeCaseModal: function(component, event, helper) {
        console.log('in close popup');
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            console.log('focused//'+response);
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        }).catch(function(error) {
            console.log(error);
        });    
    },    
    
    refreshMyOpenCasesTable: function(component, event, helper) {
        console.log('In refresh js');
        var appEvent = $A.get("e.c:refreshParentComp_Event");
        appEvent.fire();
    }
    
    
})