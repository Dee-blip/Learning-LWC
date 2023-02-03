/*
 * Create By Himanshu Verma on 24th July,20 as part of MARIT-642
 * This is responsible for creating chatter instances and inserting them.
 */

// MARIT-642
// As part of chatter creation we are creation a common function for FeedItem instance creation.
// Added the mandatory fields in the feed item instance
public class MARIT_ChatterUtilClass {
    public static FeedItem createChatterInstance(Id parentId, Id createdById, String body, boolean isRichText) {
        FeedItem item = new FeedItem();
        item.parentId = parentId;
        item.put('CreatedById', createdById);
        item.body = body;
        item.isRichText = isRichText;
        return item;
    }
    
    public static void insertChatters(List<FeedItem> feeditemList) {
        if(!feeditemList.isEmpty()) {
            DMLResults dmlres= new DMLResults();
            dmlres.dmlInsert(feeditemList);
            dmlres.withJobName('insertChatters').withClassName('MARIT_ChatterUtilClass.insertChatters').insertRecordsInErrorLog();
        }
    }
}