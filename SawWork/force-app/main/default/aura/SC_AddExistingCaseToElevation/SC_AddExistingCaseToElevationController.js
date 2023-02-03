({
    doInit : function(component) 
    {
        var workspaceAPI = component.find("workspace");
        var elevRecId;

        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Add Record to Elevation"
            });
        })
        .catch(function(error) {
            console.log(error);
        });

        if(component.get("v.pageReference") !== 'undefined' && component.get("v.pageReference") !== null)
        {
            console.log(component.get("v.pageReference").state.c__id);
            console.log(component.get("v.pageReference").state.c__object);
            elevRecId = component.get("v.pageReference").state.c__id;
            component.set("v.recordId",elevRecId);
            component.set("v.objectType",component.get("v.pageReference").state.c__object);
        }
    },

    handleCloseSubTab : function(component)
    {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });
    }
})