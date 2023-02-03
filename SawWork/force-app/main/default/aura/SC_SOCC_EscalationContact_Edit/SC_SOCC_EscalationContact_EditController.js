({
    //  Get initial data to show all the existing Escalation Contacts
    getEscConData : function(component, event, helper) {
        component.set("v.elSpinner",true);
        var lActionIfUnreachable = [
            { value: "If no answer, move to next escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable1'), selected: true }, //If no answer, move to next escalation
            { value: "If no answer, call secondary phone, move to next escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable2') }, //If no answer, call secondary phone, move to next escalation
            { value: "If no answer, call secondary phone, leave voicemail, move to the next escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable3') }, //If no answer, call secondary phone, leave voicemail, move to the next escalation
            { value: "If no answer, call secondary phone, leave voicemail, end escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable4') }, //If no answer, call secondary phone, leave voicemail, end escalation
            { value: "If no answer, leave voicemail, move to the next escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable5') }, //If no answer, leave voicemail, move to the next escalation
            { value: "If no answer, leave voicemail, end escalation", label: $A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ActionIfUnreachable6') } //If no answer, leave voicemail, end escalation
        ];
        component.set("v.lActionIfUnreachable", lActionIfUnreachable);

        let params = event.getParam('arguments');
        if (params) {
            let pdId = params.pdId;
            let escalationListId = params.escalationListId;
            let isEditPage = params.isEditPage;
            let onCaseDetail = params.onCaseDetail;
            component.set("v.pdId", pdId);
            component.set("v.escalationListId", escalationListId);
            component.set("v.isEditPage", isEditPage);
            component.set("v.onCaseDetail", onCaseDetail);
            console.log("pdId: " + pdId + ". escalationListId: " + escalationListId + "." + isEditPage + "." + onCaseDetail);
            helper.setTableData(component, event, helper, pdId, escalationListId, onCaseDetail);
            //Check if in utility bar
            // let inCommunity = true;
            // let utilityAPI = component.find("utilitybar");
            // utilityAPI.getUtilityInfo().then(function(response) {
            //     inCommunity = false;
            //     helper.setTableData(component, event, helper, pdId, escalationListId, true);
            // }).catch(function(error) {
            //     inCommunity = false;
            //     helper.setTableData(component, event, helper, pdId, escalationListId, false);
            //     console.log(error);
            // });
            // console.log('end');
            // if(inCommunity)
            //     helper.setTableData(component, event, helper, pdId, escalationListId, false);
            // console.log('end 2');
        }
    },
    
    //Method to make the page editable. Called from the parent Component
    // makePageEditable : function(component, event, helper) {
    //  let params = event.getParam('arguments');
    //     if (params) {
    //         let isEditPage = params.isEditPage;
    //         component.set("v.isEditPage", isEditPage);
    //     }
    // },
    
    //To dynamically create SC_SOCC_EscalationContact_Add component modal
    openEscalationContactAddModal : function(component, event, helper) {
        console.log('openEscalationContactAddModal method');
        helper.showSpinner(component, event, helper);
        let pdId = component.get("v.pdId");
        let lAuthConId = component.get("v.lAuthConId");
        let action = component.get("c.getAuthorizedContactRecords");
        action.setParams({
            "pdId" : pdId,
            "lAuthConId" : lAuthConId
        });
        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let lAuthorizedContactTableData = response.getReturnValue();
                console.log('lAuthorizedContactTableData');
                console.log(lAuthorizedContactTableData);
                
                $A.createComponent(
                    "c:SC_SOCC_EscalationContact_Add",
                    {
                        "pdId": pdId,
                        "lAuthConId": lAuthConId,
                        "lAuthorizedContactTableData": lAuthorizedContactTableData
                    },
                    function(newEscalationContactAddModal, status, errorMessage){
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newEscalationContactAddModal);
                            component.set("v.body", body);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                        }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                        }
                    }
                );
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                helper.showToastMessage(component, event, helper,$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastTitleError'),errors[0].message,'Error','dismissible', 5000); //Error
            }
            else
                helper.showToastMessage(component, event, helper,$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastTitleError'),$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastMessageError'),'Error','dismissible', 5000); //'Darn it! Something went wrong! Please try again or contact your System Administrator!'
        });
        $A.enqueueAction(action);
    },
    
    //To dynamically create SC_SOCC_EscalationViaCaseEmail_Add component modal
    openEscalationContactAddModalForEmail : function(component, event, helper) {
        helper.showSpinner(component, event, helper);
        let pdId = component.get("v.pdId");
        let lAuthConIdForEmail = component.get("v.lAuthConIdForEmail");
        let action = component.get("c.getAuthorizedContactRecordsForEmail");
        action.setParams({
            "pdId" : pdId,
            "lAuthConIdForEmail" : lAuthConIdForEmail
        });
        
        action.setCallback(this, function(response){
            helper.hideSpinner(component, event, helper);
            let state = response.getState();
            if(state === "SUCCESS"){
                let lAuthorizedContactTableDataForEmail = response.getReturnValue();
                console.log('lAuthorizedContactTableDataForEmail');
                console.log(lAuthorizedContactTableDataForEmail);
                
                $A.createComponent(
                    "c:SC_SOCC_EscalationViaCaseEmail_Add",
                    {
                        "pdId": pdId,
                        "lAuthConIdForEmail": lAuthConIdForEmail,
                        "lAuthorizedContactTableDataForEmail": lAuthorizedContactTableDataForEmail
                    },
                    function(newEscalationContactAddModalForEmail, status, errorMessage){
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newEscalationContactAddModalForEmail);
                            component.set("v.body", body);
                        }
                        else if (status === "INCOMPLETE") {
                            console.log("No response from server or client is offline.")
                        }
                            else if (status === "ERROR") {
                                console.log("Error: " + errorMessage);
                        }
                    }
                );
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                helper.showToastMessage(component, event, helper,$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastTitleError'),errors[0].message,'Error','dismissible', 5000); //Error
            }
            else
            helper.showToastMessage(component, event, helper,$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastTitleError'),$A.get('$Label.c.Jarvis_SC_SOCC_EscalationContact_Edit_ToastMessageError'),'Error','dismissible', 5000); //'Darn it! Something went wrong! Please try again or contact your System Administrator!'
        });
        $A.enqueueAction(action);
    },
    
    //called from Child component SC_SOCC_EscalationContact_Add via event SC_SOCC_SendSelectedAuthCon
    //Adds the selected Authorized Contacts to the Escalation Contacts
    handleSelectedAuthCon : function(component, event, helper){
        //get parameters from event
        var lSelectedAuthorizedContacts = event.getParam("lSelectedAuthorizedContacts");
        console.log("lSelectedAuthorizedContacts in parent Edit component");
        console.log(lSelectedAuthorizedContacts);
        //let escConTableData = component.get("v.escConTableData");
        let lAvailabilityRecords = component.get("v.lAvailabilityRecords");
        
        let lAuthConId = component.get("v.lAuthConId");
        let nextOrderNumber = component.get("v.nextOrderNumber");
        
        //adding selected Authorized Contacts to Table data
        for(let eachAuthConRec of lSelectedAuthorizedContacts){
            //Adding to table data
            let eachEscConRec = {};
            let escCon = {Order_Number__c : nextOrderNumber++, Action_If_Unreachable__c : eachAuthConRec.Action_If_Unreachable__c, Authorized_Contact__c : eachAuthConRec.authCon.Id, Authorized_Contact__r : eachAuthConRec.authCon};
            eachEscConRec.escCon = escCon;
            //eachEscConRec.lAvailability = eachAuthConRec.lAvailability;
            //escConTableData.push(eachEscConRec);
            
            eachEscConRec.Monday = eachAuthConRec.Monday;
            eachEscConRec.Tuesday = eachAuthConRec.Tuesday;
            eachEscConRec.Wednesday = eachAuthConRec.Wednesday;
            eachEscConRec.Thursday = eachAuthConRec.Thursday;
            eachEscConRec.Friday = eachAuthConRec.Friday;
            eachEscConRec.Saturday = eachAuthConRec.Saturday;
            eachEscConRec.Sunday = eachAuthConRec.Sunday;
            eachEscConRec.OutOfOffice = eachAuthConRec.OutOfOffice;
            eachEscConRec.dayAndColor = eachAuthConRec.dayAndColor;
            eachEscConRec.isOOONow = eachAuthConRec.isOOONow;
            eachEscConRec.isOOORecordPresent = eachAuthConRec.isOOORecordPresent;
            lAvailabilityRecords.push(eachEscConRec);
            
            //Adding to Authorized Contact Id list
            lAuthConId.push( eachAuthConRec.authCon.Id);
        }
        
        //setting the attributes
        //component.set("v.escConTableData", escConTableData);
        component.set("v.lAvailabilityRecords", lAvailabilityRecords);
        component.set("v.lAuthConId", lAuthConId);
        component.set("v.nextOrderNumber", nextOrderNumber);
    },

    //called from Child component SC_SOCC_EscalationViaCaseEmail_Add via event SC_SOCC_SendSelectedAuthConForEmail
    //Adds the selected Authorized Contacts to the Escalations via Case Email
    handleSelectedAuthConForEmail : function(component, event, helper){
        //get parameters from event
        var lSelectedAuthorizedContactsForEmail = event.getParam("lSelectedAuthorizedContactsForEmail");
        console.log("lSelectedAuthorizedContactsForEmail in parent Edit component");
        console.log(lSelectedAuthorizedContactsForEmail);
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        let lAuthConIdForEmail = component.get("v.lAuthConIdForEmail");
        let countEscalationsViaCaseEmail = component.get("v.countEscalationsViaCaseEmail");
        
        //adding selected Authorized Contacts to Table data
        for(let eachAuthConRec of lSelectedAuthorizedContactsForEmail){
            //Adding to table data
            let eachEscViaCaseEmailRec = {Authorized_Contact__c : eachAuthConRec.Id, Authorized_Contact__r : eachAuthConRec};
            escConTableDataForEmail.push(eachEscViaCaseEmailRec);
            
            //Adding to Authorized Contact Id list
            lAuthConIdForEmail.push( eachAuthConRec.Id);
        }
        
        //setting the attributes
        component.set("v.escConTableDataForEmail", escConTableDataForEmail);
        component.set("v.lAuthConIdForEmail", lAuthConIdForEmail);
        component.set("v.countEscalationsViaCaseEmail", escConTableDataForEmail.length);
        component.set("v.isSelectAllEscEmail", false);
    },
    
    //Send completed Escalation Contacts Table Data to parent component to Save Escalation List and related Escalation Contacts
    save : function(component, event, helper){
        var sendSelectedEscCon = component.getEvent("sendSelectedEscCon");
        sendSelectedEscCon.setParams({
            //"lSelectedEscalationContacts" : component.get("v.escConTableData"),
            "lSelectedEscalationContacts" : component.get("v.lAvailabilityRecords"),
            "lEscConId" : component.get("v.lEscConId"),
            "lSelectedEscalationsViaCaseEmail" : component.get("v.escConTableDataForEmail"),
            "lEscConIdForEmail" : component.get("v.lEscConIdForEmail")
        });;
        sendSelectedEscCon.fire();
    },
    
    //Edit each Escalation Contact 
    editEachEscCon : function(component, event, helper){
        component.set("v.isEditingEscalationContact", true);
        let orderNumberId = event.target.id;
        let orderNumber = parseInt(orderNumberId.split("-")[1]);
        console.log(orderNumberId);
        console.log(orderNumber);
        //let escConTableData = component.get("v.escConTableData");
        let lAvailabilityRecords= component.get("v.lAvailabilityRecords");
        let escConEditRec = component.get("v.escConEditRec");
        let oldOrderNumber = component.get("v.oldOrderNumber");
        
        for(let eachRec of lAvailabilityRecords){
            console.log(eachRec.escCon.Order_Number__c);
            if(eachRec.escCon.Order_Number__c == orderNumber){
                //setting record to open in edit modal
                escConEditRec.Id = eachRec.escCon.Id;
                escConEditRec.Order_Number__c = eachRec.escCon.Order_Number__c;
                escConEditRec.Action_If_Unreachable__c = eachRec.escCon.Action_If_Unreachable__c;
                escConEditRec.Name = eachRec.escCon.Authorized_Contact__r.Contact_Name__r.Name;
                component.set("v.escConEditRec", escConEditRec);
                
                //store old order number
                oldOrderNumber = eachRec.escCon.Order_Number__c;
                component.set("v.oldOrderNumber", oldOrderNumber);
                break;
            }
        }
    },
    
    //Save each edited Escalation Contact 
    saveEachEscCon : function(component, event, helper){
        console.log("inside saveEachEscCon");
        //for validation checks
        let maxOrderNumber = component.get("v.nextOrderNumber")-1;
        let editOrderNumberCmp = component.find('editOrderNumber');
        let editOrderNumberVal = parseFloat(editOrderNumberCmp.get("v.value"));
        if(!isNaN(editOrderNumberVal) && !(editOrderNumberVal % 1 == 0 && editOrderNumberVal >= 1 && editOrderNumberVal <= maxOrderNumber))
            editOrderNumberCmp.setCustomValidity("Please enter Order Number between 1 to " + maxOrderNumber.toString() + ". Decimals are not allowed.");
        else
            editOrderNumberCmp.setCustomValidity("");
        //check if any validations are failing
        if(!editOrderNumberCmp.checkValidity())
            editOrderNumberCmp.reportValidity();
         
        //proceed if no validations failed
        else{
            //let escConTableData = component.get("v.escConTableData");
            let lAvailabilityRecords= component.get("v.lAvailabilityRecords");
            let escConEditRec = component.get("v.escConEditRec");
            let newOrderNumber = parseInt(escConEditRec.Order_Number__c);
            let oldOrderNumber = component.get("v.oldOrderNumber");
            
            //traversing all table data and updating the new order values
            for(let eachRec of lAvailabilityRecords){
                //Setting new order number for other record where newOrderNumber > oldOrderNumber
                if(newOrderNumber > oldOrderNumber && eachRec.escCon.Order_Number__c >= oldOrderNumber && eachRec.escCon.Order_Number__c <= newOrderNumber){
                    //Setting new order for edited record
                    if(eachRec.escCon.Order_Number__c == oldOrderNumber){
                        eachRec.escCon.Order_Number__c = newOrderNumber;
                        eachRec.escCon.Action_If_Unreachable__c = escConEditRec.Action_If_Unreachable__c;
                    }
                    else{
                        eachRec.escCon.Order_Number__c--;
                    }
                }
                
                //Setting new order number for other record where newOrderNumber < oldOrderNumber
                if(newOrderNumber < oldOrderNumber && eachRec.escCon.Order_Number__c >= newOrderNumber && eachRec.escCon.Order_Number__c <= oldOrderNumber){
                    //Setting new order for edited record
                    if(eachRec.escCon.Order_Number__c == oldOrderNumber){
                        eachRec.escCon.Order_Number__c = newOrderNumber;
                        eachRec.escCon.Action_If_Unreachable__c = escConEditRec.Action_If_Unreachable__c;
                    }
                    else{
                        eachRec.escCon.Order_Number__c++;
                    }
                }
                
                //Id Order is unchanged, then update only Action If Unreachable
                if(newOrderNumber == oldOrderNumber && eachRec.escCon.Order_Number__c == oldOrderNumber){
                    eachRec.escCon.Action_If_Unreachable__c = escConEditRec.Action_If_Unreachable__c;
                }
                
            }
            
            //Sort by Order Number
            lAvailabilityRecords = helper.sort_by_key(lAvailabilityRecords);
            //component.set("v.escConTableData", escConTableData);
            component.set("v.lAvailabilityRecords", lAvailabilityRecords);
            component.set("v.isEditingEscalationContact", false);
        }
    },
    
    //Delete single Escalation Contact record from the table
    delEachEscCon : function(component, event, helper){
        console.log("inside del each esc con");
        let orderNumberId = event.target.id;
        let orderNumber = parseInt(orderNumberId.split("-")[1]);
        //let escConTableData = component.get("v.escConTableData");
        let lAvailabilityRecords = component.get("v.lAvailabilityRecords"); 
        let lEscConId = component.get("v.lEscConId");
        let lAuthConId = component.get("v.lAuthConId");
        console.log(lEscConId);
        console.log(lAuthConId);
        let nextOrderNumber = component.get("v.nextOrderNumber");
        let delEscConId = "";
        let delAuthConId = "";
        
        //removing row from table
        for(let i=0; i<lAvailabilityRecords.length; i++){
            if(lAvailabilityRecords[i].escCon.Order_Number__c === orderNumber){
                delEscConId = lAvailabilityRecords[i].escCon.Id;
                delAuthConId = lAvailabilityRecords[i].escCon.Authorized_Contact__c;
                lAvailabilityRecords.splice(i, 1);
                i--;
            }
            else if(lAvailabilityRecords[i].escCon.Order_Number__c > orderNumber)
                lAvailabilityRecords[i].escCon.Order_Number__c--;
        }
        
        //removing Escalation Contact Id of deleted Escalation from the list
        lEscConId = lEscConId.filter(word => (!delEscConId) || word != delEscConId);  
        console.log(lEscConId);
        
        //removing Authorized Contact Id of deleted Escalation from the list
        lAuthConId = lAuthConId.filter(word => (!delAuthConId) || word != delAuthConId);  
        console.log(lAuthConId);
        
        //reduce the count of Next Order Number by 1
        nextOrderNumber--;
        
        //setting the attributes
        //component.set("v.escConTableData", escConTableData);
        component.set("v.lAvailabilityRecords", lAvailabilityRecords);
        component.set("v.lEscConId", lEscConId);
        component.set("v.lAuthConId", lAuthConId);
        component.set("v.nextOrderNumber", nextOrderNumber);
        
    },
    
    
    //Close Edit each Escalation Contact Modal
    closeEditEscConModal : function(component, event, helper){
        component.set("v.isEditingEscalationContact", false);
    },
    
    //Validate Order Number field
    validateOrderNumber : function(component, event, helper){
        //validation checks
        let maxOrderNumber = component.get("v.nextOrderNumber")-1;
        let editOrderNumberCmp = component.find('editOrderNumber');
        let editOrderNumberVal = parseFloat(editOrderNumberCmp.get("v.value"));
        if(!isNaN(editOrderNumberVal) && !(editOrderNumberVal % 1 == 0 && editOrderNumberVal >= 1 && editOrderNumberVal <= maxOrderNumber))
            editOrderNumberCmp.setCustomValidity("Please enter Order Number between 1 to " + maxOrderNumber.toString() + ". Decimals are not allowed.");
        else
            editOrderNumberCmp.setCustomValidity("");
        //check if any validations are failing
        if(!editOrderNumberCmp.checkValidity())
            editOrderNumberCmp.reportValidity();
    },
    
    //cancel button to redirect back to previous tab
    redirectToPD : function(component, event, helper){
        let pdId = component.get("v.pdId");
        let escalationListId = component.get("v.escalationListId");
        if(escalationListId)
            helper.redirectToRecord(component, event, helper, escalationListId);
        else
            helper.redirectToRecord(component, event, helper, pdId);
    },

    //Handle Select All checkbox to delete Escalations via Case Email
    handleSelectAllEscViaCaseEmail : function(component, event, helper){
        let isSelectAllEscEmail = component.get("v.isSelectAllEscEmail");
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        //add a parameter isSelected(for checkbox) to all the records and make it false
        for(let eachRec of escConTableDataForEmail){
            eachRec.isSelected = isSelectAllEscEmail;
        }
        component.set("v.escConTableDataForEmail", escConTableDataForEmail);

        //Setting Delete button text
        if(isSelectAllEscEmail){
            let deleteRecipientText = "Remove " + escConTableDataForEmail.length + " Recipents";
            component.set("v.deleteRecipientText", deleteRecipientText);
            component.set("v.noOfRecipients", String.valueOf(escConTableDataForEmail.length));
        }
        else{
            component.set("v.deleteRecipientText", "Remove Recipents");
        }
    },

    handleSelectEscViaCaseEmail : function(component, event, helper){
        component.set("v.isSelectAllEscEmail", false);
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        let count = 0;
        for(let eachRec of escConTableDataForEmail){
            if(eachRec.isSelected)
                count++;
        }

        //Setting Delete button text
        if(count > 0){
            let deleteRecipientText = "Remove " + count + " Recipents";
            component.set("v.deleteRecipientText", deleteRecipientText);
        }
        else{
            component.set("v.deleteRecipientText", "Remove Recipents");
        }

    },

    //Bulk Delete Escalations via Case Emails
    deleteEscViaCaseEmail : function(component, event, helper){
        component.set("v.deleteRecipientText", "Remove Recipents");
        component.set("v.isSelectAllEscEmail", false);
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        let lEscConIdForEmail = component.get("v.lEscConIdForEmail");
        let lAuthConIdForEmail = component.get("v.lAuthConIdForEmail");
        let countEscalationsViaCaseEmail = component.get("v.countEscalationsViaCaseEmail");
        let lDelEscConIdForEmail = [];
        let lDelAuthConIdForEmail = [];

        //Removing rows from table
        for(let i=0; i<escConTableDataForEmail.length; i++){
            if(escConTableDataForEmail[i].isSelected){
                if("Id" in escConTableDataForEmail[i]){
                    lDelEscConIdForEmail.push(escConTableDataForEmail[i].Id);
                }
                lDelAuthConIdForEmail.push(escConTableDataForEmail[i].Authorized_Contact__c);
                escConTableDataForEmail.splice(i, 1);
                i--;
                countEscalationsViaCaseEmail--;
            }
        }

        //removing Escalations via Case Email Id of deleted one from the list
        for(let eachId of lDelEscConIdForEmail){
            lEscConIdForEmail = lEscConIdForEmail.filter(word => (!eachId) || word != eachId);  
        }

        //removing Authorized Contact Id of deleted one from the list
        for(let eachId of lDelAuthConIdForEmail){
            lAuthConIdForEmail = lAuthConIdForEmail.filter(word => (!eachId) || word != eachId);  
        }

        console.log(escConTableDataForEmail);
        console.log(lEscConIdForEmail);
        console.log(lAuthConIdForEmail);

        component.set("v.escConTableDataForEmail", escConTableDataForEmail);
        component.set("v.lEscConIdForEmail", lEscConIdForEmail);
        component.set("v.lAuthConIdForEmail", lAuthConIdForEmail);
        component.set("v.countEscalationsViaCaseEmail", countEscalationsViaCaseEmail);
        component.set("v.isBulkDeleteEscalationViaCaseEmailModal", false);
    },

    //Delete single Escalation via Case Email record from the table
    delEachEscViaCaseEmail : function(component, event, helper){
        console.log("inside del each esc via case email");
        let rowId = event.target.id;
        let contactId = rowId.split("-")[1];
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        let lEscConIdForEmail = component.get("v.lEscConIdForEmail");
        let lAuthConIdForEmail = component.get("v.lAuthConIdForEmail");
        let countEscalationsViaCaseEmail = component.get("v.countEscalationsViaCaseEmail");
        let delEscConIdForEmail = "";
        let delAuthConIdForEmail = "";
        
        //removing row from table
        for(let i=0; i<escConTableDataForEmail.length; i++){
            if(escConTableDataForEmail[i].Authorized_Contact__r.Contact_Name__c == contactId){
                delEscConIdForEmail = escConTableDataForEmail[i].Id;
                delAuthConIdForEmail = escConTableDataForEmail[i].Authorized_Contact__c;

                //For Delete button text
                if(escConTableDataForEmail[i].isSelected){
                    let count = 0;
                    for(let eachRec of escConTableDataForEmail){
                        if(eachRec.isSelected)
                            count++;
                    }
                    //Setting Delete button text
                    if(count > 1){
                        console.log("-----count---");
                        console.log(count);
                        count--;
                        let deleteRecipientText = "Remove " + count.toString() + " Recipents";
                        console.log(deleteRecipientText);
                        component.set("v.deleteRecipientText", deleteRecipientText);
                    }
                    else if(count == 1){
                        component.set("v.isSelectAllEscEmail", false);
                        component.set("v.deleteRecipientText", "Remove Recipents");
                    }
                    else{
                        component.set("v.deleteRecipientText", "Remove Recipents");
                    }
                }


                escConTableDataForEmail.splice(i, 1);
                i--;
                countEscalationsViaCaseEmail--;
            }
        }
        
        //removing Escalation vis Case Email Id of deleted Escalation from the list
        lEscConIdForEmail = lEscConIdForEmail.filter(word => (!delEscConIdForEmail) || word != delEscConIdForEmail);  
        console.log(delEscConIdForEmail);
        
        //removing Authorized Contact Id of deleted Escalation from the list
        lAuthConIdForEmail = lAuthConIdForEmail.filter(word => (!delAuthConIdForEmail) || word != delAuthConIdForEmail);  
        console.log(delAuthConIdForEmail);
        
        //setting the attributes
        component.set("v.escConTableDataForEmail", escConTableDataForEmail);
        component.set("v.lEscConIdForEmail", lEscConIdForEmail);
        component.set("v.lAuthConIdForEmail", lAuthConIdForEmail);
        component.set("v.countEscalationsViaCaseEmail", countEscalationsViaCaseEmail);
    },

    //Show Modal to bulk delete Escalations via Case Email
    showBulkDeleteEscalationViaCaseEmailModal : function(component, event, helper){
        let hasSelectedRecords = false;
        let escConTableDataForEmail = component.get("v.escConTableDataForEmail");
        for(let eachRec of escConTableDataForEmail){
            if(eachRec.isSelected){
                hasSelectedRecords = true;
                break;
            }
        }

        if(hasSelectedRecords){
            component.set("v.isBulkDeleteEscalationViaCaseEmailModal", true);
        }
    },
    
    //Close Modal to bulk delete Escalations via Case Email
    closeBulkDeleteEscalationViaCaseEmailModal : function(component, event, helper){
        component.set("v.isBulkDeleteEscalationViaCaseEmailModal", false);
    }
})