/******
 * Name : CommunityBlogCtrlTest
 * Author : Vikas R
 * Test Class for : CommunityBlogCtrl
 * @History
    --Developer       --Date          --Change
    Pinkesh           14-Feb-2019      ESESP-1602: Akatec Lightning Migration
******/

@istest
public class CommunityBlogCtrlTest
{
    @testSetup static void createData()
    {
        Id networkId = [Select Id,Name from Network where name = 'Customer Community' Limit 1].Id;
        List<Topic> topicList = new List<Topic>();
        Topic tpic;
        for(Integer i=0;i<10;i++)
        {
            tpic = new Topic();
            if(i == 0)
            {
                tpic.Name = 'Test Topic2Fieldtheory';
            }
            else
                tpic.Name = 'Web Performance Test'+i;
            tpic.Description = 'Web Performance'+i;
            tpic.NetworkId = networkId;
            topicList.add(tpic);
        }
        insert topicList;
    }
    
    static testmethod void CommunityBlogTest()
    {
        test.startTest();
        CommunityBlogCtrl CB = new CommunityBlogCtrl();
        
        //TestData
        Knowledge__kav blogrec = new Knowledge__kav();
        blogrec.title = 'Test';
        blogrec.Community_Blog_Navigational_Topic__c = 'Test Topic';
        blogrec.Description__c = 'Test Descreption';
        blogrec.UrlName='TestURLNamej1';
        blogrec.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
        System.debug('---------------- blogrec before insert '+ blogrec);
        insert blogrec;
        System.debug('---------------- blogrec after insert '+ blogrec);
        
        List<Topic> TopicId2 = [SELECT Id,Name,Networkid 
                                FROM Topic 
                                WHERE Networkid != NULL limit 2];
        //List<Topic> TopicId2=[Select id,name,networkid from topic where networkid!=null limit 1];
        
        //Data category method
        Id Knowledgearticleid = [Select KnowledgeArticleId from Knowledge__kav where id =: blogrec.id].KnowledgeArticleId;
        //KbManagement.PublishingService.publishArticle(Knowledgearticleid, true);
        /*String attachTitle = 'New Attachment Title';        
        String attachBody = 'New Attachment';
        String attachType = 'txt';*/
        
        CommunityBlogCtrl.createBlogRecord(blogrec,TopicId2[0].id);
        
        CommunityBlogCtrl.fetchCommunityBlogs('Test Topic',TopicId2[0].id,'2','5');
        CommunityBlogCtrl.fetchCommunityBlogs('',TopicId2[0].id,'2','5');
        CommunityBlogCtrl.getPageCountInfo('1',TopicId2[1].id,'Test Topic','2','5');
        CB.getDataCategoryApiName('Blog');
        
        //Create topic
        //String TopicId = [Select id,name,networkid from topic where networkid!=null limit 1].Id;
        System.debug('-----------------blogrec.Id' + blogrec.Id);
        
        //CommunityBlogCtrl.fetchArticleType(blogrec.Id);
        CommunityBlogCtrl.getPageCountChange('2','2','5');
        CommunityBlogCtrl.getPageCountChange('1','2','5');
        CommunityBlogCtrl.getPageCountChange('2','5','2');
        //CommunityBlogCtrl.deleteBlogRecord(blogrec.Id);
        CommunityBlogCtrl.checkAccess();
        CommunityBlogCtrl.checkAdminAccess(blogrec.UrlName);
        
        //Declaring Classes
        CommunityBlogCtrl.JSONCategory Json = new CommunityBlogCtrl.JSONCategory();
        Json.label = 'test';
        Json.name= 'test';
        Json.topCategories = new List<CommunityBlogCtrl.TopLevelCategory>();
        
        CommunityBlogCtrl.TopLevelCategory TopLevel = new CommunityBlogCtrl.TopLevelCategory();
        CommunityBlogCtrl.ChildLevelCategory ChildLevel = new CommunityBlogCtrl.ChildLevelCategory();
        ChildLevel.label = 'test';
        ChildLevel.name= 'test';
        test.stopTest();
    }
    
