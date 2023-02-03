({
	handleApplicationEvent : function(component, event, helper) {
        //get parameters from event
        var sourceId = event.getParam("sourceId");
        var sourceType = event.getParam("sourceType");
        var parentType = event.getParam("parentType");
        
        
        //Find the required utility item and open it
        var utilityAPI = component.find("utilitybar");
        utilityAPI.getAllUtilityInfo().then(function(response) {
            for(var eachUtilityItem of response){
                if(eachUtilityItem.utilityLabel == "Quality Coaching" && !eachUtilityItem.utilityVisible){
                    utilityAPI.openUtility({utilityId: eachUtilityItem.id});
                    break;
                }
            }
            
            //calling child components method
            if(parentType == "Case"){
                component.set("v.isCase", true);
                component.set("v.isEscalation", false);
                component.set("v.isTransition", false);
                component.set("v.isKnowledge", false);
                component.set("v.isDefault", false);
                component.set("v.isRCA", false);  
                var caseComponent = component.find("case");
                // call the aura:method in the child component
                caseComponent.getData(sourceId, sourceType, parentType);
            }
            else if(parentType == "Escalation"){
                component.set("v.isCase", false);
                component.set("v.isEscalation", true);
                component.set("v.isTransition", false);
                component.set("v.isKnowledge", false);
                component.set("v.isDefault", false);
                component.set("v.isRCA", false);  
                var escalation = component.find("escalation");
                // call the aura:method in the child component
                escalation.getData(sourceId, sourceType, parentType);
            }
            else if(parentType == "Transition"){
                component.set("v.isCase", false);
                component.set("v.isEscalation", false);
                component.set("v.isTransition", true);
                component.set("v.isKnowledge", false);
                component.set("v.isDefault", false);
                component.set("v.isRCA", false);  
                var transition = component.find("transition");
                // call the aura:method in the child component
                transition.getData(sourceId, sourceType, parentType);
            }
            else if(parentType == "Knowledge"){
                component.set("v.isCase", false);
                component.set("v.isEscalation", false);
                component.set("v.isTransition", false);
                component.set("v.isKnowledge", true);
                component.set("v.isDefault", false);
                component.set("v.isRCA", false);  
                var knowledge = component.find("knowledge");
                // call the aura:method in the child component
                knowledge.getData(sourceId, sourceType, parentType);
            } else if(parentType == "RCA" ){
                component.set("v.isCase", false);
                component.set("v.isRCA", true);
                component.set("v.isEscalation", false);
                component.set("v.isTransition", false);
                component.set("v.isKnowledge", false);
                component.set("v.isDefault", false);
                var rca = component.find("rca");
                // call the aura:method in the child component
                rca.getData(sourceId, sourceType, parentType);
            }
            else{
            	component.set("v.isCase", false);
                component.set("v.isEscalation", false);
                component.set("v.isTransition", false);
                component.set("v.isKnowledge", false);
                component.set("v.isDefault", true);  
                component.set("v.isRCA", false);   
            }
       })
        .catch(function(error) {
            console.log(error);
        });
        
        
    }
})