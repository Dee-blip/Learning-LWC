/**
DraftInvoiceTriggerClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class is used to handle all triggers for Draft_invoice object.
                
    @History
    --Developer           --Date            --Change
    Ali KM                06/02/2013        Created the class   
                                            CR 2068273 - Invoice Review Cases Process migration from Siebel to SF. 
	Ali KM				 24/04/2013			CR 2181044 - IR Case - For Ad-Hoc DraftInvoice/Case creation change
												- Updated the Ad-Hoc Case creation to kick-in Without Attachments as well.
	Ali KM				 24/04/2013			CR 2175590 - IR Case - Remove fields from New Draft Page.								
												- if Invoice Date is empty, defaulting it based on following logic: 
												 -> If today() <5th of Current Month; Invoice Date = 1st of current month.
 												 -> If today() >5th of Current Month, Invoice Date = 1st of next month.
	Ali KM				 13/05/2013			CR 2219258 - IR Case - Update the logic for Invoice Date defaulting for Ad-hoc IR Case creation 
												-> changed logic to default Invoice Date from 5th to 20th of Month (Custom Setting) 												 
*/
public without sharing class DraftInvoiceTriggerClass 
{
    public static void beforeInsertUpdate(Boolean isInsert, Draft_Invoice__c[] oldDraftInvoices,Draft_Invoice__c[] newDraftInvoices, Map<Id, Draft_Invoice__c> oldMap, Map<Id, Draft_Invoice__c> newMap) 
    {   
        List<Draft_Invoice__c> draftInvoiceContractResolvebyCIList = new List<Draft_Invoice__c>();
        List<Draft_Invoice__c> draftInvoiceContractResolvebyMCHList = new List<Draft_Invoice__c>(); 
        for(Draft_Invoice__c draftInvoice : newDraftInvoices)
        {   
            if (isInsert)
            {
            	if (draftInvoice.Invoice_Date__c==null)
	                draftInvoice.Invoice_Date__c = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate(draftInvoice.Name);
	            if (draftInvoice.Due_Date__c==null)
	                draftInvoice.Due_Date__c = (draftInvoice.Invoice_Date__c).toStartOfMonth().addMonths(1).addDays(-1);
                if (draftInvoice.Original_Amount__c==null)
                    draftInvoice.Original_Amount__c=0;
            	   
                if (draftInvoice.Invoice_Review_Case_Audit__c==null)
                    draftInvoice.Type__c = 'ui';
                else if (draftInvoice.Invoice_Review_Case_Audit__c!=null)
                    draftInvoice.Type__c = 'system';
	           	
                if(draftInvoice.CI_Original_Contract_Id__c != null && draftInvoice.Type__c.toLowerCase()!= 'ui')
                    draftInvoiceContractResolvebyCIList.add(draftInvoice);
                else if (draftInvoice.Type__c.toLowerCase()== 'ui' && draftInvoice.Original_Contract_Id__c!=null)// && draftInvoice.Opportunity__c==null)
                    draftInvoiceContractResolvebyMCHList.add(draftInvoice);
            }
            else
            {
                if (draftInvoice.CI_Original_Contract_Id__c != oldMap.get(draftInvoice.ID).CI_Original_Contract_Id__c)
                    draftInvoice.addError('Original Contract Id cannot be updated after insert.');
            }
        }
        if(draftInvoiceContractResolvebyCIList.size() > 0)
            CastIronClass.Resolve_Draft_Invoice_ContractHeaderForeignKeys(draftInvoiceContractResolvebyCIList);
            
        if(draftInvoiceContractResolvebyMCHList.size()>0)
            CastIronClass.Resolve_Draft_Invoice_ByContractHeaderSFId(draftInvoiceContractResolvebyMCHList);
    }
    
    public static void afterInsertUpdate(Boolean isInsert, Draft_Invoice__c[] oldDraftInvoices, Draft_Invoice__c[] newDraftInvoices, Map<Id, Draft_Invoice__c> oldMap, Map<Id, Draft_Invoice__c> newMap)
    {
        List<Draft_Invoice__c> toProcessManualDIList = new List<Draft_Invoice__c>();
        Map<Id,Draft_Invoice__c> manualDIMap = new Map<Id,Draft_Invoice__c>();
        for(Draft_Invoice__c draftInvoice : newDraftInvoices)
        {
            if(!draftInvoice.processedForIRCase__c && draftInvoice.Case__c==null 
            	&& ((draftInvoice.Override_Attachment_Check__c) || (!isInsert && draftInvoice.hasAttachment__c && !oldMap.get(draftInvoice.Id).hasAttachment__c)))
	            {
	                System.debug('inside process DI case creation for DI=' + draftInvoice);
	                if (draftInvoice.Type__c.toLowerCase()== 'ui' && draftInvoice.Invoice_Review_Case_Audit__c==null)
	                {
	                    toProcessManualDIList.add(draftInvoice);
	                    manualDIMap.put(draftInvoice.id,draftInvoice);  
	                }
	            }
        }
        if (toProcessManualDIList.size()>0)
        {
            IRCaseCreationAdHocManual manualCaseClass = new IRCaseCreationAdHocManual(toProcessManualDIList, manualDIMap);
                manualCaseClass.doService();
        }
    }
}