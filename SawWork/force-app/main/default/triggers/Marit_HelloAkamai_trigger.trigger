trigger Marit_HelloAkamai_trigger on Hello_Akamai_Activity__c (after insert) {
    ApexTriggerHandlerAbstractClass.createHandler('Hello_Akamai_Activity__c');
}