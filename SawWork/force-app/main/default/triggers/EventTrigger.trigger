/**
 * If an activity is created from a lead, this will reassociate that activity
 * to the contact object and sets all the correct associated akamIDs used for
 * integration.
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic    1/2010      Created Class
 *
 * Pitamber Sharma 06/27/2013 : Added code to set recent update = true on cases [T-157179]
 * Deepak Saxena   03/07/2016 : CR 3303121 Remove references to Case_Update__c field from Event trigger
 **/
trigger EventTrigger on Event (before insert, before update, after insert) {
        
        if(Trigger.isBefore) {                                              //Wrap Old in If condition as old code was all about Before events and new code run on After event.
            Set<Id> eventWhoIDSet = new Set<Id>();
            for (Event e : trigger.new)
                    eventWhoIDSet.add(e.whoID);
    
            Map<Id, Lead> leadMap = new Map<Id,Lead>();
            for (Lead l:[Select Id, AKAM_LEAD_ID__c, Associated_Contact__c,
                        Associated_Contact__r.AKAM_Contact_ID__c,
                        Associated_Contact__r.OD_Contact_ROW_ID__c,
                        Associated_Contact__r.AccountId,
                        Associated_Contact__r.Account.AKAM_Account_ID__c,
                        Associated_Contact__r.Account.OD_Account_Row_ID__c
                        from Lead where id in :eventWhoIDSet])
                        {
                        leadMap.put(l.id, l);
                        }
    
            Id orgWhoID; //this is needed to hold the original id as it will be replaced
            // need to update task.akam_campaign_id with oldest lead's campaign
            // so create a map of AKAM_Campaign_ids for batch
            Map<Id, CampaignMember> CampaignMap = new Map<Id,CampaignMember>();
            for (Lead l2:[SELECT id, 
                        (SELECT Id, campaign.AKAM_Campaign_ID__c 
                         FROM CampaignMembers order by createddate desc limit 1) 
                         FROM lead WHERE id in :eventWhoIDSet])
                    {
                        for (CampaignMember cm: l2.CampaignMembers)
                            campaignMap.put(l2.id, cm);
                    }
            //loop tasks and assign who,what and AKAM id's
            for (Event e2 : trigger.new)
                {
                    orgWhoID = null; //reset
                    if(leadMap.containsKey(e2.WhoID))
                    //this event record is from a lead
                    {
                    e2.Associated_AKAM_Lead_ID__c = leadMap.get(e2.whoID).AKAM_Lead_ID__c;
                    //move event to contact and Account
                    orgWhoID = e2.WhoId; // since we're changing this, need org for map
                    e2.whoID= leadMap.get(orgWhoID).Associated_Contact__c;
                    e2.Associated_AKAM_Contact_ID__c = leadMap.get(orgWhoID).Associated_Contact__r.AKAM_Contact_ID__c;
                    e2.whatID = leadMap.get(orgWhoID).Associated_Contact__r.AccountId;
                    e2.Associated_AKAM_Account_ID__c = leadMap.get(orgWhoID).Associated_Contact__r.Account.AKAM_Account_ID__c;
                    
                    //last step, add the correct campaign id
                    if (campaignMap.containsKey(orgWhoID))
                        e2.Associated_AKAM_Campaign_ID__c = campaignMap.get(orgWhoID).Campaign.AKAM_Campaign_ID__c;             
                    }
                }
        } else if(Trigger.isAfter && Trigger.isInsert) {
            List<Case> recentUpdatedCases = new List<Case>();
            List<Event> caseEvents = new List<Event>();
            Set<Id> recentUpdatedCaseIds = new Set<Id>();
            Map<Id, Case> caseMap;
            Case cs;
            Boolean isUpdated = false;
        
            for(Event e : Trigger.new) {
                if(e.WhatId != null && String.valueOf(e.WhatId).startsWith('500')) {
                    recentUpdatedCaseIds.add(e.WhatId);
                    caseEvents.add(e);
                }
            }
            
            if(recentUpdatedCaseIds.size() > 0) {
                caseMap = new Map<Id, Case>([Select Id, Recent_Update__c, ownerId ,Resolved_Date__c from Case Where Id IN : recentUpdatedCaseIds]);
                
                for(Event e : caseEvents) {
                    cs = caseMap.get(e.WhatId);
                    if(caseMap.get(e.WhatId).ownerId != e.CreatedById) {
                        cs.Recent_Update__c = true;
                        isUpdated = true;
                    }
                    // Commented below line as part of CR 3303121
                    //if(e.Case_Update__c == true) {
                        if(cs.Resolved_Date__c == null || cs.Resolved_Date__c > Datetime.now()){
                            cs.Last_Case_Update__c = Datetime.now();
                            isUpdated = true;
                        }
                        
                    //}
                    if(isUpdated) {
                        recentUpdatedCases.add(cs);
                        isUpdated = false;
                    }
                }
                
                if(recentUpdatedCases.size() > 0) {
                    update recentUpdatedCases;
                }
            }
        }

}