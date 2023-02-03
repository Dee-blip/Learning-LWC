public without sharing class SC_Jarvis_User_Setup_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.stateful
{
    public List<String> contactIds; 
    public List<String> permissionContactIds; 

    string query;
    public SC_Jarvis_User_Setup_Batch() 
    {
        contactIds = new List<String>();
        permissionContactIds = new List<String>();        
    }


    public Database.QueryLocator start(Database.BatchableContext BC)
    {        
        Set<String> limitedBetaAccountIds;                                               
        for(SC_Utility__mdt eachRec : [SELECT DeveloperName,Value_Text__c from SC_Utility__mdt
        where DeveloperName IN ('JarvisLimitedBetaAccountSFId','JarvisLimitedBetaAccountSFId2')])
        {
            if(eachRec.Value_Text__c != null && eachRec.Value_Text__c != 'ALL')
            {                    
                if(limitedBetaAccountIds == null)
                {
                    limitedBetaAccountIds = new Set<String>();
                }
                limitedBetaAccountIds.addAll(eachRec.Value_Text__c.split(','));
            }
        }

        query = 'Select Id from Contact ';

        if(contactIds != null && contactIds.size() > 0)
        {
            query += ' where ';
            query += limitedBetaAccountIds != null && limitedBetaAccountIds.size() > 0?
        ' accountId in :limitedBetaAccountIds and ' : '';
            query += ' Id in :contactIds' ; 
        }
        
        if(test.isRunningTest() || contactIds == null || contactIds.size() == 0)
        {
            query = 'Select Id from Contact limit 1';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> contactList)
    {
        system.debug('In Setup batch');
        List<Id> currentContactIds = new List<Id>();
        for(COntact contactRec: contactList)
        {
            permissionContactIds.add(contactRec.Id);
            currentContactIds.add(contactRec.Id);
        }
        SC_Jarvis_CoreSecurityController.checkForUser(currentContactIds);
        system.debug('end of  Setup batch');
    }

    public void finish(Database.BatchableContext BC)
    {
        system.debug('Calling Permission Batch');
        SC_Jarvis_Permission_Setup_Batch permissionBatch = new SC_Jarvis_Permission_Setup_Batch();
        permissionBatch.contactIds = permissionContactIds;
        Database.executeBatch(permissionBatch,20);
        system.debug('Called Permission Batch');
    }    
}