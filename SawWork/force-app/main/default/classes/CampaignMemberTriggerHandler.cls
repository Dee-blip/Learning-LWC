public without sharing class CampaignMemberTriggerHandler extends ApexTriggerHandlerAbstractClass 
{
    // NOTE - not all trigger events are handled.
    // before insert update events have to be added to the trigger if you need them.

    public override void beforeInsertBeforeUpdateTrigger()
    {
        //MARIT-1761
        Map<CampaignMember, Id> CmpgnMemToLeadId = new Map<CampaignMember, Id>();
        Map<CampaignMember, Id> CmpgnMemToContactId = new Map<CampaignMember, Id>();
        if(Trigger.isInsert) {
            for(SObject so: newList){
                CampaignMember cmpgnMem = (CampaignMember)so;
                if(cmpgnMem.ContactId != null) {
                    CmpgnMemToContactId.put(cmpgnMem,cmpgnMem.ContactId);
                } else if (cmpgnMem.LeadId != null) {
                    CmpgnMemToLeadId.put(cmpgnMem,cmpgnMem.LeadId);
                }
            }
        }
        if(CmpgnMemToContactId != null && !CmpgnMemToContactId.isEmpty()) {
            MARIT_CampaignMemberTriggerClass.SetAccountDetailsViaContact(CmpgnMemToContactId);
        }
        if(CmpgnMemToLeadId != null && !CmpgnMemToLeadId.isEmpty()) {
            MARIT_CampaignMemberTriggerClass.SetAccountDetailsViaLead(CmpgnMemToLeadId);
        }
    }

    public override void afterInsertAfterUpdateTrigger()
    {
        Set<Id> contactIdsForLatestCampaignPopulation = new Set<Id>();
        Set<Id> campaignIdsForLatestCampaignPopulation= new Set<Id>();
        Map<Id,Id> leadTocampaignMap = new Map<Id,Id>();
        Map<Id,Id> contactTocampaignMap = new Map<Id,Id>();
        Set<String> ctaCreationCampaigns = new Set<String>(MarketingUtilClass.getMarketingSettingsValue('CTACreationCampaigns').replaceAll(' ', '').split(','));

        Set<id> leadIds = new Set<Id>();
        for(SObject so: Trigger.new)
        {
            CampaignMember cmpgnMember= (CampaignMember)so;
            // MARIT-449, removing the call while inserting campaign member which update latest camp akam ID on Lead 
            // and Latest camp id on Contact
            /*if(cmpgnMember.ContactId!=null)
                contactIdsForLatestCampaignPopulation.add(cmpgnMember.ContactId);*/

            if(cmpgnMember.LeadId!=null)
            {
                //campaignIdsForLatestCampaignPopulation.add(cmpgnMember.CampaignId);
                leadIds.add(cmpgnMember.LeadId);
            }
            
            if(ctaCreationCampaigns.contains(cmpgnMember.CampaignId)) {
                if(cmpgnMember.LeadId != null) {
                    leadTocampaignMap.put(cmpgnMember.LeadId, cmpgnMember.CampaignId);
                } else {
                    contactTocampaignMap.put(cmpgnMember.ContactId, cmpgnMember.CampaignId);
                }
            }
        }
        // MARIT-449
        //if(contactIdsForLatestCampaignPopulation.size()>0)
            //CampaignTriggerClass.updateLatestCampaignOnContact(contactIdsForLatestCampaignPopulation);
        // MARIT-449
        //if(leadIds.size()>0)
            //CampaignTriggerClass.updateLatestCampaignOnLead(campaignIdsForLatestCampaignPopulation, leadIds);

        if(leadIds.size()>0)
            CampaignTriggerClass.createCampaignMemberAuditTrail(Trigger.new, leadIds, Trigger.isDelete, Trigger.isInsert);
            
        if((leadTocampaignMap != null && !leadTocampaignMap.isEmpty()) || (contactTocampaignMap != null && !contactTocampaignMap.isEmpty()) ) {
            LeadUtilClass.createCTAforPerson(leadTocampaignMap,contactTocampaignMap,'Marketing List Import','Web Security');
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        String marketingOpsProfileId=GsmUtilClass.getGSMSettingValue('CmpgnMmbrTrgr_ExcptnProfiles');
        Set<id> leadIds = new Set<Id>();
        if(!marketingOpsProfileId.contains(UserInfo.getProfileId()))
        {
            String errMsg=GsmUtilClass.getGSMSettingValue('CmpgnMmbrTrgr_RemoveErrMsg');
            for(SObject so: Trigger.old)
            {
                CampaignMember cm = (CampaignMember)so;
                cm.addError(errMsg);
            } 
        }
        else
        {
            for(SObject so: Trigger.old)
            {
                CampaignMember cm = (CampaignMember)so;
                if(cm.LeadId!=null)
                {
                    leadIds.add(cm.LeadId);
                }
            }

            if(leadIds.size()>0)
                CampaignTriggerClass.createCampaignMemberAuditTrail(Trigger.old, leadIds, Trigger.isDelete, Trigger.isInsert);

        }
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {

    }

}