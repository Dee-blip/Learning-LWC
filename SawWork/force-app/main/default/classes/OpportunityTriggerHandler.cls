/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-08-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-08-2021   apyati   Reverted change done for SFDC-8121 
**/
public without sharing class OpportunityTriggerHandler extends ApexTriggerHandlerAbstractClass{


    public static String amgOppRecordType;
    public static Map<ID,Schema.RecordTypeInfo> rt_Map;
    public static Id akamaiOppRecordTypeId,adminOppRecordTypeId,closedOppRecordTypeId;
    public static List<Id> dealRegRecordTypeIds = new List<Id>();
    public static Profile currentUserProfile;
    public static Map <String, Object> objectToFieldMap = new Map <String, Object>();
    public static Boolean objectToFieldMapFirstRunFlag = true;
    public static boolean runZoffonce = true ; // Rajesh - SFDC-7061
    public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');  //Rajesh || SFDC-7061


    public OpportunityTriggerHandler()
    {
        amgOppRecordType  = dataClassHandlerObj.amgOppRecordType;
        rt_Map = dataClassHandlerObj.oppty_rt_Map;
        closedOppRecordTypeId = dataClassHandlerObj.getRecordTypeInfoByName('Closed Opportunity');
        akamaiOppRecordTypeId = dataClassHandlerObj.getRecordTypeInfoByName('Akamai Opportunity');
        adminOppRecordTypeId = dataClassHandlerObj.getRecordTypeInfoByName('Administrative Opportunity');
        dealRegRecordTypeIds.add(dataClassHandlerObj.getRecordTypeInfoByName('Deal Reg Submitted'));
        dealRegRecordTypeIds.add(dataClassHandlerObj.getRecordTypeInfoByName('Deal Reg Unsubmitted'));
        dealRegRecordTypeIds.add(dataClassHandlerObj.getRecordTypeInfoByName('Deal Reg Rejected'));
        currentUserProfile = dataClassHandlerObj.currentUserProfile;
    }





    public override void beforeInsertBeforeUpdateTrigger()
    
    {

        Map<Opportunity,Id> zoffapprChangedoppty = new Map<Opportunity,Id>() ; //Rajesh - SFDC-7061
        Map<Opportunity,id> zoffemailListoppty = new Map<Opportunity,id>(); //Rajesh - SFDC-7061
        Map<Opportunity,id> zoffapprrejectList = new Map<Opportunity,Id>(); //Rajesh - SFDC-7061
        Map<opportunity, id> sendEmailForMediaVertZoff = new Map<opportunity, id>();
        //Cast entire collection to Opportunity sObject type collection- Maps and Lists

        List<Opportunity> opptyTriggerNew = (List<Opportunity>)newList;
        List<Opportunity> opptyTriggerOld = (List<Opportunity>)oldList;
        Map<Id,Opportunity> opptyTriggerNewMap = (Map<Id,Opportunity>)newMap;
        Map<Id,Opportunity> opptyTriggerOldMap = (Map<Id,Opportunity>)oldMap;
        List<Opportunity> populateChannelLevelList = new List<Opportunity>();
        //SFDC-3545
        List<Opportunity> oppIdListForContactRole = new List<Opportunity>();
        //SFDC-3547
        List<Opportunity> oppIdListForOrderApproval = new List<Opportunity>();
        String akamaiRecTypeId= dataClassHandlerObj.getRecordTypeInfoByName('Akamai Opportunity');//GSMSettings.getValue('RecordTypeAkamaiOpportunity');
        //SFDC-3261
        String closedRecTypeId= dataClassHandlerObj.getRecordTypeInfoByName(GSMUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type'));
        //Map<ID,Schema.RecordTypeInfo> rt_Map = dataClassHandlerObj.oppty_rt_Map;//Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();
        //String amgOppRecordType  = dataClassHandlerObj.amgOppRecordType;//GsmUtilClass.getGSMSettingValue('OppTrigger_bi_amgOppRecordType'); //[select Id, Value__c from GSM_Settings__mdt where DeveloperName = 'OppTrigger_bi_amgOppRecordType'].Value__c;
        system.debug('Static variable '+amgOppRecordType);
        List<Opportunity> opportunityShifteddateToBeUpdated = new List<Opportunity>();

        List<Opportunity> opportunityStatusToBeUpdated = new List<Opportunity>();

        // SFDC-1337
        List<Opportunity> opptyWithRejectedDealRegStatus = new List<Opportunity>();

        Set<Id> oppIdSet = new Set<Id>();

        //SFDC-1435
        Set<Opportunity> changedoppSet = new Set<Opportunity>();
        Set<String> changedFieldName = new Set<String>();
        List<Opportunity> renewalOpptyList = new List<Opportunity>();

        list<Opportunity> NewAcclist = new List<Opportunity>();
        list<Opportunity> acclist = new List<Opportunity>();
        list<Opportunity> AddTochannelMappingList = new List<Opportunity>();
        list<Opportunity> DealSubmittedList = new List<Opportunity>();
        list<Opportunity> DealApprovedList = new List<Opportunity>();
        // SFDC-9133
        List<Opportunity> closedWonDR = new List<Opportunity>();
                    List<Opportunity> oppList = new List<Opportunity>();
        List<Opportunity> fcmUpdateList = new List<Opportunity>();
        Set<Id> channelMappingIds = new Set<Id>();

        Map<Id,Opportunity> showErrorWhenRemovingOpptyCategoryMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> removeOpptyCategoryMap = new Map<Id,Opportunity>();
        //List<Opportunity> listOfOpportunitiesWithChangedStage = new List<Opportunity>();
        List<Opportunity> contractReviewedChange = new List<Opportunity>();
        Set<Opportunity> setOfOpptysForUSDConversion = new Set<Opportunity>();
        //SFDC-5991
        Set<Id> subresList = new Set<Id>();

        Boolean fCMFeatureRunFlag = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UpdateChannelManagerToOpptySalesTeam') == true; //SFDC-2304

        //SFDC-2130
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,opptyTriggerNew);
        OpportunityTriggerClass.ManageForecastCategory(opptyTriggerNew,opptyTriggerOldMap,opptyTriggerNewMap);
        OpportunityForecastingTriggerClass.ManageDPMForecast(opptyTriggerNew,opptyTriggerOldMap,opptyTriggerNewMap);
        OpportunityTriggerClass.ManagePartnerForecast(opptyTriggerNew, opptyTriggerOldMap, opptyTriggerNewMap);
        //SFDC-3550
        List<String> administrativeOpportunityTypes = GsmUtilClass.getGSMSettingValue('AdministrativeOpportunityTypes').split(',');
        List<String> salesOpportunityTypes = GsmUtilClass.getGSMSettingValue('SalesOpportunityTypes').split(',');
        //SFDC-3529
        Map<String, Object> stageForecastProbabilityMap = (Map<String, Object>)JSON.deserializeUntyped(GsmUtilClass.getGSMSettingValue('Oppty_Stage_3_4_ForecastProbabilityMap'));
        List<String> opptyStage3And4Forecasts = GsmUtilClass.getGSMSettingValue('OpptyStage3And4Forecasts').split(',');
        //SFDC-3921
        Map<String, Object> oldToNewOpptyStageMap = (Map<String, Object>)JSON.deserializeUntyped(GsmUtilClass.getGSMSettingValue('OldToNewOpptyStageMap'));
        List<String> mulesoftIntegrationUsers = GsmUtilClass.getGSMSettingValue('MulesoftIntegrationUser').split(',');
        /*SFDC- 5392 Removal of Related_trial_opportunity lookup field
        Map<Id,Id> trialToSalesOpptyMap = new Map<Id,Id>();*/
        List<opportunity> oppNewCurrencyList = new List<opportunity>();
        list<id> Accids=new list<id>();
        List<opportunity> UpdateOppCategoryList=new list<opportunity>();
        

        //SFDC-4389
        List<Id> pmaToMoveToInProgress = new List<Id>();
        List<Opportunity> oppyToAddValidationForNonInProgressPMA = new List<Opportunity>();
        //List<Opportunity> autoRenewalSwitchOpptyList = new List<Opportunity>();//SFDC-6398
        Map<Id, List<Opportunity>> stampCustomerProspectAccToOpptyMap = new Map<Id, List<Opportunity>>();
        //Map<id, Opportunity> opptyListToSyncSpecialistField = new Map<Id, Opportunity>(); //SFDC-7772
        Set<Id> specialistCompTeamId = new Set<Id>();
        String drRebateEligibleAccStatus = GsmUtilClass.getPRMSettingValue('DRRebateEligibleAccountDRStatus');
        List<String> rebateEligibleAccStatus = drRebateEligibleAccStatus.split(',');

        for(SObject so: newList)
        {
            Opportunity oppRecNew = (Opportunity)so;
            Opportunity oppRecOld = null;
            //SFDC - 6974
            if(Trigger.isInsert && oppRecNew.AccountId != null){
                //SFDC-7474
                if(oppRecNew.Opportunity_Type__c !='Renewal' && oppRecNew.Opportunity_Type__c !='Auto-Renewal'
                        && oppRecNew.oc_source__c !='Marketplace' && oppRecNew.oc_source__c !='Buy Akamai' 
                        && CreateRenewalOpptyWithMultipleContracts.Opptycurrencycheckflag){
                    Accids.add(oppRecNew.AccountId);
                    oppNewCurrencyList.add(oppRecNew);
                }
                if(stampCustomerProspectAccToOpptyMap.containsKey(oppRecNew.AccountId)){
                    List<opportunity> oppttyyList =  stampCustomerProspectAccToOpptyMap.get(oppRecNew.AccountId);
                    oppttyyList.add(oppRecNew);
                    stampCustomerProspectAccToOpptyMap.put(oppRecNew.AccountId, oppttyyList);
                    }else{
                        List<opportunity> oppNewList = new List<opportunity>();
                        oppNewList.add(oppRecNew);
                        stampCustomerProspectAccToOpptyMap.put(oppRecNew.AccountId, oppNewList);
                    }
            }
            //SFDC-7597
            if(oppRecNew.Opportunity_Type__c != null){
                if('New Logo'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                    oppRecNew.Churn_Risk__c = 'N/A';
                    oppRecNew.EMRI_Risk__c = 'N/A';
                }
                else if('Churn'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                    oppRecNew.Churn_Risk__c = '100%';
                    oppRecNew.EMRI_Risk__c = 'Acct MRR is reduced by > 50%';
                }
                else if('Non-Renewal: Add-On'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                    oppRecNew.Churn_Risk__c = '<50%';
                    oppRecNew.EMRI_Risk__c = 'Acct MRR is Flat/Increase';
                }
                else if('Automated Purchase,Contract Change,POC/Trial,Automated Trial'.ContainsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                    oppRecNew.Churn_Risk__c = '';
                    oppRecNew.EMRI_Risk__c = '';
                }
            }
            
            //SFDC-5991
            if(oppRecNew.SubReseller__c!=null)
                subresList.add(oppRecNew.SubReseller__c);
            if(Trigger.isUpdate)
                oppRecOld=(Opportunity)oldMap.get(oppRecNew.Id);

            /* Start of SFDC-3921 */
            if(oldToNewOpptyStageMap.keySet().contains(oppRecNew.StageName)){
                oppRecNew.StageName = String.valueOf(oldToNewOpptyStageMap.get(oppRecNew.StageName));
            }
            if(mulesoftIntegrationUsers.contains(UserInfo.getUserId()) && (oppRecNew.Opportunity_Type__c == null || oppRecNew.Opportunity_Type__c == '')){
                oppRecNew.Opportunity_Type__c = 'Automated Trial';
            }
            /* End of SFDC-3921 */

            /* Start of SFDC-3550 */
            if(Trigger.isInsert && oppRecNew.Opportunity_Type__c != null && salesOpportunityTypes.contains(oppRecNew.Opportunity_Type__c))
                oppRecNew.RecordTypeId = akamaiOppRecordTypeId;
            if(Trigger.isInsert && oppRecNew.Opportunity_Type__c != null && administrativeOpportunityTypes.contains(oppRecNew.Opportunity_Type__c))
                oppRecNew.RecordTypeId = adminOppRecordTypeId;
            /* End of SFDC-3550 */

            //SFDC-7772 //SFDC-9589
            /*
            if((Trigger.isInsert || (Trigger.isUpdate && (Util.hasChanges(new set<String>{'Opportunity_Category__c','Loss_Reason__c','Loss_Cancellation_Description__c','Competitor__c','Other_Competitor_Name__c','Opportunity_Leader__c','Soha_Specialist__c','CIAM_Specialist__c'},oppRecOld,oppRecNew)))) && (oppRecNew.Soha_Specialist__c != null || oppRecNew.CIAM_Specialist__c != null)){
                opptyListToSyncSpecialistField.put(oppRecNew.id, oppRecNew);
                if(String.isNotBlank(oppRecNew.Soha_Specialist__c)){
                    specialistCompTeamId.add(oppRecNew.Soha_Specialist__c);
                }
                if(String.isNotBlank(oppRecNew.CIAM_Specialist__c)){
                    specialistCompTeamId.add(oppRecNew.CIAM_Specialist__c);
                }

            }*/

            /*  Begin * Rajesh - SFDC-7061 */ //Before insert Update
            if(zoffmdtValue.Feature_Enabled__c){ // Run only when ZOFF is enabled as feature
                    List<String> webVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Web_Vertical_For_ZOFF').split(',');
                List<String> mediaVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Media_Vertical_For_ZOFF').split(',');
                List<String> webSubVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Zoff_Sub_Vetical_For_Web_HighTech').split(',');

                if (Trigger.isInsert) {
                    oppRecNew.ZOFF_Status__c = (('Renewal'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c) || 'Auto-Renewal'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)) /*&& 'Web'.equalsIgnoreCase(oppRecNew.Account_Division__c)*/) ? '' : 'Ineligible'; // If record is new and not renewal and autoreneal then stamp Ineligible
                }
                if(/*runZoffonce &&*/ Trigger.isUpdate){ // avoid update of value in loop because changes from PB/FLow/Workflow

                    List<String> zoffvalidapprType = zoffmdtValue.Opportunity_Type_Appr__c.split(','); // Configurable oppty type for approval.
                    List<String> zoffApprstatus = zoffmdtValue.Approval_Text__c.split(','); // approval status to be configurable

                    // Base condition of ZOFF for Web Vertical
                    if(oppRecNew.RecordTypeId.equals(akamaiRecTypeId) && !oppRecNew.isClosed && !'Azure Marketplace'.equalsIgnoreCase(oppRecNew.Source__c)){
                        if ((webVerticalForZOFF.contains(oppRecNew.Associated_Account_Vertical__c) || (oppRecNew.Associated_Account_Vertical__c == 'High Technology' && webSubVerticalForZOFF.contains(oppRecNew.Associated_Account_Sub_Vertical__c)))){

                            //Prepare validation filter when approval and rejection field is changed
                            if (Util.hasChanges(new Set<String> {
                                    'ZOFF_Approval__c', 'ZOFF_Decision_Reason__c'
                                }, oppRecOld, oppRecNew) && !('Auto-Renewal'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c))) {
                                zoffapprChangedoppty.put(oppRecNew, oppRecNew.Account_OwnerId__c);
                            }

                            //Prepare the list and  submit for approval for renewal and other valid  types
                            if (oppRecNew.ZOFF_Enabled__c && zoffvalidapprType.contains(oppRecNew.opportunity_type__c) && 'No'.equalsIgnoreCase(oppRecNew.ZOFF_Status__c) && String.isnotBlank(oppRecNew.Opt_Out_Reason__c) && ((util.hasChanges('Opt_Out_Reason__c', oppRecOld, oppRecNew) && String.isBlank(oppRecNew.ZOFF_Approval__c)) || ('Resubmitted'.equalsIgnoreCase(oppRecNew.ZOFF_Approval__c) && util.hasChanges('ZOFF_Approval__c', oppRecOld, oppRecNew)))) {
                                if (String.isBlank(oppRecNew.ZOFF_Approval__c)) {
                                    oppRecNew.ZOFF_Approval__c = 'Submitted';
                                }
                                zoffemailListoppty.put(oppRecNew, oppRecNew.Account_OwnerId__c);
                            }

                            //Stamp approver related field once request is approved / approval overriden / rejected
                            System.debug(Util.hasChanges('ZOFF_Approval__c', oppRecOld, oppRecNew) + '@@@@@zoffmdtValue==2==' + oppRecNew.ZOFF_Enabled__c + 'runZoffonce==' + oppRecnew.ZOFF_Approval__c + ':::::' + ZoffUtilClass.listcontainsIgnorcase(zoffvalidapprType, oppRecNew.opportunity_type__c) + '""""' + ZoffUtilClass.listcontainsIgnorcase(zoffApprstatus, oppRecNew.ZOFF_Approval__c));
                            if (oppRecNew.ZOFF_Enabled__c && Util.hasChanges('ZOFF_Approval__c', oppRecOld, oppRecNew) && ZoffUtilClass.listcontainsIgnorcase(zoffvalidapprType, oppRecNew.opportunity_type__c) && ZoffUtilClass.listcontainsIgnorcase(zoffApprstatus, oppRecNew.ZOFF_Approval__c)) {
                                oppRecNew.ZOFF_Decision_By__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName(); // getName() Returns the context user's full name. The format of the name depends on the language preferences specified for the organization.
                                oppRecNew.ZOFF_Decision_Date__c = System.Today(); // @todo : Phase 2 we need to sync from Channel mapping as well as ARR , as well as reverse validation
                                zoffapprrejectList.put(oppRecNew, oppRecNew.Account_OwnerId__c);
                            }
                            //Filter List for Rejection / Re-Submission and Approval 

                        }
                        else if(Util.hasChanges('ZOFF_Status__c', oppRecOld, oppRecNew) && 'Yes'.equalsIgnoreCase(oppRecNew.ZOFF_Status__c) && String.isNotBlank(oppRecNew.Deal_Type__c)){
                            sendEmailForMediaVertZoff.put(oppRecNew, oppRecNew.Account_OwnerId__c);
                        }
                    }
                }
                //runZoffonce = false;
            }
            /*  End * Rajesh - SFDC-7061 */

            /* Start of SFDC-3529 */
            if(Trigger.isInsert || (Trigger.isUpdate && (Util.hasChanges('StageName',oppRecOld,oppRecNew) ||
                    Util.hasChanges('Override_Forecast_Category_With__c',oppRecOld,oppRecNew))))
            {
                if(oppRecNew.StageName == '3. Verify Options' || oppRecNew.StageName == '4. Select Option'){
                    if(oppRecNew.Override_Forecast_Category_With__c == null || !opptyStage3And4Forecasts.contains(oppRecNew.Override_Forecast_Category_With__c)){
                        oppRecNew.Override_Forecast_Category_With__c = 'Pipeline';
                    }
                    oppRecNew.ForecastCategoryName = oppRecNew.Override_Forecast_Category_With__c;
                    oppRecNew.Probability = Integer.valueOf(stageForecastProbabilityMap.get(oppRecNew.StageName+'-'+oppRecNew.Override_Forecast_Category_With__c));
                }
                else{
                    oppRecNew.Override_Forecast_Category_With__c = oppRecNew.ForecastCategoryName;
                }
            }
            /* End of SFDC-3529 */

            //SFDC-4389
            String currentOppRecordtype = rt_Map.get(oppRecNew.RecordTypeId).getName();
            if(currentOppRecordtype.containsIgnoreCase('Deal Reg') && oppRecNew.Partner_Marketing_Activity__c!=null &&(Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Partner_Marketing_Activity__c',oppRecOld,oppRecNew))))
            {
                oppyToAddValidationForNonInProgressPMA.add(oppRecNew);
            }
            /* Start of SFDC-3663 */
            if(Trigger.isUpdate && oppRecNew.Pull_Forward__c && !oppRecNew.IsClosed && !Util.hasChanges('Pull_Forward__c',oppRecOld,oppRecNew) &&
                ((Util.hasChanges('ForecastCategoryName',oppRecOld,oppRecNew) && oppRecNew.ForecastCategoryName != 'Commit') ||
                (Util.hasChanges('CloseDate',oppRecOld,oppRecNew) && ((oppRecNew.CloseDate.Year() < System.Today().Year()) ||
                    (oppRecNew.CloseDate.Year() == System.Today().Year() && oppRecNew.CloseDate.Month() <= System.Today().Month()))))
                )
            {
                oppRecNew.Pull_Forward__c = false;
            }
            /* End of SFDC-3663 */

            /* Start of SFDC-4550 */
            if(Trigger.isUpdate && oppRecNew.PAE_Pull_Forward__c && !oppRecNew.IsClosed && !Util.hasChanges('PAE_Pull_Forward__c',oppRecOld,oppRecNew) &&
                ((Util.hasChanges('Partner_Forecast__c',oppRecOld,oppRecNew) && oppRecNew.Partner_Forecast__c != 'Commit') ||
                (Util.hasChanges('PAE_Close_Date__c',oppRecOld,oppRecNew) && ((oppRecNew.PAE_Close_Date__c.Year() < System.Today().Year()) ||
                    (oppRecNew.PAE_Close_Date__c.Year() == System.Today().Year() && oppRecNew.PAE_Close_Date__c.Month() <= System.Today().Month()))))
                )
            {
                oppRecNew.PAE_Pull_Forward__c = false;
            }
            /* End of SFDC-4550 */

            /* Start of SFDC-3754 */
            if(Trigger.isUpdate && Util.hasChanges('RecordTypeId',oppRecOld,oppRecNew) && oppRecNew.Account_Status__c != null &&
                (oppRecNew.RecordTypeId == akamaiRecTypeId || oppRecNew.RecordTypeId == closedRecTypeId) && oppRecNew.Opportunity_Type__c == null ){
                if(oppRecNew.Account_Status__c.containsIgnoreCase('active') || oppRecNew.Account_Status__c.containsIgnoreCase('inactive'))
                    oppRecNew.Opportunity_Type__c = 'Non-Renewal: Add-On';
                else
                    oppRecNew.Opportunity_Type__c = 'New Logo';
            }
            /* End of SFDC-3754 */

            // Partner Forecast Picklist code
            //SFDC-3831
            String opptyStageToOverride = GSMUtilClass.getGSMSettingValue('opptyStagesForRepsRecTypeChangeToClosed');
            if(opptyStageToOverride.contains(oppRecNew.stageName) || (!oppRecNew.Override_Partner_Forecast__c && oppRecNew.ForecastCategoryName != null &&
                        ((Trigger.isInsert && oppRecNew.Partner_Forecast__c==null) || (!Trigger.isInsert && !oppRecOld.Override_Partner_Forecast__c &&
                            oppRecNew.Partner_Forecast__c != oppRecNew.ForecastCategoryName && oppRecNew.Partner_Forecast__c == oppRecOld.Partner_Forecast__c))))
            {
                oppRecNew.Partner_Forecast__c = oppRecNew.ForecastCategoryName;
                oppRecNew.Override_Partner_Forecast__c = false;
            }

            /* SFDC - 5392 Removal of related_trial_opportunity lookup field
            Start of SFDC-3921
            if(Trigger.isUpdate && oppRecNew.Related_Trial_Opportunity__c != null &&
                Util.hasChanges('Related_Trial_Opportunity__c' ,oppRecOld, oppRecNew) &&
                oppRecNew.Account_Status__c != null &&
                (oppRecNew.RecordTypeId == akamaiRecTypeId || oppRecNew.RecordTypeId == closedRecTypeId))
            {
                if(oppRecNew.Account_Status__c.containsIgnoreCase('active') || oppRecNew.Account_Status__c.containsIgnoreCase('inactive'))
                    oppRecNew.Opportunity_Type__c = 'Add-on';
                else
                    oppRecNew.Opportunity_Type__c = 'New Logo';
                trialToSalesOpptyMap.put(oppRecNew.Related_Trial_Opportunity__c,oppRecNew.Id);
                oppRecNew.Related_Trial_Opportunity__c = null;
            }
             End of SFDC-3921 */

            //SFDC-3545
            Datetime dt = Datetime.valueOf(GsmUtilClass.getGSMSettingValue('OpptyCreatedDateForAgility2'));
            String profileExclusionList = GsmUtilClass.getGSMSettingValue('Gating_Criteria_Profile_Exclusion_List');

            if(Trigger.isUpdate && (oppRecOld.StageName == '1. Identify Need' || oppRecOld.StageName == '2. Explore Options') && (oppRecOld.createdDate > dt) && !oppRecNew.Validation_Override__c &&
                (oppRecNew.StageName == '3. Verify Options' || oppRecNew.StageName == '4. Select Option' || oppRecNew.StageName == '5. Negotiate' || oppRecNew.StageName == '6. Signed' || oppRecNew.StageName == 'Closed Won' || oppRecNew.StageName == 'Closed Contract Ended') &&
                oppRecNew.RecordTypeId == akamaiOppRecordTypeId && (oppRecNew.Opportunity_Type__c == 'New Logo' || oppRecNew.Opportunity_Type__c == 'Non-Renewal: Add-On') && !UserInfo.getUserType().equals('PowerPartner')
                && !profileExclusionList.contains(Userinfo.getProfileId())){
                oppIdListForContactRole.add(oppRecNew);
            }
            //SFDC-3547
            if(Trigger.isUpdate && (oppRecOld.StageName == '1. Identify Need' || oppRecOld.StageName == '2. Explore Options' || oppRecOld.StageName == '3. Verify Options'|| oppRecOld.StageName == '4. Select Option') && !oppRecNew.Validation_Override__c &&
                (oppRecNew.StageName == '5. Negotiate' || oppRecNew.StageName == '6. Signed' || oppRecNew.StageName == 'Closed Won' || oppRecNew.StageName == 'Closed Contract Ended') && oppRecNew.RecordTypeId == akamaiOppRecordTypeId &&
                (oppRecNew.Opportunity_Type__c == 'New Logo' || oppRecNew.Opportunity_Type__c == 'Non-Renewal: Add-On' || oppRecNew.Opportunity_Type__c == 'Renewal' || oppRecNew.Opportunity_Type__c == 'Non-Renewal: Downgrade' || oppRecNew.Opportunity_Type__c == 'Churn')
                && !profileExclusionList.contains(Userinfo.getProfileId())){
                oppIdListForOrderApproval.add(oppRecNew);
            }

            //SFDC-839: AMG Opportunity record types should get excluded from custom validations, hence adding validation override true for AMG Opportunity records.
            if(oppRecNew.RecordTypeId!=null && rt_Map.get(oppRecNew.RecordTypeId).getName()==amgOppRecordType){
                oppRecNew.Validation_Override__c=true;
            }

            if(!Trigger.isInsert)
                {
                    //oppRecOld=(Opportunity)oldMap.get(oppRecNew.Id);

                    //SFDC-839 : set opportunity stage to close admin on rejection of amg opportunity.

                    if(oppRecNew.RecordTypeId != null && rt_Map.get(oppRecNew.RecordTypeId).getName()==amgOppRecordType && Util.hasChanges('AMG_Opportunity_Status__c' ,oppRecOld, oppRecNew) && oppRecNew.AMG_Opportunity_Status__c=='Rejected' )
                        opportunityStatusToBeUpdated.add(oppRecNew);

                    //SFDC-1435
                    if(!oppRecNew.Override_PAE_TCV__c && Util.hasChanges('Override_PAE_TCV__c',oppRecOld,oppRecNew)){
                        oppIdSet.add(oppRecNew.id);
                        changedoppSet.add(oppRecNew);
                        changedFieldName.add('Override_PAE_TCV__c');
                    }

                    if(!oppRecNew.Security_MRR_Override__c && Util.hasChanges('Security_MRR_Override__c',oppRecOld,oppRecNew)){
                        oppIdSet.add(oppRecNew.id);
                        changedoppSet.add(oppRecNew);
                        changedFieldName.add('Security_MRR_Override__c');
                    }
                     if(!oppRecNew.DPM_One_Time_Fee_Override__c && Util.hasChanges('DPM_One_Time_Fee_Override__c',oppRecOld,oppRecNew)){
                        oppIdSet.add(oppRecNew.id);
                        changedoppSet.add(oppRecNew);
                        changedFieldName.add('DPM_One_Time_Fee_Override__c');
                    }
                    //SFDC-1560
                    for(Manage_Forecast_Date_Category_n_Override__mdt manageForecastOverrideSettingsRec : dataClassHandlerObj.listOfManageForecastOverrideSettings){
                        for(String mrrOverrideField : manageForecastOverrideSettingsRec.MRR_override__c.split(',')){
                            system.debug(LoggingLevel.ERROR,'oppRecNew.get(mrrOverrideField): '+oppRecNew.get(mrrOverrideField));
                            if(oppRecNew.get(mrrOverrideField)==false && Util.hasChanges(mrrOverrideField ,oppRecOld,oppRecNew)){
                                oppIdSet.add(oppRecNew.id);
                                changedoppSet.add(oppRecNew);
                                changedFieldName.add(mrrOverrideField);
                            }
                        }

                    }
                    //HC - Chheck with Ruchika on this and ManageDPM Forecast method
                    /*Confirm from Ruchika - if this needs to be removed
                    if(!oppRecNew.Service_MRR_Override_1__c && Util.hasChanges('Service_MRR_Override_1__c' ,oppRecOld,oppRecNew)){
                        oppIdSet.add(oppRecNew.id);
                        changedoppSet.add(oppRecNew);
                        changedFieldName.add('Service_MRR_Override_1__c');
                    }
                    if(!oppRecNew.Service_MRR_Override_2__c && Util.hasChanges('Service_MRR_Override_2__c' ,oppRecOld,oppRecNew)){
                        oppIdSet.add(oppRecNew.id);
                        changedoppSet.add(oppRecNew);
                        changedFieldName.add('Service_MRR_Override_2__c');
                    }
                    */
                    // Start:CR 2689824 - Created/Accepted Date - Marketing needs to record Opptys with Primary Campaign Source and no Associated Lead
                    if(oppRecNew.Associated_Lead__c == null && oppRecOld.CampaignId == null && oppRecNew.CampaignId != null)
                    {
                         oppRecNew.Created_Accepted_Date_Marketing__c = Date.today();

                         //SFDC-2580
                         if(oppRecNew.Tieback_Date__c == null)
                            OpportunityTriggerClass.stampTiebackDateAndEarlyInfluence(oppRecNew);

                         //SFDC-3671

                        if((dataClassHandlerObj.opptySALStage.contains(oppRecNew.StageName) || oppRecNew.StageName == 'Closed Won') || ((oppRecNew.StageName == 'Closed Lost' || oppRecNew.StageName == 'Closed Duplicate') && oppRecNew.Previous_Stage_Name__c != null && (dataClassHandlerObj.opptySALStage.contains(oppRecNew.Previous_Stage_Name__c))) && oppRecNew.SAL_Date__c == null){
                            oppRecNew.SAL_Date__c = Datetime.now();
                        }

                     }

                    //HC should be removed as part of CR 3339201 - to be reviewed
                    /*if( ( Util.hasChanges('AccountId' ,oppRecOld, oppRecNew) || Util.hasChanges('Existing_Opportunity__c' ,oppRecOld, oppRecNew))  && GSM_Custom_Settings__c.getInstance('OpportunityTrg#DealRegRecType').value__c.containsIgnoreCase(rt_map.get(oppRecNew.RecordTypeId).getName()) )
                        oppRecNew.Sales_Rep_Acknowledge__c = False;*/

                    //SFDC - 1427

                        if(Util.hasChanges('Created_Accepted_Date_Marketing__c' , oppRecOld, oppRecNew) && oppRecOld.TAL_DateTime__c == null)
                            {
                                oppRecNew.TAL_DateTime__c   = Datetime.now() ;
                            }

                            //String opptySALStage = GSMSettings.getValue('SAL_Date_Stage_Names');

                            if(Util.hasChanges('StageName' , oppRecOld, oppRecNew) && oppRecOld.StageName == '1. Identify Need' && dataClassHandlerObj.opptySALStage.contains(oppRecNew.StageName) && oppRecNew.SAL_Date__c == null)//SFDC-3539
                            {
                                oppRecNew.SAL_Date__c   = Datetime.now() ;
                            }

                            if(!oppRecOld.isClosed && oppRecNew.isClosed)
                            {
                                oppRecNew.Closed_Datetime__c   = Datetime.now() ;
                            }


                            if(Util.hasChanges('QFA_Accept_Reject_Date__c', oppRecOld, oppRecNew) && oppRecOld.Marketing_Accept_Reject_DateTime__c == null)
                            {
                                oppRecNew.Marketing_Accept_Reject_DateTime__c = Datetime.now();
                            }
                        //SFDC -1427 Ends

                        //HC - Removed this since we can directly pass Trigger.New rather than storing in a different list
                        //FCMlist.add(opp);

                        //if(oppRecNew.RecordTypeId!=OpportunityTriggerClass.adsRecTypeId && oppRecNew.AccountId!=null && Util.hasChanges('AccountId' ,oppRecOld, oppRecNew))
                          if(oppRecNew.RecordTypeId!= dataClassHandlerObj.getRecordTypeInfoByName('ADS Record Type') && oppRecNew.AccountId!=null && Util.hasChanges('AccountId' ,oppRecOld, oppRecNew))

                            {
                                NewAcclist.add(oppRecNew);
                                acclist.add(oppRecNew);
                            }
                            if(oppRecNew.Partner_Involved__c!=null && oppRecNew.FCM__c!=null && Util.hasChanges('FCM__c' ,oppRecOld, oppRecNew))//opp.Partner_Involved__c != Trigger.oldMap.get(opp.id).Partner_Involved__c || opp.FCM__c != Trigger.oldMap.get(opp.id).FCM__c))
                                AddTochannelMappingList.add(oppRecNew);

                            if(Util.hasChanges('Registration_Status__c' ,oppRecOld, oppRecNew) && oppRecNew.Registration_Status__c=='Pending')
                            {
                                    if(oppRecNew.isRebateTCToShow__c=='True')
                                    {
                                        oppRecNew.addError(dataClassHandlerObj.OpportunityTrg_RebateTCError);
                                    }
                                    else
                                        DealSubmittedList.add(oppRecNew);
                            }

                            if(Util.hasChanges('Registration_Status__c' ,oppRecOld, oppRecNew) && oppRecNew.Registration_Status__c=='Approved')
                                DealApprovedList.add(oppRecNew);

                            // SFDC-9133 - Update rebate% based on current date (contract len) when oppty is closed won, if rebate__c is not null then it means partner's no rebate required is false and its a new customer for this oppty 
                            if(Util.hasChanges('StageName' ,oppRecOld, oppRecNew)  && oppRecNew.Deal_Type__c!=null && oppRecNew.Deal_Type__c=='Indirect' &&  rebateEligibleAccStatus!=null && rebateEligibleAccStatus.contains(oppRecNew.Deal_Reg_Account_Status__c) && oppRecNew.Rebate__c!=null && oppRecNew.StageName=='Closed Won' && oppRecNew.Deal_Registration_Approved_Date__c!=null && oppRecNew.Deal_Registration_Approved_Date__c.Year() >=2022){
                                
                                closedWonDR.add(oppRecNew);
                            }

                            if(oppRecNew.Validation_Override__c==false)
                                if((oppRecNew.Opportunity_Category__c == null && oppRecOld.Opportunity_Category__c != null)
                                || (oppRecNew.Loss_Reason__c == null && oppRecOld.Loss_Reason__c != null))
                                showErrorWhenRemovingOpptyCategoryMap.put(oppRecNew.Id,oppRecNew);

                            if(oppRecNew.Validation_Override__c==false)
                                if((Util.hasChanges('Zero_MRR_Amount__c' ,oppRecOld, oppRecNew) && oppRecNew.Zero_MRR_Amount__c !='Zero MRR Contract Ended')
                                || (Util.hasChanges('Churn_No_Paper__c' ,oppRecOld, oppRecNew) && oppRecNew.Churn_No_Paper__c==false)
                                || (Util.hasChanges('StageName' ,oppRecOld, oppRecNew) && oppRecNew.StageName != 'Closed Lost' && oppRecNew.StageName != 'Closed Contract Ended' && oppRecNew.StageName != 'Closed Duplicate'))
                                    removeOpptyCategoryMap.put(oppRecNew.Id,oppRecNew);

                            /*if(oppRecNew.Opportunity_Type__c=='Churn' && Util.hasChanges('StageName' ,oppRecOld, oppRecNew) && (oppRecNew.StageName=='5. Negotiate' || oppRecNew.StageName=='6. Signed') && oppRecNew.Source__c !='Azure Marketplace')//SFDC-3539
                                {
                                    listOfOpportunitiesWithChangedStage.add(oppRecNew);
                                }*/
                            //HC - moved the logic in seperate insert and update
                            //CR 1121880 Update fields from text fields to picklist
                            // Keeping End_Customer_Country__c and End_Customer_Country_Picklist__c in sync
                            if(Util.hasChanges('End_Customer_Country__c' ,oppRecOld, oppRecNew) && oppRecNew.End_Customer_Country__c!=oppRecNew.End_Customer_Country_Picklist__c)
                                oppRecNew.End_Customer_Country_Picklist__c = oppRecNew.End_Customer_Country__c;
                            if(Util.hasChanges('End_Customer_Country_Picklist__c' ,oppRecOld, oppRecNew) && oppRecNew.End_Customer_Country__c!=oppRecNew.End_Customer_Country_Picklist__c)
                                oppRecNew.End_Customer_Country__c = oppRecNew.End_Customer_Country_Picklist__c;

                            //HC - Moved this logic inside update and removed IsUpdate check
                            if (oppRecNew.Deal_Type__c == 'Indirect' && oppRecNew.Opportunity_Type__c == 'Renewal' && Util.hasChanges('Channel_Manager__c' ,oppRecOld, oppRecNew))
                                oppRecNew.Validation_Override__c = true;

                            //HC - Moved this logic inside update and removed IsUpdate check
                            // SFDC-1337  Registration_Status__c
                            if(Util.hasChanges('Registration_Status__c' ,oppRecOld, oppRecNew) && oppRecNew.Registration_Status__c == 'Rejected')
                                opptyWithRejectedDealRegStatus.add(oppRecNew);

                            //HC Removed isUpdate check
                            system.debug('Stage Name Prev '+oppRecOld.StageName);
                            if(Util.hasChanges('StageName', oppRecOld, oppRecNew))
                                {
                                    oppRecNew.Previous_Stage_Name__c = oppRecOld.StageName;
                                    oppRecNew.Last_Stage_Change_Date__c = Date.today();
                                    system.debug('Inside stage change '+oppRecNew.Previous_Stage_Name__c);

                                }
                            //SFDC-4136
                            if(Util.hasChanges('Contract_Accepted_Date__c', oppRecOld, oppRecNew) && oppRecNew.Contract_Accepted_Date__c!=null && oppRecNew.Contract_Reviewed__c==null)
                                {
                                    oppRecNew.Contract_Reviewed__c = Datetime.now();
                                    system.debug('Inside Contract_Accepted_Date__c change '+oppRecNew.Contract_Accepted_Date__c);

                                }
                            if(Util.hasChanges('Contract_Reviewed__c', oppRecOld, oppRecNew) && oppRecNew.Contract_Reviewed__c!=null && oppRecNew.opportunity_type__c != 'Auto-Renewal')
                                {
                                    contractReviewedChange.add(oppRecNew);
                                    system.debug('Inside Contract_Reviewed__c change '+oppRecNew.Contract_Reviewed__c);

                                }
                                //SFDC-6398
                            /*if( (Util.hasChanges('MRR__c', oppRecOld, oppRecNew) || Util.hasChanges('Opportunity_Revenue_Impact__c', oppRecOld, oppRecNew)) && oppRecNew.MRR__c == 0 && oppRecNew.Opportunity_Revenue_Impact__c == 0 && oppRecNew.Auto_Renewal__c == True)
                                {
                                    autoRenewalSwitchOpptyList.add(oppRecNew);
                                }*/

                }


               else if(Trigger.isInsert)
               {
                        //End:CR 2689824 - Created/Accepted Date - Marketing needs to record Opptys with Primary Campaign Source and no Associated Lead
                   if(oppRecNew.Associated_Lead__c == null && oppRecNew.CampaignId !=null){
                        oppRecNew.Created_Accepted_Date_Marketing__c = Date.today();
                        oppRecNew.TAL_DateTime__c = Datetime.now();

                        //SFDC-2580
                        if(oppRecNew.Tieback_Date__c == null)
                            OpportunityTriggerClass.stampTiebackDateAndEarlyInfluence(oppRecNew);
                   }

                        if(oppRecNew.Partner_Involved__c!=null && oppRecNew.FCM__c!=null)
                            AddTochannelMappingList.add(oppRecNew);

                        // Keeping End_Customer_Country__c and End_Customer_Country_Picklist__c in sync
                            oppRecNew.End_Customer_Country__c = oppRecNew.End_Customer_Country_Picklist__c;

                     //SFDC-4668 - Added By Prabhanjan

                    if (oppRecNew.CampaignId != null && (dataClassHandlerObj.opptySALStage.contains(oppRecNew.StageName) || oppRecNew.StageName == 'Closed Won') || (oppRecNew.StageName == 'Closed Lost' || oppRecNew.StageName == 'Closed Duplicate') && oppRecNew.SAL_Date__c == null) {
                        oppRecNew.SAL_Date__c = Datetime.now();

                    }
               }

            //Changes for CR 1760780
            if(oppRecNew.Opportunity_Type__c != null && oppRecNew.Opportunity_Type__c != '' && oppRecNew.Opportunity_Type__c.contains('Renewal'))
                {
                    if(Trigger.isInsert &&
                        ((oppRecNew.Partner_Involved_AKAM_Id__c != null && oppRecNew.Partner_Involved_AKAM_Id__c != '')
                        || (oppRecNew.Renew_Contract_Id_Text__c != null && oppRecNew.Renew_Contract_Id_Text__c != '')))
                        {
                            renewalOpptyList.add(oppRecNew);
                        }
                    if(Trigger.isUpdate &&
                        ((oppRecNew.Partner_Involved_AKAM_Id__c != null && oppRecNew.Partner_Involved_AKAM_Id__c != '' && Util.hasChanges('Partner_Involved_AKAM_Id__c' ,oppRecOld, oppRecNew) )
                        || (oppRecNew.Renew_Contract_Id_Text__c != null && oppRecNew.Renew_Contract_Id_Text__c != '' && Util.hasChanges('Renew_Contract_Id_Text__c' ,oppRecOld, oppRecNew))))
                        {
                            renewalOpptyList.add(oppRecNew);
                        }
                }

            if (oppRecNew.AKAM_Created_Date__c == null)
                oppRecNew.AKAM_Created_Date__c = datetime.now();

            //HC - added !Trigger.isInsert in the condition and added check on size of opportunityShifteddateToBeUpdated

            if ( Trigger.isInsert || (!Trigger.isInsert && Util.hasChanges('AKAM_Created_Date__c' ,oppRecOld, oppRecNew)))
                opportunityShifteddateToBeUpdated.add(oppRecNew);

            //SFDC-1595
            if(oppRecNew.Deal_Type__c!=null && oppRecNew.Deal_Type__c=='Indirect' && oppRecNew.Partner_Involved__c!=null  && ((Trigger.isInsert && !String.isBlank(oppRecNew.GSSM_Key__c))||(Trigger.isUpdate&&Util.hasChanges('GSSM_Key__c',oppRecOld,oppRecNew)))){
                populateChannelLevelList.add(oppRecNew);
              }

            //SFDC-925  Opportunity Order Region must match the Account Finance Region
            //HC - isInsert/Update need not be checked
            //if (Trigger.isInsert || Trigger.isUpdate) {

            //List<Opportunity> oppListForOrderRegionUpdate = new List<Opportunity>();

            //Id akamaiOppRecordTypeId = dataClassHandlerObj.getRecordTypeInfoByName('Akamai Opportunity');//Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();

            String functionalitySwitch = GSMUtilClass.getGSMSettingValue('AccFinanceRegionCheck_Disable');

            if (!functionalitySwitch.equalsIgnoreCase('true')) {

                //for (Opportunity opp:Trigger.new) {Order_Region__c
                if ((Trigger.isInsert && (oppRecNew.RecordTypeId == akamaiOppRecordTypeId || oppRecNew.RecordTypeId == adminOppRecordTypeId)) ||
                    (Trigger.isUpdate && (oppRecNew.RecordTypeId == akamaiOppRecordTypeId || oppRecNew.RecordTypeId == adminOppRecordTypeId) && (Util.hasChanges('RecordTypeId' ,oppRecOld, oppRecNew) || Util.hasChanges('Order_Region__c' ,oppRecOld, oppRecNew)))) {
                        oppList.add(oppRecNew);
               // }
                }

            }

            // Project-Win change SFDC-7596
            if((Trigger.isInsert || (Trigger.isUpdate && util.hasChanges(new Set<String>{'Opportunity_Category__c','Enterprise_Loss_Category__c','Identity_Loss_Category__c'}, oppRecOld, oppRecNew))) && ((oppRecNew.Opportunity_Category__c =='ALL' && oppRecNew.Loss_Reason__c != null) || (oppRecNew.Enterprise_Loss_Category__c =='ALL' && oppRecNew.Enterprise_Loss_Reason__c != null) || (oppRecNew.Identity_Loss_Category__c =='ALL' && oppRecNew.Identity_Loss_Reason__c != null))){   
                UpdateOppCategoryList.add(oppRecNew);
            }

            // Move this back to validation rule 
            /*
            //SFDC-8121
            if(GsmUtilClass.disableLossReasonValidation && (String.ISBLANK(oppRecNew.Opportunity_Category__c) || String.ISBLANK(oppRecNew.Loss_Reason__c)) &&
                (oppRecNew.RecordTypeId == akamaiOppRecordTypeId || oppRecNew.RecordTypeId == closedOppRecordTypeId) &&
                ((oppRecNew.StageName == 'Closed Lost' || oppRecNew.StageName == 'Closed Contract Ended') ||
                ((oppRecNew.ForecastCategoryName == 'Commit' || oppRecNew.StageName == '6. Signed') && ('LMRR'.equalsIgnoreCase(oppRecNew.Account_MRR_Type__c)) && oppRecNew.Opportunity_Type__c !='Auto-Renewal'))){

                  oppRecNew.adderror('Loss Reason and Loss Category is mandatory');
            }*/

        }
        //End of sObject loop
        
        //SFDC-7772 //SFDC-9589
        /*
        if(opptyListToSyncSpecialistField.size() > 0){
            OpportunityTriggerClass.syncSpecialistField(opptyListToSyncSpecialistField, specialistCompTeamId);
        }*/

        //SFDC-7474
       if(accids.size()>0)
                OpportunityTriggerClass.updateOpptyCurrency(accids,oppNewCurrencyList);

         // Project-Win change SFDC-7596
         if(UpdateOppCategoryList.size()>0)
                OpportunityTriggerClass.UpdateLossCategory(UpdateOppCategoryList);
               

        if(stampCustomerProspectAccToOpptyMap.size() > 0){
            OpportunityTriggerClass.stampCustomerProspect(stampCustomerProspectAccToOpptyMap);

        }

        //SFDC-5991
        Map<Id,SubReseller__c> subMap;
        if(!subresList.isEmpty())
             subMap = OpportunityTriggerClass.fetchSubResellerMap(subresList);
        else
            subMap = new Map<Id,SubReseller__c>();
        /* SFDC - 5392 Removal of related trial opportunity lookup field
        Start of SFDC-3921
        if(!trialToSalesOpptyMap.isEmpty()){
            OpportunityTriggerClass.updateTrialOpptyWithSalesOppty(trialToSalesOpptyMap);
        }
        /* End of SFDC-3921 */
        //SFDC-4136
        if(!contractReviewedChange.isEmpty())
            OpportunityTriggerClass.updateOpptyContractReviewedBy(contractReviewedChange);
        //HC - in the condition and check on size of opportunityStatusToBeUpdated
                if(opportunityStatusToBeUpdated.size() > 0)
                    OpportunityTriggerClass.updateOpptyStageForAMG(opportunityStatusToBeUpdated);

            //SFDC-1595
             if(!populateChannelLevelList.isEmpty())
              OpportunityPRMTriggerClass.populateChannelLevel(populateChannelLevelList,Trigger.isUpdate);
                //SFDC-1435
                //HC Moved the method to OpportunityForecastingTriggerClass
                if(changedoppSet.size() > 0)
                    OpportunityForecastingTriggerClass.genericPopulateMRR(oppIdSet,'OpportunityTrigger',changedFieldName,changedoppSet);
                //OpportunityTriggerClass.genericPopulateMRR(oppIdSet,'OpportunityTrigger',changedFieldName,changedoppSet);


                //HC - Removed this since we can directly pass Trigger.New rather than storing in a different list
                //FCMlist.add(opp);

                //HC - added !Trigger.isInsert in the condition and check on size of opptyWithRejectedDealRegStatus

                if(opptyWithRejectedDealRegStatus.size() > 0)
                    OpportunityPRMTriggerClass.setFieldsWhenDealIsRejected(opptyWithRejectedDealRegStatus);
                //add the condtion to check if partner user here
                if(dataClassHandlerObj.getUserTypeInfo().contains('Partner'))
                {
                    if(Trigger.isInsert)
                        {
                            //HC removed FCMList from code and added direct triggernew list
                            OpportunityPRMTriggerClass.addFCMdealcreation(opptyTriggerNew);
                            OpportunityPRMTriggerClass.dealOwnershipUpdate(opptyTriggerNew);
                        }
                    //CR 1121880 Update fields from text fields to picklist
                    if(DealSubmittedList.size()>0)
                        OpportunityPRMTriggerClass.OwnerUpdateOnSubmit(DealSubmittedList);
                }


        if (oppList.size() > 0) {
                OpportunityTriggerClass.updateOrderRegion(oppList, null);
            }
        //SFDC-6398
        /*if(autoRenewalSwitchOpptyList.size() > 0 )
            OpportunityTriggerClass.switchToAutoRenewalType(autoRenewalSwitchOpptyList);*/


        //Start SFDC-1432

        for(SObject soRec: newList)
        {
            Opportunity oppRecN = (Opportunity)soRec;
            Opportunity oppRecO = null;
            //SFDC-5991
            if(!String.isBlank(oppRecN.SubReseller__c) && subMap.containsKey(oppRecN.SubReseller__c))
            {
                oppRecN.Sub_Reseller_Account__c = subMap.get(oppRecN.SubReseller__c).Account__c;
            }


            if(oppRecN.PAE_Projected_Monthly_Commit__c == null)
            {
                oppRecN.PAE_Projected_Monthly_Commit__c = 0;
            }

            if(oppRecN.Baseline_Monthly_Commit__c == null)
            {
                oppRecN.Baseline_Monthly_Commit__c = 0;
            }

            if(oppRecN.Security_Projected_Monthly_Commit__c == null)
            {
                oppRecN.Security_Projected_Monthly_Commit__c = 0;
            }

            if(oppRecN.Security_Baseline_Monthly_Commit__c == null)
            {
                oppRecN.Security_Baseline_Monthly_Commit__c = 0;
            }

            if(!Trigger.isInsert)
            {

                oppRecO=(Opportunity)oldMap.get(oppRecN.Id);
                //HC Util has changes added
                if( Util.hasChanges('PAE_Projected_Monthly_Commit__c' ,oppRecO, oppRecN) || Util.hasChanges('Baseline_Monthly_Commit__c' ,oppRecO, oppRecN))
                {
                    oppRecN.Partner_Forecast_Amount__c = oppRecN.PAE_Projected_Monthly_Commit__c-oppRecN.Baseline_Monthly_Commit__c;
                }
                //HC Util has changes added

                if(Util.hasChanges('Security_Projected_Monthly_Commit__c' ,oppRecO, oppRecN) || Util.hasChanges('Security_Baseline_Monthly_Commit__c' ,oppRecO, oppRecN))
                {
                    oppRecN.Security_MRR__c=oppRecN.Security_Projected_Monthly_Commit__c-oppRecN.Security_Baseline_Monthly_Commit__c;
                }



            }

            else if(Trigger.isInsert)
            {
                oppRecN.Partner_Forecast_Amount__c = oppRecN.PAE_Projected_Monthly_Commit__c-oppRecN.Baseline_Monthly_Commit__c;
                oppRecN.Security_MRR__c = oppRecN.Security_Projected_Monthly_Commit__c-oppRecN.Security_Baseline_Monthly_Commit__c;
            }
            //SFDC-3907
            if(oppRecN.PAE_Projected_Monthly_Commit__c != null)
            {
                oppRecN.PAE_Projected_Monthly_Commit__c = oppRecN.PAE_Projected_Monthly_Commit__c.setScale(2, RoundingMode.HALF_UP);
            }
            if(oppRecN.PAE_Projected_Monthly_Usage__c != null)
            {
                oppRecN.PAE_Projected_Monthly_Usage__c = oppRecN.PAE_Projected_Monthly_Usage__c.setScale(2, RoundingMode.HALF_UP);
            }
            if(oppRecN.PAE_Non_Traffic_Projected_Monthly_Commit__c != null)
            {
                oppRecN.PAE_Non_Traffic_Projected_Monthly_Commit__c = oppRecN.PAE_Non_Traffic_Projected_Monthly_Commit__c.setScale(2, RoundingMode.HALF_UP);
            }
            if(oppRecN.Partner_Forecast_Amount__c != null)
            {
                oppRecN.Partner_Forecast_Amount__c = oppRecN.Partner_Forecast_Amount__c.setScale(2, RoundingMode.HALF_UP);
            }

        }
            //End of SFDC-1432

        //HC removing isBefore check
        //if(Trigger.isInsert )//&& Trigger.isBefore)
        //    {
        //        OpportunityTriggerClass.sendEmailAlertOnHighRiskAccount(opptyTriggerNew);
        //    }


            //SFDC-4389
        if(!oppyToAddValidationForNonInProgressPMA.isEmpty())
            PartnerMarketingClass.addPMANotInProgressValidation(oppyToAddValidationForNonInProgressPMA);

        if(accList.size()>0)
            OpportunityTriggerClass.checkForInactiveUser(acclist);

        //HC Check and move to PRMTriggerClass

        // If new account is added then make the account owner as opportunity owner
        if(DealApprovedList.size()>0)
           OpportunityPRMTriggerClass.onDealApproval(DealApprovedList);

        // SFDC-9133 - Update rebate% based on current date (contract len) when oppty is closed won
        system.debug(LoggingLevel.Error, 'closedWonDR:: '+closedWonDR);
        if(!closedWonDR.isEmpty()){
           OpportunityPRMTriggerClass.calcDRRebateAtClosedWon(closedWonDR);
           
        }

        if(NewAcclist.size()>0)
            OpportunityPRMTriggerClass.AddAccountOwner(NewAcclist);

        if(AddTochannelMappingList.size()>0)
            OpportunityPRMTriggerClass.UpdateChannelManager(AddTochannelMappingList);

        //HC moved to EMRI
        //Changes for CR 1760780
        if(renewalOpptyList.size() > 0)
            OpportunityTriggerClass.populateRenewalOpptyFields(renewalOpptyList);

                 //HC moved to EMRI - check with Dhinesh

                 //commented by swati as part of Project-Win check with Radha
       /* if(showErrorWhenRemovingOpptyCategoryMap.size() > 0)
            OpportunityTriggerClass.checkNegativeProducts(showErrorWhenRemovingOpptyCategoryMap,true,false);

        if(removeOpptyCategoryMap.size() > 0)
            OpportunityTriggerClass.checkNegativeProducts(removeOpptyCategoryMap,false,false);*/

        //SFDC-7606
        // CR 2403102 - Create new survey functionality for customers who may churn
        /*if(listOfOpportunitiesWithChangedStage.size()>0)
        {
            OpportunityTriggerClass.verifyMinimumContactRolesOnStageChange(listOfOpportunitiesWithChangedStage);
        }*/

        //Begin , Rajesh - SFDC-7061
        if(zoffapprChangedoppty.size()>0 ){// map would be empty if ZOFF feature not enabled
          OpportunityTriggerClass.checkzoffvalidApproval(new List<Opportunity>(zoffapprChangedoppty.Keyset()),new Set<id>(zoffapprChangedoppty.values()),opptyTriggerOldMap);
        }
        if(!zoffemailListoppty.keySet().isEmpty() ){
              OpportunityTriggerClass.updateApprovername(new List<Opportunity>(zoffemailListoppty.keySet()), new Set<Id>(zoffemailListoppty.values()));
            }
        if(zoffapprrejectList.size()>0 ) {
             System.debug('zoffapprrejectList=='+zoffapprrejectList);
             OpportunityTriggerClass.sendApproveRejectEmail(new List<Opportunity>(zoffapprrejectList.keySet()), new Set<Id>(zoffapprrejectList.values()));
            }
        if(sendEmailForMediaVertZoff.size() > 0){
            OpportunityTriggerClass.sendZoffEmailForMediaVertical(new List<Opportunity>(sendEmailForMediaVertZoff.keySet()), new Set<Id>(sendEmailForMediaVertZoff.values()));
        }
       //End , Rajesh - SFDC-7061



        if(opportunityShifteddateToBeUpdated.size() > 0)
                OpportunityTriggerClass.updateShiftedDate(opportunityShifteddateToBeUpdated);


            Opportunity oldOpp = null;

            //String akamaiRecTypeId= dataClassHandlerObj.getRecordTypeInfoByName('Akamai Opportunity');//GSMSettings.getValue('RecordTypeAkamaiOpportunity');

            String opptyStagesForRepsRecTypeChangeToClosed = GSMUtilClass.getGSMSettingValue('opptyStagesForRepsRecTypeChangeToClosed');
            String opptyStageToFlipBackFromClosedRecType = GSMUtilClass.getGSMSettingValue('Oppty_StageToFlipBackFromClosedRecType');
            String opptyNascentStage = dataClassHandlerObj.opptyNascentStage;// GSMSettings.getValue('LeadAutoConvert_NascentStageName');
            String opptyUnqualifiedLeadClosedStage = dataClassHandlerObj.opptyUnqualifiedLeadClosedStage;//GSMSettings.getValue('LeadAutoConvert_UnqualifiedLeadStageName');
            String opptyStagesForRejected = GSMUtilClass.getGSMSettingValue('DWLSOpptyStageSRL');
            for(Opportunity opp : opptyTriggerNew)
            {
                if(Trigger.isUpdate)
                    oldOpp = (Opportunity)oldMap.get(opp.Id);

                if(Trigger.isUpdate && opp.Associated_lead__c != null && oldOpp.StageName!=opp.StageName)
                {
                    // 0.5 AQL to 1 and greater = accept
                    //SFDC-3539 : below code Related to old stage being 0.5 AQL, hence not applicable in current world
                    //if( oldOpp.StageName.equals(opptyNascentStage) && !opp.StageName.contains('Closed'))
                    //{
                    //    if(opp.Created_Accepted_Date_Marketing__c == null && opp.StageName.equals('1-Create'))
                    //    {
                    //        opp.Created_Accepted_Date_Marketing__c = Date.Today();
                    //        opp.TAL_DateTime__c = Datetime.now();
                    //    }
                    //    opp.QFA_Accept_Reject_Date__c = Date.today();
                    //    opp.Marketing_Opportunity_Accept_Reject__c='Accept';

                    //    if(opp.Partner_Involved__c!=null && !FeatureToggles.IS_AWE_EXPOSED_TO_PARTNERS)
                    //    {
                    //        opp.RecordTypeId = akamaiRecTypeId;
                    //    }
                    //}
                    // 0.5 AQL/ 1-create to closed unqualified or closed lost = reject
                    if((oldOpp.StageName.equals(opptyNascentStage) || oldOpp.StageName.equals('1. Identify Need')) && (opp.StageName.equalsIgnoreCase(opptyUnqualifiedLeadClosedStage) || opptyStagesForRejected.containsIgnoreCase(opp.StageName)))//SFDC-3539
                    {
                        opp.RecordTypeId = akamaiRecTypeId;
                        opp.QFA_Accept_Reject_Date__c = Date.today();
                        opp.Marketing_Opportunity_Accept_Reject__c='Reject';
                    }
                    // 1-create to greater is 'accept' if akamai oppty
                    // if aql, it means it is already accepted. change record type to akamai
                    else if(oldOpp.StageName.equals('1. Identify Need') && oldOpp.Probability<opp.Probability)//SFDC-3539
                    {
                        if(opp.RecordTypeId==akamaiRecTypeId || opp.RecordTypeId==closedRecTypeId)//SFDC-3261
                        {
                            opp.QFA_Accept_Reject_Date__c = Date.today();
                            opp.Marketing_Opportunity_Accept_Reject__c='Accept';
                        }
                        if(opp.RecordTypeId!=akamaiRecTypeId)
                        {
                            if(opp.RecordTypeId != dealRegRecordTypeIds.get(1)) { // addidng this if condition to check if it's not dealreg unsbmitted record type to solve SFDC-5904
                                opp.RecordTypeId = akamaiRecTypeId;
                            }
                        }
                    }

                }
                //SFDC-3261
                        if(opp.RecordTypeId ==akamaiRecTypeId && opptyStagesForRepsRecTypeChangeToClosed.contains(opp.StageName) && (Trigger.isInsert || (Trigger.isUpdate && (Util.hasChanges('StageName',oldOpp,opp) || Util.hasChanges('RecordTypeId',oldOpp,opp))))) {
                                opp.RecordTypeId = closedRecTypeId;
                        }
                        if(opp.RecordTypeId ==closedRecTypeId && opptyStageToFlipBackFromClosedRecType.contains(opp.StageName) && (Trigger.isInsert || (Trigger.isUpdate && (Util.hasChanges('StageName',oldOpp,opp) || Util.hasChanges('RecordTypeId',oldOpp,opp))))) {
                                opp.RecordTypeId = akamaiRecTypeId;
                        }
                         //SFDC-3269, 3261
                    if(!Trigger.isInsert && Util.hasChanges('StageName',oldOpp,opp) &&
                        opp.StageName == '6. Signed' && !Util.hasChanges('CloseDate',oldOpp,opp) &&
                        opp.RecordTypeId == closedRecTypeId)//SFDC-3539
                    {
                        opp.CloseDate = System.Today();
                    }
                        // Ali changes for CR 1768502
                    //SFDC-3261


                    //SFDC-2324
                    //SFDC-3261
                    if(((Trigger.isUpdate && dealRegRecordTypeIds.contains(opp.RecordTypeId)) || ((opp.RecordTypeId == akamaiOppRecordTypeId || opp.RecordTypeId == closedRecTypeId) && opp.Deal_Type__c == 'Indirect')) && !opp.StageName.contains('Closed') && opp.Channel_Manager__c != null && (oldOpp != null && oldOpp.Channel_Manager__c != null) && Util.hasChanges('Channel_Manager__c',oldOpp,opp))
                    {
                        fcmUpdateList.add(opp);
                        channelMappingIds.add(opp.Channel_Manager__c);
                    }
                    //End of SFDC-2324
                    //SFDC-3535 - Update the Oppty leader as owner if the old owner was Oppty leader and Owner changes for oppty
                if(Trigger.isUpdate && Util.hasChanges('OwnerId' ,oldOpp, opp)  && opp.OwnerID != null && oldOpp.OwnerId == oldOpp.Opportunity_Leader__c)
                    {
                        opp.Opportunity_Leader__c = opp.OwnerId;
                    }
            }
        //SFDC-2324
        if(fcmUpdateList.size() > 0)
        {
            OpportunityPRMTriggerClass.updateFCMForDealRegOpptys(fcmUpdateList,channelMappingIds);
        }
        //End of SFDC-2324
     //SFDC-2192
        //if(Features_Toggle__c.getInstance('Partner Sellable Country Toggle').Toggle__c) //SFDC-2304
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('Partner_Sellable_Country_Toggle')) //SFDC-2304
        {
        //SFDC-1096
            List<Opportunity> listOfOpptysForPartnerAuthorisedCountryFlag = new List<Opportunity>();
            Set<Id> setOfAccountIds = new Set<Id>();
            Set<Id> setOfPartnerInvolvedIds = new Set<Id>();
            List<Opportunity> listOfOpptysToResetPartnerAuthorsedCountryFlag = new List<Opportunity>();
            for(Opportunity oppty : opptyTriggerNew)
            {
                //SFDC-3261
            if(oppty.isWon == false && oppty.isClosed == false && oppty.Partner_Involved__c!= null && oppty.Deal_Type__c == 'Indirect' && (oppty.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId() || oppty.RecordTypeId == closedRecTypeId)
                && (Trigger.isInsert  ||(Trigger.isUpdate &&
                    (oppty.Partner_Involved__c != opptyTriggerOldMap.get(oppty.Id).Partner_Involved__c
                    || oppty.AccountId!= opptyTriggerOldMap.get(oppty.Id).AccountId || oppty.RecordTypeId!=opptyTriggerOldMap.get(oppty.Id).RecordTypeId))))
                {
                listOfOpptysForPartnerAuthorisedCountryFlag.add(oppty);
                setOfAccountIds.add(oppty.AccountId);
                setOfPartnerInvolvedIds.add(oppty.Partner_Involved__c);
                }

                if((Trigger.isInsert || (Trigger.isUpdate && opptyTriggerOldMap.get(oppty.Id).Deal_Type__c == 'Indirect')) && oppty.Deal_Type__c=='Direct' && oppty.Partner_Involved__c == null
                && oppty.Is_Authorized_Partner_Sellable_Country__c == false)
                listOfOpptysToResetPartnerAuthorsedCountryFlag.add(oppty);
            }

            if(listOfOpptysForPartnerAuthorisedCountryFlag.size()>0)
            OpportunityTriggerClass.setPartnerAuthorisedCountryFlag(setOfAccountIds,setOfPartnerInvolvedIds,listOfOpptysForPartnerAuthorisedCountryFlag);

            if(listOfOpptysToResetPartnerAuthorsedCountryFlag.size()>0)
            OpportunityTriggerClass.resetPartnerAuthorisedCountryFlag(listOfOpptysToResetPartnerAuthorsedCountryFlag);

        }
        if(Trigger.isUpdate)
            {
            // Start - Generic code for all MRR- MRR USD conversions- SFDC - 1316 & SFDC-1453
                Set<String> fieldNames = new Set<String>();
                for(USD__mdt usdObj : [Select Field__c,USD_Field__c from USD__mdt where Object__c = 'Opportunity'])
                fieldNames.add(usdObj.Field__c);
                    for(Opportunity oppty : opptyTriggerNew)
                    {
                    if(Util.hasChanges('CloseDate',opptyTriggerOldMap.get(oppty.Id),oppty))
                        setOfOpptysForUSDConversion.add(oppty);
                    else
                    {
                        if(Util.hasChanges(fieldNames,opptyTriggerOldMap.get(oppty.Id),oppty))
                            setOfOpptysForUSDConversion.add(oppty);
                    }
                    }
                if(setOfOpptysForUSDConversion.size() > 0)
                    OpportunityUtilClass.genericPopulateUSDOnChangeOfFields(new List<Opportunity>(setOfOpptysForUSDConversion),false);
                    // End - Generic code for all MRR-MRR USD conversions- SFDC - 1316 & SFDC-1453
                }
                // CR 774372 Add MSS Rep to Opportunity Sales Team
                OpportunityTriggerClass.updateOpptyOwnerId( opptyTriggerNew, opptyTriggerOldMap, Trigger.isInsert, Trigger.isUpdate );
                //SFDC -3535 Opportunity Leader
                //Populate Oppty Leader as Specialist if Creator is a Specialist else Oppty Owner becomes Leader
                Id profileId=userinfo.getProfileId();
                String salesSpecialistProfileIds = GSMUtilClass.getGSMSettingValue('SalesSpecialistProfileIds');
                System.Debug(LoggingLevel.Error, 'HC specialistTeams user profile '+profileId+'Metadata '+salesSpecialistProfileIds);
                if(Trigger.isInsert)
                {

                                for(Opportunity oppty:opptyTriggerNew)
                                {
                                    //if it's specialist created opportunity
                                    if(salesSpecialistProfileIds.contains(profileId) && oppty.Opportunity_Leader__c == null)
                                        {
                                            oppty.Opportunity_Leader__c = UserInfo.getUserId();
                                            System.Debug(LoggingLevel.Error, 'Inside If HC specialistTeams user profile '+UserInfo.getUserId()+'Owner '+oppty.OwnerId);

                                        }

                                    else if( oppty.Opportunity_Leader__c == null)
                                        {
                                            oppty.Opportunity_Leader__c = oppty.OwnerId;
                                            System.Debug(LoggingLevel.Error, 'Inside Else HC specialistTeams user profile '+UserInfo.getUserId()+'Owner '+oppty.OwnerId);

                                        }
                                    }
                                }
                // Sales Overlay Functionality

            if (fCMFeatureRunFlag)
            {
                List<Opportunity> channelManagerOpptyList = new List<Opportunity>();
                for(Opportunity oppty:opptyTriggerNew)
                {
                            // Same IF In BEOFRE AND AFTER
                            // Same IF In BEOFRE AND AFTER ----  ALMOST ---
                    if(oppty.Deal_Type__c == 'Indirect' && oppty.Partner_Involved__c != null && (Trigger.isInsert || (!Trigger.isInsert
                    && (oppty.Channel_Manager__c == null || oppty.Partner_Involved__c != opptyTriggerOldMap.get(oppty.Id).Partner_Involved__c
                        || oppty.Channel_Manager__c != opptyTriggerOldMap.get(oppty.Id).Channel_Manager__c))))
                    channelManagerOpptyList.add(oppty);
                }
                if (channelManagerOpptyList.size()>0)
                OpportunityTriggerClass.channelManagerCheck_BeforeTrigger(channelManagerOpptyList);

                }
        // MOB-72
        if(Trigger.isUpdate) {
                for(Opportunity opp : opptyTriggerNew) {
                OpportunityTriggerClass.validateAccountAndOpportunityStatus(opp);
                }
            }
        // End of MOB-72

        // Start of MOB-292
        //SFDC-2704-moved profile id hard code value to metadata
        if(Trigger.isUpdate && userinfo.getProfileId() ==GsmUtilClass.getGSMSettingValue('CMGProfileId')) {
                for(Opportunity opp: opptyTriggerNew) {
                    //SFDC-2704 -> add A+ to metadata and further tiers check as well to code
                    if((opp.Contract_Entered_by__c != opptyTriggerOldMap.get(opp.id).Contract_Entered_by__c) ||
                        (opp.Contract_Reviewed_by__c  != opptyTriggerOldMap.get(opp.id).Contract_Reviewed_by__c ) || (opp.Double_Reviewed_By__c != opptyTriggerOldMap.get(opp.id).Double_Reviewed_By__c && !String.isBlank(opp.Double_Reviewed_By__c) && opp.Account_Customer_Tier__c!=null && GSMUtilClass.getGSMSettingValue('CMG_Acc_Cust_Tier_For_Double_Review').contains(opp.Account_Customer_Tier__c))) {
                            OpportunityTriggerClass.updateOnlineChannelOpptyTaskStatus(opp);
                    }
                }
            }
        //End of MOB-292

        //SFDC-3545
        if(oppIdListForContactRole.size() > 0){
            OpportunityTriggerClass.checkOppContactRole(oppIdListForContactRole);
        }
        //SFDC-3547
        if(oppIdListForOrderApproval.size() > 0){
            OpportunityTriggerClass.checkOrderApprovalForOpp(oppIdListForOrderApproval);
        }

        //SFDC-9151 - Moving Restrict_Opportunity_Leader_Change Validation Rule to Trigger
        for(SObject so: newList)
        {
            Opportunity oppRecNew = (Opportunity)so;
            Opportunity oppRecOld = null;

            if(Trigger.isUpdate)
                oppRecOld=(Opportunity)oldMap.get(oppRecNew.Id);

            if(Trigger.isUpdate && oppRecNew.Validation_Override__c != true && Util.hasChanges('Opportunity_Leader__c',oppRecOld,oppRecNew) && 
                (UserInfo.getUserId() != oppRecOld.Opportunity_Leader__c && UserInfo.getUserId() != oppRecNew.Account.OwnerId && UserInfo.getUserId() != oppRecNew.Owner__r.ManagerId
                    && !GSMUtilClass.getGSMSettingValue('Opportunity_Leader_Change_Profile').contains(UserInfo.getProfileId()))
                && (UserInfo.getUserId() != oppRecNew.CreatedById || (!GSMUtilClass.getGSMSettingValue('Opportunity_Leader_Change_CreatedProfile').contains(oppRecNew.CreatedBy.ProfileId))))
                {
                    oppRecNew.addError(GsmUtilClass.getGSMSettingValue('Opportunity_Leader_Change_Error_Message'));
                }
        }

    }
    /*
    1. HC removed Low stage varibale
    2. HC highstage moved to metadata

    */

     /*
    1. HC removed Low stage varibale
    2. HC highstage moved to metadata

    */

    public override void afterInsertAfterUpdateTrigger()
    {

        //Cast entire collection to Opportunity sObject type collection- Maps and Lists

        List<Opportunity> opptyTriggerNew = (List<Opportunity>)newList;
        List<Opportunity> opptyTriggerOld = (List<Opportunity>)oldList;
        Map<Id,Opportunity> opptyTriggerNewMap = (Map<Id,Opportunity>)newMap;
        Map<Id,Opportunity> opptyTriggerOldMap = (Map<Id,Opportunity>)oldMap;

        List<Opportunity> competitorChangedOpptys = new List<Opportunity>();
        Set<String> competitorFields = new Set<String>{'Competitor__c','Competitor_Secondary__c','Other_Competitor_Name__c'};


        List<Opportunity> populateChannelLevelList = new List<Opportunity>();
        list<Opportunity> StatusSubmitted = new list<Opportunity>();
        list<Opportunity> managerSwarmOpptysTemp = new list<Opportunity>();
        list<Opportunity> managerSwarmOpptys = new list<Opportunity>();
        list<Opportunity> SalesStage6opps = new list<Opportunity>();
        List<Opportunity> closeDateChangedOpptys = new List<Opportunity>();
        List<Id> populateCampaignBasedOnPMA = new List<Id>();
        //SFDC-2266 -> Remove code for owner change of task on oppty stage change
        //list<Opportunity> SalesStage6oppsList = new list<Opportunity>();
        List<Opportunity> updateOpptyOwnerCShareList = new List<Opportunity>();
        //List<Opportunity> updateOpptyOLIList = new List<Opportunity>();
        Map<Id,Opportunity> mapOfOpptyIdToChangedCloseDateOpptys = new Map<Id,Opportunity>();


        //Local variables
        String akamaiRecTypeId= dataClassHandlerObj.getRecordTypeInfoByName('Akamai Opportunity');
        String adminRecTypeId = dataClassHandlerObj.getRecordTypeInfoByName('Administrative Opportunity');
        String closedRecTypeId= dataClassHandlerObj.getRecordTypeInfoByName(GSMUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type'));
        String OpportunityType= GSMUtilClass.getGSMSettingValue('AdminOpportunityTypeForContractEntryTask');
        //Boolean isOpptyToFollow=false;
        List<Opportunity> opptysToFollow=new List<Opportunity>();
        //SFDC-1333
        List<Opportunity> onlineChannelOpptyList = new List<Opportunity>();
        list<Opportunity> ClosedWonOppty = new list<Opportunity>();

        //SFDC-948
        List<Opportunity> dealRegOpptyForShareupdate = new List<Opportunity>();
        Map<Id,Id> dealRegOpptyForShareDelToOldAccount = new Map<Id,Id>();
        //system.debug('recordType: '+recordType);
        //Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        String currentOppRecordtype = '';
        String OpportunityAccess = 'Read';

        //Opportunity New World Conversion
        String opptyNascentStage = GSMSettings.getValue('LeadAutoConvert_NascentStageName');
        String opptyUnqualifiedLeadClosedStage = GSMSettings.getValue('LeadAutoConvert_UnqualifiedLeadStageName');

        Map<Id, String> leadIdToNewStatus= new Map<Id, String>();
        //Features_Toggle__c customSettingsFieldChannelManager = Features_Toggle__c.getInstance('UpdateChannelManagerToOpptySalesTeam'); //SFDC-2304
        //Boolean fCMFeatureRunFlag = customSettingsFieldChannelManager.Toggle__c == true;   //SFDC-2304
        Boolean fCMFeatureRunFlag = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UpdateChannelManagerToOpptySalesTeam') == true;    //SFDC-2304
        List<Opportunity> eligibleOpportunitiesList = new List<Opportunity>();
        Map<Id,String> leadToStageNameMap = new Map<Id,String>();
                   // String opptyNascentStage = dataClassHandlerObj.opptyNascentStage;// GSMSettings.getValue('LeadAutoConvert_NascentStageName');
        //SFDC-3535
        Map<Id,Id> opptyIdToLeaderIdMapToAddOTM = new Map<Id,Id>();
        //SFDC-4292
        //Set<Id> userIDSet = new Set<Id>();
        Map<Id,Id> opptyToOTMUserIdMap = new Map<Id,Id>();

        List<Opportunity> listOfDuplicateOpportunity = new List<Opportunity>(); // SFDC-3289 : Nagaraj Desai
        Set<Id> setOfOriginalOpptyIds = new Set<Id>();
        Map<Id,Set<Id>> accountOpportunityIds = new Map<Id,Set<Id>>(); // SFDC-3446
        Map<Id, Set<String>> IdToFieldSet = new Map<Id, Set<String>>();
        Map<Id, Opportunity> IdToOppty = new Map<Id, Opportunity>();

        List<opportunity> opportunityList = new List<opportunity>();
        List<Id> opportunityIdForUpdatingOAStatus = new List<Id>();
        Map<Id, Opportunity> opptunityList = new Map<Id, Opportunity>();
        List<Id> AzureOpportunityList = new List<Id>();
        String StageNameForOaCreation = GSMSettings.getValue('StageNameForOACreation');
        String OpptyStageToChangeOAStatus = GSMSettings.getValue('Order_Approval_Status_Transition');
        List<String> opptyClosedStages = GSMSettings.getValue('OpportunityStagesForSpecialistEmail').split(',');
        List<String> opptyStages = new List<String>{'3. Verify Options','4. Select Option','5. Negotiate','6. Signed'};
        Map<Id, Opportunity> idToOpptyMap = new Map<Id, Opportunity>();
        List<Opportunity> autoRenewalOpportunityList = new List<Opportunity>();
        String opptyClosedLostStages = GSMSettings.getValue('Closed_Opportunity_Stages');
        List<Opportunity> opportunityListForChime = new List<Opportunity>();
        
        //Begin SFDC-9455 Rajul Vishwakarma
        String closedOppStageNames = GsmUtilClass.getGSMSettingValue('Closed_Opportunity_Stage_Name');
        Set<Id> closedOppoIds = new Set<Id>();
        //End 
        

        if(Trigger.isInsert)
            OpportunityTriggerClass.sendEmailAlertOnHighRiskAccount(opptyTriggerNew);

        for(SObject so: newList)
        {
            Opportunity oppRecNew = (Opportunity)so;
            Opportunity oppRecOld = null;

            if(Trigger.isUpdate)
                oppRecOld=(Opportunity)oldMap.get(oppRecNew.Id);

            if(Trigger.isUpdate && Util.hasChanges(competitorFields,oppRecOld,oppRecNew)){
                competitorChangedOpptys.add(oppRecNew);
            }
            
            if(Trigger.isUpdate && Util.hasChanges('StageName',oppRecOld,oppRecNew) && opptyClosedLostStages.contains(oppRecNew.StageName)){
                opportunityListForChime.add(oppRecNew);
            }

            
            //Begin SFDC-9455 Rajul Vishwakarma
            if(Trigger.isUpdate && Util.hasChanges('StageName',oppRecOld,oppRecNew) && closedOppStageNames.contains(oppRecNew.StageName)){
            closedOppoIds.add(oppRecNew.Id);
            }
            //End
            

            //SFDC-7597
            if(Trigger.isUpdate && Util.hasChanges('StageName',oppRecOld,oppRecNew) && opptyStages.contains(oppRecOld.StageName) && opptyClosedStages.contains(oppRecNew.StageName) && ((oppRecNew.Soha_Specialist__c != null && String.isBlank(oppRecNew.Enterprise_Competitor_Primary__c) && String.isBlank(oppRecNew.Enterprise_Loss_Category__c)) || (oppRecNew.CIAM_Specialist__c != null && String.isBlank(oppRecNew.Identity_Competitor_Primary__c) && String.isBlank(oppRecNew.Identity_Loss_Category__c))) && oppRecNew.Opportunity_Type__c != 'Auto-Renewal'){
                idToOpptyMap.put(oppRecNew.id , oppRecNew);
            }

            //Order Approval Creation  - Saket More SFDC-4178
             if(Util.hasChanges('RecordTypeId',oppRecOld,oppRecNew) && (oppRecNew.RecordTypeId == akamaiRecTypeId || oppRecNew.RecordTypeId == adminRecTypeId) && oppRecNew.IsOACreated__c == 0){
                opportunityList.add(oppRecNew);
            }
            //Opportunity Stage - (Closed Won, Closed Lost, Closed Contract Ended, Closed Duplicate ), Then Order Approval Status -> Closed
            if(Trigger.isUpdate && oppRecNew.IsOACreated__c == 1 && Util.hasChanges('StageName',oppRecOld,oppRecNew) && OpptyStageToChangeOAStatus.contains(oppRecNew.StageName)){
                opportunityIdForUpdatingOAStatus.add(oppRecNew.id);
            }
            //SFDC-6398 - Check if Auto renew then allow to be moved to closed stage.
            if(Trigger.isUpdate && Util.hasChanges('StageName',oppRecOld,oppRecNew) && oppRecNew.StageName == '6. Signed' && oppRecNew.IsOACreated__c == 1 && oppRecNew.Opportunity_Type__c == 'Auto-Renewal' && oppRecNew.Auto_Renewal__c){
                AzureOpportunityList.add(oppRecNew.id);
            }
            //No Opportunity can be moved to Stage 6 - Signed, without an Order Management Approval in place.
            if(Trigger.isUpdate && Util.hasChanges('StageName',oppRecOld,oppRecNew) && oppRecNew.StageName == '6. Signed'){
                opptunityList.put(oppRecNew.id, oppRecNew);
            }
            if(Trigger.isUpdate && oppRecNew.IsOACreated__c == 1 && oppRecNew.Source__c != oppRecOld.Source__c && oppRecNew.Source__c == 'Azure Marketplace' && oppRecNew.Opportunity_Type__c == 'Churn'){
                AzureOpportunityList.add(oppRecNew.id);
            }


            //end SFDC-4178


            if(Trigger.isUpdate && Util.hasChanges('stageName', oppRecOld, oppRecNew) && '6. Signed'.equalsIgnoreCase(oppRecNew.stageName) && 'Auto-Renewal'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                autoRenewalOpportunityList.add(oppRecNew);
            }


            //Common for both insert and update

            //isOpptyToFollow=(Trigger.IsInsert && oppRecNew.DVP_to_Follow__c !=null) ||
            //(Trigger.IsUpdate && Util.hasChanges('DVP_to_Follow__c' ,oppRecOld, oppRecNew)) ;      //oppRecNew.DVP_to_Follow__c != oppRecOld.DVP_to_Follow__c);
            // SFDC-8902 - do not overwrite Primary Campaign Source if populated 
            if(oppRecNew.Partner_Marketing_Activity__c!=null && oppRecNew.CampaignId==null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Partner_Marketing_Activity__c',oppRecOld,oppRecNew)))) {
               populateCampaignBasedOnPMA.add(oppRecNew.id);
            }

            if((Trigger.isInsert && oppRecNew.Contract_ID__c!=null && oppRecNew.StageName=='Closed Won') || (Trigger.isUpdate && Util.hasChanges('StageName' ,oppRecOld, oppRecNew)  && oppRecNew.Contract_ID__c!=null && oppRecNew.StageName=='Closed Won'))
                ClosedWonOppty.add(oppRecNew);

            if(!Userinfo.getProfileId().contains(GsmUtilClass.getGSMSettingValue('OpptyTrigger_MarkettingOpsProfileId')))//Not marketting ops //SFDC-2304
            {
                if((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('StageName' ,oppRecOld, oppRecNew))) && oppRecNew.StageName == '6. Signed' && !'Auto-Renewal'.equalsIgnoreCase(oppRecNew.Opportunity_Type__c)){
                    SalesStage6opps.add(oppRecNew);
                }
            }

            //HC Removing this feature since it is not in use anymore
            //Confirmation on SFDC-1922
            /*if(isOpptyToFollow)
                    opptysToFollow.add(oppRecNew);*/

            String recordType = NAPSettings.getValue('Opportunity_Share_Record_Type');
            currentOppRecordtype = rt_Map.get(oppRecNew.RecordTypeId).getName();
            Set<String> changedFields = new Set<String>{'Partner_Involved__c','AccountId','Deal_Type__c','OwnerId'};

            //after insert
            if(Trigger.isInsert)
            {
                if(String.isNotBlank(recordType) && recordType.contains(currentOppRecordtype) && oppRecNew.Partner_Involved__c!=null  && (oppRecNew.Deal_Type__c == 'Indirect')){
                    //ITREQ-3098
                    //if(currentOppRecordtype == 'Deal Reg Unsubmitted')
                        OpportunityAccess = 'Edit';

                    dealRegOpptyForShareupdate.add(oppRecNew);
                }

                 //SFDC -3535 Opportunity Leader
                    if(oppRecNew.Opportunity_Leader__c != null && oppRecNew.Opportunity_Leader__c != oppRecNew.OwnerId)
                            {
                                opptyIdToLeaderIdMapToAddOTM.put(oppRecNew.Id,oppRecNew.Opportunity_Leader__c);
                            }
            }



            //after update
            if(Trigger.isUpdate)
            {
                String dealRegRecTypeIds = GsmUtilClass.getGSMSettingValue('Opportunity_Record_Type_Ids');
                if(oppRecNew.StageName=='Closed Won' && oppRecNew.Contract_Entered_by__c=='Online Channel' && oppRecNew.Momentum_Automated__c=='Online Channel Sales' )
                    onlineChannelOpptyList.add(oppRecNew);
                if(UserInfo.getUserType().contains('Partner') && Util.hasChanges('Registration_Status__c' ,oppRecOld, oppRecNew) && oppRecNew.Registration_Status__c=='Pending')
                    StatusSubmitted.add(oppRecNew);

                String highstage = GSMUtilClass.getGSMSettingValue('PRM_HighStage');

                //If SS moves beyond 4, then add managers to chatter.
                //SFDC-3261
                if((oppRecNew.RecordTypeId == akamaiRecTypeId || oppRecNew.RecordTypeId == closedRecTypeId) && (Util.hasChanges('StageName' ,oppRecOld, oppRecNew) && highStage.contains(oppRecNew.StageName) ))
                    managerSwarmOpptysTemp.add(oppRecNew);

                /*CR 2946584 - CMG Review Queue -Added By Hitesh - Checking if stage name changed from 6 to Closed Won and User is a CMG User*/
                //CR 3018287 - Extended this functionality for opportunity moved to Closed Contract Ended
                //SFDC-2266 -> Remove code for owner change of task on oppty stage change
                //if( (oppRecNew.StageName== 'Closed Won' || oppRecNew.StageName== 'Closed Contract Ended') && oppRecOld.Probability == 90 && Userinfo.getProfileId().contains(GSM_Custom_Settings__c.getInstance('CMGProfileId').Value__c))
                //    SalesStage6oppsList.add(oppRecNew);

                /* Commenting out code for CR 1259743 Make Contracts: a parent-child with accounts? */
                // Contract_Share__c related code.

                // Contract Share Update.
                if (Util.hasChanges('OwnerId' ,oppRecOld, oppRecNew)  && oppRecNew.OwnerID != null && !GSMFeatureOverride.overrideOpportunityOwnerContractShareTrigger)
                   {
                    system.debug('Inside owner change Oppty Trigger');
                     updateOpptyOwnerCShareList.add(oppRecNew);
                }
                // Forecasting Releated Code
                //updateOpptyOLIList.add(oppRecNew);

                if(Util.hasChanges('CloseDate' ,oppRecOld, oppRecNew))
                    mapOfOpptyIdToChangedCloseDateOpptys.put(oppRecNew.Id,oppRecNew);

                if(recordType.contains(currentOppRecordtype) && oppRecNew.Partner_Involved__c!=null  && (oppRecNew.Deal_Type__c == 'Indirect')){
                    if(Util.hasChanges(changedFields, oppRecOld,oppRecNew)){
                        //ITREQ-3098
                            OpportunityAccess = 'Edit';
                            dealRegOpptyForShareupdate.add(oppRecNew);
                        }
                    }
                    //ITREQ-3098
                    if(Util.hasChanges('Partner_Involved__c', oppRecOld,oppRecNew) && oppRecOld.Partner_Involved__c!=null)
                        dealRegOpptyForShareDelToOldAccount.put(oppRecNew.id,oppRecOld.Partner_Involved__c);
                //SFDC-1128
                    System.debug('Opportunity stage : '+oppRecNew.StageName);
                    if (oppRecNew.StageName != oppRecOld.StageName && (oppRecNew.StageName.equals('5. Negotiate') || oppRecNew.StageName.equals('6. Signed'))) {//SFDC-3539
                        eligibleOpportunitiesList.add(oppRecNew);
                    }
                /*SFDC-1102 Demand Waterfall Stage change for Lead*/

                    String stageNameSQL = GSMUtilClass.getGSMSettingValue('DWLSOpptyStageSQL');
                    String stageNameWonBusiness = GSMUtilClass.getGSMSettingValue('DWLSOpptyStageWonBusiness');
                    String stageNameClosedLost = GSMUtilClass.getGSMSettingValue('DWLSOpptyStageClosedLost');
                    String stageSAL = GSMUtilClass.getGSMSettingValue('DWLSStageSAL');
                    String stageSRL = GSMUtilClass.getGSMSettingValue('DWLSStageSRL');
                    String stageSQL = GSMUtilClass.getGSMSettingValue('DWLSStageSQL');
                    String stageWB = GSMUtilClass.getGSMSettingValue('DWLSStageWB');
                    String stageLB = GSMUtilClass.getGSMSettingValue('DWLSStageLB');

                    if(oppRecNew.Associated_Lead__c != null && oppRecNew.StageName!=oppRecOld.StageName)
                    {
                        system.debug('Inside accept reject logic'+oppRecNew.QFA_Accept_Reject__c);

                        if(oppRecNew.Marketing_Opportunity_Accept_Reject__c== 'Accept' && oppRecOld.Marketing_Opportunity_Accept_Reject__c!='Accept')
                            leadToStageNameMap.put(oppRecNew.Associated_Lead__c,stageSAL);
                        else if(oppRecNew.Marketing_Opportunity_Accept_Reject__c=='Reject' && oppRecOld.Marketing_Opportunity_Accept_Reject__c!='Reject')
                            leadToStageNameMap.put(oppRecNew.Associated_Lead__c,stageSRL);
                        else if(stageNameSQL.contains(oppRecNew.StageName) && !stageNameSQL.contains(oppRecOld.StageName))
                            leadToStageNameMap.put(oppRecNew.Associated_Lead__c,stageSQL);
                        else if(stageNameWonBusiness.contains(oppRecNew.StageName) && !stageNameWonBusiness.contains(oppRecOld.StageName))
                            leadToStageNameMap.put(oppRecNew.Associated_Lead__c,stageWB);
                        else if(stageNameClosedLost.contains(oppRecNew.StageName) && !stageNameClosedLost.contains(oppRecOld.StageName))
                            leadToStageNameMap.put(oppRecNew.Associated_Lead__c,stageLB);
                    }
                    // SFDC- 3289 : Nagaraj Desai
                                if((oppRecNew.StageName == 'Closed Duplicate' && (oppRecNew.Duplicate_Opportunity__c != null || oppRecNew.Duplicate_Opportunity__c != '')
                                    && (Util.hasChanges('StageName', oppRecOld, oppRecNew) || Util.hasChanges('Duplicate_Opportunity__c', oppRecOld, oppRecNew))
                                    ) ) {
                                        listOfDuplicateOpportunity.add(oppRecNew);
                                        setOfOriginalOpptyIds.add(oppRecNew.Duplicate_Opportunity__c);
                                }
                    //SFDC -3535 Opportunity Leader

                    if(Util.hasChanges('Opportunity_Leader__c' ,oppRecOld, oppRecNew) && !dealRegRecTypeIds.contains(oppRecNew.RecordTypeId))
                        {
                        System.Debug(LoggingLevel.Error, 'HC oppRecOld Opportunity_Leader__c '+oppRecOld.Opportunity_Leader__c+'oppRecNew OwnerId '+oppRecNew.OwnerId+'oppRecNew Opportunity_Leader__c '+oppRecNew.Opportunity_Leader__c +'oppRecNew OwnerId'+oppRecNew.OwnerId);

                            if(oppRecOld.Opportunity_Leader__c != oppRecNew.OwnerId )
                                {
                                    //HC:SFDC-4292 change
                                    opptyToOTMUserIdMap.put(oppRecOld.Id,oppRecOld.Opportunity_Leader__c);
                                    //userIDSet.add(oppRecOld.Opportunity_Leader__c);
                                    System.Debug(LoggingLevel.Error, 'HC Inside If '+opptyToOTMUserIdMap);
                                }
                            if(oppRecNew.Opportunity_Leader__c != oppRecNew.OwnerId )
                                {
                                    opptyIdToLeaderIdMapToAddOTM.put(oppRecNew.Id,oppRecNew.Opportunity_Leader__c);
                                                                        System.Debug(LoggingLevel.Error, 'HC Inside else '+opptyIdToLeaderIdMapToAddOTM);

                                }
                        }

                //SFDC-5295
                if(Trigger.isUpdate && Util.hasChanges('CloseDate',oppRecOld,oppRecNew) && oppRecNew.IsClosed == false)
                {
                    closeDateChangedOpptys.add(oppRecNew);
                }
                //End of SFDC-5295

                //Start SFDC-5434

                if(objectToFieldMapFirstRunFlag){
                    objectToFieldMap = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('CustomNotesObjectFieldMapping'));
                    objectToFieldMapFirstRunFlag = false;
                }

                if(objectToFieldMap.keyset().contains('Opportunity')){
                    Object innerKeyValue = objectToFieldMap.get('Opportunity');
                    Map <String, Object> fieldMappingForKeyValue = (Map <String, Object>)innerKeyValue;
                    Set<String> fieldSet = new Set<String>();

                    for(String fieldname : fieldMappingForKeyValue.KeySet()){
                        if(Util.hasChanges(fieldname ,oppRecOld, oppRecNew)){
                            fieldSet.add(fieldname);
                        }

                    }
                    if(fieldSet.size()>0){
                        IdToFieldSet.put(oppRecNew.Id, fieldSet);
                        IdToOppty.put(oppRecNew.Id, oppRecNew);
                    }

                }

                    //End SFDC-5434
            }
        }

         // SFDC-9455 Rajul Vishwakarma
         if(closedOppoIds.size()>0){
            OpportunityTriggerClass.closeAllChimeFormRelatedToClosedOpportunity(closedOppoIds);
        }
        // End
        
        
        if(opportunityListForChime.size() > 0){
            OpportunityTriggerClass.checkChimeContactForAccess(opportunityListForChime);
        }

        if(competitorChangedOpptys.size()>0){
            MeddiccTriggerClass.updateMeddicResponse(competitorChangedOpptys);
        }

        //SFDC-4178
            if(opportunityList.size()>0){
                OrderApprovalClass.CreateOrderApproval(opportunityList);
            }

            if(opportunityIdForUpdatingOAStatus.size()>0){
                OrderApprovalClass.changeOAStatus(opportunityIdForUpdatingOAStatus);
            }

             if(AzureOpportunityList.size()>0){
                OrderApprovalClass.CheckAndCreateCase(AzureOpportunityList);
            }

            if(opptunityList.size()>0){
                OpportunityTriggerClass.CheckOppValidationRule(opptunityList);
            }

        //SFDC-4178 End

        if(idToOpptyMap.size() > 0){
            OpportunityTriggerClass.sentEmailToSpecialist(idToOpptyMap);
        }

        if(IdToOppty.size()>0){
        GsmUtilClass.updateCustomNotes(IdToFieldSet, IdToOppty, 'Opportunity');
      }

        if (populateCampaignBasedOnPMA.size() > 0) {
            OpportunityTriggerClass.updateCampaignForDealReg(populateCampaignBasedOnPMA);
        }

             //SFDC-3535 + SFDC-4292
             if(!opptyIdToLeaderIdMapToAddOTM.isEmpty() || !opptyToOTMUserIdMap.isEmpty())
             {
                OpportunityTriggerClass.createDeleteOTMForLeader(opptyIdToLeaderIdMapToAddOTM,opptyToOTMUserIdMap);
             }

             if(managerSwarmOpptysTemp.size() > 0)
             {
                if(OpportunityPRMTriggerClass.IsoMap.size()<1)
                    OpportunityPRMTriggerClass.initilizeCurrencyRate();


                for(Opportunity opp :managerSwarmOpptysTemp)
                {
                  if(OpportunityPRMTriggerClass.IsoMap.get(opp.CurrencyIsoCode) != 0.00 && OpportunityPRMTriggerClass.IsoMap.get(opp.CurrencyIsoCode) != null)
                  {
                    if((opp.MRR__c)/OpportunityPRMTriggerClass.IsoMap.get(opp.CurrencyIsoCode) >= 25000)
                       managerSwarmOpptys.add(opp);
                  }
                }
             }

            //Logics being executed in handler methods
            /*if(opptysToFollow.size()>0)
                OpportunityTriggerClass.addDVPsToFollowOppty(opptysToFollow);*/

            //SFDC-1333 - HC removed isUpdate check
            if(onlineChannelOpptyList.size() > 0)
                OpportunityTriggerClass.updateOnlineChannelOpptyTaskStatus(onlineChannelOpptyList);

            //HC - Moving Partner User check to above isUpdate logic
            //if(UserInfo.getUserType().contains('Partner'))
            if(StatusSubmitted.size()>0)
                OpportunityPRMTriggerClass.AddToPartnerOwnerToSalesTeam(StatusSubmitted);
            if(ClosedWonOppty.size()>0)
                OpportunityTriggerClass.sendEmailWhenClosedWon(ClosedWonOppty);
            if(managerSwarmOpptys.size()>0)
                OpportunityTriggerClass.managerSwarmOpptys(managerSwarmOpptys);
            if(SalesStage6opps.size()>0)
                OpportunityTriggerClass.createTaskWhenSalesStage6(SalesStage6opps);
            //SFDC-2266 -> Remove code for owner change of task on oppty stage change
            //if(SalesStage6oppsList.size() > 0)
            //    OpportunityTriggerClass.updateCMGTaskOwnerWhenSalesStage6(SalesStage6oppsList);
            // Contract_Share__c related code.
            /*if (updateOpptyOwnerCShareList.size()>0 && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) // if toggle is off; dont do anything. //SFDC-2304
                ContractSharing.updateOpptyOwnerContractShare(updateOpptyOwnerCShareList, opptyTriggerOldMap, opptyTriggerNewMap);*/
            //HC - SFDC-5912 Changes
            if (updateOpptyOwnerCShareList.size()>0 )//&& GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) // if toggle is off; dont do anything. //SFDC-2304
                ContractSharing.updateOpptyOwnerContractShare(updateOpptyOwnerCShareList, opptyTriggerOldMap);

            // Forecasting Releated Code
            /*if (updateOpptyOLIList.size()>0 && GsmUtilClass.isFeatureToggleEnabled('isOOTBForecastingEnabled')) // if toggle is off; dont do anything.
                OpportunityLineItemTriggerClass.fixOpptyProducts(updateOpptyOLIList); */

            //Start-SFDC-1453 - HC - Moved logic to TriggerHandlerClass from Trigger
            if(mapOfOpptyIdToChangedCloseDateOpptys.size()>0)
                OpportunityForecastingTriggerClass.convertMRRToUSDMRRFields(mapOfOpptyIdToChangedCloseDateOpptys);

            if(!dealRegOpptyForShareDelToOldAccount.isEmpty())
                OpportunityTriggerClass.updateDealRegOpptyShareForPartnerInvolved(dealRegOpptyForShareDelToOldAccount);

            if(!dealRegOpptyForShareupdate.isEmpty())
                OpportunityTriggerClass.updateDealRegOpptyShareForPartnerInvolved(dealRegOpptyForShareupdate,OpportunityAccess);

            //SFDC-2192
            if (eligibleOpportunitiesList.size() > 0)
                  OpportunityTriggerClass.sendDoubleByteNotification(eligibleOpportunitiesList);

            //SFDC-5295
            if(closeDateChangedOpptys.size() > 0)
            {
                OpportunityTriggerClass.updateOLISpecialistCloseDates(closeDateChangedOpptys);
            }
            //End of SFDC-5295



        OpportunityTriggerClass.createAutomatedActivities(opptyTriggerNew, opptyTriggerOldMap, opptyTriggerNewMap);

        if(leadToStageNameMap.size()>0)
            DemandWaterfallStages.updateLeadDemandWaterfallStage(leadToStageNameMap);

        /* CR 774372 Add MSS Rep to Opportunity Sales Team */
        //SFDC-2572
        if( Trigger.isInsert && UserInfo.getProfileId().contains(GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')))
        {
            OpportunityTriggerClass.addOpptySalesTeam( opptyTriggerNew );
        }

        /* CR 842447 Automate Field Channel Manager Account assignments */
       // if (customSettingsFieldChannelManager.Toggle__c == true && (currentUserProfile.contains('Sales') || currentUserProfile == 'System Administrator'))
       if (fCMFeatureRunFlag)
        {
            List<Opportunity> partnerInvolvedChangedList=new List<Opportunity>();
            Map<Id,Id> opportunityIdOldPartnerInvolvedIdMap=new Map<Id,Id>();
            Map<Id,Id> mapOfOpptyIdToOldChannelMappingId = new Map<Id,Id>();
            Map<Id,Id> mapOfOpptyIdToNewChannelMappingId = new Map<Id,Id>();
            Map<Id,Opportunity> mapofOpptyIdToOppty      = new Map<Id,Opportunity>();
            Map<Id,Opportunity> mapofOpptyIdToOpptyForGSI      = new Map<Id,Opportunity>();
            List<Opportunity> channelManagerCheckOpptyList = new List<Opportunity>();
            List<Opportunity> gsiChannelManagerCheckOpptyList = new List<Opportunity>();
            Map<Id,Id> mapOfOpptyIdToOldGSIChannelMappingId = new Map<Id,Id>();
            Map<Id,Id> mapOfOpptyIdToNewGSIChannelMappingId = new Map<Id,Id>();
            Boolean isForGSIChannelmanager = false;

          for(Opportunity oppty:opptyTriggerNew)
          {

              if(oppty.Deal_Type__c == 'Indirect' && ((Trigger.isInsert && oppty.Channel_Manager__c!=null) || (Trigger.isUpdate && oppty.Channel_Manager__c != opptyTriggerOldMap.get(oppty.Id).Channel_Manager__c)))
              {
                if(oppty.Channel_Manager__c != null)
                {
                  mapOfOpptyIdToNewChannelMappingId.put(oppty.Id,oppty.Channel_Manager__c);
                  channelManagerCheckOpptyList.add(oppty);
                }
                //add following users of channel mapping to oppty team, if they are populated: Channel_Account_Manager, PAE_ID__c and Temp_PAE__c
                if(Trigger.isUpdate  && opptyTriggerOldMap.get(oppty.Id).Channel_Manager__c != null)
                  mapOfOpptyIdToOldChannelMappingId.put(oppty.Id,opptyTriggerOldMap.get(oppty.Id).Channel_Manager__c);
                mapofOpptyIdToOppty.put(oppty.Id,oppty);

              }
              
              //SFDC-7481 Changes related to GSI channel manager
              if(oppty.Deal_Type__c == 'Indirect' && ((Trigger.isInsert && oppty.GSI_Channel_Manager__c!=null) || (Trigger.isUpdate && oppty.GSI_Channel_Manager__c != opptyTriggerOldMap.get(oppty.Id).GSI_Channel_Manager__c)))
              {
                if(oppty.GSI_Channel_Manager__c != null)
                {
                  mapOfOpptyIdToNewGSIChannelMappingId.put(oppty.Id,oppty.GSI_Channel_Manager__c);
                }
                //add following users of channel mapping to oppty team, if they are populated: Channel_Account_Manager, PAE_ID__c and Temp_PAE__c
                if(Trigger.isUpdate  && opptyTriggerOldMap.get(oppty.Id).GSI_Channel_Manager__c != null)
                  mapOfOpptyIdToOldGSIChannelMappingId.put(oppty.Id,opptyTriggerOldMap.get(oppty.Id).GSI_Channel_Manager__c);
                  mapofOpptyIdToOpptyForGSI.put(oppty.Id,oppty);
                
              }

                //If partner involved is changed, remove this partner from oppty sales team
                if(Trigger.isUpdate && oppty.Partner_Involved__c != opptyTriggerOldMap.get(oppty.Id).Partner_Involved__c && opptyTriggerOldMap.get(oppty.Id).Partner_Involved__c!=null)
                {
                  partnerInvolvedChangedList.add(oppty);
                  opportunityIdOldPartnerInvolvedIdMap.put(oppty.Id,opptyTriggerOldMap.get(oppty.Id).Partner_Involved__c);
                }
              }

            // add FCM OpptySalesTeamMember
            if (channelManagerCheckOpptyList.size()>0)
                OpportunityTriggerClass.channelManagerCheck_AfterTrigger(channelManagerCheckOpptyList);

            if(mapOfOpptyIdToOldChannelMappingId.size()>0 || mapOfOpptyIdToNewChannelMappingId.size()>0)
            ChannelMappingTriggerClass.setOpportunityTeamForChannelMappingMembersFromOppportunity(mapOfOpptyIdToOldChannelMappingId,mapOfOpptyIdToNewChannelMappingId,mapofOpptyIdToOppty, isForGSIChannelmanager);
            
            //Add/Delete GSI channel manager shares
            if(mapOfOpptyIdToOldGSIChannelMappingId.size()>0 || mapOfOpptyIdToNewGSIChannelMappingId.size()>0) {
                ChannelMappingTriggerClass.setOpportunityTeamForChannelMappingMembersFromOppportunity(mapOfOpptyIdToOldGSIChannelMappingId,mapOfOpptyIdToNewGSIChannelMappingId,mapofOpptyIdToOpptyForGSI, !isForGSIChannelmanager);
                }

            if(partnerInvolvedChangedList.size()>0)
                OpportunityTriggerClass.removePartnersFromSalesTeam(partnerInvolvedChangedList,opportunityIdOldPartnerInvolvedIdMap);
        }

        //Add product specialist of specialist comp team to oppty team memeber on insert and update of specialist comp team and delete old one.
        Set<String> specialistTeams = GSMSettings.getValues('SCT_');
        System.Debug(LoggingLevel.Error, 'AGH_D specialistTeams '+specialistTeams);

        List<OpportunitySpecialistsClass.OpportunitySpecialistRelation> newSpecialistRelations = new List<OpportunitySpecialistsClass.OpportunitySpecialistRelation>();
        List<OpportunitySpecialistsClass.OpportunitySpecialistRelation> oldSpecialistRelations= new List<OpportunitySpecialistsClass.OpportunitySpecialistRelation>();


        for(Opportunity opp : opptyTriggerNew)
        {
            for(String specialist : specialistTeams)
            {
                if(opp.get(specialist)!=null && Trigger.isInsert)
                {
                    newSpecialistRelations.add(new OpportunitySpecialistsClass.OpportunitySpecialistRelation((Id)opp.get(specialist), opp.Id));
                }

                if(Trigger.isUpdate && opp.get(specialist)!=opptyTriggerOldMap.get(opp.Id).get(specialist))
                {
                    if(opp.get(specialist)!=null)
                    {
                        newSpecialistRelations.add(new OpportunitySpecialistsClass.OpportunitySpecialistRelation((Id)opp.get(specialist), opp.Id));
                    }

                    if(opptyTriggerOldMap.get(opp.id).get(specialist)!=null)
                    {
                        oldSpecialistRelations.add(new OpportunitySpecialistsClass.OpportunitySpecialistRelation((Id)opptyTriggerOldMap.get(opp.Id).get(specialist), opp.Id));
                    }
                }
            }
        }
        System.Debug(LoggingLevel.Error, 'AGH_D newSpecialistRelations'+newSpecialistRelations+ ' and oldSpecialistRelations '+oldSpecialistRelations);
        if(newSpecialistRelations.size()>0 || oldSpecialistRelations.size()>0)
            OpportunitySpecialistsClass.refreshOTMsAndShares(newSpecialistRelations, oldSpecialistRelations);

        // SFDC 2720
        // Refactoring : Bringing back SFDC logic for creditcheck Task here from Q2O Codebase as part of Apttus purge
        List<String> updateSpecialistForecastOpptyList = new List<String>();
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            List<Opportunity> creditCheckTaskOpptyList = new List<Opportunity>();
            //SFDC-1245
            Date todayDate = Date.today();
            Date next60DaysCloseDate = todayDate.addDays(60);


            for(Opportunity o : opptyTriggerNew)
            {
                Opportunity oppOldRec = null;
                //SFDC-9141
                if(Trigger.isUpdate){
                    oppOldRec=(Opportunity)oldMap.get(o.Id);
                }
                Set<Id> oppIds;
                // SFDC -1014- Sonali Tandon - Added more conditions for credit check task creation
                if(o.Associated_Account_Vertical__c!=null)
                {
                    if(o.Deal_Type__c == 'Direct' && o.ForecastCategoryName == 'Commit' && !(o.Associated_Account_Vertical__c.containsIgnoreCase('Internal'))
                    && o.Partner_Involved__c==null && o.Dollar_MRR__c >Decimal.valueOf(GsmUtilClass.getGSMSettingValue('Opportunity_forecasted_MRR_Limit')) &&
                    (o.StageName == '3. Verify Options' || o.StageName == '4. Select Option' || o.StageName == '5. Negotiate') && (o.CloseDate>todayDate && o.CloseDate<=next60DaysCloseDate)) //SFDC-3539
                    {
                        creditCheckTaskOpptyList.add(o);
                    }
                }

                if(o.RecordTypeId == akamaiOppRecordTypeId) {
                    oppIds = new Set<Id>();
                    if(Trigger.isInsert) {

                        if(accountOpportunityIds.get(o.AccountId) == null) {
                            oppIds.add(o.Id);
                            accountOpportunityIds.put(o.AccountId,new Set<Id>());
                            accountOpportunityIds.put(o.AccountId,oppIds);
                        } else {
                            accountOpportunityIds.get(o.AccountId).add(o.Id);
                        }
                    }
                    if(Trigger.isUpdate) {
                        oppOldRec=(Opportunity)oldMap.get(o.Id);
                        if(Util.hasChanges('RecordTypeId' ,oppOldRec, o)) {
                            if(accountOpportunityIds.get(o.AccountId) == null) {
                                oppIds.add(o.Id);
                                accountOpportunityIds.put(o.AccountId,new Set<Id>());
                                accountOpportunityIds.put(o.AccountId,oppIds);
                            } else {
                                accountOpportunityIds.get(o.AccountId).add(o.Id);
                            }
                            system.debug('accountOpportunityIds = '+accountOpportunityIds);
                        }
                    }
                }
                //SFDC-5138 Sausharm : changes for Opportunity product's special forecast category when Opportunity is closed
                //SFORCE-102
                if(o.isClosed == true && (Util.hasChanges('StageName' ,oppOldRec, o) || Util.hasChanges('CloseDate' ,oppOldRec, o) || Util.hasChanges('ForecastCategoryName' ,oppOldRec, o))){
                    updateSpecialistForecastOpptyList.add(o.Id);
                }

            }
            if(creditCheckTaskOpptyList.size() > 0)
            {
                OpportunityTriggerClass.creditCheckTask(creditCheckTaskOpptyList);
            }

            if(accountOpportunityIds.size() > 0) {
                OpportunityTriggerClass.createOpportunityTeamMember(accountOpportunityIds);
            }
        }
        // Begin Rajesh - SFDC-7061
        if(zoffmdtValue.Mail_Enabled__c && zoffmdtValue.Feature_Enabled__c){
            OpportunityTriggerClass.sendZoffemail();
        }
        // End Rajesh - SFDC-7061
        //SFDC-3289 : Nagaraj Desai
        if(listOfDuplicateOpportunity.size() > 0) {
                OpportunityTriggerClass.updateRequiredDuplicateOpptyDetails(listOfDuplicateOpportunity, setOfOriginalOpptyIds);
        }

        /*
        //SFDC-5138 Sausharm : changes for Opportunity product's special forecast category when Opportunity is closed
        if(Trigger.isInsert || Trigger.isUpdate && OpportunityTriggerClass.specialForecastCategoryFirstRunFlag)
        {
            OpportunityTriggerClass.specialForecastCategoryFirstRunFlag = false;
            OpportunityTriggerClass.updateSpecialistFieldsOnClosedOpp(opptyTriggerNew,opptyTriggerOldMap);

        }*/

        if(updateSpecialistForecastOpptyList.size() > 0 && OpportunityTriggerClass.specialForecastCategoryFirstRunFlag){
            //OpportunityTriggerClass.specialForecastCategoryFirstRunFlag = false;
            OpportunityTriggerClass.updateSpecialistFieldsOnClosedOpp(updateSpecialistForecastOpptyList);
        }

        if(autoRenewalOpportunityList.size() > 0){
            OpportunityTriggerClass.autoClosureRenewalOpportunity(autoRenewalOpportunityList);
        }
    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        System.debug('This is before delete and before undelete.');
        List<Opportunity> opptyTriggerNew = (List<Opportunity>)newList;
        List<Opportunity> opptyTriggerOld = (List<Opportunity>)oldList;
        Map<Id,Opportunity> opptyTriggerNewMap = (Map<Id,Opportunity>)newMap;
        Map<Id,Opportunity> opptyTriggerOldMap = (Map<Id,Opportunity>)oldMap;
        //SFDC-2192
        if(Trigger.isDelete) // before delete
        {
            OpportunityTriggerClass.PreventOppDelete(opptyTriggerOld);
        }
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        System.debug('This is after delete and after undelete.');
    }







}