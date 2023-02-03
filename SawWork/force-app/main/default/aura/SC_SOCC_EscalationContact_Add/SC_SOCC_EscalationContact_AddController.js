({
    init  : function(component, event, helper) {
        var lActionIfUnreachable = [
            { value: "If no answer, move to next escalation", label: "If no answer, move to next escalation", selected: true },
            { value: "If no answer, call secondary phone, move to next escalation", label: "If no answer, call secondary phone, move to next escalation" },
            { value: "If no answer, call secondary phone, leave voicemail, move to the next escalation", label: "If no answer, call secondary phone, leave voicemail, move to the next escalation" },
            { value: "If no answer, call secondary phone, leave voicemail, end escalation", label: "If no answer, call secondary phone, leave voicemail, end escalation" },
            { value: "If no answer, leave voicemail, move to the next escalation", label: "If no answer, leave voicemail, move to the next escalation" },
            { value: "If no answer, leave voicemail, end escalation", label: "If no answer, leave voicemail, end escalation" }
        ];
        component.set("v.lActionIfUnreachable", lActionIfUnreachable);
            

        let lAuthorizedContactTableData = component.get("v.lAuthorizedContactTableData");
        
        //   add a parameter isSelected(for checkbox) to all the records and make it false
        for(let eachAuthCon of lAuthorizedContactTableData){
            eachAuthCon.isSelected = false;
            eachAuthCon.Action_If_Unreachable__c = "If no answer, move to next escalation";
            /*if(!("lAvailability" in eachAuthCon)){
                eachAuthCon["lAvailability"] = [];
            }*/
        }
        console.log(lAuthorizedContactTableData);
        component.set("v.lAuthorizedContactTableData", lAuthorizedContactTableData);
        component.set("v.lFilteredAuthorizedContactTableData", lAuthorizedContactTableData);
        
    },
    
    //to close and destroy the Modal
    closeMe  : function(component, event, helper) {
        component.destroy();
    },
    
    //to filter the auth contacts based on search term
    dofilter  : function(component, event, helper){
        helper.filterRecords(component, event, helper);
    },
    
    //To check/uncheck all the checkboxes
    handleSelectAllAuthContact : function(component, event, helper){
        let isSelectAll = component.get("v.isSelectAll");
        let lAuthorizedContactTableData = component.get("v.lAuthorizedContactTableData");
        //add a parameter isSelected(for checkbox) to all the records and make it false
        for(let eachAuthCon of lAuthorizedContactTableData){
            eachAuthCon.isSelected = isSelectAll;
        }
        component.set("v.lAuthorizedContactTableData", lAuthorizedContactTableData);
        component.set("v.lFilteredAuthorizedContactTableData", lAuthorizedContactTableData);
    },
    
    //To uncheck the Select All checkbox
    handleSelectAuthContact : function(component, event, helper){
        component.set("v.isSelectAll", false);
        console.log("lAuthorizedContactTableData");
        console.log(component.get("v.lAuthorizedContactTableData"));
        console.log("lFilteredAuthorizedContactTableData");
        console.log(component.get("v.lFilteredAuthorizedContactTableData"));
    },
    
    //Get all selected Authorized contacts and pass it to the parent component SC_SOCC_EscalationContact_Edit
    addAuthContacts : function(component, event, helper){
        console.log('inside addAuthContacts');
        let lAuthorizedContactTableData = component.get("v.lAuthorizedContactTableData");
        let warnedContacts = [];
        //Check if Primary Contact Method is not set
        for(let eachRec of lAuthorizedContactTableData){
            if(eachRec.isSelected && !eachRec.authCon.Contact_Name__r.Primary_Contact_Method__c){
                warnedContacts.push(eachRec.authCon.Contact_Name__r.Name);
            }
        }
        console.log("warnedContacts");
        console.log(warnedContacts);
        
        if(warnedContacts.length > 0){
            component.set("v.warnedContacts", warnedContacts);
            component.set("v.hasWarning", true);
        }
        else
            helper.sendAuthContacts(component, event, helper);
    },

    //confirm Addition of Auth Contacts
    confirmAddAuthContacts : function(component, event, helper) {
        helper.sendAuthContacts(component, event, helper);
    },
    
    //hideWarningModal
    hideWarningModal : function(component, event, helper) {
        component.set("v.hasWarning", false);
    }
})