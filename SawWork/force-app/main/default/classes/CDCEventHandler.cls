public class CDCEventHandler {
    //SFDC-6594
    public static void handleAccountOwnerUpdate(List<EventBus.ChangeEventHeader> changeEventHeaders){
        /* Start of Account Reassignment */
        list<string> accountChangedFields = new list<string>();
        list<string> ownerChangeRecordIds = new list<string>();
        list<string> channelLevelAccFieldChangeRecIds = new list<string>();
        set<string> channelLevelAccFields = new set<string>();
        channelLevelAccFields.addAll(GsmUtilClass.getPRMSettingValue('ChannelLevel_AccFieldChange').split(','));
        for (EventBus.ChangeEventHeader header : changeEventHeaders) {
            accountChangedFields = header.changedfields;
            if(accountChangedFields.contains('OwnerId')){
                ownerChangeRecordIds.addAll(header.recordIds);
            }
            for(string field : channelLevelAccFields){
                if(accountChangedFields.contains(field)){
                    channelLevelAccFieldChangeRecIds.addAll(header.recordIds);
                    break;
                }
            }
        }
        if(channelLevelAccFieldChangeRecIds.size()>0){
            AccountReassignmentTriggerClass.updateOpptysChannelLevel(channelLevelAccFieldChangeRecIds);
        }
        if(ownerChangeRecordIds.size()>0){
            //AccountReassignmentTriggerClass.updateAccountRelatedRecords(ownerChangeRecordIds);
            AccountReassignmentTriggerClass.updateAccountShareForPartnerAdmins(ownerChangeRecordIds);
            map<string,string> batchSize = GsmUtilClass.getKeyValueMetadata('Account_Reassignment_Config__mdt','Value__c','ContactUpdate_BatchSize,LeadUpdate_BatchSize,OpportunityUpdate_BatchSize',false);
            UpdateOpptyOnAccountOwnerChangeBatch opptyUpdate = new UpdateOpptyOnAccountOwnerChangeBatch(ownerChangeRecordIds);
            Database.executeBatch(opptyUpdate,Integer.valueOf(batchSize.get('OpportunityUpdate_BatchSize')));
            UpdateContactOnAccountOwnerChangeBatch contactUpdate = new UpdateContactOnAccountOwnerChangeBatch(ownerChangeRecordIds);
            Database.executeBatch(contactUpdate,Integer.valueOf(batchSize.get('ContactUpdate_BatchSize')));
            UpdateLeadOnAccountOwnerChangeBatch leadUpdate = new UpdateLeadOnAccountOwnerChangeBatch(ownerChangeRecordIds);
            Database.executeBatch(leadUpdate,Integer.valueOf(batchSize.get('LeadUpdate_BatchSize')));
            ContractSharing.updateAccountOwnerContractShare(ownerChangeRecordIds);
        }
        /* End of Account Reassignment */
    }


    public static void handlePublishEvent(List<EventBus.ChangeEventHeader> changeEventHeaders) 
    {
        try
        {
            String updateFieldsToIgnoreForCDC = GSMSettings.getVerbose('UpdateFieldsToIgnoreForCDC');
            List<String> toBeIgnoredFieldsForUpdate = updateFieldsToIgnoreForCDC.split(',');    
            List<RecordToSync__c> auditTrailsToBeInserted = new List<RecordToSync__c>();

            String sObjecttypeLabel;

            List<Id> recordIds = new List<Id>();
            Map<String,Set<String>> recordIdToChangedFields = new Map<String,Set<String>>();
            Map<Id, Id> recordIdToCommitUserId = new Map<Id, Id>();
            Set<Id> userIds = new Set<Id>();

            for (EventBus.ChangeEventHeader header : changeEventHeaders) 
            {
                 if (header.changetype == 'CREATE') 
                 {
                    for (Id recordId : header.recordids) 
                    {
                        recordIdToChangedFields.put(recordId, new Set<String>());
                    }
                 }

                if(String.isBlank(sObjecttypeLabel))
                {
                    sObjecttypeLabel=header.entityname;
                }
                recordIds.addAll(header.recordIds);
                for (Id recordId : header.recordids) 
                {
                    if(header.commituser!=null)
                    {
                        recordIdToCommitUserId.put(recordId, header.commituser);
                        userIds.add((Id)header.commituser);
                    }
                    for (String field : header.changedFields) 
                    {
                        if (!toBeIgnoredFieldsForUpdate.contains(field)) 
                        {
                            if (!recordIdToChangedFields.containsKey(recordId)) 
                            {
                                recordIdToChangedFields.put(recordId, new Set<String>{});
                            } 
                            recordIdToChangedFields.get(recordId).add(field);
                        }
                    }

                }
            }

            Map<Id, Id> userIdToProfileId = UserUtils.getProfileIds(userIds);

            Map<Id,String> recordIdToAkamID = AkamFieldHandler.getAkamIds(recordIds, sObjecttypeLabel);

            Map<String, Set<String>> integrationProfileIdToSiebelFields = GSMSettings.getSyncToSiebelFields(sObjecttypeLabel, false);

            for (String recId : recordIdToChangedFields.keySet()) 
            {
                Set<String> changedFields = recordIdToChangedFields.get(recId);
                Id userId = recordIdToCommitUserId.get(recId);
                Id profileId = userIdToProfileId.get(userId);

                Set<String> fieldsForSiebel;

                if(integrationProfileIdToSiebelFields.containsKey(profileId))
                {
                    fieldsForSiebel=integrationProfileIdToSiebelFields.get(profileId);
                }
                else
                {
                    fieldsForSiebel = integrationProfileIdToSiebelFields.get('NonIntegrationUser');
                }

                Boolean shouldSyncToSiebel = false;
                // check if any field is relevant to siebel
                for (String eachField : changedFields) 
                {
                    if (fieldsForSiebel.contains(eachField)) 
                    {
                        shouldSyncToSiebel = true;
                        break;
                    }
                }

                //SFDC-8442
                if (changedFields.size()==0 || shouldSyncToSiebel) 
                {
                    RecordToSync__c  auditTrail = new RecordToSync__c();
                    auditTrail.BusinessComponent__c = sObjecttypeLabel;
                    auditTrail.ChangedFields__c = changedFields.size()>0 ? String.join(new List<String>(changedFields), ', '): '';
                    auditTrail.IntegrationId__c = recordIdToAkamID.get(recId); 
                    auditTrail.Operation__c = changedFields.size()>0 ? 'UPDATE':'INSERT';
                    auditTrail.DownstreamSystemToSync__c  = 'Siebel';
                    auditTrailsToBeInserted.add(auditTrail);
                }
                //End of SFDC-8442
            }

            if (auditTrailsToBeInserted.size() > 0) 
            {
                insert auditTrailsToBeInserted;
            } 
        }
        catch(Exception exx)
        {
            Sawyer.saw(exx);
        }
    }

}