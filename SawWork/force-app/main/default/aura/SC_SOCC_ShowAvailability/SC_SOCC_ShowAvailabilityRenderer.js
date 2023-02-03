({
    
    // Your renderer method overrides go here
    render: function(component, helper) {
        let currentUserTimeZone = $A.get("$Locale.timezone");
        component.set("v.currentUserTimeZone", currentUserTimeZone);
        
        return this.superRender();
    }
    
})