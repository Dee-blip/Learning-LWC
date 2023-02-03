/*=====================================================================================================+
Class name          :   SC_CPS_RetryEmailBatch 
Author              :   Aditya
Created             :   25-June-2019
Purpose             :  	To resend the 5 and 15 days email notification for cases with record lock failure 
Test Class			:	SC_CPS_RetryEmailBatch_Test
+=====================================================================================================*/
Public class SC_CPS_RetryEmailBatch implements Database.Batchable<SObject>, Database.stateful 
{
    public string batchQuery = NULL;
    public string batchName = 'SC_CPS_RetryEmailBatch - ' + Datetime.now(); 
    List<Case> caseListForUpdate = new List<Case>();
    
    // Setting Error Message
    public string errorMessage =  'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        'Batch Class Name = SC_CPS_RetryEmailBatch\n' + 
        'Queueable Class Name = SC_CPS_RetryEmailQueueable\n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;    
    // Fetching Case Record Types
    static Id recordTypeIdWE = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Web Experience').getRecordTypeId();    
    /*......Query on Contract Header to fetch all Active Contracts.......*/
    static String DEFAULT_QUERY = null;    
    /*......Query for Test Class.......*/      
    static String TestClass_Query = null;    
    Date todayDate = System.now().date();    
    
    // Constructor of Batch Class
    public SC_CPS_RetryEmailBatch(){
        system.debug(batchName + ' ......started...... ');
    }  
    
    /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
    Public Database.QueryLocator start(Database.BatchableContext BC){
        
        system.debug(batchName + '......Inside start Method......');
        DEFAULT_QUERY = 'SELECT Id, CPSExpiration5Days__c, CPSExpiration15Days__c,CPSExpiration8Days__c,CPSExpiration1DayAfter__c,lastModifiedDate,Expiration_Date__c,CPSDaysBeforeExpiry__c,CPS_RetryNotificationforFailureDays__c FROM Case where' +
            ' Status != \''+ 'Closed'+ '\''+ ' and (CPSExpiration5Days__c = true OR CPSExpiration8Days__c = true OR CPSExpiration1DayAfter__c = true OR CPSExpiration15Days__c = true OR CPSDaysBeforeExpiry__c != null) '+
            'and RecordTypeId =:recordTypeIdWE';
        
        TestClass_Query =   DEFAULT_QUERY + ' limit 10'; 
        system.debug('--Query---'+DEFAULT_QUERY); 
        
        // If incoming request is from Test class, then run test class query otherwise run default query  
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : DEFAULT_QUERY;
        return Database.getQueryLocator(batchQuery);
        
    }
    
    /*@Method <This method gets executed acutomatically when the batch job is execution mode.>*/   
    Public void execute(Database.BatchableContext BC, list<SObject> scope){
        
        system.debug(batchName + '......Inside Execute Method......');
        string errHdr = ' ******* ';
        try{
            /*......Get all cases for which 5 or 15 days email notification failed......*/
            List<Case> allReturnCases = (Case[]) scope; 
            Set<Id> caseList15daysChecked = new Set<Id>();
            Set<Id> caseList5daysChecked = new Set<Id>();
            
            Set<Id> caseList30daysChecked = new Set<Id>();
            Set<Id> caseList12daysChecked = new Set<Id>();
            Set<Id> caseList8daysChecked = new Set<Id>();
            Set<Id> caseList7daysChecked = new Set<Id>();
            Set<Id> caseList3daysChecked = new Set<Id>();
            Set<Id> caseList2daysChecked = new Set<Id>();
            Set<Id> caseList1daysChecked = new Set<Id>();
            Set<Id> caseList1daysAfterExpiryChecked = new Set<Id>();
            for(Case c : allReturnCases){
                integer intDays =  (c.Expiration_Date__c).Date().daysBetween(todayDate);
                
                System.debug('intDays :: '+intDays);
                
                System.debug('Integer.valueOf(System.now()) :: '+System.now()+' ****** Integer.valueOf(c.Expiration_Date__c) :: '+c.Expiration_Date__c);
                
                /*Long dt1Long = System.now().getTime();
                Long dt2Long = c.Expiration_Date__c.getTime();
                Long milliseconds = dt2Long - dt1Long;
                Long seconds = milliseconds / 1000;
                Long minutes = seconds / 60;*/
                Integer hoursInBetween = Integer.valueOf(((((c.Expiration_Date__c.getTime() - System.now().getTime()) / 1000)/60))/60);//we get the hours in between the 2 datetimes - at 9:25 it will be 48 hours and at 12:15 it will be 48-3 = 45
                //here for the corner cases I have taken the buffer as 4 - batch runs every 3 hours + 1 hr extra
                
                System.debug('hoursInBetween :: '+hoursInBetween);
                
                if(c.CPSExpiration15Days__c && c.CPSExpiration5Days__c && (intDays == -5 || (hoursInBetween != null && hoursInBetween<=120 && hoursInBetween >= 116))){ //Here we have all cases where 5 and 15 both have not gone but the checkbox is true
                    caseList5daysChecked.add(c.Id);
                }
                if(c.CPSExpiration15Days__c && !c.CPSExpiration5Days__c && (intDays == -15 || (hoursInBetween != null && hoursInBetween<=360 && hoursInBetween >= 354))){ //Only 15 days has not gone
                    caseList15daysChecked.add(c.Id);
                }
                if(!c.CPSExpiration15Days__c && c.CPSExpiration5Days__c && (intDays == -5 || (hoursInBetween != null && hoursInBetween<=120 && hoursInBetween >= 116))){ //5 has not gone
                    caseList5daysChecked.add(c.Id);
                }  
                
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '30' && (intDays == -30 || (hoursInBetween != null && hoursInBetween<=720 && hoursInBetween >= 716))){//add null check
                    caseList30daysChecked.add(c.Id);
                }  
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '12' && (intDays == -12 || (hoursInBetween != null && hoursInBetween<=288 && hoursInBetween >= 284))){
                    caseList12daysChecked.add(c.Id);
                } 
                if(c.CPSExpiration8Days__c != null && c.CPSExpiration8Days__c && (intDays == -8 || (hoursInBetween != null && hoursInBetween<=192 && hoursInBetween >= 188))){
                    caseList8daysChecked.add(c.Id);
                }
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '7' && (intDays == -7 || (hoursInBetween != null && hoursInBetween<=168 && hoursInBetween >= 164))){
                    caseList7daysChecked.add(c.Id);
                }  
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '3' && (intDays == -3 || (hoursInBetween != null && hoursInBetween<=72 && hoursInBetween >= 68))){
                    caseList3daysChecked.add(c.Id);
                } 
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '2' && (intDays == -2 || (hoursInBetween != null && hoursInBetween<=48 && hoursInBetween >= 44))){
                    caseList2daysChecked.add(c.Id);
                }
                if(c.CPSDaysBeforeExpiry__c != null && c.CPSDaysBeforeExpiry__c == '1' && (intDays == -1 || (hoursInBetween != null && hoursInBetween<=24 && hoursInBetween >= 20))){
                    caseList1daysChecked.add(c.Id);
                } 
                if(c.CPSExpiration1DayAfter__c != null && c.CPSExpiration1DayAfter__c && (intDays == 1 || (hoursInBetween != null && hoursInBetween>=-24 && hoursInBetween <= -20))){
                    caseList1daysAfterExpiryChecked.add(c.Id);
                } 
            }
            system.debug('----caseList5daysChecked-----'+caseList5daysChecked);
            system.debug('----caseList15daysChecked-----'+caseList15daysChecked);
            // Fetching Cases which doesn't have activity with subject line 5 days or 15 days email notification
            List<Task> task5DaysList;
            if(caseList5daysChecked.size()>0){
                for(Task eachTask :[Select id, WhatId,Subject,createddate from task where WhatId IN :caseList5daysChecked and (Subject like '%: 5 days until expiration%')]){
                    caseList5daysChecked.remove(eachTask.WhatId);   
                }
            }
            
            if(caseList15daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList15daysChecked and (Subject like '%: 15 days until expiration%')]){
                    caseList15daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList30daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList30daysChecked and (Subject like '%: 30 days until expiration%')]){
                    caseList30daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList12daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList12daysChecked and (Subject like '%: 12 days until expiration%')]){
                    caseList12daysChecked.remove(eachTask.WhatId);
                }
            }
            
            //Here for 8 days we are not considering the status change as in the first place the status changed and that is why the boolean was set to true and yet the email did not go so we are
            //just firing the email from here
            if(caseList8daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList8daysChecked and (Subject like '%: 8 days until expiration%')]){
                    caseList8daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList7daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList7daysChecked and (Subject like '%: 7 days until expiration%')]){
                    caseList7daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList3daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList3daysChecked and (Subject like '%: 3 days until expiration%')]){
                    caseList3daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList2daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList2daysChecked and (Subject like '%: 2 days until expiration%')]){
                    caseList2daysChecked.remove(eachTask.WhatId);
                }
            }

            if(caseList1daysChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList1daysChecked and (Subject like '%: 1 days until expiration%')]){
                    caseList1daysChecked.remove(eachTask.WhatId);
                }
            }
            if(caseList1daysAfterExpiryChecked.size()>0){
                for(Task eachTask : [Select id, WhatId,createddate from task where WhatId IN :caseList1daysAfterExpiryChecked and (Subject like '%: Certificate Expired')]){
                    caseList1daysAfterExpiryChecked.remove(eachTask.WhatId);
                }
            }

            
            
            Case cnew;    
            for(Id eachCaseId : caseList15daysChecked){
                if(caseList5daysChecked.size()>0){
                    if(!caseList5daysChecked.contains(eachCaseId)){
                        cnew = new Case();
                        cnew.Id = eachCaseId;
                        cnew.CPS_RetryEmailNotification15Days__c = true;
                        cnew.validation_override__c = true;
                        caseListForUpdate.add(cnew);
                    }
                }
                else{
                    cnew = new Case();
                    cnew.Id = eachCaseId;
                    cnew.CPS_RetryEmailNotification15Days__c = true;
                    cnew.validation_override__c = true;
                    caseListForUpdate.add(cnew);
                }
            }
            for(Id eachCaseId : caseList5daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryEmailNotification5Days__c = true;
                caseListForUpdate.add(cnew); 
            }

            for(Id eachCaseId : caseList30daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '30';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList12daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '12';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList8daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '8';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList7daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '7';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList3daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '3';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList2daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '2';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList1daysChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '1';
                caseListForUpdate.add(cnew); 
            }
            for(Id eachCaseId : caseList1daysAfterExpiryChecked){
                cnew = new Case();
                cnew.Id = eachCaseId;
                cnew.validation_override__c = true;
                cnew.CPS_RetryNotificationforFailureDays__c = '1 Day After Expiry';
                caseListForUpdate.add(cnew); 
            }
            system.debug('----caseListForUpdate-----'+caseListForUpdate);  
        }
        catch(Exception e)
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
            
            System.debug('errorMessage ::'+errorMessage);
        }  
    }
    
    
    /*@Method <This method gets executed acutomatically when the batch job is finised.>*/    
    Public void finish(Database.BatchableContext BC){       
        System.debug('......Start of Finish Method......'+system.now()+'::'+caseListForUpdate);
        
        if(caseListForUpdate.size()>0)
            ID jobID = System.enqueueJob(new SC_CPS_RetryEmailQueueable(caseListForUpdate));
        string setEmailSub = 'Exception: In Batch Job - SC_CPS_RetryEmailBatch. # Of Errors : '+noOfErrors;
        
        // Calling Send Email Method for Errors
        if(noOfErrors > 0){
            Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
            singleEmail.setSubject('Cases with CPS email failure: SC_CPS_RetryEmailBatch');
            singleEmail.setplainTextBody(errorMessage);
            singleEmail.setToAddresses(new String[] {'sc-dev@akamai.com'});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {singleEmail});
        }     
    }      
}