({
    init: function(component, event, helper) 
    {
        component.set("v.loadSpinner",true);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) 
        {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Escalations"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "standard:data_integration_hub",
                iconAlt: "Escalations"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        component.set("v.columns", 
                      [
                          {
                              label:"ID", fieldName:"escIDVal" ,type:'button',fixedWidth: 160, 
                              typeAttributes: 
                              {
                                  label: { fieldName: 'escIDVal'},
                                  variant:'base',
                                  name:'escIDVal'
                              },
                              sortable: true,
                              cellAttributes:{class:'leftAlign'}
                          },
                          {
                              label:"AKAM Case ID", fieldName:"akamcaseid" ,type:'button',fixedWidth: 160, 
                              typeAttributes: 
                              {
                                  label: { fieldName: 'akamcaseid'},
                                  variant:'base',
                                  name:'akamcaseid'
                              },
                              sortable: true,
                              cellAttributes:{class:'leftAlign'}
                          },
                          {
                              label:"Account", 
                              fieldName:"accountName",
                              type:'button',
                              variant: 'container',
                              initialWidth: 350,
                              typeAttributes: 
                              {
                                  label: {fieldName: 'accountName'},
                                  variant:'base',
                                  name:'accountName'
                              }, 
                              sortable: true,
                              cellAttributes:{class:'leftAlign'}
                          },
                          {label:"Subject", fieldName:"subject", sortable: true, type:"text"},
                          {label:"Description", fieldName:"description", sortable: true, type:"text"},
                          {label:"AKAM Created Date", fieldName:"akamcreateddate", type:"text", sortable: true}
                      ]);
        
        //component.set("v.loadSpinner",true);
        var escDet = component.get("c.populateEscalations");
        escDet.setParams({
            "filterValue": "Open Escalations" 
        });
        var escListVar = '';
        
        escDet.setCallback(this, function(result)
                               {
                                   var state = result.getState();
                                   if (state === "SUCCESS") 
                                   {
                                       escListVar = result.getReturnValue();
                                       component.set("v.data",escListVar);
                                       component.set("v.escCount",escListVar.length);
                                       component.set("v.loadSpinner",false);   
                                   }
                               }); 
        $A.enqueueAction(escDet);
    },
    
    newEscRec : function(component, event, helper) 
    {    
        /*var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": "Engagement_Request__c",
            " recordTypeId": "0120f000001IskgAAC"
        });
        createRecordEvent.fire();
        
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
        */
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__SC_AMG_NewEscalation',
            }
        };
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
    },
    
    updateTable: function(component, event, helper)
    {
        component.set("v.loadSpinner",true);   
        var escDet = component.get("c.populateEscalations");
        escDet.setParams({
            "filterValue": component.get("v.filterValue")
        });

        var escListVar = '';
        
        escDet.setCallback(this, function(result)
                               {
                                   var state = result.getState();
                                   if (state === "SUCCESS") 
                                   {
                                       escListVar = result.getReturnValue();
                                       component.set("v.data",escListVar);
                                       component.set("v.escCount",escListVar.length);
                                       component.set("v.loadSpinner",false);   
                                   }
                               }); 
        $A.enqueueAction(escDet);
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
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
        var fieldName = event.getParam('fieldName');
            
        if(actionName == "akamcaseid")    
        {
            var columns = event.getParam('columnDefinition');
            var rId = row.caseRecId;
            helper.openConsoleTab(component, event, rId);
        }
        else
        if(actionName == "accountName")    
        {
            var rId = row.accountId;
            helper.openConsoleTab(component, event, rId);
        }
        else
        if(actionName == "escIDVal")    
        {
            var rId = row.escRecId;
            helper.openConsoleTab(component, event, rId);
        }
        
    }
});