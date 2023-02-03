/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Class used for deleting the shadow object for the deleted CaseArticle 
    Created Date : 10/31/2013
    ======================================================================== */
global with sharing class BatchableCaseArticleDelete implements Database.Batchable<sObject> {
    //start method that creates the query And returns the query locator
    global Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'Select Id, CaseArticleID__c From Case_Article__c Order By CreatedDate DESC';
        if(system.Test.isRunningTest())
            query += ' LIMIT 200';
        return Database.getQueryLocator(query);
    }
    
    //call the delete case article method
    global void execute(Database.BatchableContext BC, List<Case_Article__c> scope){
        Set<Id> ids = new Set<Id>();
        Set<Id> shadowIds = new Set<Id>();
        for(Case_Article__c cas : scope){
            if(cas.CaseArticleID__c != null)
                ids.add(cas.CaseArticleID__c);
            shadowIds.add(cas.id);
        }
        
        Set<String> existingCaseArticles = new Set<String>();
        for(CaseArticle ca : [Select Id From CaseArticle Where Id IN: ids]){
            existingCaseArticles.add(ca.id);
        }
        
        delete [Select Id From Case_Article__c 
            Where Id IN: shadowIds
            And CaseArticleID__c Not In: existingCaseArticles];
    }
    
    // execution with this finish method
    global void finish(Database.BatchableContext BC){
        
    }
}