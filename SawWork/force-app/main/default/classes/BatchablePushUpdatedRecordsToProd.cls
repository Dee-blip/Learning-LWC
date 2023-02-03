/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for picking up all updated records from Partner connection 
                 Object and force S2S data syncs for the same when the production
                 org is back up again
    Created Date : 19/03/2014
    ======================================================================== */
global class BatchablePushUpdatedRecordsToProd implements Database.Batchable<sObject>, Database.Stateful
{  
   global integer ProcessedRecords=0;
   global integer FailedRecords=0;
   //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
       string query = 'select Id, LocalRecordId__c, ParentRecordId__c, RelatedRecords__c from Partner_Connection__c where Synced__c = false and Operation__c = \'Update\' order by CreatedDate asc';
       if(system.Test.isRunningTest())
            query += ' LIMIT 200';
       return Database.getQueryLocator(query);
    }

    //update the records to force updates to the production org
    global void execute(Database.BatchableContext bc,List<Partner_Connection__c> lstPartner)
    {           
        Map<string,list<sObject>> mpIds = new map<string,list<sObject>>();
        Map<Id,Partner_Connection__c> LocalpartnerMap =  new map<Id,Partner_Connection__c>();
        
        string objectName;
        list<sObject> lstRecords;
        // loop through all the record connections and segregate the record ids for each object
        for (Partner_Connection__c objRecord : lstPartner)
        {
            Id localId = (Id)objRecord.LocalRecordId__c;
            objectName = localId.getSObjectType().getDescribe().getName();
            if(mpIds.containsKey(objectName))
            {
                 lstRecords = mpIds.get(objectName);
            }
            else
            {
                 lstRecords = new list<sObject>();
            }
            sObject record = localId.getSObjectType().newSObject(objRecord.LocalRecordId__c);
            lstRecords.add(record);
            mpIds.put(objectName, lstRecords);
            objRecord.Synced__c = true;
            //maintain a map of local id and the partner record to update the errors if any during sync
            LocalpartnerMap.put(localId, objRecord);
        }
        
        //update all records for each object
        for(list<sObject> lstObj: mpIds.values())
        {
            //Update the records and update the error on the Partner Record
            Database.SaveResult[] result = database.update(lstObj, false);
            
            //Extract the number of processed and failed records             
            for(Integer i=0;i<lstObj.size();i++)
            {
                if (result.get(i).isSuccess())
                {
                     ProcessedRecords++;
                }
                else if (!result.get(i).isSuccess())
                {
                    // DML operation failed
                    Database.Error error = result.get(i).getErrors().get(0);
                    
                    //get the id of the failed record
                    Id recordId = lstObj.get(i).Id;
                    
                    //update the error on the partner record
                    Partner_Connection__c partner = LocalpartnerMap.get(recordId);
                    partner.Sync_Error__c = error.getMessage();
                    FailedRecords ++;
                }
            }
        }
        
        //Update the synced flag and errors at the records
        database.update(LocalpartnerMap.values(),false);
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                  FROM AsyncApexJob WHERE Id = :BC.getJobId()];
                  
        // Send an email to the Apex job's submitter notifying of job completion. 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('DR Data Sync job has completed');
        mail.setPlainTextBody('The Apex job processed ' + ProcessedRecords + ' records successfully and there were '+ FailedRecords + ' failures. For detailed errors, please refer the individual records by navigating to the Partner Connection Tab.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }
}