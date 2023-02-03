({ //Returns the object options got from getSFDCObject method of the class
    /*
    getData : function(component, event, helper) {
         this.toggle(component, event);
        var action = component.get('c.Calc_SC_KCS_Scorecard_Details');
        action.setParams({
            "recordId":component.get("v.recordId").toString()
        });
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set('v.Scorecard_obj', response.getReturnValue().KCS_Scorecard);
                component.set('v.Scorecard_Criteria_List', response.getReturnValue().KCS_Scorecard_Criteria);
                  component.set('v.User_Authorized', (response.getReturnValue().Is_User_Authorized && response.getReturnValue().Published) );
                
                this.toggle(component, event);
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
    ,
    */
    
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
    
    display_error1: function (component, event, helper) {
        var error_message='You are not logged in as a KCS Coach or KCS KDE or Tech Support Manager';
        var error_title='Uh-oh, Insufficient Authorization 😥';
        var duration_in_ms='10000';
        helper.showToastMessage(component,event,helper,error_title,error_message, 'error','dismissible',duration_in_ms);
  }
,
    
        display_error2: function (component, event, helper) {
        var error_message='Article must be in published state to create a scorecard';
        var error_title='Uh-oh, Article is in Draft/Archive State😥';
        var duration_in_ms='10000';
        helper.showToastMessage(component,event,helper,error_title,error_message, 'error','dismissible',duration_in_ms);
  }
    
    ,
    toggle: function (component, event) {
    
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },

    //Close Quality Coaching Utility method
    closeUtilityItem : function(component, event){
        var utilityAPI = component.find("utilitybar");
        utilityAPI.getAllUtilityInfo().then(function(response) {
            for(var eachUtilityItem of response){
                if(eachUtilityItem.utilityLabel == "Quality Coaching" && eachUtilityItem.utilityVisible){
                    utilityAPI.minimizeUtility({utilityId: eachUtilityItem.id});
                    break;
                }
            }
       })
        .catch(function(error) {
            console.log(error);
        });
    }    
    
})