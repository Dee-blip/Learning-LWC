({
    isDeletedHelper:function(component,event){
        var recordId = component.get('v.recordId');
        var isDeletedAction =  component.get('c.isDeleted');
        isDeletedAction.setParams({
            tsaId : recordId
        });
        isDeletedAction.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS"){
                console.log('isDeleted --> '+resp.getReturnValue());
                component.set('v.isDeleted',resp.getReturnValue());
            }else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
                else if (state === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
        });        
        $A.enqueueAction(isDeletedAction);
    },    
    toggleDeleteHelper: function(component,event){
        var recordId = component.get('v.recordId');
        var itemToSoftdelete =  component.get('c.toggle_soft_delete');
        itemToSoftdelete.setParams({
            tsaId : recordId
        });
        itemToSoftdelete.setCallback(this,function(response){
            var state = response.getState();
            //console.log(state);
            if(state === "SUCCESS"){
                //component.set('v.recordFlag',response.getReturnValue());
                console.log('softdelete --> '+response.getReturnValue());
                var recorddata = response.getReturnValue();
                //console.log(' ---> '+recorddata.Is_Deleted__c);
                var show = recorddata.Is_Deleted__c;
                //console.log(show);
                if(show === true)
                    this.showToast(component,event,'Record Soft Deleted !',JSON.stringify(response.getReturnValue()),'success');
                else
                    this.showToast(component,event,'Restored Successfully !',JSON.stringify(response.getReturnValue()),'success');
                //window.location.href = "/lightning/o/Territory_Security_Assignment__c/list";
            }else if (state === "INCOMPLETE") {
                console.log("No response from server or client is offline.")
                // Show offline error
            }
                else if (state === "ERROR") {
                    if(response.getError() && response.getError().length > 0 && response.getError()[0].message == 'Application is currently running on read-only mode!') {
                        //if(response.getError() && response.getError().length > 0 && CONTAINS(response.getError()[0].message,'Application is currently')) {
                        this.showToast(component,event,'Cannot Delete or Restore!',JSON.stringify(response.getError()[0].message),'error');
                    }
                    else if(response.getError() && response.getError().length > 0 && response.getError()[0].message == 'insufficient access rights on object id') {
                        this.showToast(component,event,'Insufficient Access!',JSON.stringify(response.getError()[0].message),'error');
                    }
                        else
                        {
                            this.showToast(component,event,'Duplicate Security Assignment already exixts!',JSON.stringify(response.getError()[0].message),'error');
                        }
                    // Show error message
                }
            
        });
        $A.enqueueAction(itemToSoftdelete);
    },
    showToast : function(component, event,title,message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
        $A.get("e.force:closeQuickAction").fire();
        if(type == 'success') {
            setTimeout(function(){ window.location.href = "/lightning/o/Territory_Security_Assignment__c/list"; }, 3000);
        }
    }, 
    /*showToast1 : function(component, event,title,message, type) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": title,
        "message": message,
        type: 'error'
    });
    toastEvent.fire();
    $A.get("e.force:closeQuickAction").fire();
    
} */
})