/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: trigger for SC Jira Ticket Info
 * Date: 7th October 2020
 * 
     Last Modified Developer                 Purpose            
    ============= ========================  =======
    22 Feb 2021     Sharath Prasanna        Made the Jira query configurable

*/ 

public without sharing class SC_JiraTicketInfo_Handler extends ApexTriggerHandlerAbstractClass
{
    public SC_JiraTicketInfo_Handler() 
    {

    }
    //The beforeinsertupdate handler
    public override void beforeInsertBeforeUpdateTrigger()
    {    
        //Set the Jira Id field from Name
        if(Trigger.isInsert)
        {
            for(SC_Jira_Ticket_Info__c recordJIra: (List<SC_Jira_Ticket_Info__c>) newList)
            {
                recordJIra.Jira_Id__c = (recordJIra.Jira_Id__c == null || recordJIra.Jira_Id__c == '')? 
                recordJIra.Name: recordJIra.Jira_Id__c;
            }

        }
    }
    //The afterinsertupdate handler
    public override void afterInsertAfterUpdateTrigger()
    {
        //On Update, the data should flow to the Escalation object
        if(Trigger.isUpdate)
        {
            Set<String> jiraIds = new Set<String>();
            for(SC_Jira_Ticket_Info__c jiraRec: (List<SC_Jira_Ticket_Info__c>) newList)
            {            
                jiraIds.add(jiraRec.Jira_Id__c);
            }
            if(!jiraIds.isEmpty() && !(System.isFuture() || System.isScheduled() || System.isBatch()))
            {
                updateEscalationRecords(jiraIds);
            }

        }
    }
    //The before delete/undelete handler
    public override void beforeDeleteBeforeUndeleteTrigger()
    {

    }
    //The after delete/undelete handler
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }   

    //future method to update escalation records
    @future
    public static void updateEscalationRecords(Set<String> jiraIds)
    {
        
        Map<String,SC_Jira_Ticket_Info__c> jiraIdToRec = new Map<String,SC_Jira_Ticket_Info__c>();
        Map<String,String> engagementToJiraMap = new Map<String,String>();
        List<String> fields;
        for (SC_Utility__mdt retryCountRec : [Select Value__c from SC_Utility__mdt where 
        Active__c = true and developername like 'JiraSyncEscalationMapping%' ])
        {            
            for(String mapping: retryCountRec.Value__c.split(','))
            {
                fields = mapping.split(':'); 
                if(fields != null && fields.size() == 2)
                {
                    engagementToJiraMap.put(fields.get(0),fields.get(1));
                }                
            }
        }
        if(!engagementToJiraMap.isEmpty())
        {
            //Adding the values of engagementToJiraMap to get unique values
            Set <String> jiraFielfFromMap = new Set <String>();
            jiraFielfFromMap.addAll(engagementToJiraMap.values());
            string sqlQuery = 'Select Id,Jira_Id__c,';
            //a join on the list of jira fields to query
            sqlQuery += String.join(new List<String>(jiraFielfFromMap), ',');
            sqlQuery += ',Last_Sync_Status__c,Last_Sync_Message__c from SC_Jira_Ticket_Info__c where Jira_Id__c in :jiraIds';


            List<SC_Jira_Ticket_Info__c> jiraRecordsFromQuery = new List<SC_Jira_Ticket_Info__c>();
            jiraRecordsFromQuery = Database.query(sqlQuery);
            //populate map of Jira Id to Jira rec    

            for(SC_Jira_Ticket_Info__c jiraRec : jiraRecordsFromQuery)
            {
                jiraIdToRec.put(jiraRec.Jira_Id__c,jiraRec);
            }
            //Clearing the List
            jiraRecordsFromQuery.clear();
            jiraFielfFromMap.clear();            

            sqlQuery = 'Select Id,ID__c,';
            sqlQuery += String.join(new List<String>(engagementToJiraMap.keySet()), ',');
            sqlQuery += ',Error_Message__c from Engagement_Request__c where Case__r.Status != \'Closed\' and System__c = \'JIRA\' and ID__c in :jiraIds and Case__r.Casenumber != null';
            sqlQuery += ' order by Case__c'; 
            
            SC_Jira_Ticket_Info__c jiraRecord;
            List<Engagement_Request__c> recordsFromQuery = new List<Engagement_Request__c>();
            List<Engagement_Request__c> erRecords = new List<Engagement_Request__c>();
            
            //update each escalation record
            recordsFromQuery = Database.query(sqlQuery);
            for (Engagement_Request__c erRecord : recordsFromQuery)
            {
                if(jiraIdToRec.containsKey(erRecord.ID__c))
                {
                    jiraRecord = jiraIdToRec.get(erRecord.ID__c);
                    for(String fieldName: engagementToJiraMap.keySet())
                    {
                        erRecord.put(fieldName,jiraRecord.get(engagementToJiraMap.get(fieldName)));    
                    }
                    erRecord.Error_Message__c = jiraRecord.Last_Sync_Status__c == 'Failure' ? jiraRecord.Last_Sync_Message__c: null;    
                    erRecords.add(erRecord);
                }            
            }
            
            if(!erRecords.isEmpty())
            {
                List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
                saveResultRecords = Database.Update(erRecords,False);
                //sendErrorMail(saveResultRecords);               
                PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
                String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';
                Map<String,String> parameters = new Map<String,String>();
                parameters.put('recepients',emailAddress);
                parameters.put('subject','Jira Poller Engagement Request Update');
                parameters.put('Caption','Escalations');
                PopulateErrorTableForUpdate(saveResultRecords,erRecords,true,parameters);
            }
            
        }

    }
    
    //synchronous method to create and return jira references
    public static Map<String,String> getJiraRecords(Set<String>jiraIds)
    {
        return createJiraRecords(jiraIds);
    }
    
    //a future method to create jira references
    @future
    public static void getJiraRecordsFuture(Set<String>jiraIds)
    {
        createJiraRecords(jiraIds);
    }
    
    //Future method to add records to the jira object
    public static Map<String,String> createJiraRecords(Set<String>jiraIds)
    {
        Map<String,String> jiraToIds = new Map<String,String>();
        Set<String> jiraIdsToCreate = new Set<String>();
        jiraIdsToCreate.addAll(jiraIds);
        List<SC_Jira_Ticket_Info__c> jiraRecords = new List<SC_Jira_Ticket_Info__c>();
        SC_Jira_Ticket_Info__c jiraRecord; 
        for(SC_Jira_Ticket_Info__c jiraRec : [Select Id,Jira_Id__c from SC_Jira_Ticket_Info__c where Jira_Id__c in : jiraIds])
        {
            jiraToIds.put(jiraRec.Jira_Id__c,jiraRec.Id);
        }
        if(!jiraToIds.isEmpty())
        {
            jiraIdsToCreate.removeAll(jiraToIds.keySet());
        }
        for(String jiraId : jiraIdsToCreate)
        {
            jiraRecord = new SC_Jira_Ticket_Info__c(Name=jiraId,Jira_Id__c=jiraId);
            jiraRecords.add(jiraRecord);   
        }
        if(!jiraRecords.isEmpty())
        {
            List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
            saveResultRecords = Database.insert(jiraRecords,False);
            Database.SaveResult sr;
            String errors = '';            
                
            for(Integer i = 0; saveResultRecords != null && jiraRecords != null &&  i < saveResultRecords.size(); i++)
            {
                sr = saveResultRecords.get(i);
                if (!sr.isSuccess()) 
                {
                    for(Database.Error err : sr.getErrors()) 
                    {
                        errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ jiraRecords.get(i).id + '</td></tr>';
                    }
                }
                else
                {
                    jiraToIds.put(jiraRecords.get(i).Jira_Id__c,sr.getId());
                }
            }
            if(errors != '')
            {
                String table = '';     
                table = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>';  
                table += '<table><caption><b>' +'Jira Records' + '</b></caption><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
                table += errors;
                table += '</table><br/><br/></body></html>';      

                PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
                String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';
                    
                Map<String,String> emailParams = new Map<String,String>();
                emailParams.put('emailBody',table);
                emailParams.put('recepients',emailAddress);
                emailParams.put('subject','Create Jira Records');
                sendErrorMails(emailParams);                
                
            }
    

        }
        return jiraToIds;
    }

    //The function to loop over the List of Update/Save results. If there is any failure, send a mail with the error table
    public static String PopulateErrorTableForUpdate(List<Database.SaveResult> results,List<SObject> objectLists,Boolean sendEmail,Map<String,String> parameters)
    {
        String errors = '';            
        String table = ''; 
        String tableCaption = parameters.containsKey('Caption') ? parameters.get('Caption') : 'Errors';
        for(Integer i = 0; results != null && objectLists != null &&  i < results.size(); i++)
        {
          Database.SaveResult sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                    errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ objectLists.get(i).id + '</td></tr>';
                }
            }

        }
        if(errors != '')
        {
            table = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>';  
            table += '<table><caption><b>' +tableCaption + '</b></caption><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
            table += errors;
            table += '</table><br/><br/></body></html>';      
            
            if(sendEmail && parameters.containsKey('recepients'))
            {
                Map<String,String> emailParams = new Map<String,String>();
                emailParams.put('emailBody',table);
                emailParams.put('recepients',parameters.get('recepients'));
                emailParams.put('subject',parameters.get('subject'));
                sendErrorMails(emailParams);                
            }        
            
        }
        return table;
    }

    //The function to loop over the List of upsert results. If there is any failure, send a mail with the error table
    public static String PopulateErrorTableForUpsert(List<Database.UpsertResult> results,Boolean sendEmail,Map<String,String> parameters)
    {
        String errors = '';            
        String table = '';
        String tableCaption = parameters.containsKey('Caption') ? parameters.get('Caption') : 'Errors'; 
        for (Database.UpsertResult sr : results)
        {
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                    errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ err.getFields() + '</td></tr>';
                }
            }
        }
        if(errors != '')
        {
            table = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>';  
            table += '<table><caption><b>' +tableCaption + '</b></caption><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
            table += errors;
            table += '</table><br/><br/></body></html>';      
            if(sendEmail && parameters.containsKey('recepients'))
            {
                Map<String,String> emailParams = new Map<String,String>();
                emailParams.put('emailBody',table);
                emailParams.put('recepients',parameters.get('recepients'));
                emailParams.put('subject',parameters.get('subject'));
                sendErrorMails(emailParams);                
            }        
        }
        return table;
    }

    //This takes in the subject and the error message string: sends a mail to the engg team
    public static void sendErrorMails(Map<String,String> parameters)
    {
        if(!parameters.containsKey('emailBody') || !parameters.containsKey('recepients'))
        {
            return;
        }
        String subject = parameters.containsKey('subject')? parameters.get('subject') : 'Error Mail';
        String hostName = URL.getSalesforceBaseUrl().getHost(); 
        String body = '<html>Hi team<br/><br/>'+ 'Hostname: ' +hostName + '<br/><br/>' + parameters.get('emailBody'); 
        
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(parameters.get('recepients').split(','));            
        objEmail.setSubject(subject + hostName);
        objEmail.setHTMLBody( body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);

    }    
}