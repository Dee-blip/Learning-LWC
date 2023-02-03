trigger partnerOrderAcceptanceDocument on Partner_Order_Acceptance_Document__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    //Moved All existing code to L2Q_POAD_TriggerHandler
    ApexTriggerHandlerAbstractClass.createHandler('partnerOrderAcceptanceDocument');
}