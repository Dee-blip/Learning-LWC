/*
* Developer  : Vandhana Krishnamurthy
* Purpose    : Service Cloud code on task trigger
* Date       : 4 June 2020
* Test Class : SC_SecurityServices_Ctrlr_Test, SC_SI_AllUseCases_TC, SC_RCA_AllUseCase_TC , SC_SOCC_Case_LightningUtility_TC , SC_Elevation_TriggerHandler_Test
* 
* Date                 Developer           JIRA                            Changes
* 26-May-2020          Vandhana         ESESP-3524                 S2ET Security Service Activity Tasks
* 20-Oct-2020         Sheena Bhan       ESESP-3767                 Added logic to populate 'Total Incident LOE (Hours)' field on SI.     
* 10-Aug-2021           Vandhana        ESESP-4359                 Elevate/Escalate on Account
* 25-Apr-2022          Tejaswini        ESESP-6444                 Salesforce automation for case closure - SOCC
*/ 

public class SC_TaskTriggerHandler 
{
    public static Boolean s2etCheckRecursion = true;
    public static Boolean s2etTaskDeferBypass = true;
    public static Boolean s2etSchedDepTaskBypass = false;
    //private class TicketPushException extends Exception { }
    
    public static void s2etDueDateCorrect(List<Task> lstTask, Boolean isInsert)
    {   
        System.debug('Entered Once');
        TimeZone tz = UserInfo.getTimeZone();
        Integer offset = (tz.getOffset(System.now()))/1000;
        List<String> shiftTimeMap = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'S2ET_Shift_Mapping'].Value_Text__c.split('-');
        
        Map<Integer,List<String>> shiftMap = new Map<Integer,List<String>>();
        Integer i=0;
        for(String s : shiftTimeMap)
        {
            shiftMap.put(i++,s.split(','));
        }
        
