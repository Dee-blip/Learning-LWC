({
    init: function(component, event, helper) 
    {
        component.set("v.loadSpinner",true);
        component.set("v.columns", 
        [
            {label:"Name", fieldName:"userName",type:'button', typeAttributes: {label: { fieldName: 'userName' },variant:'base',name:'userName'}, sortable: true},
            {label:"Available?", fieldName:"available", type:"text",fixedWidth: 150},
            {label:"Backup User", fieldName:"backupUserName" ,type:'button', typeAttributes: {label: { fieldName: 'backupUserName' },variant:'base',name:'backupUserName'}, sortable: true},
            {label:"Backup Available?", fieldName:"backupAvailable", type:"text",fixedWidth: 150}
        ]);
        
        var userAvail = component.get("c.getUserAvailabilility");
        userAvail.setCallback(this, function(result)
                              {
                                  var state = result.getState();
                                  if (state === "SUCCESS") 
                                  {
                                      component.set("v.loggedUser",result.getReturnValue());
                                      component.set("v.loggedUserId",result.getReturnValue().Id);
                                      
                                      console.log('loggedUserId : ' + component.get("v.loggedUserId"));
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
                              }); 
        $A.enqueueAction(userAvail);
        
        
        var interval = window.setInterval(
            $A.getCallback(function() {
                helper.updateUserTable(component,helper);
            }), 600000
        ); 
        component.set("v.setIntervalId", interval) ;
    },
    
    refreshTable: function(component, event, helper)
    { 
        helper.updateUserTable(component,helper);
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
        var userRecId = event.getParam('row').userId;
        var backupRecId = event.getParam('row').backupUserId;
        
        if(actionName == "userName")
        {
            helper.openConsoleTab(component, event, userRecId);
        }
        else 
            if(actionName == "backupUserName")
            {
                helper.openConsoleTab(component, event, backupRecId);
            }
    },
    
    openTeamAvailabilityModal: function(component,event,helper)
    {
        component.set("v.teamAvailabilityModal","true");
    },

    closeTeamAvailabilityModal: function(component,event,helper)
    {
        component.set("v.selectedUserRecord","");
        component.set("v.selectedUserRecordId","");
        component.set("v.managerData","");
        component.set("v.teamAvailabilityModal","false");
    },

    handleComponentEvent : function(component, event, helper) 
    {
        var userSelected = event.getParam("recordByEvent");
		console.log(userSelected.Name);
        helper.callServer(
            component,
            "c.fetchUserBackup",
            function(result)
            {
                component.set("v.managerData",result);
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