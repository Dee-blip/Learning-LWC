/** 
* History:
 * ==================================================================================================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
Sonali Tandon - 22/02/2016 - CR 3313721 - NAP -- Enhance Partner Onboarding form :: When Partner onboarding record is created/ opportunity on
                                         it is updated, stamp the partner onboarding on the corresponding opportunity.
**/
trigger PartnerOnboardingTrigger_ai_au on Partner_Onboarding__c (after insert, after update) {

    
    Map<Id,Id> mapOfOpptyIdWithPobId = new Map<Id,Id>();
    List<Id> listOfOldOpptysIds = new List<Id>();
    
    for(Partner_Onboarding__c pob : Trigger.new)
    {
        if(Trigger.isInsert && pob.Partner_Opportunity__c !=null)
        {
           mapOfOpptyIdWithPobId.put(pob.Partner_Opportunity__c,pob.Id);       
        }   
        if(Trigger.isUpdate && Trigger.oldMap.get(pob.Id).Partner_Opportunity__c!= pob.Partner_Opportunity__c)
         {
            mapOfOpptyIdWithPobId.put(pob.Partner_Opportunity__c,pob.Id);      
            listOfOldOpptysIds.add(Trigger.oldMap.get(pob.Id).Partner_Opportunity__c);
         }
    }
    
    System.debug('mapOfOpptyIdWithPobId' + mapOfOpptyIdWithPobId);
    System.debug('listOfOldOpptysIds' + listOfOldOpptysIds);

    if(mapOfOpptyIdWithPobId.size()>0)
        OpportunityTriggerClass.stampPartnerOnboardingOnOppty(mapOfOpptyIdWithPobId,listOfOldOpptysIds);
     
}