global class CS_BatchableContactUpdate implements Database.Batchable<sObject>{
/*
Author: Sharath
Version: 1.0
Created date: 01/10/2010
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Modified: Sharath 03/20/2011 
CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
CR 1011117 CSAT: Decoupling the Cast Iron logic to check for low sat score and moving it to Salesforce
CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts
Modified: Sharath 07/01/2011
CR 1186969 - Removing logic to populate Low Sat Score & NPS fields through code
*/

    global final String Query;
    global final List<String> surveyResponseIdList;
    global final String surveyId;
    Map<String,String> akamIdContactIdMap = new Map<String,String>();
    global List<String> createCaseForTheseContactsList = new List<String>();   
    /* 
Author: Sharath
Version: 1.0
Created date: 01/10/2010
    Description: Contructor with no parameters for the class to be inherited. 
    */
    global CS_BatchableContactUpdate()
    {
        
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/10/2010
    Description: Parameterised contructor for initialising the query
    */
    global CS_BatchableContactUpdate(String Query,Map<String,String> akamContactIdMap, List<String> surveyResponseIdList,String surveyId)
    {
        this.Query = Query;
        this.surveyResponseIdList = surveyResponseIdList;
        this.surveyId = surveyId;
        akamIdContactIdMap = akamContactIdMap;
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/10/2010
    Description: this method returns a Database.QueryLocator which is used as an input to the execute method. 
    */
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 01/10/2010
    Description: this method executes the query returned by start method. This method updates Contacts from Name-value object for a particular SurveyResponse
    Modified: Sharath
    CR 1011117 CSAT: Decoupling the Cast Iron logic to check for low sat score and moving it to Salesforce
        - added IF conditions to check if incoming score is not null and is lesser than 6, if so, mark lowSatScore field = TRUE
    CR 1014942 CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
        - adding a map "contactIdSyncIdMap" that links a contact with a particular surveyResponse Sync Id
    CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts
        - Need to update Survey Contacts instead of Contacts, hence making necessary changes in SOQL and fields to update
    Modified: Sharath 06/03/2011
    CR 1140535 CSAT:  Contacts Update Apex Job to look at Response Date
        - Adding logic so that no old responses(previous surveys) get processed
    Modified: Sharath 07/01/2011
    CR 1186969 - Removing logic to populate Low Sat Score & NPS fields through code
    */
     global void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        List<CS_SurveyContacts__c> updateContacts = new List<CS_SurveyContacts__c>(); 
        List<CS_SurveyResponseNameValue__c> updateNVRows = new List<CS_SurveyResponseNameValue__c>();
        List<CS_SurveyResponseNameValue__c> nvRows = new List<CS_SurveyResponseNameValue__c>();
        Map<String,CS_SurveyContacts__c> akamIdContactMap = new Map<String,CS_SurveyContacts__c>();
        // all the  NV rows that meet batch SOQL criteria are stored in nvRows list
        nvRows = scope;
        // retrieve all the Values(salesforce Contact Ids) from the Map
        List<String> sfContacts = akamIdContactIdMap.values();
        CS_SurveyContacts__c con =new CS_SurveyContacts__c();
        Set<String> contactIdSet = new Set<String>();
        Map<String,CS_SurveyResponseNameValue__c> contactIdnvRowMapping = new Map<String,CS_SurveyResponseNameValue__c>();
        Map<String,String> contactIdSyncIdMap = new Map<String,String>();
        String truncatedScore;       
        Set<String> erroredContactIds = new Set<String>();
        List<CS_SURVEYRESPONSENAMEVALUE__C> erroredNameValues = new List<CS_SURVEYRESPONSENAMEVALUE__C>();
        
        try{
        Date surveyOpenedDate = [SELECT Id,Name,CS_SurveyOpenedOn__c from CS_Survey__c where CS_Status__c = 'Active' order by CreatedDate desc limit 1 ][0].CS_SurveyOpenedOn__c;
        
        //CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts - identify all survey contacts that have to be updated. 
        List<CS_SurveyContacts__c> contactsToUpdate = [ select Id,CS_SyncDate__c,CS_NPS__c,CS_SyncStatus__c,CS_SurveyResponseSyncId__c,CS_Contact__r.akam_contact_id__c,CS_OverallSatWithProductAdvertising__c,CS_OverallSatWithProductEnterpriseApps__c,CS_OverallSatWithImplementationChange__c,CS_OverallSatWithProductSoftware__c,CS_OverallSatWithAccountMgmtSupport__c,CS_OverallSatWithProductStreamingMedia__c,CS_OverallSatWithProductWebSite__c,CS_OverallSatWithProductOthers__c,CS_LikelihoodToRecommend__c,CS_Classification__c,CS_Type__c,CS_LowSatScore__c,CS_OverallSatisfaction__c,CS_ImplementationProcessSatisfaction__c,CS_BusinessSupportSatisfaction__c,CS_EdgeControlSatisfaction__c,CS_SalesProcessSatisfaction__c,CS_FeedbackReceivedDate__c,CS_CustomerCareSatisfaction__c,CS_BillingOperationsSatisfaction__c from CS_SurveyContacts__c where CS_Contact__c IN :sfContacts AND CS_SurveyAccount__r.CS_Survey__c = :surveyId];
        for(CS_SurveyContacts__c c : contactsToUpdate){
            akamIdContactMap.put(c.CS_Contact__r.akam_contact_id__c, c);
            }
        
        // iter - counter to identify position of old response in the list "contactsToUpdate"
        Integer iter = 0;
        // the name- value records in nvRows are stored in ASCENDING order. 1st row always maps to akam-contact Id. So whenever you come across akam-contact Id, treat all following rows as field values for that contact 
        for(CS_SurveyResponseNameValue__c nvRow :nvRows){
            if(nvRow.CS_CustomOrder__c==0){
                con = akamIdContactMap.get(nvRow.CS_Value__c);
                if(con == null){
                    continue;
                }
                nvRow.CS_SyncStatus__c = 'Processed';
                nvRow.CS_RecordStatus__c = 'Processed';
                nvRow.CS_SyncDate__c = datetime.now();
                // the following map is used for error handling. If contact update fails, corresponding NV records should also go to FAILED
                contactIdnvRowMapping.put(con.Id,nvRow); 
                // CR 1014942 change - associate the contact with a survey response sync id
                contactIdSyncIdMap.put(con.Id,nvRow.CS_SurveyResponse__c);
                updateNVRows.add(nvRow);
                if(updateNVRows.size() > 995){
                    database.update(updateNVRows,false);
                    updateNVRows.clear();
                    }
                if(updateContacts.size() >995){
                database.update(updateContacts,false);
                updateContacts.clear();
                }
            }
            // CR 1011117 changes - checking for scores less than 6
            if(nvRow.CS_CustomOrder__c==2 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductStreamingMedia__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==3 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductOthers__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==4 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductWebSite__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==5 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_EdgeControlSatisfaction__c= nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==6 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_SalesProcessSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==7 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                /* CR 1140535 - don't process old responses. Remove the old responses for the List which will be updated at the end */
                /*String responseDate = nvRow.CS_Value__c;
                Date formattedResponseDate =  Date.parse(responseDate);
                if(formattedResponseDate < surveyOpenedDate){
                    
                    contactsToUpdate.remove(iter);
                    iter++;
                    continue;
                    }*/
                /*else{*/
                    con.CS_FeedbackReceivedDate__c = nvRow.CS_Value__c;
                    //}
                iter++;
                }
            if(nvRow.CS_CustomOrder__c==8 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_CustomerCareSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==9 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_BillingOperationsSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==10 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_BusinessSupportSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==11 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_ImplementationProcessSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==12 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
            // assumption - This field is MANDATORY. Hence, updating Sync Status, surveyresponse sync id here
                con.CS_LikelihoodToRecommend__c = nvRow.CS_Value__c;
                con.CS_Type__c = 'Survey Response';
                con.CS_SyncStatus__c = 'Pending';
                con.CS_SyncDate__c = datetime.now();
                con.CS_SurveyResponseSyncId__c = nvRow.CS_SurveyResponse__c;
                //split score on "," (0, very unlikely / 10, very likely are the 2 scenarios)
                truncatedScore = nvRow.CS_Value__c.split(',')[0].trim();
                // CR 1186969 - Removing logic to populate NPS through code
                // CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts - logic to set the Classification for the survey Contact
                if(Integer.valueOf(truncatedScore) <= 6){
                    // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                    con.CS_Classification__c = 'Detractor';
					 try
					{
					if(con!=NULL && con.CS_CaseId__c == NULL)
					createCaseForTheseContactsList.add(con.CS_Contact__c);
					con.CS_CaseId__c = 'Processed';
                    }
					catch(exception e)
					{
						CS_SurveyException__c excpRecord = new CS_SurveyException__c();
						excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
						excpRecord.CS_ExceptionMessage__c = e.getMessage() + ' (Error in creating Detractor Case)';
						database.insert(excpRecord);
					
					}
                    }
                else if (Integer.valueOf(truncatedScore) <= 8){
                    con.CS_Classification__c = 'Passive';
                    }
                else{
                    con.CS_Classification__c = 'Promoter';
                    }
                }
            if(nvRow.CS_CustomOrder__c==13 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatisfaction__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==15 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithAccountMgmtSupport__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==16 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductAdvertising__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==17 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductEnterpriseApps__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==18 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithImplementationChange__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(nvRow.CS_CustomOrder__c==19 && nvRow.CS_Value__c!='' && nvRow.CS_Value__c!=null && con!= null){
                con.CS_OverallSatWithProductSoftware__c = nvRow.CS_Value__c;
                // CR 1186969 - Removing logic to calcualte Low Sat Score through code
                }
            if(con!= null){
            // the contactIdSet is used for error handling purpose.
            contactIdSet.add(con.Id);
            }
        }
        
        if(updateNVRows.size() >0){
            database.update(updateNVRows,false);
            }
        if(contactsToUpdate.size()>0){
        // false parameter allows update operation to continue even if one contact Update fails
        Database.SaveResult[]  saveResults = database.update(contactsToUpdate,false);
        
        List<CS_SurveyException__c> exceptionRows= new List<CS_SurveyException__c>();
        for (Integer j = 0; j < saveResults.size(); j++){
            if ((saveResults[j].isSuccess())){
                // if Update is successful, remove the corresponding Conatct from ContactIdSet
                contactIdSet.remove(saveResults[j].getId());
                }
            }
            
            // error handling - if size of ContactIdSet is > 0,few errors have occured while updating
            if(contactIdSet.size()>0){
                
                updateNVRows.clear();
                // for each Contact which couldn't be updated, update corresponding NV rows to Failed
                for(String contact : contactIdSet){
                    CS_SurveyResponseNameValue__c nvRow = contactIdnvRowMapping.get(contact);
                    nvRow.CS_RecordStatus__c = 'Failed';
                    nvRow.CS_SyncStatus__c = 'Failed';
                    updateNVRows.add(nvRow);
                    }
                database.update(updateNVRows);
                
                //populate the Survey Exception object
                List<String> failedIds = new List<String>();
                failedIds.addAll(contactIdSet);
                Integer i =0 ;
                String failedContactId;
                List<CS_SurveyException__c> updateExceptions = new List<CS_SurveyException__c>();
                for (Integer j = 0; j < saveResults.size(); j++){
                    if (!(saveResults[j].isSuccess())){
                        CS_SurveyException__c excpRecord1 = new CS_SurveyException__c();
                        excpRecord1.CS_ExceptionInObject__c = ' Survey Contacts';
                        String errorMessage = '';
                        for(Database.Error err :saveResults[j].getErrors()){
                            errorMessage = errorMessage + err.getMessage();
                            }
                        failedContactId = failedIds[i++];
                        excpRecord1.CS_ExceptionMessage__c = errorMessage;
                        excpRecord1.CS_Survey__c = surveyId;
                        //CR 1014942 change - get the contact's surveyResponse sync id from the map
                        excpRecord1.CS_SurveyResponse__c = contactIdSyncIdMap.get(failedContactId);
                        excpRecord1.CS_ErrorRecordId__c = failedContactId;
                        updateExceptions.add(excpRecord1);
                        }
                    }
                if(updateExceptions.size()>0){
                    database.insert(updateExceptions);
                    }
                }
        }
         if(createCaseForTheseContactsList!= NULL)
        {
            if(createCaseForTheseContactsList.size() > 0)
            {
             CS_CreateCaseForDetractors CreateCaseForDetractorContacts = new CS_CreateCaseForDetractors(createCaseForTheseContactsList,surveyId);
             CreateCaseForDetractorContacts.csCreateCaseFunction();
            }
        }
        /*
        not updating accounts anymore - removing pervious code
        */
        }
        catch(Exception e){
            CS_SurveyException__c excpRecord = new CS_SurveyException__c();
            excpRecord.CS_ExceptionInObject__c = 'CS_BatchableContactUpdate ApexClass';
            excpRecord.CS_ExceptionMessage__c = e.getMessage();
            database.insert(excpRecord);
            }
    }
    
    /*
Author: Sharath
Version: 1.0
Created date: 01/10/2010
    Description: this method can be used to send mails regarging the batch job. 
    */
    global void finish(Database.BatchableContext BC)
    {   
        CSAT_CustomSettings__c instanceValue1 = CSAT_CustomSettings__c.getInstance('NumberOfRecords');
        Integer noOfRecordsToProcess =Integer.valueOf(instanceValue1.CSAT_Value__c);
        
        CSAT_CustomSettings__c CSRecsPerBatch = CSAT_CustomSettings__c.getInstance('RecordsPerBatch');
        Integer RecordsPerBatch = Integer.valueOf(CSRecsPerBatch.CSAT_Value__c);
        
        CSAT_CustomSettings__c instanceValue2 = CSAT_CustomSettings__c.getInstance('NumberOfColumns');
        Integer noOfColumnsInRecord = Integer.valueOf(instanceValue2.CSAT_Value__c);
        // noOfContactsInBatch will be the batch size for the batch jobs
        Integer noOfContactsInBatch = (10000/noOfColumnsInRecord) ;
        List<String> srIdList = new List<String>();
        List<CS_SurveyResponse__c> processedSurveyResponses = [ select Id,CS_NoInPending__c,CS_SyncStatus__c,CS_SyncStatusMessage__c from CS_SurveyResponse__c where CS_SyncStatus__c = 'Contacts Processed' AND (CS_Survey__c = :surveyId) AND (CS_IsDeleted__c = false) ];
        if(!(processedSurveyResponses.isEmpty())){
            for(CS_SurveyResponse__c processedSurveyResponse :processedSurveyResponses){
                srIdList.add(processedSurveyResponse.Id);
            }
        }
        //change by janantha. Commenting out the below line and using the soql in the for loop for efficiency*/        
        //List<CS_SURVEYRESPONSENAMEVALUE__C> processedContactsList = [SELECT CS_RECORDID__C,CS_SURVEYRESPONSE__C,CS_VALUE__C,CS_RECORDSTATUS__C FROM CS_SURVEYRESPONSENAMEVALUE__C WHERE CS_RECORDSTATUS__C != '' AND (CS_CONTACTID__C='') AND (CS_CUSTOMORDER__C =0 ) AND (CS_SURVEYRESPONSE__C IN :srIdList) AND (CS_IsDeleted__c = false) order by CS_SURVEYRESPONSE__C,CS_RecordId__c limit :noOfRecordsToProcess];
        List<String> akamContacts = new List<String>();
        Map<String,String> recordIdAkamContactMap= new Map<String,String>();
        Map<String,String> akamContactIdMap= new Map<String,String>();
        Map<String,String> nvFieldQuestionMap= new Map<String,String>();    
        Map<String,String> recIdRecStatusMap = new Map<String,String>();
        List<Contact> contactIds = new List<Contact>();
        //change by janantha. Commenting out the below line.  
        //if(!(processedContactsList.isEmpty())){
            String recIds ='';
            for(CS_SURVEYRESPONSENAMEVALUE__C processedContact :[SELECT CS_RECORDID__C,CS_SURVEYRESPONSE__C,CS_VALUE__C,CS_RECORDSTATUS__C FROM CS_SURVEYRESPONSENAMEVALUE__C WHERE CS_RECORDSTATUS__C != '' AND (CS_CONTACTID__C='') AND (CS_CUSTOMORDER__C =0 ) AND (CS_SURVEYRESPONSE__C IN :srIdList) AND (CS_IsDeleted__c = false) order by CS_SURVEYRESPONSE__C,CS_RecordId__c])
            {
                recIds = recIds + '\''+ processedContact.CS_RecordId__c + '\',' ;
                akamContacts.add(processedContact.CS_VALUE__C);
                //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
                recordIdAkamContactMap.put(processedContact.CS_RECORDID__C + '#' + processedContact.CS_SurveyResponse__c,processedContact.CS_VALUE__C);
                //3/25/2011 - concatinating CS_SurveyResponse__c to the maps, so that we can identify to which surveyResponse file it belongs
                recIdRecStatusMap.put(processedContact.CS_RecordId__c + '#' + processedContact.CS_SurveyResponse__c,processedContact.CS_RecordStatus__c);
            }
            // remove the last ','
            //change by janantha - Adding the condition for null check.
            if(recIds != '' && recIds != null)
                recIds = recIds.substring(0,recIds.length()-1 );
            
            // create a string form of surveyResponseList
            String surveyResponseString = '';
            for( String surveyRespId : surveyResponseIdList){
                surveyResponseString = surveyResponseString + '\''+ surveyRespId + '\',' ;
            }
            // remove the last ','
            //change by janantha - Adding the condition for null check.
            if(surveyResponseString != '' && surveyResponseString != null)
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
            
            if(!Test.isRunningTest())
                Id batchinstanceid1 = Database.executeBatch(new CS_BatchableNVUpdate(NVQuery,recordIdAkamContactMap,akamContactIdMap,nvFieldQuestionMap,recIdRecStatusMap), RecordsPerBatch);
   // }
}
}