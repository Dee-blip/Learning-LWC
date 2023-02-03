public class OrderApprovalButtonPageController
{
	PageReference pageRef;

	public static Id recordId;
	public static String formUrl;
    public static Boolean orderExpiry {get; set;}
    public static Boolean eSignatureError {get; set;}
    public static String eSignOverride;
    public static String accountPrimaryCountry;
    public static String OrderExpiryDate;

	public PageReference init()
    {
    	String fromButton;

    	fromButton            = ApexPages.currentPage().getParameters().get('fromButton');
    	recordId              = ApexPages.currentPage().getParameters().get('recordId');
    	formUrl               = ApexPages.currentPage().getParameters().get('formUrl');
        eSignOverride         = ApexPages.currentPage().getParameters().get('eSignOverride');
        accountPrimaryCountry = ApexPages.currentPage().getParameters().get('accountPrimaryCountry');
        OrderExpiryDate       = ApexPages.currentPage().getParameters().get('orderExpiryDate');

    	if(!String.isBlank(fromButton))
    	{
    		if(fromButton == 'CreateViewOrderForm')
    		{
                pageRef = createViewOrderForm();
                return pageRef;
            }
            
            if(fromButton == 'SendForESignature') {
                pageRef = sendForESignature();
                return pageRef;
            }
    	}

        return null;
    }

    public PageReference createViewOrderForm()
    {
    	List<Order_Approval__c> oaList = [select Id, Associated_Opportunity__r.Id, Associated_Opportunity__r.Momentum_Order_Form_Initiated__c, Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c from Order_Approval__c where Id = :recordId];
    	
    	OpportunityButtonPageController.updateMomentumFields(oaList);

    	String link = Momentum_Link__c.getInstance('Production').Link__c+formUrl;
    	pageRef = new PageReference(link);
    	pageRef.setRedirect(true);
    	return pageRef;
    }
    
    public PageReference sendForESignature(){
        String result;
        String countries1,countries2;
        Order_Approval__c orderApp = [Select Id,Order_Expires_Unless_Duly_Executed_By__c from Order_Approval__c 
                           where Id = :(Id)recordId];
        Q2O_DocuSignCountries__c docusignCountries = Q2O_DocuSignCountries__c.getInstance();
        countries1 = docusignCountries.countries1__c;
        countries2 = docusignCountries.countries2__c;
        
        if(eSignOverride == '1' || countries1.contains(accountPrimaryCountry) || 
           countries2.contains(accountPrimaryCountry)) {
               if(orderApp.Order_Expires_Unless_Duly_Executed_By__c < Date.today()) {
                    orderExpiry = true;
                    return null;
               }
               else {
                pageRef = new PageReference('/apex/ESign_Intermediate?id='+(Id)recordId);   
                return pageRef;     
               }
            
        } else {
            eSignatureError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                                                       System.Label.Send_for_E_Signature_Error + ' '
                                                       +accountPrimaryCountry));
            return null;       
        }
    }
    
    public PageReference orderExpiryConfirmed(){
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        return new PageReference('/apex/ESign_Intermediate?id='+(Id)recordId);
    }
    
    public PageReference orderExpiryRejected(){
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        return new PageReference('/'+(Id)recordId);
    }
}