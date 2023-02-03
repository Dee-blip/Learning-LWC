({
	doInit : function(component, event, helper) {
      
      	
        var action = component.get("c.lightningRedirectionController");
        action.setParams({ "recordId" : component.get("v.recordId") });

       
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                
               var res = response.getReturnValue();
                
                var workspaceAPI = component.find("workspace");
        		workspaceAPI.isConsoleNavigation().then(function(response) {
                // redirection for non-console applications
            	if(!response){
                
          
                	if(res.recordTypeName == 'Service Incident' && !$A.util.isUndefinedOrNull(res.SIId)){
                        debugger;
                    	var navEvt = $A.get("e.force:navigateToURL");
    					navEvt.setParams({
      						"url": '/lightning/r/SC_SI_Service_Incident__c/'+res.SIId+'/view',
      					});
    					navEvt.fire();
                       
                	}
                       
                	
                } else{
                    // redirection for console applications
                    debugger;
                    if(res.recordTypeName == 'Service Incident'){
                        var focusedTabId;
                        	//Closing current tab of BMC Incident in console context
                            workspaceAPI.getFocusedTabInfo().then(function(response) {
                                focusedTabId = response.tabId;
                                
                            })
                            .catch(function(error) {
                                console.log(error);
                            });
                        	//Opening tab of new Service Incident in console context
                        	workspaceAPI.openTab({
                                recordId: res.SIId,
                                focus: true
                            }).then(function(response) {
                                workspaceAPI.closeTab({tabId: focusedTabId});
                                workspaceAPI.getTabInfo({
                                      tabId: response
                                }).then(function(tabInfo) {
                                console.log("The url for this tab is: " + tabInfo.url);
                                });
                            })
                            .catch(function(error) {
                                   console.log(error);
                            });
                    }     
                }    
            
        		})
        		.catch(function(error) {
            		console.log(error);
        		});
                
                   
                
            }
            else if (state === "INCOMPLETE") {
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

      
        $A.enqueueAction(action);  
      
	}
})