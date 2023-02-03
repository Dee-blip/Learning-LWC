public without sharing class SharingUtil {

    public static Map<Id, Id> getRoles(Set<Id> parIds){
        List<Id> ids = new List<Id>();
        ids.addAll(parIds);
        return SharingUtil.getRoles(ids);
    }

    public static Map<Id, Id> getRoles(List<Id> parIds){
        Map<Id, Id> accountIdUserRoleIdMap = new Map<Id, Id>();
        try{
            for (UserRole uRole : [Select  u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId In :parIds]) {
                accountIdUserRoleIdMap.put(uRole.PortalAccountId, uRole.Id);
            }
        }catch(Exception e){
            System.debug('Exception occured : ' + e.getMessage());
        }
        return accountIdUserRoleIdMap;
    }
  
    public static Map<Id,Id> getGroups(List<Id> roleIds){
        //get the group for the above roles
        Map<Id, Id> gMap = new Map<Id, Id>();
        List<Group> gList = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId In :roleIds and Type = 'RoleAndSubordinates'];
        for (Group g : gList) {
            gMap.put(g.RelatedId, g.Id);
        }
        return gMap;
    }
}