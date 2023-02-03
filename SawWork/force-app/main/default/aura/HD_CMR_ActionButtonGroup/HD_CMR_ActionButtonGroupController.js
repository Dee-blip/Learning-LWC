({
    doInit : function(component, event, helper) {
        
    },
    
    myAction : function(component, event, helper) {
        
    },
    handleRefreshEvent : function(component, event, helper) {
        
    },
    performAction:function(component, event, helper){
        var action;
        try{
          action = event.currentTarget.id;
        }catch(Exception){
          action = event.detail.menuItem.get("v.value");
        }
        
     
        if(action=="Submit for Approval"){
          helper.submitForApproval(component, event, helper);
        }else if(action=="Clone"){
            helper.clone(component, event, helper);
        }else if(action=="Close"){
            helper.close(component, event, helper,'CLOSED');
        }else if(action=="Recall"){
           component.set("v.action","Recall");
           component.set("v.isOpen",true);
        }else if(action=="Cancel"){
             helper.cancel(component, event, helper);
        }else if(action=="InProgress"){
            helper.inProgress(component, event, helper);
        }else if(action=="Completed"){
            helper.completed(component, event, helper);
        }else if(action=="Change Failed"){
            helper.close(component, event, helper,'CHANGE FAILED');
        }        
    },
     hideCreatePIRForm: function(component,event,helper){ 
       component.set("v.renderCreateForm",false);
    }
})