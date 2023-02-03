public without sharing class EditFundClaimController {
    
    private ApexPages.StandardController sc;
    private SFDC_MDF_Claim__c fundClaim;
    public String fundClaimId {get; set;}
    public String fundClaimSpender {get; set;}
    public String linkUrl {get; set;}
    

    public EditFundClaimController(ApexPages.StandardController sc) {
        this.sc = sc;
        fundClaim = (SFDC_MDF_Claim__c) sc.getRecord();
        fundClaimId = fundClaim.id;
        fundClaim = [Select id,Fund_Claim_Activity_Spender__c  from SFDC_MDF_Claim__c where id=:fundClaimId];
        fundClaimSpender = fundClaim.Fund_Claim_Activity_Spender__c;
        
        String baseURL = ApexPages.currentPage().getHeaders().get('Host');
        linkUrl = 'https://' + baseURL + '/' + fundClaimId;
    }
}