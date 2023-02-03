global class CS_BatchableNVUpdate implements Database.Batchable<sObject>{
/*
Author: Sharath
Version: 1.0
Created date: 01/09/2010
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Modified: Sharath 03/20/2011
CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
*/

    global final String Query;
    Map<String,String> recIdAkamContactMap= new Map<String,String>();
    Map<String,String> akamIdContactIdMap = new Map<String,String>();
    Map<String,String> nameValueFieldQuestionMap = new Map<String,String>();
    Map<String,String> recordIdRecordStatusMap = new Map<String,String>();
    /* 
Author: Sharath
Version: 1.0
Created date: 01/09/2010
    Description: Contructor with no parameters for the class to be inherited. 
    */
    global CS_BatchableNVUpdate(){}
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/09/2010
    Description: Parameterised contructor for initialising the query
    */
    global CS_BatchableNVUpdate(String Query, Map<String,String> mapRecordIdAkamContact,Map<String,String> akamContactIdMap,Map<String,String> nvFieldQuestionMap,Map<String,String> recIdRecStatusMap)
    {
        this.Query = Query;
        akamIdContactIdMap = akamContactIdMap;
        recIdAkamContactMap = mapRecordIdAkamContact;
        nameValueFieldQuestionMap = nvFieldQuestionMap;
        recordIdRecordStatusMap = recIdRecStatusMap;
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/09/2010
    Description: this method returns a Database.QueryLocator which is used as an input to the execute method. 
    */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/09/2010
    Description: this method executes the query returned by start method. This method update the name-value records with corresponding ContactIds and QuestionIds
    Modified: Sharath 03/20/2011
    CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
        - concatinating surveyResponse Sync Ids to Maps, so that we can map the correct NV records with corrsponding Contacts
        - moving the NV row to Failed/Processed using a map "recordIdRecordStatusMap". removing the dependency on @future job(used in v1.0).
    */
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        List<CS_SurveyResponseNameValue__c> updaterecords = new List<CS_SurveyResponseNameValue__c>();
        List<CS_SurveyResponseNameValue__c> nvRows = new List<CS_SurveyResponseNameValue__c>();
        String questionMapping;
        // list of nvRows returned by start method
        nvRows = scope;
        
        for(CS_SurveyResponseNameValue__c nvRec :nvRows){
            //get the corresponding contact's Id from the Maps
            nvRec.CS_ContactId__c =akamIdContactIdMap.get(recIdAkamContactMap.get(nvRec.CS_RecordId__c + '#' + nvRec.CS_SurveyResponse__c));
            nvRec.CS_SyncStatus__c = recordIdRecordStatusMap.get(nvRec.CS_RecordId__c + '#' + nvRec.CS_SurveyResponse__c);
            nvRec.CS_SyncDate__c = datetime.now();
            questionMapping = nameValueFieldQuestionMap.get(nvRec.CS_Name__c);
            if(questionMapping != null){
                nvRec.CS_MapsToQuestion__c = questionMapping ;
                }
            updaterecords.add(nvRec);
            if(updaterecords.size()>990){
                database.update(updaterecords,false);
                updaterecords.clear();
                }
        }
        database.update(updaterecords,false);
    }
    
    /*
Author: Sharath
Version: 1.0
Created date: 01/09/2010
    Description: this method can be used to send mails regarging the batch job. 
    */
    global void finish(Database.BatchableContext BC)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] {'janantha@akamai.com'});
        mail.setSenderDisplayName('Batch Processing');
        mail.setSubject('Batch Process Completed');
        mail.setPlainTextBody('Batch Process has completed');
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}