/*
Author: Sharath
Created: 05/01/2011
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Description: This class is used to update the Contacts with surveyResponse scores for corresponnding Contacts. also, updates name-value object with ContactId, corrsponding QuestionId(if any) and updates the sync status after contact has been updated
Modified: Sharath 03/20/2011 
CR 1021287 CSAT: Use IsDeleted in all of the SQLs while accessing Survey Custom Objects
CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
Modified: Sharath 06/03/2011
CR 1140535 CSAT: Contacts Update Apex Job to look at Response Date
    - Adding logic so that no old responses(previous surveys) get processed
*/

public class CS_UpdateContacts{

/*
This method is called by the schedulable class.
Description: we search for an 'active' Survey and its child survey responses. If a valid surveyresponse is found in 'pending' state, call processNameValueAndContacts() to process the contacts
Modified : 3/20/2011 
CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
- Process contacts from multiple surveyResponse files. Changed the logic from "looking at a single surveyResponse file" to "looking for contacts in a list of surveyResponse files"
- Change status of NV Records to "Processed"/"Failed" after surveyResponse moves to "Contacts Processed" status. Emphasis is on processing contacts faster.
*/

CSAT_CustomSettings__c instanceValue2 = CSAT_CustomSettings__c.getInstance('NumberOfColumns');
Integer noOfColumnsInRecord = Integer.valueOf(instanceValue2.CSAT_Value__c);

public void execute(){
// assumption - only 1 survey can be active at any given time
try{
    CS_Survey__c activeSurvey= [ select Id, Name from CS_Survey__c where CS_Status__c = 'Active' AND (CS_IsDeleted__c = false)][0];
    if(activeSurvey!=null){
        String surveyId = activeSurvey.Id;
        List<String> srIdList = new List<String>();
        // Looks for surveyResponse files in "Pending". process the contacts. 
        List<CS_SurveyResponse__c> surveyResponses = [ select Id,CS_NoInPending__c,CS_SyncStatus__c,CS_SyncStatusMessage__c from CS_SurveyResponse__c where CS_SyncStatus__c = 'Pending' AND (CS_Survey__c = :surveyId) AND (CS_IsDeleted__c = false)];
        if(!(surveyResponses.isEmpty())){
            for(CS_SurveyResponse__c surveyResponse :surveyResponses){
                srIdList.add(surveyResponse.Id);
                }
            //System.assertEquals(srIdList,null);
            processNameValueAndContacts(srIdList,surveyId);
            }
        srIdList.clear();
        //call new method "processNameValue" to move status of NV records to "Processed"/"Failed" , to populate Contact IDs and Question Ids. Looks for surveyResponse files in "Contacts Processed" 
       /* List<CS_SurveyResponse__c> processedSurveyResponses = [ select Id,CS_NoInPending__c,CS_SyncStatus__c,CS_SyncStatusMessage__c from CS_SurveyResponse__c where CS_SyncStatus__c = 'Contacts Processed' AND (CS_Survey__c = :surveyId) AND (CS_IsDeleted__c = false) ];
        if(!(processedSurveyResponses.isEmpty())){
            for(CS_SurveyResponse__c processedSurveyResponse :processedSurveyResponses){
                srIdList.add(processedSurveyResponse.Id);
                }
            processNameValue(srIdList,surveyId);
            }*/
        }
    }
catch(Exception e){
//system.assertEquals(e.getMessage(),'abc');
    CS_SurveyException__c excpRecord = new CS_SurveyException__c();
    excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
    excpRecord.CS_ExceptionMessage__c = e.getMessage() + ' (No Survey/Survey Response record  found )';
    database.insert(excpRecord);
    }
}

/* 
Modified: 3/20/2011 By :Sharath
Description:1. Look for invalid akam contact Ids. Populate the Survey Exceptions object with corresponding NV record details.
            2. Populate few maps so that it can be passed to the batch class as parameters
            3. Update contacts using the batch class CS_BatchableContactUpdate
            4. CR CR 1021287 CSAT: Use IsDeleted in all of the SQLs while accessing Survey Custom Objects
            5. CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
*/

public void processNameValueAndContacts(List<String> surveyResponseIdList,String surveyId){
    
    //Retrieve custom setting values so that we can calcualate batch size of the batch jobs
    CSAT_CustomSettings__c instanceValue1 = CSAT_CustomSettings__c.getInstance('NumberOfRecords');
    Integer noOfRecordsToProcess =Integer.valueOf(instanceValue1.CSAT_Value__c);
    
    CSAT_CustomSettings__c CSRecsPerBatch = CSAT_CustomSettings__c.getInstance('RecordsPerBatch');
    Integer RecordsPerBatch = Integer.valueOf(CSRecsPerBatch.CSAT_Value__c);
    
    // noOfContactsInBatch will be the batch size for the batch jobs
    Integer noOfContactsInBatch = (10000/noOfColumnsInRecord) ;
    
    List<String> akamContacts = new List<String>();
    Set<String> recordIdentifiers = new Set<String>();
    Map<String,String> recordIdAkamContactMap= new Map<String,String>();
    Map<String,String> akamContactIdMap= new Map<String,String>();
    String validId;
    List<String> invalidIds = new List<String>();
    List<CS_SurveyException__c> exceptionRows = new List<CS_SurveyException__c>();
    List<CS_SurveyResponseNameValue__c> updateInvalidNVRecs = new List<CS_SurveyResponseNameValue__c>();
    List<CS_SurveyResponseNameValue__c> invalidResponseList = new List<CS_SurveyResponseNameValue__c>();
    /*start of changes by janantha to handle seed data creation*/
    Map<String, String> conIdSRId = new Map<String, String>();
    /*End of changes by janantha to handle seed data creation*/
    try{
    /*start of changes - 06/03/2011
    Modified by : Sharath
    CR 1140535  - Adding logic so that no old responses(previous surveys) get processed
    */
    //Date SurveyOpenedDate = [SELECT Id,Name,CS_SurveyOpenedOn__c from CS_Survey__c where CS_Status__c = 'Active' order by CreatedDate desc limit 1 ][0].CS_SurveyOpenedOn__c;
    //Retrieve the dates for all the responses that needs to be processed
    //List<CS_SURVEYRESPONSENAMEVALUE__c> responsesList=[SELECT Id,CS_RECORDID__C,CS_VALUE__C,CS_SurveyResponse__c FROM CS_SURVEYRESPONSENAMEVALUE__c WHERE CS_SYNCSTATUS__C = 'Pending' AND CS_SurveyResponse__c in :surveyResponseIdList AND CS_CUSTOMORDER__C=7 AND (CS_RECORDSTATUS__C != 'Failed' OR CS_RECORDSTATUS__C != 'Processed') AND (CS_IsDeleted__c = false) ORDER BY CS_SURVEYRESPONSE__C,CREATEDDATE,CS_RECORDID__C limit :noOfRecordsToProcess]; 
    /*for(CS_SURVEYRESPONSENAMEVALUE__c response : responsesList){
        String responseDate = response.CS_Value__c;
        
        Date formattedResponseDate =  Date.parse(responseDate);
        if(formattedResponseDate < surveyOpenedDate){
            
            response.CS_RecordStatus__c = 'Failed';
            response.CS_SyncStatus__c = 'Failed';
            response.CS_SyncStatusMessage__c = ' Old Response';
            invalidResponseList.add(response);
            CS_SurveyException__c excpRecord = new CS_SurveyException__c();
            excpRecord.CS_ExceptionInObject__c = 'Survey Response Name-Value';
            excpRecord.CS_SurveyResponse__c = response.CS_SurveyResponse__c;
            excpRecord.CS_Survey__c = surveyId;
            excpRecord.CS_ExceptionMessage__c = 'Old data - Response date :' + responseDate +' is older than the Survey Opened date: ' + surveyOpenedDate;
            exceptionRows.add(excpRecord);
            }
        }*/
       /* if(invalidResponseList.size()>0){
            database.update(invalidResponseList,false);
        }
        if(exceptionRows.size()>0){
            database.insert(exceptionRows);
            exceptionRows.clear();
        } */
    /*End of changes - 06/03/2011 */    
    
    //Retrieve unique records -limits based on Custom settings , use CS_ISDeleted__c in SOQL
    /*Changes by janantha for making the SOQL more efficient. Commenting out the below line and using the soql in the for loop.*/
    //List<CS_SURVEYRESPONSENAMEVALUE__c> uniqueRecords=[SELECT CS_RECORDID__C,CS_VALUE__C,CS_SurveyResponse__c FROM CS_SURVEYRESPONSENAMEVALUE__c WHERE CS_SYNCSTATUS__C = 'Pending' AND CS_SurveyResponse__c in :surveyResponseIdList AND CS_CUSTOMORDER__C=0 AND (CS_RECORDSTATUS__C != 'Failed' OR CS_RECORDSTATUS__C != 'Processed') AND (CS_IsDeleted__c = false) ORDER BY CS_SURVEYRESPONSE__C,CREATEDDATE,CS_RECORDID__C limit :noOfRecordsToProcess]; 
    /*start of changes by janantha to handle seed data creation*/
    /*change by janantha. Commenting out the below line and using the soql in the for loop condition for efficiency.*/
    //for(CS_SURVEYRESPONSENAMEVALUE__c row : uniqueRecords){
    for(CS_SURVEYRESPONSENAMEVALUE__c SRNV : [SELECT CS_RECORDID__C,CS_VALUE__C,CS_SurveyResponse__c FROM CS_SURVEYRESPONSENAMEVALUE__c WHERE CS_SYNCSTATUS__C = 'Pending' AND CS_SurveyResponse__c in :surveyResponseIdList AND CS_CUSTOMORDER__C=0 AND (CS_RECORDSTATUS__C != 'Failed' OR CS_RECORDSTATUS__C != 'Processed') AND (CS_IsDeleted__c = false) ORDER BY CS_SURVEYRESPONSE__C,CREATEDDATE,CS_RECORDID__C])
    {
        conIdSRId.put(SRNV.CS_VALUE__C,SRNV.CS_SurveyResponse__c);
    }
    
    /*end of changes by janantha to handle seed data creation*/
    //Create a list of akam_contact_Ids, list of RowIdentifiers and a map b/w RowIdentifiers & akam_contact_Ids
    /*change by janantha. Commenting out the below line and using the soql in the for loop condition for efficiency.*/
    for(CS_SURVEYRESPONSENAMEVALUE__c row : [SELECT CS_RECORDID__C,CS_VALUE__C,CS_SurveyResponse__c FROM CS_SURVEYRESPONSENAMEVALUE__c WHERE CS_SYNCSTATUS__C = 'Pending' AND CS_SurveyResponse__c in :surveyResponseIdList AND CS_CUSTOMORDER__C=0 AND (CS_RECORDSTATUS__C != 'Failed' OR CS_RECORDSTATUS__C != 'Processed') AND (CS_IsDeleted__c = false) ORDER BY CS_SURVEYRESPONSE__C,CREATEDDATE,CS_RECORDID__C])
    {
        akamContacts.add(row.CS_VALUE__C);
        //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
        recordIdentifiers.add(row.CS_RECORDID__C + '#' + row.CS_SurveyResponse__c);
        //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
        recordIdAkamContactMap.put(row.CS_RECORDID__C + '#' + row.CS_SurveyResponse__c,row.CS_VALUE__C);
    }
    
    // create a string form of surveyResponseList
    String surveyResponseString = '';
    for( String surveyRespId : surveyResponseIdList){
        surveyResponseString = surveyResponseString + '\''+ surveyRespId + '\',' ;
    }
    // remove the last ','
    surveyResponseString = surveyResponseString.substring(0,surveyResponseString.length()-1 );
    
    // Retieve all the Contact_Ids for  corresponding akam_contact_Ids
    /*Change by janantha commenting out the below line and using the soql in the for loop for efficiency.*/
    //List<Contact> contactIds = [ SELECT ID,AKAM_CONTACT_ID__C FROM CONTACT WHERE AKAM_CONTACT_ID__C IN :akamContacts ];
    
    // create a map between akam_contact_Ids and SF Contact_Ids
    //change by janantha commenting out the below line and using soql instead of contactIds.
    //for( Contact c:contactIds){
    for(Contact c:[SELECT ID,AKAM_CONTACT_ID__C FROM CONTACT WHERE AKAM_CONTACT_ID__C IN :akamContacts])
    {
        akamContactIdMap.put(c.AKAM_CONTACT_ID__C,c.ID);
    }
    
    
    /*Start of Changes by janantha for handling the condition of no seed data present*/
        List<String> sfContacts = new List<String>();
        sfContacts = akamContactIdMap.values();               
        CS_SurveyAccount__c surveyAccount = new CS_SurveyAccount__c();
        CS_SurveyContacts__c surveyContact = new CS_SurveyContacts__c();
        List<CS_SurveyAccount__c> surveyAccountList = new List<CS_SurveyAccount__c>();
        Set<CS_SurveyAccount__c> surveyAccountSetTemp = new Set<CS_SurveyAccount__c>();
        List<CS_SurveyContacts__c> surveyContactList = new List<CS_SurveyContacts__c>();
        Set<CS_SurveyContacts__c> surveyContactSetTemp = new Set<CS_SurveyContacts__c>();
       // Map<String,String> contactIdAccountId = new Map<String,String>();
        List<Id> surveyAccountIds = new List<Id>();
        List<Id> surveyContactIds = new List<Id>();
        Map<String,String> surveyAccountIdsAccountIds = new Map<String,String>();
        List<String> accountIdsSAToBeUpdated = new List<String>();
        List<String> contactIdsSCToBeUpdated = new List<String>();
        Map<String,String> surveyContactIdsContactIds = new Map<String,String>();
        List<Account> accountSAToBeUpdated = new List<Account>();
        List<Contact> contactSCToBeUpdated = new List<Contact>();
        Map<String,String> contactIdSCIdMapping = new Map<String,String>();
        Map<String,String> accountIdSAIdMapping = new Map<String,String>();
        List<String> accountIdsMissingSAMapping = new List<String>();
        List<CS_SurveyException__c> exceptionList = new List<CS_SurveyException__c>();
        
        for(CS_SurveyContacts__c surveyCon:[select Id, CS_Contact__c from CS_SurveyContacts__c where CS_Survey__c = :surveyId])
        {
            contactIdSCIdMapping.put(surveyCon.CS_Contact__c,surveyCon.Id);
        }
        
        for(CS_SurveyAccount__c surveyAcc:[select Id, CS_Account__c from CS_SurveyAccount__c where CS_Survey__c = :surveyId])
        {
            accountIdSAIdMapping.put(surveyAcc.CS_Account__c, surveyAcc.Id);
        }
        
        for(Contact con1:[select Id, CS_CurrentlySurveyed__c, Validation_Override__c, CS_LowSatScore__c, AKAM_Contact_Id__c, Account.CS_SurveyAccount__c, Account.Id, CS_AssociatedSurveyContact__c from Contact where Id in :sfContacts])
        {
            if(con1.CS_AssociatedSurveyContact__c == null)
            {
                //System.assertEquals(conIdSRId.get(con1.AKAM_Contact_Id__c),'01pA0000001ry3d');
                //If both Survey Account and Survey Contact are not present create Survey Accounts                
                if(con1.Account.CS_SurveyAccount__c == null && accountIdSAIdMapping.get(con1.Account.Id) == null)
                {                                                                                       
                    surveyAccount = new CS_SurveyAccount__c();
                    surveyAccount.CS_Account__c = con1.Account.Id;
                    surveyAccount.CS_Survey__c = surveyId;
                    surveyAccountList.add(surveyAccount);                   
                }  
                else if(accountIdSAIdMapping.get(con1.Account.Id) != null)
                {
                    accountIdsMissingSAMapping.add(con1.Account.Id);
                    if(contactIdSCIdMapping.get(con1.Id) != null)
                    {
                        con1.CS_AssociatedSurveyContact__c = contactIdSCIdMapping.get(con1.Id);
                        con1.Validation_Override__c = true;
                        con1.CS_LowSatScore__c = false;
                        con1.CS_CurrentlySurveyed__c = true;
                        contactSCToBeUpdated.add(con1);
                    }     
                    else
                    {  
                        surveyContact = new CS_SurveyContacts__c();
                        surveyContact.CS_Account__c = con1.Account.Id;
                        surveyContact.CS_Contact__c = con1.Id;
                        surveyContact.CS_Survey__c = surveyId;
                        //get the survey account from the map since the survey account is already present.
                        surveyContact.CS_SurveyAccount__c = accountIdSAIdMapping.get(con1.Account.Id);
                        surveyContact.CS_SurveyResponseSyncId__c = conIdSRId.get(con1.AKAM_Contact_Id__c);
                        surveyContact.CS_Type__c = 'Survey Response';
                        surveyContact.CS_Classification__c = 'None';
                        //System.assertEquals(surveyContact, null);
                        surveyContactList.add(surveyContact);
                    }
                }            
                else
                {  
                    //System.assertEquals('abc','def');
                    //if survey contact is present but the mapping b/w survey contact and contact is not done
                    if(contactIdSCIdMapping.get(con1.Id) != null)
                    {
                        con1.CS_AssociatedSurveyContact__c = contactIdSCIdMapping.get(con1.Id);
                        con1.Validation_Override__c = true;
                        con1.CS_LowSatScore__c = false;
                        con1.CS_CurrentlySurveyed__c = true;
                        contactSCToBeUpdated.add(con1);
                    }     
                    else
                    {             
                        surveyContact = new CS_SurveyContacts__c();
                        surveyContact.CS_Account__c = con1.Account.Id;
                        surveyContact.CS_Contact__c = con1.Id;
                        surveyContact.CS_Survey__c = surveyId;
                        surveyContact.CS_SurveyAccount__c = con1.Account.CS_SurveyAccount__c;
                        surveyContact.CS_SurveyResponseSyncId__c = conIdSRId.get(con1.AKAM_Contact_Id__c);
                        surveyContact.CS_Type__c = 'Survey Response';
                        surveyContact.CS_Classification__c = 'None';
                        //System.assertEquals(surveyContact, null);
                        surveyContactList.add(surveyContact);
                    }
                }
            }
        }
        
        for(Account acc:[select Id, Validation_Override__c, CS_SurveyAccount__c from Account where Id in :accountIdsMissingSAMapping])
        {
            acc.CS_SurveyAccount__c = accountIdSAIdMapping.get(acc.Id);
            acc.Validation_Override__c = true;
            accountSAToBeUpdated.add(acc);
        }
        
        update accountSAToBeUpdated;
        accountSAToBeUpdated = new List<Account>();
        
        update contactSCToBeUpdated;
        contactSCToBeUpdated = new List<Contact>();
        
        if(surveyAccountList.size()>0)
        {
            surveyAccountSetTemp.addAll(surveyAccountList);
            surveyAccountList = new List<CS_SurveyAccount__c>();
            surveyAccountList.addAll(surveyAccountSetTemp);
            //insert survey accounts
            Database.SaveResult[] surveyAccountListResult = Database.insert(surveyAccountList,false);
            surveyAccountList = new List<CS_SurveyAccount__c>();
            //logic below to update the Account records with the survey account ids
            
            for(Database.SaveResult result:surveyAccountListResult)
            {
                if(result.isSuccess())
                    surveyAccountIds.add(result.getId());    
                else
                {
                    CS_SurveyException__c excpRecord = new CS_SurveyException__c();
                    excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
                    excpRecord.CS_ExceptionMessage__c = result.getErrors()[0].getMessage() + ' Error in creating Survey Account.';
                    exceptionList.add(excpRecord);
                }       
            }
            
            if(exceptionList.size()>0)
            {
                insert exceptionList;
                exceptionList = new List<CS_SurveyException__c>();
            }            
            
            for(CS_SurveyAccount__c surveyAcc:[select Id,CS_Account__c from CS_SurveyAccount__c where Id in :surveyAccountIds])
            {
                accountIdsSAToBeUpdated.add(surveyAcc.CS_Account__c);
                surveyAccountIdsAccountIds.put(surveyAcc.CS_Account__c,surveyAcc.Id);
            }
            
            for(Account acc:[select Id, Validation_Override__c, CS_SurveyAccount__c from Account where Id in :accountIdsSAToBeUpdated])
            {
                acc.CS_SurveyAccount__c = surveyAccountIdsAccountIds.get(acc.Id);
                acc.Validation_Override__c = true;
                accountSAToBeUpdated.add(acc);
            }
            //Update the Account with Survey Account Id
            update accountSAToBeUpdated;
            
            //Create the survey contacts
            //System.assertEquals(sfContacts,null);
            for(Contact con1:[select Id, AKAM_Contact_Id__c, Validation_Override__c, Account.Id, Account.CS_SurveyAccount__c, CS_AssociatedSurveyContact__c from Contact where Id in :sfContacts])
            {
                if(con1.CS_AssociatedSurveyContact__c == null)
                {
                    surveyContact = new CS_SurveyContacts__c();
                    surveyContact.CS_Account__c = con1.Account.Id;
                    surveyContact.CS_Contact__c = con1.Id;
                    surveyContact.CS_Survey__c = surveyId;
                    surveyContact.CS_SurveyAccount__c = con1.Account.CS_SurveyAccount__c;
                    surveyContact.CS_SurveyResponseSyncId__c = conIdSRId.get(con1.AKAM_Contact_Id__c);
                    surveyContact.CS_Type__c = 'Survey Response';
                    surveyContact.CS_Classification__c = 'None';
                    surveyContactList.add(surveyContact);
                }
            }
        } 
        
        if(surveyContactList.size()>0)
        {
            surveyContactSetTemp.addAll(surveyContactList);
            surveyContactList = new List<CS_SurveyContacts__c>();
            surveyContactList.addAll(surveyContactSetTemp);
            Database.SaveResult[] surveyContactListResult = Database.insert(surveyContactList,false);           
            //Update Contact with the corresponding Survey Contact Id.
            for(Database.SaveResult result:surveyContactListResult)
            {
                if(result.isSuccess())
                    surveyContactIds.add(result.getId());    
                else
                {                   
                    CS_SurveyException__c excpRecord = new CS_SurveyException__c();
                    excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
                    excpRecord.CS_ExceptionMessage__c = result.getErrors()[0].getMessage() + ' Error in creating Survey Contact.';
                    exceptionList.add(excpRecord);
                }       
            }
            
            if(exceptionList.size()>0)
            {
                insert exceptionList;
                exceptionList = new List<CS_SurveyException__c>();
            }
            
            for(CS_SurveyContacts__c surveyCon:[select Id,CS_Contact__c from CS_SurveyContacts__c where Id in :surveyContactIds])
            {
                contactIdsSCToBeUpdated.add(surveyCon.CS_Contact__c);
                surveyContactIdsContactIds.put(surveyCon.CS_Contact__c,surveyCon.Id);
            }
            for(Contact contact:[select Id, CS_LowSatScore__c,CS_CurrentlySurveyed__c, Validation_Override__c, CS_AssociatedSurveyContact__c from Contact where Id in :contactIdsSCToBeUpdated])
            {
                contact.CS_AssociatedSurveyContact__c = surveyContactIdsContactIds.get(contact.Id);
                contact.Validation_Override__c = true;
                contact.CS_LowSatScore__c = false;
                contact.CS_CurrentlySurveyed__c = true;
                contactSCToBeUpdated.add(contact);
            }
            if(contactSCToBeUpdated.size()>0)
                update contactSCToBeUpdated;
        }
         
        /*End of Changes by janantha for handling the condition of no seed data present*/
    
    
    //create exception records in Survey Exception object for invalid akam_contact_ids, blank /non existant values
    for(String akam_contact :akamContacts){
        validId = akamContactIdMap.get(akam_contact);
        if(validId == null || validId == ''){
            invalidIds.add(akam_contact);
        }
    }
    if(invalidIds.size() > 0){
    // retrieve details for invalid akam contact ids
        List<CS_SurveyResponseNameValue__c> invalidRecords= [ select CS_RecordId__c, CS_Value__c,CS_SurveyResponse__c from CS_SurveyResponseNameValue__c where CS_SurveyResponse__c IN :surveyResponseIdList AND (CS_CUSTOMORDER__C=0) AND (CS_Value__c IN :invalidIds) AND (CS_IsDeleted__c = false) ];
        for(CS_SurveyResponseNameValue__c invalidNVRec :invalidRecords){
            Boolean flag = recordIdentifiers.remove(invalidNVRec.CS_RecordId__c + '#' + invalidNVRec.CS_SurveyResponse__c);
            CS_SurveyException__c excpRecord = new CS_SurveyException__c();
            excpRecord.CS_ExceptionInObject__c = 'Survey Response Name-Value';
            excpRecord.CS_SurveyResponse__c = invalidNVRec.CS_SurveyResponse__c;
            excpRecord.CS_Survey__c = surveyId;
            excpRecord.CS_ExceptionMessage__c = 'Invalid AkamContactId - ' + invalidNVRec.CS_Value__c + ' identifeid by the Row Identifier : ' + invalidNVRec.CS_RecordId__c;
            exceptionRows.add(excpRecord);
            invalidNVRec.CS_RecordStatus__c = 'Failed';
            invalidNVRec.CS_SyncStatus__c = 'Failed';
            updateInvalidNVRecs.add(invalidNVRec);
            if(exceptionRows.size()>995){
                insert(exceptionRows);
                exceptionRows.clear();
                }
                // update the status of Name-value records as Failed
            if(updateInvalidNVRecs.size()>995){
                database.update(updateInvalidNVRecs,false);
                updateInvalidNVRecs.clear();
                }
            }
            if(exceptionRows.size()>0){
                insert(exceptionRows);
            }
            if(updateInvalidNVRecs.size()>0){
                database.update(updateInvalidNVRecs,false);
            }
        }
    
    System.debug('>>>recordIdentifiers.isEmpty()>>'+ recordIdentifiers.isEmpty());
     if(!(recordIdentifiers.isEmpty())){
     System.debug('>>>should be false>>'+ recordIdentifiers.isEmpty());
    // convert RowIdentifiers list into a String, so that it can be passed in a SOQL - if this is not done, then soql would look like "where CS_RecordId__c IN (10,12,13,14,15.....)" --> '.' will cause failure
    String recIdString = '';
    for( String recId : recordIdentifiers){
        String splitValue = recId.split('#')[0];
        recIdString = recIdString + '\''+ splitValue + '\',' ;
    }
    // remove the last ','
    recIdString = recIdString.substring(0,recIdString.length()-1 );
    String contactQuery = 'Select CS_Value__c,CS_SyncStatus__c,CS_RecordStatus__c,CS_CustomOrder__c,CS_SurveyResponse__c from CS_SurveyResponseNameValue__c where CS_CustomOrder__c in (0,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19) and CS_RecordId__c IN ( '+ recIdString + ') and CS_SurveyResponse__c IN (' + surveyResponseString +') AND (CS_IsDeleted__c = false) order by CS_SURVEYRESPONSE__C,CS_RecordId__c,CS_CustomOrder__c';
    // call a Batchable class that has logic to update Contacts
   // system.assertEquals (akamContactIdMap,null);
    Id batchinstanceid2 = Database.executeBatch(new CS_BatchableContactUpdate(contactQuery,akamContactIdMap,surveyResponseIdList, surveyId), RecordsPerBatch);
    }
    }
/*
removing old commented code
*/  
    catch(Exception e){
        CS_SurveyException__c excpRecord = new CS_SurveyException__c();
        excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
        excpRecord.CS_ExceptionMessage__c = e.getMessage() + ' (No Survey/Survey Response record  found )';
        //system.assertEquals(e.getLineNumber(),0);
        database.insert(excpRecord);
        }
    }
    
