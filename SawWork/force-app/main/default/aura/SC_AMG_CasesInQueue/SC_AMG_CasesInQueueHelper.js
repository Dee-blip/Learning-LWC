({
    getMoreCases: function(component , rows)
    {
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get('c.getCaseListForAMG');
            var recordOffset = component.get("v.currentCount");
            var recordLimit = component.get("v.rowsToAdd");
            var selectedQueue = component.get("v.selectedQueue");
            action.setParams(
                {
                    "ownerFilterValue":  selectedQueue,
                    "userOrQueue":  "queue",
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
        var selectedQueue = component.get("v.selectedQueue");
        action.setParams(
            {
                "ownerFilterValue":  selectedQueue,
                "userOrQueue":  "queue"
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
        if(fieldName == 'sla')
            fieldName = 'slaInMinutes';
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.dataFiltered", data);
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
    
    openConsoleTab:function(component, event, rId) 
    {
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
        
        component.set("v.qCaseSearchText","");
        component.set("v.filteredDataCount","0");
        
        var caseDet = component.get("c.getCaseListForAMG");
        var selectedQueue = component.get("v.selectedQueue");

        if(selectedQueue == 'Transition Queue')
        {
            component.set("v.columns", 
            [
                {
                    label: 'Assign', 
                    fieldName:"hand",
                    type: 'button',
                    fixedWidth: 65, 
                    variant: 'container',
                    typeAttributes: 
                    {
                        name: 'assign',
                        label: { fieldName: 'hand' },
                        variant: 'base',
                        title: 'Assign',
                        alternativeText: 'Assign'
                    },
                    cellAttributes:{class:'assignIcon'}
                },
                //{label: 'AKAM Case ID', fieldName:"akamcaseid",type:'button', fixedWidth: 175, typeAttributes: {label: { fieldName: 'akamcaseid'},variant:'base',name:'akamcaseid'}, sortable: true},
                {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 150, cellAttributes:{class: { fieldName:'priority' }}},
                {label:"Due In", fieldName:"sla", initialWidth: 120, type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }}, sortable: true},
                {
                    label:"Account", 
                    fieldName:"accountName",
                    type:'button',
                    variant: 'container',
                    initialWidth: 230, 
                    typeAttributes: 
                    {
                        label: {fieldName: 'accountName'},
                        variant:'base',
                        name:'accountName'
                    }, 
                    sortable: true,
                    cellAttributes:{class:'leftAlign'}
                },
                {label:"Region", fieldName:"region",initialWidth:130, type:"text", sortable: true},
                {
                    label:"Contact", 
                    fieldName:"contactName",
                    type:'button',
                    variant: 'container',
                    typeAttributes: 
                    {
                        label: {fieldName: 'contactName'},
                        variant:'base',
                        name:'contactName'
                    }, 
                    initialWidth:170,
                    cellAttributes:{class:'leftAlign'}
                },
                {label:"Subject", fieldName:"subject",initialWidth:180, type:"text", sortable: true},
                {label:"Owner", fieldName:"ownername", type:"text", sortable: true},
                {label:"Visibility", fieldName:"visibility", type:"text", sortable: true,initialWidth:110},
                {label:"Transitioned", fieldName:"transitioned", type:"boolean",initialWidth:110,sortable: true,cellAttributes:{alignment:'center'}},
                {label:"Age", fieldName:"agedays", type:"number", sortable: true, cellAttributes:{alignment:'left'},initialWidth:90}            
            ]);
        }
        
        caseDet.setParams(
            {
                "ownerFilterValue":  selectedQueue,
                "userOrQueue":  "queue",
                "recordLimit": component.get("v.initialRows"),
                "recordOffset": component.get("v.rowNumberOffset")
            });
        var caseListVar = '';
        var caseListArray = [];    
        
        caseDet.setCallback(this, function(result)
                            {
                                var state = result.getState();
                                if (state === "SUCCESS")
                                {
                                    caseListVar = result.getReturnValue();
                                    component.set("v.data",caseListVar);
                                    for(var i=0; i < caseListVar.length; i++)
                                    component.set("v.dataFiltered",caseListVar);
                                    component.set("v.casesCount",caseListVar.length);
                                    component.set("v.currentCount", component.get("v.initialRows"));
                                    component.set("v.enableInfiniteLoading",true);
                                    component.set("v.loadSpinner",false);
                                }
                            }); 
        $A.enqueueAction(caseDet);
    }
})