global without sharing class AMI_UserDetailResponse {
    public String companyName{get; set;}
    
    public String givenName {get; set;}
    public String displayName{get;set;}
    public String surname{get;set;}
    
    public String jobTitle {get; set;}
    public List<String> businessPhones{get;set;}
    public String mobilePhone {get;set;}

    public String streetAddress {get; set;}
    public String city {get; set;}
    public String state {get; set;}
    public String country {get; set;}
    public String postalCode {get; set;}

    //fields from AMI_SaasSubscriberDetailsModel
    public String emailId { get; set; }
    public String objectId { get; set; }
    public String tenantId { get; set; }
    public String puid { get; set; }
}