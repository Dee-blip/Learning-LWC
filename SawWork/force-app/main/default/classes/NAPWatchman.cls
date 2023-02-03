/*

Author - Neil Gaym'n - BECAUSE WATCHMEN ALWAYS NAP!

*/
public class NAPWatchman{
    private static Map<Id, String> pageIdToFirstAccessibleMenuItem = new Map<Id, String>();
    private static Set<Id> accessibleMenuItems = new Set<Id>();

    static
    {
        //SFDC-1673 - Added the new where clause to check if NAp Area is selcted as Type then check for the User's Contact's Account's NAP Area  

        for(NAP_Page_Security__c pbs : [Select NAP_Page_Builder__c, Security_Type_Id__c, Type__c from NAP_Page_Security__c  where (Security_Type_Id__c IN :CurrentUser.profileAndPermissionSets AND Type__c != 'NAP Area') OR (Type__c = 'NAP Area' AND Security_Type_Id__c = :CurrentUser.attributes.get('NAP Area')) ])
        {
            accessibleMenuItems.add(pbs.NAP_Page_Builder__c);
        }

        // get all the joins with parent as page and collect the ids of children

        for(NAP_Page_Builder_Join__c pbj : [select id, NAP_Page_Builder_Parent__r.Component_Type__c, NAP_Page_Builder_Parent__c, NAP_Page_Builder_Child__r.Name from NAP_Page_Builder_Join__c where NAP_Page_Builder_Parent__r.Component_Type__c='Page' and NAP_Page_Builder_Child__r.Component_Type__c='Main Menu' and NAP_Page_Builder_Child__c in :accessibleMenuItems order by Order__c DESC])
        {
            pageIdToFirstAccessibleMenuItem.put(pbj.NAP_Page_Builder_Parent__c, pbj.NAP_Page_Builder_Child__r.Name);
        }
    }


    public static Boolean allows(NAP_Page_Builder__c menuItem)
    {
        if(menuItem.Component_Type__c.equalsIgnoreCase('Main Menu'))
            return accessibleMenuItems.contains(menuItem.Id);
        else if(menuItem.Component_Type__c.equalsIgnoreCase('Page'))
            return pageIdToFirstAccessibleMenuItem.containsKey(menuItem.Id);
        return false;
    }

    public static String getAddress(Id pageId)
    {
        return NAPURLService.getLink(pageIdToFirstAccessibleMenuItem.get(pageId));
    }
}