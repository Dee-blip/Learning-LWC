({
    componentToastHandler:function(component,title,message,type)
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message":message,
            "type":type
        });
        toastEvent.fire();   
    },
    OpenHandlerEditModal:function(component,row)
    {
        let handlerIdList = [];
        handlerIdList.push(row.Id);
        
        /*** Make Server Call to get Handler Details and Escalation Contacts ***/
        let Handlerescaction = component.get("c.getHandlerEscContactList");
        Handlerescaction.setParams({
            handlerIdList: handlerIdList
        });
        Handlerescaction.setCallback(this, function(response) {
            
            let returnValue = response.getReturnValue();
            component.set("v.handlerId", row.Id);
            component.set("v.HandlerDetails", returnValue[0].Handler);
            component.set(
                "v.EscalationContactList",
                returnValue[0].EscalationContact
            );
            component.set("v.isModalOpen", true);
            
        });
        $A.enqueueAction(Handlerescaction);
    },
    
    OpenSituationPopup:function(component,rowid)
    {
        let Handlerescaction = component.get("c.getassociatedSituations");
        Handlerescaction.setParams({
            HandlerID: rowid
        });
        Handlerescaction.setCallback(this, function(response) {
            
            let returnValue = response.getReturnValue();
            component.set("v.SituationDet",returnValue);
           component.set("v.isAssociatedSitOpen",true);
        });
        $A.enqueueAction(Handlerescaction);
        
    }
})