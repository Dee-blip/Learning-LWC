/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    28/05/2018     Created this Handler - SFDC-2706
    
*/
public with sharing class PartnerMarketingPlanHandler extends ApexTriggerHandlerAbstractClass{
    public PartnerMarketingPlanHandler() {
        
    }
    public override void beforeInsertBeforeUpdateTrigger()
    {
        //Cast entire collection to Opportunity sObject type collection- Maps and Lists

        List<Partner_Marketing_Plan__c> pmpTriggerNew = (List<Partner_Marketing_Plan__c>)newList;
        List<Partner_Marketing_Plan__c> pmpTriggerOld = (List<Partner_Marketing_Plan__c>)oldList;
        List<Partner_Marketing_Plan__c> submittedPMPs = new List<Partner_Marketing_Plan__c>();
        List<Partner_Marketing_Plan__c> pmpListForPartnerLookupUpdate = new List<Partner_Marketing_Plan__c>();
        Map<Id,Partner_Marketing_Plan__c> pmpTriggerNewMap = (Map<Id,Partner_Marketing_Plan__c>)newMap;
        Map<Id,Partner_Marketing_Plan__c> pmpTriggerOldMap = (Map<Id,Partner_Marketing_Plan__c>)oldMap;
        List<Partner_Marketing_Plan__c> pmpListForApprovedError = new List<Partner_Marketing_Plan__c>();
        //List<Partner_Marketing_Plan__c> pmpList = new List<Partner_Marketing_Plan__c>();

       
        Set<String> fieldsToCheck = new Set<String>{'Plan_Status__c','Active__c'};
        Set<String> statusesToCheck = new Set<String>{'Submitted', 'Approved'};
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,pmpTriggerNew);
        //SFDC-5995
        Map<Id, Partner_Marketing_Plan__c> mapOfAccountIdVsPMP = new Map<Id, Partner_Marketing_Plan__c>();

        for(SObject so: newList)
        {
            Partner_Marketing_Plan__c pmpRecNew = (Partner_Marketing_Plan__c)so;
            Partner_Marketing_Plan__c pmpRecOld = null;

            if(Trigger.isUpdate)
                pmpRecOld=(Partner_Marketing_Plan__c)oldMap.get(pmpRecNew.Id);

                //SFDC-4582 if user is making changes in approved PMP, its not allowed unless record is unlocked which will change the status.
                //system.debug(LoggingLevel.ERROR,'Plan_Funding_Approved_Roll_Up__c:::: '+Util.hasChanges('Approval_required__c',pmpRecOld,pmpRecNew) +' : '+ !Util.hasChanges('Cost_null_non_excluded__c',pmpRecOld,pmpRecNew) +' : '+ !Util.hasChanges('Plan_Funding_Approved_Roll_Up__c',pmpRecOld,pmpRecNew));
            if(Trigger.isUpdate && pmpRecNew.Plan_Status__c=='Approved' && !Util.hasChanges('Plan_Status__c',pmpRecOld,pmpRecNew) && !Util.hasChanges('Approval_required__c',pmpRecOld,pmpRecNew) && !Util.hasChanges('Cost_null_non_excluded__c',pmpRecOld,pmpRecNew) && !Util.hasChanges('Plan_Funding_Approved_Roll_Up__c',pmpRecOld,pmpRecNew)){
                pmpListForApprovedError.add(pmpRecNew);
            }

            if((Trigger.isInsert || (Trigger.isUpdate &&  Util.hasChanges(fieldsToCheck,pmpRecOld,pmpRecNew)))  && statusesToCheck.contains(pmpRecNew.Plan_Status__c) && pmpRecNew.Active__c)
                submittedPMPs.add(pmpRecNew);

            if(pmpRecNew.Partner_Submitter__c==null && UserInfo.getUserType().equals('PowerPartner') && 'Submitted'.equals(pmpRecNew.Plan_Status__c))
                pmpRecNew.Partner_Submitter__c=UserInfo.getUserId();

            if(Trigger.isInsert || (Trigger.isUpdate && pmpRecOld.Business_Plan__c!=pmpRecNew.Business_Plan__c))
                pmpListForPartnerLookupUpdate.add(pmpRecNew);
                //SFDC-4582
            if(!pmpListForApprovedError.isEmpty())
                PartnerMarketingClass.addPMPApprovedError(pmpListForApprovedError);

            //SFDC-5995
            if(Trigger.isInsert) {
                if(pmpRecNew.Partner__c != null) {
                    mapOfAccountIdVsPMP.put(pmpRecNew.Partner__c, pmpRecNew);
                }
            }

        }

        if(!submittedPMPs.isEmpty())
            PartnerMarketingClass.populateApproverFieldsAndEnsureSinglePMPPerPlanPeriod(submittedPMPs);

        if(!pmpListForPartnerLookupUpdate.isEmpty())
            PartnerMarketingClass.populatePartnerLookupOnPMPs(pmpListForPartnerLookupUpdate);
        //SFDC-5995
        if(!mapOfAccountIdVsPMP.isEmpty()) {
            PartnerMarketingClass.copyOverDefaultMDFCurrencyToPartnerMDFObjects(mapOfAccountIdVsPMP, 'Partner_Marketing_Plan__c');
        }

    }

    public override void beforeDeleteBeforeUndeleteTrigger(){

    }

    public override void afterInsertAfterUpdateTrigger(){
        List<Partner_Marketing_Plan__c> pmpTriggerNew = (List<Partner_Marketing_Plan__c>)newList;
        List<Partner_Marketing_Plan__c> pmpTriggerOld = (List<Partner_Marketing_Plan__c>)oldList;
        Map<Id,Partner_Marketing_Plan__c> pmpTriggerNewMap = (Map<Id,Partner_Marketing_Plan__c>)newMap;
        Map<Id,Partner_Marketing_Plan__c> pmpTriggerOldMap = (Map<Id,Partner_Marketing_Plan__c>)oldMap;
        List<Partner_Marketing_Plan__c> pmpList = new List<Partner_Marketing_Plan__c>();
        //List<Partner_Marketing_Plan__c> pmpSubmittedList = new List<Partner_Marketing_Plan__c>();
        for(SObject so: newList)
        {
            Partner_Marketing_Plan__c pmpRecNew = (Partner_Marketing_Plan__c)so;
            Partner_Marketing_Plan__c pmpRecOld = null;

            if(Trigger.isUpdate)
                pmpRecOld=(Partner_Marketing_Plan__c)oldMap.get(pmpRecNew.Id);
            //if(pmpRecNew.Plan_Status__c=='Submitted' && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Plan_Status__c',pmpRecOld,pmpRecNew))))
            //        pmpSubmittedList.add(pmpRecNew);
            if(pmpRecNew.Plan_Status__c=='Approved' && Trigger.isUpdate && Util.hasChanges('Plan_Status__c',pmpRecOld,pmpRecNew))
                    pmpList.add(pmpRecNew);
         
        }
         if(!pmpList.isEmpty()){
                PartnerMarketingClass pmpObj = new PartnerMarketingClass();
                Map<Id,Decimal> pmpToActivityCost = pmpObj.approvePlannedPMAs(pmpList);
                system.debug(LoggingLevel.ERROR,'pmpToActivityCost in Handler:: '+pmpToActivityCost);
                pmpObj.createFundBudget(pmpList,pmpToActivityCost);
                //SFDC-4582
                pmpObj.populatePlanFundingApproved(pmpList,pmpToActivityCost);
            }
    }

    public override void afterDeleteAfterUndeleteTrigger(){

    }
}
//Resoved Conflict