trigger ProtectedClassPublisher_bi on Protected_Class_Publisher__c (before insert) {
    ProtectedClassPublisherApproval.costCenterTeamMemberCheck(trigger.New);
    ProtectedClassPublisherApproval.duplicateCheck(trigger.New);
}