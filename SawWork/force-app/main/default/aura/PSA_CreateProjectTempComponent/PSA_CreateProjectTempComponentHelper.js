({
    showToastMessage : function(type,message) 
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : message,
            message: message,
            messageTemplate: message,
            duration:' 5000',
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();                
        
    },
    navigateToCreatePage :function(accountId,oppId,component)
    {
        if(oppId === undefined && accountId === undefined)
        {
            window.location.href = '/aAE/o';
        }
        
        var navigateAction = $A.get("e.force:navigateToURL");
        
        var url = '/apex/PSA_CreateProjectFromTemplate_Page?acctId=' + accountId;
        if(oppId != undefined)
        {
            url += '&oppId='+oppId;
        }
        navigateAction.setParams(
            {
                "url": url
            }
        ).fire();        
        
        var workspaceAPI = component.find("NewCaseworkspace");        
        console.log('workspaceAPI: '+ workspaceAPI);
        //Closing Main Tab with 1 Sec Delay
        //if(workspaceAPI != undefined)
        {
            workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
                console.log('focusedTabId: '+ focusedTabId);    
            setTimeout(function(){
                workspaceAPI.closeTab({tabId: focusedTabId});
            }, 500);
           }); 
        }

    }
})