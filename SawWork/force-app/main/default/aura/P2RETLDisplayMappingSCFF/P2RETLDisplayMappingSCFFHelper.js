({ //Returns the object options got from getSFDCObject method of the class
    getOptions : function(component) {
        var action = component.get('c.getSFDCObject');
        action.setCallback(this, $A.getCallback(function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
        	component.set('v.SFDCObjectOptionList', response.getReturnValue());
        } 
        else if (state === "ERROR") {
        	 var errors = response.getError();
             console.error(errors);
            }
        }));
        $A.enqueueAction(action);
    }
    ,
    //Returns the records got from Apex
    getRecords: function(component ,SFDCObjectSelectedFromUI) {
  var action = component.get("c.getDetails");
        
       action.setParams({"SelectedSFDCObject": SFDCObjectSelectedFromUI });
       
          
     action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS' && component.isValid()){
                var pageSize = component.get("v.pageSize");
                // hold all the records into an attribute named "Finaltabledata"
                component.set('v.Finaltabledata', response.getReturnValue());
                component.set('v.FinaltabledataWarehouse', response.getReturnValue());
                
                // get size of all the records and then hold into an attribute "totalRecords"
                component.set("v.totalRecords", component.get("v.Finaltabledata").length);
                // set start as 0
                component.set("v.startPage",0);
                
                component.set("v.endPage",pageSize-1);
                var PaginationList = [];
                for(var i=0; i< pageSize; i++){
                    if(component.get("v.Finaltabledata").length> i)
                        PaginationList.push(response.getReturnValue()[i]);    
                }
                component.set('v.PaginationList', PaginationList);
               
            }else{
                alert('ERROR');
            }
        });
        $A.enqueueAction(action);
      
   }
   
    ,
     getRecords2: function(component) {
                var pageSize = component.get("v.pageSize");
                // get size of all the records and then hold into an attribute "totalRecords"
                component.set("v.totalRecords", component.get("v.Finaltabledata").length);
                // set start as 0
                component.set("v.startPage",0);
                component.set("v.endPage",pageSize-1);
                var PaginationList = [];
                for(var i=0; i< pageSize; i++){
                    if(component.get("v.Finaltabledata").length> i)
                        PaginationList.push(component.get("v.Finaltabledata")[i]);    
                }
                component.set('v.PaginationList', PaginationList);
            }
    ,
     // returns the CSV formatted String 
    convertArrayOfObjectsToCSV : function(component,objectRecords){
        // declare variables
        var csvStringResult, counter, keys, columnDivider, lineDivider;
        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
         }
        // store ,[comma] in columnDivider variabel for sparate CSV values and 
        // for start next line use '\n' [new line] in lineDivider varaible  
        columnDivider = ',';
        lineDivider =  '\n';
        // in the keys valirable store fields API Names as a key 
        // this labels use in CSV file header  
        keys = ['SFDC_Field_Name__c','Sfdc_Data_type__c','EDW_Field_Name__c','EDW_Field_DataType__c'];
        csvStringResult = '';
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;
        for(var i=0; i < objectRecords.length; i++){   
            counter = 0;
             for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;  
              // add , [comma] after every String value,. [except first]
                  if(counter > 0){ 
                      csvStringResult += columnDivider; 
                   }   
               csvStringResult += '"'+ objectRecords[i][skey]+'"'; 
               counter++;
            } // inner for loop close 
             csvStringResult += lineDivider;
          }// outer main for loop close 
       // return the CSV formate String 
        return csvStringResult;        
    }
    ,
    //Sorting data helper method 1
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.Finaltabledata");
        var reverse = sortDirection !== 'asc';
        if(data != null){
        data.sort(this.sortBy(fieldName, reverse));
        component.set("v.Finaltabledata", data);
        //Pagination after sorting
        var pageSize = component.get("v.pageSize");
 				component.set("v.startPage",0);
                component.set("v.endPage",pageSize-1);
        	 	component.set("v.index",1);
                var PaginationList = [];
                for(var i=0; i< pageSize; i++){
                    if(component.get("v.Finaltabledata").length> i)
                        PaginationList.push(component.get("v.Finaltabledata")[i]);    
                }
                component.set('v.PaginationList', PaginationList);
        
    }
    }
    ,
    //Sorting helper method 2
    sortBy: function (field, reverse) {
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
        return a = a[field], b = b[field], reverse * ((a > b) - (b > a));
        }
    }
    ,
    
// Method will be called when user clicks on next button and performs the calculation to show the next set of records
    next : function(component, event){
        var sObjectList = component.get("v.Finaltabledata");
        var end = parseInt(component.get("v.endPage"));
        var start =parseInt(component.get("v.startPage"));
        var Size = parseInt(component.get("v.pageSize")); ;
        var Paginationlist = [];
        var counter = 0;
        var i;
        for(i=end+1; i<end+Size+1; i++){
  
            if(sObjectList.length > i){
                Paginationlist.push(sObjectList[i]);
            }
            counter++ ;
        }
     
        start = start + counter;
        end = end + counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
        var ind=(end+1)/Size ;
        component.set("v.index",ind);
         
    },

//Method will be called when use clicks on previous button and performs the  calculation to show the previous set of records
    previous : function(component, event){
        var sObjectList = component.get("v.Finaltabledata");
        var end = parseInt(component.get("v.endPage"));
        var start = parseInt(component.get("v.startPage"));
        var pageSize = parseInt(component.get("v.pageSize"));
        var Paginationlist = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                Paginationlist.push(sObjectList[i]);
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationList', Paginationlist);
        var ind=(end+1)/pageSize;
        component.set("v.index",ind);
	}
})