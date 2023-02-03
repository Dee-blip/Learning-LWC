({
    //Method 1: Called on load of the component and create and AD with RT based on case RT
    assignDefaultValues : function(component, event, helper) 
    {
        if(component.get('v.action')=='Case Page'){
        	helper.updateForNewButton(component,event,helper);
        } else if(component.get('v.action')==''){
            helper.cloneMethod(component,event,helper);
        }
    }
    
    
})