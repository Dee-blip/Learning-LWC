/**
Gautam Sargur    18/06/2013    Created the class   
                 CR 2274149    Need to create Trigger on Draft Invoice Line Items to resolve ids for parent Draft Invoices.
                               This trigger resolves the parent Draft Invoice to which the line items must be attached.  
*/

trigger DraftInvoiceLineItemsTrigger on Draft_Invoice_Line_Item__c (before insert) {
    
    Map<string, Set<Draft_Invoice_Line_Item__c>> LineItemsMap = new Map<string, Set<Draft_Invoice_Line_Item__c>>();
    
    for ( Draft_Invoice_Line_Item__c LineItem : Trigger.new ) {
        if ( !LineItem.Is_From_Refresh__c && !LineItemsMap.containsKey(LineItem.CI_Draft_Invoice_id__c) ) {
            LineItemsMap.put(LineItem.CI_Draft_Invoice_id__c, new Set<Draft_Invoice_Line_Item__c>());
        }
        if ( !LineItem.Is_From_Refresh__c )
            LineItemsMap.get(LineItem.CI_Draft_Invoice_id__c).add(LineItem);
    }
    
    if ( !LineItemsMap.isEmpty() ){
        Invoice_Review_Case_Audit__c lastIRCA = [select Id,Name from Invoice_Review_Case_Audit__c order by Import_Start_Date__c desc limit 1];
    
        for ( Draft_Invoice__c Invoice : [select Id,Name from Draft_Invoice__c where Name IN :LineItemsMap.keySet() and Invoice_Review_Case_Audit__c = :lastIRCA.Id] ) {
            Set<Draft_Invoice_Line_Item__c> LineItems = LineItemsMap.get(Invoice.Name);
            for ( Draft_Invoice_Line_Item__c LineItem : LineItems ) {
               LineItem.Draft_Invoice__c = Invoice.Id;
            }
        }
    }
}