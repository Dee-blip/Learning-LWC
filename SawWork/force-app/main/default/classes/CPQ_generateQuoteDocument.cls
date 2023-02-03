/**
 *
 * Developer         Date            Version     Update 
 * kimishra          21-SEPT-2020    1.0         invocable method for quote document triggered by flow upon Place Order
 *
 */
 public with sharing class CPQ_generateQuoteDocument {
    @InvocableMethod(label='Generate quote document')
    public static void recalculate(List<String> quoteIds) {
        //generate document with latest prices
        String jobId = CPQ_ApiWrapper.generateDocument(quoteIds[0]);
        
    }
}