({
    getEscalationListDetails: function(component, event, helper) {
        let handlerId = [];
        handlerId.push(component.get('v.handlerRecId'));
        /*** First do a server Call and Get Escalation Id ***/
        let action = component.get("c.getHandlerEscContactList");
        action.setParams({
            "handlerIdList":handlerId
        });
        action.setCallback(this,function(response){
            console.log(response.getState());
            if(response.getState()==="SUCCESS")
            {
                console.log(response.getReturnValue());
                //component.set('v.SuggestedSituationInstructions',response.getReturnValue().Value__c);
            }
        });
        $A.enqueueAction(action);    
    },
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
    showFields:function(component, event, helper)
    {
        let handlerType = component.get("v.HandlerDetails").Handler_Type__r.Name;
        let fieldsToShow = component.get("v.fieldsToShowList");
        var fieldstoshowarray = '';
        for (var i = 0; i < fieldsToShow.length; i++){
            if (fieldsToShow[i].Name == handlerType){
                fieldstoshowarray = fieldsToShow[i].Fields_To_Show__c;
                break;
            }
        }
        if(typeof(fieldstoshowarray) != "undefined" && fieldstoshowarray.length > 0)
        { 
            fieldstoshowarray = fieldstoshowarray.split(",");
            if(fieldstoshowarray.includes("Ignore_Condition__c"))
            {
                component.set('v.showIgnoreCondition',true);
            }
            if(fieldstoshowarray.includes("Escalation_List__c"))
            {
                component.set('v.showEscalationList',true);
                var currPdId = component.get('v.pdId');
                var escalationListId = component.get('v.escalationContactId');
                var escalationContactEditSection = component.find("escalationContactEditSection");
                escalationContactEditSection.getEscConData(currPdId, escalationListId, false,false);
            }
        }
    },
});