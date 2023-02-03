trigger ProtectedClassPublisher_ai on Protected_Class_Publisher__c (after insert) {
    ProtectedClassPublisherApproval.protectedClassSubmit(trigger.New);
}