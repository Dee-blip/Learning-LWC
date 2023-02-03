({
    showHideInstructions : function(component,fieldstoshowarray,serverreturn) 
    {
        if(fieldstoshowarray.includes("Escalation_List__c"))
        {
            component.set('v.showEscalationList','true');
            var pdId=serverreturn.Handler.Policy_Domain__c;
            var escalationListId=serverreturn.Handler.Escalation_List__c;
            var isEditPage=false;
            setTimeout(function(){ 
                var escalationContactEditSection = component.find("escalationContactEditSections");
            escalationContactEditSection.getEscConData(pdId, escalationListId,isEditPage,false);
            }, 500);
        }
        else
        {
            component.set('v.showEscalationList','false');
        }
        //Situation Instruction
        if(fieldstoshowarray.includes("Situation_Instruction__c"))
        {
            component.set('v.showSituationInstruction',true);
        }
        else
        {
            component.set('v.showSituationInstruction',false);
        }
        
        //Ignore Condition
        if(fieldstoshowarray.includes("Ignore_Condition__c"))
        {
            component.set('v.showIgnoreCondition',true);
        }
        else
        {
            component.set('v.showIgnoreCondition',false);
        }
        
        
        
    }
})