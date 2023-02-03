({
    getMoreCases: function(component , rows)
    {
        return new Promise($A.getCallback(function(resolve, reject) 
        {
            console.log('GET MORE CALLED ');
            var filterValue = component.get("v.filterVal");
            var recordLimit = component.get("v.rowsToAdd");
            
            var action = component.get('c.getCaseListForAMG');
            var recordOffset = component.get("v.currentCount");
            
            var isUserManager = component.get("v.isUserManager");
            if(isUserManager)
                filterValue = 'My Team\'s Open Cases with SLA running';
            
            action.setParams(
                {
                    "ownerFilterValue":  filterValue,
                    "userOrQueue":  "user",
                    "recordLimit": recordLimit,
                    "recordOffset": recordOffset
                });
            
            action.setCallback(this, function(response) 
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var resultData = response.getReturnValue();
                                       resolve(resultData);
                                       recordOffset = recordOffset+recordLimit;
                                       component.set("v.currentCount", recordOffset);   
                                   }                
                               });
            $A.enqueueAction(action);
        }));
    },
    
    getTotalNumberOfCases : function(component) 
    {
        var action = component.get("c.getCaseListForAMGCount");
        var filterValue = component.get("v.filterVal");
        /*
        var isUserManager = component.get("v.isUserManager");
        if(isUserManager)
            filterValue = 'My Team\'s Open Cases with SLA running';
            */
        action.setParams(
            {
                "ownerFilterValue":  filterValue,
                "userOrQueue":  "user"
            });
        action.setCallback(this, function(response) 
                           {
                               var state = response.getState();
                               if (state === "SUCCESS" ) 
                               {
                                   var resultData = response.getReturnValue();
                                   component.set("v.totalNumberOfRows",resultData);
                               }
                           });
        $A.enqueueAction(action);
    },
    
    sortData: function (component, fieldName, sortDirection) 
    {
        var data = component.get("v.dataFiltered");
        var reverse = sortDirection !== 'asc';
        var finalData = [];
        var sortedList = [];

        if(fieldName == 'sla')
        {
            var redCaseList = [];
            var greenCaseList = [];
            var naCaseList = [];
            var slaCaseList = [];

            for(var i=0; i < data.length; i++)
            {
                if(data[i].slaColour == 'red')
                    redCaseList.push(data[i]);
                else if(data[i].slaColour == 'green')
                    greenCaseList.push(data[i]);
                else if(data[i].slaColour == 'N/A')
                    naCaseList.push(data[i]);     
                else slaCaseList.push(data[i]);
            }

            slaCaseList.sort(this.sortBy('slaInMinutes', false));
            finalData = slaCaseList.concat(redCaseList).concat(greenCaseList).concat(naCaseList);
            
            component.set("v.dataFiltered", finalData);
        }

        else
        {
            data.sort(this.sortBy(fieldName, reverse));
            component.set("v.dataFiltered", data);
        }
        
    },

    sortBy: function (field, reverse, primer) 
    {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },

    openConsoleTab:function(component, event, rId) {
        var workspaceAPI = component.find("workspace");
        
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":rId,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
    enableButton : function(component,closeMode, cloneMode){
        closeMode = !closeMode;
        var filterValue = component.get('v.filterVal')
        if(filterValue!='My Closed Cases (Last 3 Months)')
        	component.find('closebulkbtn').set('v.disabled',closeMode);
        
        
        cloneMode = !cloneMode;
        component.find('cloneMultiple').set('v.disabled',cloneMode);
        component.find('cloneCase').set('v.disabled',cloneMode);
        if(filterValue=='My Closed Cases (Last 3 Months)')
        	component.find('reopenBulkBtn').set('v.disabled',cloneMode);
    },
    
   refreshTable : function(component,event)
    {
        component.set("v.loadSpinner",true);
        var caseDet = component.get("c.getCaseListForAMG");
        var filterValue = component.get("v.filterVal");
        
        // add Case Owner column for Team Views
        if(filterValue == 'My Team\'s Open Cases with SLA running')
        {
            component.set("v.columns", 
                          [
                              {
                                  type: 'button-icon',
                                  typeAttributes: {
                                      iconName: 'utility:edit',
                                      name: 'edit', 
                                      title: 'Edit',
                                      variant: 'container',
                                      alternativeText: 'Edit',
                                      disabled: false
                                  },
                                  initialWidth: 20
                              },
                              {
                                  label: '', 
                                  fieldName:"chatTranscript",
                                  type: 'button',
                                  initialWidth: 20, 
                                  variant: 'container',
                                  typeAttributes: 
                                  {
                                      name: 'akachat',
                                      label: { fieldName: 'chatTranscript' },
                                      variant: 'base',
                                      title: 'AkaChat',
                                      alternativeText: 'AkaChat'
                                  },
                                  cellAttributes:{class:'chatIcon'}
                              },
                              {
                                  label: '', 
                                  fieldName:"incident",
                                  type: 'button',
                                  initialWidth: 20, 
                                  variant: 'container',
                                  typeAttributes: 
                                  {
                                      name: 'incident',
                                      label: { fieldName: 'incident' },
                                      variant: 'base',
                                      title: 'Incident',
                                      alternativeText: 'Incident'
                                  },
                                  cellAttributes:{class:'chatIcon'}
                              },
                              /*
                              {
                                  label:"AKAM Case ID", 
                                  fieldName:"akamcaseid",
                                  type:'button',
                                  variant: 'container',
                                  fixedWidth: 125, 
                                  typeAttributes: 
                                  {
                                      label: {fieldName: 'akamcaseid'},
                                      variant:'base',
                                      name:'akamcaseid'
                                  }, 
                                  sortable: true,
                                  cellAttributes:{alignment:'center', class: { fieldName:'priority' }},
                              },*/
                              {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 125,cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                              {label:"Age", fieldName:"agedays", type:"number", sortable: true, initialWidth:80, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
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
                              {
                                  type: 'button-icon',
                                  typeAttributes: {
                                      iconName: 'utility:edit',
                                      name: 'edit', 
                                      title: 'Edit',
                                      variant: 'container',
                                      alternativeText: 'Edit',
                                      disabled: false
                                  },
                                  initialWidth: 30
                              },
                              {
                                  label: '', 
                                  fieldName:"chatTranscript",
                                  type: 'button',
                                  initialWidth: 40, 
                                  variant: 'container',
                                  typeAttributes: 
                                  {
                                      name: 'akachat',
                                      label: { fieldName: 'chatTranscript' },
                                      variant: 'base',
                                      title: 'AkaChat',
                                      alternativeText: 'AkaChat'
                                  },
                                  cellAttributes:{class:'chatIcon'}
                              },
                              {
                                  label: '', 
                                  fieldName:"incident",
                                  type: 'button',
                                  initialWidth: 40, 
                                  variant: 'container',
                                  typeAttributes: 
                                  {
                                      name: 'incident',
                                      label: { fieldName: 'incident' },
                                      variant: 'base',
                                      title: 'Incident',
                                      alternativeText: 'Incident'
                                  },
                                  cellAttributes:{class:'chatIcon'}
                              },
                              /*
                              {
                                  label:"AKAM Case ID", 
                                  fieldName:"akamcaseid",
                                  type:'button',
                                  variant: 'container',
                                  fixedWidth: 125, 
                                  typeAttributes: 
                                  {
                                      label: {fieldName: 'akamcaseid'},
                                      variant:'base',
                                      name:'akamcaseid'
                                  }, 
                                  sortable: true,
                                  cellAttributes:{alignment:'center', class: { fieldName:'priority' }},
                              },*/
                              {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, initialWidth: 125,cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},
                              {label:"Age", fieldName:"agedays", type:"number", sortable: true, initialWidth:80, cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
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
                              //{label:"Owner", fieldName:"ownername", type:"text", sortable: true},
                              {label:"Last Customer Update", fieldName:"lastCustUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastCustUpdateColour' }}},
                              {label:"Last Case Owner Update", fieldName:"lastOwnerUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastOwnerUpdateColour' }}},
                              {label:"Last Non-Case Owner Update", fieldName:"lastAkamUpdate", type:"text",cellAttributes:{alignment:'left', class: { fieldName:'lastAkamUpdateColour' }}}
                          ]);
        }

        component.set("v.myCaseSearchText","");
        component.set("v.filteredDataCount","0");
        caseDet.setParams(
            {
                "ownerFilterValue":  filterValue,
                "userOrQueue":  "user",
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
                                    component.set("v.currentCount", component.get("v.initialRows"));
                                    component.set("v.casesCount",caseListVar.length);
                                    component.set("v.loadSpinner",false);  
                                    component.set('v.enableInfiniteLoading', true);
                                    //component.set("v.loadButtonSpinner",false); 
                                }
                                //component.set("v.loadSpinner",false);   
                            }); 
        $A.enqueueAction(caseDet);
        
    },
    
   openCaseCloneTab:function(component, event, rId) 
   {
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__component",
                "attributes": {
                    "componentName": "c__SC_AMG_CloneMultipleCases"
                },
                "state": {
                    "c__caserecId": component.get("v.recIdtoClone"),
                    "c__showCloneFromCase": "false"
                }
            },
            focus: true
        }).then(function(response){
            workspaceAPI.setTabLabel({
                tabId: response,
                label: "Clone Case"
            });
            workspaceAPI.setTabIcon({
                tabId: response,
                icon: "action:new_case",
                iconAlt: "Clone Case"
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    

    openBulkCaseCloseTab:function(component, event, helper) 
    {    
        var event = $A.get("e.force:navigateToComponent");
        event.setParams({
            componentDef : "c:SC_AMG_BulkCaseClosure",
            componentAttributes: {
                recIds : component.get("v.idList")
            }
        });
        event.fire();
    },

    filter: function(component, event) 
    {
        var allRecords = component.get("v.data");
        var searchFilter = event.getSource().get("v.value").toUpperCase();
        
        var tempArray = [];
        var i;

        for(i=0; i < allRecords.length; i++)
        {
            if((allRecords[i].subject && allRecords[i].subject.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].accountName && allRecords[i].accountName.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].ownername && allRecords[i].ownername.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].service && allRecords[i].service.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].requestType && allRecords[i].requestType.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].supportLevel && allRecords[i].supportLevel.toUpperCase().indexOf(searchFilter) != -1)
               || (allRecords[i].akamcaseid && allRecords[i].akamcaseid.toUpperCase().indexOf(searchFilter) != -1)
              )
            {
                tempArray.push(allRecords[i]);
            }
        }
        component.set('v.bypassSelectionRowMethod',true);
        component.set("v.dataFiltered",tempArray);
        component.set("v.filteredDataCount",tempArray.length);
        component.set('v.bypassSelectionRowMethod',false);
        if(!searchFilter){
            component.set("v.selectedRows",component.get("v.allSelectedRows"));
            
        }
        
    }
})