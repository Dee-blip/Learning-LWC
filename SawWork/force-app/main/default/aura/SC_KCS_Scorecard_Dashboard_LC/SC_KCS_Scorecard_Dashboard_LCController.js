({

    //initialization method
    /*
    init: function (component, event, helper) {
        helper.getData(component, event, helper);
        
  }, */
    //Method called from Utility bar to initialize and load data
    getData : function(component, event, helper) {
        helper.toggle(component, event);
        var params = event.getParam('arguments');
        if (params) {
            var sourceId = params.sourceId;
            var sourceType = params.sourceType;
            var parentType = params.parentType;
            component.set("v.sourceId", sourceId);
            component.set("v.sourceType", sourceType);
            component.set("v.parentType", parentType);
        
            //calling apex controller
            var action = component.get('c.Calc_SC_KCS_Scorecard_Details');
            action.setParams({
                "sourceId" : sourceId,
                "sourceType" : sourceType,
                "parentType" : parentType
            });
            action.setCallback(this, $A.getCallback(function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.Scorecard_obj', response.getReturnValue().KCS_Scorecard);
                    component.set('v.Scorecard_Criteria_List', response.getReturnValue().KCS_Scorecard_Criteria);
                      component.set('v.User_Authorized', (response.getReturnValue().Is_User_Authorized && response.getReturnValue().Published) );
                    
                    helper.toggle(component, event);
                    if(response.getReturnValue().Is_User_Authorized.toString() =='false'){
                        helper.display_error1(component, event, helper);
                        $A.get("e.force:closeQuickAction").fire();
                        return;
                    } 
                     if(response.getReturnValue().Published.toString() =='false'){
                        helper.display_error2(component, event, helper);
                        $A.get("e.force:closeQuickAction").fire();
                        return;
                    }
                    for(var index=0;index<component.get("v.Scorecard_Criteria_List").length;index++){
                        if(component.get("v.Scorecard_Criteria_List")[index].Response__c.toString()=='')
                        {
                            component.set("v.Is_save_button_disabled",true);
                            return;
                        }
                    }
                    component.set("v.Is_save_button_disabled",false);
                    
                } 
                else if (state === "ERROR") {
                     this.toggle(component, event);
                    var errors = response.getError();
                    alert('error');
                    
                    
                }
            }));
            $A.enqueueAction(action);
        }
    },

  //Method 1 to handle response change
    uncheckgood: function(component,event,handler){
        var row_number = event.target.id;        
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Response__c", "");
            }
        }
        for(var index=0;index<component.get("v.Scorecard_Criteria_List").length;index++){
            if(component.get("v.Scorecard_Criteria_List")[index].Response__c.toString()=='')
            {
                component.set("v.Is_save_button_disabled",true);
                return;
            }
        }
    },
    //Method 2 to handle response change
    checkgood: function(component,event,handler){
        var row_number = event.target.id;
       
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Response__c", "Good");
            }
        }
        for(var index=0;index<component.get("v.Scorecard_Criteria_List").length;index++){
            if(component.get("v.Scorecard_Criteria_List")[index].Response__c.toString()=='')
            {
                component.set("v.Is_save_button_disabled",true);
                return;
            }
        }
        component.set("v.Is_save_button_disabled",false);
    },
    //Method 3 to handle response change
    uncheckbad: function(component,event,handler){
        var row_number = event.target.id;
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Response__c", "");
            }
        }
        for(var index=0;index<component.get("v.Scorecard_Criteria_List").length;index++){
            if(component.get("v.Scorecard_Criteria_List")[index].Response__c.toString()=='')
            {
                component.set("v.Is_save_button_disabled",true);
                return;
            }
        }
    },
    //Method 4 to handle response change
    checkbad: function(component,event,handler){
        var row_number = event.target.id;
       
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Response__c", "Need Fix");
            }
        }
        for(var index=0;index<component.get("v.Scorecard_Criteria_List").length;index++){
            if(component.get("v.Scorecard_Criteria_List")[index].Response__c.toString()=='')
            {
                component.set("v.Is_save_button_disabled",true);
                return;
            }
        }
        component.set("v.Is_save_button_disabled",false);
    },
    

    //Method 1 to handle 'fixed' field change
    uncheckFixed: function(component,event,handler){
        var row_number = event.target.id;
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Fixed__c",false);
            }
        }
    },
    //Method 2 to handle 'fixed' field change
    checkFixed: function(component,event,handler){
        var row_number = event.target.id;
        for(var index= 0;index< component.get("v.Scorecard_Criteria_List").length ;index++){
            if(component.get("v.Scorecard_Criteria_List["+index+"].Criteria_Number__c").toString() == row_number.toString())
            {
                component.set("v.Scorecard_Criteria_List["+index+"].Fixed__c",true);
            }
        }
    },


    //Method to Save scorecard
    Save_Scorecard : function(component, event, helper) {
        if($A.util.isUndefinedOrNull(component.get("v.Scorecard_obj").Notes__c)){
            helper.showToastMessage(component, event, helper,'Saving error','Please fill notes.','error','dismissible', duration_in_ms );
        }else{
          var duration_in_ms='5000';
        component.set("v.Dynamic_button_label",'Saving...');
                
        
        var action = component.get('c.Update_KCS_Scorecard_Details');
        action.setParams({ "Criteria_Data" : JSON.stringify(component.get("v.Scorecard_Criteria_List")),
                          "Notes": component.get("v.Scorecard_obj").Notes__c,
                          "sourceId": component.get("v.sourceId"),
                          "sourceType": component.get("v.sourceType"),
                          "parentType": component.get("v.parentType")
                         });
        
        action.setCallback(this, $A.getCallback(function (response) {
          
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Dynamic_button_label",'Save');
                $A.get("e.force:closeQuickAction").fire();
                helper.showToastMessage(component, event, helper,'Saved','Thank you for the rating. Hungry for more? 👨‍🍳‍ Go to Akapedia','success','dismissible', duration_in_ms );
                $A.get('e.force:refreshView').fire();   
                helper.closeUtilityItem(component, event);
            } 
            else if (state === "ERROR") {
                var errors = response.getError();
                alert("Error"+ JSON.stringify(response.getError()[0].pageErrors[0].message.toString()));
                //helper.showToastMessage(component, event, helper,'Saving error',response.getError()[0].pageErrors[0].message.toString(),'error','dismissible', duration_in_ms );
            }
        }));
        $A.enqueueAction(action);
    }
    }
    
    
    
    
})