/******
 * Name : CommunityBlogCommentCtrlTest
 * Author : Vikas R
 * Test Class for : CommunityBlogCommentCtrl, SC_CommunityWrapper
 * @History
    --Developer       --Date          --Change
    Pinkesh           14-Feb-2019      ESESP-1602: Akatec Lightning Migration
******/

@istest
public class CommunityBlogCommentCtrlTest
{
    static testmethod void CommunityBlogCommentCtrlTestMethod()  
    {
        //Datasetup
        Knowledge__kav blogrec = new Knowledge__kav();
        blogrec.title = 'Test';
        blogrec.Community_Blog_Navigational_Topic__c = 'Test Topic';
        blogrec.Description__c = 'Test Descreption';
        blogrec.UrlName='TestURLName5';
        blogrec.IsVisibleInCsp=true;
        blogrec.IsVisibleInPkb =true;
        blogrec.IsVisibleInPrm =true;
        blogrec.Visibility__c = 'External';
        blogrec.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
        insert blogrec;
        system.debug('----blogrec----'+blogrec);
        Test.startTest();
        Knowledge__kav cb = [select id,KnowledgeArticleId from Knowledge__kav where id=:blogrec.Id];
        system.debug('----KnowledgeArticleId----'+cb.KnowledgeArticleId);       
        KbManagement.PublishingService.publishArticle(cb.KnowledgeArticleId, true);
        //ID blogId = [Select id from Community_Blog__kav where id =: blogrec.id].Id;
        //String articleId = [Select KnowledgeArticleId from Community_Blog__kav where id =: blogrec.id].KnowledgeArticleId;
        
        //Test mockup for SOSL
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = cb.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        //List<List<SObject>> searchList =[FIND 'TestURLName5' in ALL FIELDS returning Community_Blog__kav(KnowledgeArticleId), Glossary_Definition__kav(KnowledgeArticleId), How_To__kav(KnowledgeArticleId),Troubleshooting_Procedure__kav(KnowledgeArticleId),Question_Answer__kav(KnowledgeArticleId),Release_Notes__kav(KnowledgeArticleId)];
        
        
        
        //Create a blog Comment
        Community_Blog_Comment__c blogCommentrecord = new Community_Blog_Comment__c();
        blogCommentrecord.Comment__c = 'New Comment 1gfjsk';
        insert blogCommentrecord;
        
        //Create Instance of Controller
        //CommunityBlogCommentCtrl CB = new CommunityBlogCommentCtrl();
        
        //Calling first controller method
        CommunityBlogCommentCtrl.addBlogComment(blogCommentrecord,cb.Id,'TestURLName5');
        
        //Calling second controller method
        CommunityBlogCommentCtrl.fetchBlogComments(cb.Id,'TestURLName5');
        
        //Calling third Controller method
        CommunityBlogCommentCtrl.checkAccess();
        
        //Calling Fourth Controller method
        CommunityBlogCommentCtrl.fetchBlogComment(blogCommentrecord.Id);
        
        //Calling Fifth Controller method
        CommunityBlogCommentCtrl.deleteBlogComment(blogCommentrecord.Id);
        
        SC_CommunityWrapper p = new SC_CommunityWrapper();
        List<Knowledge__kav> nList = new List<Knowledge__kav>();
        nList.add(new Knowledge__kav());
        p.comment = new Community_Blog_Comment__c();
        p.communityDocument = new Customer_Community_Document__c();
        p.hasEdit = false;
        p.hasDel = false;
        p.totalRecords = 1;
        p.allBlogList = nList;
        Test.stopTest();
    }
}