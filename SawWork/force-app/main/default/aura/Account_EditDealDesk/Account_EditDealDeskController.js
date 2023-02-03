({
	updateRecord : function(component, event, helper) {
		console.log("updateRecord entry in Account_editdealdesk");
        //Setting the Apex Parameter
        
        //fetch contact from apex controller
        helper.updateAccount(component);
       
        console.log("updateRecord exit in Account_editdealdesk");
        
	}
   
})