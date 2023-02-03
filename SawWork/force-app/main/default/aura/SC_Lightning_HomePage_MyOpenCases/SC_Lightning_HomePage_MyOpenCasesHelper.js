({
    getMyOpenCases : function(component, event, helper) {
        
        var slalist=[];
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getMyopenCases");
        action.setParams({
            "userID": userId,
            "QueryType":'MyOpenCases'
            
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var myopenlst=response.getReturnValue();
                for(var i=0;i<myopenlst.length;i++)
                {
                    if(myopenlst[i].SLA_Color=="Red")
                    {slalist.push(myopenlst[i]);}
                }
                component.set("v.OpenCase", myopenlst);
                component.set("v.OpenCount", myopenlst.length);
                component.set("v.SLAMissList", slalist);
                component.set("v.SLAMissListcount", slalist.length);
                component.set("v.spinner",false);
                if(slalist.length>0)
                    component.set("v.HasMissedSLA",true);
                
            }
            
        });
        $A.enqueueAction(action);
        
    },
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    }
    
})