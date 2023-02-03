public class OpportunityTriggerDataClass extends TriggerAbstractDataClass{ //implements TriggerAbstractDataClass{
    
    

    public OpportunityTriggerDataClass() 
    {

    }

    public override void init()
    {
        
        //initializeDependency();
        getRecordTypeInfo();
        getCustomSettings();
        getCustomMetadata();
        getUserTypeInfo();
        getUserNameInfo();
    }

    public override String getUserTypeInfo()
    {
        return UserInfo.getUserType();
    }
    public override String getUserNameInfo()
    {
        return UserInfo.getName();
    }
    /*public override void initializeDependency()
    {
        System.debug('initializeDependency');
    }*/

    public override void getRecordTypeInfo()
    {
        System.debug('getRecordTypeInfo');
        oppty_rt_Map = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();
        //currentUserProfile = [select Name from profile where id = :userinfo.getProfileId()];

    }

    public override Id getRecordTypeInfoByName(String recordTypeName)

    {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();    

    }

    public override void getCustomSettings()
    {
        System.debug('getCustomSettings');
    }

    public  override void getCustomMetadata()
    {
        System.debug('getCustomMetadata');
        amgOppRecordType = GsmUtilClass.getGSMSettingValue('OppTrigger_bi_amgOppRecordType');
        listOfManageForecastOverrideSettings = [Select Id,DeveloperName,MRR_override__c from Manage_Forecast_Date_Category_n_Override__mdt limit 50000];
        opptySALStage = GSMSettings.getValue('SAL_Date_Stage_Names');
        opptyNascentStage = GSMSettings.getValue('LeadAutoConvert_NascentStageName');
        opptyUnqualifiedLeadClosedStage = GSMSettings.getValue('LeadAutoConvert_UnqualifiedLeadStageName');

    }

    
}