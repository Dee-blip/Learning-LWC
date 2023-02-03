({
    init: function(component, event, helper) {
        var action = component.get("c.getCategories");
		helper.constructTree(component,action);
    },
    onSearchCat: function(component, event, helper){
        var searchValue = component.find("catSearch").get("v.value"); 
        if(searchValue == null){
            return
        }else{
            searchValue.trim();
        }
            
        
		component.set("v.searchCategory",searchValue);
        
        var action;
        if(component.get("v.searchCategory"))
        {
            action = component.get("c.searchCategories");
            action.setParams({
                    searchText : component.get("v.searchCategory")
    
                }); 
        helper.constructTree(component,action);
            component.set("v.expandAll","true");
        }
        else
        {
            action = component.get("c.getCategories");
            helper.constructTree(component,action);
        }
    },
     onClear: function(component, event, helper) {
        component.set("v.searchCategory",null);
        component.set("v.expandAll","false");
        component.find("catSearch").set("v.value","")
        var action = component.get("c.getCategories");
		helper.constructTree(component,action);
    }
})