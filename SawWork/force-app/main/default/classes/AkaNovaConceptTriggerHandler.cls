public class AkaNovaConceptTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public AkaNovaConceptTriggerHandler(){
        
    }
    public override void beforeInsertBeforeUpdateTrigger(){
    }
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    public override void afterInsertAfterUpdateTrigger(){
        System.debug('Inside the after triger concept'); 
        // map concept to team members
        Map<Id, Set<String>> conceptToTeamMembers = new Map<Id, Set<String>>();
        List<Concept__c> concepts = new List<Concept__c>();
        List<Concept__c> conceptsStatusUpdate = new List<Concept__c>();
        for(SObject so: newList){
			Concept__c conceptObj = (Concept__c)so;
            Concept__c oldConceptObj = null;
            /*if(conceptObj.Team_Members__c != null) {
                //Set<String> teammembers = new Set<String>(conceptObj.Team_Members__c.split(','));
                conceptToTeamMembers.put(conceptObj.Id, new Set<String>(conceptObj.Team_Members__c.split(',')));
            }*/
            concepts.add(conceptObj);
            if(Trigger.isInsert){
            }
            else if(Trigger.isUpdate){
            }
        }
        if(Trigger.isInsert){
            // create records for Concept Owner
             AkaNovaConceptTriggerClass.createConceptTeamOwner(concepts);
            // create records for concept memebers
            /*if (conceptToTeamMembers.size() > 0) {
                AkaNovaConceptTriggerClass.createConceptTeamMembers(conceptToTeamMembers);
            }*/
            // Create records for reviewers only on insert
            AkaNovaConceptTriggerClass.createReviewerRecords(concepts);
        }
    }
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}