@isTest
public class SC_CommunityVideoPlayer_Test
{
    static testmethod void VideoPlayerDocumentTest()
    {
        test.startTest();
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.mp4',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title != ''];
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', contentVersion_1.id);
        Test.setCurrentPage(pageRef);
        
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        test.stopTest();
    }
    static testmethod void VideoPlayerDocumentf4mTest()
    {
        test.startTest();
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.f4m',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title != ''];
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', contentVersion_1.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        test.stopTest();
    }
    static testmethod void VideoPlayerDocumentwebmTest()
    {
        test.startTest();
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.webm',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title != ''];
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', contentVersion_1.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        test.stopTest();
    }
    static testmethod void VideoPlayerDocumentflvTest()
    {
        test.startTest();
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.flv',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title != ''];
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', contentVersion_1.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        test.stopTest();
    }
    static testmethod void VideoPlayerDocumentmkvTest()
    {
        test.startTest();
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.mkv',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title != ''];
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', contentVersion_1.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        test.stopTest();
    }
    static testmethod void VideoPlayerCVTest()
    {
        test.startTest();
        //List<Topic> TopicId2=[Select id,name,networkid from topic where networkid!=null limit 2];
        
        //Create new Topic 
        Topic newTopic = new Topic(Name='Test Topic seealldata',NetworkId=null);
        insert newTopic;
        //
        
        Community_Video__c cv = new Community_Video__c();
        cv.Name = 'Test';
        cv.Topic_Id__c = newTopic.id;
        insert cv;
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', cv.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
        SC_CommunityVideoPlayer.fetchdownLoadURL(String.valueOf(cv.id));
        SC_CommunityVideoPlayer.convertToCommunityURL(String.valueOf(cv.id));
        SC_CommunityVideoPlayer.fetchContentList(String.valueOf(newTopic.id));
        SC_CommunityVideoPlayer.generateVideoLink(String.valueOf(cv.id));
    }
    static testmethod void VideoPlayerNCTest()
    {
        test.startTest();
        Community_Blog_Comment__c cv = new Community_Blog_Comment__c();
        //cv.Name = 'Test';
        insert cv;
        PageReference pageRef = Page.SC_CommunityVideoPlayer; // Add your VF page Name here
        pageRef.getParameters().put('id', cv.id);
        Test.setCurrentPage(pageRef);
        SC_CommunityVideoPlayer scVp = new SC_CommunityVideoPlayer();
    }
}