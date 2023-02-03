trigger ProtectedClassPublisher_au on Protected_Class_Publisher__c (before update) {
    ProtectedClassPublisherApproval.costCenterTeamMemberCheck(trigger.New);
	ProtectedClassPublisherApproval.protectedClassPublisherEscalation2(Trigger.New, Trigger.OldMap);
}