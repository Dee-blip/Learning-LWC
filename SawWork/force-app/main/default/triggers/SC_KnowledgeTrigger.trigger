/*=======================================================================================+
    Trigger name        :   SC_KnowledgeTrigger
    Author              :   Vamsee S
    Created             :   05 Feb 2017
    Purpose             :   ESESP-1779 : Akatec Lightning Migration
    Test Class          :   SC_KCS_TestClass
-----------------------------------------------------------------------------------------*/
trigger SC_KnowledgeTrigger on Knowledge__kav (before insert, after insert) {
    
    if(trigger.isbefore && trigger.isinsert){
        
        Set<id> sourceCaseIdSet = new Set<id>();
        //Get all the cass details
        for(Knowledge__kav eachKAV : trigger.new){
            if(eachKAV.Source_Case__c != null){
                sourceCaseIdSet.add(eachKAV.Source_Case__c);
            }
        }
        Map<Id, Case> sourceCaseMap = new Map<Id, Case>([SELECT Id, Issue_Summary__c, Solution_Summary__c, Root_Cause__c, Service_Incident__c FROM Case WHERE Id in :sourceCaseIdSet]);
        
        //Get Record Types in the Knowledge
        Id psRecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Troubleshooting_Procedure').getRecordTypeId();
        Id howToRecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('How_To').getRecordTypeId();
        Id qaRecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Question_Answer').getRecordTypeId();
        Id rcaRecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('RCA_Document').getRecordTypeId();
        
        //To remove special Characters in the end.
        Pattern pattern = Pattern.compile('^(-)*(.+?)(-)+$');
        
        //When article is created from Publisher Action
        for(Knowledge__kav eachKAV : trigger.new){
            if(eachKAV.Created_from_Publisher_Action__c == True && eachKAV.KnowledgeArticleId == null){
                //Only Alphanumer characters are allowed in URL Name
                String urlName = eachKAV.Title.replaceAll('[^a-zA-z0-9]','-');
                urlName = urlName.replaceAll('(\\[|\\]|\\^)','-');
                //Remove special characters present at the start/end ('-' is not allowed)
                if(urlName.endsWith('-') || urlName.startsWith('-')){
                    Matcher pm = pattern.matcher(urlName);
                    if(pm.matches())
                        urlName = pm.group(2);
                }
                eachKAV.UrlName = urlName;
                eachKAV.Create_Case_Article__c = True;
                
                //Problem & Solution Article
                if(eachKAV.RecordTypeId == psRecordTypeId){
                    eachKAV.Symptoms__c = sourceCaseMap.get(eachKAV.Source_Case__c).Issue_Summary__c;
                    eachKAV.Explanation__c = sourceCaseMap.get(eachKAV.Source_Case__c).Root_Cause__c;
                    eachKAV.Solution__c = sourceCaseMap.get(eachKAV.Source_Case__c).Solution_Summary__c;
                }
                //How To Article
                else if(eachKAV.RecordTypeId == howToRecordTypeId){
                    eachKAV.Description__c = sourceCaseMap.get(eachKAV.Source_Case__c).Issue_Summary__c;
                    eachKAV.How_To_Procedure__c = sourceCaseMap.get(eachKAV.Source_Case__c).Solution_Summary__c;
                }
                //Question & Answer
                else if(eachKAV.RecordTypeId == qaRecordTypeId){
                    eachKAV.Question_Answer_Question__c = sourceCaseMap.get(eachKAV.Source_Case__c).Issue_Summary__c;
                    eachKAV.Question_Answer_Answer__c = sourceCaseMap.get(eachKAV.Source_Case__c).Solution_Summary__c;
                } 
                
            }
            // This is to avoid Case Article creation on Every Knowledge article version creation
            else if(eachKAV.KnowledgeArticleId != null)
                eachKAV.Create_Case_Article__c = false;

            //Added by Bhavesh,ESESP-3590, RCA request changes
            if( eachKAV.RecordTypeId == rcaRecordTypeId && trigger.isInsert && eachKAV.Source_Case__c != NULL && sourceCaseMap.containsKey(eachKAV.Source_Case__c) ){
                eachKAV.Service_Incident_Number__c = sourceCaseMap.get(eachKAV.Source_Case__c).Service_Incident__c;
            }
        }
    }
    
    //When article is created from record creation page
    if(trigger.isafter && trigger.isinsert){
        CaseArticle tempCaseArticle;
        List<CaseArticle> caseArticleList = new List<CaseArticle>();
        for(Knowledge__kav eachKAV : trigger.new){
            if(eachKAV.Source_Case__c != null && eachKAV.Create_Case_Article__c == True){
                tempCaseArticle = new CaseArticle();
                tempCaseArticle.CaseId = eachKAV.Source_Case__c;
                tempCaseArticle.KnowledgeArticleId = eachKAV.KnowledgeArticleId;
                caseArticleList.add(tempCaseArticle);
            }
        }
        if(caseArticleList.size() > 0){
            Insert caseArticleList;
        }
    }
        
 }