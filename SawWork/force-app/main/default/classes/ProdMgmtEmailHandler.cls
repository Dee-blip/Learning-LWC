/**
 * EMail handler for Product Management cases.
 * When email is sent to a particular address, a case is created
 * and a email is sent to case creater and queue with a unique subject.
 * All the subsequent email trasfers with attachments are tracked by case as tasks
 *
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
   Vinayendra T N	12/2010		Created Class
 **/
global class ProdMgmtEmailHandler implements Messaging.InboundEmailHandler {
private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('ProdMgmt');
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //create result for email operation
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
              
        // Call Init function which does all the work.
        EmailToCase.init(email,CustomSettings);
        /*result.message='The data has been added successfully: '+ subjecttext;
                    result.success = true;                    
                    return result;*/
        //Dont return anthing for the user
        return null;
               

	}
}