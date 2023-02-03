// https://developer.akamai.com/legacy/introduction/Client_Auth.html
public class AkamaiEdgeAuthStrategy extends RestEasyClient.GenericAuthStrategy
{

        public AkamaiEdgeAuthStrategy()
        {
                
            super(!Test.isRunningTest() ? (GsmUtilClass.isSandbox() ? NAPSettings.getValue('PulsarEnvironmentConnectorName_Sandbox') : NAPSettings.getValue('PulsarEnvironmentConnectorName')) :'PulsarSQAForTestClass');
        }

        //added this parameterized constructor for autonomy - shegade 02-10-2020
        public AkamaiEdgeAuthStrategy(String connectorName){
            super(connectorName);
        }


        public override HttpRequest setAuthHeaders(HttpRequest req)
        {
                Blob aesKey = Crypto.GenerateAESKey(128);
                String hexKey = EncodingUtil.ConvertTohex(aesKey);
                String nonce = hexKey.SubString(0,8)+ '-' + hexKey.SubString(8,12) + '-' + hexKey.SubString(12,16) + '-' + hexKey.SubString(16,20) + '-' + hexKey.substring(20);
                //nonce = 'nonce-xx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

                String timeStamp = Datetime.now().formatGMT(connector.Time_format__c)+'+0000';
                //timeStamp = '20140321T19:34:21+0000';


                // The signing key is computed as the base64 encoding of the SHA–256 HMAC of the timestamp string (the field value included in the HTTP authorization header described above) with the client secret as the key.


                Blob signingKeyBytes = crypto.generateMac(connector.Crypto_Algorithm__c,Blob.valueOf(timeStamp), Blob.valueOf(connector.Client_Secret__c));

                String signingKey= EncodingUtil.base64Encode(signingKeyBytes);

                /*
                   the data to sign is comprised of the request data combined with the authorization header value (excluding the signature field, but including the ; right before the signature field).

                   Request data fields:


                   {0} Request method (GET/PUT etc.) in upper case
                   {1} Scheme (http/https) in lower case
                   {1} Host from the Host header in lower case
                   {1} Relative URL that contains the path and query portions of the URL, exactly as it appears in the HTTP request line
                   {2} Canonicalized request headers
                   {3} Content hash of the request body for POST requests

                   /identity-management/v1/open-identities/z63477vy2tu5tgmh/account-switch-keys?search=IBM Global Services
                   https://akaa-ktv4je2sztj3vycw-b55buy6nl4ks6zqc.luna-dev.akamaiapis.net/identity-management/v1/open-identities/z63477vy2tu5tgmh/account-switch-keys?search=IBM
                   GET\thttps\takaa-ktv4je2sztj3vycw-b55buy6nl4ks6zqc.luna-dev.akamaiapis.net\t/identity-management/v1/open-identities/z63477vy2tu5tgmh/account-switch-keys?search=IBM

                   FOr testing - https://github.com/akamai/AkamaiOPEN-edgegrid-node/blob/30f4af19e92a233f95a36faa8a788452eaa63232/test/test_data.json

                 */

                String requestEndPoint = req.getEndpoint();

                if(requestEndPoint.startsWith('callout'))
                {
                        // is a named crendetial
                        String namedCredentialDeveloperName = requestEndPoint.substringBefore('/').substringAfter(':');
                        System.Debug('namedCredentialDeveloperName: ' + namedCredentialDeveloperName);

                        NamedCredential nc= [select Endpoint from NamedCredential where Developername=:namedCredentialDeveloperName];
                        requestEndPoint = nc.Endpoint +'/'+ requestEndPoint.substringAfter('/');

                }

                Url fullUrl = new Url(requestEndPoint);
                String urlPathWithQueryParams= fullUrl.getPath();

                if(fullUrl.getQuery() != null)
                        urlPathWithQueryParams = urlPathWithQueryParams +'?'+ fullUrl.getQuery();



                /*
                   String strToSign = String.format(
                   '{0}\t{1}\t{2}\t{3}\t\t\t{3} client_token={4};access_token={5};timestamp={6};nonce={7};',
                   new List<String>{
                    req.getMethod(),
                    tabSeparatedEndpoint,
                    connector.Moniker__c,
                    connector.Client_Token__c,
                    connector.Access_Token__c,
                    timestamp,
                    nonce
                   }
                   );
                   String hexValueOfBody = EncodingUtil.convertToHex(req.getBodyAsBlob());

                   if(hexValueOfBody.length()>262144)
                   trimmedSignature = hexValueOfBody.substring(0,262144);
                   else
                   trimmedSignature = hexValueOfBody;
                 */




                String strToSign = 'REQ_METHOD\tCONNECTION_SCHEME\tHOST\tURL_PATH\t\tCONTENT_HASH_OF_POST_BODY\tAUTH_HEADER_WITHOUT_SIGNATURE';
                Blob bodyAsBlb = req.getBodyAsBlob();

                String postBodyHash = (req.getMethod() == 'POST' && !String.isEmpty(req.getBody())) ? EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', bodyAsBlb)) : '';
                String authHeaderWithoutSignature = String.format(
                        '{0} client_token={1};access_token={2};timestamp={3};nonce={4};',
                        new List<String>{
                        connector.Moniker__c,
                        connector.Client_Token__c,
                        connector.Access_Token__c,
                        timestamp,
                        nonce
                }
                        );

                strToSign = strToSign.replace('REQ_METHOD', req.getMethod())
                            .replace('CONNECTION_SCHEME', fullUrl.getProtocol())
                            .replace('HOST', connector.Host__c)
                            .replace('URL_PATH', urlPathWithQueryParams)
                            .replace('CONTENT_HASH_OF_POST_BODY', postBodyHash)
                            .replace('AUTH_HEADER_WITHOUT_SIGNATURE', authHeaderWithoutSignature);



                Blob signatureBytes = crypto.generateMac(connector.Crypto_Algorithm__c, Blob.valueOf(strToSign), Blob.valueOf(signingKey));
                String signature = EncodingUtil.base64Encode(signatureBytes);

                /*
                   Authorization:EG1-HMAC-SHA256 client_token=akaa-xxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxx;
                   access_token=akaa-xxxxxxxxxxxxxx-xxxxxxxxxxxxxx;timestamp=20130817T02:49:13+0000;
                   nonce=dd9957e2-4fe5-48ca-8d32-16a772ac6d8f;signature=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

                   The signature is the base64-encoding of the SHA–256 HMAC of the data to sign with the signing key.



                 */


                String authHeader = authHeaderWithoutSignature + 'signature='+ signature;

                req.setHeader('Authorization', authHeader);
                req.setHeader('Host', connector.Host__c);
                return req;
        }


}