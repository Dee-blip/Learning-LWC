({ 
    doInit : function(component) {
        var mailerData;
        var toastEvent;
        var navEvent
        var checkEditAccess
        if(component.get("v.recordId")!==null){
             checkEditAccess = component.get("c.getMailerData");
            checkEditAccess.setParams({
                "mailerId": component.get("v.recordId")
            });
            checkEditAccess.setCallback(this, function(result)
                                        {
                                            if(result.getState() === 'SUCCESS'){
                                                mailerData = result.getReturnValue();
                                                if(mailerData.EB_Status__c==='Draft'){
                                                    component.set("v.showINTComp",true); 
                                                }
                                                else{
                                                    toastEvent = $A.get("e.force:showToast");
                                                    toastEvent.setParams({
                                                        "type": "Error",
                                                        "message": "You cannot edit this record."
                                                    });
                                                    toastEvent.fire();
                                                    
                                                    navEvent = $A.get("e.force:navigateToSObject");
                                                    navEvent.setParams({
                                                        recordId: component.get("v.recordId"),
                                                        slideDevName: "detail"
                                                    });
                                                    navEvent.fire();
                                                }
                                            }                                        
                                        });
            $A.enqueueAction(checkEditAccess);
            
        }
        else{
         component.set("v.showINTComp",true);    
        }
    }
    
})