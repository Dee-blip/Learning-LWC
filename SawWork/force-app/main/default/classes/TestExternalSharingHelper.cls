/*
Author: Sonia Sawhney
Description: Contains test cases for External Sharing Helper Methods that are specific for Connection User
Created Date : 08/22/2014
*/
@isTest
private class TestExternalSharingHelper {
    
    static testMethod void TestCreateEmailMessages() {
        
         //Create all custom settings to set (seeAlldata=false)
         utilTestClass.createCustomSettings();
         
        Account acc = utilTestClass.CreateAccount('test account1');
        insert acc;
       
        Case objCase = utilTestClass.createCase(acc.Id);
             
        ExternalSharingHelper.RunFromtestClass = true; 
        Email_Message_Shadow__c  shadow = new Email_Message_Shadow__c (ParentId__c = objCase.Id, TextBody__c = 'Test Email', MessageDate__c = System.now(),
        Subject__c = 'Test Subject', To__c = 'ssawhney@akamai.com', FromAddress__c = 'ssawhney@akamai.com', FromName__c = 'Sonia Sawhney', Status__c = '0');
        insert shadow;
        
        list<Email_Message_Shadow__c> lstShadow = new list<Email_Message_Shadow__c>();
        lstShadow.add(shadow);
      
        ExternalSharingHelper.RunFromtestClass = false;
        ExternalSharingHelper.CreateEmailMessages(lstShadow);
          
        Id msgId = [Select LocalRecordId__c from Email_Message_Shadow__c  where Id = :shadow.Id].LocalRecordId__c;
        System.AssertNotEquals(msgId,null);   
    }  
    
    static testMethod void TestKnowledge() {
        
        //Create all custom settings to set (seeAlldata=false)
         utilTestClass.createCustomSettings();
        
        Knowledge__kav rec1 = new Knowledge__kav();
		rec1.title = '-RandomUniqueTitle323232323-';
		rec1.Description__c = 'Test Descreption';
        rec1.UrlName='RandomUniqueTitle323232323';
        rec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Troubleshooting_Procedure').getRecordTypeId();
        Insert rec1;
        
        Knowledge__kav ht=[select knowledgearticleid,articlenumber from Knowledge__kav where id =: rec1.id Limit 1];
    	KbManagement.PublishingService.publishArticle(ht.knowledgearticleid, true);
   
        
        List<KA_Generic_Article__c> kalist = new List<KA_Generic_Article__c>();
    	KA_Generic_Article__c articleShdow = new KA_Generic_Article__c(Title__c='Title 1', Summary__c='Summary', URL_Name__c='URL-1', Knowledge_Article_ID__c = ht.KnowledgeArticleId);
        kalist.add(articleShdow);
        KA_Generic_Article__c articleShdow2 = new KA_Generic_Article__c(Title__c='Title 2', Summary__c='Summary 2', URL_Name__c='URL-2');
		kalist.add(articleShdow2);
        insert kalist;
        List<Knowledge_Article_DR_Mapping__c> csList = new List<Knowledge_Article_DR_Mapping__c>();
        Knowledge_Article_DR_Mapping__c cs = new Knowledge_Article_DR_Mapping__c();
        cs.Article_Type__c = 'Knowledge__kav';
        cs.Field_Name__c  = 'Internal_Notes__c';
        cs.Generic_Field_Name__c = 'Internal_Notes__c'; 
        cs.Name = '25';
        csList.add(cs);
        Knowledge_Article_DR_Mapping__c cs2 = new Knowledge_Article_DR_Mapping__c();
        cs2.Article_Type__c = 'Knowledge__kav';
        cs2.Field_Name__c  = 'Visibility__c';
        cs2.Generic_Field_Name__c = 'Visibility__c'; 
        cs2.Name = '26';
        csList.add(cs2);
        
        Insert csList;
        ExternalSharingHelper.FetchFieldMappings();
        
        ExternalSharingHelper.CreateUpdateKbArticles('Knowledge__kav', csList, kalist, new Map<String, Id>(), new Map<String, Id>());
        List<sobject> ll = new List<sobject>();
        ll.add(rec1);
        ExternalSharingHelper.UpsertKbArticleShadow('Knowledge__kav', csList, ll);
        PartnerNetworkRecordConnection ps = new PartnerNetworkRecordConnection();
        //ps.ParentRecordId = csList[0].id;
        //Insert ps;
        List<PartnerNetworkRecordConnection> pslist = [SELECT Id from PartnerNetworkRecordConnection LIMIT 5];
        //pslist.add(ps);
        ExternalSharingHelper.DeletesObjects(pslist);
        
            
    }
    static testMethod void TestCaseArticle() {
        utilTestClass.createCustomSettings();
        Account acc = utilTestClass.CreateAccount('test account1');
        insert acc;
       
        Case objCase = utilTestClass.createCase(acc.Id);
        Case objCase2 = utilTestClass.createCase(acc.Id);
        
        
        Knowledge__kav rec1 = new Knowledge__kav();
		rec1.title = '-RandomUniqueTitle323232323-';
		rec1.Description__c = 'Test Descreption';
        rec1.UrlName='RandomUniqueTitle323232323';
        rec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Troubleshooting_Procedure').getRecordTypeId();
        Insert rec1;
        
        Knowledge__kav ht=[select knowledgearticleid,articlenumber from Knowledge__kav where id =: rec1.id Limit 1];
    	KbManagement.PublishingService.publishArticle(ht.knowledgearticleid, true);

        List<Case_Article__c> caseArticleLst = new List<Case_Article__c>();
        caseArticleLst.add(new Case_Article__c(Case__c = objCase.ID, KnowledgeArticle_URLName__c = rec1.UrlName));
        Insert caseArticleLst;
        
        List<CaseArticle> caseArticleLst2 = new List<CaseArticle>();
        caseArticleLst2.add(new CaseArticle(CaseID = objCase2.ID, KnowledgeArticleId = ht.KnowledgeArticleId));
        Insert caseArticleLst2;
        
        ExternalSharingHelper.CreateCaseArticle(caseArticleLst);
        ExternalSharingHelper.UpsertCaseArticleShadows(caseArticleLst2);
        ExternalSharingHelper.DeleteCaseArticleShadows(caseArticleLst);
        
    }
}