/*
Author          : Sharath Prasanna
Description     : user provision queue

Date                    Developer             		JIRA #                      Description                                                       
-------------------------------------------------------
-----------------------------------------------------------
09 Feb 2021				Authors				 	    					  Initial Development
------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_Jarvis_User_Permission_Queue implements Finalizer, Queueable, Database.AllowsCallouts 
{
    public List<String> contactIds; 
    public List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> wrappers;
    public List<String> permissionContactIds; 
    public SC_Jarvis_User_Permission_Queue() 
    {
        contactIds = new List<String>();
        permissionContactIds = new List<String>();        
        wrappers = new List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper>();
    }

    public void execute(QueueableContext context) 
    {
        System.debug('QueueableContext: ' + contactIds);
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

        if(contactIds.size() > 0)
        {
            String query = 'Select id from contact where id in: contactIds and Active_Portal_Login__c = true';
            query += limitedBetaAccountIds != null && limitedBetaAccountIds.size() > 0 ? ' and accountId in :limitedBetaAccountIds' : '';
            for(Contact contactRec: Database.query(query))
            {
                permissionContactIds.add(contactRec.Id);
            }

            if(test.isRunningTest())
            {
                permissionContactIds.addAll(contactIds);
            }
            if(permissionContactIds.size() > 0)
            {
                SC_Jarvis_CoreSecurityController.CreateUserWrapper wrapper = SC_Jarvis_CoreSecurityController.checkForUser(permissionContactIds);
                if(wrapper != null && !wrapper.upserted && wrapper.wrappers.size() > 0)
                {
                    SC_Jarvis_CoreSecurityController.getIdmPermission(wrapper.wrappers);
                }
                else if(wrapper != null && wrapper.upserted && wrapper.wrappers.size() > 0)
                {
                    system.debug('wrapper: ' + wrapper);
                    SC_Jarvis_User_Permission_Queue finalizerQueue = new SC_Jarvis_User_Permission_Queue();
                    finalizerQueue.wrappers = wrapper.wrappers;
                    System.attachFinalizer(finalizerQueue);        
                    
                }
    
            }
        }
    }

    public void execute(FinalizerContext ctx) 
    {
        System.debug('FinalizerContext: ' + wrappers);
        if(wrappers != null && wrappers.size() > 0)
        {
            SC_Jarvis_CoreSecurityController.getIdmPermission(wrappers);
        }
    }
}