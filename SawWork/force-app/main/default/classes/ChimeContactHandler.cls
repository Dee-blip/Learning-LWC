/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-17-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-17-2021   apyati   SFDC-8036 Remove contact's account validation
**/
public class ChimeContactHandler extends ApexTriggerHandlerAbstractClass{
    public override void beforeInsertBeforeUpdateTrigger(){
        List<CHIME_Contact__c> chimeContactTriggerNew = (List<CHIME_Contact__c>)newList;
        List<CHIME_Contact__c> chimeContactTriggerOld = (List<CHIME_Contact__c>)oldList;
        Map<Id,CHIME_Contact__c> chimeContactTriggerNewMap = (Map<Id,CHIME_Contact__c>)newMap;
        Map<Id,CHIME_Contact__c> chimeContactTriggerOldMap = (Map<Id,CHIME_Contact__c>)oldMap;
        
        Map<Id,Set<Id>> validChimeIdToContactIdMap = new Map<Id,Set<Id>>();
        Map<id,id> contactaccountIdMap = new Map<Id,Id>();
        set<id> contactidset = new set<id>();
        
        for(CHIME_Contact__c chimeContact : chimeContactTriggerNew){
            //contactaccountIdMap.put(chimeContact.contact__c)
            contactidset.add(chimeContact.contact__c);
        }
        if(contactidset.size()>0){
            for(Contact con : [Select id,accountid from Contact where id in: contactidset ] ){
                contactaccountIdMap.put(con.id, con.AccountId);
            }
        } 
        
        for(CHIME_Contact__c chimeContact : chimeContactTriggerNew){
            CHIME_Contact__c chimeContactRecOld = null;
            if(Trigger.isUpdate){
                chimeContactRecOld = chimeContactTriggerOldMap.get(chimeContact.Id);
            }
            
            System.debug('Inside Trigger Chime_contact handler');
            if(contactaccountIdMap.get(chimeContact.contact__c) != chimeContact.Account__c ){
                //chimeContact.addError('Selected Contact is not present on the Account.');
            }
            if(Trigger.isInsert){
                if(!validChimeIdToContactIdMap.containsKey(chimeContact.chime__C)){
                    validChimeIdToContactIdMap.put(chimeContact.chime__C, new Set<id>());
                }
                validChimeIdToContactIdMap.get(chimeContact.chime__C).add(chimeContact.contact__C);
               
            }
        }

        if(validChimeIdToContactIdMap.size() > 0){       
            ChimeContactClass.validateChimeContact(validChimeIdToContactIdMap,chimeContactTriggerNew);
        }

    }
    
    public override void afterInsertAfterUpdateTrigger(){
        List<CHIME_Contact__c> chimeContactTriggerNew = (List<CHIME_Contact__c>)newList;
        List<CHIME_Contact__c> chimeContactTriggerOld = (List<CHIME_Contact__c>)oldList;
        Map<Id,CHIME_Contact__c> chimeContactTriggerNewMap = (Map<Id,CHIME_Contact__c>)newMap;
        Map<Id,CHIME_Contact__c> chimeContactTriggerOldMap = (Map<Id,CHIME_Contact__c>)oldMap;
        Set<Id> contactIdListForChimeAccessRemoval = new Set<Id>();
        Map<Id, Id> contantIdtoChimeFormId = new Map<Id, Id>();
        List<Id> contactIdList = new List<Id>();

        for(CHIME_Contact__c chimeContact : chimeContactTriggerNew){
            CHIME_Contact__c chimeContactRecOld = null;
            if(Trigger.isUpdate)
                chimeContactRecOld = chimeContactTriggerOldMap.get(chimeContact.Id);

            if(Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Chime_access__c',chimeContactRecOld,chimeContact)) && chimeContact.Chime_access__c){
                contactIdList.add(chimeContact.Contact__c);
                contantIdtoChimeFormId.put(chimeContact.Contact__c, chimeContact.CHIME__c);
                System.debug('chime access checkbox made true');
            }
            
            if(Trigger.isUpdate && Util.hasChanges('Chime_access__c',chimeContactRecOld,chimeContact) && !chimeContact.Chime_access__c){
                contactIdListForChimeAccessRemoval.add(chimeContact.Contact__c);
                System.debug('chime access checkbox made false');
            }
        }

        if(contactIdList.size() > 0){
            System.debug('provisonChimeFormAccessToContacts');
            ChimeContactClass.provisonChimeFormAccessToContacts(contactIdList, contantIdtoChimeFormId);
        }

        if(contactIdListForChimeAccessRemoval.size() > 0){
            System.debug('contactIdListForChimeAccessRemoval:::'+contactIdListForChimeAccessRemoval);
            ChimeContactClass.uncheckChimeOnContact(contactIdListForChimeAccessRemoval);
        }

    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
    
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
        List<CHIME_Contact__c> chimeContactOld = (List<CHIME_Contact__c>)oldList;
        Set<Id> contactIdListForChimeAccessRemoval = new Set<Id>();
        for(CHIME_Contact__c chimeContact : chimeContactOld){
            System.debug('chimeContact:'+chimeContact);
            contactIdListForChimeAccessRemoval.add(chimeContact.contact__c);
        }
        System.debug('contactIdListForChimeAccessRemoval:'+contactIdListForChimeAccessRemoval);
        if(contactIdListForChimeAccessRemoval.size() > 0){
            ChimeContactClass.uncheckChimeOnContact(contactIdListForChimeAccessRemoval);
        }
    }
}