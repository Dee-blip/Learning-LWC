/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for bulk upload of already existing data for S2S
    Created Date : 07/22/2013
    ======================================================================== */
global class CreateRecordsBatch implements Database.Batchable<sObject>
{
   global final String objName;
   global final String parentName;

   //constructor used for passing the parameters for creating the query
   global CreateRecordsBatch(String objectName, String parentFieldName){
             objName=objectName;
             parentName=parentFieldName; 
   }
   
   //start method that creates the dynamic query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {       
        string query = 'select Id,ConnectionReceivedId ';
        
        //add the parent id field if the object has a parent
        if(parentName !=null && parentName != '')
            query = query + ', ' + parentName ;
        query = query + ' from ' + objName + ' where ConnectionReceivedId = null';
        if(system.Test.isRunningTest())
            query += ' ORDER BY CREATEDDATE DESC LIMIT 200 ';
        else if(parentName !=null && parentName != '')
            query += ' ORDER BY ' + parentName; 
        return Database.getQueryLocator(query);
    }

    //call the S2S sync class to create the sync records 
    global void execute(Database.BatchableContext bc,List<sObject> lstObjects)
    {        
        system.debug('*******************Execute of Batch Apex***********');
        ExternalSharingHelper.createS2Ssync(parentName, lstObjects,null);
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        system.debug('****Finished*****');
    }
}