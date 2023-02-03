public without sharing class SC_Jarvis_Permission_Deprovision_Batch implements Database.Batchable<sObject>,Database.stateful
{
    public List<String> contactIds;
    string query;

    
    public SC_Jarvis_Permission_Deprovision_Batch() 
    {
        contactIds = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        query = 'Select Id,Active__c from Jarvis_Contact_ACC_Permission__c where Active__c = true';
        query += contactIds != null && contactIds.size() > 0 ? ' and contact__c in :contactIds' : ' limit 1';
        
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Jarvis_Contact_ACC_Permission__c> permissionList)
    {
        List<Jarvis_Contact_ACC_Permission__c> permissions = new List<Jarvis_Contact_ACC_Permission__c>();
        for(Jarvis_Contact_ACC_Permission__c contactPermission: permissionList)
        {
            contactPermission.Active__c = false;
            permissions.add(contactPermission);
        }
        if(permissions.size() > 0)
        {
            Database.update(permissions,false);
        }

    }
    public void finish(Database.BatchableContext BC)
    {

    }    
}