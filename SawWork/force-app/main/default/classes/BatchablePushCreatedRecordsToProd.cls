/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for picking up all records from Partner connection 
                 Object and force S2S data syncs for the same when the production
                 org is back up again
    Created Date : 19/03/2014
    ======================================================================== */
global class BatchablePushCreatedRecordsToProd implements Database.Batchable<sObject>, Database.Stateful
{  
   global integer ProcessedRecords=0;
   global integer FailedRecords=0;
 
   //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
       string query = 'select Id, LocalRecordId__c, ParentRecordId__c, RelatedRecords__c from Partner_Connection__c where Synced__c = false and Operation__c = \'Insert\' order by CreatedDate asc';
       if(system.Test.isRunningTest())
            query += ' LIMIT 200';
       return Database.getQueryLocator(query);
    }

    //start the S2S sync for objects 
    global void execute(Database.BatchableContext bc,List<Partner_Connection__c> lstObjects)
    {        
        //Fetch the connection Id
        //Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        Id networkId = ConnectionHelper.getConnectionId(); 

        //Create partner record connections and start the S2S sync
        List<PartnerNetworkRecordConnection> connections =  new  List<PartnerNetworkRecordConnection>(); 
        Map<Id,Partner_Connection__c> LocalpartnerMap =  new map<Id,Partner_Connection__c>();  
              
        for (Partner_Connection__c partner : lstObjects) {   
            Id localId = (Id) partner.LocalRecordId__c;
            Schema.sobjectType objectType = localId.getSObjectType();
            PartnerNetworkRecordConnection newConnection = 
              new PartnerNetworkRecordConnection( 
                  ConnectionId = networkId, 
                  LocalRecordId = partner.LocalRecordId__c, 
                  RelatedRecords = partner.RelatedRecords__c,
                  SendEmails = false);
                      
                 if(partner.ParentRecordId__c != null && partner.ParentRecordId__c != '')
                     newConnection.ParentRecordId = partner.ParentRecordId__c;     
                      
                 if(ExternalSharingHelper.taskEnabledObjects.contains(objectType)){
                     newConnection.SendClosedTasks = true;
                     newConnection.SendOpenTasks = true;
                 }
                 connections.add(newConnection);  
             partner.Synced__c = true; 
			 partner.Sync_Error__c = '';
             //maintain a map of local id and the partner record to update the errors if any during sync
             LocalpartnerMap.put(localId, partner);       
        } 
        
        Database.SaveResult[] result = database.insert(connections,false);
        
        //Extract the number of processed and failed records             
        for(Integer i=0;i<connections.size();i++)
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
                Id recordId = connections.get(i).LocalRecordId;
                
                //update the error on the partner record
                Partner_Connection__c partner = LocalpartnerMap.get(recordId);
                partner.Sync_Error__c = error.getMessage();
                FailedRecords ++;
            }
        }
        
        //Update the synced flag for the picked records 
        database.update(lstObjects,false);  
    }
    
    //Submit the job for picking up the updated records and force updates
    global void finish(Database.BatchableContext BC)
    {
        BatchablePushUpdatedRecordsToProd updateJob = new BatchablePushUpdatedRecordsToProd();
        updateJob.ProcessedRecords = ProcessedRecords;
        updateJob.FailedRecords = FailedRecords;
        //Submit the second job
        Database.executeBatch(updateJob);
    }
}