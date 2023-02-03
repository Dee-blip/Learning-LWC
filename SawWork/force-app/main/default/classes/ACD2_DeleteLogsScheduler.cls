/***************************************************************************
 * Name             : ACD2_DeleteLogsScheduler
 * Created By       : Vamsee S
 * Created Date     : 30-Sept-2020
 * Purpose          : Scheduler to delete the ACD Webservice Logs
 * Test Class		: ACD2_Webservices_Test
 
 Last Modified BY   Last Modified Date  Purpose
 ----------------   ------------------  ---------
 Vamsee		    	30-Sept-2020			Initial Development
 ****************************************************************************/

global class ACD2_DeleteLogsScheduler implements Schedulable{
    
    global void execute(SchedulableContext SC) {
        //Get the Number of days from the custom metadata
        Integer no_Of_Days = Integer.valueOf([SELECT Num_Value__c FROM ACD_Utility__mdt where DeveloperName = 'Delete_Log_Days' LIMIT 1].Num_Value__c);
        Datetime ConsiderationDate = System.now().addDays(-no_Of_Days);

		//Query
		String query = 'SELECT Id FROM ACD2_Logs__c ';
        
        //Query for Test Class
        if(!test.isRunningTest())
            query += 'WHERE Createddate <  ' + ConsiderationDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        System.debug('--Query--'+query);
        //Call the Batch Class
        SC_DeleteSobject batchApex = new SC_DeleteSobject(query, 'Delete_ACD_Logs'); 
        Database.executeBatch(batchApex,2000);
        
    }
    
    

}