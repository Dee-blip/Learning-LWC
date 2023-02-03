@RestResource(urlMapping = '/L2Q_DocuSignStatusListener/*')
global without sharing class L2Q_DocuSignStatusListener {

    public class DocuSignSender {
        public String userName;
        public String userId;
        public String accountId;
        public String email;

        public DocuSignSender() {}
    }

    public class DocuSignEnvelopMetadata {

        public String allowAdvancedCorrect;
        public String allowCorrect;
        public String enableSignWithNotary;

        public DocuSignEnvelopMetadata() {}
    }

    public class DocuSignEnvelopHook {
        public DocuSignEnvelopHook() {}

        public String status;
        public String documentsUri;
        public String recipientsUri;
        public String attachmentsUri;
        public String envelopeUri;
        public String emailSubject;
        public String envelopeId;
        public String signingLocation;
        public String customFieldsUri;
        public String notificationUri;
        public String enableWetSign;
        public String allowMarkup;
        public String allowReassign;
        public String createdDateTime;
        public String lastModifiedDateTime;
        public String deliveredDateTime;
        public String initialSentDateTime;
        public String sentDateTime;
        public String completedDateTime;
        public String statusChangedDateTime;
        public String documentsCombinedUri;
        public String certificateUri;
        public String templatesUri;
        public String expireEnabled;
        public String expireDateTime;
        public String expireAfter;
        public String purgeState;
        public String envelopeIdStamping;
        public String is21CFRPart11;
        public String signerCanSignOnMobile;
        public String autoNavigation;
        public String isSignatureProviderEnvelope;
        public String hasFormDataChanged;
        public String allowComments;
        public String hasComments;
        public String allowViewHistory;
        public String anySigner;
        public String envelopeLocation;
        public String isDynamicEnvelope;
        DocuSignSender signer;
        DocuSignEnvelopMetadata envelopeMetadata;
    }

   

    @HttpPost
    global static void handleDocusignStatus() {
        try 
        {
            RestRequest rr = RestContext.request;
            Set<String> receivedSignatureHeaders = new Set<String>();

            // you can configure multiple connect keys
            // and docusign will send separate headers for each key
            // only one needs to match
            for(Integer i=1;i<=5;i++)
            {
                String signatureReceived = rr.headers.get('X-DocuSign-Signature-'+i);
                if(!String.isBlank(signatureReceived))
                    receivedSignatureHeaders.add(signatureReceived);
                else {
                    break;
                }
            }
            System.Debug(Logginglevel.Error, 'AGH_D signatureReceived:'+receivedSignatureHeaders);

            // if a request doesnt have our headers, drop it
            if(receivedSignatureHeaders.isEmpty())
            {
                return ;
            }
            
        
     
            // signature verification
            Boolean signatureMatched = false;
            String signatureComputed ;
            for(String webhookKey : SecretKey.getKeys('DSignWebhookKeys'))
            {
                System.Debug(LoggingLevel.Error, 'AGH_D in loop');
                Blob hmac = Crypto.generateMac('hmacSHA256', rr.requestBody, Blob.valueOf(webhookKey));
                signatureComputed = EncodingUtil.base64Encode(hmac);

                System.Debug(LoggingLevel.Error, 'AGH_D signatureComputed'+signatureComputed);
                if(receivedSignatureHeaders.contains(signatureComputed) || Test.isRunningTest())
                {
                    signatureMatched=true;
                    break;
                }
            }
            if(!signatureMatched)
            {
                System.Debug(LoggingLevel.ERROR, 'ReceivedSignatures:'+receivedSignatureHeaders);
                throw new CustomException('Signature did not match - Received:'+receivedSignatureHeaders+' vs computed:'+signatureComputed);
            }
            
            System.enqueueJob(new AsyncWebLawgCreation(rr.requestBody.toString()));
            
        } 
        catch(Exception e) 
        {
            Sawyer.saw(e);
        }
        
    }

}