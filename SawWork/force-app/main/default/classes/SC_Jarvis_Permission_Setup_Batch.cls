public without sharing class SC_Jarvis_Permission_Setup_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts
{
    public List<String> contactIds; 
    string query;

    public SC_Jarvis_Permission_Setup_Batch() 
    {
        contactIds = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        system.debug('In PERmission Batch');
        query = 'Select Id,contactId,contact.AKAM_Contact_Id__c,contact.Login__c from User where isactive = true';
        //contactId,userRec.AKAM_User_Id__c,userRec.Id,idToContact.get(userRec.AKAM_User_Id__c).Jarvis_Login__c
        query += contactIds != null && contactIds.size() > 0 ? ' and contactId in :contactIds' : ' limit 1';
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<User> userList)
    {
        system.debug('In PERmission Batch: userList' + userList);
        List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> wrappers = new List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper>();
        for(User userRec: userList)
        {
            if(!String.isBlank(userRec.contact.Login__c))
            {
                wrappers.add(new SC_Jarvis_CoreSecurityController.ContactPermissionWrapper(userRec.contactId,userRec.Contact.AKAM_Contact_Id__c,userRec.Id,userRec.contact.Login__c));                
            }
            
        }
        system.debug('In PERmission Batch: wrappers' + wrappers);
        if(wrappers.size() > 0)
        {
            system.debug('In PERmission Batch: wrappers' + wrappers);
            SC_Jarvis_CoreSecurityController.getIdmPermission(wrappers);
        }
        
    }

    public void finish(Database.BatchableContext BC)
    {

    }    
 
}