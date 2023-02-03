({
    getMoreTasks: function(component , rows)
    {
        return new Promise($A.getCallback(function(resolve, reject) 
        {
            console.log('GET MORE TASKS');
            var action = component.get('c.getOpenTaskAMG');
            var recordOffset = component.get("v.currentCount");
            var recordLimit = component.get("v.rowsToAdd");
            
            var filterVal = component.get("v.taskFilterVal");
            var isUserManager = component.get("v.isUserManager");
            if(isUserManager)
                filterVal = 'My Team\'s Open Tasks';
            
            action.setParams(
                {
                    "filterVal":  filterVal,
                    "recordLimit": recordLimit,
                    "recordOffset": recordOffset
                });
            action.setCallback(this, function(response) 
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var resultData = response.getReturnValue();
                                       resolve(resultData);
                                       recordOffset = recordOffset+recordLimit;
                                       component.set("v.currentCount", recordOffset);   
                                   }                
                               });
            $A.enqueueAction(action);
        }));
    },

    getTotalNumberOfTasks : function(component) 
    {
        var action = component.get("c.getOpenTaskAMGCount");
        var filterVal = component.get("v.taskFilterVal");
            var isUserManager = component.get("v.isUserManager");
            if(isUserManager)
                filterVal = 'My Team\'s Open Tasks';

        action.setParams(
            {
                "filterVal":  filterVal
            });
        action.setCallback(this, function(response) 
                           {
                               var state = response.getState();
                               if (state === "SUCCESS" ) 
                               {
                                   component.set("v.totalNumberOfRows",response.getReturnValue());
                               }
                           });
        $A.enqueueAction(action);
    },

    sortData: function (component, fieldName, sortDirection) 
    {
        var data = component.get("v.dataFiltered");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.dataFiltered", data);
    },

    sortBy: function (field, reverse, primer) 
    {
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
    
    refreshTable: function(component,event)
    {
        component.set("v.loadSpinner",true);

        if(component.get("v.taskFilterVal") == 'My Team\'s Open Tasks')
        {
            component.set("v.columns", 
            [
                {label:"Subject", fieldName:"subject" ,type:'button', typeAttributes: {label: { fieldName: 'subject' },variant:'base',name: 'taskId'}, sortable: true,cellAttributes:{class:'leftAlign'}},
                {label:"Type", fieldName:"taskType", type:"text"},
                {
                    label:"Account", 
                    fieldName:"accountName",
                    type:'button',
                    variant: 'container',
                    typeAttributes: 
                    {
                        label: {fieldName: 'accountName'},
                        variant:'base',
                        name:'accountName'
                    }, 
                    sortable: true,
                    cellAttributes:{class:'leftAlign'},
                    initialWidth: 220
                },
                {label:"Related To", fieldName:"caseRecAKAM" ,type:'button', typeAttributes: {label: { fieldName: 'caseRecAKAM' },variant:'base',name:'caseId'}, sortable: true,initialWidth: 115},
                {label:"Due Date", fieldName:"dueDate", sortable: true},
                {label:"Status", fieldName:"status",sortable: true},
                {label:"Owner", fieldName:"owner", sortable: true}
            ]);
        }
        
        var action = component.get("c.getOpenTaskAMG");
        action.setParams(
            {
                "filterVal":  component.get("v.taskFilterVal"),
                "recordLimit": component.get("v.initialRows"),
                "recordOffset": component.get("v.rowNumberOffset")
            });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if(state === "SUCCESS")
            {
                var taskListVar = response.getReturnValue();;
                component.set("v.data",taskListVar);
                component.set("v.dataFiltered",taskListVar);
                component.set("v.taskCount",taskListVar.length);
                component.set("v.currentCount", component.get("v.initialRows"));
                
            }  

			component.set("v.loadSpinner",false); 
        });
        $A.enqueueAction(action);
    }
})