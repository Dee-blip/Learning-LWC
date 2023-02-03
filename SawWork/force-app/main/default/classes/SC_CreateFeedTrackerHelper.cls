/* 
DATE                DEVELOPER               CHANGE
________________________________________________________________________________
23-Aug-2018     Vandhana Krishnamurthy       Helper class to create/edit timestamps for posts(FeedItems) 
                                             on Service Incident Notification Group
________________________________________________________________________________
*/

public class SC_CreateFeedTrackerHelper 
{
    public static void createFeedItemTrackerRec(List<FeedItem> servNotifFeedItemLst, Boolean isInsert)
    {
        List<Service_Incident_Notif_Group_Tracker__c> trackerRec = new List<Service_Incident_Notif_Group_Tracker__c>();
        Service_Incident_Notif_Group_Tracker__c rec;
        for(FeedItem fi : servNotifFeedItemLst)
        {
            rec = new Service_Incident_Notif_Group_Tracker__c();
            rec.FeedItem_Post_ID__c = fi.Id;
            if(isInsert)
            {
                rec.Created_Time__c = fi.CreatedDate;
                rec.FeedItem_Created_By__c = fi.CreatedById;
            }
            else
            {
                rec.Edited_Time__c = fi.LastEditDate;
                rec.Edited_By__c = fi.LastEditById;
            }
            if(fi.Body != null)
            {
                rec.FeedItem_Post_Body__c = fi.Body.replaceAll('</p>','\n');
                rec.FeedItem_Post_Body__c = rec.FeedItem_Post_Body__c.replaceAll('<[^>]+>',' ');
            }
            if(fi.Revision != null)
            {
                rec.FeedItem_Revision__c = fi.Revision;
            }
            trackerRec.add(rec);
        }
        if(!trackerRec.isEmpty())
        {
           insert trackerRec; 
        }
    }
}