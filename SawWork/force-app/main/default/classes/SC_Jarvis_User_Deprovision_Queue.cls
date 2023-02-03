public with sharing class SC_Jarvis_User_Deprovision_Queue implements Finalizer, Queueable
{
    public List<String> contactIds; 
    public SC_Jarvis_User_Deprovision_Queue() 
    {
        contactIds = new List<String>();
    }
    public void execute(QueueableContext context) 
    {
        if(contactIds.size() > 0)
        {
            List<Id> userids= new List<Id>();
            SC_CommunityUtility__mdt utilRec = [Select Case_Field_API__c from SC_CommunityUtility__mdt where DeveloperName = 'DeprovisionLicenses' limit 1];
            List<String>licenses = utilRec.Case_Field_API__c != null ? utilRec.Case_Field_API__c.split(',') : new List<String>{'Customer Community Plus Login'};
                
            for(User userRec: [Select Id from User where contactId in :contactIds and isactive = true and 
            Profile.UserLicense.Name in :licenses])
            {
                userids.add(userRec.Id);
            }
            if(userids.size() > 0)
            {
                SC_Jarvis_CoreSecurityController.customerDeprovisionLogic(userids);                
            }
            SC_Jarvis_User_Deprovision_Queue finalizerQueue = new SC_Jarvis_User_Deprovision_Queue();
            finalizerQueue.contactIds = contactIds;
            System.attachFinalizer(finalizerQueue);        

            
        }
    }
    public void execute(FinalizerContext ctx) 
    {
        if(contactIds.size() > 0)
        {
            List<Jarvis_Contact_ACC_Permission__c> permissions = new List<Jarvis_Contact_ACC_Permission__c>();
            for(Jarvis_Contact_ACC_Permission__c contactPermission: [Select Id,Active__c from Jarvis_Contact_ACC_Permission__c
            where contact__c in :contactIds and Active__c = true])
            {
                contactPermission.Active__c = false;
                permissions.add(contactPermission);
            }
            if(permissions.size() > 0)
            {
                Database.update(permissions,false);
            }
        }
    }
}