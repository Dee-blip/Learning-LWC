// Helper Class for - SC_NewCase_Lightning.cmp 

({
    // Method - 1 : For Getting Parent Account Id & Case Id from URL
    calculateParentAccount_CaseId_FromURL : function(component,event,userSelectedRecordTypeId,addressableContext) {
        var workspaceAPI = component.find("NewCaseworkspace");
        
        // Variable to store Parent AccountID & CaseID
        var parentAccountId = null;
        var parentCaseId = null;
        var getIndex_Account;
        var getIndex_Case;
        
        // For Getting complete URL
        var getParentURL =  window.location.href;  
        
        //Added by aditi for ESESP-3222 : Getting the parentCase Id from the contextRefId variable JSON
        if(typeof addressableContext !== "undefined") { 
            if(typeof addressableContext.attributes !== "undefined" && typeof addressableContext.attributes.recordId !== "undefined"){
                if(addressableContext.attributes.recordId.startsWith("500")){
                    parentCaseId = addressableContext.attributes.recordId;
                }
                else if(addressableContext.attributes.recordId.startsWith("001")){
                    parentAccountId = addressableContext.attributes.recordId;
                }
            }
        }
        //Aditi changes end here
        
        //Aditi added below if so that if we do not get the accountId from the above block using the ContextRef we use the old method in this class
        if(parentAccountId === null){
            // Getting Index of Account from Both Lightning Console and outside Console
            getIndex_Account = getParentURL.indexOf("%2Flightning%2Fr%2FAccount%2F"); 
            
            // For Inside Console
            if(getIndex_Account !== -1){
                parentAccountId = getParentURL.substr(getIndex_Account + 29, 18).toString();
                
            }
            // For outside Console
            else
            {
                getIndex_Account = getParentURL.indexOf("def_account_id");
                if(getIndex_Account !== -1){
                    parentAccountId = getParentURL.substr(getIndex_Account + 17, 15).toString();
                    
                }
            }
        }
        
        //Aditi added below if so that if we do not get the parentCaseId from the above block using the ContextRef we use the old method in this class
        if(parentCaseId === null){
            // Getting Index of Case
            getIndex_Case = getParentURL.indexOf("%2Flightning%2Fr%2FCase%2F");
            
            // For Inside Console
            if(getIndex_Case !== -1){
                parentCaseId = getParentURL.substr(getIndex_Case + 26, 18).toString();
            }
            // For outside Console
            else
            {
                getIndex_Case = getParentURL.indexOf("def_parent_id");
                if(getIndex_Case !== -1){
                    parentCaseId = getParentURL.substr(getIndex_Case + 16, 15).toString();
                }
                
            }
        }
        
        // Calling for Case Creation
        this.CallCaseCreationFromStandardNewButton(component,event,userSelectedRecordTypeId,parentAccountId,parentCaseId);
    },
    
    // Method - 2 : For deriving Navigation URL for VF Page & Standard record Creation Page
    CallCaseCreationFromStandardNewButton : function(component,event,userSelectedRecordTypeId,parentAccountId,parentCaseId) {
        
        //Variable for setting Navigation URL 
        var setNavigationURL;
        
        // Variable for Getting the PS Record Type Id
        var getPsRecTypeIdAction = component.get("c.getRecTypeId");
        getPsRecTypeIdAction.setParams({
            "recordTypeLabel": "Professional Services"
        });
        
        getPsRecTypeIdAction.setCallback(this, function(response) {
            
            if (response.getState() === "SUCCESS") {
                userSelectedRecordTypeId = userSelectedRecordTypeId.substr(0,15);
                var getPsRecTypeId  = response.getReturnValue().substr(0,15);
                
                // If User selected PS, then call VF Page directly Else pass the RecordTypeId
                if(userSelectedRecordTypeId == getPsRecTypeId){
                    setNavigationURL = '/apex/SC_EditCase?RecordType=' + getPsRecTypeId; 
                    this.redirectCaseCreationLandingPage(component,event,setNavigationURL,'true',parentAccountId,parentCaseId);
                }
                else
                {
                    this.redirectCaseCreationLandingPage(component,event,userSelectedRecordTypeId,'false',parentAccountId,parentCaseId);
                }
                
            }
            
        });
        $A.enqueueAction(getPsRecTypeIdAction);   
        
    },
    
    // Method - 2 : For Redirecting to VF Page or Standard Record Creation Page
    // Aditi updated this method for ESESP-3222 - calling apex to get the Parent AccountId rather if it is null but the ParentCaseId is there
    redirectCaseCreationLandingPage : function(component,event,navigationURL,isVFPageCall,parentAccountId,parentCaseId) {
        
        var workspaceAPI = component.find("NewCaseworkspace");
        var VFPageRedirectURL;
        var action;
        var action1;
        var createRecordEvent;
        
        //Aditi changes start here
        // If VF Page Call, then Call OpenTab function otherwise Call CreateRecord Method
        if(isVFPageCall === 'true'){
        
            // Variable for Designing Navigation for VF Page with dynamic parameters
            VFPageRedirectURL = navigationURL;
            
            // Logic for Parent Account Id
            if(parentAccountId !== null){
                VFPageRedirectURL += '&def_account_id='+parentAccountId;
            }
        
            // Logic for Parent Case Id
            if(parentCaseId !== null){
                //VFPageRedirectURL = navigationURL; - Commented by aditi as it was reseting the URL again
                VFPageRedirectURL += '&def_parent_id='+parentCaseId;
            }
            else{
                parentCaseId = component.get("v.parentCaseIdFrmSubTab");
                if(typeof parentCaseId !== "undefined" && parentCaseId !== null){
                    //VFPageRedirectURL = navigationURL; - Commented by aditi as it was reseting the URL again
                    VFPageRedirectURL += '&def_parent_id='+parentCaseId;
                }
            }
            
            if(parentCaseId !== null && parentAccountId === null){
                action = component.get("c.queryParentAccountId");
                action.setParams({
                    "idOftheCase": parentCaseId
                });
                action.setCallback(this, function(res) {
                    if (res.getState() === "SUCCESS") {
                        parentAccountId = res.getReturnValue();
                        
                        if(parentAccountId !== null){
                            VFPageRedirectURL += '&def_account_id='+parentAccountId;
                        }
                        workspaceAPI.isConsoleNavigation().then(function(consoleResponse) {            
                            console.log("IsConsole: ", consoleResponse);
                            if (consoleResponse) {
                                workspaceAPI.getFocusedTabInfo().then(function(tabResponse) {
                                    var closeTabId = tabResponse.tabId;
                                    var closeTitle = tabResponse.title;
                                    var parentTabId = tabResponse.parentTabId;
                                    var isSubtab = tabResponse.isSubtab;
                                    console.log("Current Tab: ", closeTabId + " | " + closeTitle);
                                    console.log("Is Sub: ",isSubtab," ParentId: ",parentTabId);
                     
                                    // Open Visualforce Page in a new tab
                                    if (isSubtab) {
                                        workspaceAPI.openSubtab({
                                            parentTabId: parentTabId,
                                            url: VFPageRedirectURL,
                                            focus: true
                                        }).then(function(openSubResponse) {
                                            console.log("New SubTab Id: ", openSubResponse);
                                        })
                                        .catch(function(error) {
                                            console.log(error);
                                        });                        
                                    } else {
                                        workspaceAPI.openTab({
                                            url: VFPageRedirectURL,
                                            focus: true
                                        }).then(function(openParResponse) {
                                            console.log("New ParentTab Id: ", openParResponse);
                                        })
                                        .catch(function(error) {
                                            console.log(error);
                                        });                        
                                    }
                     
                                    // Because exiting the VF page will reopen the object record,
                                    // close the tab we started on
                                    if (tabResponse.closeable && !tabResponse.pinned) {
                                        workspaceAPI.closeTab({
                                            tabId: closeTabId
                                        }).then(function(closeResponse) {
                                            console.log("closeResponse: ", closeResponse);
                                            console.log("Closed: ", closeTitle);                      
                                        })
                                        .catch(function(error) {
                                            console.log(error);
                                        });                            
                                    } else {
                                        console.log("Left Open: ", tabResponse.title);
                                    }
                                })
                                .catch(function(error){
                                    console.log('Error occurred here is = '+error);
                                    console.log('Error occurred here is = '+error.message);
                                });
                            }
                            else{
                                $A.get("e.force:navigateToURL").setParams({     
                                    "url": VFPageRedirectURL
                                }).fire();
                            }
                        });
                    }
                });
                $A.enqueueAction(action);
            }//End of if(parentCaseId != null && parentAccountId == null)
            else{
                workspaceAPI.isConsoleNavigation().then(function(consoleResponse) {            
                    console.log("IsConsole: ", consoleResponse);
                    if (consoleResponse) {
                        workspaceAPI.getFocusedTabInfo().then(function(tabResponse) {
                            var closeTabId = tabResponse.tabId;
                            var closeTitle = tabResponse.title;
                            var parentTabId = tabResponse.parentTabId;
                            var isSubtab = tabResponse.isSubtab;
                            console.log("Current Tab: ", closeTabId + " | " + closeTitle);
                            console.log("Is Sub: ",isSubtab," ParentId: ",parentTabId);
             
                            // Open Visualforce Page in a new tab
                            if (isSubtab) {
                                workspaceAPI.openSubtab({
                                    parentTabId: parentTabId,
                                    url: VFPageRedirectURL,
                                    focus: true
                                }).then(function(openSubResponse) {
                                    console.log("New SubTab Id: ", openSubResponse);
                                })
                                .catch(function(error) {
                                    console.log(error);
                                });                        
                            } else {
                                workspaceAPI.openTab({
                                    url: VFPageRedirectURL,
                                    focus: true
                                }).then(function(openParResponse) {
                                    console.log("New ParentTab Id: ", openParResponse);
                                })
                                .catch(function(error) {
                                    console.log(error);
                                });                        
                            }
             
                            // Because exiting the VF page will reopen the object record,
                            // close the tab we started on
                            if (tabResponse.closeable && !tabResponse.pinned) {
                                workspaceAPI.closeTab({
                                    tabId: closeTabId
                                }).then(function(closeResponse) {
                                    console.log("closeResponse: ", closeResponse);
                                    console.log("Closed: ", closeTitle);                      
                                })
                                .catch(function(error) {
                                    console.log(error);
                                });                            
                            } else {
                                console.log("Left Open: ", tabResponse.title);
                            }
                        })
                        .catch(function(error){
                            console.log('Error occurred here is = '+error);
                            console.log('Error occurred here is = '+error.message);
                        });
                    }
                    else{
                        $A.get("e.force:navigateToURL").setParams({     
                            "url": VFPageRedirectURL
                        }).fire();
                    }
                });
            }
        }//End of if(isVFPageCall == 'true'){
        else{
            //Added by aditi for ESESP-3222 - this block is executed if the PS RT is not selected when creating a new case
            if(parentCaseId !== null && parentAccountId === null){
                action1 = component.get("c.queryParentAccountId");
                action1.setParams({
                    "idOftheCase": parentCaseId
                });
                action1.setCallback(this, function(res) {
                    if (res.getState() === "SUCCESS") {
                        parentAccountId = res.getReturnValue(); 
                        
                        createRecordEvent = $A.get("e.force:createRecord");
                        createRecordEvent.setParams({
                            "entityApiName": "Case",
                            "recordTypeId": navigationURL,
                            "defaultFieldValues": {
                                'AccountId' : parentAccountId,
                                'ParentId': parentCaseId
                            }
                            
                        });
                        createRecordEvent.fire();
                    }
                });
                $A.enqueueAction(action1);
            }//End of if(parentCaseId != null && parentAccountId == null){
            else{
                //Aditi - ESESP-3222 : Added below without null check for parentAccountId and parentCaseId, it will work as it is already assigned as null so when null nothing is prepopulated 
                createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Case",
                    "recordTypeId": navigationURL,
                    "defaultFieldValues": {
                        'AccountId' : parentAccountId,
                        'ParentId': parentCaseId
                    }
                    
                });
                createRecordEvent.fire();
			}
		}//End of else part for Other RTs                                                       
	},
    // Method - 2 : For deriving Navigation URL for VF Page & Standard record Creation Page
    returnParentCaseId : function(component,event,helper) {
        var workspaceAPI = component.find("NewCaseworkspace");
        var getParentCaseIdfromSubtab = null;
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            
            var getParentURL = JSON.stringify(response);
            var getIndex_Case = getParentURL.indexOf("def_parent_id");
            if(getIndex_Case !== -1){
                getParentCaseIdfromSubtab = getParentURL.substr(getIndex_Case + 16, 15).toString();    
            }
            
            component.set("v.parentCaseIdFrmSubTab",getParentCaseIdfromSubtab);
        });
    }
})