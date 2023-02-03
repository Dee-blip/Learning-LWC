({
    init: function(component, event, helper) 
    {
        component.set("v.loadSpinner",true);
        component.set("v.loadButtonSpinner",true);
        
        var isUserManagerVal = false;
        var filterVal = "My Open Cases";
        var dataStoredCache = false;
        helper.callServer(component,"c.getDefaultListViewInCache",
            function(result){
                if(result!= ''){
                    filterVal = result;
                    dataStoredCache = true;
                }                  
            }, 
            {
                "listViewName" : "filterSelect"
            });
        var isUserManagerVal = false;
        
        helper.callServer(
            component,
            "c.isUserManagerCheck",
            function(result)
            {
                component.set("v.isUserManager",result);
                isUserManagerVal = result;
                
                if(isUserManagerVal && !dataStoredCache)
                    filterVal = 'My Team\'s Open Cases with SLA running';
                
                component.set("v.filterVal",filterVal);
                
                helper.getTotalNumberOfCases(component);
                
                //abstract call server method from AuraUtils
                helper.callServer(
                    component,
                    "c.getCaseListForAMG",
                    function(result)
                    {
                        var caseListVar = '';
                        caseListVar = result;
                        component.set("v.data",caseListVar);
                        component.set("v.dataFiltered",caseListVar);
                        component.set("v.casesCount",caseListVar.length);
                        component.set("v.currentCount", component.get("v.initialRows"));
                        component.set("v.loadSpinner",false);
                        
                        // get SLA Alerts Count
                        helper.callServer(
                            component,
                            "c.SLAAlertButtonColor",
                            function(result)
                            {
                                var slaResult = result.split("::");
                                var slaColourCount = slaResult[0].split("_");
                                
                                component.set("v.slaAlertCount",slaColourCount[1]);
                                component.set("v.slaAlertColour",slaColourCount[0]);
                                component.set("v.slaTitle",slaResult[1]);
                                
                                var cmpTarget = component.find('slaAlertButton');
                                if(slaColourCount[0] === 'orange')
                                    $A.util.addClass(cmpTarget, 'orangeSLAButton');
                                else
                                    if(slaColourCount[0] === 'yellow')
                                        $A.util.addClass(cmpTarget, 'yellowSLAButton');
                                    else
                                        if(slaColourCount[0] === 'red')
                                            $A.util.addClass(cmpTarget, 'redSLAButton');
                                        else
                                            if(slaColourCount[0] === 'green')
                                                $A.util.addClass(cmpTarget, 'greenSLAButton');
                                
                            },
                            {
                                "ownerFilterValue":  filterVal
                            }
                        );

                        // get Ageing Cases Count
                        helper.callServer(
                            component,
                            "c.ageingCasesCount",
                            function(result)
                            {
                                var slaResult = result.split("::");
                                var slaColourCount = slaResult[0].split("_");
                                
                                component.set("v.ageingCasesCount",slaColourCount[1]);
                                component.set("v.ageingCasesColour",slaColourCount[0]);
                                component.set("v.ageingTitle",slaResult[1]);
                            },
                            {
                                "ownerFilterValue":	filterVal
                            }
                        );
                    },
                    {
                        "ownerFilterValue":  filterVal,
                        "userOrQueue": "user",
                        "recordLimit": component.get("v.initialRows"),
                        "recordOffset": component.get("v.rowNumberOffset")
                    }
                );                
            }
        );
        
        //var isUserManager = component.get("v.isUserManager");
        if(component.get("v.filterVal") == 'My Team\'s Open Cases with SLA running')
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
                                  //variant: 'container',
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
                              {label:'AKAM Case ID', fieldName:'url', type: 'url', typeAttributes: { label:{fieldName: 'akamcaseid'}},sortable: true, 
                              initialWidth: 125,
                              cellAttributes:{alignment:'center', class: { fieldName:'priority' }}},

                              {label:"Age", fieldName:"agedays", type:"number", sortable: true, 
                              initialWidth:80, 
                              cellAttributes:{alignment:'left', class: { fieldName:'ageColour' }}},
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
        
        // get Escalations Count
        //component.set("v.loadSpinner",true);
        helper.callServer(
            component,
            "c.populateEscalationsCount",
            function(result)
            {
                component.set("v.escalationsCount",result);
            }
        );
        
        // get Service Incidents Count
        helper.callServer(
            component,
            "c.populateIncidentsCount",
            function(result)
            {
                component.set("v.siCount",result);
            },
            {
                "incidentFilter" : "Last 24 Hours"
            }
        );
        
        // get User Availability
        helper.callServer(
            component,
            "c.getUserAvailabilility",
            function(result)
            {
                component.set("v.userAvailable",result.Availability__c);
                component.set("v.backupUser",result.Backup_User__c);
                if(typeof result.Backup_User__c !== 'undefined')
                {
                    component.set("v.backupUserName",result.Backup_User__r["Name"]);
                    component.set("v.backupSet","true");
                }
                component.set("v.userRecordId",result.Id);
            }
        );
        
        //helper.getAMGRecordTypeId(component, event, helper);
        
        var interval = window.setInterval(
            $A.getCallback(function() 
            {
                var action = component.get('c.updateTable');
                $A.enqueueAction(action);
            }), 150000
        ); 
        component.set("v.setIntervalId", interval) ;
    },

    afterRender: function(component,event,helper)
    {
        var cmpTarget = component.find('slaAlertButton');
        var buttonColour = component.get("v.slaAlertColour");
        if(buttonColour === 'orange')
            $A.util.addClass(cmpTarget, 'orangeSLAButton');
        else
            if(buttonColour === 'yellow')
                $A.util.addClass(cmpTarget, 'yellowSLAButton');
            else
                if(buttonColour === 'red')
                    $A.util.addClass(cmpTarget, 'redSLAButton');
                else
                    if(buttonColour === 'green')
                        $A.util.addClass(cmpTarget, 'greenSLAButton');
        
        cmpTarget = component.find('ageingCaseButton');
        buttonColour = component.get("v.ageingCasesColour");
        
        if(buttonColour === 'orange')
            $A.util.addClass(cmpTarget, 'orangeSLAButton');
        else
            if(buttonColour === 'yellow')
                $A.util.addClass(cmpTarget, 'yellowSLAButton');
            else
                if(buttonColour === 'red')
                    $A.util.addClass(cmpTarget, 'redSLAButton');
                else
                    if(buttonColour === 'green')
                        $A.util.addClass(cmpTarget, 'greenSLAButton');    
        component.set("v.loadButtonSpinner",false);
        //component.set("v.loadSpinner",false);
    },
    
    handleSubmit: function(cmp, event, helper) 
    {
        cmp.set('v.loadBackupSpinner', true);
        var eventFields = event.getParam("fields");
        var backup = eventFields["Backup_User__c"];
        event.preventDefault(); 
        var addBackup = cmp.get("c.addBackupUser");
        addBackup.setParams({
            "backupId": backup
        });
        
        addBackup.setCallback(this, function(result)
                              {
                                  var state = result.getState();
                                  if (state === "SUCCESS") 
                                  {
                                      //console.log('RETURN VALUE' + result.getReturnValue());
                                      cmp.set('v.loadBackupSpinner', false);
                                      cmp.set("v.isBackupModalOpen", false);
                                      helper.showToastMessage(cmp, event, helper,"","Backup Saved!","success","dismissable");
                                      
                                      cmp.set("v.loadButtonSpinner",true);
                                      helper.callServer(
                                          cmp,
                                          "c.getUserAvailabilility",
                                          function(result)
                                          {
                                              cmp.set("v.userAvailable",result.Availability__c);
                                              cmp.set("v.backupUser",result.Backup_User__c);
                                              if(typeof result.Backup_User__c !== 'undefined')
                                              {
                                                  cmp.set("v.backupUserName",result.Backup_User__r["Name"]);
                                                  cmp.set("v.backupSet","true");
                                              }
                                              else
                                              {
                                                  cmp.set("v.backupUserName","");
                                                  cmp.set("v.backupSet","false"); 
                                              }
                                              cmp.set("v.userRecordId",result.Id);
                                              cmp.set("v.loadButtonSpinner",false);
                                          }
                                      );
                                  }
                                  else
                                  {
                                      cmp.set('v.loadBackupSpinner', false);
                                      var error = result.getError();
                                      cmp.set('v.loadBackupSpinner', false);
                                      helper.showToastMessage(cmp, event, helper,"Error!",error[0].message,"error","dismissable");
                                  }
                              }); 
        $A.enqueueAction(addBackup);
        
    },
    
    handleError: function(cmp, event, helper) 
    {
        //alert('handleError' + event.getParams());
    },
    
    handleSuccess: function(cmp, event, helper) 
    {
        alert('SUCCESS');
    },
    
    updateTable: function(component, event, helper)
    {
        var action;
        try{
                //update picklist value in cache 
                if(!(typeof event == 'undefined' || typeof event.getParam == 'undefined')){
                action = component.get('c.setDefaultListViewInCache'); 
                action.setParams({
                    "listViewName" : "filterSelect" ,
                    "value" : event.getParam('value')  
                });
                $A.enqueueAction(action); 
            }           
        }catch(err){
            
        }
        
        helper.getTotalNumberOfCases(component);
        
        helper.refreshTable(component, event);
        //console.log('SORTED BY : ' + component.get("v.sortedBy"));
        helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
        
        component.set("v.loadButtonSpinner",true);
        helper.callServer(
            component,
            "c.SLAAlertButtonColor",
            function(result)
            {
                var slaResult = result.split("::");
                var slaColourCount = slaResult[0].split("_");
                
                component.set("v.slaAlertCount",slaColourCount[1]);
                component.set("v.slaAlertColour",slaColourCount[0]);
                component.set("v.slaTitle",slaResult[1]);
                //console.log('slaResult : ' + slaResult);
                //console.log('slaColourCount[0] : ' + slaColourCount[0]);
                //console.log('slaColourCount[1] : ' + slaColourCount[1]);
                
                var cmpTarget = component.find('slaAlertButton');
                
                $A.util.removeClass(cmpTarget, 'orangeSLAButton');
                $A.util.removeClass(cmpTarget, 'yellowSLAButton');
                $A.util.removeClass(cmpTarget, 'redSLAButton');
                $A.util.removeClass(cmpTarget, 'greenSLAButton');
                
                if(slaColourCount[0] === 'orange')
                    $A.util.addClass(cmpTarget, 'orangeSLAButton');
                else
                    if(slaColourCount[0] === 'yellow')
                        $A.util.addClass(cmpTarget, 'yellowSLAButton');
                    else
                        if(slaColourCount[0] === 'red')
                            $A.util.addClass(cmpTarget, 'redSLAButton');
                        else
                            if(slaColourCount[0] === 'green')
                                $A.util.addClass(cmpTarget, 'greenSLAButton');
                component.set("v.loadButtonSpinner",false);
            },
            {
                "ownerFilterValue":	component.get("v.filterVal")
            }
        );
        
        
        component.set("v.loadButtonSpinner",true);
        helper.callServer(
            component,
            "c.ageingCasesCount",
            function(result)
            {
                var slaResult = result.split("::");
                var slaColourCount = slaResult[0].split("_");
                
                component.set("v.ageingCasesCount",slaColourCount[1]);
                component.set("v.ageingCasesColour",slaColourCount[0]);
                component.set("v.ageingTitle",slaResult[1]);
                
                var cmpTarget = component.find('ageingCaseButton');
                $A.util.removeClass(cmpTarget, 'orangeSLAButton');
                $A.util.removeClass(cmpTarget, 'yellowSLAButton');
                $A.util.removeClass(cmpTarget, 'redSLAButton');
                $A.util.removeClass(cmpTarget, 'greenSLAButton');
                
                if(slaColourCount[0] === 'orange')
                    $A.util.addClass(cmpTarget, 'orangeSLAButton');
                else
                    if(slaColourCount[0] === 'yellow')
                        $A.util.addClass(cmpTarget, 'yellowSLAButton');
                    else
                        if(slaColourCount[0] === 'red')
                            $A.util.addClass(cmpTarget, 'redSLAButton');
                        else
                            if(slaColourCount[0] === 'green')
                                $A.util.addClass(cmpTarget, 'greenSLAButton');
                component.set("v.loadButtonSpinner",false);
                //component.set("v.loadSpinner",false);
            },
            {
                "ownerFilterValue":	component.get("v.filterVal")
            }
        );

        console.log('INFINITE LOADING : ' + component.get('v.enableInfiniteLoading'));
        
    },
    
    toggleAvailability: function(component,event,helper)
    {
        component.set("v.loadButtonSpinner",true);
        var fetchUserAv = component.get("c.toggleUserAvailability");
        fetchUserAv.setCallback(this, function(result)
                                {
                                    var state = result.getState();
                                    if (state === "SUCCESS") 
                                    {
                                        component.set("v.userAvailable",result.getReturnValue());
                                        
                                        var userAvail = component.get("c.getUserAvailabilility");
                                        userAvail.setCallback(this, function(result)
                                                              {
                                                                  var state = result.getState();
                                                                  if (state === "SUCCESS") 
                                                                  {
                                                                      var res = result.getReturnValue();
                                                                      component.set("v.userAvailable",res.Availability__c);
                                                                      component.set("v.backupUser",res.Backup_User__c);
                                                                      if(typeof res.Backup_User__c !== 'undefined')
                                                                      {
                                                                          component.set("v.backupUserName",res.Backup_User__r["Name"]);
                                                                          component.set("v.backupSet","true");
                                                                      }
                                                                      else
                                                                      {
                                                                          component.set("v.backupUserName","");
                                                                          component.set("v.backupSet","false"); 
                                                                      } 
                                                                  }
                                                                  component.set("v.loadButtonSpinner",false);
                                                              }); 
                                        $A.enqueueAction(userAvail);
                                    }
                                }); 
        $A.enqueueAction(fetchUserAv);
    },
    
    handleLoadMoreCases: function (component, event, helper) 
    {
        if(component.get("v.myCaseSearchText") == '')
        {
            event.getSource().set("v.isLoading", true);
            component.set('v.loadMoreStatus', 'Loading Cases...');
            helper.getMoreCases(component, component.get('v.rowsToLoad'))
            .then($A.getCallback(function (data) 
            {
                if (component.get('v.data').length == component.get('v.totalNumberOfRows')) 
                {
                    console.log('NOTHING MORE TO LOAD');
                    component.set('v.enableInfiniteLoading', false);
                    component.set('v.loadMoreStatus', 'No more data to load');
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
    
    updateColumnSorting: function (component, event, helper) 
    {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    },
    
    updateSelectedText: function (component, event,helper) {
        var bypass = component.get('v.bypassSelectionRowMethod');
        if(!bypass){
            var searchFilter = component.get("v.myCaseSearchText")
            var selectedRows = event.getParam('selectedRows'); 
            var tableData = component.get("v.dataFiltered");
            
            
            
            if(!searchFilter){
                var allSelectedRows = [];
                for ( var i = 0; i < selectedRows.length; i++ ) {
                    allSelectedRows.push(selectedRows[i].caseRecId );
                }
                component.set("v.allSelectedRows",allSelectedRows);
            } else {
                var allSelectedRows = component.get("v.allSelectedRows");
                var selectedIds = [];
                for ( var i = 0; i < selectedRows.length; i++ ) {
                    selectedIds.push(selectedRows[i].caseRecId );
                }
                for ( var i = 0; i < tableData.length; i++ ) {
                    if(allSelectedRows.includes(tableData[i].caseRecId) && !selectedIds.includes(tableData[i].caseRecId)){
                        var index = allSelectedRows.indexOf(tableData[i].caseRecId);
                        allSelectedRows.splice(index, 1);
                    }
                    if(!allSelectedRows.includes(tableData[i].caseRecId) && selectedIds.includes(tableData[i].caseRecId)){
                        allSelectedRows.push(tableData[i].caseRecId );
                    }
                }
                component.set("v.allSelectedRows",allSelectedRows);
            }
            var allSelectedRows = component.get("v.allSelectedRows");
            component.set('v.selectedRowsCount', allSelectedRows.length);
            
            
        } else {
            component.set('v.bypassSelectionRowMethod',false);
        }
        var selectedRows = component.get('v.allSelectedRows');
        helper.enableButton(component, selectedRows.length > 0, selectedRows.length == 1);
    },
    
    editContactRecord : function(component, event, helper) {
        var row = event.getParam('row');
        var recordId = row.Id;
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recordId
        });
        editRecordEvent.fire();
    },
    
    handleRowAction: function(component,event,helper)
    {
        console.log('CALLED');
        var caseRecId = event.getParam('row').caseRecId;
        var row = event.getParam('row');
        var actionName = event.getParam('action').name;
        
        if(actionName == "edit")
        {
            var editRecordEvent = $A.get("e.force:editRecord");
            editRecordEvent.setParams({
                "recordId": caseRecId
            });
            editRecordEvent.fire();
        }
        else 
            if(actionName == "akachat")
            {
                var getAkaChatBody = component.get("c.akachatTranscriptBody");
                getAkaChatBody.setParams(
                    {
                        "caseId": caseRecId
                    });
                
                var chatBody = '';
                
                getAkaChatBody.setCallback(this, function(result)
                                           {
                                               var state = result.getState();
                                               if (state === "SUCCESS") 
                                               {
                                                   chatBody = result.getReturnValue();
                                                   component.set("v.akachatTranscript",chatBody);
                                                   component.set("v.isModalOpen",true);  
                                               }
                                           }); 
                $A.enqueueAction(getAkaChatBody);
            }
            else 
                if(actionName == "akamcaseid")    
                {
                    helper.openConsoleTab(component, event, caseRecId);
                }
                else
                    if(actionName == "accountName")    
                    {
                        helper.openConsoleTab(component, event, row.accountId);
                    }
                    else
                        if(actionName == "incident")    
                        {
                            helper.openConsoleTab(component, event, row.incidentId);
                        }
    }, 
    
    closeBulkCases: function(component,event,helper)
    {
        var selections;
        var selectedIds = [];
        if(component.get("v.myCaseSearchText")){
            selections = component.get("v.allSelectedRows");
            for(var i =0 ; i < selections.length; i++){
                selectedIds.push(selections[i])
            }
        } else {
            selections = component.find('datatable').getSelectedRows();
            for(var i =0 ; i < selections.length; i++){
                selectedIds.push(selections[i].caseRecId)
            }
        }
        //component.set("v.showPop", true);
        component.set("v.idList",selectedIds);
        helper.openBulkCaseCloseTab(component, event, helper);                
    },
    
    newCase : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Case/new'            
        }).fire();
    },
    
    filter: function(component, event, helper) 
    {
        helper.filter(component,event);
    },
    
   
    closeCaseModal: function(component, event, helper) {
        component.set("v.showPop", false);
    },
    
    openModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    openBackupModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isBackupModalOpen", true);
    },
    
    closeBackupModal: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isBackupModalOpen", false);
    },
    
    closeModal: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
    
    showSpinner: function(component, event, helper) {
        component.set("v.loadSpinner",true);
    },
    
    hideSpinner: function(component, event, helper) {
        component.set("v.loadSpinner",false);
    },
    
    submitDetails: function(component, event, helper) {
        // Set isModalOpen attribute to false
        //Add your code to call apex method or do some processing
        component.set("v.isModalOpen", false);
    },
    
    slaAlertButtonNav: function(component, event, helper) 
    {
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__SC_AMG_SLACases',
            },
            state: {
                "c__filterValRecd": component.get("v.filterVal")
            }
            
        };
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
    },
    
    ageingCaseButtonNav: function(component, event, helper) 
    {
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__SC_AMG_AgeingCases',
            },
            state: {
                "c__filterValRecd": component.get("v.filterVal")
            }
        };
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
    },
    
    escalationButtonNav: function(component, event, helper) 
    {
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__SC_AMG_Escalations',
            }
        };
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
    },
    
    servIncButtonNav: function(component, event, helper) 
    {
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__SC_AMG_ServiceIncidents',
            }
        };
        var navService = component.find("navService");
        event.preventDefault();
        navService.navigate(pageReference);
    },
    
    cloneCases: function(component, event, helper)
    {
        var selections = component.find('datatable').getSelectedRows();
        component.set("v.recIdtoClone", selections[0].caseRecId);
        component.set("v.showSingCloneModal", true);
  
    },
    
    cloneCaseOnMultiAcc: function(component, event, helper)
    {
        var selections = component.find('datatable').getSelectedRows();
        component.set("v.showCloneModal", false);
        component.set("v.recIdtoClone", selections[0].caseRecId);
        helper.openCaseCloneTab(component, event, helper);
    },

    
    spinnerShow: function(component, event, helper)   
    {
        component.set("v.showSpinner", true);
    },
    spinnerHide: function(component, event, helper)   
    {
        component.set("v.showSpinner", false);
    },
    refreshCmp: function(component, event, helper)   
    {
        $A.get('e.force:refreshView').fire();
        
    }, 
    
    closeReopenModal: function(component, event, helper){
		component.set('v.displayReopenModal',false);
        component.set('v.reOpenErrMsg',"");
    },
    reopenCase: function(component, event, helper){
        
        var selections = component.find('datatable').getSelectedRows();
        helper.callServer(component,"c.reopenClosedCase",
            function(result){
                if(result!= ''){
                    component.set('v.displayReopenModal',true); 
                    component.set('v.reOpenErrMsg',result);
                } else {
                    helper.showToastMessage(component, event, helper,"","Case re-opened successfully.","success","dismissable");
                    component.set('v.displayReopenModal',false);
                    //$A.get('e.force:refreshView').fire();
                    var action = component.get('c.updateTable');
                    $A.enqueueAction(action);
                    var editRecordEvent = $A.get("e.force:editRecord");
                    editRecordEvent.setParams({
                        "recordId": selections[0].caseRecId
                    });
                    editRecordEvent.fire();
                    
                }                  
            }, 
            {
                "caseId" : selections[0].caseRecId
            });
    },
    
    //method to destory the setInterval value
    handleDestroy: function (cmp) {
        window.clearInterval(cmp.get("v.setIntervalId"));
    }
});