    /*
    Created: 3/20/2011
    By: Sharath
    Description: 1. Updates the contact Ids for NV Rows
                 2. Updates the Question Ids for NV Rows
                 3. Updates the sync status,sync date for NV Rows if corresponding Record Status of Contact is Processed/Failed
    */
   /* public void processNameValue(List<String> surveyResponseIdList,String surveyId){
    
    //Retrieve custom setting values so that we can calcualate batch size of the batch jobs
    CSAT_CustomSettings__c instanceValue1 = CSAT_CustomSettings__c.getInstance('NumberOfRecords');
    Integer noOfRecordsToProcess =Integer.valueOf(instanceValue1.CSAT_Value__c);
       
    // noOfContactsInBatch will be the batch size for the batch jobs
    Integer noOfContactsInBatch = (10000/noOfColumnsInRecord) ;
    
    List<String> akamContacts = new List<String>();
    Map<String,String> recordIdAkamContactMap= new Map<String,String>();
    Map<String,String> akamContactIdMap= new Map<String,String>();
    Map<String,String> nvFieldQuestionMap= new Map<String,String>();    
    Map<String,String> recIdRecStatusMap = new Map<String,String>();
    List<Contact> contactIds = new List<Contact>();
        
    // retrieve the list of unique NV records for which record status is populated and contact Id is not populated.
    List<CS_SURVEYRESPONSENAMEVALUE__C> processedContactsList =[SELECT CS_RECORDID__C,CS_SURVEYRESPONSE__C,CS_VALUE__C,CS_RECORDSTATUS__C FROM CS_SURVEYRESPONSENAMEVALUE__C WHERE CS_RECORDSTATUS__C != '' AND (CS_CONTACTID__C='') AND (CS_CUSTOMORDER__C =0 ) AND (CS_SURVEYRESPONSE__C IN :surveyResponseIdList) AND (CS_IsDeleted__c = false) order by CS_SURVEYRESPONSE__C,CS_RecordId__c limit :noOfRecordsToProcess];
    if(!(processedContactsList.isEmpty())){
        String recIds ='';
        for(CS_SURVEYRESPONSENAMEVALUE__C processedContact :processedContactsList){
            recIds = recIds + '\''+ processedContact.CS_RecordId__c + '\',' ;
            akamContacts.add(processedContact.CS_VALUE__C);
            //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
            recordIdAkamContactMap.put(processedContact.CS_RECORDID__C + '#' + processedContact.CS_SurveyResponse__c,processedContact.CS_VALUE__C);
            //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
            recIdRecStatusMap.put(processedContact.CS_RecordId__c + '#' + processedContact.CS_SurveyResponse__c,processedContact.CS_RecordStatus__c);
            }
        // remove the last ','
        recIds = recIds.substring(0,recIds.length()-1 );
        
        // create a string form of surveyResponseList
        String surveyResponseString = '';
        for( String surveyRespId : surveyResponseIdList){
            surveyResponseString = surveyResponseString + '\''+ surveyRespId + '\',' ;
        }
        // remove the last ','
        surveyResponseString = surveyResponseString.substring(0,surveyResponseString.length()-1 );
    
        // Retieve all the Contact_Ids for  corresponding akam_contact_Ids
        contactIds = [ SELECT ID,AKAM_CONTACT_ID__C FROM CONTACT WHERE AKAM_CONTACT_ID__C IN :akamContacts ];
    
        // create a map between akam_contact_Ids and SF Contact_Ids
        for( Contact c:contactIds){
            akamContactIdMap.put(c.AKAM_CONTACT_ID__C,c.ID);
        }
        // create a map between Questions and corresponding fields in Name-Value object
        List<CS_SurveyQuestion__c> questions = [select Id, CS_MapToField__c from CS_SurveyQuestion__c where (CS_IsDeleted__c = false) AND (CS_QuestionSet__r.CS_QuestionnareNumber__r.CS_SurveyId__c = :surveyId) order by Name ];
        for( CS_SurveyQuestion__c question: questions){
            nvFieldQuestionMap.put(question.CS_MapToField__c, question.Id );
            }
        
        //for each row in name value, populate ContactId from Contact. So, prepare a SOQL which will be used a parameter to a Batchable call
        String NVQuery= 'Select CS_ContactId__c,CS_RecordId__c,CS_Name__c,CS_SurveyResponse__c,CS_SyncStatus__c,CS_SyncDate__c from CS_SurveyResponseNameValue__c where CS_RECORDID__C in (' + recIds +') AND CS_SurveyResponse__c IN ('+ surveyResponseString +') AND (CS_ContactId__c =\'\') AND (CS_IsDeleted__c = false) order by CS_SURVEYRESPONSE__C,CS_RECORDID__C, CS_CustomOrder__c';
        // batch size is never greater than 10000 and is always a multiple of the number of columns in a record (137)
        Id batchinstanceid1 = Database.executeBatch(new CS_BatchableNVUpdate(NVQuery,recordIdAkamContactMap,akamContactIdMap,nvFieldQuestionMap,recIdRecStatusMap), noOfContactsInBatch*noOfColumnsInRecord);
    }
    }*/
    
/*
removing old commented code 
*/
}