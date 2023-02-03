/*-------------------------------------------------------------------------------------------------------------
 * Class Name           : SC_UpdateArticle_Batch
 * Developer Name       : Vamsee Surya
 * Date                 : 23th April,2018
 * JIRA                 : ESESP-1137
 * Description          : Batch class to update the articles with AKAM fields. 
 -------------------------------------------------------------------------------------------------------------*/ 
Global class SC_UpdateArticle_Batch implements Database.Batchable<sObject>, Database.stateful{
    public string result;
    Public SC_UpdateArticle_Batch(){
        result ='';        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String articleQuery;
        if(System.Test.isRunningTest()){
            articleQuery = 'SELECT Id, KnowledgearticleId, LastModifiedBy.alias, LastModifiedDate, LastModifiedbyId FROM ' +
                           'Knowledge__kav LIMIT 50';
        }
        else{
            articleQuery = 'SELECT Id, KnowledgearticleId, Visibility__c FROM Knowledge__kav WHERE ' +
                           'Recordtype.Developername = \'Community_Blog\'' +
                		   'AND Visibility__c = \'Internal\'';
        }
       return Database.getQueryLocator(articleQuery);
	}
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<Id, Knowledge__kav> articleMap = new Map<Id, Knowledge__kav>();
       	result = 'How To Article Type\n\n';
        Set<Id> failedKAId = new Set<Id>();
        for(Knowledge__kav eachArticle : (List<Knowledge__kav>) scope){
            try{
                KbManagement.PublishingService.editOnlineArticle(eachArticle.knowledgearticleId, false);
                articleMap.put(eachArticle.KnowledgearticleId, eachArticle);
            }
            Catch(Exception ex){
                failedKAId.add(eachArticle.KnowledgearticleId);
            }
            
        }
        result = result + '---FailedArticles--- '+ failedKAId + '\n';
        result = result + '---Failed Articles Count--- '+ failedKAId.size() + '\n';

        List<Knowledge__kav> howToDraftList = new List<Knowledge__kav>();
        
        for(Knowledge__kav eachArticle : [SELECT Id, KnowledgearticleId, Visibility__c FROM Knowledge__kav WHERE Publishstatus = 'Draft' AND Visibility__c = 'Internal']){
    
            if(failedKAId.contains(eachArticle.KnowledgearticleId)){
                result = result + '---DeletedArticles--- '+ eachArticle.KnowledgearticleId + '\n';
                KbManagement.PublishingService.deleteDraftArticle(eachArticle.KnowledgearticleId);
            }
                                 
            if(articleMap.get(eachArticle.KnowledgearticleId) != null){
                eachArticle.Visibility__c = 'External';
                howToDraftList.add(eachArticle);
            }

        }
        if(howToDraftList.size() > 0){
            Update howToDraftList;
            result = result + '---Updated Article Count--- '+ howToDraftList.size() + '\n';
            for(Knowledge__kav eachArticle : howToDraftList){
                KbManagement.PublishingService.publishArticle(eachArticle.knowledgearticleId, false);
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        String[] toAdd = new String[] {};
        toAdd.add('prathore@akamai.com');
        toAdd.add('vs@akamai.com');
            
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = 'Update Articles Result';
        mail.plainTextBody = result;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        
    }
    
}