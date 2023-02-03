({
	init : function(component, event, helper) {
		// Setting columns for related list 
        component.set('v.columns', [
            {label: 'Subject', fieldName: 'recordLink', type: 'url',sortable: true,
        	typeAttributes: { label: { fieldName: "Subject" }, target: "_blank"}},
            
            {label: 'Type', fieldName: 'type', type: 'text'},
            {label: 'From Address', fieldName: 'FromAddress', type: 'text'},
            {label: 'To Address', fieldName: 'ToAddress', type: 'text'},
            {label: 'Message Date', fieldName: 'MessageDate', type: 'date',typeAttributes:{month: 'short',  
            year: 'numeric',  
            hour: '2-digit',  
            minute: '2-digit',  
            hour12: true}},
           
        ]);
		// Calling helper for data
      helper.helperMethod(component, event, helper);  


        
	},
    // method to decide if view all button to show        
    viewAllRelatedList : function(component, event, helper) {
            component.set("v.initialData",component.get("v.data"));
            component.set("v.showViewAll",false);
            
    }        
})