/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Class used for updating the CaseArticle from the shadow objects
        This is run from BatchableKnowledgeArticleShadows so the new articles will be created before any case articles
    Created Date : 10/31/2013
    ======================================================================== */
global with sharing class BatchableCaseArticleShadow implements Database.Batchable<sObject> {
    //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext BC){
        DateTime lastJobRunDate;
        AggregateResult result = [Select max(CompletedDate) jobDate From AsyncApexJob 
           Where ApexClass.Name = 'BatchableCaseArticleShadow' And Status = 'Completed'];
        if(result != null && result.get('jobDate') != null){
            lastJobRunDate = (Datetime)result.get('jobDate');
        }
        String query;
        query = 'Select Id, Case__c, CaseArticleID__c, Case_RO__c, Case_RW__c, KnowledgeArticleID__c, KnowledgeArticle_URLName__c ' +
            'From Case_Article__c Where CaseArticleID__c = null AND ConnectionReceivedId != null ';
        
        if(Test.isRunningTest())
        {
            query = 'Select Id, Case__c, CaseArticleID__c, Case_RO__c, Case_RW__c, KnowledgeArticleID__c, KnowledgeArticle_URLName__c ' +
            'From Case_Article__c Where CaseArticleID__c = null ';
        }
        
        if(lastJobRunDate != null)
           query += 'AND LastModifiedDate >: lastJobRunDate';
        if(System.Test.isRunningTest())
            query += ' ORDER BY CREATEDDATE DESC  LIMIT 200';
            
        return Database.getQueryLocator(query);
    }
    
    //call the S2S sync class to create the sync records  
    global void execute(Database.BatchableContext BC, List<Case_Article__c> scope){        
        ExternalSharingHelper.CreateCaseArticle(scope);
    }
    
    // execution with this finish method
    global void finish(Database.BatchableContext BC){
        
    }
}