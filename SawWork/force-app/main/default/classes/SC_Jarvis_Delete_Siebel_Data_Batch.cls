public without sharing class SC_Jarvis_Delete_Siebel_Data_Batch implements Database.Batchable<sObject>,Database.stateful
{    
    string query;
    public String objectType;
    Integer totalCount;
    public SC_Jarvis_Delete_Siebel_Data_Batch() 
    {
        totalCount = 0;
    }
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        query = 'Select Id from ' +  objectType + ' where Marked_For_Deletion__c = true';
        
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Sobject> objectList)
    {
        if(objectList != null && objectList.size() > 0)
        {
            totalCount += objectList.size();
            delete objectList;
        }

    }
    public void finish(Database.BatchableContext BC)
    {
        SC_Jarvis_utility.sendErrorMails('Jarvis Delete Batch','Deleted ' +  totalCount + ' records from ' + objectType,'');
    }    

}