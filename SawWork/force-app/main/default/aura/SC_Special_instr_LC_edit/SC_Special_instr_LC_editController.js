({
    //Calculates if SI with template or SI without Template    
    init: function (component, event, helper) {
        helper.initialize_data(component, event, helper);
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
    }
    ,
    
    //Calculate flag url
    Flag_calc: function(component, event, helper) {
        helper.get_Flag_Image_details(component, event, helper);
    }
    
})