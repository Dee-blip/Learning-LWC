({
    doInit : function(component, event, helper) {
        helper.DataTableHeader(component);
        //helper.ContentDocumentRecords(component);       
    },
    
    deleteFiles : function(component, event, helper) {
        var selectedEventId = event.target.id;
        var msg ='Are you sure you want to delete these files?';
        if (!confirm(msg)) {
            console.log('No');
            return false;
        } 
        else {
            console.log('Yes');
            var Id = component.get("v.recordId");
            var toastEvent = $A.get("e.force:showToast");
            var rows = [];
            rows = component.find('linesTable').getSelectedRows();
            var contentDocumentList = JSON.stringify(rows);
            console.log('Rows Selected:'+contentDocumentList);
            if(contentDocumentList.length > 0 ){
                console.log('Inside IF');
                component.set("v.isSpinner",true);
                var action = component.get("c.deleteContentFiles");
                action.setParams({contentDocumentLists : contentDocumentList});
                action.setCallback(this, function(response) {
                    component.set("v.isSpinner",false);
                    var state = response.getState();
                    var result = response.getReturnValue();
                    
                    if (component.isValid() && state === "SUCCESS" && result === "Success"){  
                        toastEvent.setParams({
                        "title": "Success!",
                        "message": "The record has been deleted successfully."
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                    else{
                        toastEvent.setParams({
                        "title": "Failure!",
                        "message": "Something went wrong.!!"
                        });
                        console.log('Error Message:'+result);
                        toastEvent.fire();                   
                    }                
                });
                $A.enqueueAction(action);     
            }
            else{
                console.log('Inside Else');
                toastEvent.setParams({
                    "title": "Message",
                    "message": "Please select a file to delete"
                });
                toastEvent.fire();
            }
        }
    },
    
    cancel : function(component, event, helper) {
        
        $A.get("e.force:closeQuickAction").fire();
    },
    
    updateIsRowSelected : function(component, event, helper) {
       var rows = [];
       rows = component.find('linesTable').getSelectedRows();
        if(rows.length>0){
            component.set('v.isRowSelected', false);
        }else{
            component.set('v.isRowSelected', true);
        }
    }
    
})