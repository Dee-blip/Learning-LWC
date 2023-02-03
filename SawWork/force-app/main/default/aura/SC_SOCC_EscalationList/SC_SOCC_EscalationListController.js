({
    init : function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        let pdId = component.get("v.recordId");
        component.set("v.pdId", pdId);
        let action = component.get("c.getlEscalationList");
        action.setParams({
            "pdId" : pdId
        });
        
        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let lEscalationList = response.getReturnValue();
                component.set("v.lEscalationList", lEscalationList);
                console.log("lEscalationList");
                console.log(lEscalationList);
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
    openEscContactModal:function(component, event, helper){
        
        let idEscalationListId = event.target.id;
        let escalationListId = idEscalationListId.split("-")[1];
        let pdId= component.get("v.recordId");
        var isEditPage=false;
        component.set("v.showEscalationContact", true);
        
        // setTimeout(function(){ 
        var escalationContactEditSection = component.find("escalationContactEditSections");
        escalationContactEditSection.getEscConData(pdId, escalationListId,isEditPage,false);
        //}, 500);
    },
    closeEscContactModal: function(component, event, helper){
        component.set("v.showEscalationContact", false);

    },
    //Refresh Escalation List
    refreshList : function(component, event, helper){
        let action = component.get('c.init');
        $A.enqueueAction(action);
    },
    
    //Create new Escalation List - calling SC_SOCC_EsclationList_CreateEdit in subtab
    createEscalationList : function(component, event, helper){
        helper.createEditEscalationList(component, event, helper);
    },
    
    //Edit Escalation List - calling SC_SOCC_EsclationList_CreateEdit in subtab
    editEachEscList : function(component, event, helper){
        let idEscalationListId = event.target.id;
        let escalationListId = idEscalationListId.split("-")[1];
        
        //helper.createEditEscalationList(component, event, helper, escalationListId, 'Edit');
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": escalationListId
        });
        editRecordEvent.fire();
    },
    
    //Open Modal to Copy the Escalation List record to a PD
    openCopyEachEscList : function(component, event, helper){
        helper.showSpinner(component, event, helper);
        // component.set("v.isCopyPDModal", true);
        let idEscalationListId = event.target.id;
        let escalationListId = idEscalationListId.split("-")[1];
        console.log(escalationListId);
        
        //List of all Escalation List
        let lEscalationList = component.get("v.lEscalationList");
        
        //get the current Escalation List record
        for(let eachRec of lEscalationList){
            if(eachRec.Id == escalationListId){
                //start server call getlPDForCopy
                //Get all the list of available Policy Domains
                let callGetlPDForCopy = component.get("c.getlPDForCopy");
                callGetlPDForCopy.setParams({
                    "escListRec": eachRec
                });
                callGetlPDForCopy.setCallback(this, function(response){
                    let state = response.getState();
                    if(state === "SUCCESS"){
                        let lPDForCopy = response.getReturnValue();
                        console.log("lPDForCopy");
                        console.log(lPDForCopy);
                        
                        //start server call getInvalidEscalationContacts
                        //Get the list of invalid Escalation Contacts for the first PD in lPDForCopy
                        let callGetInvalidEscalationContacts = component.get("c.getInvalidEscalationContacts");
                        callGetInvalidEscalationContacts.setParams({
                            "pdId": lPDForCopy[0].Id,
                            "escalationListId": escalationListId
                        });
                        
                        callGetInvalidEscalationContacts.setCallback(this, function(response){
                            helper.hideSpinner(component, event, helper);
                            let state = response.getState();
                            if(state === "SUCCESS"){
                                let notifyAndEscalationContactsWrapper = response.getReturnValue();
                                let lInvalidEscalationCon = notifyAndEscalationContactsWrapper.lEscalationContact;
                                let lInvalidEscalationViaCaseEmail = notifyAndEscalationContactsWrapper.lEscalationViaCaseEmail;
                                let lisNotCopiable = notifyAndEscalationContactsWrapper.notCopiable;
                       
                                console.log("lInvalidEscalationCon");
                                console.log(lInvalidEscalationCon);
                                console.log("lInvalidEscalationViaCaseEmail");
                                console.log(lInvalidEscalationViaCaseEmail);
                                console.log("lPDForCopy inside");
                                console.log(lPDForCopy);
                                //Create an Escalation List record
                                //Changes for ESESP-4955
                                let escalationListRec = {Id: eachRec.Id, Name: eachRec.Name, Policy_Domain__c: lPDForCopy[0].Id,isNotCopiable: lisNotCopiable};
                                console.log(escalationListRec);
                                
                                //Start of Create dynamic modal
                                $A.createComponent(
                                    "c:SC_SOCC_EscalationList_Copy",
                                    {
                                        "escalationListRec": escalationListRec,
                                        "lPDForCopy": lPDForCopy,
                                        "lInvalidEscalationCon": lInvalidEscalationCon,
                                        "lInvalidEscalationViaCaseEmail": lInvalidEscalationViaCaseEmail
                                    },
                                    function(newEscalationListCopyModal, status, errorMessage){
                                        try{
                                            if (status === "SUCCESS") {
                                                var body = component.get("v.body");
                                                body.push(newEscalationListCopyModal);
                                                component.set("v.body", body);
                                            }
                                            else if (status === "INCOMPLETE") {
                                                console.log("No response from server or client is offline.")
                                            }
                                                else if (status === "ERROR") {
                                                    console.log("Error: " + errorMessage);
                                                }
                                        } catch(e){
                                            console.error(e);
                                        }
                                    }
                                );//End of Create dynamic modal
                                
                                
                            }
                            else if (state === "ERROR") {
                                let errors = response.getError();
                                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
                            }
                                else
                                    helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
                        });
                        $A.enqueueAction(callGetInvalidEscalationContacts); //End server call getValidEscalationContacts
                    }
                    else if (state === "ERROR") {
                        let errors = response.getError();
                        helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
                    }
                        else
                            helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
                    
                });
                $A.enqueueAction(callGetlPDForCopy); //End server call getlPDForCopy
                
                
                
                break;
            }
        }
        
    },
    
    //Open Modal for Deleting the Escalation List record from a PD
    openDelEachEscListModal : function(component, event, helper){
        helper.showSpinner(component, event, helper);
        let idEscalationListId = event.target.id;
        let escalationListId = idEscalationListId.split("-")[1];
        component.set("v.delEscalationId", escalationListId);
        let action = component.get("c.getAssociatedHandlers");
        action.setParams({
            "delEscalationId" : escalationListId
        });
        
        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let lHandler = response.getReturnValue();
                console.log(lHandler);
                component.set("v.isDelEscListModal", true);
                if(lHandler.length > 0){
                    component.set("v.lHandler", lHandler);
                    component.set("v.isHandlerAssociated", true);
                }
                else
                    component.set("v.isHandlerAssociated", false);
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
    
    //Delete the Escalation List record from a PD
    confirmDelEachEscList : function(component, event, helper){
        helper.showSpinner(component, event, helper);
        let action = component.get("c.delEachEscList");
        action.setParams({
            "pdId" : component.get("v.pdId"),
            "delEscalationId" : component.get("v.delEscalationId")
        });
        
        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let lEscalationList = response.getReturnValue();
                console.log(lEscalationList);
                component.set("v.lEscalationList", lEscalationList);
                component.set("v.isDelEscListModal", false);
                helper.showToastMessage(component, event, helper,'Deleted','Huzzah! Record is deleted successfully! ‍🥳‍','success','dismissible', 5000);
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
    
    //Close Modal for Deleting the Escalation List record from a PD
    closeDelEscListModal : function(component, event, helper){
        component.set("v.isDelEscListModal", false);
    },
    
    //View Escalation List - calling SC_SOCC_EsclationList_CreateEdit in subtab
    viewEachEscList : function(component, event, helper){
        let idEscalationListId = event.target.id;
        let escalationListId = idEscalationListId.split("-")[1];
        let navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": escalationListId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    
    //To check/uncheck all the checkboxes
    // handleSelectAllEL : function(component, event, helper){
    //     let isSelectAll = component.get("v.isSelectAll");
    //     let lEscalationList = component.get("v.lEscalationList");
    //     //add a parameter isSelected(for checkbox) to all the records and make it false
    //     for(let eachrec of lEscalationList){
    //         eachrec.isSelected = isSelectAll;
    //     }
    //     component.set("v.lEscalationList", lEscalationList);
    // },
    
    //To uncheck the Select All checkbox
    // handleSelectEL : function(component, event, helper){
    //     component.set("v.isSelectAll", false);
    // },
    
    //Open Bulk delete modal
    // openBulkDelEscListModal : function(component, event, helper){
    //     let lEscalationList = component.get("v.lEscalationList");
    //     let lSelectedELId = [];
    //     for(let eachrec of lEscalationList){
    //         if(eachrec.isSelected)
    //             lSelectedELId.push(eachrec.Id);
    //     }
    
    //     console.log(lSelectedELId);
    //     if(lSelectedELId.length>0){
    //         component.set("v.isBulkDelEscListModal", true);
    //     }
    //     else
    //         helper.showToastMessage(component, event, helper,'Error: Please select at least one Escalation List to delete!',' ','Error','dismissible', 5000);
    // },
    
    //Close Bulk delete modal
    // closeBulkDelEscListModal : function(component, event, helper){
    //     component.set("v.isBulkDelEscListModal", false);
    // },
    
    //Bulk Delete Escalation List
    // bulkDeleteEscalationList : function(component, event, helper){
    //     let lEscalationList = component.get("v.lEscalationList");
    //     let lSelectedELId = [];
    //     for(let eachrec of lEscalationList){
    //         if(eachrec.isSelected)
    //             lSelectedELId.push(eachrec.Id);
    //     }
    
    //     console.log(lSelectedELId);
    //     if(lSelectedELId.length>0){
    //         let action = component.get("c.bulkDelEscList");
    //         action.setParams({
    //             "pdId" : component.get("v.pdId"),
    //             "lEscalationIdJson" : JSON.stringify(lSelectedELId)
    //         });
    
    //         action.setCallback(this, function(response){
    //             let state = response.getState();
    //             if(state === "SUCCESS"){
    //                 let lLatestEscalationList = response.getReturnValue();
    //                 component.set("v.lEscalationList", lLatestEscalationList);
    //                 component.set("v.isBulkDelEscListModal", false);
    //                 component.set("v.isSelectAll", false);
    //                 helper.showToastMessage(component, event, helper,'Deleted','Huzzah! Records are deleted successfully! ‍🥳‍','success','dismissible', 5000);
    //             }
    //             else if (state === "ERROR") {
    //                 var errors = response.getError();
    //                 helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
    //             }
    //             else
    //                 helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
    
    //         });
    //         $A.enqueueAction(action);
    //     }
    //     else
    //         helper.showToastMessage(component, event, helper,'Error: Please select at least one Escalation List to delete!',' ','Error','dismissible', 5000);
    // }
})