/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for deleting the records that have been deleted from the primary organization
    Created Date : 06/08/2013
    ======================================================================== */
global class BatchableDeleteRecords implements Database.Batchable<sObject>
{  
    //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
        AggregateResult result = [Select max(CompletedDate) jobDate from AsyncApexJob where 
                        ApexClass.Name = 'BatchableDeleteRecords'  and Status = 'Completed'];
        DateTime LastJobRunDate;
        if(result != null && result.get('jobDate') != null)
        {
            LastJobRunDate = (Datetime)result.get('jobDate');
        }
       string query = 'select Id, LocalRecordId from PartnerNetworkRecordConnection where PartnerRecordId = null and status = \'Deleted\'';
       if(LastJobRunDate != null)
           query += ' and EndDate > :LastJobRunDate';
       if(system.Test.isRunningTest())
            query += ' LIMIT 200';
       return Database.getQueryLocator(query);
    }

    //call the delete account method 
    global void execute(Database.BatchableContext bc,List<PartnerNetworkRecordConnection> lstObjects)
    {        
        system.debug('*******************Execute of Batch Apex***********');
        ExternalSharingHelper.DeletesObjects(lstObjects);
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        system.debug('****Finished*****');
    }
}