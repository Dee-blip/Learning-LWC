({
        ContentDocumentRecords : function( component ) {
        var Id = component.get("v.recordId"); 
        var action = component.get("c.getContentDocumentRecords");
        action.setParams({orderApprovalId : Id});
        action.setCallback(this, function(response) {
                var state = response.getState(); 
                if (component.isValid() && state === "SUCCESS"){
                    var result = JSON.stringify(response.getReturnValue());
                    console.log('Result List:'+result);
                    //Flattening the object. i. e modifying the response before binding it to the data table to get the owner name. 
                    var rows = response.getReturnValue();     
                    for (var i = 0; i < rows.length; i++) { 
                        var row = rows[i]; 
                        if (row.Owner) { 
                            row.OwnerName = row.Owner.Name;   
                        } 
                    }
                    console.log('Rows:'+JSON.stringify(rows));
                    component.set("v.cdList", response.getReturnValue());
                    /*
                    component.set('v.columnsName', [
                        {label: 'Name', fieldName: 'Title', type: 'text', wrapText: true},
                        {label: 'Owner', fieldName: 'OwnerName', type: 'text', fixedWidth: 130, wrapText: true},
                        {label: 'Modified Date', fieldName: 'LastModifiedDate', type: 'date', fixedWidth: 130}
                    ]);
                    */
                }
                else{
                    console.log('Oops. Some error occurred!');              
                }
            });
        $A.enqueueAction(action);
        },
    
    DataTableHeader : function( component ) {
        var action = component.get("c.getDataTableHeader");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS"){
                var result = response.getReturnValue();
                console.log('Column Headers:'+result);
                component.set('v.columnsName', JSON.parse(result));
                this.ContentDocumentRecords(component);
            }else{
                console.log('Oops. Some error occurred while retrieving column header');
            }
        });
        $A.enqueueAction(action);
    }
})