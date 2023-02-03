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
                label: "Aging Cases"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "action:defer",
                iconAlt: "Aging Cases"
            });
        })
        .catch(function(error) {
            console.log(error);
        });

        var isUserManager = false;
        var filterVal = 'My Open Cases';
        
        console.log('RECEIVED : ' + filterVal);

        // set columns based on logged in User. If(Manager), show Case Owner
        var isUserManagerVal = false;
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManager = result;
                console.log(isUserManager);
                if(isUserManager)
                {
                    filterVal = 'My Team\'s Open Cases with SLA running';
                    component.set("v.columns", 
                                  [
                                    {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 125,cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                                      {label:"Age", fieldName:"agedays", type:"number", sortable: true, fixedWidth:60, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
                                      {label:"Visibility", fieldName:"visibility", type:"text", sortable: true},
                                      //{label:"Due In", fieldName:"sla", type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }}},
                                      {
                                          label:"Account", 
                                          fieldName:"accountName",
                                          type:'button',
                                          variant: 'container',
                                          initialWidth: 250,
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
                                      //{label:"Due In", fieldName:"sla", type:"text", cellAttributes:{alignment:'left', class: { fieldName:'slaColour' }}},
                                      {
                                          label:"Account", 
                                          fieldName:"accountName",
                                          type:'button',
                                          variant: 'container',
                                          initialWidth: 250,
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
                
                if(!isUserManager)
                filterVal = component.get("v.pageReference").state.c__filterValRecd;

                component.set("v.filterVal",filterVal);

                //abstract call server method from AuraUtils
                helper.callServer(
                    component,
                    "c.populateAgeingCases",
                    function(result)
                    {
                        component.set("v.data",result);
                        component.set("v.ageingCasesCount",result.length);
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
        component.set("v.loadSpinner",true);        
        helper.callServer(
            component,
            "c.populateAgeingCases",
            function(result)
            {
                component.set("v.data",result);
                component.set("v.ageingCasesCount",result.length);
                component.set("v.loadSpinner",false);  
            },
            {
                "ownerFilterValue":  component.get("v.filterVal")
            }
        );   
    },
    
    updateColumnSorting: function (cmp, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    handleRowAction: function(component,event,helper)
    {
        var workspaceAPI = component.find("workspace");
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
        if(actionName == "akamcaseid")    
        {
            helper.openConsoleTab(component, event, row.caseRecId);
        }
        else
        if(actionName == "accountName")    
        {
            helper.openConsoleTab(component, event, row.accountId);
        }
    },
    
    newCase : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Case/new'            
        }).fire();
    },
});