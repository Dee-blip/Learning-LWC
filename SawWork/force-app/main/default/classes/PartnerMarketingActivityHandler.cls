/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    28/05/2018     Created this Handler - SFDC-2706
    
*/
public with sharing class PartnerMarketingActivityHandler extends ApexTriggerHandlerAbstractClass{
    public PartnerMarketingActivityHandler() {
        
    }
public override void beforeInsertBeforeUpdateTrigger()
    {
        //Cast entire collection to Opportunity sObject type collection- Maps and Lists

        List<Partner_Marketing_Activity__c> pmaTriggerNew = (List<Partner_Marketing_Activity__c>)newList;
        List<Partner_Marketing_Activity__c> pmaTriggerOld = (List<Partner_Marketing_Activity__c>)oldList;
        Map<Id,Partner_Marketing_Activity__c> pmaTriggerNewMap = (Map<Id,Partner_Marketing_Activity__c>)newMap;
        Map<Id,Partner_Marketing_Activity__c> pmaTriggerOldMap = (Map<Id,Partner_Marketing_Activity__c>)oldMap;
        List<Partner_Marketing_Activity__c> pmaList = new List<Partner_Marketing_Activity__c>();
        //SFDC-4058
        List<Partner_Marketing_Activity__c> pmaToCreateCampaignList = new List<Partner_Marketing_Activity__c>();
        List<Partner_Marketing_Activity__c> pmaListForStatusChangeToExcluded = new List<Partner_Marketing_Activity__c>();
        List<Partner_Marketing_Activity__c> pmaListForStatusChange = new List<Partner_Marketing_Activity__c>();
        List<Partner_Marketing_Activity__c> pmaListForPartnerLookupUpdate = new List<Partner_Marketing_Activity__c>();
        String changedField = '';
        //SFDC-5888
        String progressStatus = GSMUtilClass.getGSMSettingValue('PM_Status_Progress');
        //SFDC-6149
        String activityTypeNoCampaign = GSMUtilClass.getGSMSettingValue('activityTypeNoCampaign');
        //SFDC-5995
        Map<Id, Partner_Marketing_Activity__c> mapOfAccountIdVsPMA = new Map<Id, Partner_Marketing_Activity__c>();
        // SFDC-7222
        List<Partner_Marketing_Activity__c> checkToPoulateChangedFieldsAfterApproval = new List<Partner_Marketing_Activity__c>();
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,pmaTriggerNew);
        for(SObject so: newList)
        {
            Partner_Marketing_Activity__c pmaRecNew = (Partner_Marketing_Activity__c)so;
            Partner_Marketing_Activity__c pmaRecOld = null;

            if(Trigger.isUpdate)
                pmaRecOld=(Partner_Marketing_Activity__c)oldMap.get(pmaRecNew.Id);
            if(pmaRecNew.Activity_Status__c=='Approved' && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Activity_Status__c',pmaRecOld,pmaRecNew))))
                    pmaList.add(pmaRecNew);
                    //allow reparenting for excluded pmas
                    //system.debug(LoggingLevel.ERROR,'pmaRecNew.Activity_Status__c:: '+pmaRecNew.Activity_Status__c+' Approval.isLocked(pmaRecNew): '+Approval.isLocked(pmaRecNew));
            //SFDC-4058 - Campaign should always be created at update
            if(Trigger.isUpdate && Util.hasChanges('Activity_Status__c',pmaRecOld,pmaRecNew)){
                //SFDC-6149
                if(pmaRecNew.Activity_Status__c=='Approved'  && pmaRecNew.MDF_Activity_Type__c !=null && !activityTypeNoCampaign.contains(pmaRecNew.MDF_Activity_Type__c) && (pmaRecNew.Indirect_Campaign__c==null || !pmaRecNew.Is_Campaign_Active__c))
                    pmaToCreateCampaignList.add(pmaRecNew);
                //SFDC-5888
                if(progressStatus.contains(pmaRecOld.Activity_Status__c) && !progressStatus.contains(pmaRecNew.Activity_Status__c))
                pmaListForStatusChange.add(pmaRecNew);
            }

            if(Trigger.isInsert || (Trigger.isUpdate && pmaRecOld.Partner_Marketing_Plan__c!=pmaRecNew.Partner_Marketing_Plan__c))
                pmaListForPartnerLookupUpdate.add(pmaRecNew);
            //SFDC-4058, 4582
                //(pmaRecOld.Activity_Status__c=='Approved' || pmaRecOld.Activity_Status__c=='In Progress') &&
             /*** Begin Rajesh Kumar JIRA # SFDC-5777 **/ // Added condition when status is cancelled
            if(Trigger.isUpdate && ((Util.hasChanges('Activity_Status__c',pmaRecOld,pmaRecNew) && (pmaRecNew.Activity_Status__c=='Excluded' || pmaRecNew.Activity_Status__c=='Planned' || pmaRecNew.Activity_Status__c=='Cancelled') ) || Util.hasChanges('Partner_Marketing_Plan__c',pmaRecOld,pmaRecNew))){
              /*** End Rajesh Kumar JIRA # SFDC-5777 **/
                pmaListForStatusChangeToExcluded.add(pmaRecNew);
                if(Util.hasChanges('Activity_Status__c',pmaRecOld,pmaRecNew))
                    changedField = 'Activity_Status__c';
                if(Util.hasChanges('Partner_Marketing_Plan__c',pmaRecOld,pmaRecNew))
                    changedField += 'Partner_Marketing_Plan__c';
            }

            //SFDC-4962
            if(Trigger.isUpdate && Util.hasChanges('PAE_Forecast_Override__c',pmaRecOld,pmaRecNew) && !pmaRecNew.PAE_Forecast_Override__c){
                pmaRecNew.PAE_Forecast_Closed_Deals__c = null;
                pmaRecNew.PAE_Forecast_DR__c = null;
                pmaRecNew.PAE_Forecast_Monthly_Bookings__c = null;
                pmaRecNew.PAE_Forecast_Total_Contract_Value__c = null;
            }

            //SFDC-5995
            if(Trigger.isInsert) {
                if(pmaRecNew.Partner__c != null) {
                    mapOfAccountIdVsPMA.put(pmaRecNew.Partner__c, pmaRecNew);
                }
            }

            // SFDC-7222: if PMA is approved/in-progress it means associated PMP was approved. PMA status can only move from Approved to cancelled and you cannot change an in progress PMA status.
            // and if fields mentioned in ticket are changing, populate Changed_Fields_after_approval__c
            if(Trigger.isUpdate && !Util.hasChanges('Activity_Status__c',pmaRecOld,pmaRecNew) && progressStatus.contains(pmaRecOld.Activity_Status__c) && pmaRecNew.PMP_Status_Formula__c!='Approved'){
                checkToPoulateChangedFieldsAfterApproval.add(pmaRecNew);
                // fetch all the field names and check if they are changing
               
            }
        }
        PartnerMarketingClass pmaObj = new PartnerMarketingClass();
        if(!pmaList.isEmpty()){
                pmaObj.captureApprovalFields(pmaList);
            }
        //SFDC-4058 - create campaign only when there is no indirect active campaign.
        if(!pmaToCreateCampaignList.isEmpty()){
                pmaObj.createCampaign(pmaToCreateCampaignList);
            }
        if(!pmaListForStatusChange.isEmpty())
                pmaObj.addPMPChangeErrorAndModifyRec(pmaListForStatusChange,pmaTriggerOldMap);

        if(!pmaListForPartnerLookupUpdate.isEmpty())
            PartnerMarketingClass.populatePartnerLookupOnPMAs(pmaListForPartnerLookupUpdate);
            //SFDC-4058
        if(!pmaListForStatusChangeToExcluded.isEmpty())
                pmaObj.addPMPChangeErrorOnExcluded(pmaListForStatusChangeToExcluded,pmaTriggerNewMap,changedField);

        //SFDC-5995
        if(!mapOfAccountIdVsPMA.isEmpty()) {
            PartnerMarketingClass.copyOverDefaultMDFCurrencyToPartnerMDFObjects(mapOfAccountIdVsPMA, 'Partner_Marketing_Activity__c');
        }
        
        // SFDC-7222
        if(!checkToPoulateChangedFieldsAfterApproval.isEmpty()){
                pmaObj.populateChangedFieldsAfterApproval(checkToPoulateChangedFieldsAfterApproval,pmaTriggerOldMap);
            }
            
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){

    }

    public override void afterInsertAfterUpdateTrigger(){

    }

    public override void afterDeleteAfterUndeleteTrigger(){

    }
}