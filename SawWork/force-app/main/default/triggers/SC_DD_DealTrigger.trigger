/****************************************************************************
* @author     : 'Vishnu Vardhan'
* @date       : '06/12/2019'
* @description: 'Deal Desk Trigger'
* Test Class  :   SC_DD_DealDeskTest
****************************************************************************
DATE             DEVELOPER          CR              DESCRIPTION
===========      =========          =======         ===========
June 18, 2020    Vishnu Vardhan     ESESP-3579      Added a Switch, to enable/ disable trigger logic
****************************************************************************/
trigger SC_DD_DealTrigger on SC_DD_Deal__c (after insert, after update) {

    // ESESP-3579 Custom Metadata to enable/ disable this trigger
    Boolean isTriggerActive = [select id, DeveloperName from SC_Utility__mdt 
                                        where DeveloperName = 'SC_DD_DealTrigger' and Active__c = true].size() > 0;
                                                    
    if(isTriggerActive == false) {
        return;
    }
    // After Updtae
    if( Trigger.isAfter && Trigger.isUpdate) {
        SC_DD_DealTriggerHandler.onAfterUpdateDeal();
    }
    
    // After Insert
    if( Trigger.isAfter && Trigger.isInsert) {
        SC_DD_DealTriggerHandler.onAfterInsertDeal();
    }
}