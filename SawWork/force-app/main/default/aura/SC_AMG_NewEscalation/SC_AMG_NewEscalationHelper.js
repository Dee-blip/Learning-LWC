({
    closeTab : function(component,event) 
    {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });	
	},
    
    closeFocusedTabAndOpenNewTab : function(component, event)
    {
        var workspaceAPI = component.find("workspace");
        var escId = component.get("v.newEscRecId");
        console.log('escId : ' + escId);
        
        workspaceAPI.getFocusedTabInfo().then(function(response) 
        {
            var focusedTabId = response.tabId;
            console.log('focusedTabId'+focusedTabId);
            workspaceAPI.openTab({
                pageReference: {
                    "type": "standard__recordPage",
                    "attributes": 
                    {
                        "recordId": escId,
                        "actionName":"view"
                    },
                    "state": {}
                },
                focus:true
            }).then(function(response) {
                var resId = response;
                workspaceAPI.closeTab({tabId : focusedTabId});
            }).catch(function(error) {
                console.log(error);
            })}).catch(function(error) {
            console.log(error);
        });   
    }
})