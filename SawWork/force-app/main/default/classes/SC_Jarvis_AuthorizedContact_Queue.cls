/*
Author          : Sharath Prasanna
Description     : Authorized Contact queue

Date                    Developer             		JIRA #                      Description                                                       
-------------------------------------------------------
-----------------------------------------------------------
25 July 2021				Authors				 	    					  Initial Development
------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_Jarvis_AuthorizedContact_Queue implements Finalizer, Queueable, Database.AllowsCallouts 
{
    public Boolean isProvision;
    public List<String> authorizedContactGroups;
    public List<string> authorizedContactIds = new List<string>();
    public SC_Jarvis_AuthorizedContact_Queue() 
    {
        isProvision = false;
        authorizedContactGroups = new List<String>();

    }
    public void execute(QueueableContext context) 
    {
        System.debug('QueueableContext: ' + authorizedContactGroups);
        if(authorizedContactGroups.size() > 0)
        {
            if(isProvision)
            {
                SC_Jarvis_CoreSecurityController.addContactToPublicGroups(authorizedContactGroups);
            }
            else 
            {
                SC_Jarvis_CoreSecurityController.removeContactFromPublicGroups(authorizedContactGroups);
            }
            SC_Jarvis_AuthorizedContact_Queue finalizerQueue = new SC_Jarvis_AuthorizedContact_Queue();
            finalizerQueue.isProvision = isProvision;
            finalizerQueue.authorizedContactGroups = authorizedContactGroups;
            if(!isProvision)
            {
                finalizerQueue.authorizedContactIds = authorizedContactIds;
            }
            System.attachFinalizer(finalizerQueue);        

        }
    }

    public void execute(FinalizerContext ctx) 
    {
        System.debug('FinalizerContext: ' + authorizedContactGroups);
        Set<String> contactIds = new Set<String>();
        String contactId;
        List<Jarvis_Contact_ACC_Permission__c> permissions = new List<Jarvis_Contact_ACC_Permission__c>();

        if(authorizedContactGroups.size() > 0 )
        {
            for(String groupName: authorizedContactGroups)
            {
                contactId = groupName.split('-')[0];
                contactIds.add(contactId);
            }
            if(contactIds.size() > 0)
            {
                if(!isProvision)
                {
                    Set<String>states = new Set<String>{'Provisioned','Active'};
                    String currentContactId;
                    for(AggregateResult groupedResult :[select count(id),Contact_Name__c contactId from Authorized_Contact__c where 
                    (not Id in :authorizedContactIds) and Policy_Domain__r.Policy_Domain_State__c in :states 
                    and Contact_Name__c in :contactIds group by Contact_Name__c])
                    {
                        currentContactId = String.valueOf(groupedResult.get('contactId')); 
                        if(contactIds.contains(currentContactId))
                        {
                            contactIds.remove(currentContactId);
                        }                    
                    }            
                }
                String permissionQuery = 'Select Id, Authorized_Contact__c from Jarvis_Contact_ACC_Permission__c where contact__c in :contactIds';
                permissionQuery += isProvision? ' and Authorized_Contact__c = false' : ' and Authorized_Contact__c = true';
                for(Jarvis_Contact_ACC_Permission__c record: Database.query(permissionQuery))
                {
                    record.Authorized_Contact__c = isProvision? true : false;
                    permissions.add(record);
                }
                if(permissions.size() > 0)
                {
                    Database.update(permissions,false);
                }
            }
                      
        }
    }

}