({
    init: function(component, event, helper) 
    {
        component.set("v.loadSpinner",true);
        component.set("v.loadButtonSpinner",true);
        component.set("v.columns", 
                      [
                        {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, 
                        initialWidth: 125,
                        cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                          {label:"Age", fieldName:"agedays", type:"number", sortable: true, initialWidth:60, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
                          {label:"Due In", fieldName:"sla", type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }},sortable: true},
                          {
                              label:"Account", 
                              fieldName:"accountName",
                              type:'button',
                              variant: 'container',
                              fixedWidth: 125, 
                              typeAttributes: 
                              {
                                  label: {fieldName: 'accountName'},
                                  variant:'base',
                                  name:'accountName'
                              }, 
                              sortable: true,
                              cellAttributes:{class:'leftAlign'}
                          },
                          {label:"Service", fieldName:"service", type:"text", sortable: true},
                          {label:"Request Type", fieldName:"requestType", type:"text", sortable: true},
                          {label:"Subject", fieldName:"subject", type:"text", sortable: true}
                      ]);
        
        var isUserManagerVal = false;
        var filterVal = "My Open Cases";
        
        //component.set("v.loadSpinner",true);
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                if(result)
                    component.set("v.filterVal", 'My Team\'s Open Cases with SLA running');

                helper.getTotalNumberOfCases(component);

                var filterVal = component.get("v.filterVal");
                helper.callServer(
                    component,
                    "c.getCaseListForAMG",
                    function(result)
                    {
                        var caseListVar = '';
                        caseListVar = result;
                        component.set("v.data",caseListVar);
                        component.set("v.dataFiltered",caseListVar);
                        component.set("v.casesCount",caseListVar.length);
                        component.set("v.currentCount", component.get("v.initialRows"));
                        helper.sortData(component, 'sla', 'asc');
                        component.set("v.loadSpinner",false);
                    },
                    {
                        "ownerFilterValue":  filterVal,
                        "userOrQueue": "user",
                        "recordLimit": component.get("v.initialRows"),
                        "recordOffset": component.get("v.rowNumberOffset")
                    }
                );
            }
        );
        
        
        var interval = window.setInterval(
            $A.getCallback(function() {
                var action = component.get('c.updateTable');
                $A.enqueueAction(action);
            }), 150000
        ); 
        component.set("v.setIntervalId", interval) ;
        
    },
    //method to destory the setInterval value
    handleDestroy: function (cmp) {
        window.clearInterval(cmp.get("v.setIntervalId"));
    },
    
    handleRowAction: function(component,event,helper)
    {
        var caseRecId = event.getParam('row').caseRecId;
        var actionName = event.getParam('action').name;
        if(actionName == "akamcaseid")    
        {
            var row = event.getParam('row');
            var columns = event.getParam('columnDefinition');
            var fieldName = event.getParam('fieldName');
            var rId = row.caseRecId;
            helper.openConsoleTab(component, event, rId);
        }
        else
            if(actionName == "accountName")    
            {
                var row = event.getParam('row');
                var fieldName = event.getParam('fieldName');
                var rId = row.accountId;
                helper.openConsoleTab(component, event, rId);
            }
    },    
    
    
    updateTable: function(component, event, helper)
    {
        helper.getTotalNumberOfCases(component);
        helper.refreshTable(component, event);
        
    },
    
    handleLoadMoreCases: function (component, event, helper) 
    {
        event.getSource().set("v.isLoading", true);
            component.set('v.loadMoreStatus', 'Loading Cases...');
            helper.getMoreCases(component, component.get('v.rowsToLoad'))
            .then($A.getCallback(function (data) 
            {
                if (component.get('v.data').length == component.get('v.totalNumberOfRows')) 
                {
                    component.set('v.enableInfiniteLoading', false);
                    component.set('v.loadMoreStatus', 'No more data to load');
                    event.getSource().set("v.isLoading", false);
                } 
                else 
                {
                    var currentData = component.get('v.dataFiltered');
                    var newData = currentData.concat(data);
                    component.set('v.data', newData);
                    component.set('v.dataFiltered', newData);
                    component.set('v.casesCount',newData.length);
                    component.set('v.loadMoreStatus', 'Scroll down to load more!');
                }
                event.getSource().set("v.isLoading", false);
            }));
    },
    
    updateColumnSorting: function (component, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    
    showSpinner: function(component, event, helper) {
        component.set("v.loadSpinner",true);
    },
    
    hideSpinner: function(component, event, helper) {
        component.set("v.loadSpinner",false);
    },
    
    spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    }
});