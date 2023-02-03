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
    
    filterRecords : function(component, event, helper) {
        //Search Term
		let searchTerm = component.get("v.searchTerm");
        //All data
        let allData = component.get("v.lAuthorizedContactTableDataForEmail");
        //Table data
        let data = component.get("v.lFilteredAuthorizedContactTableDataForEmail");
            
        // check is data is not undefined and its lenght is greater than 0  
         if(data!=undefined || data.length>0){  
           // filter method create a new array that passes the search criteria (provided as function)  
           let filteredData = allData.filter(word => (!searchTerm) || word.Contact_Name__r.Email.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1 || word.Contact_Name__r.Name.toLowerCase().indexOf(searchTerm.toLowerCase()) > -1);  
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
         	component.set("v.lFilteredAuthorizedContactTableDataForEmail", filteredData);
         }  
           
         // check if searchKey is blank  
         if(searchTerm==''){  
           // set unfiltered data to data in the table.  
         	component.set("v.lFilteredAuthorizedContactTableDataForEmail", allData);  
         } 
        
    },

    //Send the selected Auth Con as Escalations via Case Email to parent component.
    sendAuthContacts : function(component, event, helper) {
        console.log('inside sendAuthContacts');
        let lAuthorizedContactTableDataForEmail = component.get("v.lAuthorizedContactTableDataForEmail");
        let lSelectedAuthorizedContactsForEmail = [];
        for(let eachRec of lAuthorizedContactTableDataForEmail){
            if(eachRec.isSelected){
                lSelectedAuthorizedContactsForEmail.push(eachRec);
            }
        }
        console.log("lSelectedAuthorizedContactsForEmail");
        console.log(lSelectedAuthorizedContactsForEmail);
        
        //Sending lSelectedAuthorizedContactsForEmail to Parent component SC_SOCC_EscalationContact_Edit
        var sendSelectedAuthConForEmail = component.getEvent("sendSelectedAuthConForEmail");
        sendSelectedAuthConForEmail.setParams({
            "lSelectedAuthorizedContactsForEmail" : lSelectedAuthorizedContactsForEmail
        });
        sendSelectedAuthConForEmail.fire();
        component.destroy();
    }
})