/*
 * Created By Mayank Bansal on 22nd Aug,19 as part of MARIT-5-0
 */
public without sharing class MARIT_LeadTriggerHandler extends ApexTriggerHandlerAbstractClass {

    public static Boolean checkLeadStatusFirstRunFlag = true;//MARIT-11
    public static Boolean checkLeadOwnerIdFirstRunFlag = true; // MARIT-142
    //MARIT-306
    public static List<String> listOfMDT = new List<String>();
    public static List<String> fetchStringSetFromMDT = new List<String>();
    public static Map<String, String> fetchRequiredMDTs = new Map<String, String>();
    public static Map<String, Set<String>> fetchStringSetForRequiredMDTs = new Map<String, Set<String>>();
    public static Set<String> fieldsToBeChecked = new Set<String>();
    public static Set<String> leadAssignmentfieldsToBeChecked = new Set<String>();
    public static Map<String, Id> recordTypeNameToIDMap = new Map<String, Id>();//MARIT-401
    public static Boolean isLeadConversionAsynModeSet = true; //MARIT-543
    public static Map<Id, Boolean> leadIdTofirstRunFlagMap = new Map<Id, Boolean>(); //MARIT-867
    
    public MARIT_LeadTriggerHandler(){
        listOfMDT.add('MarketoIntegrationProfileId');
        listOfMDT.add('WWWLeadGenAccountIdMarketo');
        listOfMDT.add('WWWLeadGenAKAMAccountIds');
        listOfMDT.add('SystemAdminProfileId');
        listOfMDT.add('MarketoAPIUserAliases');
        listOfMDT.add('BPPStatusFieldsForLead');
        listOfMDT.add('BPPStageFieldsForLead');
        listOfMDT.add('MarketoSyncUserAliases');
        listOfMDT.add('MarketoSyncUserId');
        listOfMDT.add('LeadAutoConvert_QueueId');
        
        fetchStringSetFromMDT.add('LeadAutoConversionFieldsToBeChecked');
        fetchStringSetFromMDT.add('LeadAssignmentRuleFieldsToBeChecked');
        fetchStringSetFromMDT.add('BPPStageFieldsForLead');
        fetchStringSetFromMDT.add('BPPStatusFieldsForLead');
        fetchStringSetFromMDT.add('BPPSLAs');
        
        fetchRequiredMDTs = MarketingUtilClass.getGSMSettingValueForMultiples(listOfMDT);
        fetchStringSetForRequiredMDTs = MarketingUtilClass.getGSMSettingSetValuesForMultiples(fetchStringSetFromMDT);
        fieldsToBeChecked = fetchStringSetForRequiredMDTs.get('LeadAutoConversionFieldsToBeChecked');
        leadAssignmentfieldsToBeChecked = fetchStringSetForRequiredMDTs.get('LeadAssignmentRuleFieldsToBeChecked');
        List<RecordType> leadRecordTypeList = [select Id,Name from RecordType where sObjectType='Lead'];
        for(RecordType rc: leadRecordTypeList){
            recordTypeNameToIDMap.put(rc.Name, rc.Id);
        }
        isLeadConversionAsynModeSet = MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus') != null?Boolean.valueOf(MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus').Flag_Status__c):true;
        //whether to run in async or sync mode. Set LeadAsyncConversionFlagStatus = false in custom settings to turn off async manual lead conversion
    }    


    public override void beforeInsertBeforeUpdateTrigger() {
        String marketoSyncUserAliases = fetchRequiredMDTs.get('MarketoSyncUserAliases');
        String marketoSyncUserId = fetchRequiredMDTs.get('MarketoSyncUserId');
        List<Lead> leadListHavingMarketoAkamAccountId = new List<Lead>();
        Set<String> marketoAkamAccountIdSet = new Set<String>();
        List<Lead> checkDuplicateList = new List<Lead>();
        List<Lead> leadToPopulatePersonFields = new List<Lead>();//SFDC-4546
        List<Lead> leadToSetSLAs = new List<Lead>();
        List<Lead> leadToSetInitialSLAs = new List<Lead>();//SFDC-5167
        List<Lead> addErrorForMissingValue = new List<Lead>();//SFDC-4546
        List<Id> parentLeads = new List<Id>();
        List<Id> parentCons = new List<Id>();
        List<Lead> marketoLeadForProjectedOwnerUpdate = new List<Lead>();//MARIT-215
        List<Lead> leadToUpdateProspectField = new List<Lead>(); //MARIT-687
        Map<Lead, Id> leadToCampaignIdMap = new Map<Lead, Id>();

        //MARIT-1277, for CTA field updates 
        List<Id> parentLeadsWithCTAFieldUpdates = new List<Id>();
        List<Id> parentConsWithCTAFieldUpdates = new List<Id>();
        List<Lead> leadToPopulatePersonFieldsOnCTAFieldUpdates = new List<Lead>();

        //MARIT-16 : Annuitas: Highest Lead Qualification Stage
        Set<String> stageFieldsQL = fetchStringSetForRequiredMDTs.get('BPPStageFieldsForLead');
        Set<String> statusAndSLAFields = fetchStringSetForRequiredMDTs.get('BPPStatusFieldsForLead');//MARIT-448
        List<String> strList = MarketingUtilClass.getMarketingSettingValuePartialMatch('HighestToLowestLeadQualificationStage');
        String marketoIntegrationProfileId = fetchRequiredMDTs.get('MarketoIntegrationProfileId');
        String high_to_low = null;
        Set<Lead> leadsToCheckAddress = new Set<Lead>();
        Set<String> leadAddressFields = new Set<String>(MarketingUtilClass.getMarketingSettingsValue('LeadAddressFields').split(','));
        Set<String> bppFields = new Set<String>(MarketingUtilClass.getMarketingSettingsValue('BPP_Field_List').replaceAll(' ', '').split(','));
        Map<Id,Boolean> relatedRecordAddressCheck = new Map<Id,Boolean>();

        String driftAlias = MarketingUtilClass.getMarketingSettingsValue('DriftAlias');
        Set<Id> DriftProfileId = new Set<Id>();
        List<Id> DriftProfileIds = MarketingUtilClass.getMarketingSettingsValue('DriftProfileId').split(',');
        DriftProfileId.addAll(DriftProfileIds);
        Id driftCampaign = MarketingUtilClass.getMarketingSettingsValue('DriftCampaign');
        Id globalCatchAllId = MarketingUtilClass.getMarketingSettingsValue('GlobalCacheCatchQueue');

        //MARIT-875
        Map<Id,Lead> parentContact = new Map<Id,Lead>();
        Map<Id,Lead> parentLead = new Map<Id,Lead>();

        //MARIT-773
        Map<Id,Id> convertedLeadIdWithParentIdMap = new Map<Id,Id>();
        List<Lead> playbooksCopyOverLeadList = new List<Lead>();
        
        //MARIT-946 acd
        List<Lead> removePhoneValuesFromLead = new List<Lead>();
        List<Lead> syncNewFromOldPhoneFields = new List<Lead>();
        List<Lead> syncOldFromNewPhoneFields = new List<Lead>();

        //MARIT-1681 e164
        List<Lead> updatePhoneValuesToE164 = new List<Lead>();

        //MARIT-1014
        Map<Id,Lead> ctaWithPersonLead = new Map<Id,Lead>();
        Map<Id,Lead> ctaWithPersonCon = new Map<Id,Lead>();

        //MARIT-1071
        Map<String,List<SObject>> acquistionProgramToLeadMap = new Map<String,List<SObject>>(); 
        Set<String> acquistionProgramNames = new Set<String>();
        Set<String> acquistionProgramAkamIds = new Set<String>();
        
        for(String str: strList){
            if(high_to_low == null){
                high_to_low = str;
            } else{
                high_to_low += ',' + str;
            }
        }
        List<String> highest_lowest_QL_Stage = high_to_low.split(',');
        
        for(SObject so: newList){
            Lead l = (Lead)so;
            Lead oldLead = Trigger.isUpdate ? (Lead)oldMap.get(l.Id) : null;
            
            if(l.Donot_run_Trigger__c == true || (leadIdTofirstRunFlagMap.containsKey(l.id) && leadIdTofirstRunFlagMap.get(l.id))){
                leadIdTofirstRunFlagMap.put(l.id, true);
                continue;
            }else{
                leadIdTofirstRunFlagMap.put(l.id, false);
            }
            // common code irrespective of lead type
            if(l.First_Assignment_Date__c==null && l.ownerId!=null && l.Associated_AKAM_Account_ID__c!=null && !fetchRequiredMDTs.get('WWWLeadGenAKAMAccountIds').contains(l.Associated_AKAM_Account_ID__c) && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('OwnerId',oldLead,l)))){
                l.First_Assignment_Date__c = Datetime.now();//SFDC-4546
            }

            //MARIT-946 acd
            //sync new phone fields with oob phone fields on insert and update of lead and when do not call flag value is true -> false
            if(!Test.isRunningTest() && (l.Phone != null || l.MobilePhone != null )&& ((Util.hasChanges('Phone',oldLead,l) || Util.hasChanges('MobilePhone',oldLead,l) || Util.hasChanges('DoNotCall',oldLead,l)) && !l.DoNotCall)){
                syncNewFromOldPhoneFields.add(l);
            }
            //MARIT-1681 : update E.164 phone fields on insert and update of lead and when do not call flag value is true -> false
            if((Util.hasChanges('Phone_Custom__c',oldLead,l) || Util.hasChanges('MobilePhone_Custom__c',oldLead,l) || Util.hasChanges('Phone',oldLead,l) || Util.hasChanges('MobilePhone',oldLead,l) || Util.hasChanges('DoNotCall',oldLead,l) || Util.hasChanges('Country',oldLead,l)) && !l.DoNotCall) {
                updatePhoneValuesToE164.add(l);
            }
            //sync old fields with new phone fields on insert and update of lead and when do not call flag value is false
            if(((Util.hasChanges('Phone_Custom__c',oldLead,l) && l.Phone_Custom__c!= null) || (Util.hasChanges('MobilePhone_Custom__c',oldLead,l) && l.MobilePhone_Custom__c!= null)) && !l.DoNotCall){
                syncOldFromNewPhoneFields.add(l);
            }
            //When the Do not call flag is set to true below if piece is triggered to blank out custom phone field values
            if(l != null && l.DoNotCall && (l.Phone_Custom__c != null || l.MobilePhone_Custom__c != null || l.E164_Phone__c != null || l.E164_MobilePhone__c != null)){
                removePhoneValuesFromLead.add(l);
            }
            //Validation rule which triggers when the do not call flag is checked and sdr* profiles tries to update the phone field
            if(((l.Phone_Custom__c != null && Util.hasChanges('Phone_Custom__c',oldLead,l)) || (l.MobilePhone_Custom__c != null && Util.hasChanges('MobilePhone_Custom__c',oldLead,l))) && l.DoNotCall){
                String error = MarketingUtilClass.phoneEditValidationErrorWhenDNCIsChecked();
                if(error != null){
                  l.addError(error);  
                }
                
            }

            // logic based on lead record type - MARIT-680
            if(l.RecordTypeId == recordTypeNameToIDMap.get('Marketo Lead')) {
                if((Trigger.isInsert || (Trigger.isUpdate && (DriftProfileId.contains(userinfo.getProfileId()) || Test.isRunningTest()) && !Util.hasChanges('Lead_Qualification_Stage__c',oldLead,l) && l.Lead_Qualification_Stage__c != 'Qualified Lead - Hot' && l.Lead_Qualification_Stage__c != 'Qualified Lead - Warm' )) && l.CQL_Score__c == 3){
                    l.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
                    l.Lead_Qualification_Status__c = 'New';
                }

                if(marketoIntegrationProfileId.contains(UserInfo.getProfileId()) && l.CQL_Score__c ==3 && Util.hasChanges('Lead_Qualification_Stage__c',oldLead,l) && l.Lead_Qualification_Stage__c != 'Qualified Lead - Hot'){
                        l.CQL_Score__c = null;
                }

                /*Common code block for insert and update operation of a marketo lead */
                if(marketoIntegrationProfileId.contains(UserInfo.getProfileId()) && l.Marketo_AKAM_Account_ID__c != null && 
                (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Marketo_AKAM_Account_ID__c',oldLead,l)))){
                    leadListHavingMarketoAkamAccountId.add(l);
                    marketoAkamAccountIdSet.add(l.Marketo_AKAM_Account_ID__c);//SFDC-4384
                }

                if(Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges(stageFieldsQL,oldLead,l))) {
                    l.Highest_Lead_Qualification_Stage__c= LeadUtilClass.updateHighestLeadQualificationStage(stageFieldsQL,l,highest_lowest_QL_Stage);//MARIT-16
                }
                if(Trigger.IsInsert || (Trigger.IsUpdate && Util.hasChanges(bppFields,oldLead,l))){
                    l.Buyer_Pain_Points__c = MARIT_LeadTriggerClass.getEnabledBPPs(bppFields, l);//MARIT-873
                }
                            
                //MARIT-215 - updating/populating marketo lead and c2a lead with account PAO value when new lead created or associated account is changed.
                //TODO : Need to check the method definition, becuase now projection happens at Account level itself so do we really need to re project again or not at lead level.
                if(l.Associated_Account__c != null && (Trigger.isInsert || Trigger.isUpdate && Util.hasChanges('Associated_Account__c' ,oldLead, l))){
                    marketoLeadForProjectedOwnerUpdate.add(l);
                }

                // MARIT-211, if marketo lead insertion has latest campaign Id field then we need to consider this for copy over to latest camapaign akam id
                if(l.Latest_Campaign_Id__c != null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Latest_Campaign_Id__c',oldLead,l)))) {
                    leadToCampaignIdMap.put(l, l.Latest_Campaign_Id__c);
                }

                if(l.email!=null && (Trigger.isInsert || (Trigger.isUpdate && l.Email != oldLead.Email))){
                    checkDuplicateList.add(l);//SFDC-4547
                }
                //MARIT-685
                if((Trigger.isInsert || Trigger.isUpdate) && Util.hasChanges(leadAddressFields,oldLead,l)){
                    relatedRecordAddressCheck.put(l.Id,false);
                    leadsToCheckAddress.add(l);
                }

                if(Trigger.isInsert) {
                    //Marit-2084
                    if(l.Lead_Qualification_Stage__c == null && l.Lead_Qualification_Status__c == null){
                        l.Lead_Qualification_Stage__c = 'Prospect';
                        l.Lead_Qualification_Status__c = 'Prospect';
                    }

                    //MARIT-401
                    MARIT_LeadTriggerClass.copyAddrFieldsToLocalFields(l);
                    if(l.Associated_Account__c == null){
                        l.Associated_Account__c = fetchRequiredMDTs.get('WWWLeadGenAccountIdMarketo');//SFDC-5172
                    }
                    if(l.mkto71_Acquisition_Program__c != null && l.mkto71_Acquisition_Program_Id__c != null){
                        String acquisitionCampaign = l.mkto71_Acquisition_Program__c + String.valueOf(l.mkto71_Acquisition_Program_Id__c);
                        List<SObject> acquisitionLeads;
                        if(acquistionProgramToLeadMap.get(acquisitionCampaign) == null){
                            acquisitionLeads = new List<SObject>();
                        }
                        else{
                            acquisitionLeads = acquistionProgramToLeadMap.get(acquisitionCampaign);
                        }
                        acquisitionLeads.add((SObject)l);
                        acquistionProgramToLeadMap.put(acquisitionCampaign,acquisitionLeads); //MARIT-1071
                        acquistionProgramNames.add(l.mkto71_Acquisition_Program__c);
                        acquistionProgramAkamIds.add('%'+String.valueOf(l.mkto71_Acquisition_Program_Id__c)+'%');
                    }
                }
                else if(Trigger.isUpdate) {
                    //MARIT-1743: Copy over Company_Self_Entered__c to Company when ever its changed
                    if(l != null && Util.hasChanges('Company_Self_Entered__c',oldLead,l) && l.Company_Self_Entered__c != null) {
                        l.Company = l.Company_Self_Entered__c;
                    }
                }
            } else if(l.RecordTypeId == recordTypeNameToIDMap.get('Akamai Lead')) {

                if(l != null && (l.Parent_Lead__c!=null || l.Associated_Contact__c!=null) && (l.Status == 'New' || l.Status == 'In Process')) { 
                    if ((Trigger.isInsert || Trigger.isUpdate && (Util.hasChanges('Associated_Contact__c',oldLead,l) || Util.hasChanges('Parent_Lead__c',oldLead,l)))){
                        system.debug(LoggingLevel.ERROR,'leadToPopulatePersonFields:: ');
                        if(l.Associated_Contact__c!=null) {
                            parentCons.add(l.Associated_Contact__c);
                        }
                        if(l.Parent_Lead__c!=null) {
                            parentLeads.add(l.Parent_Lead__c);
                        }
                        leadToPopulatePersonFields.add(l);//SFDC-4546
                    }
                    
                    // all field updates changes except parent record change for CTA will go here - MARIT-1277
                    if (Trigger.isUpdate && (Util.hasChanges('FirstName',oldLead,l) || Util.hasChanges('LastName',oldLead,l))) {
                        if(l.Associated_Contact__c!=null) {
                            parentConsWithCTAFieldUpdates.add(l.Associated_Contact__c);
                        }
                        if(l.Parent_Lead__c!=null) {
                            parentLeadsWithCTAFieldUpdates.add(l.Parent_Lead__c);
                        }
                        leadToPopulatePersonFieldsOnCTAFieldUpdates.add(l);
                    }
                }


                if(l.First_Assignment_Date__c!=null) {
                    system.debug(Logginglevel.ERROR,'l.RecordTypeId:: '+l.RecordTypeId+' l.First_Assignment_Date__c:: '+l.First_Assignment_Date__c);
                    leadToSetInitialSLAs.add(l);//SFDC-5167

                    if(LeadUtilClass.hasPassedBPPStageThreshold(l)){
                        leadToSetSLAs.add(l);//SFDC-4546
                    }
                }

                //Marit-374 Condition to avoid conversion of lead when owned by a queue rather than autoconvert to opportunity
                //MARIT-779 Adding checks before calling get deficiences method, system should check only on the change of fields
                Set<String> BPPStatusFields = fetchStringSetForRequiredMDTs.get('BPPStatusFieldsForLead');
                if(l.RecordTypeId == recordTypeNameToIDMap.get('Akamai Lead') && 
                   ((Util.hasChanges('Status',oldLead,l) && l.Status == 'Converted') || (LeadUtilClass.isBPPStatusConverted(l,oldLead)) )){
                    List<String> errs = LeadConversionHelper.getDeficiencies(l, true, true);
                    if(errs.size() > 0){
                        for(String s : errs){
                            l.addError(s);
                        }
                    }
                }

                //MARIT-687
                if(Trigger.isInsert || Trigger.isUpdate && Util.hasChanges('Associated_Account_Name__c',oldLead,l)) {   
                    leadToUpdateProspectField.add(l);
                }
                //MARIT-685
                if((Trigger.isInsert || Trigger.isUpdate) && Util.hasChanges(leadAddressFields,oldLead,l)){
                    relatedRecordAddressCheck.put(l.Id,false);
                    leadsToCheckAddress.add(l);
                }
                
                if(Trigger.isInsert) {

                    if(DriftProfileId.contains(userinfo.getProfileId())){
                        l.adg_Self_Generated_Lead_Type__c = 'Inbound Chat';
                        l.Primary_Campaign__c = driftCampaign;
                        l.OwnerId = globalCatchAllId;
                    }

                    //MARIT-1014
                    if(l.adg_Self_Generated_Lead_Type__c == 'Marketing List Import'){
                        if(l.Associated_Contact__c != null)
                           {
                               ctaWithPersonCon.put(l.Associated_Contact__c, l);
                               
                           }
                           else if(l.Parent_Lead__c != null)
                           {
                               ctaWithPersonLead.put(l.Parent_Lead__c,l);
                           }
                        
                    }

                    //MARIT-875
                    if(l.Lead_Qualification_Stage__c == null && l.Lead_Qualification_Status__c == null)
                    {
                           if(l.Associated_Contact__c != null)
                           {
                               parentContact.put(l.Associated_Contact__c, l);
                           }
                           else if(l.Parent_Lead__c != null)
                           {
                               parentLead.put(l.Parent_Lead__c, l);
                           }
                    }
                }
                else if(Trigger.isUpdate) {
                    //MARIT-11
                    //TODO: need to check if this logic is need in trigger or moved to lwc as part of 2.0
                    if(l.Self_Gen_Or_Demand_Gen_Formula__c == 'Demand Gen' && Util.hasChanges('Status',oldLead,l) && l.Status != 'New' && l.Status != 'In Process' && !Util.hasChanges(stageFieldsQL,oldLead,l) && !util.hasChanges('Reason_For_Closure__c',oldLead,l) && checkLeadStatusFirstRunFlag){
                        l.addError('Please use the Buyer Journey Status fields in the Demand Gen Summary section to Convert or Close this Lead.');
                        checkLeadStatusFirstRunFlag = false;
                    }

                    //MARIT-1736: To not all status change back to New from In Process
                    if(l != null && Util.hasChanges('Status',oldLead,l) && l.Status == 'New' && oldLead.Status == 'In Process') {
                        l.Status = 'In Process';
                    }

                    //MARIT-448
                    if(Util.hasChanges(statusAndSLAFields,oldLead,l) && (l.Parent_Lead__c != null || l.Associated_Contact__c != null)){
                        List<String> bppStatuses = LeadUtilClass.isBPPStatusClosedConvertedOrTurnBack(l, oldLead);
                        for(String bppStatus: bppStatuses)
                        {
                            LeadUtilClass.updateBPPStatusBasedOnStage(l, bppStatus);
                        }
                    }

                    //MARIT-773
                    if( (Util.hasChanges('status',oldLead,l) || Util.hasChanges('lead_qualification_status__c',oldLead,l)) && ((l.status=='Converted' || (LeadUtilClass.isBPPStatusConverted(l,oldLead)))|| l.status=='Closed')){
                        if(l.Associated_Contact__c != null)
                        {
                            convertedLeadIdWithParentIdMap.put(l.Id, l.Associated_Contact__c);   
                        }
                        else if(l.Parent_Lead__c != null)
                        {
                            convertedLeadIdWithParentIdMap.put(l.Id,l.Parent_Lead__c);
                        }
                        playbooksCopyOverLeadList.add(l);
                    }

                    if(!Util.hasChanges('Associated_Contact__c',oldLead,l) && !Util.hasChanges('Parent_Lead__c',oldLead,l) && !l.Validation_Override__c && !l.Is_Partner_Lead__c && !(fetchRequiredMDTs.get('SystemAdminProfileId').contains(UserInfo.getProfileId())) && (l.Status == 'New' || l.Status == 'In Process')) {
                        addErrorForMissingValue.add(l);
                    }

                    if(l.status!=null && Util.hasChanges('Status',oldLead,l) && (l.status=='Turnback' || l.status=='Closed')){
                        l.RecordTypeId = recordTypeNameToIDMap.get('Converted Lead');//SFDC-4546
                    }

                    if(isLeadConversionAsynModeSet && (l.Status=='Converted' || LeadUtilClass.isBPPStatusConverted(l, oldLead))){
                        //MARIT-671 - C2A conversion address check on marketo lead address or its associated account
                        relatedRecordAddressCheck.put(l.Id,true);
                        leadsToCheckAddress.add(l);
                    }

                }
            }

            else if(l.RecordTypeId == recordTypeNameToIDMap.get('Converted Lead')) {
                if(l.First_Assignment_Date__c!=null) {
                    system.debug(Logginglevel.ERROR,'l.RecordTypeId:: '+l.RecordTypeId+' l.First_Assignment_Date__c:: '+l.First_Assignment_Date__c);
                    leadToSetInitialSLAs.add(l);//SFDC-5167

                    if(LeadUtilClass.hasPassedBPPStageThreshold(l)){
                        leadToSetSLAs.add(l);//SFDC-4546
                    }
                }

                //MARIT-687
                if(Trigger.isInsert || Trigger.isUpdate && Util.hasChanges('Associated_Account_Name__c',oldLead,l)) {   
                    leadToUpdateProspectField.add(l);
                }

                if(Trigger.isInsert) {

                }
                else if(Trigger.isUpdate) {

                }
            }    
        }

        if(leadsToCheckAddress != null && !leadsToCheckAddress.isEmpty()){
            //MARIT-685
            System.debug('In Address Validation for lead');
            MARIT_LeadAddressValidation.validateLeadAddressFields(leadsToCheckAddress,relatedRecordAddressCheck);
        }
        if(marketoLeadForProjectedOwnerUpdate != null && !marketoLeadForProjectedOwnerUpdate.isEmpty()){
            marketoLeadForProjectedOwnerUpdate = LeadToContactConversionClass.ProjectSDRForONALeads(marketoLeadForProjectedOwnerUpdate);
            System.debug('No of person leads with PSO updated/populated:'+marketoLeadForProjectedOwnerUpdate.size());
        }
        
        if(checkDuplicateList != null && !checkDuplicateList.isEmpty())//SFDC-4547
            MARIT_LeadTriggerClass.CheckDuplicates(checkDuplicateList);

        //MARIT-946 acd
        if(removePhoneValuesFromLead != null && !removePhoneValuesFromLead.isEmpty()){
            MARIT_LeadTriggerClass.removePhoneValueWhenDNCFlagIsCheckedLead(removePhoneValuesFromLead,new List<Contact>());
        }
        if(syncNewFromOldPhoneFields != null && !syncNewFromOldPhoneFields.isEmpty()){
            MarketingUtilClass.syncNewPhoneFieldsWithOld(syncNewFromOldPhoneFields, new List<Contact>());
        }
        if(syncOldFromNewPhoneFields != null && !syncOldFromNewPhoneFields.isEmpty()){
            MarketingUtilClass.syncOldPhoneFieldsWithNew(syncOldFromNewPhoneFields, new List<Contact>());
        }
        //MARIT-1681 e164
        if(updatePhoneValuesToE164 != null && !updatePhoneValuesToE164.isEmpty()){
            MARIT_LeadContactUtils.e164PhoneNumberformatting(updatePhoneValuesToE164,'Country');
        }

        if(leadListHavingMarketoAkamAccountId != null && !leadListHavingMarketoAkamAccountId.isEmpty())
            MARIT_LeadTriggerClass.setAssociatedAccountOnLead(leadListHavingMarketoAkamAccountId,new List<String>(marketoAkamAccountIdSet));

        if(leadToPopulatePersonFields != null && !leadToPopulatePersonFields.isEmpty()) {
            boolean isInsertTrigger = false;
            //MARIT-1276, for lattice recommendation only on insert of CTA.
            if (Trigger.isInsert) {
               isInsertTrigger = true;
            }
            LeadToContactConversionClass.populatePersonFields(leadToPopulatePersonFields,parentCons,parentLeads, isInsertTrigger, false);
        }
        //MARIT-1277, send all field updates on CTA
        if(leadToPopulatePersonFieldsOnCTAFieldUpdates != null && !leadToPopulatePersonFieldsOnCTAFieldUpdates.isEmpty()) {
            LeadToContactConversionClass.populatePersonFields(leadToPopulatePersonFieldsOnCTAFieldUpdates,parentConsWithCTAFieldUpdates,parentLeadsWithCTAFieldUpdates, false, true);
        }

        if(leadToSetInitialSLAs != null && !leadToSetInitialSLAs.isEmpty())//SFDC-5167
            MARIT_LeadTriggerClass.setInitialSLAs(leadToSetInitialSLAs);

        if(leadToSetSLAs != null && !leadToSetSLAs.isEmpty())//SFDC-4546
            MARIT_LeadTriggerClass.setSLAs(leadToSetSLAs,Trigger.isUpdate);

        if(addErrorForMissingValue != null && !addErrorForMissingValue.isEmpty())
            LeadToContactConversionClass.addErrorOnLead(addErrorForMissingValue,Trigger.newMap);

        // MARIT-211
        if (leadToCampaignIdMap != null && !leadToCampaignIdMap.isEmpty()) {
            MARIT_LeadTriggerClass.UpdateLatestCampAkamIdFromLatestCampId(leadToCampaignIdMap);
        }

        //MARIT-687
        if(leadToUpdateProspectField != null && !leadToUpdateProspectField.isEmpty()){
            MARIT_LeadTriggerClass.updateProspectCustomerField(leadToUpdateProspectField);
        }

        //MARIT-875
        if((parentContact != null && !parentContact.isEmpty()) || (parentLead != null && !parentLead.isEmpty())){
            LeadToContactConversionClass.updateProspectCtaStageStatus(parentContact,parentLead);
        }

        //MARIT-773
        if((convertedLeadIdWithParentIdMap != null && !convertedLeadIdWithParentIdMap.isEmpty()) || (playbooksCopyOverLeadList!= null && !playbooksCopyOverLeadList.isEmpty())){
            LeadToContactConversionClass.migrateTasks(convertedLeadIdWithParentIdMap);
            LeadToContactConversionClass.playbooksFieldsCopyOverWhenLeadIsConverted(playbooksCopyOverLeadList);
        }

        //MARIT-1014
        if((ctaWithPersonLead != null && !ctaWithPersonLead.isEmpty()) || (ctaWithPersonCon != null && !ctaWithPersonCon.isEmpty())){
            MARIT_LeadTriggerClass.checkIfCTAAlreadyExistsGeneric(ctaWithPersonLead,ctaWithPersonCon);
            MARIT_ContactTriggerClass.checkIfOpenOppExistsWhileInsertingCTA(ctaWithPersonCon);
        }
        //MARIT-1071
        if(!acquistionProgramToLeadMap.isEmpty()){
            MARIT_LeadContactUtils.personAcquistionCampaign(acquistionProgramToLeadMap,acquistionProgramNames,acquistionProgramAkamIds);
        }
    }
    public override void beforeDeleteBeforeUndeleteTrigger() {
        //MARIT-1751 : Can't delete a person record which has an open CTA
        if(Trigger.isDelete) {
            Set<String> ids = new Set<String>();
            Set<String> parentIdswithOpenCTA = new Set<String>();
            for(SObject so: oldList) {
                ids.add(so.Id);
            }
            List<lead> openC2ALeads = [Select id,Parent_Lead__c from Lead where Parent_Lead__c in :ids and status in ('New', 'In Process')];
            for(lead l: openC2ALeads) {
                parentIdswithOpenCTA.add(l.Parent_Lead__c);
            }
            for(SObject so: oldList) {
                if(parentIdswithOpenCTA.contains(so.Id)) {
                    so.addError('Please action the open CTA before performing a delete/merge operation on the Person Lead');
                }
            }
        }
    }
    public override void afterInsertAfterUpdateTrigger() {
        Map<Id, Id> marketoLeadIdToAssociatedAccountId = new Map<Id, Id>();
        List<Lead> leadsInsertedWithPrimaryCampaign = new List<Lead>();
        Set<Id> createAkamaiLeadIdSet = new Set<Id>();
        List<Lead> personLeadlist = new List<Lead>();
        List<Lead> leadsReassignment = new List<Lead>(); //SFDC-4547-5
        Map<Id, Boolean> leadIdToForceRunMap = new Map<Id, Boolean>(); //MARIT-339
        List<Lead> leadsforAutoConversion = new List<Lead>();
        List<Lead> leadsWithAssociatedAccountOnInsert = new List<Lead>();
        Set<Id> closedCampaignIds = new Set<Id>();
        Boolean skipAlreadyConvertedLeads=false;
        Set<Id> leadsToBeConvertedManually = new Set<Id>();
        String marketoUserAlias = fetchRequiredMDTs.get('MarketoAPIUserAliases');
        Set<String> fieldsToBeChecked = GSMSettings.getSetOfStrings('LeadAutoConversionFieldsToBeChecked');
        Set<String> leadAssignmentfieldsToBeChecked = GSMSettings.getSetOfStrings('LeadAssignmentRuleFieldsToBeChecked');//SFDC-4547-9
        // MARIT-142
        List<Lead> reassginedOwnerLeadList = new List<Lead>();
        //MARIT-214 created by nagarajg
        Set<Id> updatedMarketoLeads = new Set<ID>();
        Map<Id,Lead> oldLeadMap = new Map<Id,Lead>();
        Map<Id,Lead> newLeadMap = new Map<Id,Lead>();
        List<String> marketoC2ASyncFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('marketoC2ASyncFields');
        marketoC2ASyncFields = String.join(marketoC2ASyncFields,',').split('\\s*,\\s*');
        Set<String> marketoC2ASyncFieldsSet = new Set<String>(marketoC2ASyncFields);
        Map<Id, Id> mLeadToAccForContactCreation = new Map<Id, Id>();
        Map<Id, Boolean> marketoLeadIDToOppCreationCheck = new Map<Id, Boolean>(); //MARIT-609
        //MARIT-553 changed c2aLeads from List to Set and created a map for old leads <id,Lead> and custom metadata for c2a
        //to person lead sync
        Set<Lead> c2aLeads = new Set<Lead>();
        Map<Id, Lead> oldLeadC2AToPerson= new Map<Id,Lead>();
        List<String> C2APersonLeadSyncField = MarketingUtilClass.getMarketingSettingsValue('C2APersonLeadSyncFields').split(',');
        Set<String> c2aSyncField = new Set<String>();//MARIT-0000
        String leadAutoConvertRuleLogicExecution = MarketingUtilClass.getMarketingSettingsValue('LeadAutoConvertRuleLogicExecution'); //MARIT-1108
        String driftAlias = MarketingUtilClass.getMarketingSettingsValue('DriftAlias');
        Map<Id,Id> ctaForTaskReassignment = new Map<Id,Id>();

        //MARIT-487
        //Create a List of Leads to Update after all functions modify the different leads
        Map<String,Lead> leadMap = new Map<String,Lead>();
        List<Lead> toPerformDML = new List<Lead>();
        
        //MARIT-543
        Boolean asyncModeForLeadConversion = false; //set true for manual lead conversion
        Boolean autoConversionFlag = false;
        Boolean contactCreationErrors = false; //to avoid addError being called on same lead multiple times
        
        Set<String> statusFields = fetchStringSetForRequiredMDTs.get('BPPStatusFieldsForLead');
        Set<String> stageFields = fetchStringSetForRequiredMDTs.get('BPPStageFieldsForLead');
        Set<String> slaFields = fetchStringSetForRequiredMDTs.get('BPPSLAs');
        
        c2aSyncField.addAll(C2APersonLeadSyncField);
        
        for(SObject so: newList)
        {
            Lead l = (Lead)so;
            Lead oldLead = null;
            
            if(Trigger.isUpdate){
                oldLead = (Lead)oldMap.get(l.Id);                
            }
            
            if(l.Donot_run_Trigger__c == true || (leadIdTofirstRunFlagMap.containsKey(l.id) && leadIdTofirstRunFlagMap.get(l.id))){
                leadIdTofirstRunFlagMap.put(l.id, true);
                continue;
            }else{
                leadIdTofirstRunFlagMap.put(l.id, false);
            }
            String ownerId = l.OwnerId;
            
            if(l.recordTypeId == recordTypeNameToIDMap.get('Marketo Lead')){
                //Camapign Member creation based on Campaign, please check at the time of conversion. -------- future call
                if(Trigger.isInsert && l.Primary_Campaign__c != null){
                    leadsInsertedWithPrimaryCampaign.add(l);
                }
                //Marketo Lead manual conversion
                if(Trigger.isUpdate && oldLead.status!='Converted' && l.Status=='Converted' && l.Associated_Opportunity__c==null && l.Convert_to_Opportunity__c!=true && l.Associated_Account__c!=null && l.IsConverted==false){
                    marketoLeadIdToAssociatedAccountId.put(l.Id, l.Associated_Account__c);
                    marketoLeadIDToOppCreationCheck.put(l.id, true);
                    System.Debug(LoggingLevel.Error, 'Mayank, Marketo Lead Manual Conv:'+l.Id);
                }
                //Marketo Lead Auto conversion
                //MARIT-933 : Marketo lead to contact conversion on account change from www lead gen
                else if(l.IsConverted == false &&
                        l.Associated_Account__c!=null &&
                        l.Convert_to_Opportunity__c==true &&
                        ((Trigger.isUpdate && l.Convert_to_Opportunity__c!=oldLead.Convert_to_Opportunity__c) || (Trigger.isUpdate && Util.hasChanges('Associated_Account__c',oldLead,l) && oldLead.Associated_Account__c == fetchRequiredMDTs.get('WWWLeadGenAccountIdMarketo')) || (Trigger.isInsert) )) {
                             marketoLeadIdToAssociatedAccountId.put(l.Id,l.Associated_Account__c);
                             marketoLeadIDToOppCreationCheck.put(l.id, true);
                             System.Debug(LoggingLevel.Error, 'Mayank, Marketo Lead Auto Conv:'+l.Id);
                }
                //Only Marketo to Contact creation through Marketo_Convert_to_Contact__c flag MARIT-265
                //MARIT-933 : Marketo lead to contact conversion on account change from www lead gen
                else if ((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Marketo_Convert_to_Contact__c',oldLead,l)) || (Trigger.isUpdate && Util.hasChanges('Associated_Account__c',oldLead,l) && oldLead.Associated_Account__c == fetchRequiredMDTs.get('WWWLeadGenAccountIdMarketo')))
                        && l.Associated_Account__c !=null && l.Associated_Contact__c == null && l.IsConverted == false && l.Marketo_Convert_to_Contact__c == true) {
                             marketoLeadIdToAssociatedAccountId.put(l.Id, l.Associated_Account__c);
                             if((Trigger.IsInsert && LeadUtilClass.hasPassedBPPStageThreshold(l)) || (Trigger.isUpdate && LeadUtilClass.hasPassedBPPStageThreshold(l, oldLead)) || (Trigger.isUpdate && Util.hasChanges('Associated_Account__c',oldLead,l) && oldLead.Associated_Account__c == fetchRequiredMDTs.get('WWWLeadGenAccountIdMarketo') && LeadUtilClass.hasPassedBPPStageThreshold(l))){
                                 marketoLeadIDToOppCreationCheck.put(l.id, true);
                             } else{
                                 marketoLeadIDToOppCreationCheck.put(l.id, false);
                             }
                             System.Debug(LoggingLevel.Error, 'Mayank, Only Marketo Lead Manual Conv:'+l.Id);
                         }
                //Just C2A creation from Marketo Lead on passing threshold --------- This update should be handled as merged framework
                else if(((Trigger.isInsert && LeadUtilClass.hasPassedBPPStageThreshold(l))
                         || (Trigger.isUpdate && LeadUtilClass.hasPassedBPPStageThreshold(l, oldLead)))
                        && l.convert_to_opportunity__c == false && l.status != 'Converted'){
                            System.Debug(LoggingLevel.Error, 'Mayank, in createAkamaiLeadIdSet parent_lead:'+l.Parent_Lead__c+'and rtypeid'+l.RecordTypeId);
                            createAkamaiLeadIdSet.add(l.Id);
                        }
                //Copy over from marketo to C2A sync FirstName,LastName,Email,Phone,Associated_Account__c,Title,DoNotCall,HasOptedOutOfEmail,MobilePhone
                //Should be done in future call
                else if(Trigger.isUpdate && Trigger.isAfter && Util.hasChanges(marketoC2ASyncFieldsSet,oldLead,l)){
                    updatedMarketoLeads.add(l.Id);
                    oldLeadMap.put(l.Id,oldLead);
                    newLeadMap.put(l.Id,l);
                    System.debug('Marketo Lead is updated. Id = ' +l.Id);
                    
                }
                //NEED TO MERGE WITH ABOVE COPY OVER AND WILL SAVE ONE QUERY AND UPDATE
                if(Trigger.isUpdate && (Util.hasChanges(stageFields,oldLead,l) || Util.hasChanges(statusFields,oldLead,l))){
                    personLeadlist.add(l);
                }
            }else if(l.recordTypeId == recordTypeNameToIDMap.get('Akamai Lead')){
                //Copy over future calls have issue that it will keep on running.
                if(Trigger.IsInsert){
                    //Lead Auto Convert Source but the condition is too simple and will always run on Insert, check with business on this
                    //Might move this to before trigger
                    //if below condition passes, no need to check for lead reassignment condition as at the end it will call.
                    //We should cexclude WWW lead gen Accs from below one
                    //We are doing this at insert of C2A, so autoconvertrule field will be updated that time only. So in conversion we should not do again.
                    if(l.Associated_Account__c != null){
                        Lead leadRecord = new Lead(Id=l.Id,Parent_Lead__c=l.Parent_Lead__c,Reassigned_By__c=UserInfo.getName());
                        leadsWithAssociatedAccountOnInsert.add(leadRecord);
                    }
                    //Check with business if on update do we need to run Reassigment rules
                    if((l.Status == 'New' || l.Status == 'In Process') && (l.Parent_Lead__c != null || l.Associated_Contact__c != null) && !l.isC2ABySDR__c){
                        Lead leadRecord = new Lead(Id=l.Id,Parent_Lead__c=l.Parent_Lead__c,Reassigned_By__c=UserInfo.getName());
                        leadsReassignment.add(leadRecord);
                        leadIdToForceRunMap.put(leadRecord.id, false);
                    }
                    // assign task to open cta if was created by drift in last 10 minutes
                    if(l.AKAM_Modified_By__c == driftAlias || Test.isRunningTest()){
                        if(l.Associated_Contact__c != null){
                            ctaForTaskReassignment.put(l.Associated_Contact__c,l.Id);
                        }else if(l.Parent_Lead__c != null){
                            ctaForTaskReassignment.put(l.Parent_Lead__c,l.Id);
                        }
                    }
                }else if(Trigger.IsUpdate){
                    //Conversion Process
                    //Akamai Lead Manual Conversion for demand gen------Need to handle copy over process
                    if(l.Parent_Lead__c != null && l.Associated_Account__c!=null && LeadUtilClass.isBPPStatusConverted(l,oldLead)){
                        skipAlreadyConvertedLeads=true;
                        asyncModeForLeadConversion = true;   //set true since its a manual conversion
                        marketoLeadIdToAssociatedAccountId.put(l.Parent_Lead__c,l.Associated_Account__c);
                        leadsToBeConvertedManually.add(l.id);
                        marketoLeadIDToOppCreationCheck.put(l.Parent_Lead__c, true);
                        System.Debug(LoggingLevel.Error, 'Mayank,Parent = marketo lead,Akamai Lead Manual Conv Demand:'+l.Id);
                    }
                    //Akamai Lead Auto Conversion
                    else if(Util.hasChanges(fieldsToBeChecked, oldLead, l) &&
                            (l.Parent_Lead__c!=null || l.Associated_Contact__c!=null) && l.Associated_Account__c != fetchRequiredMDTs.get('WWWLeadGenAccountIdMarketo') &&
                            l.OwnerId == fetchRequiredMDTs.get('LeadAutoConvert_QueueId')){
                                Lead leadRecord = new Lead(Id=l.Id,Parent_Lead__c=l.Parent_Lead__c);
                                leadsforAutoConversion.add(leadRecord);
                                autoConversionFlag = true;
                                System.Debug(LoggingLevel.Error, 'Mayank, Akamai Lead Auto Conv:'+l.Id);
                    }
                    //Akamai lead manual conversion whose parent = contact
                    else if(l.Associated_Account__c!=null && LeadUtilClass.isBPPStatusConverted(l,oldLead)){
                        leadsToBeConvertedManually.add(l.id);
                        asyncModeForLeadConversion = true;   //set true since its a manual conversion
                        System.Debug(LoggingLevel.Error, 'Mayank,Parent = contact,Akamai Lead Manual Conv Demand:'+l.Id);
                    }
                    //Non-Conversion process
                    else{
                        //Reassignment Rules conditional run Fields: Associated_Account__c,adg_Projected_Account_Owner__c,Parent_Lead__c,Convert_to_Opportunity__c, Primary_Campaign__c
                        if((l.Status == 'New' || l.Status == 'In Process') && (l.Parent_Lead__c != null || l.Associated_Contact__c != null) && 
                           Util.hasChanges(leadAssignmentfieldsToBeChecked, oldLead, l) && 
                           !(oldLead.Convert_to_Opportunity__c==true && l.Convert_to_Opportunity__c==false)){
                               Lead leadRecord = new Lead(Id=l.Id,Parent_Lead__c=l.Parent_Lead__c,Reassigned_By__c=UserInfo.getName());
                               leadsReassignment.add(leadRecord);
                               leadIdToForceRunMap.put(leadRecord.id, true);//MARIT-339
                           } 
                        //Reassignment Rules conditional run for campaign
                        else if((l.Status == 'New' || l.Status == 'In Process') && (l.Parent_Lead__c != null || l.Associated_Contact__c != null) && 
                                l.Primary_Campaign__c!=oldLead.Primary_Campaign__c && oldLead.Primary_Campaign__c==null && marketoUserAlias.contains(l.AKAM_Created_By__c)){
                                    Lead leadRecord = new Lead(Id=l.Id,Parent_Lead__c=l.Parent_Lead__c,Reassigned_By__c='SYSTEM');
                                    leadsReassignment.add(leadRecord);
                                    leadIdToForceRunMap.put(leadRecord.id, false);
                                }
                        //Copy over from C2A to person record on BPP Status, SLA fields, Street, City, State, Country, PostalCode
                        //check if we are not doing redundant update, Check if this condition is required on 
                        //Should be done as part of future call
                        if(Trigger.isUpdate && (Util.hasChanges(statusFields,oldLead,l) || Util.hasChanges(slaFields,oldLead,l) || Util.hasChanges(c2aSyncField,oldLead,l))
                           && (l.Associated_contact__c!=null || l.Parent_Lead__c!=null)){
                               oldLeadC2AToPerson.put(oldLead.Id, oldLead);
                               c2aLeads.add(l);
                           }
                        //Create Chatter record when Owner changes to a User ------- Need to move in reassignment code as well
                        if(checkLeadOwnerIdFirstRunFlag && Trigger.isUpdate && Util.hasChanges('OwnerId',oldLead,l) && ownerId.startsWith('005')
                           && (l.Status == 'In Process' || l.Status == 'New')) {
                               reassginedOwnerLeadList.add(l);
                               checkLeadOwnerIdFirstRunFlag = false;
                           }
                    }
                }
            }else if(l.recordTypeId == recordTypeNameToIDMap.get('Converted Lead')){
                //REMOVE BELOW CONDITION AND HANDLE IT AS PART OF CONVERSION
                if(Trigger.isUpdate && (Util.hasChanges(statusFields,oldLead,l) || Util.hasChanges(slaFields,oldLead,l))
                   && (l.Associated_contact__c!=null || l.Parent_Lead__c!=null)){
                       oldLeadC2AToPerson.put(oldLead.Id, oldLead);
                       c2aLeads.add(l);
                   }
            }
            
            //NOT SURE WHETHER IT'S FOR MARKETO OR AKAMAI LEAD.... KEEPING IT OUT UNTIL CONFIRMATION
            if(Trigger.isUpdate && l.Status == 'Closed' && Util.hasChanges('Status' ,oldLead, l)) {
                closedCampaignIds.add(l.Primary_Campaign__c);
            }
            
        }
        
        // MARIT-142
        if (reassginedOwnerLeadList != null && !reassginedOwnerLeadList.isEmpty()) {
            MARIT_LeadTriggerClass.postChatterOnLeadOwner(reassginedOwnerLeadList);
        }
        //MARIT-214 created by nagarajg
        if(updatedMarketoLeads != null && !updatedMarketoLeads.isEmpty()){
            System.debug('Updating C2A Lead');
            leadMap = LeadToContactConversionClass.updateC2ALeadFromMarketoLead(updatedMarketoLeads,oldLeadMap,newLeadMap,leadMap);
            updatedMarketoLeads.clear();
            oldLeadMap.clear();
            newLeadMap.clear();
        }

        //MARIT-553 added old lead map parameter to the method updatePersonContactOrLeadFromC2ALead
        if(c2aLeads != null && !c2aLeads.isEmpty()){
            List<Lead> c2aLead = new List<Lead>(c2aLeads);
            LeadToContactConversionClass.updatePersonContactOrLeadFromC2ALead(c2aLead,oldLeadC2AToPerson);
            oldLeadC2AToPerson.clear();
            c2aLead.clear();
            c2aLeads.clear();
        }

         if(ctaForTaskReassignment != null && !ctaForTaskReassignment.isEmpty()){
            MARIT_LeadTriggerClass.assignTaskToOpenCTA(ctaForTaskReassignment);
        }
        
        //MARIT-609 Single call for all kind of Marketo Lead to Contact conversion
        if(marketoLeadIdToAssociatedAccountId != null && !marketoLeadIdToAssociatedAccountId.isEmpty() && !(asyncModeForLeadConversion && isLeadConversionAsynModeSet && !autoConversionFlag)){
            String errorMsg = LeadToContactConversionClass.convertLeadsToContacts(marketoLeadIdToAssociatedAccountId, skipAlreadyConvertedLeads, marketoLeadIDToOppCreationCheck);
            System.Debug(LoggingLevel.Error, 'Mayank, Called Contact Conve:'+marketoLeadIDToOppCreationCheck.keySet());
            System.debug('marketo lead to contact via marketo_lead_to_contact flag::'+errorMsg);
            if(errorMsg != null && !contactCreationErrors){
                contactCreationErrors = true;
                MARIT_LeadTriggerClass.addErrorOnLead((List<Lead>) Trigger.newMap.values(),errorMsg);
            }
        }
        
        if(leadsInsertedWithPrimaryCampaign != null && !leadsInsertedWithPrimaryCampaign.isEmpty())
            LeadTriggerClassWithoutSharing.createCampaignMemberbasedOnPrimaryCampaign(leadsInsertedWithPrimaryCampaign);
        
        if(createAkamaiLeadIdSet != null && !createAkamaiLeadIdSet.isEmpty()){
            System.debug(LoggingLevel.Error,'AGH_D before calling createAkamaiLeadIdSet');
            LeadToContactConversionClass.createOrUpdateAkamaiLeads(createAkamaiLeadIdSet, true, Trigger.newMap, Trigger.oldMap);//MARIT-735
        }
        
        //MARIT-487 Adding to lead update list through map
        if(personLeadlist != null && !personLeadlist.isEmpty()) {
            leadMap = LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLead(new List<Contact>(), personLeadlist,leadMap);
        }
        
        if(leadsWithAssociatedAccountOnInsert != null && !leadsWithAssociatedAccountOnInsert.isEmpty() && (leadAutoConvertRuleLogicExecution.equalsIgnoreCase('TRUE') || Test.isRunningTest())){
            leadsWithAssociatedAccountOnInsert = LeadConversionHelper.populateAutoConvertSource(new Map<Id, Sobject>(leadsWithAssociatedAccountOnInsert).keyset());
            for (Integer i=leadsWithAssociatedAccountOnInsert.size()-1;i>=0;i--) {
                if (leadsWithAssociatedAccountOnInsert[i].Auto_Convert_Source__c!='Lead Auto Convert rule') {
                    leadsWithAssociatedAccountOnInsert.remove(i);
                }
            }
            if(leadsWithAssociatedAccountOnInsert != null && !leadsWithAssociatedAccountOnInsert.isEmpty()){
                update leadsWithAssociatedAccountOnInsert;
                leadsReassignment.addAll(leadsWithAssociatedAccountOnInsert);
            }
        }
        
        if (leadsReassignment != null && !leadsReassignment.isEmpty())
            LeadTriggerClass.runLeadReassignmentRules(leadsReassignment, leadIdToForceRunMap);
        
        //MARIT-0000 Moving down to leadsWithAssociatedAccountOnInsert condition
        if(leadsforAutoConversion != null && !leadsforAutoConversion.isEmpty()) {
            LeadTriggerClass.setConverted(leadsforAutoConversion);
            LeadConversionHelper.runConversion((new Map<Id,SObject>(leadsforAutoConversion)).keySet(), false);
        }
        
        //MARIT-487 Final Update statement for all leads
        toPerformDML = leadMap.values();
        System.debug('IDs of Final List of Leads'+ leadMap.keyset());
        System.debug('Final List of Leads to Update:' + toPerformDML);
        if (toPerformDML != null && !toPerformDML.isEmpty()) {
            LeadToContactConversionClass.upsertLeads(toPerformDML); //MARIT-566
        }
        
        System.debug('CHECK FLAGS: asyncModeForLeadConversion:'+asyncModeForLeadConversion+',isLeadConversionAsynModeSet:'+isLeadConversionAsynModeSet+',autoConversionFlag:'+autoConversionFlag);
        if(leadsToBeConvertedManually != null && !leadsToBeConvertedManually.isEmpty()){
            System.Debug(Logginglevel.Error, 'AGH_D now trying manual conversion');
            Map<Id, List<String>> leadIdToErrors;
            if(isLeadConversionAsynModeSet && asyncModeForLeadConversion && !autoConversionFlag){
                //Async Lead Manual Conversion
                leadIdToErrors = LeadConversionHelper.runAsyncLeadConversion(leadsToBeConvertedManually, true);//MARIT-987
                System.debug('In Async Mode');
            }
            else{
                //Synchronous Lead Manual Conversion
                leadIdToErrors = LeadConversionHelper.runConversion(leadsToBeConvertedManually, true);
                System.debug('In Sync Mode');
            }
            if(leadIdToErrors != null && !leadIdToErrors.isEmpty() && !contactCreationErrors){
                for(Id leadId: leadIdToErrors.keySet()){
                    Lead triggerLead = (Lead) Trigger.newMap.get(leadId);
                    String str = null;
                    Integer count = 1;
                    if(leadIdToErrors.containsKey(leadId)){
                        for(String s: leadIdToErrors.get(leadId)){
                            if(str == null){
                                str = ' ' + count + '. ' + s;
                            } else{
                                str = str + ' '+ count + '. ' + s;
                            }
                            count++;
                        }
                        triggerLead.addError(str,false);
                    }
                }
            }
        }
        System.debug('Mayank, CPU time :'+Limits.getCpuTime());
        System.debug('Mayank, Query count till now :'+Limits.getQueries()); 
    }
    
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}