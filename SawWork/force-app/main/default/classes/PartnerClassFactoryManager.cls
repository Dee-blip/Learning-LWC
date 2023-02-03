/*=====================================================================================================+
    Class name          :   PartnerClassFactoryManager 
    Authors             :   Aditya,Akhila,Jay & Kunal
    Created             :   27-Jan-16
	Purpose 			:	Class for generating Handler class for Partners dynamically.
+=====================================================================================================*/
public class PartnerClassFactoryManager {
    
    public PartnerClassFactoryManager(){}

    public static void createHandler(List<SObject> lSobject, Boolean isBefore){
		IPartnerProcessor handler;
        if(lSobject[0] instanceOf Inbound_Request_Queue__c){
            // Get a handler appropriate to the object being processed
            handler = getHandler(((Inbound_Request_Queue__c)lSobject[0]).Originating_Partner_Account__c+'Handler');
        }
        if(lSobject[0] instanceOf Outbound_Request_Queue__c){
            // Get a handler appropriate to the object being processed
            handler = getHandler(((Outbound_Request_Queue__c)lSobject[0]).Originating_Partner_Account__c+'Handler');
        }
		// Make sure we have a handler registered, new handlers must be registered in the getHandler method.
		if (handler == null){
			throw new TriggerException('No Trigger Handler registered for Partner Type');
		}
		
		// Execute the handler to fulfil the trigger
		execute(handler);
	}
    private static void execute(IPartnerProcessor handler){
        if(Trigger.isInsert){
        	handler.inboundRequestInsertProcessor(Trigger.new, Trigger.isBefore);
        	handler.outboundRequestInsertProcessor(Trigger.new, Trigger.isBefore);
        }
        if(Trigger.isUpdate){
       		handler.inboundRequestUpdateProcessor(Trigger.new, Trigger.isBefore, Trigger.old);
        	handler.outboundRequestUpdateProcessor(Trigger.new, Trigger.isBefore, Trigger.old);
        }
    }
    // Return the appropriate class instance based on className
    public static IPartnerProcessor getHandler(String className)
    {
        Type t = Type.forName(className);
        if(t==null){
            return null;
        }
        return (IPartnerProcessor) t.newInstance();
    }

}