        for(Task eachTask : lstTask)
        {   
            if(eachTask.Assigned_Division__c == 's2etautogen' && isInsert)
            {
                if(eachTask.DueDateProlexic__c.hourGMT() >= Integer.valueOf(shiftMap.get(0)[0]) && eachTask.DueDateProlexic__c.hourGMT() < Integer.valueOf(shiftMap.get(0)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(0)[2];
                }
                else if(eachTask.DueDateProlexic__c.hourGMT() >= Integer.valueOf(shiftMap.get(1)[0]) && eachTask.DueDateProlexic__c.hourGMT() < Integer.valueOf(shiftMap.get(1)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(1)[2];
                }
                else if(eachTask.DueDateProlexic__c.hourGMT() >= Integer.valueOf(shiftMap.get(2)[0]) && eachTask.DueDateProlexic__c.hourGMT() < Integer.valueOf(shiftMap.get(2)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(2)[2];
                }
                else 
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(3)[2];
                }
            }
            else  
            {
                if( eachTask.DueDateProlexic__c.hour() >= Integer.valueOf(shiftMap.get(0)[0]) && eachTask.DueDateProlexic__c.hour() < Integer.valueOf(shiftMap.get(0)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(0)[2];
                }
                else
                    if(eachTask.DueDateProlexic__c.hour() >= Integer.valueOf(shiftMap.get(1)[0]) && eachTask.DueDateProlexic__c.hour() < Integer.valueOf(shiftMap.get(1)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(1)[2];
                }
                else
                    if(eachTask.DueDateProlexic__c.hour() >= Integer.valueOf(shiftMap.get(2)[0]) && eachTask.DueDateProlexic__c.hour() < Integer.valueOf(shiftMap.get(2)[1]))
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(2)[2];
                }
                else 
                {
                    eachTask.Assigned_Shift__c = shiftMap.get(3)[2];
                }
            }
            
            //if(SC_TaskTriggerHandler.s2etCheckRecursion)
            //{
            if(s2etTaskDeferBypass && (eachTask.Assigned_Division__c != 's2etautogen' || (eachTask.Assigned_Division__c == 's2etautogen' && !isInsert)))
            {
                eachTask.DueDateProlexic__c = eachTask.DueDateProlexic__c.addSeconds(offset);
            }
            //}
        }
        
        s2etCheckRecursion = false;
    }
    
    // Method to call addIncidentLoe after delete for 'Total Incident LOE (Hours)' logic
    public static void onAfterDelete(List<Task> taskList)
    {
        addIncidentLoe(taskList); 
    }
    
    
    /*********** ESESP-3767: Method to Populate the 'Total Incident LOE (Hours)' field on SI.**********/
    public static void addIncidentLoe(List<Task> taskList)
    {
        List<SC_SI_Service_Incident__c> siToUpt = new List<SC_SI_Service_Incident__c>();
        List<SC_SI_Service_Incident__c> siList = new List<SC_SI_Service_Incident__c>();
        Set<Id> siIds = new Set<Id>();
        Decimal totalLoeHrs = 0;
        Id SIActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident Activity').getRecordTypeId();
        String siObjPrefix = Schema.getGlobalDescribe().get('SC_SI_Service_Incident__c').getDescribe().getKeyPrefix();
        
        for(Task eachTask: taskList){
            // Check for afterDelete and afterUndelete
            if(eachTask.WhatId != null  && eachTask.RecordtypeId == SIActivityId && String.valueOf(eachTask.WhatId).startsWith(siObjPrefix))
                siIds.add(eachTask.WhatId);
        }
        
        if(!siIds.isEmpty()){
            siList = [select id,Total_Incident_LOE_Hours__c,(Select id, LOE_hours__c, Type__c from Tasks where LOE_hours__c!=null) from SC_SI_Service_Incident__c where id =: siIds];
            for(SC_SI_Service_Incident__c eachSI : siList){
                if(eachSI.Tasks.size()>0){
                    for(Task eachTask : eachSI.Tasks){
                        totalLoeHrs += eachTask.LOE_hours__c;
                    }
                }
                eachSI.Total_Incident_LOE_Hours__c=totalLoeHrs;
                eachSI.Validation_Override__c=true;
                siToUpt.add(eachSI);
            }
            
            if(!siToUpt.isEmpty()){
                update siToUpt;
            }
        }
    }
    
    // Method to call addCaseLoeRCA after delete for 'Total Incident LOE (Hours)' logic
    public static void onAfterDeleteRCA(List<Task> taskList)
    {
        addCaseLoeRCA(taskList); 
    }
    /*********** ESESP-3590: Method to Populate the 'Total LOE (Hours)' field on RCA.**********/
    public static void addCaseLoeRCA(List<Task> taskList) 
    {
        List<Case> caseToUpt = new List<Case>();
        List<Case> caseList = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        Decimal totalLoeHrs = 0;
        Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
        String caseObjPrefix = Schema.getGlobalDescribe().get('Case').getDescribe().getKeyPrefix();
        for(Task eachTask: taskList){
            // Check for afterDelete and afterUndelete
            if(eachTask.WhatId != null  && eachTask.RecordtypeId == rcaActivityId && String.valueOf(eachTask.WhatId).startsWith(caseObjPrefix))
                caseIds.add(eachTask.WhatId);
        }
        if(!caseIds.isEmpty()){
            caseList = [select id,Total_LOE_Hours_RCA__c,(Select id, LOE_hours__c, Type__c from Tasks where LOE_hours__c!=null) from Case where id IN: caseIds];
            for(Case cs : caseList){
                totalLoeHrs = 0;
                if(cs.Tasks.size()>0){
                    for(Task eachTask : cs.Tasks){
                        totalLoeHrs += eachTask.LOE_hours__c;
                    }
                }
                cs.Total_LOE_Hours_RCA__c=totalLoeHrs;
                cs.Validation_Override__c=true;
                caseToUpt.add(cs);
            }
            if(!caseToUpt.isEmpty()){
                update caseToUpt;
            }
        }
    }
    
    // changes by Vandhana for Elevate/Escalate on Account (ESESP-4359)
    public static void notifyAccountDLElevateTask(Map<Id,Task> mapElevateTask,map<Id,Id> mapTaskIdElevationId)
    {
        Set<Id> lstElevationID = new Set<Id>();
        Map<Id,Elevation__c> mapElevationRecords = new Map<Id,Elevation__c>();
        
        List<String> toAddresses = new List<String>();
        List<String> lstAccElevDL = new List<String>();
        
        Messaging.SingleEmailMessage mail;
        List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
        
        String errorMssg = '';
        String emailSubj = ''; String emailHTMLBody = ''; String plainTextBody = '';
        
        //EmailTemplate taskEmailTemp = [Select Id,Subject,Body,HtmlValue from EmailTemplate where DeveloperName = 'SC_Elevation_Task_New_VF' LIMIT 1];
        String taskEmailTemp = [Select Value_Text__c from SC_Utility__mdt where DeveloperName = 'SC_Elevation_Task_New_VF_TemplateId'].Value_Text__c; 
        
        
        if(!mapTaskIdElevationId.isEmpty())
        {
            mapElevationRecords =  new Map<Id,Elevation__c>([SELECT Name,Account__r.Account_Elevation_Mailing_List__c,Account__r.Name FROM Elevation__c WHERE ID IN :mapTaskIdElevationId.values()]);
        }
        
        for(Id taskRecId : mapElevateTask.keyset())
        {
            Task t = new Task();
            toAddresses = new List<String>();   
            
            if(String.isNotBlank(mapElevationRecords.get(mapTaskIdElevationId.get(taskRecId)).Account__r.Account_Elevation_Mailing_List__c))
            {
                mail = new Messaging.SingleEmailMessage();
                mail = Messaging.renderStoredEmailTemplate(taskEmailTemp, mapElevateTask.get(taskRecId).CreatedById,taskRecId);
                
                lstAccElevDL = new List<String>();
                String accDL = mapElevationRecords.get(mapTaskIdElevationId.get(taskRecId)).Account__r.Account_Elevation_Mailing_List__c;
                //accDL = accDL.replace('\r','\n').replaceAll('[\n;]',',');
                toAddresses.addAll(accDL.split(','));   
                
                emailSubj = mail.getSubject().replace('<ElevationName>',mapElevationRecords.get(mapTaskIdElevationId.get(taskRecId)).Name).replace('<AccountName>',mapElevationRecords.get(mapTaskIdElevationId.get(taskRecId)).Account__r.Name);
                emailHTMLBody = mail.getHtmlBody().replace('{AssignedTo}',UserInfo.getName());
                plainTextBody = mail.getPlainTextBody().replace('{AssignedTo}',UserInfo.getName());
                
                mail.setTargetObjectId(mapElevateTask.get(taskRecId).CreatedById);
                mail.setSaveAsActivity(false);
                mail.setToAddresses(toAddresses);
                mail.setSubject(emailSubj);
                mail.setHtmlBody(emailHTMLBody);
                mail.setPlainTextBody(plainTextBody);
                lstMails.add(mail);
            }
        }
        
        if(!lstMails.isEmpty())
        {
            System.debug('lstMails : ' + lstMails);
            List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(lstMails);
            
            for(Messaging.SendEmailResult result : sendEmailResults) 
            {
                if(!result.IsSuccess())
                {
                    System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                    System.debug('Status code: ' + statusCode);
                    System.debug('Error msg: ' + result.getErrors()[0].getMessage());
                    
                    errorMssg = 'Status code: ' + statusCode + '\nError msg: '+ result.getErrors()[0].getMessage() + '\n';
                    
                    Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                    singleEmail.setSubject('New Elevation Task Failure : SC_TaskTriggerHandler');
                    singleEmail.setplainTextBody(errorMssg);
                    singleEmail.setToAddresses(new String[] {'sc-dev@akamai.com'});
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {singleEmail});
                }
            }
        }
    }
    
    //Changes for ESESP-6444
    public static void updateTicketPushTask(List<Task> taskList)
    {
        /*for(Task ts:[ SELECT Id, Type__c,Subject,WhatId,CreatedDate FROM Task WHERE What.Type = 'Case' AND what.recordtype.name = 'Managed Security' AND Subject='Jarvis Comment' AND Type__c='Web Update' AND Id IN :Trigger.new])
        {caseId.add(ts.whatId);}*/
        List<Id> caseId=new List<Id>();
        for(Task ts:taskList)
        {
            System.debug('the Task..s case Type is: '+ts.What.Type);
            System.debug('the Task..s case Record Type is: '+ts.what.recordtype.name);
            if(/*ts.What.Type=='Case' && ts.what.recordtype.name == 'Managed Security' &&*/ ts.Subject=='Jarvis Comment' && ts.Type__c=='Web Update' && ((String)ts.WhatId).startsWith('500'))
            {
                caseId.add(ts.whatId);
            }
        }
        List<Task> updateTask = new List<Task>();
        for(Task ts:[Select Id,Type__c,Status,WhatId,CreatedDate from Task where /*status = 'Deferred'*/ status NOT IN ('Completed','Completed Important') and (Type__c='Ticket Push 24h' or Type__c='Ticket Push 72h') and WhatId=:caseId and what.recordtype.name ='Managed Security'])
        {
            if(ts.Type__c=='Ticket Push 24h' || ts.Type__c=='Ticket Push 72h')
            {
                 ts.Status='Completed';
                 updateTask.add(ts);
            }                                            
        }
        if(updateTask.size()>0)
        {
            update updateTask;
        }
    }
    
    public static void handleTicketPushTask(List<Task> taskList){
        List<Id> caseId = new List<Id>();
        List<Id> msClosedCase = new List<Id>();
        List<Id> msCaseMissingMandateFields = new List<Id>();
        List<Id> msCaseWithOpenTicketPushTask = new List<Id>();
        for(Task ts:taskList)
        {
            if((ts.Status!='Completed' && ts.Status!='Completed Important') && (ts.Type__c=='Ticket Push 24h' || ts.Type__c == 'Ticket Push 72h') && ((String)ts.WhatId).startsWith('500'))
            {
                caseId.add(ts.WhatId);
            }
        }
        if(caseId.size()>0)
        {
            for(Case c:[Select Id,isClosed,Solution_Summary__c, Policy_Domain__c,Case_Product__c  from Case where Id=:caseId AND RecordType.DeveloperName ='Managed_Security' /*AND isClosed=true*/])
            {
                if(c.isClosed==true)
                {
                    msClosedCase.add(c.Id);
                }
                else if(c.Solution_Summary__c==null ||  c.Policy_Domain__c==null || c.Case_Product__c==null)
                {
                    msCaseMissingMandateFields.add(c.Id);
                }
                
            }
        }
        
        if(msClosedCase.size()>0)
        {
            for(Task tsk:taskList){
            if(msClosedCase.contains(tsk.whatId)){
                  tsk.addError('Can not create ticket push task on a closed managed security case');
            	}
        	}
        }
        if(msCaseMissingMandateFields.size()>0)
        {
            for(Task tsk:taskList){
            if(msCaseMissingMandateFields.contains(tsk.whatId)){
                  tsk.addError('All the mandatory fields are not filled in');
            	}
        	}
        }
        else
        {
            for(Task ts : [Select Id, Type__c, Status, WhatId from Task where WhatId =: caseId and status NOT IN ('Completed','Completed Important') AND (Type__c = 'Ticket Push 24h' OR Type__c = 'Ticket Push 72h')]){
                msCaseWithOpenTicketPushTask.add(ts.whatId);
            }
            
            for(Task tsk:taskList)
            {
               if(msCaseWithOpenTicketPushTask.contains(tsk.whatId)){
                 tsk.addError('An open 24h/72h Push Task already exists');
                 //throw new TicketPushException('An open 24h/72h Push Task already exists');
                 //tsk.addError(new TicketPushException('An open 24h/72h Push Task already exists'));
            	}
        	} 
        }
    
    
    }   
    //End of changes
}