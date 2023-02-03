/***
    InformaticaPhoneVerificationResponse
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : 
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          25/05/2015        Created the class.
***/
public class InformaticaPhoneVerificationResponse {

    public class ZipInfo {
        public String ZipCode;
        public String ZipCodeCount;
        public String ZipCodeFrequency;
    }
    
    public WebServiceResponse WebServiceResponse;

    public class WebServiceResponse {
        //public String @xmlns;
        public SubscriptionInfo SubscriptionInfo;
        public ValidateNumberISOResponse ValidateNumberISOResponse;
    }
    
    public class SubscriptionInfo {
        //public String @xmlns;
        public String LicenseStatusCode;
        public String LicenseStatus;
        public String LicenseActionCode;
        public String LicenseAction;
        public String RemainingHits;
        public String Amount;
    }
    
    public class ValidateNumberISOResponse {
        //public String @xmlns;
        public ValidateNumberISOResult ValidateNumberISOResult;
    }
    
    public class ValidateNumberISOResult {
        public ServiceStatus ServiceStatus;
        public ServiceResult ServiceResult;
    }

    public class ServiceStatus {
        public String StatusNbr;
        public String StatusDescription;
    }
    
    public class ServiceResult {
        public Results Results;
    }

    public class ZipCodes {
        public List<ZipInfo> ZipInfo;
    }

    public class Results {
        public GlobalPhoneEntryWithStatus GlobalPhoneEntryWithStatus;
    }
    
    public class GlobalPhoneEntryWithStatus {
        public ItemStatus ItemStatus;
        public Listing Listing;
    }
    
    public class ItemStatus {
        public String StatusNbr;    //201
        public String StatusDescription;    //Valid Number
    }
    
    public class Listing {
        //public String Number; 
        public String CountryCode;  
        public String InternationalPrefix;  
        public String NationalPrefix;   
        public CellPrefix CellPrefix;
        public String NDC;  
        public String SN_From;  
        public String SN_To;    
        public String Uses_NDC; 
        public String Number_Type;  
        public String CarrierName;  
        public String Language; 
        public String Country;  
        public String ISO;  
        public String RegionCode;   
        public String RegionName;   
        public String City; 
        public String TimeZone; 
        public String UTC;  
        public String DST;  
        public String Latitude; 
        public String Longitude;    
        public String ErrorCode;    
    }
    
    public class CellPrefix {
    }
    
    public static InformaticaPhoneVerificationResponse parse(String json) {
        return (InformaticaPhoneVerificationResponse) System.JSON.deserialize(json, InformaticaPhoneVerificationResponse.class);
    }
}