public class PlatformUtils
{
    public static Set<String> getFieldsForSiebel(String sObjType, Id profileId)
    {
        Map<String, Set<String>> integrationProfileIdToSiebelFields = GSMSettings.getSyncToSiebelFields(sObjType, true);

        if(integrationProfileIdToSiebelFields.containsKey(profileId))
        {
            return integrationProfileIdToSiebelFields.get(profileId);
        }
        else
        {
            return integrationProfileIdToSiebelFields.get('NonIntegrationUser');
        }
    }

}