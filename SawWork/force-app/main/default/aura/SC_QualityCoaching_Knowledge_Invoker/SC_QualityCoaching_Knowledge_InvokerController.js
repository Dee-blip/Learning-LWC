({
    init : function(component, event, helper) {
        
        var qualityCoachingEvent = $A.get("e.c:SC_QualityCoaching_Event");
        qualityCoachingEvent.setParams({ 
            "sourceId": component.get("v.recordId"),
            "sourceType": "Knowledge",
            "parentType": "Knowledge"
        });
        qualityCoachingEvent.fire();
        
        //Close modal
        window.setTimeout( $A.getCallback(function() {
            $A.get("e.force:closeQuickAction").fire();
        }), 500 );
    }
})