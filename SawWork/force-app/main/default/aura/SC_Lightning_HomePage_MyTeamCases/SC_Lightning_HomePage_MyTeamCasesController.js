({
    
    doInit: function(component, event, helper) {
       
       setTimeout(function(){ 
       
           helper.getMyTeamCases(component,event,helper);
       }, 2000);

    },
    
    //Method - 2 : Opening the Case Clicked into new console tab
    openNewTab:function(component, event, helper) {
        var ID = event.target.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":ID,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
                // console.log("The recordId for this tab is: " + tabInfo.recordId);
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
    handleSelect: function (component, event, helper) {
      
        var selectedMenuItemValue = event.getParam("value");
         if(selectedMenuItemValue=='Refresh')
         {
              helper.getMyTeamCases(component,event,helper);
         }
         
     },
    
})