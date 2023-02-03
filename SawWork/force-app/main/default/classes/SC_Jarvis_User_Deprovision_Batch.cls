public without sharing class SC_Jarvis_User_Deprovision_Batch implements Database.Batchable<sObject>, Database.stateful
{
    public List<String> contactIds;
    string query;
    Boolean isMonthlyBatch;
    public SC_Jarvis_User_Deprovision_Batch() 
    {
        contactIds = new List<String>();
        isMonthlyBatch = false;
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        query = 'Select Id,Contact__c, User__c from Jarvis_Contact_ACC_Permission__c where Active__c = true and User__r.isActive = true'; 
        if(contactIds != null && contactIds.size() > 0)
        {
            query += ' and Contact__c in :contactIds';            
        }
        else
        {
            isMonthlyBatch = true;
            query += ' and (User__r.LastLoginDate < last_n_months:3 or (User__r.createddate < last_n_months:3 and User__r.LastLoginDate = null) )';
        }
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Jarvis_Contact_ACC_Permission__c> userList)
    {
        List<Id> userids= new List<Id>();
        for(Jarvis_Contact_ACC_Permission__c userRec: userList)
        {
            userids.add(userRec.User__c);
            if(isMonthlyBatch)
            {
                contactIds.add(userRec.Contact__c);
            }            
        }
        if(userids.size() > 0)
        {
            SC_Jarvis_CoreSecurityController.customerDeprovisionLogic(userids);                
        }

    }
    public void finish(Database.BatchableContext BC)
    {
        if(contactIds.size() > 0)
        {
            SC_Jarvis_Permission_Deprovision_Batch deprovisionBatch = new SC_Jarvis_Permission_Deprovision_Batch();
            deprovisionBatch.contactIds = contactIds;
            Database.executeBatch(deprovisionBatch,100);
        }
    }
}