({
    init: function(component, event, helper) 
    {
        component.set("v.loadSpinner",true);
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
                initialWidth: 280, 
                typeAttributes: 
                {
                    label: {fieldName: 'accountName'},
                    variant:'base',
                    name:'accountName'
                }, 
                sortable: true,
                cellAttributes:{class:'leftAlign'}
            },
            {label:"Region", fieldName:"region",initialWidth:150, type:"text", sortable: true},
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
                initialWidth:180,
                cellAttributes:{class:'leftAlign'}
            },
            {label:"Subject", fieldName:"subject",initialWidth:200, type:"text", sortable: true},
            {label:"Visibility", fieldName:"visibility", type:"text", sortable: true},
            {label:"Transitioned", fieldName:"transitioned", type:"boolean",sortable: true,cellAttributes:{alignment:'center'}},
            {label:"Age", fieldName:"agedays", type:"number", sortable: true, cellAttributes:{alignment:'left'}}            
        ]);
        
        component.set("v.userChosenColumns", 
                              [
                                  {label:"Name", fieldName:"userName",type:'button', 
                                   typeAttributes: {label: { fieldName: 'userName' },
                                                    variant:'base',
                                                    name:'userName'}, 
                                   },
                                  {label:"Available?", fieldName:"available", type:"text"},
                                  {label:"Backup User", fieldName:"backupUserName" ,type:'button', 
                                   typeAttributes: {label: { fieldName: 'backupUserName' },
                                                    variant:'base',
                                                    name:'backupUserName'}, 
                                  },
                                  {label:"Backup Available?", fieldName:"backupAvailable", type:"text"},
                                  {label:"Manager", fieldName:"managerName", type:"text"}
                              ]);
        
        var cacheValue = '';
        helper.callServer(component,"c.getDefaultListViewInCache",
                          function(result){
                              if(result!= ''){
                                  cacheValue = result;
                                  component.set("v.selectedQueue",result);
                              } 
                          }, 
                          {
                              "listViewName" : "queueFilter"
                          }
                         );
        // POPULATE AMG QUEUES IN QUEUE PICKLIST
        var getAMGQueues = component.get("c.getAMGQueues");
        getAMGQueues.setCallback(this, function(result)
        {
            var state = result.getState();
            if(state === "SUCCESS")
            {
                var amgQ = result.getReturnValue();
                component.set("v.amgQueue",amgQ);
                if(!cacheValue){
                    component.set("v.selectedQueue",amgQ[0]);
                }
                
                // get Case Details
                var caseDet = component.get("c.getCaseListForAMG");
                var selectedQueue = component.get("v.selectedQueue");
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
                                            component.set("v.dataFiltered",caseListVar);
                                            component.set("v.casesCount",caseListVar.length);
                                            component.set("v.currentCount", component.get("v.initialRows"));
                                            component.set("v.loadSpinner",false);
                                        }
                                    }); 
                $A.enqueueAction(caseDet);
            }
        });
        $A.enqueueAction(getAMGQueues);
        
        helper.getTotalNumberOfCases(component);
        
        var isUserManagerVal = false;
        
        component.set("v.loadSpinner",true);
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManagerVal = result;
                component.set("v.loadSpinner",false);
            }
        );
        
        
        var interval = window.setInterval(
            $A.getCallback(function() {
                var action = component.get('c.updateQueueTable');
                $A.enqueueAction(action);
            }), 600000
        );     
        component.set("v.setIntervalId", interval) ;
    },
    
    updateColumnSorting: function (component, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName,sortDirection);
    },
    
    updateSelectedText: function (component, event,helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedRowsCount', selectedRows.length);
    },
    
    refreshView: function(component,event,helper)
    {
        $A.get('e.force:refreshView').fire();  
    },
    
    handleRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        var row = event.getParam('row');
        var rId = row.caseRecId;
        var accId = row.accountId;
        var actionName = event.getParam('action').name;
        var isUserManager = component.get("v.isUserManager");
        
        if(actionName == "assign")
        {
            component.set("v.assignCaseId",rId);
            component.set("v.teamColumns", 
                          [
                              {label:"Name", fieldName:"userName",type:'button', 
                               typeAttributes: {label: { fieldName: 'userName' },
                                                variant:'base',
                                                name:'userName'}, 
                               sortable: true},
                              {label:"Role", fieldName:"atmRole", type:"text"},
                              {label:"Available?", fieldName:"available", type:"text",fixedWidth: 100},
                              {label:"Backup User", fieldName:"backupUserName" ,type:'button', 
                               typeAttributes: {label: { fieldName: 'backupUserName' },
                                                variant:'base',
                                                name:'backupUserName'}, 
                               sortable: true},
                              {label:"Backup Available?", fieldName:"backupAvailable", type:"text",fixedWidth: 200},
                              {label:"Manager", fieldName:"managerName", type:"text"}
                          ]);
            var userDet = component.get("c.fetchAccountTeamMembers");
            var userListVar = '';
            
            helper.callServer(
                component,
                "c.fetchAccountTeamMembers",
                function(result)
                {
                    component.set("v.teamData",result);
                    component.set("v.teamDataCount",result.length);
                    component.set("v.loadSpinner",false);
                },
                {
                    "accountId" : accId
                }
            );
            component.set("v.isTeamModalOpen",true);
        }
        else 
            if(actionName == "akamcaseid")    
            {
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
                else
                    if(actionName == "contactName")    
                    {
                        var row = event.getParam('row');
                        var fieldName = event.getParam('fieldName');
                        var rId = row.contactId;
                        helper.openConsoleTab(component, event, rId);
                    }
    },
    
    handleTeamRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        
        var actionName = event.getParam('action').name;
        var row = event.getParam('row');

        if(actionName == "userName" )
        {
            component.set("v.assignUserId",row.userId);
            component.set("v.assignUserName",row.userName);
        }
        else if(actionName == "backupUserName")
        {
            component.set("v.assignUserId",row.backupUserId);
            component.set("v.assignUserName",row.backupUserName);
        }

        component.set("v.isTeamModalOpen",false);
        component.set("v.isAssignUserModalOpen", true);
    },
    
    handleUserRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
        if(actionName == "userName")
        {
            component.set("v.isTeamModalOpen",false);
            component.set("v.assignUserId",row.userId);
            component.set("v.assignUserName",row.userName);
            component.set("v.isAssignUserModalOpen", true);
        }
        else
            if(actionName == "backupUserName")
        {
            component.set("v.isTeamModalOpen",false);
            component.set("v.assignUserId",row.backupUserId);
            component.set("v.assignUserName",row.backupUserName);
            component.set("v.isAssignUserModalOpen", true);
        }
    },
    
    newCase : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Case/new'            
        }).fire();
    },
    
    openModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    closeModal: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    
    openTeamModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isTeamModalOpen", true);
    },
    
    closeTeamModal: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isTeamModalOpen", false);
    },
    
    openAssignUserModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isAssignUserModalOpen", true);
    },
    
    closeAssignUserModal: function(component, event, helper) 
    {
        // Set isModalOpen attribute to false  
        component.set("v.isAssignUserModalOpen", false);
        component.set("v.userChosenData", "");
        component.set("v.amgUserSelected", "false");
        component.set("v.selectedUserRecord", "");
        component.set("v.selectedUserRecordId", "");
    },
    
    assignCaseFunction: function(component,event,helper)
    {
        component.set("v.isModalOpen", false);
        component.set("v.isTeamModalOpen", false);                  
        component.set("v.loadSpinner",true);
        
        var rId = component.get("v.assignCaseId");
        var assignCaseToUser = component.get("c.assignCase");
        assignCaseToUser.setParams(
            {
                "caseRecId":  rId
            });
        assignCaseToUser.setCallback(this, function(result)
        {
            var state = result.getState();
            if(state === "SUCCESS")
            {
                component.set("v.loadSpinner",true);
                helper.refreshTable(component,event);
                helper.showToastMessage(component, event, helper,"Case Assigned!","Now, let's get to work!","success","dismissable");
            }
            else
        {
            var error = result.getError();
            helper.showToastMessage(component, event, helper,"Error!",error[0].message,"error","dismissable");
            component.set("v.loadSpinner",false);
        }
        });
        $A.enqueueAction(assignCaseToUser);
    },
    
    assignCaseToUserFunction: function(component,event,helper)
    {
        component.set("v.isAssignUserModalOpen", false);
        component.set("v.loadSpinner",true);
        var caseId = component.get("v.assignCaseId");
        var userId = component.get("v.assignUserId");
        var assignCaseToUser = component.get("c.assignCaseToUser");
        assignCaseToUser.setParams(
            {
                "caseRecId":  caseId,
                "userId": userId
            });
        assignCaseToUser.setCallback(this, function(result)
        {
            var state = result.getState();
            if(state === "SUCCESS")
            {
                component.set("v.loadSpinner",false);
                component.set("v.userChosenData", "");
                component.set("v.amgUserSelected", "false");
                component.set("v.selectedUserRecord", "");
                component.set("v.selectedUserRecordId", "");
                helper.showToastMessage(component, event, helper,"Case Assigned!","Now, let's get to work!","success","dismissable");
                helper.refreshTable(component,event);
            }
            else
            {
                var error = result.getError();
                helper.showToastMessage(component, event, helper,"Error!",error[0].message,"error","dismissable");
                component.set("v.loadSpinner",false);
            }
        });
        $A.enqueueAction(assignCaseToUser);
    },
    
    updateQueueTable: function(component, event, helper)
    {
        try{
            if(!(typeof event == 'undefined' || typeof event.getParam == 'undefined')){
                var action = component.get('c.setDefaultListViewInCache'); 
                action.setParams({
                    "listViewName" : "queueFilter" ,
                    "value" : event.getParam('value') 
                }); 
                $A.enqueueAction(action);
            }
        }catch(err){
        }
        helper.getTotalNumberOfCases(component);
        helper.refreshTable(component,event);
        helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
    },
    
    filter: function(component, event, helper) 
    {
        var allRecords = component.get("v.data");
        var searchFilter = event.getSource().get("v.value").toUpperCase();
        
        var tempArray = [];
        var i;
        
        
        for(i=0; i < allRecords.length; i++)
        {
            if((allRecords[i].subject && allRecords[i].subject.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].accountName && allRecords[i].accountName.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].akamcaseid && allRecords[i].akamcaseid.toUpperCase().indexOf(searchFilter) != -1)
              )
            {
                tempArray.push(allRecords[i]);
            }
        }
        component.set("v.dataFiltered",tempArray);
        component.set("v.filteredDataCount",tempArray.length);
    },
    
    handleLoadMoreCases: function (component, event, helper) 
    {
        if(component.get("v.qCaseSearchText") == '')
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
        }
    },
    
    handleComponentEvent : function(component, event, helper) 
    {
        var userSelected = event.getParam("recordByEvent");

        helper.callServer(
            component,
            "c.fetchSelectedAMGUser",
            function(result)
            {
                component.set("v.amgUserSelected","true");
                component.set("v.userChosenData",result);
            },
            {
                "userId" : userSelected.Id
            }
        );
    },
    //method to destory the setInterval value
    handleDestroy: function (cmp) {
        window.clearInterval(cmp.get("v.setIntervalId"));
    }
});