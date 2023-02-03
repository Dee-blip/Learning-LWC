trigger OutboundRequestTrigger on Outbound_Request_Queue__c (after delete, after insert, 
                                                             after update, before delete, before insert, 
                                                             before update) {
    if(MSAzureHandler.varActivateMSAzureCode)
		PartnerClassFactoryManager.createHandler(Trigger.new, Trigger.isBefore);
}