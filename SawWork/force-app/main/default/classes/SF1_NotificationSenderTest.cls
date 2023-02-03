@isTest(seeAllData=false) 
public class SF1_NotificationSenderTest 
{
    static TestMethod void testTaskCommentChange()
    {

        Task t  = [select Id,Description from Task where What.Name like 'OA-%' Limit 1];

        Test.startTest();
       
        t.Description = 'test Description updated';
        update t;
        Test.stopTest();
    }

    static testmethod void testSendNotification()
    {
        Test.startTest();

        User u = [Select id from User where IsActive = true limit 1];
        u.SF1_Receive_OATask_ChatterFeed__c = true;
        update u;
        Task t  = [select Id,Description from Task where What.Name like 'OA-%' Limit 1];
        Id uId = u.Id;
        List<Id> recepients = new List<Id>();
        recepients.add(uId);

        SF1_NotificationSenderUtil.sendNotification(recepients, 'Test message', t.id);
        Test.stopTest();
    }
    static testmethod void postFeedWithLinkTest()
    {
        
        Test.startTest();

        User u = [Select id from User where IsActive = true limit 1];
        u.SF1_Receive_OATask_ChatterFeed__c = true;
        update u;
        Task t  = [select Id,Description from Task where What.Name like 'OA-%' Limit 1];
        Id uId = u.Id;


        SF1_NotificationSenderUtil.postFeedWithLink(uId, 'Test message', t.id);
        Test.stopTest();
    }
}