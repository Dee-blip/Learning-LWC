({ 
    //Returns the records got from Apex
    getRecords: function(component ) {
  var action = component.get("c.getAllOracleSFDCMapping");
     action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS' && component.isValid()){
                // hold all the records into an attribute named "Finaltabledata"
                component.set('v.Finaltabledata', response.getReturnValue());
                component.set('v.FinaltabledataWarehouse', response.getReturnValue());
                component.set('v.PaginationList', response.getReturnValue());
               
            }else{
                alert('ERROR');
            }
        });
        $A.enqueueAction(action);
      
   }
   
    ,
    
    //Sorting data helper method 1
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.PaginationList");
        var reverse = sortDirection !== 'asc';
        if(data != null){
        data.sort(this.sortBy(fieldName, reverse));
        component.set("v.PaginationList", data);
        
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
    
})