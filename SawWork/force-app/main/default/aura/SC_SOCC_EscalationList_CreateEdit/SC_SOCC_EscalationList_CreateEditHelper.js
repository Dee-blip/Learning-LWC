({
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
    
    //method to redirect
    redirectToRecord : function(component, event, helper, recordId){
        let workspaceAPI = component.find("workspace");
        //check if in console
        workspaceAPI.isConsoleNavigation().then(function(res){
            if(res){
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
            
                    //$A.get('e.force:refreshView').fire();
                    workspaceAPI.openTab({
                        recordId: recordId,
                        focus: true
                    }).then(function(response) {
                        workspaceAPI.getTabInfo({
                            tabId: response
                        }).then(function(tabInfo) {
                            let resptabId = tabInfo.tabId;
                            workspaceAPI.closeTab({
                                tabId: focusedTabId
                            });
                            workspaceAPI.refreshTab({
                                tabId: resptabId
                            }).then(function(response) {
                                workspaceAPI.closeTab({
                                    tabId: focusedTabId
                                });
            
                            });
            
                        });
            
                    });
                })
                .catch(function(error) {
                    console.log(error);
                });
            }
            else{
                /*
                let navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": recordId
                });
                navEvt.fire();
                */
                //window.location.href = '/'+recordId ;
                window.parent.location = '/' + recordId;
            }
        })
        .catch(function(err) {
            console.log(err);
        });
    },
    
    //Load the complete Escalation List data including the existing escalation contacts
    loadCompleteData : function(component, event, helper, pdId, escalationListId, operation){
        helper.showSpinner(component, event, helper);
        //making a server call and prepopulating the field values on Escalation List record
        let action = component.get("c.getData");
        action.setParams({
            "pdId" : pdId,
            "escalationListId" : escalationListId
        });

        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let escalationListInstructionWrapper = response.getReturnValue();
                console.log("escalationListInstructionWrapper");
                console.log(escalationListInstructionWrapper);

                //setting the current PD id and Escalation List record
                let escRec = escalationListInstructionWrapper.escalationListRec;
                component.set("v.escRec", escRec);
                let currPdId = "";
                if(escRec){
                    currPdId = escRec.Policy_Domain__c;
                    component.set("v.pdId", currPdId);
                    
                }
                    

                //Setting the Pending Approval Rec and its status indicator
                if(escalationListInstructionWrapper.pendingInstructionRec){
                    component.set("v.pendingInstructionRec", escalationListInstructionWrapper.pendingInstructionRec);
                    component.set("v.hasPendingInstruction", true);
                }
                
                //setting tab heading if called from custom create button
                if(operation && operation == "New"){
                    helper.setTabName(component, event, helper, "New Escalation List");
                }
                
                // call the aura:method in the child component SC_SOCC_EscalationContact_Edit
                let isEditPage = component.get("v.isEditPage");
                console.log('-- isEditPage : ' + isEditPage);
                var escalationContactEditSection = component.find("escalationContactEditSection");
                escalationContactEditSection.getEscConData(currPdId, escalationListId, isEditPage, false);
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
    
    //Set Tab name and icon
    setTabName : function(component, event, helper, tabHeading){
        //Setting the tab name and icon
        let workspaceAPI = component.find("workspace");
        window.setTimeout($A.getCallback(function() {
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                let focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: tabHeading //set label you want to set
                });
                workspaceAPI.setTabIcon({
                    tabId: focusedTabId,
                    icon: "utility:new_person_account", //set icon you want to set
                    iconAlt: tabHeading //set label tooltip you want to set
                });
            })
        }), 500);
    },

    //Escalation List field validations
    checkValidation : function(component, event, helper){
        //Escalation Name Field Validations
        let escRec = component.get("v.escRec");
        let lSelectedEscalationsViaCaseEmail;
        console.log('the escrec is'+JSON.stringify(escRec));
        lSelectedEscalationsViaCaseEmail = event.getParam("lSelectedEscalationsViaCaseEmail");
        //console.log('the esc via email '+JSON.stringify(lSelectedEscalationsViaCaseEmail));
        //console.log('the length is'+lSelectedEscalationsViaCaseEmail.length);
        
        console.log(escRec);
        if(!escRec || !escRec.Name){
            helper.showToastMessage(component, event, helper,'Escalation List Name: You must enter a value!',' ','Error','dismissible', 5000);
            return false;
        }
        if(!escRec.Policy_Domain__c){
            helper.showToastMessage(component, event, helper,'Policy Domain: You must enter a value!',' ','Error','dismissible', 5000);
            return false;
        }
        if(escRec.Name.length > 80){
            helper.showToastMessage(component, event, helper,'Escalation List Name: Max input length is 80!',' ','Error','dismissible', 5000);
            return false;
        }
        //Changes for ESESP-4955
        //Escalation via Case email validation
        if(lSelectedEscalationsViaCaseEmail.length===0){
            helper.showToastMessage(component, event, helper,'Notify Via Case Email should not be empty!',' ','Error','dismissible', 5000);
            return false;
        }
        
        //Suggested Instruction validations
        let pendingInstruction = component.get("v.pendingInstruction");
        if(pendingInstruction && pendingInstruction.length > 32767){
            helper.showToastMessage(component, event, helper,'Suggest Instructions: Max input length is 32767!',' ','Error','dismissible', 5000);
            return false;
        }

        return true;
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