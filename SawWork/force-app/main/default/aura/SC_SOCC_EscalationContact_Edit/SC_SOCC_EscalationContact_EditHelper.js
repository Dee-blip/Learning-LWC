({  //Set Table data called from init
    setTableData : function(component, event, helper, pdId, escalationListId, isinUtility) {
        let action = component.get("c.getEscalationContactRecords");
        action.setParams({
            "pdId" : pdId,
            "escalationListId" : escalationListId,
            "inUtility" : isinUtility
        });
        action.setCallback(this, function(response){
            let state = response.getState();
                    component.set("v.elSpinner",false);
            if(state === "SUCCESS"){
                let escalationListWrapper = response.getReturnValue();
                console.log("escalationListWrapper");
                console.log(escalationListWrapper);
                
                //Set lAvailability id no records/attribute present
                //let escConTableData = escalationListWrapper.escConTableData;
                /*for(let eachRec of escConTableData)
                if(!("lAvailability" in eachRec)){
                    eachRec["lAvailability"] = [];
                }*/
                
                let lAvailabilityRecords = escalationListWrapper.lAvailabilityRecords;
                console.log("lAvailabilityRecords");
                console.log(lAvailabilityRecords);

                //Set a track variable for checkbox
                let escConTableDataForEmail = escalationListWrapper.escConTableDataForEmail;
                for(let eachrec of escConTableDataForEmail){
                    eachrec.isSelected = false;
                }

                
                //console.log(escConTableData);
                //component.set("v.escConTableData", escConTableData);
                component.set("v.lEscConId", escalationListWrapper.lEscConId);
                component.set("v.lAuthConId", escalationListWrapper.lAuthConId);
                //component.set("v.nextOrderNumber", escalationListWrapper.escConTableData.length+1);
                component.set("v.escConTableDataForEmail", escConTableDataForEmail);
                component.set("v.lEscConIdForEmail", escalationListWrapper.lEscConIdForEmail);
                component.set("v.lAuthConIdForEmail", escalationListWrapper.lAuthConIdForEmail);
                component.set("v.countEscalationsViaCaseEmail", escConTableDataForEmail.length);

                console.log(component.get("v.escConTableDataForEmail"));
                
                console.log("nextOrderNumber");
                console.log(component.get("v.nextOrderNumber"));
                
                //Tejaswini-changes
                component.set("v.lAvailabilityRecords", lAvailabilityRecords);
                component.set("v.nextOrderNumber", escalationListWrapper.lAvailabilityRecords.length+1);
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
            }
            else
                helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
        });
        $A.enqueueAction(action);
    },

    //Generic toast message method
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode,duration_in_ms) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Saved!',
            duration:duration_in_ms,
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    
    //Sorting method
    sort_by_key : function(array)
    {
        return array.sort(function(a, b){
            var x = a.escCon.Order_Number__c; var y = b.escCon.Order_Number__c;
            return ((x < y) ? -1 : ((x > y) ? 1 : 0));
        });
    },
    
    //method to redirect
    redirectToRecord : function(component, event, helper, recordId){
        let workspaceAPI = component.find("workspace");
        //check if in console
        workspaceAPI.isConsoleNavigation().then(function(res){
            if(res){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    let focusedTabId = response.tabId;
                    console.log(focusedTabId);
                    
                    //Opening New Tab
                    workspaceAPI.openTab({
                        url: '#/sObject/' +recordId+ '/view'
                    }).then(function(response) {
                        workspaceAPI.focusTab({tabId : response});
                    })
                    .catch(function(error) {
                        console.log(error);
                    });
                    
                    //Closing old one
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
            else{
                /*let navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId,
                    "slideDevName": "detail"
                });
                navEvt.fire();*/
                window.parent.location = '/' + recordId;
            }
        })
        .catch(function(err) {
            console.log(err);
        });
    },

    // this function is automatically called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.elSpinner", true); 
    },
     
    // this function is automatically called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.elSpinner", false);
    }
})