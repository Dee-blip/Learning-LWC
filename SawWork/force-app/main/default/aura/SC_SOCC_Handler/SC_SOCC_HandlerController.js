({
    doInit: function(component, event, helper) {
        var actions = [{ label: "Edit", name: "edit" }];
        component.set("v.columns", [
            {
                label: "Handler Name",
                fieldName: "linkName",
                type: "url",
                typeAttributes: { label: { fieldName: "Name" }, target: "_self" }
            },
            { label: "Handler Type", fieldName: "Handler_Type", type: "text"},
            {label:'Situations Associated',
             fixedWidth: 60,
             type:  'button',
             typeAttributes:
             {label: {fieldName: 'associatedcount'},
              variant:{fieldName: 'associatedbrand'},
              name: 'viewRecord', 
              disabled: false,
              value: 'viewBtn'}
            },
            {
                label: "Created By",
                fieldName: "Created_By",
                type: "text"
            },
            
            {
                label: "Updated By",
                fieldName: "Updated_By",
                type: "text"
            },
            {
                label: "Created Date",
                fieldName: "CreatedDate",
                type: "date",
                typeAttributes: {   day: 'numeric',   month: 'short',   year: 'numeric',  hour: '2-digit',  
                                 minute: '2-digit',  
                                 second: '2-digit',  
                                 hour12: true}
            },
            {
                label: "Last Updated Date",
                fieldName: "LastModifiedDate",
                type: "date",
                typeAttributes: {   day: 'numeric',   month: 'short',   year: 'numeric',  hour: '2-digit',  
                                 minute: '2-digit',  
                                 second: '2-digit',  
                                 hour12: true}
            },
            { type: "action", typeAttributes: { rowActions: actions } }
        ]);
        
        var action = component.get("c.getAllHandlers");
        action.setParams({
            pdId: component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            let handlerIdList = [];
            var state = response.getState();
            if (state === "SUCCESS") {
                var ServerReturn = response.getReturnValue();
                var returnValue =ServerReturn.HandlerDetails;
                var returncount=ServerReturn.no_of_associated_situations;
                if (ServerReturn.IsShiftManager === true) {
                    component.set("v.showDeleteIfManager", true);
                } else {
                    component.set("v.showDeleteIfManager", false);
                }
                
                returnValue.forEach(function(returnValue) {
                    returnValue.linkName = "/" + returnValue.Id;
                });
                
                for(var i=0;i<returnValue.length;i++)
                {	
                    returnValue[i].associatedcount=returncount[i];
                    if(returncount[i]=='0')
                    {
                        returnValue[i].associatedbrand='Destructive';                        
                    }
                    else
                    {
                        returnValue[i].associatedbrand='Brand';
                    }
                }
                
                var regex = "/<(.|\n)*?>/";
                //Modify the Object
                Object.keys(returnValue).forEach(key => {
                    //if (returnValue[key].Handler_Type__r.Name) {
                    if ("Handler_Type__r" in returnValue[key]) {
                    returnValue[key].Handler_Type =
                    returnValue[key].Handler_Type__r.Name;
                    returnValue[key].Created_By = returnValue[key].CreatedBy.Name;
                    returnValue[key].Updated_By = returnValue[key].LastModifiedBy.Name;
                    handlerIdList.push(returnValue[key].Id);
                }
                                                 });
                
                component.set("v.HandlerIdList", handlerIdList);
                
                component.set("v.data", returnValue);
                
            }
        });
        
        $A.enqueueAction(action);
    },
    handleRowAction: function(component, event, helper) {
        var action = event.getParam("action");
        var row = event.getParam("row");
        switch (action.name) {
            case "edit":
                helper.OpenHandlerEditModal(component,row);
                break;
            case "viewRecord":
                if(row.associatedcount!='0'){
                var rowid=row.Id;
                    helper.OpenSituationPopup(component,rowid);}
                break;
        }
        
    },
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false
        component.set("v.isModalOpen", false);
        component.set("v.isAssociatedSitOpen", false);
        
    },
    deleteAll: function(component, event, helper) {
        let selectedRows = component.get("v.selectedRowsForProcessing");
        if (selectedRows.length === 0) {
            let title = "Error!";
            let message = "Please select one or more records";
            let type = "error";
            helper.componentToastHandler(component, title, message, type);
        } else {
            var selectedIds = []; //Collect Handler Ids to Delete
            var inputIds = [];
            for (var i = 0; i < selectedRows.length; i++) {
                let Id = selectedRows[i].Id;
                let Name = selectedRows[i].Name;
                selectedIds.push({ Id, Name });
                                  inputIds.push(Id);
                                 }
                                   let action = component.get("c.checkforPendingInstruction");
                                  action.setParams({
                                  "incomingHandlerId":inputIds              
                                 });
                action.setCallback(this,function(response){
                    if(response.getState()==="SUCCESS")
                    {
                        var retValue = response.getReturnValue();
                        if(Object.keys(retValue).length>0)
                        {
                            component.set('v.pendingHandlersInstructions',response.getReturnValue());
                            //Open the related modal
                            component.set('v.isModalPendingInstructions',true)
                            
                        }
                        else
                        {
                            component.set("v.recordsforDeletion", selectedIds);
                            component.set("v.isModalOpenDelete", true);
                        }
                    }
                });
                $A.enqueueAction(action);
                
            }
            //Show Modal for Confiramtion
        },
            
            updateSelectedText: function(component, event, helper) 
        {
            var selectedRows = event.getParam("selectedRows");
            component.set("v.selectedRowsCount", selectedRows.length);
            component.set("v.selectedRowsForProcessing", selectedRows);
        },
            closeModelDelete: function(component, event, helper) 
        {
            component.set("v.isModalOpenDelete", false);
        },
            closeModelpendingInstruction:function(component, event, helper)
        {
            component.set("v.isModalPendingInstructions", false);
        },
            DeleteHandlerRecords: function(component, event, helper) 
        {
            let handlerIdList = [];
            let HandlerToDeleteObject = component.get("v.recordsforDeletion");
            Object.keys(HandlerToDeleteObject).forEach(key => {
                handlerIdList.push(HandlerToDeleteObject[key].Id);
            });
                
                let action = component.get("c.deleteAllHandlers");
                action.setParams({
                HandlerIdList: handlerIdList,
                pdId: component.get("v.recordId")
            });
            action.setCallback(this, function(response) {
                if (response.getState() === "SUCCESS") {
                    let title = "Success!";
                    let message = "Records Have Been Deleted";
                    let type = "success";
                    let emptyselectedrows = [];
                    helper.componentToastHandler(component, title, message, type);
                    component.set("v.isModalOpenDelete", false);
                    component.set("v.selectedRows",emptyselectedrows);
                    
                    //fire component event
                    var cmpevent = component.getEvent("handlerDeleteEvent");
                    cmpevent.fire();
                    //$A.enqueueAction(component.get('c.doInit'));
                    
                }
            });
            $A.enqueueAction(action);
        },
            destroy:function(component, event, helper) {
                component.destroy();
            },
                createHandler: function(component, event, helper) {
                    
                    let pdId = component.get("v.recordId");
                    var navService = component.find("navService");
                    var pageReference = {
                        type: "standard__component",
                        attributes: {
                            componentName: "c__SC_SOCC_Create_Handler"
                        },
                        state: {
                            c__policyDomainId: pdId
                        }
                    };
                    
                    navService.navigate(pageReference);
                }
    });