({
    getMoreCases: function(component , rows)
    {
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get('c.getCaseListForAMG');
            var recordOffset = component.get("v.currentCount");
            var recordLimit = component.get("v.rowsToAdd");
            var filterValue = component.get("v.filterVal");

            var isUserManager = component.get("v.isUserManager");
            if(isUserManager)
                filterValue = 'My Team\'s Open Cases with SLA running';

            action.setParams(
                {
                    "ownerFilterValue":  filterValue,
                    "userOrQueue":  "user",
                    "recordLimit": recordLimit,
                    "recordOffset": recordOffset
                });
            action.setCallback(this, function(response) 
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS"){
                                       var resultData = response.getReturnValue();
                                       resolve(resultData);
                                       recordOffset = recordOffset+recordLimit;
                                       component.set("v.currentCount", recordOffset);   
                                   }                
                               });
            $A.enqueueAction(action);
        }));
    },
    
    getTotalNumberOfCases : function(component) 
    {
        var action = component.get("c.getCaseListForAMGCount");
        var filterValue = component.get("v.filterVal");
        action.setParams(
            {
                "ownerFilterValue":  filterValue,
                "userOrQueue":  "user"
            });
        action.setCallback(this, function(response) 
                           {
                               var state = response.getState();
                               if (state === "SUCCESS" ) 
                               {
                                   var resultData = response.getReturnValue();
                                   component.set("v.totalNumberOfRows",resultData);
                               }
                           });
        $A.enqueueAction(action);
    },
    
    sortData: function (component, fieldName, sortDirection)
     {
        var data = component.get("v.dataFiltered");
        var reverse = sortDirection !== 'asc';
        var finalData = [];
        console.log('sortDirection : ' + sortDirection);
        console.log('reverse : ' + reverse);

        if(fieldName == 'sla')
        {
            var redCaseList = [];
            var greenCaseList = [];
            var naCaseList = [];
            var slaCaseList = [];

            for(var i=0; i < data.length; i++)
            {
                if(data[i].slaColour == 'red')
                    redCaseList.push(data[i]);
                else if(data[i].slaColour == 'green')
                    greenCaseList.push(data[i]);
                else if(data[i].slaColour == 'N/A')
                    naCaseList.push(data[i]);     
                else slaCaseList.push(data[i]);
            }

            slaCaseList.sort(this.sortBy('slaInMinutes', false));
            finalData = slaCaseList.concat(redCaseList).concat(greenCaseList).concat(naCaseList);
            
            component.set("v.dataFiltered", finalData);
        }

        else
        {
            data.sort(this.sortBy(fieldName, reverse));
            component.set("v.dataFiltered", data);
        }
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

    refreshTable : function(component,event)
    {
        component.set("v.loadSpinner",true);
        var caseDet = component.get("c.getCaseListForAMG");
        var filterValue = component.get("v.filterVal");
        
        component.set("v.filteredDataCount","0");
        caseDet.setParams(
            {
                "ownerFilterValue":  filterValue,
                "userOrQueue":  "user",
                "recordLimit": component.get("v.initialRows"),
                "recordOffset": component.get("v.rowNumberOffset")
            });
        var caseListVar = '';
        
        caseDet.setCallback(this, function(result)
                            {
                                var state = result.getState();
                                if (state === "SUCCESS") 
                                {
                                    caseListVar = result.getReturnValue();
                                    component.set("v.data",caseListVar);
                                    component.set("v.dataFiltered",caseListVar);
                                    component.set("v.cases",caseListVar);
                                    component.set("v.currentCount", component.get("v.initialRows"));
                                    component.set("v.casesCount",caseListVar.length);
                                    this.sortData(component, 'sla', 'asc');
                                    component.set("v.loadSpinner",false);   
                                }
                                
                            }); 
        $A.enqueueAction(caseDet);
    }
})