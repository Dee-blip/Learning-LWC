/**
 * EMail handler for International Business Development.
 * When email is sent to a particular address, a case is created
 * and a email is sent to case creater and queue with a unique subject.
 * All the subsequent email trasfers with attachments are tracked by case as tasks
 *
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N	03/2011		Created Class
 **/
global class E2CIntlBusDev implements Messaging.InboundEmailHandler {
private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('E2CIntlBusDev');
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //create result for email operation
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
               
        EmailToCase.init(email,CustomSettings);
        /*result.message='The data has been added successfully: '+ subjecttext;
        result.success = true;                    
        return result;*/
        //Dont return anthing for the user
        return null;
               

	}
}