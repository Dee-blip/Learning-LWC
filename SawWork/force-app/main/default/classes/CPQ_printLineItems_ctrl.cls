/**
 *
 * Details: Controller to generate the custom line items on Partner quote document
 *
 * Developer         Date            Version     Update 
 * kimishra          19-AUG-2020      1.0        Initial version
 *
 */
public with sharing class CPQ_printLineItems_ctrl {
    private Id quoteId;
    public CPQ_QuoteWrapper quoteData {get; set;}

    public CPQ_printLineItems_ctrl() {
        quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
        System.debug('--quote Id: '+quoteId);
    }

    public PageReference init() {
        try {
            quoteData = new CPQ_QuoteFactory(quoteId).generateQuoteData();
            System.debug('--quoteData: '+JSON.serialize(quoteData));
        } catch (Exception exc) {
            String errorMsg = 'There was an error getting QLs for our Quote. Exception Cause = ' + 
                exc.getLineNumber() + ' - ' + exc.getCause() + ', Exception Message = ' + exc.getMessage();
            System.debug('=====> error: ' + errorMsg);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
        }
        return null;

    }
}