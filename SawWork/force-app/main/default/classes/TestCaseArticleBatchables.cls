/*
Author: Denise Bacher (salesforce.com)
Description: Contains test cases for BatchableCaseArticleCreate, BatchableCaseArticleShadow, BatchableCaseArticleDelete
Created Date : 10/31/2013 

Modified by prathore on 20/12/2016 added method TestScheduleDeleteCaseArticleBatch() to cover scheduleDeleteCaseArticleBatch class
*/
@isTest
private class TestCaseArticleBatchables {/*
    
    static {
        utilTestClass.createCustomSettings();
    }
    
    static testMethod void testBatchableCaseArticleCreate() {
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        System.runas(cUser) {
            insert usr;
        } 
        
        List<SObject> articles = new List<SObject>();
        articles.add(new How_To__kav(Title='How To Test1', UrlName='How-To-Test1'+System.currentTimeMillis(), Summary='How To Summary1'));
        articles.add(new How_To__kav(Title='How To Test2', UrlName='How-To-Test2'+System.currentTimeMillis(), Summary='How To Summary2'));
        articles.add(new How_To__kav(Title='How To Test3', UrlName='How-To-Test3'+System.currentTimeMillis(), Summary='How To Summary3'));
        articles.add(new How_To__kav(Title='How To Test4', UrlName='How-To-Test4'+System.currentTimeMillis(), Summary='How To Summary4'));
        articles.add(new How_To__kav(Title='How To Test5', UrlName='How-To-Test5'+System.currentTimeMillis(), Summary='How To Summary5'));
        insert articles;
        
        List<How_To__kav> howTo = [Select ID, KnowledgeArticleId, PublishStatus From How_To__kav Where ID IN : articles];
        for(How_To__kav k : howTo){
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        }
        
        List<Case> caseLst = utilTestClass.createCases(40, false, usr.Id, '1');
        insert caseLst;
        
        List<CaseArticle> caseArticleLst = new List<CaseArticle>();
        for(Case c : caseLst){
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[0].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[1].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[2].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[3].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[4].KnowledgeArticleId));
        }
        insert caseArticleLst;
        
        Set<String> caseArticleIds = new Set<String>();
        for(CaseArticle c : caseArticleLst){
            caseArticleIds.add(c.ID);
        }
        
        Test.startTest();
            Database.executeBatch(new BatchableCaseArticleCreate());
        Test.stopTest();
        
        List<Case_Article__c> shadows = [Select ID From Case_Article__c Where CaseArticleID__c IN: caseArticleIds];
        System.assertEquals(200, shadows.size());
    }
    
    static testMethod void testBatchableCaseArticleShadow() {
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        System.runas(cUser) {
            insert usr;
        } 
        
        List<How_To__kav> articles = new List<How_To__kav>();
        articles.add(new How_To__kav(Title='How To Test1', UrlName='How-To-Test1'+System.currentTimeMillis(), Summary='How To Summary1'));
        articles.add(new How_To__kav(Title='How To Test2', UrlName='How-To-Test2'+System.currentTimeMillis(), Summary='How To Summary2'));
        articles.add(new How_To__kav(Title='How To Test3', UrlName='How-To-Test3'+System.currentTimeMillis(), Summary='How To Summary3'));
        articles.add(new How_To__kav(Title='How To Test4', UrlName='How-To-Test4'+System.currentTimeMillis(), Summary='How To Summary4'));
        articles.add(new How_To__kav(Title='How To Test5', UrlName='How-To-Test5'+System.currentTimeMillis(), Summary='How To Summary5'));
        insert articles;
        
        List<How_To__kav> howTo = [Select ID, KnowledgeArticleId, PublishStatus From How_To__kav Where ID IN : articles];
        for(How_To__kav k : howTo){
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        }
        
        List<Case> caseLst = utilTestClass.createCases(40, false, usr.Id, '1');
        insert caseLst;
        
        List<Case_Article__c> caseArticleLst = new List<Case_Article__c>();
        for(Case c : caseLst){
            caseArticleLst.add(new Case_Article__c(Case__c = c.ID, KnowledgeArticle_URLName__c = articles[0].UrlName));
            caseArticleLst.add(new Case_Article__c(Case__c = c.ID, KnowledgeArticle_URLName__c = articles[1].UrlName));
            caseArticleLst.add(new Case_Article__c(Case__c = c.ID, KnowledgeArticle_URLName__c = articles[2].UrlName));
            caseArticleLst.add(new Case_Article__c(Case__c = c.ID, KnowledgeArticle_URLName__c = articles[3].UrlName));
            caseArticleLst.add(new Case_Article__c(Case__c = c.ID, KnowledgeArticle_URLName__c = articles[4].UrlName));
        }
        insert caseArticleLst;
        
        Test.startTest();
            Database.executeBatch(new BatchableCaseArticleShadow());
        Test.stopTest();
        
        List<CaseArticle> caseArticles = [Select ID From CaseArticle Where CaseID IN: caseLst];
        System.assertEquals(200, caseArticles.size());
    }
    
    static testMethod void testBatchableCaseArticleDelete() {
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        System.runas(cUser) {
            insert usr;
        } 
        
        List<SObject> articles = new List<SObject>();
        articles.add(new How_To__kav(Title='How To Test1', UrlName='How-To-Test1'+System.currentTimeMillis(), Summary='How To Summary1'));
        articles.add(new How_To__kav(Title='How To Test2', UrlName='How-To-Test2'+System.currentTimeMillis(), Summary='How To Summary2'));
        articles.add(new How_To__kav(Title='How To Test3', UrlName='How-To-Test3'+System.currentTimeMillis(), Summary='How To Summary3'));
        articles.add(new How_To__kav(Title='How To Test4', UrlName='How-To-Test4'+System.currentTimeMillis(), Summary='How To Summary4'));
        articles.add(new How_To__kav(Title='How To Test5', UrlName='How-To-Test5'+System.currentTimeMillis(), Summary='How To Summary5'));
        insert articles;
        
        List<How_To__kav> howTo = [Select ID, KnowledgeArticleId, PublishStatus From How_To__kav Where ID IN : articles];
        for(How_To__kav k : howTo){
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
        }
        
        List<Case> caseLst = utilTestClass.createCases(40, false, usr.Id, '1');
        insert caseLst;
        
        List<CaseArticle> caseArticleLst = new List<CaseArticle>();
        for(Case c : caseLst){
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[0].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[1].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[2].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[3].KnowledgeArticleId));
            caseArticleLst.add(new CaseArticle(CaseID = c.ID, KnowledgeArticleId = howTo[4].KnowledgeArticleId));
        }
        insert caseArticleLst;
        
        List<Case_Article__c> shadowCaseArticleLst = new List<Case_Article__c>();
        for(CaseArticle c : caseArticleLst){
            shadowCaseArticleLst.add(new Case_Article__c(Case__c = c.CaseID, KnowledgeArticleId__c = c.KnowledgeArticleId, CaseArticleID__c = c.ID));
        }
        insert shadowCaseArticleLst;
        
        delete caseArticleLst;
        
        Test.startTest();
            Database.executeBatch(new BatchableCaseArticleDelete());
        Test.stopTest();
        
        List<Case_Article__c> shadows = [Select ID From Case_Article__c Where ID IN: shadowCaseArticleLst];
        System.assertEquals(0, shadows.size());
    }
    
    static testMethod void TestScheduleDeleteCaseArticleBatch()
    {   
        Test.StartTest();
        scheduleDeleteCaseArticleBatch s = new scheduleDeleteCaseArticleBatch();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('TestScheduleDeleteCaseArticleBatch', sch, s);
        Test.StopTest();
    }*/
}