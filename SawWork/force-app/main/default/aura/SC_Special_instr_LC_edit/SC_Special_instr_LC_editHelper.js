({
	//Displays Toast Message    
    showToastMessage : function(component, event, helper,p_title,p_message,p_type,p_mode,duration_in_ms) {
        
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : p_title,
            message: p_message,
            messageTemplate: 'Saved!',
            duration:duration_in_ms,
            key: 'info_alt',
            type: p_type,
            mode: p_mode
        });
        toastEvent.fire();
    },
    //Refreshes the tab after saving
    refreshFocusedTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.parentTabId;
            workspaceAPI.refreshTab({
                tabId: focusedTabId,
                includeAllSubtabs: true
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    }
    ,
   //Calculates if SI with template or SI without Template. Also retrieve the Special Instruction template list.
    initialize_data: function (component, event, helper) {
        
        this.start_spinner_helper(component, event, helper);
        var action = component.get('c.get_Special_Instruction_Template_List');
        var Is_SI_With_Template;
        action.setCallback(this, $A.getCallback(function (response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Special_Instruction_Template_List",response.getReturnValue());
                
                
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error"+ JSON.stringify(response.getError().toString()));
            } 
        }));
        $A.enqueueAction(action);  
        
        
        
        action = component.get('c.get_SI_Template_details');
        action.setParams({
            "SI_Id":component.get("v.recordId"),
            
        });
        action.setCallback(this, $A.getCallback(function (response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
                
                if(response.getReturnValue()[0].Name.toString() == 'NA'){
                    
                    component.set("v.Is_Special_Instructions_With_Templates_Open", false);
                    component.set("v.Is_Special_Instructions_Without_Templates_Open", true);
                    component.set("v.Is_Save_For_Special_Instructions_Without_Template_disabled", false);
                    
                }
                
                else {
                    component.set("v.Special_Instruction_Template_Id",response.getReturnValue()[0].Id.toString());
                    component.set("v.default_SIT_Template", response.getReturnValue()[0].Name);
                    
                    component.set("v.Is_Special_Instructions_With_Templates_Open", true);
                    component.set("v.Is_Special_Instructions_Without_Templates_Open", false);
                    component.set("v.Is_Save_For_Special_Instructions_With_Template_disabled", false);
                    
                    
                }
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error"+ JSON.stringify(response.getError().toString()));
            }
        }));
        $A.enqueueAction(action);  
        
    }
    ,
    //Stops spinner
    stop_spinner_helper: function(component, event, helper) {
        component.set("v.Is_Loading", false);
    }
     
    ,
    //Start spinner
    start_spinner_helper: function(component, event, helper) {
        component.set("v.Is_Loading", true);
    },

    get_Flag_Image_details: function(component, event, helper){
        var action = component.get('c.getLogoUrl');
        action.setParams({
            "SIT_Template":component.find("SIT_Template").get("v.value"),
            
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            
            var state = response.getState();
            if (state === "SUCCESS") { 
                component.set("v.Flag_Url",response.getReturnValue().toString());
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error"+ JSON.stringify(response.getError().toString()));
            }
        }));
        $A.enqueueAction(action);   
        this.stop_spinner_helper(component, event, helper);
    }
    ,
    
    //Display The new SI Template values on Change of selected Template
    handle_Special_Instruction_Template_Change_helper: function(component, event, helper) {
        
        var Selected_Special_Instruction_Template = component.find("SIT_Template").get("v.value");
        var Special_Instruction_Template_List =component.get("v.Special_Instruction_Template_List");
        
        
        for(var index=0;index<Special_Instruction_Template_List.length;index++)
        {
            if(Selected_Special_Instruction_Template==Special_Instruction_Template_List[index].Name)
            {          
                component.set("v.default_SIT_Template", Special_Instruction_Template_List[index].Name);
                
                component.set("v.Special_Instruction_Template_Id", Special_Instruction_Template_List[index].Id);
                
            }
        }
        
    }
    ,
    //Save SI with Template
    Save_Special_Instruction_With_Template_helper: function(component, event, helper) {
       this.start_spinner_helper(component, event, helper);
        
        var Special_Instruction_Template_Selected=component.find("SIT_Template").get("v.value").toString();
        var Special_Instruction_Template_List =component.get("v.Special_Instruction_Template_List");
        var Special_Instruction_Template_Selected_Id;    
        var Toast_Display_Duration_In_Millisecons='5000';
        
        for(var index=0;index<Special_Instruction_Template_List.length;index++)
        {
            if(Special_Instruction_Template_Selected==Special_Instruction_Template_List[index].Name)
            {         Special_Instruction_Template_Selected_Id= Special_Instruction_Template_List[index].Id;
             
            }
        }
        
        
        var action = component.get('c.Update_Special_Instruction_With_Template');
        action.setParams({
            "StartDate":component.find("SIT_Start_Date").get("v.value"),
            "ExpirationDate":component.find("SIT_Expiration_Date").get("v.value"),
            "SIT_Id":Special_Instruction_Template_Selected_Id,
            "Account_Id":component.find("SIT_Account").get("v.value").toString(),
            "SI_Id":component.get("v.recordId")
            
        });
        action.setCallback(this, $A.getCallback(function (response) {
            if (response.getReturnValue().toString() == "Success") {
                
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
                
                this.refreshFocusedTab(component, event, helper);  
                this.stop_spinner_helper(component, event, helper);
                this.showToastMessage(component, event, helper,'Saved','Special Instruction with Template Saved.','success','dismissible', Toast_Display_Duration_In_Millisecons );
                
                
            } 
            else  {
                this.stop_spinner_helper(component, event, helper);
                console.log(response.getError());
                this.showToastMessage(component, event, helper,'Error',response.getReturnValue().toString(),'error','dismissible', Toast_Display_Duration_In_Millisecons );
                
                
            }
        }));
        $A.enqueueAction(action);
        
    }
    ,
    //Save SI without Template
    Save_Special_Instruction_WithOut_Template_helper: function(component, event, helper) {
       
        this.start_spinner_helper(component, event, helper);
        var Toast_Display_Duration_In_Millisecons='5000';
        var action = component.get('c.Update_Special_Instruction_WithOut_Template');
        action.setParams({
            "AccountId":component.find("SI_Account").get("v.value").toString(),
            "StartDate":component.find("SI_Start_Date").get("v.value"),
            "ExpirationDate":component.find("SI_Expiration_Date").get("v.value"),
            "Title":component.find("SI_Title").get("v.value"),
            "Instructions":component.find("SI_Instructions").get("v.value"),
            "SRT":component.find("SI_SRT").get("v.value"),
            "SI_Id":component.get("v.recordId")
        });
        action.setCallback(this, $A.getCallback(function (response) {
            
            if (response.getReturnValue().toString() == "Success") {
                
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
                
                this.refreshFocusedTab(component, event, helper);  
                this.stop_spinner_helper(component, event, helper);
                
                
                this.showToastMessage(component, event, helper,'Saved','Special Instruction Saved.','success','dismissible', Toast_Display_Duration_In_Millisecons );
            } 
            else {
                
                var errors = response.getError();
                this.stop_spinner_helper(component, event, helper);
                
                this.showToastMessage(component, event, helper,'Error',response.getReturnValue().toString(),'error','dismissible', Toast_Display_Duration_In_Millisecons );
                
            }
        }));
        $A.enqueueAction(action);
        
    }
    ,
    //Checks if Save must be Disabled
    save_Disable_Check_For_Special_Instruction_Without_Template_helper: function(component, event, helper) {
        
        if(component.find("SI_Account").get("v.value") != null 
           && component.find("SI_Start_Date").get("v.value") != null 
           && component.find("SI_Title").get("v.value") != null && component.find("SI_Title").get("v.value") != '' 
           && component.find("SI_Instructions").get("v.value")!= null && component.find("SI_Instructions").get("v.value")!= ''
           && component.find("SI_SRT").get("v.value")!= null && component.find("SI_SRT").get("v.value")!= '')
        {
            component.set("v.Is_Save_For_Special_Instructions_Without_Template_disabled", false);
            
        }
        else
        {
            component.set("v.Is_Save_For_Special_Instructions_Without_Template_disabled", true);
        }
        
        
    }
    ,
    //Checks if Save must be Disabled
    save_Disable_Check_For_Special_Instruction_With_Template_helper: function(component, event, helper) {
        
        
        if(component.find("SIT_Start_Date").get("v.value") != null &&
           component.find("SIT_Account").get("v.value")!= null )
        {
            component.set("v.Is_Save_For_Special_Instructions_With_Template_disabled", false);
            
        }
        else
        {
            component.set("v.Is_Save_For_Special_Instructions_With_Template_disabled", true);
        }
        
    }
})