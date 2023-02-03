/*
Author          : Sharath P
Description     : Controller for Acc Contact Permission


Date                    Developer                   JIRA #                      Description                                                       
-------------------------------------------------------------------------------------------------------------------
15 Mar 2021             Authors                     ESESP-5085                Initial Development
-------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_Jarvis_Contact_ACC_Permission_Handler extends ApexTriggerHandlerAbstractClass 
{
    public static Boolean recursionCheck = false;
    public class AccountContactPermissionWrapper
    {
        public String accountId;
        public String contactId;
        public String parentId;
        public String contactSalesforceId;
        public ContractPermissionWrapper[] authGrants;
    }
    public class ContractPermissionWrapper
    {
        public String contractId;
        public String[] scopes;
    }
    public SC_Jarvis_Contact_ACC_Permission_Handler() 
    {

    }

    public override void beforeInsertBeforeUpdateTrigger()
    {    
        //If the user lookup is null, update the field on the Acc permission record
        if(!recursionCheck)
        {
            Map<String,String> contactToUser = new Map<String,String>();
            List<Jarvis_Contact_ACC_Permission__c> contactRecs = (List<Jarvis_Contact_ACC_Permission__c>)newList;
            Set<String> contactIds = new Set<String>();
            Set<String> forceSyncIds = new Set<String>();
            //List of contact Ids to set Case management permission
            Set<String> caseManagementContactIds = new Set<String>();

            Set<Jarvis_Contact_ACC_Permission__c> forceSyncRecords = new Set<Jarvis_Contact_ACC_Permission__c>();
            Map<String,Map<String,String>> contactPermissionMap;
            for(Jarvis_Contact_ACC_Permission__c record: contactRecs)
            {
                if(record.User__c == null)
                {
                    contactToUser.put(record.Akam_Contact_ACC_Permission_Id__c,'');
                }
                if(Trigger.isUpdate && record.Force_Sync__c )
                {
                    record.Force_Sync__c = false;
                    record.Response__c = null;
                    forceSyncRecords.add(record);
                    forceSyncIds.add(record.Id);
                    contactIds.add(record.contact__c);
                }
                else if(Trigger.isInsert || 
                        (Trigger.isUpdate && record.Active__c && !((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(record.Id).Active__c))
                {
                    contactIds.add(record.contact__c);    
                }
                
                if(Trigger.isUpdate && record.Active__c && record.Response__c != null && 
                record.Response__c == ((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(record.Id).Response__c)
                {
                    caseManagementContactIds.add(record.Akam_Contact_ACC_Permission_Id__c);
                }
            }
            if(caseManagementContactIds.size() > 0)
            {
                contactPermissionMap = SC_Jarvis_utility.getCaseManagementContacts(caseManagementContactIds);
            }

            if(contactIds.size() > 0)
            {
                Set<String>states = new Set<String>{'Active'};
                String currentContactId;
                system.debug('contactIds: ' + contactIds);
                for(AggregateResult groupedResult :[select count(id),Contact_Name__c contactId from Authorized_Contact__c where 
                Policy_Domain__r.Policy_Domain_State__c in :states 
                and Contact_Name__c in :contactIds group by Contact_Name__c])
                {
                    //system.debug('groupedResult: ' + groupedResult);
                    currentContactId = String.valueOf(groupedResult.get('contactId')); 
                    if(contactIds.contains(currentContactId))
                    {
                        contactIds.remove(currentContactId);
                    }                    
                }            
                //system.debug('contactIds: ' + contactIds);
            }
            if(contactToUser.size() > 0)
            {
                for(User userRec : [Select Id, FederationIdentifier from User where 
                FederationIdentifier in :contactToUser.keySet() and isactive = true])
                {
                    contactToUser.put(userRec.FederationIdentifier,userRec.Id);
                }
            }
            for(Jarvis_Contact_ACC_Permission__c record: contactRecs)
            {
                if(record.User__c == null && contactToUser.get(record.Akam_Contact_ACC_Permission_Id__c) != '')
                {
                    record.User__c = contactToUser.get(record.Akam_Contact_ACC_Permission_Id__c);
                }
                if(record.Response__c == null || record.Response__c.length()  < 10)
                {
                    record.Akamai_Case_Permission__c = 'None';
                    record.ATT_Case_Permission__c = 'None';
                }
                if(caseManagementContactIds != null && caseManagementContactIds.contains(record.Akam_Contact_ACC_Permission_Id__c))
                {
                    record.Akamai_Case_Permission__c = contactPermissionMap == null || 
                    !contactPermissionMap.containsKey(record.Akam_Contact_ACC_Permission_Id__c) || 
                    contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c) == null || 
                    !contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c).containsKey('akamai') ? 'None' : 
                    contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c).get('akamai');


                    record.ATT_Case_Permission__c = contactPermissionMap == null || 
                    !contactPermissionMap.containsKey(record.Akam_Contact_ACC_Permission_Id__c) || 
                    contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c) == null || 
                    !contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c).containsKey('att') ? 'None' : 
                    contactPermissionMap.get(record.Akam_Contact_ACC_Permission_Id__c).get('att');
                }
                record.Authorized_Contact__c = (Trigger.isInsert || 
                (Trigger.isUpdate && record.Active__c && !((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(record.Id).Active__c) ||
                forceSyncIds.contains(record.Id))?
                (contactIds != null && contactIds.contains(record.contact__c) ? false : true):
                record.Authorized_Contact__c ;
            }
            if(forceSyncRecords.size() > 0)
            {    
                //Uncommenting the code.
                SC_Jarvis_CoreSecurityController.forceSyncPermissions(forceSyncRecords);
            }
    
        }
    }
    //The afterinsertupdate handler
    public override void afterInsertAfterUpdateTrigger()
    {
        //On Update, the data should flow to the Escalation object
        if(!recursionCheck)
        {
            List<AccountContactPermissionWrapper> responseWrappers = new List<AccountContactPermissionWrapper>();
            List<Jarvis_Contact_ACC_Permission__c> contactRecs = (List<Jarvis_Contact_ACC_Permission__c>)newList;
            Set<String> contactIds = new Set<String>();
            //After Insert to set the Acc permission lookup
            List<Contact> contactsToUpdate = new List<Contact>();
            Contact newContact;
    
            //When Acc permission becomes inactive, make all the contract permission records and ACRs inactive
            Set<String> permissionsToInactivate = new Set<String>();
            Set<String> contactsToInactivate = new Set<String>();
    
            
            for(Jarvis_Contact_ACC_Permission__c contactRec : contactRecs)
            {
                if(Trigger.isInsert)
                {
                    newContact = new Contact();
                    newContact.Id = contactRec.Contact__c;
                    newContact.Jarvis_Contact_ACC_Permission__c = contactRec.Id;
                    newContact.Validation_Override__c = true;
                    contactsToUpdate.add(newContact);   
                }
    
                if(contactRec.Response__c != null && contactRec.Response__c.length()  > 10 && 
                    (Trigger.isInsert || 
                        (Trigger.isUpdate && 
                            (
                                contactRec.Response__c != ((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(contactRec.Id).Response__c
                                ||
                                (contactRec.Active__c && !((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(contactRec.Id).Active__c)
                            )
                        )
                    )
                )
                {
                    system.debug('Inside For LOOP');
                    String currentResponse = contactRec.Response__c.replace('auth-grants','authGrants');
                    for(AccountContactPermissionWrapper accountContactWrapper : (List<AccountContactPermissionWrapper>) JSON.deserialize(currentResponse, 
                    List<AccountContactPermissionWrapper>.class))
                    {
                        accountContactWrapper.contactId = contactRec.Akam_Contact_Id__c;
                        accountContactWrapper.parentId = contactRec.Id;
                        accountContactWrapper.contactSalesforceId = contactRec.Contact__c;
                        responseWrappers.add(accountContactWrapper);
                    }
                    contactIds.add(contactRec.Akam_Contact_Id__c);
                }
    
                
                if(Trigger.isUpdate && 
                ((!contactRec.Active__c && ((Map<Id,Jarvis_Contact_ACC_Permission__c>)oldMap).get(contactRec.Id).Active__c )
                ||
                contactRec.Response__c == null
                ||
                contactRec.Response__c.length() < 10)
                )
                {                    
                    permissionsToInactivate.add(contactRec.Id);
                    contactsToInactivate.add(contactRec.Contact__c);
                }
            }
            if(responseWrappers.size() > 0)
            {
                SC_Jarvis_CoreSecurityController.createPermissionRecords(responseWrappers,contactIds);
            }
            if(contactsToUpdate.size() > 0)
            {
                database.update(contactsToUpdate,false);
            }
            if(permissionsToInactivate.size() > 0)
            {
                List<Jarvis_Contact_ACC_Permission_Contract__c> contractPermissionsUpdate = new List<Jarvis_Contact_ACC_Permission_Contract__c>();
    
                for(Jarvis_Contact_ACC_Permission_Contract__c contractPermission : [Select Id, Active__c from Jarvis_Contact_ACC_Permission_Contract__c where
                Customer_Permission__c in :permissionsToInactivate and Active__c = true order by Account__c])
                {
                    contractPermission.Active__c = false;
                    contractPermissionsUpdate.add(contractPermission);
                }
                if(contractPermissionsUpdate.size() > 0)
                {
                    database.update(contractPermissionsUpdate,false);
                    //update contractPermissionsUpdate;
                }
        
            }
            if(contactsToInactivate.size() > 0)
            {
                List<AccountContactRelation> acrRecordsToUpdate = new List<AccountContactRelation>();
                for(AccountContactRelation acrRecord: [Select Id,IsActive  
                from AccountContactRelation where ContactId in :contactsToInactivate and IsActive = true])
                {
                    acrRecord.IsActive = false;
                    acrRecordsToUpdate.add(acrRecord);
                }
                if(acrRecordsToUpdate.size() > 0)
                {
                    database.update(acrRecordsToUpdate,false);
                    //update acrRecordsToUpdate;
                }
            }
    
        }


    }
    //The before delete/undelete handler
    public override void beforeDeleteBeforeUndeleteTrigger()
    {

    }
    //The after delete/undelete handler
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }   
 
}