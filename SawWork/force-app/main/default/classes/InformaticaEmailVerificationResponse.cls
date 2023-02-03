/***
    InformaticaEmailVerificationResponse
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : 
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          15/05/2015        Created the class.
***/
public class InformaticaEmailVerificationResponse {

    public class WebServiceResponse {
        public SubscriptionInfo SubscriptionInfo;
        public VerifyEmailResponse VerifyEmailResponse;
    }

    public class VerifyEmailResponse {
        public VerifyEmailResult VerifyEmailResult;
    }

    public WebServiceResponse WebServiceResponse;

    /*public class StringKeyValuePair {
        public String Key;
        public String Value;
    }*/

    public class ServiceResult {
        public Reason Reason;
        public String HygieneResult;
        public String NetProtected;
        //public Object NetProtectedBy;
        public String SourceIdentifier;
        public String Email;
        public String LocalPart;
        public String DomainPart;
        //public String IronStandardCertifiedTimestamp;
        //public Object DomainKnowledge;
        //public AddressKnowledge AddressKnowledge;
    }

    /*public class AddressKnowledge {
        public StringKeyValuePair StringKeyValuePair;
    }*/

    public class SubscriptionInfo {
        public String LicenseStatusCode;
        public String LicenseStatus;
        public String LicenseActionCode;
        public String LicenseAction;
        public String RemainingHits;
        public String Amount;
    }

    public class VerifyEmailResult {
        public ServiceStatus ServiceStatus;
        public ServiceResult ServiceResult;
    }

    public class Reason {
        public String Code;
        public String Description;
    }

    public class ServiceStatus {
        public String StatusNbr;
        public String StatusDescription;
    }

    
    public static InformaticaEmailVerificationResponse parse(String json) {
        return (InformaticaEmailVerificationResponse) System.JSON.deserialize(json, InformaticaEmailVerificationResponse.class);
    }
    
    
}