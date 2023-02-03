public class CommunityHomeCtrl {
    @AuraEnabled
    public static String fetchNewsEventsId(String blogId){
        Id topicId = null;
        topicId = [select id from topic where name = 'News & Events' and networkId in(select id from network where name = 'Customer Community')].Id;
        return String.valueOf(topicId);
    }
}