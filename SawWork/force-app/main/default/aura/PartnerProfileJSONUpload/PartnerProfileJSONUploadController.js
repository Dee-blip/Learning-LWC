({  
    doInit:function(component,event,helper){  
    },      
    
    SendFiles : function(component, event, helper) {
        component.set("v.Spinner", true);
        helper.sendPartnerProfiles(component);
    },
    
    UploadFinished : function(component, event, helper) {
        component.set("v.Spinner", true);
        helper.updatePartnerProfiles(component,event);
    }
 })