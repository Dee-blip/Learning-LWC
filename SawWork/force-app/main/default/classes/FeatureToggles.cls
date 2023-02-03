public class FeatureToggles
{
    // FEATURE TOGGLES AND THE MIND BOGGLES
    // TODO - Make these settings overrideable from tests

    // private static Map<String, Boolean> defaultSettings = new Map<String, Boolean>();

    // static
    // {
    //     for(FeatureToggle__mdt ft: [select Toggle__c, DeveloperName from FeatureToggle__mdt])
    //     {
    //         defaultSettings.put(ft.DeveloperName, ft.Toggle__c);
    //     }
    // }
    
    public static boolean getFeatureToggleValue(String developerName) {
        FeatureToggle__mdt ft = [select Toggle__c, DeveloperName from FeatureToggle__mdt where DeveloperName = :developerName limit 1];
        return ft.Toggle__c;
    }

    public static boolean IS_AWE_EXPOSED_TO_PARTNERS
    {
        get
        {
            return getFeatureToggleValue('LeadAutoConversionExposeAweToPartners');
        }
    }

    public static boolean isNewWorldConversion()
    {
        return IS_LEAD_AUTO_CONVERSION_ON || IS_REAL_TIME_CONVERSION_ON;
    }

    public static Boolean IS_LEAD_AUTO_CONVERSION_ON
    {
        get
        {
            return getFeatureToggleValue('LeadAutoConversion');
        }
    }

    public static Boolean IS_REAL_TIME_CONVERSION_ON
    {
        get
        {
            return getFeatureToggleValue('RealTimeLeadConversion');
        }
    }

    //Added as part of SFDC-2686
    public static Boolean IS_WYWYN_ACTIVITIES_PAGE_TOGGLE
    {
        get
        {
            return getFeatureToggleValue('WYWYNActivitiesPageToggle');
        }
    }

    // public static void switchOffRealTimeConversion()
    // {
    //     // ANAYLSIS : Method not called anywhere - SFORCE-79
    //     defaultSettings.put('RealTimeLeadConversion', true);
    // }
}