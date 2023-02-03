/**

    13/Aug/2014     CR 2723520 - Changing the logic of Threshold case creation so that even if a final invoice is not present,draft invoice
                                 threshold case should be created. Also capturing both Previous Month Final and Current Month Draft Threshold
                                 violation separately through hasFinalThresholdViolation and hasDraftThresholdViolation
    03/Apr/2017  CR 3619951 - IR Case Generation for Contracts
*/
public without sharing class IRCaseWrapper
{
    public Id contractId {get; set;}
    public Case associatedCase {get; set;}
    public Draft_Invoice__c associatedDraftInvoice {get; set;}
    public String description {get; set;}
    public Boolean toUpdateInsert {get; set;}
    public Boolean isExisting {get; set;}
    public Boolean isManualInvoice {get; set;}
    public Boolean isMissingInFinalInv {get; set;}
    public Boolean isMissingInLastMonthInv {get; set;}
    public Boolean isMissingInDInv {get; set;}
    public Boolean isNewDInv {get; set;}
    public Boolean hasDoubleInvoiceReview {get; set;}
    public Boolean isAdHocManual {get; set;}
    public Boolean hasPaperChange {get; set;}
    public Boolean hasFinalThresholdViolation {get; set;}
    public Boolean hasDraftThresholdViolation {get; set;}//CR 2723520
    public Id ircaseOwnerId {get; set;}
    public Id ircaseEscalOwnerId {get; set;}
    public String akamOpportunityId {get; set;}
    public Date acceptanceDate {get; set;}
    public Boolean hasDataErrors {get; set;}
    public Boolean hasUpsertErrors {get; set;}
    public String alertType {get; set;}

    public IRCaseWrapper()
    {
        this.contractId=null;
        this.associatedCase=null;
        this.associatedDraftInvoice=null;
        this.description='';
        this.toUpdateInsert=false;
        this.isExisting=false;
        this.isManualInvoice=false;
        this.isMissingInFinalInv=false;
        this.isMissingInDInv=false;
        this.isNewDInv=false;
        this.hasDoubleInvoiceReview=false;
        this.isAdHocManual=false;
        this.hasPaperChange=false;
        this.hasFinalThresholdViolation=false;
        this.hasDraftThresholdViolation=false;//CR 2723520
        this.ircaseOwnerId=null;
        this.ircaseEscalOwnerId=null;
        this.akamOpportunityId='';
        //this.acceptanceDate;
        this.hasDataErrors=false;
        this.hasUpsertErrors=false;
        this.isMissingInLastMonthInv=false; //CR 3619951
        this.alertType = null;
    }

    public IRCaseWrapper(Id pContractId,Case pAssociatedCase,Boolean pIsExisting)
        {
            this.contractId=pContractId;
            this.associatedCase=pAssociatedCase;
            this.associatedDraftInvoice=null;
            this.description=null;
            this.toUpdateInsert=false;
            this.isExisting=pIsExisting;
            this.isManualInvoice=false;
            this.isMissingInFinalInv=false;
            this.isMissingInDInv=false;
            this.isNewDInv=false;
            this.hasDoubleInvoiceReview=false;
            this.isAdHocManual=false;
            this.hasPaperChange=false;
            this.hasFinalThresholdViolation=false;
            this.hasDraftThresholdViolation=false;//CR 2723520
            this.ircaseOwnerId=null;
            this.ircaseEscalOwnerId=null;
            this.akamOpportunityId=null;
            this.acceptanceDate=null;
            this.hasDataErrors=false;
            this.hasUpsertErrors=false;
            this.isMissingInLastMonthInv=false; //CR 3619951
            this.alertType = null;
        }

    public IRCaseWrapper(Id pContractId,Case pAssociatedCase,Draft_Invoice__c pAssociatedDraftInvoice,String pDescription,Boolean pToUpdateInsert,Boolean pIsExisting,Boolean pIsManualInvoice,Boolean pIsMissingInFinalInv,
        Boolean pIsMissingInDInv,Boolean pIsNewDInv,
        Boolean pHasDoubleInvoiceReview,Boolean pIsAdHocManual,Boolean pHasPaperChange,
        Boolean pHasFinalThresholdViolation,Boolean pHasDraftThresholdViolation,
        Id pIrcaseOwnerId,Id pIrcaseEscalOwnerId,String pAkamOpportunityId,
        Date pAcceptanceDate,Boolean pHasDataErrors,Boolean pHasUpsertErrors,Boolean pIsMissingInvLastMonth,String pAlertType)
        {
            this.contractId=pContractId;
            this.associatedCase=pAssociatedCase;
            this.associatedDraftInvoice=pAssociatedDraftInvoice;
            this.description=pDescription;
            this.toUpdateInsert=pToUpdateInsert;
            this.isExisting=pIsExisting;
            this.isManualInvoice=pIsManualInvoice;
            this.isMissingInFinalInv=pIsMissingInFinalInv;
            this.isMissingInDInv=pIsMissingInDInv;
            this.isNewDInv=pIsNewDInv;
            this.hasDoubleInvoiceReview=pHasDoubleInvoiceReview;
            this.isAdHocManual=pIsAdHocManual;
            this.hasPaperChange=pHasPaperChange;
            this.hasFinalThresholdViolation=pHasFinalThresholdViolation;
            this.hasDraftThresholdViolation=pHasDraftThresholdViolation;//CR 2723520
            this.ircaseOwnerId=pIrcaseOwnerId;
            this.ircaseEscalOwnerId=pIrcaseEscalOwnerId;
            this.akamOpportunityId=pAkamOpportunityId;
            this.acceptanceDate=pAcceptanceDate;
            this.hasDataErrors=pHasDataErrors;
            this.hasUpsertErrors=pHasUpsertErrors;
            this.isMissingInLastMonthInv=pIsMissingInvLastMonth; //CR 3619951
            this.alertType = pAlertType;
        }
}