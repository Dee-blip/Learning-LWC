/*******************************************************************************************************
 Name         :   ExternalDependencyTriggerHandler
 Author       :   Pinkesh Rathore
 Created Date :   Jan 30,2017
 CR           :   3612751
 Description  :   Handler class for  the ExternalDependencyTrigger


*******************************************************************************************************/
public class ExternalDependencyTriggerHandler {
    public static void ChangeCaseExternalDependencies(Boolean isUpdate, List<External_Dependency__c> lNewED, Map<Id, External_Dependency__c> oldMap){
        Set<ID> allCaseIds = new Set<ID>();
        List<Engagement_Request__c> lEndReq = new List<Engagement_Request__c>();
        string allExtDepNames;
        for(External_Dependency__c ED : lNewED){
            if(ED.ID__c != oldMap.get(ED.Id).ID__c && ED.Case__c!=NULL){
                 allCaseIds.add(ED.Case__c);
           }
       }
        for(Case eachCaseRec : [Select Id, (select Id__c from External_Dependencies__r), (select Id, External_Dependencies__c, Request_Status__c  from Engagement_Requests__r) from Case where Id in :allCaseIds]){
            allExtDepNames = '';
            if(eachCaseRec.External_Dependencies__r !=NULL)
                for(External_Dependency__c eachExtDep : eachCaseRec.External_Dependencies__r){
                    if(eachExtDep.ID__c != null)
                        allExtDepNames += eachExtDep.ID__c + ';';
                }
            
            if(eachCaseRec.Engagement_Requests__r != NUll){
                for(Engagement_Request__c eachER : eachCaseRec.Engagement_Requests__r){
                    eachER.External_Dependencies__c = allExtDepNames;
                    lEndReq.add(eachER);
                    
                }
            }    
        }
      update lEndReq;
    }
}