/* ========================================================================
    Author: Sonia Sawhney
    Description: Used to set the category for the Ideas
    Created Date : 26/06/2014
    Modifications:
    1. ssawhney on 16/12/2014 - CR 2869635 - Added logic for Idea Number generation for Wizards, Removed logic for marking categories
    2. janantha on 30/12/2014 - CR 2869698 - Added code to populate the reviewer(Project owner) and send an email on category change.
    3. Nagdeep CR 2869707 - Populate the Search tag
    4. Laxmi CR - Adding team Members
    5. janantha on 03/11/2015 - CR 3197171 - Sending notifications to Sponsor on changes to Sponsor section.
    ======================================================================== */
   trigger WizardsIdeaTrigger on Idea (before insert, before update, after insert, after update) {
   
    /*Added by janantha */
    if(Trigger.isAfter && Trigger.isUpdate)
    {
        WizardsIdeaTriggerClass triggerClass = new WizardsIdeaTriggerClass();                   
        triggerClass.emailOnCatChange(trigger.newMap,trigger.oldMap); 
        
        //Added by janantha on 2nd nov 2015
        triggerClass.sponsorAssignedEmail(trigger.new, trigger.oldMap);
       
        //For hisotry Tracking
        WizardsIdeaHistory historyTrigger = new WizardsIdeaHistory(trigger.new,trigger.oldMap);
        historyTrigger.storeHistory();
    }  
    
    if(Trigger.isBefore)
    {       
        WizardsIdeaTriggerClass triggerClass = new WizardsIdeaTriggerClass();  
        triggerClass.GenerateIdeaNumber(Trigger.new);
        triggerClass.SearchTagBuilder(Trigger.new);
        if(Trigger.isUpdate)
        {              
            triggerClass.createRemoveMembers(trigger.new,trigger.oldMap);
            // logic to update reviewer name based on changes done in category and subcatgegory.
            List<Idea> newUpdatedIdeas = new List<Idea>();
            Map<Id,Idea> newIdeasMap = new Map<Id,Idea>();
            Map<Id,Idea> oldIdeasMap = new Map<Id,Idea>();
            newIdeasMap = trigger.newMap;
            oldIdeasMap = trigger.oldMap;
            for(Idea ideaObj:newIdeasMap.values()){
                Idea oldIdea = oldIdeasMap.get(ideaObj.Id);
                Idea newIdea = newIdeasMap.get(ideaObj.Id);
                if(Util.hasChanges('Project_Type__c', oldIdea,newIdea) && Util.hasChanges('Idea_Sub_Category__c',oldIdea,newIdea)){
                    newUpdatedIdeas.add(newIdea);
                }
                if(newUpdatedIdeas.size()>0){
                    triggerClass.populateProjectOwner(newUpdatedIdeas);
                }
            }
            //checks if idea number is valid (when saved idea from 2017 is submitted in 2018, idea number has to change to change to 2018)
            triggerClass.validateIdeaNumber(trigger.new, Trigger.oldMap);
        }
        if(Trigger.isInsert)
        {
            triggerClass.populateProjectOwner(trigger.new);
        } 
    }
    if(Trigger.isAfter && Trigger.isInsert){
       WizardsIdeaTriggerClass triggerClass = new WizardsIdeaTriggerClass();  
       triggerClass.createRemoveMembers(trigger.new,trigger.oldMap);
       //triggerClass.createVoteAfterInsert(trigger.new);
    } 
}