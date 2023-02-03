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
                label: "Service Incidents"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "action:announcement",
                iconAlt: "Service Incidents"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        console.log("entered init");
        component.set("v.columns", 
                      [
                          {label:"Incident #", fieldName:"IncidentNumber" ,type:'button',fixedWidth: 125, 
                           typeAttributes: 
                           {
                               label: { fieldName: 'IncidentNumber'},
                               variant:'base',name:'IncidentNumber'}, sortable: true
                          },
                          //{label:"Incident #", fieldName:"IncidentNumber", type:"String", sortable: true, cellAttributes:{alignment:'left'}},
                          {label:"Title", fieldName:"Title", type:"text", sortable: true},
                          {label:"Status", fieldName:"Status", sortable: true, type:"text"},
                          {label:"Incident Start", fieldName:"IncidentStart", type:"text", sortable: true},
                          {label:"Urgency", fieldName:"Urgency", type:"text", sortable: true}
        ]);
        
        //component.set("v.loadSpinner",true);
        var servIncDet = component.get("c.populateIncidents");
        servIncDet.setParams({
            "incidentFilter": "Last 24 Hours" 
        });
        
        var servIncListVar = '';
        
        servIncDet.setCallback(this, function(result)
                               {
                                   var state = result.getState();
                                   if (state === "SUCCESS") 
                                   {
                                       servIncListVar = result.getReturnValue();
                                       component.set("v.data",servIncListVar);
                                       component.set("v.siCount",servIncListVar.length);
                                       component.set("v.loadSpinner",false);   
                                   }
                               }); 
        $A.enqueueAction(servIncDet);
    },
    
    updateSITable: function(component, event, helper)
    {
        component.set("v.loadSpinner",true);
        var servIncDet = component.get("c.populateIncidents");
        var incidentFilter = component.get("v.timeWindow");
        servIncDet.setParams({
            "incidentFilter": incidentFilter
        });
        
        var servIncListVar = '';
        
        servIncDet.setCallback(this, function(result)
                               {
                                   var state = result.getState();
                                   if (state === "SUCCESS") 
                                   {
                                       servIncListVar = result.getReturnValue();
                                       component.set("v.data",servIncListVar);
                                       component.set("v.siCount",servIncListVar.length);
                                       component.set("v.loadSpinner",false);
                                   }
                               }); 
        $A.enqueueAction(servIncDet);
    },
    
    updateColumnSorting: function (cmp, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    refreshView: function(component,event,helper)
    {
        $A.get('e.force:refreshView').fire();  
    },
    
    handleRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        var row = event.getParam('row');
        var rId = row.siRecId;
        helper.openConsoleTab(component, event, rId);
    }
});