({
    doInit: function(component, event, helper)     
    {
    //     var workspaceAPI = component.find("workspace");
    //     workspaceAPI.getEnclosingTabId().then(function(tabId) {
    //         console.log('current Tab:' + tabId);
    //         component.set("v.currentTab",tabId);
    //    })
    //     .catch(function(error) {
    //         console.log(error);
    //     });
    },
    onTabFocused : function(component, event, helper)     
    {
        console.log("Tab Focused");
        //var enclosingTab = component.get("v.currentTab");
        var focusedTabId = event.getParam('currentTabId');

        //console.log('enclosingTab:' + enclosingTab);
        console.log('focusedTabId:' + focusedTabId);

        var sameTab;
        if(focusedTabId === null || focusedTabId === 'null' )
        {
            console.log('SAME!! : true');
            sameTab = 'true';
            
        }
        else
        {
            console.log('DIFF!! : false');
            sameTab = 'false';
        }
        component.set("v.currentTab",sameTab);
    },

    openInConsoleTab : function(component, event, helper) {
        console.log('In aura: ' );
        var workspaceAPI = component.find("workspace");
        var consoleUrl = event.getParam('url');
        console.log('In aura: ' + consoleUrl );
        workspaceAPI.openTab({
            url: consoleUrl,
            focus: true
        });
        
    }
       
    
})