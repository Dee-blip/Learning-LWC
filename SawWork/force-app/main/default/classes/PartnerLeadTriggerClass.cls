public with sharing class PartnerLeadTriggerClass
{
    public static void updateCampaignOnLeads(List<Lead> leads) 
    {

        List<Id> pmaIdList = new List<Id>();
        Map<Id,Id> pmaToCampaignIdMap = new Map<Id,Id>();

        for (Lead l:leads) 
        {
            pmaIdList.add(l.Partner_Marketing_Activity__c);
        }

        for (Partner_Marketing_Activity__c pma:[Select id,Indirect_Campaign__c 
                                                        From Partner_Marketing_Activity__c
                                                        Where id IN:pmaIdList]) 
        {
            pmaToCampaignIdMap.put(pma.id, pma.Indirect_Campaign__c);
        }

        for (Lead l:leads) 
        {
            l.Primary_Campaign__c = pmaToCampaignIdMap.get(l.Partner_Marketing_Activity__c);
        }
    }

    public static void populatePartnerInvolved(List<Lead> eligiblePartnerLeadsList)
    {
            List<Id> partnerLeadOwnerIdsList = new List<Id>();

            for (Lead l:eligiblePartnerLeadsList) 
            {
                partnerLeadOwnerIdsList.add(l.ownerId);
            }

            Map<Id,Id> userIdToPartnerAccountIdMap = new Map<Id,Id>();
            for(User u : [Select id, contact.accountId From User where id IN :partnerLeadOwnerIdsList])
            {
                userIdToPartnerAccountIdMap.put(u.id,u.contact.accountId);
            }

            for (Lead l:eligiblePartnerLeadsList) {
                if (l.Partner_Involved__c == null) {
                    l.Partner_Involved__c = userIdToPartnerAccountIdMap.get(l.ownerId);
                }
            }
    }

    public static void partnerLeadOwnerCheck(List<Lead> partnerLeadOwnerCheckList) 
    {

        if (partnerLeadOwnerCheckList == null)
            return;

        Map<Id,List<Lead>> ownerToLeadMap = new Map<Id,List<Lead>>();
        List<Id> leadOwnerIds = new List<Id>();
        List<Lead> leadList;

        for (Lead l:partnerLeadOwnerCheckList) {
            if (ownerToLeadMap.get(l.Lead_Owner__c) == null) {
                leadList = new List<Lead>();
            } else {
                leadList = ownerToLeadMap.get(l.Lead_Owner__c);
            }
            leadList.add(l);
            ownerToLeadMap.put(l.Lead_Owner__c, leadList);

            leadOwnerIds.add(l.Lead_Owner__c);
        }

        List<User> ownersList = [Select id, isActive,Contact.Active_Partner__c From User Where id IN:leadOwnerIds];

        Id loggedInUserId = UserInfo.getUserId();
        User loggedInUser = [Select id,Contact.Active_Partner__c From User where id =:loggedInUserId];

        if (!loggedInUser.Contact.Active_Partner__c) {

            for (User u:ownersList) {
                List<Lead> leadsForUser = ownerToLeadMap.get(u.id);
                //Boolean hasPartnerLeadPermission;
                if (!u.isActive || !u.Contact.Active_Partner__c || !hasPartnerLeadPermission(u.id)) {
                    for (Lead ld:leadsForUser) {
                        ld.addError(GSMUtilClass.getNAPSettingValue('PartnerLeadOwnerCheckError'));
                    }
                } else {
                    System.debug('Setting owner to :'+u.id);
                    for (Lead ld:leadsForUser) {
                        ld.ownerId = u.id;
                    }
                }
            }
        }
        
    }
    public static void CreatePartnerLeadSharesTriggerMethod(list<sObject> Triggernew , map<Id,sObject> TriggeroldMap,map<Id,sObject> TriggernewMap, Id partnerleadRecordType)
    {
        Map<Id, Id> leadPartnerAccMap = new Map<Id, Id>();
        Map<Id, Id> leadOldPartnerAccMap = new Map<Id, Id>();

        Map<Id, Id> leadIds = new Map<Id, Id>();
        Map<Id, Id> oldLeadIds = new Map<Id, Id>();

        Map<Id,Id> leadShareCreateMap = new Map<Id,Id>();
        List<Lead> leadShareDeleteList = new List<Lead>();
    
        for (sObject sOb : Triggernew) {
             Lead sObj = (Lead)sOb;
            //Check if the owner is getting changed
            Boolean partnerChanged = trigger.isUpdate && Util.hasChanges('Partner_Involved__c', 
                                                                        TriggeroldMap.get(sObj.Id),
                                                                        sObj);
            if (partnerChanged && sObj.RecordTypeId==partnerleadRecordType) {
                //oldLeadIds.put(sObj.Id, TriggeroldMap.get(sObj.Id).Partner_Involved__c);
                leadShareCreateMap.put(sObj.id,sObj.Partner_Involved__c);
                leadShareDeleteList.add(sObj);
            }

            if (trigger.isUpdate && Util.hasChanges('OwnerId',TriggeroldMap.get(sObj.Id),sObj) && sObj.RecordTypeId==partnerleadRecordType) {
                leadShareCreateMap.put(sObj.id,sObj.Partner_Involved__c);
            }

            if (trigger.isInsert && sObj.RecordTypeId==partnerleadRecordType) {
                //leadIds.put(sObj.Id, sObj.Partner_Involved__c);
                leadShareCreateMap.put(sObj.id,sObj.Partner_Involved__c);
            }
        }

        if (!leadShareCreateMap.isEmpty()) {
            PartnerLeadShare.CreatePartnerShares(leadShareCreateMap);
        }

        if (!leadShareDeleteList.isEmpty()) {
            PartnerLeadShare.DeletePartnerShares(leadShareDeleteList,Trigger.oldMap);
        } 
    }


    public static boolean hasPartnerLeadPermission(Id userId) {

        Set<String> psSet = new Set<String>();
        psSet.add('Partner_Leads_Only_Access');

        List<PermissionSetAssignment> psaList =  [SELECT PermissionSetId 
                                                        FROM PermissionSetAssignment 
                                                        WHERE AssigneeId= :userId 
                                                            AND PermissionSet.Name IN:psSet];
        if (psaList.size() > 0)
            return true;
        else
            return false;
    }
}