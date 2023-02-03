({
    //   Generic toast message method
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
    
    filterRecords : function(component, event, helper) {
        //Search Term
        let searchTerm = component.get("v.searchTerm");
        //All data
        let allData = component.get("v.lAuthorizedContactTableData");
        //Table data
        let data = component.get("v.lFilteredAuthorizedContactTableData");
            
        // check is data is not undefined and its lenght is greater than 0  
         if(data!=undefined || data.length>0){  
           // filter method create a new array that passes the search criteria (provided as function)  
           let filteredData = allData.filter(word => (!searchTerm) || word.authCon.Contact_Name__r.Email.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || word.authCon.Contact_Name__r.Name.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1);  
           /*
            let filteredData = [];
             for(let eachAuthCon of allData){
                 //check if search string is found
                 if(eachAuthCon.authCon.Contact_Name__r.Name.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1){
                     filteredData.push(eachAuthCon)
                 }
             }
             */
             
             console.log('** '+filteredData); 
             // set new filtered array value to data showing in the table.  
            component.set("v.lFilteredAuthorizedContactTableData", filteredData);
         }  
           
         // check if searchKey is blank  
         if(searchTerm==''){  
           // set unfiltered data to data in the table.  
            component.set("v.lFilteredAuthorizedContactTableData", allData);  
         } 
        
    },
    
    //Send the selected Auth Con as Escalation Contact to parent component.
    sendAuthContacts : function(component, event, helper) {
        console.log('inside sendAuthContacts');
        let lAuthorizedContactTableData = component.get("v.lAuthorizedContactTableData");
        let lSelectedAuthorizedContacts = [];
        for(let eachRec of lAuthorizedContactTableData){
            if(eachRec.isSelected){
                let selectedAuthCon = {}; 
                selectedAuthCon.authCon = eachRec.authCon;
                
                //selectedAuthCon.lAvailability = eachRec.lAvailability;
                selectedAuthCon.Monday = eachRec.Monday;
                selectedAuthCon.Tuesday = eachRec.Tuesday;
                selectedAuthCon.Wednesday = eachRec.Wednesday;
                selectedAuthCon.Thursday = eachRec.Thursday;
                selectedAuthCon.Friday = eachRec.Friday;
                selectedAuthCon.Saturday = eachRec.Saturday;
                selectedAuthCon.Sunday = eachRec.Sunday;
                selectedAuthCon.OutOfOffice = eachRec.OutOfOffice;
                selectedAuthCon.dayAndColor = eachRec.dayAndColor; 
                selectedAuthCon.isOOONow = eachRec.isOOONow; 
                selectedAuthCon.isOOORecordPresent = eachRec.isOOORecordPresent; 
                
                selectedAuthCon.Action_If_Unreachable__c = eachRec.Action_If_Unreachable__c;
                lSelectedAuthorizedContacts.push(selectedAuthCon);
            }
        }
        console.log("lSelectedAuthorizedContacts");
        console.log(lSelectedAuthorizedContacts);
        
        //Sending lSelectedAuthorizedContacts to Parent component SC_SOCC_EscalationContact_Edit
        var sendSelectedAuthCon = component.getEvent("sendSelectedAuthCon");
        sendSelectedAuthCon.setParams({
            "lSelectedAuthorizedContacts" : lSelectedAuthorizedContacts
        });
        sendSelectedAuthCon.fire();
        component.destroy();
    }
})