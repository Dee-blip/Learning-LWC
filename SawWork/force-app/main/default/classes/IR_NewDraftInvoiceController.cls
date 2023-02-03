public class IR_NewDraftInvoiceController {

    @AuraEnabled
    public static Draft_Invoice__c getDefaults(Id relatedContractId){
        Draft_Invoice__c di = new Draft_Invoice__c();
        Case cs=null;
        String invoiceNumber = GsmUtilClass.GetCustomSettingValue('IRCase_DefaultInvoiceNumber'); //'N/A';
        Date invoiceDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();
        cs=IRCaseHelperClass.getExistingIRCase(relatedContractId,invoiceDate);
        if (cs==null || cs.IR_Invoice_Number__c==null){
        	di = IRCaseHelperClass.getExistingDraftInvoice(relatedContractId,invoiceDate);
        }

        if (cs!=null && cs.IR_Invoice_Number__c!=null){
            di.Name = cs.IR_Invoice_Number__c!=null ? cs.IR_Invoice_Number__c : invoiceNumber;
            di.Invoice_Date__c = cs.IR_Invoice_Date__c;
        }
        else if (di==null)
        {
            di = new Draft_Invoice__c();
            di.Name = invoiceNumber;
            di.Invoice_Date__c = invoiceDate;
        }
        di.Original_Contract_Id__c  = relatedContractId;
		return di;
    }
}