({
    //Initial Setup
    init: function (component, event, helper) {
        // Set the columns of the Table 
        component.set('v.columns', [
            {label: 'Salesforce ', fieldName: 'SFDCObject__c', type: 'text', sortable:true},
            {label: 'EDW', fieldName: 'EDWTable__c', type: 'text', sortable:true},
            {label: 'Application Type', fieldName: 'Application_Type__c', type: 'text', sortable:true}
           ]);
        // Set the size options for pagination
  			helper.getRecords(component);
    }
    ,
    performSearchField: function(component, event, helper) {
       
        var value1 = component.get("v.searchField1");
        var value2 = component.get("v.searchField2");
         var value3 = component.get("v.searchField3");
        var obj=[];
        for(var i= 0;i< component.get("v.FinaltabledataWarehouse").length ;i++){
            if(((component.get("v.FinaltabledataWarehouse["+i+"].SFDCObject__c")).toLowerCase().includes(value1.toLowerCase() ) || value1 == "")
              && ((component.get("v.FinaltabledataWarehouse["+i+"].EDWTable__c")).toLowerCase().includes(value2.toLowerCase() ) || value2 == "")
              && ((component.get("v.FinaltabledataWarehouse["+i+"].Application_Type__c")).toLowerCase().includes(value3.toLowerCase() ) || value3 == "")
             ){
                obj.push(component.get("v.FinaltabledataWarehouse")[i]); 
          }
        }
		component.set('v.PaginationList', obj); 
        
        
       }
  ,
    //Sorting method invoked on clicking on the field
    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
    
})