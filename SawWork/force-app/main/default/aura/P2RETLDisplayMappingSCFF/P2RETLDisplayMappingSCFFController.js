({
    //Initial Setup
    init: function (component, event, helper) {
        // Set the columns of the Table 
        component.set('v.columns', [
            {label: 'Salesforce field name', fieldName: 'SFDC_Field_Name__c', type: 'text', sortable:true},
            {label: 'Salesforce data type', fieldName: 'Sfdc_Data_type__c', type: 'text', sortable:true},
            {label: 'EDW column name', fieldName: 'EDW_Field_Name__c', type: 'text', sortable:true},
            {label: 'EDW data type', fieldName: 'EDW_Field_DataType__c', type: 'text', sortable:true}
        ]);
        // Set the size options for pagination
        var options = [
            { value: "10", label: "10" },
            { value: "100", label: "100" },
            { value: "1000", label: "All" }
        ];
        component.set("v.sizeOptions", options);
        helper.getOptions(component);
    }
    ,
    performSearchField: function(component, event, helper) {
       
        var value1 = component.get("v.searchField1");
        var value2 = component.get("v.searchField2");
        var value3 = component.get("v.searchField3");
        var value4 = component.get("v.searchField4");
        var obj=[];
        for(var i= 0;i< component.get("v.FinaltabledataWarehouse").length ;i++){
            if(((component.get("v.FinaltabledataWarehouse["+i+"].SFDC_Field_Name__c")).toLowerCase().includes(value1.toLowerCase() ) || value1 == "")
              && ((component.get("v.FinaltabledataWarehouse["+i+"].Sfdc_Data_type__c")).toLowerCase().includes(value2.toLowerCase() ) || value2 == "")
              && ((component.get("v.FinaltabledataWarehouse["+i+"].EDW_Field_Name__c")).toLowerCase().includes(value3.toLowerCase() ) || value3 == "")
              && ((component.get("v.FinaltabledataWarehouse["+i+"].EDW_Field_DataType__c")).toLowerCase().includes(value4.toLowerCase() ) || value4 == "")
              ){
                obj.push(component.get("v.FinaltabledataWarehouse")[i]); 
          }
        }
		component.set('v.Finaltabledata', obj); 
        helper.getRecords2(component); 
        }
   , 
    
    //Search method everytime a new key is pressed for the suggestion box
    performSearch: function(component, event, helper) {
        var value = component.get("v.searchQuery");
        var resultsFinal=component.get("v.SFDCObjectOptionList");
        var results = [];
        
        if(value == null || value == ''){
            results = [];
        }
        
        else if(value.includes("*") || value.includes("\\")||value.includes("(")||value.includes(")")||value.includes("?")||value.includes("["))
        {
            
        }
            else{
                
                var reg = new RegExp(value, 'i');
                for(var key in resultsFinal){
                    if(String(resultsFinal[key]).match(reg)){
                        results.push(resultsFinal[key]);
                    }
                }
            }
        component.set("v.results",results);       
    }
    ,
    //Next method for pagination
    next: function (component, event, helper) {
        helper.next(component, event);
    }
    ,
    //Previous method for pagination
    previous: function (component, event, helper) {
        helper.previous(component, event);
    }
    ,
    //function call on Click on the "Download As CSV" Button. 
    downloadCsv : function(component,event,helper){
        // get the Records list from 'Finaltabledata' attribute 
        var stockData = component.get("v.Finaltabledata");
        // call the helper function which "return" the CSV data as a String   
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData);   
        if (csv == null){return;} 
        //code for create a temp. <a> html tag [link tag] for download the CSV file    
        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self'; // 
        hiddenElement.download = component.get("v.SelectedObjectAndTable[0]")+'__To__'+component.get("v.SelectedObjectAndTable[1]")+'__Data.csv';  // CSV file Name* you can change it.[only name not .csv] 
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click(); 					  // using click() js function to download csv file
    }
    ,
    
    //Gets invoked when a new option is selected and gets new data for table
    onSelectChangeObject : function(component, event, helper) {
        var SFDCObjectSelectedFromUI=event.currentTarget.dataset.name;
        component.set("v.results",[]);
        component.set("v.searchQuery","");
        component.set("v.searchQuery",SFDCObjectSelectedFromUI);
        component.set("v.index",1);
        var action = component.get("c.getOracleSFDCMapping");
        action.setParams({"SelectedSFDCObject": SFDCObjectSelectedFromUI});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                component.set("v.SelectedObjectAndTable", response.getReturnValue());
                
            } 
        });
        $A.enqueueAction(action);
        helper.getRecords(component,SFDCObjectSelectedFromUI);     
    }
    ,
   //Gets invoked when a new option is selected and gets new data for table
    onSelectChangeSize : function(component, event, helper) {
        var size = event.getParam("value");
        var pagesize1=  component.get("v.pageSize");
        component.set("v.pageSize", size);
        component.set("v.index",1);
        helper.getRecords2(component);     
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