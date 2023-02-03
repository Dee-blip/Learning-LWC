({
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    openConsoleTab:function(component, event, rId) {
        var workspaceAPI = component.find("workspace");
        
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":rId,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
    updateUserTable: function(component,event)
    {
        component.set("v.loadSpinner",true);
        var userDet = component.get("c.fetchUserBackup");
        userDet.setParams(
            {
                "userId": component.get("v.loggedUserId")
            });
        var userListVar = '';
        userDet.setCallback(this, function(result)
                            {
                                var state = result.getState();
                                if (state === "SUCCESS") 
                                {
                                    userListVar = result.getReturnValue();
                                    component.set("v.data",userListVar);
                                    component.set("v.userCount",userListVar.length);
                                    component.set("v.loadSpinner",false);
                                }
                            }); 
        $A.enqueueAction(userDet);
    }
})