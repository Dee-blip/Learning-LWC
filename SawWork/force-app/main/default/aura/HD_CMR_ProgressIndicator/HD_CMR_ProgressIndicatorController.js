({
	doInit : function(component, event, helper) {
        
        if(component.get("v.change") == null){
            var action =component.get("c.getChange");
            action.setParams({Id:component.get("v.recordId")});
            action.setCallback(this,function(data){
                var state=data.getState();
                if(state==="SUCCESS"){
                    var result=data.getReturnValue();
                    component.set("v.change", result);
                    helper.setStatuses(component);
                }else if (state==="Error"){
                    console.log("Error Occured");
                }
            });
            $A.enqueueAction(action);
            
        }else{
            helper.setStatuses(component);
        }
       	
    },refreshPreviewCMR : function (component, event, helper) {
        
        //set that data to change variable
        helper.setStatuses(component);  
    },
    onstepblur: function (component, event, helper) {
        var test="test";
        
    },
    onstepfocus: function (component, event, helper) {
        var test="test";
        
    },
    onstepmouseenter: function (component, event, helper) {
        var test="test";
        
    },
    onstepmouseleave: function (component, event, helper) {
        var test="test";
        
    }

    
    
})