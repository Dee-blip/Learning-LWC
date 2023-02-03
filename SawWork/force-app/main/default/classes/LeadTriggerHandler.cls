public with sharing class LeadTriggerHandler extends ApexTriggerHandlerAbstractClass
{
    
    public LeadTriggerHandler(){}

    public override void beforeInsertBeforeUpdateTrigger()
    {
        Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2391
        Id MulesoftIntegrationProfileId = Id.valueOf(GsmUtilClass.getGSMSettingValue('ProfileIdMulesoftIntegration'));
        List<Lead> listOfLeads = new List<Lead>();
        String stageAQL = GSMUtilClass.getGSMSettingValue('DWLSStageAQL');
        String stageTAL = GSMUtilClass.getGSMSettingValue('DWLSStageTAL');
        String stageTQL = GSMUtilClass.getGSMSettingValue('DWLSStageTQL');
        String stageTGL = GSMUtilClass.getGSMSettingValue('DWLSStageTGL');
        String stageTRL = GSMUtilClass.getGSMSettingValue('DWLSStageTRL');
        String stageMQL = GSMUtilClass.getGSMSettingValue('DWLSStageMQL');
        String stageMRL = GSMUtilClass.getGSMSettingValue('DWLSStageMRL');
        String stageSGL = GSMUtilClass.getGSMSettingValue('DWLSStageSGL');
        String stageMGL = GSMUtilClass.getGSMSettingValue('DWLSStageMGL');
        String stagePGL = GSMUtilClass.getGSMSettingValue('DWLSStagePGL');
        String marketoSyncUserAliases = GSMSettings.getValue('MarketoSyncUserAliases');
        String marketoSyncUserId = GSMSettings.getValue('MarketoSyncUserId');

        Map<String,Schema.RecordTypeInfo> recordTypeInfo = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName(); //getting all Recordtype for the Sobject
        Map<String,Id> recordTypeNameIdMap = new Map<String,Id>();        

        List<Lead> eligiblePartnerLeadsList = new List<Lead>();

        for(String recordName: recordTypeInfo.keySet()){
            Schema.RecordTypeInfo recInfo = recordTypeInfo.get(recordName);
            if(recInfo.isAvailable())
                recordTypeNameIdMap.put(recordName,recInfo.getRecordTypeId());
        }

        Set<Lead> leadsRequiringBuyAkamaiFields = new Set<Lead>(); // SFDC-2417 - End
        List<Lead> partnerLeadOwnerCheckList = new List<Lead>();
        List<Lead> partnerCampaignUpdateList = new List<Lead>();
        String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');
        String marketoUserAlias = GSMUtilClass.getGSMSettingValue('MarketoAPIUserAliases');
        String leadStatus = GSMUtilClass.getGSMSettingValue('ContactConversionLeadStatus');
        String partnerLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
        List<Id> pmaToMoveToInProgress = new List<Id>();//SFDC-4389
        List<Lead> pmaAccociatedEligibleForValidation = new List<Lead>();
        Set<String> leadFields_ChangeStatusToInProgress = GSMSettings.getSetOfStrings('leadFields_ChangeStatusToInProgress');
        List<Lead> c2aLeadForProjectedOwnerUpdate = new List<Lead>();//SFDC-5172
        

        for(SObject so: newList){
            Lead l = (Lead)so;
            Lead oldLead;

            if(Trigger.isUpdate)
                oldLead = (Lead)oldMap.get(l.Id);

            if(l.recordTypeId != recordTypeNameIdMap.get('Partner Lead') && 
                (Trigger.isUpdate && l.Associated_Account__c!= oldLead.Associated_Account__c) || Trigger.isInsert){
                System.Debug(LoggingLevel.Error, 'AGH_D account change');
                listOfLeads.add(l);
            }
            
            //MARIT-552 Removed Primary Campaign check with Self Gen as well as removing Primary Campaign from below custom metadata
            if (Trigger.isUpdate && l.RecordTypeId == recordTypeNameIdMap.get('Akamai Lead') && Util.hasChanges(leadFields_ChangeStatusToInProgress,oldLead,l) && l.status == 'New' && (!marketoUserAlias.contains(l.AKAM_Modified_By__c) && UserInfo.getUserId() != marketoSyncUserId)) {
                l.Status = 'In Process';
            }

            if(l.recordTypeId == partnerLeadRecordTypeId && l.Partner_Marketing_Activity__c!=null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Partner_Marketing_Activity__c',oldLead,l))))
            {
                SYstem.debug('Lead PMA status :'+l.Partner_Marketing_Activity__r.Activity_Status__c);
                pmaAccociatedEligibleForValidation.add(l);
            }

            // SFDC-2338
            if(Trigger.isUpdate && (oldLead.status != l.status || oldLead.Disposition__c != l.Disposition__c)) {
                l.Recent_Status_Disposition_Change_By__c = l.AKAM_Alias__c;
                l.Recent_Status_Disposition_Date__c = system.now();
            }

            // SFDC-3935 Campaign based on Partner Marketing activity
            if(l.recordTypeId == partnerLeadRecordTypeId && (Trigger.isInsert || (Trigger.isUpdate && oldLead.Partner_Marketing_Activity__c != l.Partner_Marketing_Activity__c ))) {
                partnerCampaignUpdateList.add(l);
            }

            // SFDC-2338
            if(Trigger.isInsert) {
                l.Recent_Status_Disposition_Change_By__c = l.AKAM_Alias__c;
                l.Recent_Status_Disposition_Date__c = system.now();
            }

            //This code takes care OF AKAM fields while insert if any of these field is null or Empty
            if(Trigger.isInsert){
                if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (l.AKAM_Created_By__c =='' ||  l.AKAM_Created_Date__c == null || l.AKAM_System__c =='')) || UserInfo.getProfileId() != MulesoftIntegrationProfileId ){
                    l.AKAM_Created_By__c = l.AKAM_Alias__c;
                    l.AKAM_Created_Date__c = system.now();
                    l.AKAM_System__c ='FORCE';
                }

                if(marketoUserAlias.contains(l.AKAM_Created_By__c)){
                    //SFDC-4547 Commenting below line
                    //l.RecordTypeId = Id.valueOf(akamaiLeadRecordTypeId);
                    l.Status = leadStatus;
                    l.Disposition__c = null;
                }
            }

            if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (l.AKAM_Modified_Date__c  == null|| l.AKAM_Modified_By__c == '' || l.AKAM_Modified_By__c == null)) || UserInfo.getProfileId() != MulesoftIntegrationProfileId){
                l.AKAM_Modified_By__c = l.AKAM_Alias__c;
                l.AKAM_Modified_Date__c =  system.now();
            }

            //SFDC-2361
            if((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('OwnerId',oldLead,l))) && UserInfo.getUserId() == marketoSyncUserId){
                l.Reassigned_By__c = 'SYSTEM';
                l.Reassigned_Date__c = Datetime.now();
            }

            if(Trigger.isInsert && UserInfo.getUserId() != marketoSyncUserId){
                l.Reassigned_By__c = UserInfo.getName();
                l.Reassigned_Date__c = Datetime.now();
            }

            //End of SFDC-2361

            if((Trigger.isInsert || l.OwnerId != oldLead.OwnerId) && (l.OwnerId + '').startsWith('005'))
                l.OwnerIDAlt__c = l.OwnerId;

            if(Trigger.isInsert && l.Associated_Contact_Id__c != null && l.Associated_Contact_Id__c != '' || Trigger.isUpdate && l.Associated_Contact_Id__c != null && l.Associated_Contact_Id__c != '' && l.Associated_Contact_Id__c != oldLead.Associated_Contact_Id__c){
                Id contactId = l.Associated_Contact_Id__c;
                l.Associated_Contact__c = contactId;
            }

            //correct the f-le field if it is not in sync
            if (l.AKAM_Lead_ID__c ==null || l.AKAM_Lead_ID__c.contains('F-LE') || Trigger.isInsert  )
                l.AKAM_Lead_ID__c = l.LeadAutoID__c;

            if (l.AKAM_Created_Date__c == null) l.AKAM_Created_Date__c = datetime.now();

            if((Trigger.isInsert || (Trigger.isUpdate && l.Status!=oldLead.Status)) && l.Status == 'New' && !marketoSyncUserAliases.contains(l.AKAM_Created_By__c)){
                if(GSMSettings.contains('MarketoAPIUserAliases', l.AKAM_Created_By__c))
                    l.Demand_Waterfall_Stage__c = stageMRL;
                else if(ProfileUtils.isSDR())
                    l.Demand_Waterfall_Stage__c = stageTGL;
                else if(ProfileUtils.isSalesOrGSSUser() || ProfileUtils.isBusinessOps())
                    l.Demand_Waterfall_Stage__c = stageSGL;
                else if(ProfileUtils.isMarketingOps())
                    l.Demand_Waterfall_Stage__c = stageMGL;
                else if(l.recordTypeId == partnerLeadRecordTypeId)
                    l.Demand_Waterfall_Stage__c = stagePGL;


            }
            
            if((Trigger.isInsert || (Trigger.isUpdate && l.Status!=oldLead.Status)) && !marketoSyncUserAliases.contains(l.AKAM_Created_By__c)){
                if(l.Status == 'Converted' && l.OwnerId==autoConvertQId)
                    l.Demand_Waterfall_Stage__c = stageAQL;
                else if(l.Status=='In Process')
                    l.Demand_Waterfall_Stage__c = stageTAL;
                else if(l.Status == 'Closed')
                    l.Demand_Waterfall_Stage__c = stageTRL;
                else if(l.Status =='Converted')
                    l.Demand_Waterfall_Stage__c = stageMQL;
            }

            if((Trigger.isInsert && l.Demand_Waterfall_Stage__c!=null) || (Trigger.isUpdate && oldLead.Demand_Waterfall_Stage__c != l.Demand_Waterfall_Stage__c))
                l.Lead_Stage_Create_Update_Time__c = datetime.now();

            // SFDC-2417
            if( (l.Lead_Record_Type__c == 'Akamai Lead') && ( Trigger.isInsert || ( Trigger.isUpdate && (oldLead.Associated_Account__c != l.Associated_Account__c) ) ) ) {
                leadsRequiringBuyAkamaiFields.add(l);
            }// SFDC-2417 - End

            If(Trigger.isUpdate && l.Validation_Override__c == True && (l.Status == 'Closed' || l.Status == 'In Process' || l.Status == 'New') && oldLead.Status == 'Converted'){
            l.Validation_Override__c = False;
            }

            //Populated partner involved field for Partner Leads
            if (l.RecordTypeId == recordTypeNameIdMap.get('Partner Lead') &&
                     (Trigger.isInsert || Util.hasChanges('OwnerId',Trigger.oldMap.get(so.Id),so))) {
                eligiblePartnerLeadsList.add(l);
            }

            if (l.recordTypeId == recordTypeNameIdMap.get('Partner Lead') && (Trigger.isInsert || oldLead.OwnerId !=l.OwnerId || oldLead.Lead_Owner__c !=l.Lead_Owner__c)) {
                partnerLeadOwnerCheckList.add(l);
            }

            if (l.recordTypeId == recordTypeNameIdMap.get('Partner Lead') && (Trigger.isUpdate && (oldLead.OwnerId !=l.OwnerId && !Util.hasChanges('Lead_Owner__c',oldLead,l)))) {
                l.Lead_Owner__c = l.OwnerId;
                partnerLeadOwnerCheckList.add(l);
            }

            

            
            /*//SFDC-5172
            if(Trigger.isUpdate && l.recordTypeId == recordTypeNameIdMap.get('Akamai Lead') && l.Associated_Account__c != null && Util.hasChanges('Associated_Account__c' ,oldLead, l) && (l.Status == 'In Process' || l.Status == 'New'))
            {
                c2aLeadForProjectedOwnerUpdate.add(l);
            }

            //MARIT-7
            //Ujjawal : Insert Projected Owner at the time of C2A creation
            if(Trigger.isInsert && l.recordTypeId == recordTypeNameIdMap.get('Akamai Lead') && l.Associated_Account__c != null && (l.Status == 'In Process' || l.Status == 'New'))
            {
                c2aLeadForProjectedOwnerUpdate.add(l);
            }*/

        }
        /*//SFDC-5172
        if(c2aLeadForProjectedOwnerUpdate.size()>0)
        {   
            List<Lead> c2aLeadForProjectedOwnerUpdateList = new List<Lead>();
            c2aLeadForProjectedOwnerUpdateList.addAll(c2aLeadForProjectedOwnerUpdate);
            c2aLeadForProjectedOwnerUpdateList =LeadToContactConversionClass.ProjectSDRForONALeads(c2aLeadForProjectedOwnerUpdateList);
        }*/

        //SFDC-4389
        if(!pmaAccociatedEligibleForValidation.isEmpty())
            PartnerMarketingClass.addPMANotInProgressValidation(pmaAccociatedEligibleForValidation);

        if (partnerLeadOwnerCheckList.size() > 0)
            PartnerLeadTriggerClass.partnerLeadOwnerCheck(partnerLeadOwnerCheckList);

        if (partnerCampaignUpdateList.size() > 0)
            PartnerLeadTriggerClass.updateCampaignOnLeads(partnerCampaignUpdateList);

        if (eligiblePartnerLeadsList.size() > 0) {
            PartnerLeadTriggerClass.populatePartnerInvolved(eligiblePartnerLeadsList);
        }

        for(SObject so: newList){//Not sure why its looped again, hence need to check with Hitesh and close it{
            Lead l = (Lead)so;
            Lead oldLead;
            if(Trigger.isUpdate)
                oldLead = (Lead)oldMap.get(l.Id);
            //SFDC-5172
            if(Trigger.isUpdate && l.recordTypeId == recordTypeNameIdMap.get('Akamai Lead') && l.Associated_Account__c != null && Util.hasChanges('Associated_Account__c' ,oldLead, l) && (l.Status == 'In Process' || l.Status == 'New'))
            {
                c2aLeadForProjectedOwnerUpdate.add(l);
            }
            //MARIT-7
            //Ujjawal : Insert Projected Owner at the time of C2A creation
            if(Trigger.isInsert && l.recordTypeId == recordTypeNameIdMap.get('Akamai Lead') && l.Associated_Account__c != null && (l.Status == 'In Process' || l.Status == 'New'))
            {
                c2aLeadForProjectedOwnerUpdate.add(l);
            }
        }
        if(c2aLeadForProjectedOwnerUpdate.size()>0){
            List<Lead> c2aLeadForProjectedOwnerUpdateList = new List<Lead>();
            c2aLeadForProjectedOwnerUpdateList.addAll(c2aLeadForProjectedOwnerUpdate);
            c2aLeadForProjectedOwnerUpdateList =LeadToContactConversionClass.ProjectSDRForONALeads(c2aLeadForProjectedOwnerUpdateList);
        }

        if(listOfLeads.size()>0)
            LeadTriggerClassWithoutSharing.populateVerticalFieldsFromAccountForLead(listOfLeads);


        // SFDC-2417 the below two logics should only run after populating Associated_Account__c field
        if(leadsRequiringBuyAkamaiFields.size() > 0)
            LeadTriggerClass.setBuyAkamaiFields(leadsRequiringBuyAkamaiFields);
    }

    public override void afterInsertAfterUpdateTrigger()
    {
        String stageMRL = GSMUtilClass.getGSMSettingValue('DWLSStageMRL');
        String stageSGL = GSMUtilClass.getGSMSettingValue('DWLSStageSGL');
        String stageMGL = GSMUtilClass.getGSMSettingValue('DWLSStageMGL');
        String stageTGL = GSMUtilClass.getGSMSettingValue('DWLSStageTGL');

        
        Map<Id,Id> mapContactToLead = new Map<Id,Id>();
        // Sometimes leads get converted on insert, in that case we want to capture both the stages. Eg : SGL, AQL.
        // if we do insert and update together, first run flag gets set on insert. So we need to separate it.
        Map<Id, String> leadIdToStageNameInserts = new Map<Id, String>();
        
        
        // Map<ID, String> convertedLeadIdsWithContactIdMap = new Map<Id, String>();

        String marketoSyncUserAliases = GSMSettings.getValue('MarketoSyncUserAliases');
        
        List<Lead> leadList = new List<Lead>();
        Map<Id, String> leadIdToStageName = new Map<Id, String>();
        
        System.debug('This is after insert and after update.');


        Map<String,Schema.RecordTypeInfo> recordTypeInfo = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName(); //getting all Recordtype for the Sobject
        Map<String,Id> recordTypeNameIdMap = new Map<String,Id>();
        for(String recordName: recordTypeInfo.keySet()){
            Schema.RecordTypeInfo recInfo = recordTypeInfo.get(recordName);
            if(recInfo.isAvailable())
                recordTypeNameIdMap.put(recordName,recInfo.getRecordTypeId());
        }


        //SFDC 3223 - Partner Lead Management - Creating shares
        Id partnerLeadRecordType = recordTypeInfo.get('Partner Lead').getRecordTypeId();
        PartnerLeadTriggerClass.CreatePartnerLeadSharesTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap, partnerLeadRecordType);
        //End of SFDC 3223

        
        
        for(SObject so: newList){
            Lead l = (Lead)so;
            Lead oldLead;


            if(Trigger.isUpdate)
                oldLead = (Lead)oldMap.get(l.Id);

            if(l.RecordTypeId != recordTypeNameIdMap.get('Marketo Lead') && l.RecordTypeId != recordTypeNameIdMap.get('Partner Lead')){
                // if lead is created or it's status/disposition is updated
                if(Trigger.isInsert || (Trigger.isUpdate && (l.Status != oldLead.Status || l.Disposition__c!= oldLead.Disposition__c))){
                    mapContactToLead.put(l.Associated_Contact__c,l.Id);
                }
            }

            //SFDC-1102- If Insert and cretaed by MAPI- Its the first Stage-AQL
            //On update of Status or Disposition - Create History Records based on Stage Name
            //Lead Demand Waterfall Stage field population and Demand Waterfall Stage History Record Creation
            if(Trigger.isInsert && l.Demand_Waterfall_Stage__c!=null){
                leadIdToStageNameInserts.put(l.Id, l.Demand_Waterfall_Stage__c);
                String initStage;
                if(l.status == 'In Process'){
                    if(GSMSettings.contains('MarketoAPIUserAliases', l.AKAM_Created_By__c))
                        initStage = stageMRL;
                    else if(ProfileUtils.isSDR())
                        initStage = stageTGL;
                    else if(ProfileUtils.isSalesOrGSSUser() || ProfileUtils.isBusinessOps())
                        initStage = stageSGL;
                    else if(ProfileUtils.isMarketingOps())
                        initStage = stageMGL;

                    DemandWaterfallStages.createDemandWaterfallStages(new Map<Id, String>{l.id => initStage });
                    DemandWaterfallStages.createDemandWaterfallStagesHasRun = false;

                }
            }
            if(Trigger.isUpdate && l.Demand_Waterfall_Stage__c != oldLead.Demand_Waterfall_Stage__c){
                leadIdToStageName.put(l.Id, l.Demand_Waterfall_Stage__c);
            }

            //SFDC-3054
            // if(Trigger.isUpdate && l.recordTypeId == recordTypeNameIdMap.get('Partner Lead') && ((oldLead.status!='Converted' && l.Status=='Converted') || (oldLead.status!='Closed' && l.Status=='Closed'))){
            //     convertedLeadIdsWithContactIdMap.put(l.Id, l.Associated_Contact__c);
            // }
              
        }

        // if(convertedLeadIdsWithContactIdMap.size()>0)
        //     LeadToContactConversionClass.migrateTasks(convertedLeadIdsWithContactIdMap);

        // populate Associated Lead on Contact
        if(mapContactToLead.size()>0)
            LeadHelper.populateLatestLeadOnContact(mapContactToLead);
        
        

        if(leadIdToStageNameInserts.size()>0){
            DemandWaterfallStages.createDemandWaterfallStages(leadIdToStageNameInserts);
            // if there is AQL coming in update, then i want this to run again
            DemandWaterfallStages.createDemandWaterfallStagesHasRun = false;
        }


        if(leadIdToStageName.size() > 0){
            DemandWaterfallStages.createDemandWaterfallStages(leadIdToStageName);
        }


        //SFDC-9138  Rajul Vishwakarma
        if(Trigger.isUpdate){
            LeadTriggerClass.prepareAccoutsForRecomputation(false,true,Trigger.oldMap,Trigger.new,null);
        }
        if(Trigger.isInsert){
            LeadTriggerClass.prepareAccoutsForRecomputation(true,false,null,Trigger.new,null);
        }
        //End
    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        //SFDC-2861
        String profileIds = GSMUtilClass.getGSMSettingValue('LeadDeleteAccessProfiles');
        if(!profileIds.contains(UserInfo.getProfileId())){
            for(SObject so: Trigger.old){
                Lead l = (Lead)so;
                l.adderror('Profile does not have delete permission on Lead record'); 
            }
        }  
        
         //SFDC-9138  - Rajul Vishwakarma
         if(Trigger.isDelete){
            LeadTriggerClass.prepareAccoutsForRecomputation(false,false,null,null,Trigger.old);
        }
        // End
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        System.debug('This is after delete and after undelete.');
    }

}