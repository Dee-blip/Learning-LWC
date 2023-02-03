public without sharing class CampaignTriggerHandler extends ApexTriggerHandlerAbstractClass {

    public override void beforeInsertBeforeUpdateTrigger(){
        List<Campaign> campaignTriggerNew = (List<Campaign>)newList;
        Map<Id,Campaign> campaignTriggerOldMap = (Map<Id,Campaign>)oldMap;
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, campaignTriggerNew);

        List<Campaign> campaignGroupPopulationList = new List<Campaign>();
        //Set<String> campaignRecordTypeIds = GSMSettings.getSetOfStrings('CampaignRecordTypeIdsForGroupPopulation');

        for(Campaign campaign : campaignTriggerNew)
        {
            if((Trigger.isUpdate && campaign.Type!= campaignTriggerOldMap.get(campaign.Id).Type) || (Trigger.isInsert && campaign.Type!=null))
            {
                campaignGroupPopulationList.add(campaign);
            }
        }

        if(campaignGroupPopulationList.size()>0)
            CampaignTriggerClass.populateCampaignGroup(campaignGroupPopulationList);

    }

    public override void afterInsertAfterUpdateTrigger(){
        List<Campaign> campaignTriggerNew = (List<Campaign>)newList;
        Map<Id,Campaign> campaignTriggerOldMap = (Map<Id,Campaign>)oldMap;

        Set<Id> campaignIdSet = new Set<Id>();

        for(Campaign campaign : campaignTriggerNew){
            if(Trigger.isUpdate && campaign.AKAM_Campaign_ID__c != campaignTriggerOldMap.get(campaign.Id).AKAM_Campaign_ID__c)
                campaignIdSet.add(campaign.Id);
        }

        if(campaignIdSet.size()>0)
        {
            CampaignTriggerClass.UpdateLatestCampaignOnLead(campaignIdSet, null); //MARIT-72 
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){

    }

    public override void afterDeleteAfterUndeleteTrigger(){

    }

}