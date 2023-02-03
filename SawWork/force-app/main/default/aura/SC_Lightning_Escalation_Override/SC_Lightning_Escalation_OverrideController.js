({
    doInit : function(component, event, helper) 
    {
        //Aditi - declared these two at top to remove eslint errors when deploying
        var pageReference;
        var navService;
        
        var res = '';
        console.log('ENTERED INIT');
        //var recordId = component.get("v.recordId");
        var para = component.get("v.pageReference").state.additionalParams;
        console.log('PARA : ' + component.get("v.pageReference").state);
        var EscalationrecordTypeId; 
        var escDefRecTypeId;
        
        var escRT = component.get("c.getDefaultEscRecType");
        
        escRT.setCallback(this, function(response)
        {
            console.log('CALLED : ' + response.getState());
            if(response.getState() == "SUCCESS") 
            {
                escDefRecTypeId = response.getReturnValue();
                console.log('REC TYPE RECD : ' + escDefRecTypeId);
                if(typeof para === 'undefined')
                {
                    console.log('PARA UNDEFINED');
                    EscalationrecordTypeId = escDefRecTypeId;
                }
                else
                {
                    console.log('PARA DEFINED');
                    EscalationrecordTypeId = component.get("v.pageReference").state.recordTypeId;
                }
                
                console.log('EscalationrecordTypeId : ' + EscalationrecordTypeId);
                
                var action = component.get("c.getEscRecordTypeName");
                action.setParams({
                    "EscRecordTypeId": EscalationrecordTypeId
                });
                
                action.setCallback(this, function(response) 
                {
                    var workspaceAPI;
                    if (response.getState() == "SUCCESS") 
                    {
                        var escrecordtypename=response.getReturnValue();
                        console.log('REC TYPE NAME : ' + escrecordtypename);
                        
                        //Code for AMG Escalation RT
                        if(escrecordtypename =='AMG Escalation')
                        {
                            //console.log('amg esc');
                            workspaceAPI = component.find("workspace");
                                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                                        var focusedTabId = response.tabId;
                                        setTimeout(function(){ workspaceAPI.closeTab({tabId: focusedTabId});}, 1000);
                                        
                                    })
                                    .catch(function(error) {
                                        console.log(error);
                                    });
                            
                           pageReference = {
                                type: 'standard__component',
                                attributes: {
                                    componentName: 'c__SC_AMG_NewEscalation',
                                }
                            };
                            navService = component.find("navigation");
                            //event.preventDefault();
                            navService.navigate(pageReference); 
                        }
                        else
                        {
                            //Code for any other RT
                            var index = para.indexOf("id=");
                            //If escalation is created from inside the Case Related List
                            if(index !== -1){
                                //Code if that other RT is being created from some RT
                                console.log('Inside related list');
                                res = para.substr(index+3);
                                res=res.substr(0,15);
                                console.log(res);
                                
                                //Code for External Team RT in RL
                                if(escrecordtypename === 'External Team'){
                                    workspaceAPI = component.find("workspace");
                                    workspaceAPI.isConsoleNavigation().then(function(consoleResponse){
                                        console.log("IsConsole: ", consoleResponse);
                                        if(consoleResponse){
                                            workspaceAPI.getFocusedTabInfo().then(function(tabResponse){
                                                var closeTabId = tabResponse.tabId;
                                                var closeTitle = tabResponse.title;
                                                var parentTabId = tabResponse.parentTabId;
                                                var isSubtab = tabResponse.isSubtab;
                                                
                                                //Only added code for subtab as when opened from a RL the page should always open as a subtab
                                                if(isSubtab){
                                                    workspaceAPI.openSubtab({
                                                        pageReference: {
                                                            "type": "standard__component",
                                                            "attributes": {
                                                                "componentName": "c__SC_ExternalTeam"
                                                            },
                                                            state: {
                                                               "c__caseRecId": res
                                                            }
                                                        },
                                                        parentTabId: parentTabId,
                                                        focus: true
                                                    }).then(function(openSubResponse){
                                                        console.log("openSubResponse: ", openSubResponse);
                                                        workspaceAPI.setTabLabel({
                                                            tabId: openSubResponse,
                                                            label: "New Escalation"
                                                        });
                                                        workspaceAPI.setTabIcon({
                                                            tabId: openSubResponse,
                                                            icon: "utility:photo",
                                                            iconAlt: "Focused Tab"
                                                        });
                                                        workspaceAPI.focusTab({tabId : openSubResponse});
                                                        // close the tab we started on -- this should be done when new tab is created so we kill the old tab
                                                        if(tabResponse.closeable && !tabResponse.pinned){
                                                            workspaceAPI.closeTab({
                                                                tabId: closeTabId
                                                            }).then(function(closeResponse){
                                                                console.log("closeResponse: ", closeResponse);
                                                                console.log("Closed: ", closeTitle);                      
                                                            })
                                                            .catch(function(error){
                                                                console.log(error);
                                                            });                            
                                                        }else{
                                                            console.log("Left Open: ", tabResponse.title);
                                                        }
                                                    })
                                                    .catch(function(error){
                                                        console.log('Error occurred here is = '+error);
                                                        console.log('Error occurred here is = '+error.message);
                                                    });
                                                }
                                            })
                                            .catch(function(error){
                                                console.log('Error occurred here is = '+error);
                                                console.log('Error occurred here is = '+error.message);
                                            });
                                        }
                                        else{
                                            //inside not console for external team escalation records
                                            pageReference = {
                                                type: 'standard__component',
                                                attributes: {
                                                    componentName: 'c__SC_ExternalTeam',
                                                }
                                                ,
                                                state: {
                                                   "c__caseRecId": res
                                                }
                                            };
                                            navService = component.find("navigation");
                                            navService.navigate(pageReference);
                                        }
                                    });
                                }
                                else
                                {
                                    //Code for some other RT in RL
                                    var workspaceAPI = component.find("workspace");
                                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                                        var focusedTabId = response.tabId;
                                        setTimeout(function(){ workspaceAPI.closeTab({tabId: focusedTabId});}, 1000);
                                        
                                    })
                                    .catch(function(error) {
                                        console.log(error);
                                    });
                                    
                                    var createRecordEvent = $A.get("e.force:createRecord");
                                    createRecordEvent.setParams({
                                        "entityApiName": "Engagement_Request__c",
                                        "recordTypeId" : EscalationrecordTypeId,
                                        "defaultFieldValues": {
                                            'Case__c' : res
                                        }
                                        
                                    });
                                    createRecordEvent.fire();
                                }
                                
                            }
                            //Escalations created outside related list
                            else
                            {      
                                console.log('Outside related list');
                                //alert(escRecordtypeName);
                                
                                //Code for External Team RT from New button on Escalations List
                                if(escrecordtypename === 'External Team'){
                                    
                                    //First part is for the console apps - for External Team Escaltions
                                    workspaceAPI = component.find("workspace");
                                    workspaceAPI.isConsoleNavigation().then(function(consoleResponse){
                                        if(consoleResponse){
                                            workspaceAPI.getFocusedTabInfo().then(function(tabResponse){
                                                var closeTabId = tabResponse.tabId;
                                                var closeTitle = tabResponse.title;
                                                workspaceAPI.openTab({
                                                    pageReference:{
                                                        "type": "standard__component",
                                                        "attributes":{
                                                            "componentName": "c__SC_ExternalTeam"
                                                        }
                                                    },
                                                    focus: true
                                                }).then(function(openParResponse){
                                                    workspaceAPI.setTabLabel({
                                                        tabId: openParResponse,
                                                        label: "New Escalation"
                                                    });
                                                    workspaceAPI.setTabIcon({
                                                        tabId: openParResponse,
                                                        icon: "utility:photo",
                                                        iconAlt: "Focused Tab"
                                                    });
                                                    workspaceAPI.focusTab({tabId : openParResponse});
                                                    // close the tab we started on -- this should be done when new tab is created so we kill the old tab
                                                    if(tabResponse.closeable && !tabResponse.pinned){
                                                        workspaceAPI.closeTab({
                                                            tabId: closeTabId
                                                        }).then(function(closeResponse){
                                                            console.log("closeResponse: ", closeResponse);
                                                            console.log("Closed: ", closeTitle);                      
                                                        })
                                                        .catch(function(error){
                                                            console.log(error);
                                                        });                            
                                                    }else{
                                                        console.log("Left Open: ", tabResponse.title);
                                                    }
                                                })
                                                .catch(function(error){
                                                    console.log(error);
                                                });
                                            })
                                            .catch(function(error){
                                                console.log('Error occurred here is = '+error);
                                                console.log('Error occurred here is = '+error.message);
                                            });
                                        }
                                        else{
                                            //inside not console for external team escalation records
                                            pageReference = {
                                                type: 'standard__component',
                                                attributes: {
                                                    componentName: 'c__SC_ExternalTeam',
                                                }
                                            };
                                            navService = component.find("navigation");
                                            navService.navigate(pageReference);
                                        }
                                    });
                                }
                                else
                                {
                                    //Code for any other RT from New button on Escalations List
                                    workspaceAPI = component.find("workspace"); 
                                    workspaceAPI.getFocusedTabInfo().then(function(response) 
                                                                          {
                                                                              var focusedTabId = response.tabId;
                                                                              setTimeout(function(){ workspaceAPI.closeTab({tabId: focusedTabId});}, 1000);
                                                                          })
                                    .catch(function(error) 
                                           {
                                               console.log(error);
                                           });
                                    
                                    var createRecordEvent = $A.get("e.force:createRecord");
                                    createRecordEvent.setParams({
                                        "entityApiName": "Engagement_Request__c",
                                        "recordTypeId" : EscalationrecordTypeId
                                    });
                                    createRecordEvent.fire();
                                }
                            }
                        }
                    }
                });
                $A.enqueueAction(action);
            }
        });
        $A.enqueueAction(escRT);
        
        //var EscalationrecordTypeId = component.get("v.pageReference").state.recordTypeId;
        
        console.log('ESC RT Id : ' + EscalationrecordTypeId);
        
    }
})