({
    doInit : function(component, event, helper) {
        
        helper.doInitHelper(component, event);
    },
    
    deleteFileAction: function(component, event, helper) { //this function is used to delete the attachment and files 
        var result = confirm("Want to delete?");
        if (result) {
            helper.deleteActionHelper(component, event,helper);
        }        
    }
})