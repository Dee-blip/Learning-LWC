({
    init : function(component, event, helper) {
        //check for pending instructions on this PD
        let action = component.get("c.checkPendingInstructionForPD");
        action.setParams({
            "pdId": component.get("v.recordId")
        });

        action.setCallback(this, function(response){
            let state = response.getState();
            if(state === "ERROR"){
                var errors = response.getError();
                helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
                $A.get("e.force:closeQuickAction").fire();
            }
            else if(state !== "SUCCESS"){
                helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },

    
    handleSubmit : function(component, event, helper) {
        let suggestedInstruction = component.get("v.suggestedInstruction");
        
        //field validations
        if(!suggestedInstruction)
            helper.showToastMessage(component, event, helper,'Error: Please provide an input!',' ','Error','dismissible', 5000);
        else if(suggestedInstruction.length > 32767)
            helper.showToastMessage(component, event, helper,'Error: Max input length is 32767!',' ','Error','dismissible', 5000);
        else{
            //show spinner
            helper.toggle(component, event);

            let action = component.get("c.submitInstructionForPD");
            action.setParams({
                "pdId": component.get("v.recordId"),
                "suggestedInstruction": suggestedInstruction
            });

            action.setCallback(this, function(response){
                let state = response.getState();
                if(state === "SUCCESS"){
                    helper.showToastMessage(component, event, helper,'Instruction submitted for approval succesfully!',' ','success','dismissible', 5000);
                    $A.get("e.force:closeQuickAction").fire();
                    helper.toggle(component, event);
                    $A.get('e.force:refreshView').fire();
                }
                else if(state === "ERROR"){
                    var errors = response.getError();
                    helper.showToastMessage(component, event, helper,'Error',errors[0].message,'Error','dismissible', 5000);
                    helper.toggle(component, event);
                }
                else{
                    helper.showToastMessage(component, event, helper,'Error','Darn it! Something went wrong! Please try again or contact your System Administrator!','Error','dismissible', 5000);
                    helper.toggle(component, event);
                }
            });
            $A.enqueueAction(action);
        }
    },

    //close the modal
    handleClose : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }
})