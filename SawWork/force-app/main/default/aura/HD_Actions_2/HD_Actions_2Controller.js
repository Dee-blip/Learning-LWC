({
    myAction : function(component, event, helper) {
        
        
        var buttonKey=  event.currentTarget.dataset.key;
        var cmp=component.find(buttonKey);
        helper.collapseAll(component,buttonKey);
        if($A.util.hasClass(cmp,"slds-is-collapsed")){
            $A.util.swapClass(cmp, "slds-is-collapsed","slds-is-expanded");
            component.set("v.startTime",new Date());
            component.set("v.actionName",buttonKey);
           	
        } else {
            $A.util.swapClass(cmp, "slds-is-expanded","slds-is-collapsed");  
            
            
        }
    },
    actionManagerRules : function(component, event, helper){
       
        helper.getisAccessibleHelper(component, event, helper);
        helper.getIncidentDetailhelper(component, event, helper);
        helper.actionManagerHelper(component, event, helper);
        
    }
    
    
})