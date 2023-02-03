({
	constructTree : function(component,action) {
		
                
        action.setCallback(this, function(response) {
            var categories = {}, results,parent;
            var state = response.getState();
            if(state == 'ERROR'){
                
                var errors = response.getError();
                HD_Error_Logger.createLogger(component, event, helper, errors[0].message, errors[0].message,false);
                return;
            }
            if(component.isValid() && response.getState() === "SUCCESS") {
                results = response.getReturnValue();
                if(results.length<1)
                {
                    component.find("textMessage").set("v.value","No such categories found.");
                }
                //categories[undefined] = { Name: "Root",Id: "Root",items: [] };
                categories["firstLevel"] = { Name: "Root",Id: "Root",items: [] };
                results.forEach(function(cat) {
                    categories[cat.Id] = { Name: cat.Name,Id: cat.Id, items: [] };
                });
                results.forEach(function(cat) {
                    if(cat.BMCServiceDesk__FKParentCategory__c)
                    {
                        parent = cat.BMCServiceDesk__FKParentCategory__c;
                    }
                    else
                    {
                        parent = "firstLevel";
                        
                    }
                    if(categories[parent]&&categories[parent].items)
                    {
                        categories[parent].items.push(categories[cat.Id]);
                    }
                    
                });
                component.set("v.nodes", categories["firstLevel"].items);
                
                //alert(categories["firstLevel"].items);
                //alert(component.get("v.nodes"));
            } else {
                alert(response.getError());
            }
        });
        $A.enqueueAction(action);
	}
})