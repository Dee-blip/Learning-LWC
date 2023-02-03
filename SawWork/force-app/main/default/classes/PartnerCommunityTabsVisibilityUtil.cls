/*
 * Created the class - SFDC 6263 Partner Community Tabs visiblity
 */
public without sharing class PartnerCommunityTabsVisibilityUtil {
    
    @AuraEnabled
    public static List<NavigationMenuItem> getMenuItemsBasedOnTabs(List<NavigationMenuItem> allMeniItems) {
        List<NavigationMenuItem> eligibleMenuItems = new List<NavigationMenuItem>();
        List<String> objectsList = new List<String>();
        for (NavigationMenuItem ni:allMeniItems) {
            if (ni.Type =='SalesforceObject')
            	objectsList.add(ni.Target);
        }
        System.debug('Navigation objects list : '+objectsList);
        
        Map<String,Boolean> objectVisiblityMap = getObjectVisiblityMap(objectsList);
        System.debug('objectVisiblityMap :'+objectVisiblityMap);
        Set<String> tabEnabledAtProfileLevel = getTabsEnabledAtProfileLevel(objectsList);
        System.debug('tabEnabledAtProfileLevel :'+tabEnabledAtProfileLevel);
        
        /*  Show the Navigation Tab if -
         * 	- The Tab is not Salesforce Object
         *  - The Tab is visible (DefaultOn) at the Profile level
         *  - The User has the permission set required to make the Tab DefaultOn
         *  ELSE -
         *    Tab will not be visible
         */
        for (NavigationMenuItem ni:allMeniItems) {
            System.debug('ni.Target :'+ni.Target);
            
            if (ni.Type !='SalesforceObject' || (objectVisiblityMap.get(ni.Target) && (tabEnabledAtProfileLevel.contains(ni.Target) || tabVisiblityBasedOnPermissionSets(ni.Target)))) {
                eligibleMenuItems.add(ni);
            }
        }
        
        return eligibleMenuItems;
    }
    
    /* 
     * This method return the Tabs enabled at the Loggin In User profile level
     */
    public static Set<String> getTabsEnabledAtProfileLevel(List<String> objectList) {
        Set<String> tabsAvailableForProfile = new Set<String>();
        
        String loggedInUserProfile = Userinfo.getProfileId();
        System.debug('loggedInUserProfile :'+loggedInUserProfile);
        System.debug('Object List : '+objectList);
        List<String> tabsIds = getTabId(objectList);
        objectList.addAll(tabsIds);
        
        List<PermissionSetTabSetting> tabPermssions = [SELECT Name, Visibility, Parent.Profile.Name 
                                                       FROM PermissionSetTabSetting 
                                                       where Visibility = 'DefaultOn' 
                                                       			and Name IN:objectList
                                                       			and Parent.ProfileId=:loggedInUserProfile];
        
        Map<String,String> mapOfTabIdToAPIName = getTabsIdToTabAPIName();
        for (PermissionSetTabSetting tb:tabPermssions) {
            if (mapOfTabIdToAPIName.keySet().contains(tb.Name)) {
                tabsAvailableForProfile.add(mapOfTabIdToAPIName.get(tb.name));
            } else {
                tabsAvailableForProfile.add(tb.Name);
            }
            
        }
        return tabsAvailableForProfile;
    }
    
    public static List<String> getTabId(List<String> objectAPINameList) {
        Map<String,String> mapTOTabIdToTabAPIName = getTabsAPINameToTabId();
        List<String> tabIds = new List<String>();
        for (String s:objectAPINameList) {
            if (mapTOTabIdToTabAPIName.keySet().contains(s))
                tabIds.add(mapTOTabIdToTabAPIName.get(s));
        }
        System.debug('Tab Ids :'+tabIds);
        return tabIds;
    }
    
    public static Map<String,String> getTabsAPINameToTabId() {
        
        Map<String,String> result = new Map<String,String>();
        
        Map<String,String> mapTOTabIdToTabAPIName = GSMUtilClass.getPRMSettingKeyValue('PCTab');
        System.debug('mapTOTabIdToTabAPIName :'+mapTOTabIdToTabAPIName);
        for (String s:mapTOTabIdToTabAPIName.keySet()) {
            String objectAPIname = s.replace('PCTab','');
            objectAPIname = objectAPIname + '__c';
            result.put(objectAPIname, mapTOTabIdToTabAPIName.get(s));
        }
        System.debug('Result :'+result);
        return result;
    }
    
    public static Map<String,String> getTabsIdToTabAPIName() {
        
        Map<String,String> result = new Map<String,String>();
        
        Map<String,String> mapTOTabIdToTabAPIName = GSMUtilClass.getPRMSettingKeyValue('PCTab');
        System.debug('mapTOTabIdToTabAPIName :'+mapTOTabIdToTabAPIName);
        for (String s:mapTOTabIdToTabAPIName.keySet()) {
            String objectAPIname = s.replace('PCTab','');
            objectAPIname = objectAPIname + '__c';
            result.put(mapTOTabIdToTabAPIName.get(s), objectAPIname);
        }
        System.debug('Result :'+result);
        return result;
    }
    
    public static Boolean tabVisiblityBasedOnPermissionSets(String objectAPIName) {
        
        Boolean tabVisible = false;
        List<String> tabList = new List<String>();
        tabList.add(objectAPIName);
        Map<String,String> tabsIdToTabAPINameMap = getTabsAPINameToTabId();
        tabList.add(tabsIdToTabAPINameMap.get(objectAPIName));
        
        List<Id> permissionsSetIds = new List<Id>();
        Id loggedInUserId = Userinfo.getUserId();
        List<PermissionSetTabSetting> tabPermssions = [SELECT Name, Visibility, ParentId 
                                                        FROM PermissionSetTabSetting 
                                                        where name IN:tabList 
                                                            and Visibility = 'DefaultOn'
                                                       		and (Parent.Name Like 'Community%' OR Parent.Name Like 'Partner%')
                                                       ];
        
        if (tabPermssions.size() > 0) {
            for (PermissionSetTabSetting pts:tabPermssions) {
                permissionsSetIds.add(pts.ParentId);
            }
        }
        
        List<PermissionSetAssignment> permissions = [SELECT AssigneeId 
                                                     FROM PermissionSetAssignment 
                                                     where PermissionSetId IN:permissionsSetIds 
                                                     	and AssigneeId=:loggedInUserId];
        if (permissions.size() > 0)
            tabVisible = true;
        
        return tabVisible;
    } 
    
    public static Map<String,Boolean> getObjectVisiblityMap(List<String> objectsList) {
        System.debug('objectsList :::: '+objectsList);
        for (String s:objectsList) {
            System.debug('Object : '+s);
        }
        Map<String,Boolean> result = new Map<String,Boolean>();
        Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(objectsList);
        for (Schema.DescribeSObjectResult s:descResult) {
            result.put(s.getName(),s.isAccessible());
        }
        System.debug('result :'+result);
        return result;
    }

}