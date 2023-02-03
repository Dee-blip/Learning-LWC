({

    //initialization method
    init: function (component, event, helper) {
        var action = component.get('c.getParentType');
        action.setParams({
            "sourceId": component.get("v.recordId")
        });
        
        action.setCallback(this, $A.getCallback(function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var parentType = response.getReturnValue();
                if(parentType != "Not Found"){
                    var qualityCoachingEvent = $A.get("e.c:SC_QualityCoaching_Event");
                    qualityCoachingEvent.setParams({ 
                        "sourceId": component.get("v.recordId"),
                        "sourceType": "Quality Coaching",
                        "parentType": parentType
                    });
                    qualityCoachingEvent.fire();
                    
                    //Close modal
                    $A.get("e.force:closeQuickAction").fire();
                }
                else{
                    alert('Error: Record Type not found!');
                }
            }
        }));
        $A.enqueueAction(action);
          
  }
})