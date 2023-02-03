public class DraftInvoiceRefreshController { 

    @AuraEnabled
    public static Map<String,String> refreshDraftInvoice (Id draftInvoiceId){
        Draft_Invoice__c di = [select id, Name, Refreshed__c, (select Id from Draft_Invoice_Line_Items__r) from Draft_Invoice__c where Id = :draftInvoiceId Limit 1];
        if(di.Draft_Invoice_Line_Items__r.size() > 0){
            return new Map<String,String>{'error' => 'You need to create a new invoice header to refresh this invoice.'};
        }
        else if(di.Refreshed__c == true){
            return new Map<String,String>{'error' => 'A Refresh has already been requested on this Invoice.'};
        }
        else{
            try{
                Long.valueOf(di.Name);
                di.Refreshed__c = true;
                update di;
                return new Map<String,String>{'success' => 'A refresh has been requested. Please wait for a while before the line items are updated.'};
            }
            catch(Exception e){
              if(e.getTypeName().contains('TypeException') == true){
                return new Map<String,String>{'error' => 'Please provide a numeric invoice number.'};
              }else
                return new Map<String,String>{'error' => e.getMessage()};
            }
        }
    }
}