public class UserUtils
{
    public static Map<Id, Id> getProfileIds(Set<Id> userIds)
    {
        Map<Id, Id> userIdToProfileId = new Map<Id,Id>();

        for(user u : [select id,profileid from user where id in :userIds])
        {
            userIdToProfileId.put(u.id, u.profileId);
        }

        return userIdToProfileId;
    }

}