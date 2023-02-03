global class ClosePlanTriggerClass {
    public static void handleClosePlanOperation(Set<Id> associatedOpptyIds,Boolean valueToUpdate){
        List<Opportunity> opptys = [Select Id,Has_Close_Plan__c from Opportunity where Id in :associatedOpptyIds];
        List<Opportunity> opptysToUpdate = new List<Opportunity>();
        if(opptys.size() > 0) {
            for(Opportunity opp : opptys) {
                opp.Has_Close_Plan__c  = valueToUpdate;
                opptysToUpdate.add(opp);
            }
        }
        if(opptysToUpdate.size() > 0) {
            update opptysToUpdate;
        }
    }
}