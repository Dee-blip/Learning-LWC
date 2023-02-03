/**
 * Created by kusharma on 22/01/18.
 */

trigger RAMDOzoneTrigger on RAMD_Orange_Zone_Countries__c (before insert, before update,
        before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isAfter) {
        RAMDProcessor ramdProcessor = new RAMDProcessor();
        ramdProcessor.processInactiveCountries(Trigger.New, Trigger.isUpdate, Trigger.OldMap);
    }

}