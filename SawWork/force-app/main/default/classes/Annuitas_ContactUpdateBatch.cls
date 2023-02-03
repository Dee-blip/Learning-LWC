/*
 * Should the validation be overriden?
 * Errors logging?
 */
global class Annuitas_ContactUpdateBatch implements Database.Batchable<sObject> {
    
    global Set<id> allFailedId=new Set<id>();
    global List<id> allSuccessId=new List<id>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Integer jobSize = GSMSettings.getInt('AnnuitasContactUpdateJobLimit');
        //PDG 2.0
        String bppStageValue = GSMSettings.getValue('BPPStageFieldsForLead');
        String bppStatusValue = GSMSettings.getValue('BPPStatusFieldsForLead');
        String query = 'SELECT Id,';
        query+= bppStageValue + ',' + bppStatusValue + ',ContactJobRunFailureCount__c FROM Contact';
        query+=' where ' + bppStageValue +'=null or ' + bppStatusValue+'=null';
        query+=' Order by ContactJobRunFailureCount__c asc,CreatedDate desc limit '+jobSize;
        System.debug('Query'+query);
        System.debug('Query'+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
       
        // process each batch of records
        allFailedId=new Set<id>();
        allSuccessId=new List<id>();
        //PDG 2.0
        for(Contact conRec : contactList)
        {        
            if(conRec.Lead_Qualification_Stage__c==null){
                conRec.Lead_Qualification_Stage__c='Prospect';
            }
            if(conRec.Lead_Qualification_Status__c==null){
                conRec.Lead_Qualification_Status__c='New';
            }
            conRec.Validation_Override__c=true;
           //Repeat for others
        }
        try {
            List<Error_Log__c> errorLogs = new List<Error_Log__c>();
            Set<Id> failedLeadId = new Set<Id>();
            Error_Log__c el;
            database.SaveResult[] updateResults=database.update(contactList,false);
            Integer successCount=0;
            for (Database.SaveResult sr : updateResults) {

                if (sr.isSuccess()) {
                    allSuccessId.add(sr.getId());
                    successCount+=1;
                    
                }
                else {
                   Database.Error errors =  sr.getErrors().get(0);
                   String errorId;
                   if(errors.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                        errorId=errors.getMessage().substringAfter('with id ');
                        errorId=errorId.subStringBefore(';');
                        if(errorId.length()==18){
                            failedLeadId.add(errorId);
                        }
                        el = new Error_Log__c(Name='Annuitas_ContactUpdateBatch_Lead_Error', Class__c='Annuitas_ContactUpdateBatch', Error_Message__c=errors.getMessage(),RecordId__c=errorId); 
                        errorLogs.add(el);
                        break;
                    }
                }
            }

            if(successCount>0){
                el = new Error_Log__c(Name='Annuitas_ContactUpdateBatch_SuccessCount', Class__c='Annuitas_ContactUpdateBatch', Error_Message__c='Updated Successfully',RecordId__c=String.valueOf(successCount));
                errorLogs.add(el);
            }
            if(Test.isRunningTest()){
                for(Lead l:[Select Id,Associated_Contact__c from Lead where Associated_Contact__c!=null]){
                failedLeadId.add(l.Id);
                }
            }
            for(Lead l :[Select id,Associated_Contact__c from Lead where Id IN :failedLeadId]){
                el = new Error_Log__c(Name='Annuitas_CUB_ContactFailed', Class__c='Annuitas_ContactUpdateBatch',RecordId__c=l.Associated_Contact__c); 
                errorLogs.add(el);
                allFailedId.add(l.Associated_Contact__c);
            }
            insert errorLogs;
            List<Contact> updateFailedRecords = new List<Contact>();
            for(Contact conRec : [Select Id,ContactJobRunFailureCount__c From Contact where id In :allFailedId]){
                if(conRec.ContactJobRunFailureCount__c>0){
                    conRec.ContactJobRunFailureCount__c+=1;
                }else{
                    conRec.ContactJobRunFailureCount__c=1;
                }
                conRec.Validation_Override__c=true;
                updateFailedRecords.add(conRec);
            }
            update updateFailedRecords;
        
        } catch(Exception e) {
            Error_Log__c el = new Error_Log__c(Name='Annuitas_ContactUpdateBatch', Class__c='Annuitas_ContactUpdateBatch', Error_Message__c=e.getMessage());
            insert el;
            System.debug(e);
        }
        
    }   
    
    global void finish(Database.BatchableContext BC) {
        String successMsg='Batch Run Completed';
        Error_Log__c el = new Error_Log__c(Name='Annuitas_ContactUpdateBatch_Finish', Class__c='Annuitas_ContactUpdateBatch', Error_Message__c=successMsg);
        insert el;
    }
}