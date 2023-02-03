({
    init : function(component, event, helper) {
        helper.fetchProducts(component);
    },
    
    back : function(component, event, helper) {
        window.location.href = '/' + component.get("v.recordId");
    },
    
    handleChange: function (component, event) {
        var selectedOptionValue = event.getParam("value");
        component.set("v.selectedvalues",selectedOptionValue);
    },
    
    saveAction : function(component, event, helper) {
        helper.saveProducts(component);
    },
})