/***************************************************************************************************************************************
Class Name  : TrailsEmailService
Author      : kusharma
Description : This class attach the SA reports to the Trials Request Form
***************************************************************************************************************************************/
global class TrailsEmailService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        System.debug('<<< Email Service Called');
        string emailPrefix = Trials_Automation_Site_Analyser_Details__c.getValues('EmailPrefix').Value__c;
        string recordName ;
        if(email.subject.containsIgnoreCase(emailPrefix)){
            recordName = emailPrefix.substring(0,1)+ email.subject.substringBetween(emailPrefix.substring(0,1),':').trim() ;
        }
                
        List<Trials_Request_Form__c> lTrialsReqForm = new List<Trials_Request_Form__c>();
        lTrialsReqForm = [SELECT Id,TrialsTestingStarted__c,Trials_Trials_Request_Name__c FROM Trials_Request_Form__c 
                          WHERE Name =: recordName AND Trails_Complete__c = false];
        list<Attachment> lAttachments = new list<Attachment>();
        system.debug('###' + lTrialsReqForm + ' ' + email.binaryAttachments);
        if(email.binaryAttachments != null && email.binaryAttachments.size() > 0 
           && !lTrialsReqForm.isEmpty()){
            for (integer i = 0 ; i < email.binaryAttachments.size() ; i++){
                Attachment objAttachment = new Attachment();
                objAttachment.Body = email.binaryAttachments[i].body;
                objAttachment.Name = lTrialsReqForm[0].Trials_Trials_Request_Name__c + '_'
                             + string.valueOf(System.now().formatGMT('dd/MM/yyyy'));
                objAttachment.ParentId = lTrialsReqForm[0].Id;
                lAttachments.add(objAttachment);
            } 
            system.debug('$$$$' + lAttachments);            
            if(lAttachments.size() >0){
                insert lAttachments;
            }
            
            if(!lTrialsReqForm.isEmpty() && lTrialsReqForm != NULL 
               && !lTrialsReqForm[0].TrialsTestingStarted__c){
                lTrialsReqForm[0].TrialsTestingStarted__c = true;
                update lTrialsReqForm;
            }
            
        }
        return null;
    }
    
}