    static testmethod void CommunityBlogTest1()
    {
        test.startTest();
        User usr = [Select Id,Name from User where isActive = true AND Profile.Name = 'System Administrator' and UserPermissionsKnowledgeUser = true limit 1];
        System.runAs(usr)
        {
            Knowledge__kav blogrec1 = new Knowledge__kav();
            blogrec1.title = 'Test2';
            blogrec1.Community_Blog_Navigational_Topic__c = 'Test Topic2';
            blogrec1.Description__c = 'Test Descreption';
            blogrec1.UrlName='TestURLName2j2';
            blogrec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
            insert blogrec1;
            
            List<Topic> TopicId2=[Select id,name,networkid from topic where networkid!=null limit 2];
            Id Knowledgearticleid = [Select KnowledgeArticleId from Knowledge__kav where id =: blogrec1.id].KnowledgeArticleId;
            KbManagement.PublishingService.publishArticle(Knowledgearticleid, true);
            CommunityBlogCtrl.createBlogRecord(blogrec1,'');
            
            CommunityBlogCtrl.fetchCommunityBlogs('',TopicId2[1].id,'2','5');
            CommunityBlogCtrl.checkKBAccess();
            CommunityBlogCtrl.getPageCountInfo('1',TopicId2[1].id,'','2','5');
        }
        test.stopTest();
    }
    static testmethod void CommunityBlogTest2()
    {
        test.startTest();
        
        Knowledge__kav blogrec1 = new Knowledge__kav();
        blogrec1.title = 'Test2';
        blogrec1.Community_Blog_Navigational_Topic__c = 'Test Topic2';
        blogrec1.Description__c = 'Test Descreption';
        blogrec1.UrlName='TestURLName2h3';
        blogrec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
        List<Topic> TopicId2=[Select id,name,networkid from topic where networkid!=null limit 2];
        /*String attachTitle = 'New Attachment Title';        
        String attachBody = 'New Attachment';
        String attachType = 'txt';*/
        CommunityBlogCtrl.createBlogRecord(blogrec1,TopicId2[0].id);
        
        test.stopTest();
    }
    
    static testmethod void CommunityBlogTest3()
    {
        test.startTest();
        User usr = [Select Id,Name from User where isActive = true AND Profile.Name = 'System Administrator' and UserPermissionsKnowledgeUser = true limit 1];
        System.runAs(usr)
        {
            Knowledge__kav blogrec1 = new Knowledge__kav();
            blogrec1.title = 'Test2';
            blogrec1.Community_Blog_Navigational_Topic__c = 'Test Topic2Fieldtheory';
            blogrec1.Description__c = 'Test Descreption';
            blogrec1.UrlName='TestURLName2j4';
            blogrec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
            insert blogrec1;
            
            Id Knowledgearticleid = [Select KnowledgeArticleId from Knowledge__kav where id = :blogrec1.id].KnowledgeArticleId;
            KbManagement.PublishingService.publishArticle(Knowledgearticleid, true);
            //Id articleId = [Select id, Knowledgearticleid from Knowledge__kav where PublishStatus = 'Online' and Language = 'en_US' and Knowledgearticleid =:Knowledgearticleid limit 1].id;
            CommunityBlogCtrl.fetchBlogRecord(blogrec1.Id);
            CommunityBlogCtrl.deleteBlogRecord(blogrec1.Id);
            CommunityBlogCtrl.fetchCommunityId();
        }
        test.stopTest();
    }
    //Upload Attachmnet
    static testmethod void CommunityBlogTest4(){
        Knowledge__kav blogrec1 = new Knowledge__kav();
        blogrec1.title = 'Test2';
        blogrec1.Community_Blog_Navigational_Topic__c = 'Test Topic2Fieldtheory';
        blogrec1.Description__c = 'Test Descreption';
        blogrec1.UrlName='TestURLName2j6';
        blogrec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
        insert blogrec1;
        
        Id Knowledgearticleid = [Select KnowledgeArticleId from Knowledge__kav where id = :blogrec1.id].KnowledgeArticleId;
        KbManagement.PublishingService.publishArticle(Knowledgearticleid, true);
        
        String attachTitle = 'New Attachment Title';        
        String attachBody = 'New Attachment';
        String attachType = 'txt';
        
        CommunityBlogCtrl.uploadFile(blogrec1.id, attachTitle, attachBody, attachType);
    }
}