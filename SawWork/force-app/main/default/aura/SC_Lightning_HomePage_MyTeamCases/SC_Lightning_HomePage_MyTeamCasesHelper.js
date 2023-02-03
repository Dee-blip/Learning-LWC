({
	 getMyTeamCases: function(component, event, helper) {
          var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getMyopenCases");
        action.setParams({
            "userID": userId,
            "QueryType":'MyTeamCases'
            
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var myopenlst=response.getReturnValue();
                component.set("v.OpenCase", myopenlst);
                component.set("v.OpenCount", myopenlst.length);
                  
            }
            
        });
        $A.enqueueAction(action);
		
	}
})