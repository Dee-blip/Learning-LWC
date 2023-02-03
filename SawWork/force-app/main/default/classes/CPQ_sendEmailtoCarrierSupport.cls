/**
* The CPQ_sendEmailtoCarrierSupport class will send emails to carrier support,
* When the opportunity is turend to the stage 6. signed
* Scheduler class: CPQ_sendEmailtoCarrierSupportScheduler
* Test class: CPQ_Test_sendEmailtoCarrierSupport
* @author  Shashank Hegade
* @version 1.0
* @since   2020-05-18
*/
public class CPQ_sendEmailtoCarrierSupport implements Queueable{

    private Map<string, CPQ_Generic_Settings__c> cpqCustomSetting;

    /** 
     * The constructor is used to get the required custom setting
     */ 

    public CPQ_sendEmailtoCarrierSupport(){

        this.cpqCustomSetting = new Map<string, CPQ_Generic_Settings__c>{
            'CarrierSupportEmail' => CPQ_Generic_Settings__c.getValues('CarrierSupportEmail'),
            'SendAttachment' => CPQ_Generic_Settings__c.getValues('SendAttachment'),
            'emailTemplateName' => CPQ_Generic_Settings__c.getValues('EmailTemplateName'),
            'targetUserAlias' => CPQ_Generic_Settings__c.getValues('targetUserAlias'),
            'opportunityStageName' => CPQ_Generic_Settings__c.getValues('opportunityStageName'),
            'addCCaddress' => CPQ_Generic_Settings__c.getValues('addCCaddress'),
            'addBCCaddress' => CPQ_Generic_Settings__c.getValues('addCCaddress')
        };

    }

    /**
     * execute method is called from the queuable instance of the class
     * @param  qc queable context of the class which implements Queueable interface
     */
    public void execute(QueueableContext qc){

        try{
            List<SBQQ__Quote__c> primaryQuotes = [SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c,SBQQ__Status__c, SBQQ__SalesRep__r.Email,
                                                (SELECT Name, SBQQ__AttachmentId__c, SBQQ__Quote__c, createdDate FROM SBQQ__R00N70000001lX7YEAU__r ORDER BY CreatedDate DESC LIMIT 1) 
                                                FROM SBQQ__Quote__c
                                                WHERE CPQ_Primary__c = true
                                                AND SBQQ__Status__c = 'Approved'
                                                AND CPQ_Carrier_Support_Email_sent__c != true 
                                                AND CPQ_Opportunity_Stage_name__c LIKE :'%' + this.cpqCustomSetting.get('opportunityStageName').CPQ_Value__c + '%'];

            EmailTemplate[] emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                        FROM EmailTemplate 
                                        WHERE name LIKE : '%' + this.cpqCustomSetting.get('emailTemplateName').CPQ_Value__c + '%' LIMIT 1];

            User targetUser = [SELECT Id, Name , Alias FROM User where Alias = :this.cpqCustomSetting.get('targetUserAlias').CPQ_Value__c LIMIT 1];

            if(this.cpqCustomSetting.get('CarrierSupportEmail').CPQ_Active__c && primaryQuotes.size() > 0 && emailTemplate.size()>0){

                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

                for(SBQQ__Quote__c quote: primaryQuotes){

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTemplateId(emailTemplate[0].Id);
                message.setTargetObjectId(targetUser.Id);
                
                if(this.cpqCustomSetting.get('addBCCaddress').CPQ_Active__c){
                    message.setBccAddresses(new List<String>{quote.SBQQ__SalesRep__r.Email});
                }

                if(this.cpqCustomSetting.get('addCCaddress').CPQ_Active__c){
                    string emailAddresses = this.cpqCustomSetting.get('addCCaddress').CPQ_Value__c;
                    String[] emailAddressesList = emailAddresses.split(';');
                    message.setCcAddresses(emailAddressesList);
                }

                if(Test.isRunningTest()){
                    //don't create activity if test is running, setSaveAsActivity with TRUE will create mail actvity history as task
                    message.setSaveAsActivity(false);
                }

                message.setToAddresses(new List<String>{this.cpqCustomSetting.get('CarrierSupportEmail').CPQ_Value__c});
                message.setTreatTargetObjectAsRecipient(false);
                message.setWhatId(quote.Id);

                if(this.cpqCustomSetting.get('SendAttachment').CPQ_Active__c &&  quote.SBQQ__R00N70000001lX7YEAU__r.size() > 0 && quote.SBQQ__R00N70000001lX7YEAU__r != null ){
                    SBQQ__QuoteDocument__c attachment = quote.SBQQ__R00N70000001lX7YEAU__r[0];
                    message.setEntityAttachments(new List<Id>{attachment.SBQQ__AttachmentId__c});
                }

                messages.add(message);
                quote.CPQ_Carrier_Support_Email_sent__c = true;

            }

            if(Test.isRunningTest() && primaryQuotes.size() > 1){
                primaryQuotes[0].ownerId = primaryQuotes[0].Id;
            }

                Messaging.SendEmailResult[] mailResults = Messaging.sendEmail(messages);
                Database.SaveResult[] recordResults = Database.update(primaryQuotes,false);

                CPQ_Error_Log__c[] errorList = new List<CPQ_Error_Log__c>();  
                for (Database.SaveResult sr : recordResults) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            CPQ_Error_Log__c newError = new CPQ_LogException(err.getMessage()).createErrorRecord(false).getErrorRecord();
                            errorList.add(newError);
                        }
                        
                    }
                }
                if(errorList.size() > 0){
                    Database.SaveResult[] errorResults = Database.insert(errorList,false);
                }
            }
        }
        Catch(Exception error){
            CPQ_Error_Log__c newError = new CPQ_LogException('Error occured in CPQ_sendEmailtoCarrierSupport:execute method',error).createErrorRecord(true).getErrorRecord();
            System.debug(LoggingLevel.WARN,'-->' + newError);
        }
    }
    
}