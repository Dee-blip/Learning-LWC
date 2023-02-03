/*Author: Ruchika Sharma
    Version: 2.0
    SFDC-6322: PMP-PMA flow*/
public with sharing class L2Q_PMPFlowController {

    public Boolean isPartnerUser{get;set;}
    public String partnerUserURL{get;set;}
    public String internalUserURL{get;set;}
    public String internalUserAccId{get;set;}

    public L2Q_PMPFlowController(ApexPages.StandardController stdController) {
        String partnerPlanId='';
        isPartnerUser = false;
        if(UserInfo.getUserType().contains('Partner'))
            isPartnerUser = true;
        partnerUserURL = GSMUtilClass.getGSMSettingValue('Flow_PartnerUserURLForPMCreation');
        internalUserURL = GSMUtilClass.getGSMSettingValue('Flow_InternalUserURLForPMCreation');
        internalUserAccId = 'empty';
        if(ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('PB_PMDFP_Relationship_Id')) != null && ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('PB_PMDFP_Relationship_Id')) != ''){ //CF00N0f00000FSOyo_lkid
            partnerPlanId = ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('PB_PMDFP_Relationship_Id'));
        }
        system.debug(LoggingLevel.ERROR,'partnerPlanId:: '+partnerPlanId);
        if(!String.isEmpty(partnerPlanId)){
            SFDC_Channel_Account_Plan__c pbp = [select id, Partner_Account__c from SFDC_Channel_Account_Plan__c where id=:partnerPlanId];
            if(pbp!=null)
                internalUserAccId = pbp.Partner_Account__c;
        }
        system.debug(LoggingLevel.ERROR,'internalUserURL:: '+internalUserURL);
    }

}