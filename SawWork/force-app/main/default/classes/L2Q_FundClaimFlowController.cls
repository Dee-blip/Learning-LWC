//SFDC-6038
public with sharing class L2Q_FundClaimFlowController {

    public String curFRId{get;set;}
    //SFDC-6506
    public Boolean isPartnerUser{get;set;}
    
    public L2Q_FundClaimFlowController(ApexPages.StandardController stdController) {
        //SFDC-6506
        isPartnerUser = false;
        if(UserInfo.getUserType().contains('Partner'))
            isPartnerUser = true;
        curFRId = '';
        if(ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FC_FR_RelationshipId')) != null && ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FC_FR_RelationshipId')) != ''){
            curFRId = ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FC_FR_RelationshipId'));
        }
        //else{
        //    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'error: Relationship with Fund Request Cannot be established. Please contact admin.');
        //    ApexPages.addMessage(msg);
        //}
    }
}