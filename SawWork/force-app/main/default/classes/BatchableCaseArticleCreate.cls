/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Class used for updating the shadow object from the CaseArticle object
        This is run from BatchableKnowledgeArticles so the new articles will be created before any case articles
    Created Date : 10/30/2013
    ======================================================================== */
global with sharing class BatchableCaseArticleCreate implements Database.Batchable<sObject> {
    //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext BC){   
        DateTime lastJobRunDate;
        AggregateResult result = [Select max(CompletedDate) jobDate From AsyncApexJob
            Where ApexClass.Name = 'BatchableCaseArticleShadowCreate' And Status = 'Completed'];
        
        if(result != null && result.get('jobDate') != null){
            lastJobRunDate = (Datetime)result.get('jobDate');
        }
        
        String query = 'Select Id, CaseId, KnowledgeArticleId From CaseArticle ';
        if(lastJobRunDate != null)
           query += 'Where LastModifiedDate > :lastJobRunDate ';
        if(system.Test.isRunningTest())
            query += ' ORDER BY CREATEDDATE DESC LIMIT 200';
            
        return Database.getQueryLocator(query);
    }

    //call the S2S sync class to create the sync records  
    global void execute(Database.BatchableContext BC, List<CaseArticle> scope){        
        ExternalSharingHelper.UpsertCaseArticleShadows(scope);
    }
    
    // execution with this finish method
    global void finish(Database.BatchableContext BC){
        
    }
}