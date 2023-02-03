global without sharing class AMI_SaasSubscriptionResponse {
    public String id { get; set; }
    public String publisherId { get; set; }
    public String offerId { get; set; }
    public String name { get; set; }
    public String saasSubscriptionStatus { get; set; }
    public String planId { get; set; }
    public String sessionId { get; set; }
    public String fulfillmentId { get; set; }
    public AMI_SaasSubscriberDetailsModel beneficiary { get; set; }
    public AMI_SaasSubscriberDetailsModel purchaser { get; set; }
    public AMI_TermResponseModel term {get;set;}
    public Boolean isFreeTrial {get;set;}
}