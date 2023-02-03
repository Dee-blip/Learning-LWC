({
    doInit : function(component, event, helper) 
    {
        let handlerId = component.get('v.recordId');
        let action = component.get('c.getHandlerEscalationContact');
        action.setParams({
            "handlerId":handlerId
        });
        action.setCallback(this,function(response){
            if(response.getState()==='SUCCESS')
            {
                component.set('v.handlerRec',response.getReturnValue());
                var serverreturn=response.getReturnValue();
                /*** Code Block to Selectively Show fields based on Handler Type ***/
                let fieldstoshow = serverreturn.Handler.Handler_Type__r.Fields_To_Show__c;
                let fieldstoshowarray = fieldstoshow.split(",");
                component.set('v.hasPendingInstruction',serverreturn.HasActiveInstruction);
                //Showing relevant sections based on the Handler Type
                 helper.showHideInstructions(component,fieldstoshowarray,serverreturn);
              
            }
        });
        $A.enqueueAction(action);
        
    }
})