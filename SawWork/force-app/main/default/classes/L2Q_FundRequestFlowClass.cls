public class L2Q_FundRequestFlowClass {
    public String currentPMA_Id{get;set;}
    //SFDC-6506
    public Boolean isPartnerUser{get;set;}
    public L2Q_FundRequestFlowClass(ApexPages.StandardController stdController) {
    	//SFDC-6506
    	isPartnerUser = false;
        if(UserInfo.getUserType().contains('Partner'))
            isPartnerUser = true;
        currentPMA_Id = '';
        if(ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id')) != null && ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id')) != ''){
            currentPMA_Id = ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id'));
        }
    }
    
}