/*
* Object: SBQQ__Quote__c
* Details : Class for Advance Approval submit and recall functionality on CPQ quote object
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial logic to implement submit and recall functionality
* kimishra			09/16/2019		1.1			primary quote and OA validation logic added
* kimishra          10/12/2019      1.2         SBQQ__Primary field replaced by CPQ_Primary__c
* kimishra          06/03/2020      1.3         AuraEnabled onRecall and onSubmit methods added
* kimishra          17-JUN-20       1.4         checkCPQPermission method to check logged in user CPQ custom permission
* 
*/
public class QuoteExtController {
    private SBQQ__Quote__c record { get; private set; }
    private Id quoteId;
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        
        //logic added for OA validation
        List<String> fields = new List<String> { 'CPQ_Order_Approval__c', 'CPQ_Primary__c','SBQQ__Opportunity2__c' };
            if (!Test.isRunningTest()) stdController.addFields(fields);
        record = (SBQQ__Quote__c)stdController.getRecord();

    }
    public PageReference onSubmit() {
        if (quoteId != null) {

            boolean status = !(String.isBlank(record.CPQ_Order_Approval__c));

            // OA link check
            if(!status){
               status = CPQ_UtilityClass.UpdateTheQuoteLookup(record);
               system.debug('Order Approval record exists? : ' + status);
            }
            //primary quote validation
            if(!record.CPQ_Primary__c) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.CPQ_Approval_applicable_for_primary_quotes));
                return null;
            } 
            //Order Approval on Opportunity validation
            else if (!status) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,System.Label.CPQ_Approval_applicable_for_quotes_with_Order_Approval));
                return null;
            } 
            else {
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
            }
        }
        return new PageReference('/' + quoteId);
    }
    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
    
    //method to recall quote approval from aura component [CPQ-256  kimishra    06/03/2020]
    @AuraEnabled
	public static void onRecall(Id quoteId) {
		if (quoteId != null) {
			SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
		}
	}
    
    //method to submit quote approval from aura component [CPQ-256  kimishra    06/03/2020]
    @AuraEnabled
	public static void onSubmit(Id quoteId) {
		if (quoteId != null) {
			SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
		}
	}

    //method to check CPQ_Permission custom permission of logged in user  [CPQ-262  kimishra    17-JUN-20]
    @AuraEnabled
    public static boolean checkCPQPermission(String customPermissionApiName){
        return FeatureManagement.checkPermission(customPermissionApiName);
    }

    //method to check validity of the partner quote before placing an order  [CPQ-312  kimishra    15-SEP-20]
    @AuraEnabled
    public static boolean checkQuoteValidityForOrder(String quoteId){
        System.debug('quote id from checkQuoteValidityForOrder: '+quoteId);
        Boolean showOrderButton = false;
        SBQQ__Quote__c quote = [SELECT SBQQ__Status__c,
                                        CPQ_Primary__c,
                                        CPQ_CustomerType__c
                                        FROM SBQQ__Quote__c
                                        WHERE Id = :quoteId];
        
        //check custom setting if PAC is under maintenance

        if (quote.SBQQ__Status__c != 'Order Accepted' && quote.CPQ_CustomerType__c != 'Existing Customer') {
            showOrderButton = true;
        }

        return showOrderButton;
    }
    
}