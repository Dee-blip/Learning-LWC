/**
InvoiceReviewCaseWrapper
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class is wrapper for processing IR Cases. 

	@History
	--Developer		      --Date			--Change
	Ali KM		     	  06/02/2013		Created the class
	Ankit				06/04/2017			Removed unused constructors to improve code coverage InvoiceReviewCaseWrapper() and InvoiceReviewCaseWrapper(Case pAssociatedCase, Boolean pIsExisting)
											CR 3713022
*/public without sharing class InvoiceReviewCaseWrapper
{
	public Case associatedCase {get; set;}
	public Draft_Invoice__c associatedDraftInvoice {get; set;}
	public Draft_Invoice__c associatedLastImportDI {get; set;}
	public String description {get; set;}
	public Boolean toUpdateInsert {get; set;}
	public Boolean isExisting {get; set;}
	public Boolean isManualInvoice {get; set;}
	public Boolean isMissingInvoice {get; set;}
	public Boolean hasDoubleInvoiceReview {get; set;}
	public Boolean isAdHocManual {get; set;}
	public Id contractId {get; set;}
	public Id ircaseOwnerId {get; set;}
	public Id ircaseEscalOwnerId {get; set;}
	public Boolean hasDataErrors {get; set;}
	public Boolean hasUpsertErrors {get; set;}
	public Boolean hasFinalThresholdViolation {get; set;}
	public Boolean hasDraftThresholdViolation {get; set;}

	public InvoiceReviewCaseWrapper(Case pAssociatedCase, Draft_Invoice__c pAssociatedDraftInvoice, Draft_Invoice__c pAssociatedLastImportDI, String pDescription, Boolean pToUpdateInsert,
		Boolean pIsExisting, Boolean pIsManualInvoice, Boolean pHasDoubleInvoiceReview, Boolean pIsMissingInvoice, Id pContractId, Id pIrcaseOwnerId, Id pIrcaseEscalOwnerId, Boolean pHasDataErrors, Boolean pHasUpsertErrors, Boolean pIsAdHocManual, Boolean pHasFinalThresholdViolation,Boolean pHasDraftThresholdViolation)
		{
			associatedCase= new Case();
			associatedDraftInvoice= pAssociatedDraftInvoice;
			associatedLastImportDI= pAssociatedLastImportDI;
			description = pDescription;
			toUpdateInsert = pToUpdateInsert;
			isExisting = false;
			isManualInvoice = pIsManualInvoice;
			hasDoubleInvoiceReview = pHasDoubleInvoiceReview;
			isMissingInvoice = pIsMissingInvoice;
			contractId = pContractId;
			ircaseOwnerId = pIrcaseOwnerId;
			ircaseEscalOwnerId = pIrcaseEscalOwnerId;
			hasDataErrors = pHasDataErrors;
			hasUpsertErrors= pHasUpsertErrors;
			isAdHocManual=pIsAdHocManual;
			hasFinalThresholdViolation = pHasFinalThresholdViolation;
			hasDraftThresholdViolation = pHasDraftThresholdViolation;
		}

		public InvoiceReviewCaseWrapper(){
			this.hasFinalThresholdViolation=false;
			this.hasDraftThresholdViolation=false;
		}
	 public InvoiceReviewCaseWrapper(Case pAssociatedCase, Draft_Invoice__c pAssociatedDraftInvoice, String pDescription, Boolean pToUpdateInsert,
        Boolean pIsExisting, Id pContractId, Id pIrcaseOwnerId, Boolean pIsAdHocManual)
        {
            associatedCase= pAssociatedCase;
            associatedDraftInvoice= pAssociatedDraftInvoice;
            //associatedLastImportDI= pAssociatedLastImportDI;
            description = pDescription;
            toUpdateInsert = pToUpdateInsert;
            isExisting = true;
            //isManualInvoice = pIsManualInvoice;
            //hasDoubleInvoiceReview = pHasDoubleInvoiceReview;
            //isMissingInvoice = pIsMissingInvoice;
            contractId = pContractId;
            ircaseOwnerId = pIrcaseOwnerId;
            //ircaseEscalOwnerId = pIrcaseEscalOwnerId;
            //hasDataErrors = pHasDataErrors;
            //hasUpsertErrors= pHasUpsertErrors;
            isAdHocManual=pIsAdHocManual;
        }
}