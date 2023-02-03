/****************************************************************************
* Class name          :   SC_TrialRequestFormTrigger
* Author              :   Vishnu Vardhan
* Created             :   03-Aug-2020
* Purpose             :   Trigger for SC_Trial_Request_Form__c
* Test Class          :    
-------------------------------------------------------------------------------
DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
03-Aug-2020      Vishnu Vardhan   ESESP-2826      PST Case: TRF Validations
*****************************************************************************/
trigger SC_TrialRequestFormTrigger on SC_Trial_Request_Form__c (before update) {
    //ESESP-2826 :PST Case related Logic
    SC_TriggerHandlerAbstract trfTriggerHandler = new SC_TrialFormTriggerHandler(); 
    trfTriggerHandler.process();
}