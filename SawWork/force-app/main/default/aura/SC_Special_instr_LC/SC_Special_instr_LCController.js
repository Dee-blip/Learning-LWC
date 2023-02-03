({
    init: function (component, event, helper) {
   var action = component.get('c.get_Special_Instruction_Template_List');
            action.setCallback(this, $A.getCallback(function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.Special_Instruction_Template_List",response.getReturnValue());
                    component.set("v.Special_Instruction_Template_Id", response.getReturnValue()[0].Id);
                } 
                else if (state === "ERROR") {
                    var errors = response.getError();
                    alert("Error"+ JSON.stringify(response.getError().toString()));
                }
            }));
            $A.enqueueAction(action);      
    }
    ,
    
    //Calculates if SI with template or SI without Template
    Dynamic_Special_Instruction_Creation_Page: function(component, event, helper) {
        helper.Dynamic_Special_Instruction_Creation_Page_helper(component, event, helper);
       }
    ,
    //Stops spinner
    stop_spinner: function(component, event, helper) {
        helper.stop_spinner_helper(component, event, helper);
    }
    
    ,
    //Start spinner
    start_spinner: function(component, event, helper) {
        helper.start_spinner_helper(component, event, helper);
    }
    ,
    //Display The new SI Template values on Change of selected Template
    handle_Special_Instruction_Template_Change: function(component, event, helper) {
        helper.handle_Special_Instruction_Template_Change_helper(component, event, helper);
        helper.get_Flag_Image_details(component, event, helper);
        
    }
    ,
    //Save SI with Template
    Save_Special_Instruction_With_Template: function(component, event, helper) {
        helper.Save_Special_Instruction_With_Template_helper(component, event, helper);
    }
    ,
    //Save SI without Template
    Save_Special_Instruction_WithOut_Template: function(component, event, helper) {
        helper.Save_Special_Instruction_WithOut_Template_helper(component, event, helper);
    }
    ,
    //Checks if Save must be Disabled
    save_Disable_Check_For_Special_Instruction_Without_Template: function(component, event, helper) {
        helper.save_Disable_Check_For_Special_Instruction_Without_Template_helper(component, event, helper);
    }
    ,
    //Checks if Save must be Disabled
    save_Disable_Check_For_Special_Instruction_With_Template: function(component, event, helper) {
        helper.save_Disable_Check_For_Special_Instruction_With_Template_helper(component, event, helper);
    },
    
    //Calculate flag url
    Flag_calc: function(component, event, helper) {
        helper.get_Flag_Image_details(component, event, helper);
        
    }
    
    
    
})