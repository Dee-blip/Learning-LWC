/**
DraftInvoiceTriggerClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class handles auto-populating of Draft Invoice fields like Invoice Number.
                
    @History
    --Developer           --Date            --Change
	Ali IM				24/04/2013		Created the class   
										CR 2175581 - IR Case - For Ad hoc Manual Draft Invoices, auto-populate the Invoice number.										
										- Auto-populate Invoice Number for Ad-hoc Case creation.
	Ali KM				 13/05/2013		CR 2219258 - IR Case - Update the logic for Invoice Date defaulting for Ad-hoc IR Case creation 
										- Calculating the Invoice Review Date based on: Last successfull IRCAudit record, if not found then based on cut-off DayOfMonth.										
*/	 
public class DraftInvoiceCreateNew 
{
	public DraftInvoiceCreateNew(){}
	public DraftInvoiceCreateNew(ApexPages.StandardController controller){}
	
	public Pagereference pageRedirect()
	{
		String Prefix =  Schema.Sobjecttype.Draft_Invoice__c.getKeyPrefix();
		PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');

		Id relatedContractId=ApexPages.currentPage().getParameters().get('CF00NG0000009avbL_lkid');
		System.debug('CF00NA0000000saFf_lkid Key Value=' + relatedContractId);

		String invoiceNumber = GsmUtilClass.GetCustomSettingValue('IRCase_DefaultInvoiceNumber'); //'N/A';
     	Date invoiceDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();
     	Case cs=null;
     	Draft_Invoice__c di=null;
     	
     	if (relatedContractId!=null)
     	{	
     		cs=IRCaseHelperClass.getExistingIRCase(relatedContractId,invoiceDate);
     		if (cs==null || cs.IR_Invoice_Number__c==null)
     			di = IRCaseHelperClass.getExistingDraftInvoice(relatedContractId,invoiceDate);
     			
	     	System.debug('invoiceDate=' + invoiceDate);
	     	System.debug('cs=' + cs);
	     	System.debug('di=' + di);
     	
	     	if (cs!=null && cs.IR_Invoice_Number__c!=null)
	     	{ 
	     		di = new Draft_Invoice__c();
	     		di.Name = cs.IR_Invoice_Number__c!=null ? cs.IR_Invoice_Number__c : invoiceNumber;
	     		di.Invoice_Date__c = cs.IR_Invoice_Date__c;
	     	}
     		else if (di==null)
     		{
     			di = new Draft_Invoice__c();
     			di.Name = invoiceNumber;
     			di.Invoice_Date__c = invoiceDate;	
	     	}
     		
     		//di.Name = IRCaseHelperClass.getEncodedString(di.Name);
     		System.debug('di FINAL=' + di);
     	}
     	
		for(string key:ApexPages.currentPage().getParameters().keySet())
		{
			returnURL.getParameters().put(key, ApexPages.currentPage().getParameters().get(key));
		}
		returnURL.getParameters().remove('save_new');
		returnURL.getParameters().put('nooverride', '1');
		
		if(di!=null)
			returnURL.getParameters().put('Name',di.Name);
		
		returnURL.setRedirect(true);
		return returnURL;
	}
}