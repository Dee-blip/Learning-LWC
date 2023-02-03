public  class SF1_Controller_MergeOppty 
{
    @AuraEnabled
    public static Opportunity getOpportunityRecord(String oppId)
    {
        MigrateOpptyPageController pc = new MigrateOpptyPageController();
        return pc.getCurrentOpportunity(oppId);
    }

    @AuraEnabled
    public static List<Opportunity> getListOfOpportunities(String accId)
    {
        MigrateOpptyPageController pc = new MigrateOpptyPageController();
        return pc.getAccountAQLOpptysWithContactRole(accId);
    }

    @AuraEnabled
    public static List<Opportunity> getListOfAQLOpportunities(String oppName)
    {
        MigrateOpptyPageController pc = new MigrateOpptyPageController();
        return pc.getDuplicateAQLOpptysWithContactRole(oppName);
    }

    @AuraEnabled
    public static String updateOpportunity(String sourceOppListJSONString, Opportunity targetOpp)
    {
        String message = '';
        List<Opportunity> opptysWithContactRole;
        MigrateOpptyPageController pc = new MigrateOpptyPageController();
        try
        {
            if(targetOpp.RecordType.Name == 'AWE Opportunities')
            {
                opptysWithContactRole = pc.getDuplicateAQLOpptysWithContactRole(targetOpp.Name);
            }
            else
            {
                opptysWithContactRole = pc.getAccountAQLOpptysWithContactRole(targetOpp.AccountId);
            }
            pc.updateOppty(sourceOppListJSONString,targetOpp.id,opptysWithContactRole);
        }
        catch(Exception ex)
        {
            message = 'Error '+ex.getMessage()+ ' '+ex.getStackTraceString();
        }
        return message;
    }
    @AuraEnabled
    public static String getDuplicateOpportunityError()
    {
        return GsmUtilClass.getGSMSettingValue('No_Duplicate_Opportunity');
    }

    @AuraEnabled
    public static boolean isLightning() 
    {
        if( UserInfo.getUiThemeDisplayed() == 'Theme4d')
            return true;
        else
            return false;
    }
    
}