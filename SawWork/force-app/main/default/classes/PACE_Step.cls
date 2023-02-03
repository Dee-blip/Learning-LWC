public class PACE_Step {

    
    public static PACE_Step__c initialize(PACE_Phase__c phase, String name, Integer position){
        
        PACE_Step__c step = new PACE_Step__c();
        step.Name = name;
        step.Phase__c = phase.Id;
        step.Position__c = position;
        
        return step;
        
    }
    
    /*    public static PACE_Step__c initialize(PACE_Concept__c concept, String name, Integer position){
        
        PACE_Step__c step = new PACE_Step__c();
        step.Name = name;
        step.Concept__c = concept.Id;
        step.Position__c = position;
        
        return step;
        
    }*/
    
    
}