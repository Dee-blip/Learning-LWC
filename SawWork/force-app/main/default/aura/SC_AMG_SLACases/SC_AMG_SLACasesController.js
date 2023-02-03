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
                label: "SLA Alerts"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "action:priority",
                iconAlt: "SLA Alerts"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        
        //component.set("v.loadSpinner",true);
        var isUserManagerVal = false;
        var filterVal = 'My Open Cases';
        
        filterVal = component.get("v.pageReference").state.c__filterValRecd;
        console.log("FILTERVAL : " + filterVal);
        
        component.set("v.loadSpinner",true);
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManagerVal = result;
                component.set("v.loadSpinner",false);
                
                if(isUserManagerVal)
                {
                    filterVal = 'My Team\'s Open Cases with SLA running';
                    component.set("v.columns", 
                      [
                        {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 125,cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                                    
                          {label:"Age", fieldName:"agedays", type:"number", sortable: true, fixedWidth:60, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
                          {label:"Visibility", fieldName:"visibility", type:"text", sortable: true},
                          {label:"Due In", fieldName:"sla", type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }},sortable: true},
                          {
                              label:"Account", 
                              fieldName:"accountName",
                              type:'button',
                              variant: 'container',
                              initialWidth: 150,
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
                          {label:"Subject", fieldName:"subject", type:"text", sortable: true},
                          {label:"Owner", fieldName:"ownername", type:"text", sortable: true},
                          {label:"Last Customer Update", fieldName:"lastCustUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastCustUpdateColour' }}},
                          {label:"Last Case Owner Update", fieldName:"lastOwnerUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastOwnerUpdateColour' }}},
                          {label:"Last Non-Case Owner Update", fieldName:"lastAkamUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastAkamUpdateColour' }}}
                      ]);
                }
                else
                {
                    component.set("v.columns", 
                      [
                        {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 125,cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                                    
                          {label:"Age", fieldName:"agedays", type:"number", sortable: true, fixedWidth:60, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
                          {label:"Visibility", fieldName:"visibility", type:"text", sortable: true},
                          {label:"Due In", fieldName:"sla", type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }},sortable: true},
                          {
                              label:"Account", 
                              fieldName:"accountName",
                              type:'button',
                              variant: 'container',
                              initialWidth: 150,
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
                          {label:"Subject", fieldName:"subject", type:"text", sortable: true},
                          {label:"Last Customer Update", fieldName:"lastCustUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastCustUpdateColour' }}},
                          {label:"Last Case Owner Update", fieldName:"lastOwnerUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastOwnerUpdateColour' }}},
                          {label:"Last Non-Case Owner Update", fieldName:"lastAkamUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastAkamUpdateColour' }}}
                      ]);
                }
                
                component.set("v.loadSpinner",true);
                
                helper.callServer(
                    component,
                    "c.populateSLACases",
                    function(result)
                    {
                        var caseListVar = result;
                        component.set("v.data",caseListVar);
                        component.set("v.dataFiltered",caseListVar);
                        component.set("v.slaCasesCount",caseListVar.length);
                        helper.sortData(component, "sla", "asc");
                        component.set("v.loadSpinner",false);
                    },
                    {
                        "ownerFilterValue":  filterVal
                    }
                );
            });
    },
    
    updateTable: function(component, event, helper)
    {
        var isUserManagerVal = false;
        var filterVal = 'My Open Cases';
        
        component.set("v.loadSpinner",true);
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManagerVal = result;
                component.set("v.loadSpinner",false);
                
                if(isUserManagerVal)
                    filterVal = 'My Team\'s Open Cases with SLA running';
                
                component.set("v.loadSpinner",true);
                
                helper.callServer(
                    component,
                    "c.populateSLACases",
                    function(result)
                    {
                        var caseListVar = result;
                        component.set("v.data",caseListVar);
                        component.set("v.dataFiltered",caseListVar);
                        component.set("v.slaCasesCount",caseListVar.length);
                        helper.sortData(component, "slaInMinutes", "asc");
                        component.set("v.loadSpinner",false);
                    },
                    {
                        "ownerFilterValue":  filterVal
                    }
                );
            });
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
        var actionName = event.getParam('action').name;
        if(actionName == "akamcaseid")    
        {
            // var workspaceAPI = component.find("workspace");
            var row = event.getParam('row');
            console.log('rowwwww//'+JSON.stringify(row));
            // var columns = component.get('v.columns');
            var columns = event.getParam('columnDefinition');
            console.log('columns///'+columns);
            console.log('columnssssss///'+JSON.stringify(columns));
            var fieldName = event.getParam('fieldName');
            console.log('fieldName//'+fieldName);
            console.log('fieldNameeeeee//'+JSON.stringify(fieldName));
            /* if(columns.fieldName=='AKAMCaseId'){
            alert('In Iffff');
        }*/
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
    
    newCase : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Case/new'            
        }).fire();
    },
});