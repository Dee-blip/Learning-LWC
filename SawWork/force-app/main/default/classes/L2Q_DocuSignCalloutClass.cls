public without sharing class L2Q_DocuSignCalloutClass {
    public static Map < String, String > settingsMap {
        get {
            if(settingsMap == null ) {
                settingsMap = NAPSettings.getValuesWithPrefix('DSign');
                /*
              settingsMap = new Map < String, String > {
                    'RequestAuthEndpoint' => 'https://account-d.docusign.com/oauth/token',
                    'RequestAuthContentType' => 'application/x-www-form-urlencoded',
                    'RequestAuthDomain' => 'account-d.docusign.com',
                    'RequestScope' => 'signature',
                    'RequestAuthBody' => 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=',
                    'DSUserId' => 'fdf25f2b-9663-4245-b54e-0a61fd249883',
                    'DSAccountID' => '90efc75a-58c3-46c7-a814-e7cea0d8dd29',
                    'RequestEnvelopeEndpoint' => 'https://demo.docusign.net/restapi/v2/accounts/',
                    'RequestEnvelopeStatus' => 'sent',
                    'RequestEnvelopeSubject' => 'Send Envelope via REST from Salesforce',
                    'RequestEnvelopeTemplateID' => '59856e78-d3c2-44e8-a6b5-6f31c96b67cf',
                    'requestCreateEnvelopeEndpoint' => '#baseUrl#/#apiVersion#/accounts/#accountId#/envelopes',
                    'baseUrl' => 'https://demo.docusign.net/restapi',
                    'apiVersion' => 'v2.1',
                    'GetDocumentsFromEnvelopEndpoint' => '#baseUrl#/#apiVersion#/accounts/#accountId#/envelopes/#envelopId#/documents/archive'
                };
                */
            }
            return settingsMap;
        }
        set;
    }

    public L2Q_DocuSignCalloutClass() {}

    public class EnvelopeCreationRequest {
        public String emailSubject { get; set; }
        public String status { get; set; }
        public String templateId { get; set; }
    }

    public class EnvelopeCreationResponse {
        public String envelopeId { get; set; }
        public String uri { get; set; }
        public String status { get; set; }
        public String statusDateTime { get; set; }
    }

    public static void createEnvelope(String name, String email, String contentVersionId, Partner_Order_Acceptance_Document__c poa) {
        try {
            String accessToken = getAccessToken();


        if (!String.isEmpty(accessToken)) {
            Http httpProtocol = new Http();
            HttpRequest request = new HttpRequest();
            String endpoint = settingsMap.get('RequestCreateEnvelopeEndpoint')
                .replaceAll('#baseUrl#', settingsMap.get('BaseUrl'))
                .replaceAll('#apiVersion#', settingsMap.get('ApiVersion'))
                .replaceAll('#accountId#', settingsMap.get('DSAccountID'));
            System.Debug(LoggingLevel.INFO, '***endpoint ' + endpoint);
            request.setEndPoint(endpoint);
            request.setMethod('POST');

            request.setHeader('grant_type', 'Bearer');
            String authType = 'Authorization';
            String authValue = 'Bearer '+accessToken;
            request.setHeader(authType, authValue);
            request.setHeader('Accept', 'application/json');

            request.setHeader('Content-type', 'application/json');
            EmailTemplate et = [SELECT Id, DeveloperName, Body, HtmlValue, Subject 
                FROM EmailTemplate WHERE DeveloperName='TNC_Sending'];
        
            String plainTextBody = et.Body
                .replaceAll('#CustomerContactName#', name)
                .replaceAll('#SenderName#', UserInfo.getName())
                .replaceAll('#PartnerInvolvedName#', poa.Opportunity__r.Partner_Involved__r.Name);

            DocuSignEnvelop envelop = new DocuSignEnvelop();

            ContentVersion requiredDocument = [SELECT Id, VersionData, FileExtension, PathOnClient, ContentDocumentId  FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            Document documentBeingSent = new Document(EncodingUtil.base64Encode(requiredDocument.VersionData), '1', requiredDocument.FileExtension, requiredDocument.PathOnClient);
            
            envelop.documents.add(documentBeingSent);
            envelop.emailSubject = et.Subject;
            envelop.emailBlurb=plainTextBody;

            Signer signerPerson = new Signer(email, name, '1');
            envelop.recipients.signers.add(signerPerson);

            envelop.status = settingsMap.get('RequestEnvelopeStatus');

            System.Debug(LoggingLevel.INFO, 'requestObject() ' + envelop);
            String jsonBody = json.serialize(envelop);
            System.Debug(LoggingLevel.INFO, 'jsonBody() ' + jsonBody);
            request.setBody(jsonBody);

            HttpResponse response = httpProtocol.send(request);
            System.Debug(LoggingLevel.INFO, 'response.getBody() ' + response.getBody());
            System.debug(LoggingLevel.INFO, 'response.getStatus() ' + response.getStatus());
			
            String responseStatus = response.getStatus();
            if (responseStatus.equals('Created')) 
            {
                DocuSignEnvelopResponse responseObject = new DocuSignEnvelopResponse();
                responseObject = (DocuSignEnvelopResponse)System.JSON.deserialize(response.getBody(), DocuSignEnvelopResponse.class);
                System.Debug(LoggingLevel.INFO, 'responseObject ' + responseObject);
                Partner_Passthrough_Detail__c pd = new Partner_Passthrough_Detail__c();
                pd.Customer_Name__c = name;
                pd.Customer_Email__c = email;
                pd.DocuSignEnvelopId__c = responseObject.envelopeId;
                pd.DocuSignEnvelopStatus__c = responseObject.status;
                pd.DocuSignEnvelopURI__c = responseObject.uri;
                pd.DocuSignEnvelopDateTime__c = DateTime.valueOf(responseObject.statusDateTime.replace('T', ' ').subString(0, 19));
                pd.Partner_Order_Acceptance_Document__c = poa.Id;
                pd.End_Customer_Account__c = poa.Opportunity__r.AccountId;
                insert pd;
                ContentDocumentLink cdl = L2Q_ContentDocumentUtilClass.setContentDocumentLink(requiredDocument.ContentDocumentId, pd.Id, 'I', 'AllUsers');
                insert cdl;
            }
            else 
            {
                throw new CustomException(responseStatus+ ' ' + response.getBody());
            }    
        }
    }
        catch (Exception e) 
        {
            Sawyer.saw(e);
        }
        
    }

    public static String getAccessToken() {

        String access_token = null;
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');

        String authendpoint = settingsMap.get('RequestAuthEndpoint');
        req.setEndPoint(authendpoint);

        String authRequestContentType = settingsMap.get('RequestAuthContentType');
        req.setHeader('Content-type', authRequestContentType);

        String authRequestDomain = settingsMap.get('RequestAuthDomain');
        req.setHeader('Host', authRequestDomain);

        String alg = 'RS256';
        String iss = SecretKey.getKey('DSignRequestIntegratorKey');
        String pkey = SecretKey.getKeyWithPrefix('DSignPvtKey');
        String scope = settingsMap.get('RequestScope');
        DocusignJWT jwtObject = new DocusignJWT(alg, settingsMap.get('DSUserId'), iss, pkey, scope, authRequestDomain);

        String requestBody = settingsMap.get('RequestAuthBody') + jwtObject.issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, 'ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, 'ResponseAuth' + res);

        if (res.getStatusCode() == 200) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    access_token = parser.getText();
                    break;
                }
            }
        }
        else {
            throw new CustomException(res.getStatusCode() + ': '+ res.getStatus()+ ': '+ res.getBody());
        }

        return access_token;

    }
    
    @future(callout=true)
    public static void getCompletedDocumentDetails(String envelopId, String passThroughDetailId) {
        try {
            String accessToken = getAccessToken();

            Blob blbResponse = null;
            if (!String.isEmpty(accessToken)) {
                Http httpProtocol = new Http();
                HttpRequest request = new HttpRequest();
                String endpoint = settingsMap.get('GetDocumentsFromEnvelopEndpoint')
                    .replaceAll('#baseUrl#', settingsMap.get('BaseUrl'))
                    .replaceAll('#apiVersion#', settingsMap.get('ApiVersion'))
                    .replaceAll('#accountId#', settingsMap.get('DSAccountID'))
                    .replaceAll('#envelopId#', envelopId);

                request.setEndPoint(endpoint);
                request.setMethod('GET');

                request.setHeader('grant_type', 'Bearer');
                request.setHeader('Authorization', 'Bearer ' + accessToken);
                //request.setHeader('Accept', 'application/json');
                request.setHeader('Content-type', 'application/json');
                request.setHeader('Accept', 'application/json');
                HttpResponse response = httpProtocol.send(request);

                blbResponse = response.getBodyAsBlob();

                ContentVersion cv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'DocuSigned-' + 'Doc' + '.zip', 'DocuSigned-' + 'Doc' + '.zip', blbResponse);
                cv.FirstPublishLocationId = passThroughDetailId;
                insert cv;
                System.DEBUG(cv.Id);
            } 
        }catch (Exception e) {
            Sawyer.saw(e);
        }
    }
    
    public class DocusignJWT {
        
        public String alg {get;set;} //RS256 for DocuSign REST integration
        public String iss {get;set;} // Integrator key
        public String sub {get;set;} // DSFProUserName from the user record
        public String aud {get;set;} // Authentication domain
        public String scope {get;set;} // signature scope
        public String privateKey {get;set;} //Private key 
        public String exp {get;set;} 
        public String iat {get;set;}
        public Map<String,String> claims {get;set;}
        public Integer validFor {get;set;}
        public String cert {get;set;}
        public final String HS256 = 'HS256';
        public final String RS256 = 'RS256';
        public final String NONE = 'none';
        private final String STRING_EMPTY = '';


        //Constructor 
        public DocusignJWT(String alg,String sub,String iss, String privateKey,String scope,String aud) {
            this.alg = alg; 
            this.sub = sub; 
            this.iss = iss; 
            this.privateKey = privateKey; 
            this.scope = scope; 
            this.validFor = 300; 
            this.aud = aud; 
        }
        
        //Method which returns the JSON Web Token
        public String issue() {
            String jwt = STRING_EMPTY;
            
            //Construct the JSON Web Token Header 
            JSONGenerator header = JSON.createGenerator(false);
            header.writeStartObject();
            header.writeStringField('alg', this.alg);
            header.writeStringField('typ','JWT'); // Set as JWT
            header.writeEndObject();
            String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
            
            //Construct the JSON Body             

            JSONGenerator body = JSON.createGenerator(false);
            body.writeStartObject();
            body.writeStringField('iss', this.iss);
            body.writeStringField('sub', this.sub);
            body.writeStringField('aud', this.aud);
            Long rightNow = (dateTime.now().getTime()/1000)+1;
            body.writeNumberField('iat', rightNow);
            body.writeNumberField('exp', (rightNow + validFor));
            body.writeStringField('scope', this.scope);
            if (claims != null) {
                for (String claim : claims.keySet()) {
                    body.writeStringField(claim, claims.get(claim));
                }
            }
            body.writeEndObject();
            
            //JSON Web Token in this stage = encodedHeader + . + encodedBody
            jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
            
            //Sign with Private key to create the signature 
            if (this.alg == HS256 ) {
                Blob key = EncodingUtil.base64Decode(privateKey);
                Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
                jwt += '.' + base64URLencode(signature);  
            } 
            else if (this.alg == RS256 ) {
                Blob signature = null;   
                if (cert != null) {
                    signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
                } else {
                    Blob privateKeyBlob = EncodingUtil.base64Decode(privateKey);
                    //construct the signature
                    if(!Test.isRunningTest())
                        signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKeyBlob);
                    else
                        signature=Blob.valueOf('JLFDS-X');
                }
                jwt += '.' + base64URLencode(signature);  
            } else if ( this.alg == NONE ) {
                jwt += '.';
            }
            return jwt;
            
        }
        
    }

    public static String base64URLencode(Blob input){ 
        String output = '';
        if (input != null) {
            output = encodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
        }    
        return output;
    }

    class Document {
        String documentBase64;
        String documentId;
        String fileExtension;
        String name;

        public Document(String documentBase64, String documentId, String fileExtension, String name) {
            this.documentBase64 = documentBase64;
            this.documentId = documentId;
            this.fileExtension = fileExtension;
            this.name = name;
        }
    }

    class Signer {
        public String email;
        public String name;
        public String recipientId;

        public Signer(String email, String name, String recipientId) {
            this.email = email;
            this.name = name;
            this.recipientId = recipientId;
        }
    }

    class Recipient {
        public List<Signer> signers;
        public Recipient() {
            this.signers = new List<Signer>();
        }
    }

    class DocuSignEnvelop {
        public List<Document> documents;
        public String emailSubject;
        public Recipient recipients;
        public String status;
        public string emailBlurb;
        public boolean allowReassign;

        public DocuSignEnvelop() {
            documents = new List<Document>();
            recipients = new Recipient();
            allowReassign=false;
        }
    }

    class DocuSignEnvelopResponse {
        public String envelopeId;
        public String uri;
        public String statusDateTime;
        public String status;
    }

}