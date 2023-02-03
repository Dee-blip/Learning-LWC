public class createViewOrderFormController {
	public static Id recordId {get; set;}
	public static String akamId {get; set;}
    public static String stageName {get; set;}
    public static String getField {get; set;}
    public static Id recordTypeId {get; set;}
	public static String dealType;
    public static String buyAkamaiRedirectionURL {get; set;}
    public static String theme {get; set;}
    public static String orderApprovalId {get; set;}
    public static String FromObject;
	PageReference pageRef;

	public PageReference redirectBuyAkamaiorMomentum() {
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        theme = GSMLite_UtilClass.getUIThemeDescription();
        orderApprovalId = ApexPages.currentPage().getParameters().get('orderApprovalId');
        FromObject = ApexPages.currentPage().getParameters().get('FromObject');
        getField = ApexPages.currentPage().getParameters().get('getField');
        if(recordId != null){
            system.debug('Record Id = '+recordId);
            if(FromObject == 'Case' ){
                Opportunity opp = [Select id, StageName, AKAM_Opportunity_ID__c, RecordTypeId, Deal_Type__c from Opportunity where id =:recordId][0];
                recordTypeId = opp.RecordTypeId;
                stageName = opp.StageName;
                akamId = opp.AKAM_Opportunity_ID__c;
                dealType = opp.Deal_Type__c;
            }
            else
            {
                recordTypeId    = ApexPages.currentPage().getParameters().get('recordTypeId');
                stageName       = ApexPages.currentPage().getParameters().get('stageName');
                akamId          = ApexPages.currentPage().getParameters().get('akamId');
                dealType        = ApexPages.currentPage().getParameters().get('dealType');
            }

            String accessUserIds = GSMSettings.getVerbose('BuyAkamai_CreateOrderFormUserIds');
            if(!accessUserIds.containsIgnoreCase(String.valueOf(UserInfo.getUserId()).substring(0, 15))) {
                pageRef = createViewOrderForm();
                return pageRef;    
            }
            else {
                buyAkamaiRedirectionURL = GsmUtilClass.getGSMSettingValue('BuyAkamai_redirectionURLOpportunity')
                                    .replaceAll('##AKAM_Opportunity_ID__c##',  akamId)
                                    .replaceAll('##Deal_Type__c##', dealType);
            }
        }
        return null;
    }

	public PageReference createViewOrderForm()
    {
        String result;

        try {
            result = OrderApprovalClass.Create_OrderApproval(recordId,recordTypeId,stageName,getField);
        }

        catch(Exception err) {
        	String myRegExp = 'INSUFFICIENT_ACCESS';
            String errString = err+'';
            if(errString.contains(myRegExp) != true)
                result = '0:You do not have sufficient access to create an Order Approval.';
            else
                result = '0:An unexpected error has occurred. Please contact your System Administrator\n\n' + 'Error : ' + err;
        }
        String resultFlag = result.substring(0, result.indexOf(':'));
        String resultMessage = result.substring(result.indexOf(':') + 1, result.length());
        system.debug('result Message = '+resultMessage);

        if(resultFlag == '1') {
            pageRef = new PageReference(resultMessage);
            pageRef.setRedirect(true);

            List<Order_Approval__c> oaList = [select Id, Associated_Opportunity__r.Id, Associated_Opportunity__r.Momentum_Order_Form_Initiated__c, Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c from Order_Approval__c where Associated_Opportunity__c = :recordId];

            System.debug('Order Approval : ' + oaList);

            OpportunityButtonPageController.updateMomentumFields(oaList);

            resultFlag = '';
            return pageRef;
        }

        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, resultMessage));
            return null;
        }
    }
    
    @AuraEnabled
    public static Map<String, String> getBuyAkamaiOrderFormProducts() {
    	Map<String, String> mapOfProductVsAccountType = new Map<String, String>();
        String productNameVsAccountTypeJSON = GSMSettings.getVerbose('BuyAkamai_ProductNameAccountTypeJSON');
        mapOfProductVsAccountType = (Map<String, String>)JSON.deserialize(productNameVsAccountTypeJSON, Map<String, String>.Class);
        return mapOfProductVsAccountType;
	}
	
    /*@AuraEnabled
    public static String getBuyAkamaiRedirectURL() {
        String redirectionURL;
        redirectionURL = GsmUtilClass.getGSMSettingValue('BuyAkamai_redirectionURLOpportunity');
        redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLOpportunity')
                                .replaceAll('##AKAM_Opportunity_ID__c##',  oppty.AKAM_Opportunity_ID__c)
                                .replaceAll('##Deal_Type__c##', oppty.Deal_Type__c);
        return redirectionURL;
    }*/
    
    @AuraEnabled
    public static string getMomentumURL(String opportunityId, Id recordTypeId, String stageName, String getField) {
        String result;
        try {
        	result = OrderApprovalClass.Create_OrderApproval(opportunityId,recordTypeId,stageName,getField);
        }
		catch(Exception err) {
        	String myRegExp = 'INSUFFICIENT_ACCESS';
            String errString = err+'';
            if(errString.contains(myRegExp) != true)
            	result = '0:You do not have sufficient access to create an Order Approval.';
            else
                result = '0:An unexpected error has occurred. Please contact your System Administrator\n\n' + 'Error : ' + err;
        }
        String resultFlag = result.substring(0, result.indexOf(':'));
        String resultMessage = result.substring(result.indexOf(':') + 1, result.length());
        if(resultFlag == '1') {
            List<Order_Approval__c> oaList = [select Id, Associated_Opportunity__r.Id, 
                                              Associated_Opportunity__r.Momentum_Order_Form_Initiated__c, 
                                              Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c 
                                              from Order_Approval__c where Associated_Opportunity__c = :opportunityId];
			System.debug('Order Approval : ' + oaList);
			OpportunityButtonPageController.updateMomentumFields(oaList);
        }
        return resultMessage;
    }
}