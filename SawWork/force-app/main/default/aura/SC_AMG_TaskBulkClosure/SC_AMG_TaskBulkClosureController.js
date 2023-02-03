({
	init : function(component, event, helper) {
        component.set('v.mycolumns', helper.getColumnDefinitions());
        var action = component.get('c.updateTable');
        $A.enqueueAction(action);
        
        
		
	},
    
    getOpenTaskCountMethod : function(component,event,helper){
    	helper.callServer(
            component,
            "c.openTaskCount",
            function(response){
                var returnVal = response;
                component.set("v.totalNumberOfRows", response);
                if(component.get("v.taskSize") < response)
                	component.set("v.enableInfiniteLoading", true);
                else
                    component.set("v.enableInfiniteLoading", false);    
                
                
                component.set("v.loadSpinner", false);
            }, 
            {
                "caseId" : component.get('v.recordId')
            });
    },
    updateTable : function(component,event,helper){
        component.set("v.loadSpinner", true);
        helper.callServer(
            component,
            "c.allOpenTaskRelatedToCase",
            function(response){
                var returnVal = response;
                component.set("v.taskList", returnVal);
                component.set("v.taskSize", returnVal.length);
                component.set("v.currentCount", component.get("v.initialRows"));
                
                var action = component.get('c.getOpenTaskCountMethod');
                $A.enqueueAction(action);
            }, 
            {
                "caseId" : component.get('v.recordId'),
                "recordLimit": component.get("v.initialRows"),
                "recordOffset": component.get("v.rowNumberOffset")
            });
    },
    getSelectedName: function (component, event) {
        var selectedRows = event.getParam('selectedRows');
        if ( selectedRows[0] ){
            component.set('v.rowSelected',true);
        } else {
            component.set('v.rowSelected',false);	
        }
        var allSelectedRows = [];
        for ( var i = 0; i < selectedRows.length; i++ ) {
            allSelectedRows.push(selectedRows[i].Id );
        }
        component.set('v.selectedIds',allSelectedRows);
    },
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var taskId = event.getParam('row').Id;
        component.set("v.loadSpinner", true);
        if(action.name == "edit")
        {
            var editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": taskId
            });
            editRecordEvent.fire();
            component.set("v.loadSpinner", false);
        } else if(action.name == "close")
        {
            var selectedIdsList = [];
            selectedIdsList.push(row.Id)
            helper.callServer(
                component,
                "c.updateBulkTaskStatus",
                function(response){
                    var returnVal = response;
                    if(returnVal == ''){
                        helper.showToastMessage(component, event, helper,"","Success: Task closed!","success","dismissable");
                    	component.set("v.loadSpinner", false);
                        component.set('v.taskList',[]);
                    	$A.get('e.force:refreshView').fire();
                    } else {
                        helper.showToastMessage(component, event, helper,"","Error:"+returnVal,"error","dismissable");
                        component.set("v.loadSpinner", false);
                    }
                }, 
                {
                    "status" : "Completed",
                    "taskIdsList" : selectedIdsList
                });
            
        }
        
    
    },
    updateTaskStatus: function (component, event, helper) {
        component.set('v.displayModal',false);
        component.set("v.loadSpinner", true);
        
        var statusValue = component.get('v.statusValue');
        var selectedIds = component.get('v.selectedIds');
        var selectedIdsList = [];
        for(var i =0 ; i < selectedIds.length; i++){
                selectedIdsList.push(selectedIds[i])
            }
        helper.callServer(
            component,
            "c.updateBulkTaskStatus",
            function(response){
                var returnVal = response;
                if(returnVal == ''){
                    helper.showToastMessage(component, event, helper,"","Success: Task status updated!","success","dismissable");
                    $A.get('e.force:refreshView').fire();
                    component.set('v.taskList',[]);
                    component.set("v.loadSpinner", false);
                    $A.get('e.force:refreshView').fire();
                    
                } else {
                    helper.showToastMessage(component, event, helper,"",returnVal,"error","dismissable");
                    component.set("v.loadSpinner", false);
                }
                
            }, 
            {
                "status" : statusValue,
                "taskIdsList" : selectedIdsList
            });
    },
    createNewTask : function(component, event, helper){
        component.set("v.loadSpinner", true);
        component.set('v.displayModalRT',false);
        
        var action = component.get("c.getRecTypeId");
        var recordTypeLabel = component.get('v.selectedRT');
        action.setParams({
            "recordTypeLabel": recordTypeLabel
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.loadSpinner", false);
                var createRecordEvent = $A.get("e.force:createRecord");
                var RecTypeID  = response.getReturnValue();
                var whatId = component.get('v.recordId');
                createRecordEvent.setParams({
                    'entityApiName': 'Task',
                    'recordTypeId': RecTypeID,
                    'defaultFieldValues' : {
                        'WhatId' :  whatId
                    }
                });
                createRecordEvent.fire();
          
            } else  {
                component.set("v.loadSpinner", false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please contact your administrator"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
        
        
    },
    createNewEvent : function(component, event, helper){
        var createAcountContactEvent = $A.get("e.force:createRecord");
        createAcountContactEvent.setParams({
            "entityApiName": "Event",
            "defaultFieldValues": {
                'WhatId' :  component.get('v.recordId')
            }
        });
        createAcountContactEvent.fire();
    },
    closeModal: function(component, event, helper){
        component.set('v.displayModal',false);
    },
    showPopupModal: function(component, event, helper){
        component.set('v.displayModal',true);
    },
    
    updateColumnSorting: function (component, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    fetchListOfRecordTypes: function(component, event, helper) {
        component.set("v.loadSpinner", true);
        component.set('v.displayModalRT',true);
        var action = component.get("c.fetchRecordTypeValues");
        action.setCallback(this, function(response) {
            component.set("v.lstOfRecordType", response.getReturnValue());
            component.set("v.loadSpinner", false);
            component.set("v.selectedRT", response.getReturnValue()[0]);
        });
        $A.enqueueAction(action);
    },
    
    
    handleLoadMoreTask: function (component, event, helper) 
    {
        
        event.getSource().set("v.isLoading", true);
        component.set('v.loadMoreStatus', 'Loading Cases...');
        helper.getMoreTask(component, component.get('v.rowsToLoad'))
        .then($A.getCallback(function (data) 
                             {
                                 if (component.get('v.taskList').length == component.get('v.totalNumberOfRows')) 
                                 {
                                     console.log('NOTHING MORE TO LOAD');
                                     component.set('v.enableInfiniteLoading', false);
                                     component.set('v.loadMoreStatus', 'No more data to load');
                                     component.set("v.taskSize", component.get('v.totalNumberOfRows'));
                                 } 
                                 else 
                                 {
                                     var currentData = component.get('v.taskList');
                                     var newData = currentData.concat(data);
                                     component.set('v.taskList', newData);
                                     console.log('New Data Length : ' + newData.length);
                                     component.set('v.loadMoreStatus', 'Scroll down to load more!');
                                 }
                                 event.getSource().set("v.isLoading", false);
                             }));
        
    },
    
    
    closeModalRT: function(component, event, helper){
		component.set('v.displayModalRT',false);
    },
    showPopupModalRT: function(component, event, helper){
        component.set('v.displayModalRT',true);
    },
})