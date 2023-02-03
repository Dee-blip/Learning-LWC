({
    renderComponent : function(component, event, helper) {
        var componentName = component.get("v.componentName");
        var componentParameter = component.get("v.componentParameter");
        
        if(componentName != null)
        {
            helper.componentGenerator(component,componentName,componentParameter);
            //console.log('>>>'+componentName);
            //console.log('>>>'+componentParameter);
        }
        else
        {
            console.log('>>> NO COMPONENT NAME FOUND'); 
            
        }
        
    }
})