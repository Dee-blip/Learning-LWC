({
    init: function(component, event, helper) 
    {
        var interval = 0;
        component.set("v.loadSpinner",true);
        
        var isUserManagerVal = false;
        var filterVal = component.get("v.taskFilterVal");
        
        var cacheValue = '';
        helper.callServer(component,"c.getDefaultListViewInCache",
                          function(result){
                              if(result!= ''){
                                  cacheValue = result;
                                  filterVal = result;
                                  component.set("v.taskFilterVal",filterVal);
                              } 
                          }, 
                          {
                              "listViewName" : "taskFilter"
                          }
                         );
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManagerVal = result;
                
                if(isUserManagerVal)
                {
                    if(!cacheValue){
                        filterVal = 'My Team\'s Open Tasks';
                    	component.set("v.taskFilterVal","My Team\'s Open Tasks");
                    }
                    
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
                else
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
                                          initialWidth: 220, 
                                          typeAttributes: 
                                          {
                                              label: {fieldName: 'accountName'},
                                              variant:'base',
                                              name:'accountName'
                                          }, 
                                          sortable: true,
                                          cellAttributes:{class:'leftAlign'}
                                      },
                                      {label:"Related To", fieldName:"caseRecAKAM" ,type:'button', typeAttributes: {label: { fieldName: 'caseRecAKAM' },variant:'base',name:'caseId'}, sortable: true,initialWidth: 115},
                                      {label:"Due Date", fieldName:"dueDate", sortable: true},
                                      {label:"Status", fieldName:"status",sortable: true}
                                  ]);
                }
                
                helper.callServer(
                    component,
                    "c.getOpenTaskAMG",
                    function(result)
                    {
                        //alert("Hello");
                        var taskListVar = result;
                        component.set("v.data",taskListVar);
                        component.set("v.dataFiltered",taskListVar);
                        //console.log('TAKSS : ' + result);
                        component.set("v.taskCount",taskListVar.length);
                        component.set("v.currentCount", component.get("v.initialRows"));
                        component.set("v.loadSpinner",false);
                    },
                    {
                        "filterVal":  filterVal,
                        "recordLimit": component.get("v.initialRows"),
                        "recordOffset": component.get("v.rowNumberOffset")
                    }
                );
            });

        helper.getTotalNumberOfTasks(component);
/*eslint-disable @lwc/lwc/no-async-operation*/
        interval = window.setInterval(
            $A.getCallback(function() 
            {
                var action = component.get('c.updateTaskTable');
                $A.enqueueAction(action);
            }), 150000
        ); 
        component.set("v.setIntervalId", interval) ;  
    },
    handleDestroy: function (cmp) {
        window.clearInterval(cmp.get("v.setIntervalId"));
    },
    updateTaskTable: function(component, event, helper)
    { 
        try{
            if(!(typeof event == 'undefined' || typeof event.getParam == 'undefined')){
                var action = component.get('c.setDefaultListViewInCache'); 
                action.setParams({
                    "listViewName" : "taskFilter" ,
                    "value" : event.getParam('value') 
                });
                $A.enqueueAction(action);
            }
        }catch(err){}
        
        
        helper.getTotalNumberOfTasks(component);
        helper.refreshTable(component,event);
        helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
    },
    
    updateColumnSorting: function (component, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    handleRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
        
        if(actionName == "taskId")
        {
            helper.openConsoleTab(component, event, row.taskRecId);
        }
        else 
            if(actionName == "caseId")
            {
                helper.openConsoleTab(component, event, row.caseRecId);
            }
            else if(actionName == "accountName")    
            {
                helper.openConsoleTab(component, event, row.accountId);
            }
    }, 
    
    filter: function(cmp, event, helper) 
    {
        var allRecords = cmp.get("v.data");
        var searchFilter = event.getSource().get("v.value").toUpperCase();
        
        var tempArray = [];
        var i;
        
        for(i=0; i < allRecords.length; i++)
        {
            if((allRecords[i].subject && allRecords[i].subject.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].caseRecAKAM && allRecords[i].caseRecAKAM.toUpperCase().indexOf(searchFilter) != -1)
              )
            {
                tempArray.push(allRecords[i]);
            }
        }
        cmp.set("v.dataFiltered",tempArray);
        cmp.set("v.filteredDataCount",tempArray.length);
    },

    handleLoadMoreTasks: function (component, event, helper) 
    {
        console.log('HANDLE LOAD MORE');
        event.getSource().set("v.isLoading", true);
        component.set('v.loadMoreStatus', 'Loading Tasks...');
        helper.getMoreTasks(component, component.get('v.rowsToLoad'))
        .then($A.getCallback(function (data) 
        {
            console.log('Data Length : ' + component.get('v.data').length);
            console.log('Total no. of rows : ' + component.get('v.totalNumberOfRows'));
                
            if (component.get('v.data').length == component.get('v.totalNumberOfRows')) 
            {
                component.set('v.enableInfiniteLoading', false);
                component.set('v.loadMoreStatus', 'No more data to load');
                event.getSource().set("v.isLoading", false);
            } 
            else 
            {
                console.log('LOAD MORE');
                var currentData = component.get('v.dataFiltered');
                var newData = currentData.concat(data);
                component.set('v.data', newData);
                component.set('v.dataFiltered', newData);
                component.set('v.taskCount',newData.length);
                component.set('v.loadMoreStatus', 'Scroll down to load more!');
                
            }
            event.getSource().set("v.isLoading", false);
            }));
    },
    
    newTask : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Task/new'            
        }).fire();
    }
    
    
});