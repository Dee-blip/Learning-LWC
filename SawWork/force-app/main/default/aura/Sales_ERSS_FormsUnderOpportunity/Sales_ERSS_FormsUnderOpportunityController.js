({
    doInit : function(component, event, helper) {

        
        var oppId = component.get("v.recordId ");
        
        var action = component.get("c.getPublishedFormsUnderOpportunity");
         action.setParams({
            oppId : oppId
            
        });
        action.setCallback(this,function(a){
            var state = a.getState();
            if(state == "SUCCESS"){
                
                
                
                component.set("v.rssList",a.getReturnValue());
                
            
            }
            else{
               
                console.log('error in Success');
                console.log(JSON.stringify(a.getError()));
            }
        });
         $A.enqueueAction(action);
    }
})