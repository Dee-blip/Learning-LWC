//Added as part of SFDC-2250
//Modified class by Sujay - added changes as per CR : FFPSA-373
// Modified class by Nagaraj Desai - as part of SFDC-3601
// Modified by Sujay 19.1 for FFPSA, to merge few customMetadat for the Fall 18 upgrade from line 20.

public class ContactTriggerHandler extends ApexTriggerHandlerAbstractClass {
    
    public static Boolean callJarvisUserMethod = true;
    public override void beforeInsertBeforeUpdateTrigger(){
        
        List<Contact> contactsTriggerNew = (List<Contact>)newList;
        List<Contact> contactsTriggerOld = (List<Contact>)oldList;
        Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
        Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;
        
        List<Id> accountIdList=new List<Id>();
        
        //adding a below variables and a Query to get all record values from CMD - Sujay, CR : FFPSA-373. And adding changes from line 47
        Id devRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
        Double lPresense, lAbsense;
        //changes by Sujay 19.1: This is as part of clubbing custometa data to minimize the usage for FF fall 18 Upgrade. 
        List <PSA_Common_Setting__mdt> titleContacts = new List<PSA_Common_Setting__mdt>([SELECT Id, MasterLabel, Value__c,DeveloperName ,LOE_Low_Limts__c , LOE_High_Limit__c FROM PSA_Common_Setting__mdt WHERE type__c = 'PSA_Resource_Contact__mdt']);
        //List<PSA_Resource_Contact__mdt> titleContacts = new List<PSA_Resource_Contact__mdt>([SELECT Value__c, DeveloperName, LOE_Low_Limts__c,LOE_High_Limit__c FROM PSA_Resource_Contact__mdt]);
        
        //Adding changes as per CR : FFPSA-373 - Sujay
        for(Contact con: contactsTriggerNew) {
            
            Boolean flag = false;
            if(con.RecordTypeId == devRecTypeId && con.Title != NULL) {
                for(PSA_Common_Setting__mdt t : titleContacts) {
                    System.debug('t ::::: '+ t);
                    if( t.Value__c != NULL && con.Title.ContainsIgnoreCase(t.Value__c) ) {
                        flag = true;
                    }
                    if(t.DeveloperName == 'Lead_Presence_Absence' && t.LOE_Low_Limts__c != NULL) {
                        lAbsense = t.LOE_Low_Limts__c;
                        System.debug('lAbsense ::: '+ lAbsense);
                    }
                    if(t.DeveloperName == 'Lead_Presence_Absence' && t.LOE_High_Limit__c != NULL) {
                        lPresense = t.LOE_High_Limit__c;
                        System.debug('lAbsense ::: '+ lPresense);
                    }
                }
                
                if(con.Title.ContainsIgnoreCase('Lead') && !flag ) {
                    con.Billable_Utilization_Target__c = lPresense;
                }
                else if(!con.Title.ContainsIgnoreCase('Lead') && !flag ) {
                    con.Billable_Utilization_Target__c = lAbsense;
                }
            }
            
            if(Trigger.isInsert)
            {
                accountIdList.add(con.AccountId); // check this list -- needed?
            }
            
        }// End of changes as per FFPSA-373 - Sujay
        
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    
    public override void afterInsertAfterUpdateTrigger() {
        
        list<string> contactsforDeProvisioning = new list<string>();
        list<string> contactsforProvisioning = new list<string>();

        List<Contact> contactsTriggerNew = (List<Contact>)newList;
        //List<Contact> contactsTriggerOld = (List<Contact>)oldList;
        //Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
        Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;
        
        //--------JARVIS RELATED CHANGES----------
        try 
        {
            for(Contact con: contactsTriggerNew) 
            {
                if(Trigger.isUpdate && !con.active_portal_login__c && contactsTriggerOldMap.get(con.Id).active_portal_login__c)
                {
                    contactsforDeProvisioning.add(con.id);
                }
                //Added L2Q_ManagePartnerOperationsController.createPartnerUserRun check to by Pass the Partner Users - ESESP-7303(Vamsee)
                else if((Trigger.isUpdate && L2Q_ManagePartnerOperationsController.createPartnerUserRun == false && con.active_portal_login__c && !contactsTriggerOldMap.get(con.Id).active_portal_login__c)
                || (Trigger.isInsert && con.active_portal_login__c))
                {
                    contactsforProvisioning.add(con.id);
                }
            }
            if(callJarvisUserMethod && contactsforDeProvisioning.size()>0 && !(System.isFuture() || System.isScheduled() || System.isBatch()) )
            {
                callJarvisUserMethod = false;
                if(contactsforDeProvisioning.size() < 50)
                {
                    SC_Jarvis_User_Deprovision_Queue deprovisionQueue = new SC_Jarvis_User_Deprovision_Queue();
                    deprovisionQueue.contactIds = contactsforDeProvisioning;
                    system.enqueueJob(deprovisionQueue);

                }
                else
                {
                    SC_Jarvis_User_Deprovision_Batch deprovisionBatch = new SC_Jarvis_User_Deprovision_Batch();
                    deprovisionBatch.contactIds = contactsforDeProvisioning;
                    database.executeBatch(deprovisionBatch,50);

                }
            }
            if(callJarvisUserMethod && contactsforProvisioning.size()>0 && !(System.isFuture() || System.isScheduled() || System.isBatch()))
            {
                callJarvisUserMethod = false;
                if(contactsforProvisioning.size() < 20)
                {
                    SC_Jarvis_User_Permission_Queue permissionQueue = new SC_Jarvis_User_Permission_Queue();
                    permissionQueue.contactIds = contactsforProvisioning;
                    system.enqueueJob(permissionQueue);
                }
                else
                {
                    SC_Jarvis_User_Setup_Batch provisionBatch = new SC_Jarvis_User_Setup_Batch();
                    provisionBatch.contactIds = contactsforProvisioning;
                    database.executeBatch(provisionBatch,20);
                }

            }
                
        } 
        catch (Exception e) 
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Contact Handler Exception','Exception: ' , e.getMessage());
        }
        
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger() {
    }
}