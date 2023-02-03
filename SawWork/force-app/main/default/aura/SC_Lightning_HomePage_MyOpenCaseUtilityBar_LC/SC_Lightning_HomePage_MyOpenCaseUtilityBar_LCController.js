({
    //Method -1 : Init Method for utility bar component
    doInit: function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getMyopenCases");
        action.setParams({
            "userID": userId,
             "QueryType":'MyOpenCases'
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var myopenlst=response.getReturnValue();
                component.set("v.OpenCase", myopenlst);
                component.set("v.OpenCount", myopenlst.length);
                var utilityAPI = component.find("utilitybar");
                utilityAPI.setUtilityLabel({
                    label: myopenlst.length + " My Open Cases"
                });
                utilityAPI.setUtilityHighlighted({
                    highlighted: false
                });
            }
            
        });
        $A.enqueueAction(action);
        
        
    },
    //Subscription for pushtopic
    doSubscription:function(component, event, helper) {
        //Call server action to get current user's session id
        var action = component.get("c.getSessionId");
        
        action.setCallback(this, function(response) {
            // setting session id value from response
            var sessionId = response.getReturnValue();
            
            //inintializing cometD object/class
            var cometd = new window.org.cometd.CometD();
            
            //Calling configure method of cometD class, to setup authentication which will be used in handshaking
            cometd.configure({
                url: window.location.protocol + '//' + window.location.hostname + '/cometd/41.0/',
                requestHeaders: { Authorization: 'OAuth ' + sessionId},
                appendMessageTypeToURL : false
            });
            
            cometd.websocketEnabled = false;
            console.log('comet'+ JSON.stringify(cometd));
            component.set('v.cometd', cometd);
            // unless you have explicitly disconnected by calling disconnect().
            cometd.handshake($A.getCallback(function(status) {
                
                if (status.successful) {
                    console.log("Handshake");
                    var eventName = '/topic/CaseLightning';
                    var subscription = cometd.subscribe(eventName, $A.getCallback(function(message) {
                        //console.log("Subscribed");
                        
                        var userId = $A.get("$SObjectType.CurrentUser.Id");
                        console.log(message.data);
                        var payload= message.data;
                        if(payload.event.replayId %2==1)
                        {
                            component.set("v.PayloadOdd", payload.sobject.OwnerId);
                        }
                        else if(payload.event.replayId %2==0)
                        {
                            component.set("v.PayloadEven", payload.sobject.OwnerId);
                        }
                        
                        var payodd= component.get("v.PayloadOdd");
                        var payeven= component.get("v.PayloadEven");
                        
                        console.log('odd : '+payodd);
                        console.log('even : '+payeven);   
                      
                        if(payodd==userId && payeven==userId)
                        {
                            console.log('Matches!');
                            //Clearing Payload Values
                            component.set("v.PayloadOdd", "");
                            component.set("v.PayloadEven", "");
                            
                            var appEvent = $A.get("e.c:SC_Akatec_MyOpenCases_Refresher"); // firing event to refresh my open table
                            appEvent.fire();
                            
                            /*
                            var utilityAPI = component.find("utilitybar");
                            utilityAPI.setUtilityHighlighted({
                                highlighted: true
                            });*/
                            
                            //Firing Notification for customer update
                            {
                                var notification = new Notification(payload.sobject.AKAM_Case_ID__c , {
                                    icon: '',
                                    body: "You have an update from a customer for Case : "+payload.sobject.AKAM_Case_ID__c,
                                });
                                
                                notification.onclick = function () {
                                    
                                    var workspaceAPI = component.find("workspace");
                                    workspaceAPI.openTab({
                                        pageReference: {
                                            "type": "standard__recordPage",
                                            "attributes": {
                                                "recordId":payload.sobject.Id,
                                                "actionName":"view"
                                            },
                                            "state": {}
                                        },
                                        focus: true
                                    }).then(function(response) {
                                        workspaceAPI.getTabInfo({
                                            tabId: response
                                        }).then(function(tabInfo) {
                                            // console.log("The recordId for this tab is: " + tabInfo.recordId);
                                        });
                                    }).catch(function(error) {
                                        console.log(error);
                                    });
                                };
                                
                            }
                            
                        }
                        
                    }));
                    
                    component.set('v.subscription', subscription);
                    console.log('subs'+ JSON.stringify(subscription));
                    
                } else {
                    /// Cannot handshake with the server, alert user.
                    console.error('Error in handshaking: ' + status);
                }
            }));
            
        });
        $A.enqueueAction(action);
        
    },
    //Method - 3 : Unsubscribing from the pushtopic
    unsubscribe : function (component, event, helper) {
        //get reference if cometD instance
        var cometd = component.get("v.cometd");
        //get current subscription
        var subscription = component.get("v.subscription");
        
        if(cometd){
            //Unsubscribing the current subscription
            cometd.unsubscribe(subscription, {}, function(unsubscribeReply) {
                if(unsubscribeReply.successful) {
                    //unsubcription is susccessful, disconnect from server now
                    cometd.disconnect(function(disconnectReply) 
                                      { 
                                          console.log('Push topic successfully unsubscribed.');
                                          if(disconnectReply.successful) {
                                              console.log('Successfully disconnected to server');
                                          } else {
                                              //Error in disconnect. Show user alert
                                              console.error('Error is disconnecting')                    
                                          }
                                      });
                } else {
                    //Error in unsubscribe. Show user alert
                    console.error('Error in unsubscribe')                    		    
                }
            });
        }
    },
    
    //Method - 4 : Opening the Case Clicked into new console tab
    openNewTab:function(component, event, helper) {
        var ID = event.target.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":ID,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
                // console.log("The recordId for this tab is: " + tabInfo.recordId);
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
    //Method - 5: Opening new tab and supress case update
    openNewTabandClear:function(component, event, helper) {
        var ID = event.target.id;
        
        //Opening the tab in console
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":ID,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
                // console.log("The recordId for this tab is: " + tabInfo.recordId);
            });
        }).catch(function(error) {
            console.log(error);
        });
        
        //Removing the update notification
        
        var action = component.get("c.suppressCaseUpdate");
        action.setParams({
            "CaseID": ID
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var appEvent = $A.get("e.c:SC_Akatec_MyOpenCases_Refresher"); // firing event to refresh my open table
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    }
    
    
})