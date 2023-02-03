({
    init  : function(component, event, helper) {
        let lAuthorizedContactTableDataForEmail = component.get("v.lAuthorizedContactTableDataForEmail");
        
        //add a parameter isSelected(for checkbox) to all the records and make it false
        for(let eachAuthCon of lAuthorizedContactTableDataForEmail){
            eachAuthCon.isSelected = false;
        }
        console.log("In init SC_SOCC_EscalationViaCaseEmail_Add");
        console.log(lAuthorizedContactTableDataForEmail);
        component.set("v.lAuthorizedContactTableDataForEmail", lAuthorizedContactTableDataForEmail);
        component.set("v.lFilteredAuthorizedContactTableDataForEmail", lAuthorizedContactTableDataForEmail);
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
        let lAuthorizedContactTableDataForEmail = component.get("v.lAuthorizedContactTableDataForEmail");
        //add a parameter isSelected(for checkbox) to all the records and make it false
        for(let eachAuthCon of lAuthorizedContactTableDataForEmail){
            eachAuthCon.isSelected = isSelectAll;
        }
        component.set("v.lAuthorizedContactTableDataForEmail", lAuthorizedContactTableDataForEmail);
        component.set("v.lFilteredAuthorizedContactTableDataForEmail", lAuthorizedContactTableDataForEmail);
    },

    //To uncheck the Select All checkbox
    handleSelectAuthContact : function(component, event, helper){
        component.set("v.isSelectAll", false);
        console.log("lAuthorizedContactTableDataForEmail");
        console.log(component.get("v.lAuthorizedContactTableDataForEmail"));
        console.log("lAuthorizedContactTableDataForEmail");
        console.log(component.get("v.lAuthorizedContactTableDataForEmail"));
    },

    //Get all selected Authorized contacts and pass it to the parent component SC_SOCC_EscalationContact_Edit
    addAuthContacts : function(component, event, helper){
        helper.sendAuthContacts(component, event, helper);
    },
})