public class PartnerCommunityNavigationController {
    
    //private List<List<SObject>> searchList;
    private Map<String,String> mapOfObjectToFields;
	
    @auraEnabled
    public static List<NavigationMenuItem> getNavigationItems() {
        // Getting the id of Navigation set for Partner Community - Default_Navigation3 (id=0Lm63000000CbH0CAK)
        List<NavigationMenuItem> finalNavigation = new List<NavigationMenuItem>();
        List<NavigationMenuItem> subMenu = new List<NavigationMenuItem>();
        String linkSetId = getlinkSetId();

        // Get a list of 'NavigationMenuItem' that are 'Live' and have a 'NavigationLinkSetId' equal to the 'id' above.
        List<NavigationMenuItem> reg = new LIST<NavigationMenuItem>();
        reg = [SELECT Id,Label, NavigationLinkSetId, Target, Status, DraftRowID, AccessRestriction, Position, Type
               FROM NavigationMenuItem 
               WHERE Status = 'Live' 
               		AND NavigationLinkSetId = :linkSetId 
              ORDER By Position ASC];
        
        reg = PartnerCommunityTabsVisibilityUtil.getMenuItemsBasedOnTabs(reg);
        
        return reg;
    }
    
    @auraEnabled
    public static List<NavigationMenuItem> getQuickCreateItems() {
        // Getting the id of Navigation set for Partner Community - Default_Navigation3 (id=0Lm63000000CbH0CAK)
        List<NavigationMenuItem> finalNavigation = new List<NavigationMenuItem>();
        List<NavigationMenuItem> subMenu = new List<NavigationMenuItem>();
        String linkSetId = getlinkSetId();

        // Get a list of 'NavigationMenuItem' that are 'Live' and have a 'NavigationLinkSetId' equal to the 'id' above.
        List<NavigationMenuItem> reg = new LIST<NavigationMenuItem>();
        List<NavigationMenuItem> creatableReg = new LIST<NavigationMenuItem>();
        
        reg = [SELECT Id,Label, NavigationLinkSetId, Target, Status, DraftRowID, AccessRestriction, Position, Type
               FROM NavigationMenuItem WHERE Status = 'Live' AND NavigationLinkSetId = :linkSetId and type = 'SalesforceObject' 
               ORDER By Position ASC];
        
        Map<String,NavigationMenuItem> objnameToNavItemMap = new Map<String,NavigationMenuItem>();
        List<String> objectsList = new List<String>();
        for (NavigationMenuItem ni:reg) {
            objnameToNavItemMap.put(ni.Target,ni);
        }
        
        Map<String,Boolean> result = new Map<String,Boolean>();
        List<String> objList = new List<String>(objnameToNavItemMap.keySet());
        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(objList);
        for (Schema.DescribeSObjectResult s:descResult) {
            if(s.isCreateable()) {
                creatableReg.add(objnameToNavItemMap.get(s.getName()));
            }
        }
        
        reg = PartnerCommunityTabsVisibilityUtil.getMenuItemsBasedOnTabs(creatableReg);
        
        return reg;
    }
    
    public static List<String> getCommunityObject() {
         List<String> objectsList = new List<String>();
         List<NavigationMenuItem> navigationItems = getNavigationItems();
         System.debug('Navigation Items :'+navigationItems);
         if (navigationItems != null && navigationItems.size() > 0) {
             for (NavigationMenuItem ni:navigationItems) {
                 if (ni.Type=='SalesforceObject') {
                     objectsList.add(ni.Target);
                 }
             }
         }
         return objectsList;
    }

    @AuraEnabled
    public static string getNavigationUrl(String navigationMenuId){
        String retUrl = '';
        List<NavigationMenuItem> reg = [SELECT Id,Label,DefaultListViewId, NavigationLinkSetId, Target, Status, DraftRowID, AccessRestriction, Position, Type
                                        FROM NavigationMenuItem 
                                        WHERE Status = 'Live' 
                                                AND Id = :navigationMenuId];

        if (reg.size() > 0) {
            NavigationMenuItem navItem = reg[0];
            if (navItem.Type=='SalesforceObject') {
                retUrl += '/partners/s/recordlist/'+navItem.Target+'/Default';
            }else {
                retUrl += '/partners/s'+navItem.Target;
            }
        }
        return retUrl;
    }

    public static String getlinkSetId() {
        String navId = GsmUtilClass.getPRMSettingValue('PartnerCommunityNavLinkId');
        NavigationLinkSet linkSet = [SELECT Id, DeveloperName, MasterLabel, NetworkId 
                                     FROM NavigationLinkSet
                                     Where id=:navId];
        return linkSet.id;
    }
    
    @AuraEnabled
    public static String getButtonUrl(String objectName) {
        return PartnerCommunityRecordsController.getButtonUrl(objectName);
    }
}