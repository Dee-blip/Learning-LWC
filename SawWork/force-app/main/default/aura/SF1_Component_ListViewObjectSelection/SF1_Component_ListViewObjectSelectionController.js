({
	initialize : function(component, event, helper) 
    {
        
	   var action = component.get("c.getEnabledObjectsForListView");
       var self = this;
	   action.setCallback(this, function(response){
        if(component.isValid() && response.getState() == 'SUCCESS')
        {
        	
            var lvValue = response.getReturnValue();
            component.set("v.listViewObjects", lvValue);
        }
        });
		$A.enqueueAction(action);
    },
	changeSelection : function(component, event, helper) 
    {
		var selection = component.find("selection").get("v.value");
        if(selection == null)
        {
            selection = component.get("v.listViewObjects")[0];
        }
        component.set("v.selectedSObject", selection);
        var navigateEvent = $A.get("e.c:SF1_Event_NavigateToListView");
        navigateEvent.setParams({"selectedSObject": selection});
        navigateEvent.fire();  
   
    }

})