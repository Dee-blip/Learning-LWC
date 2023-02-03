({
    toggle: function(component, event, helper) {
        component.set("v.expanded", !component.get("v.expanded"));
       
    },
    
    selectCategory: function(component, event, helper) {
        var selEvent = $A.get("e.c:HD_SelectCategory");
		selEvent.setParams({ "categoryId" : component.get("v.node").Id ,
                            "categoryName" : component.get("v.node").Name });
		selEvent.fire();
        
    }
})