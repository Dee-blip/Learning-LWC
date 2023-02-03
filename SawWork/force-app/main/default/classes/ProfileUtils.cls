public class ProfileUtils
{
    public static Boolean isSalesOrGSSUser()
    {
        List<String> profileListMDT = GsmUtilClass.getGSMSettingValuePartialMatch('ContactConversion_Prof_%');


        for(String ss  : profileListMDT)
        {
            if(ss.contains(UserInfo.getProfileId()))
                return true;
        }

        return false;
    }

    public static Boolean isSDR()
    {
        return GSMSettings.getValue('ProfileIdSDR').contains(UserInfo.getProfileId());
    }

    public static Boolean isBusinessOps()
    {
        return GSMSettings.getValue('ProfileIdBusinessOps').contains(UserInfo.getProfileId());
    }

    public static Boolean isMarketingOps()
    {
        return GSMSettings.getValue('ProfileIdMarketingOps').contains(UserInfo.getProfileId());
    }
}