/**
 *
 * Details: Methods for interacting with Steelbrick CPQ
 *
 * Developer         Date            Version     Update 
 * kimishra          19-AUG-2020      1.0        generateDocument for quote document generation - Autonomy
 *
 */
public without sharing class CPQ_ApiWrapper {

    public static Boolean debug = true;

   /** CPQ API METHODS */
    public static final String QUOTE_DOCUMENT = 'SBQQ.QuoteDocumentAPI.Save';

    /** Mini Wrapper around SBQQ API METHODS */
    // private static String read(String name, String uid) {
    //     return SBQQ.ServiceRouter.read(name, uid);
    // }
    // private static String load(String name, String uid, Object payload) {
    //     return loadStr(name, uid, JSON.serialize(payload));
    // }
    // private static String loadStr(String name, String uid, String payloadJson) {
    //     return SBQQ.ServiceRouter.load(name, uid, payloadJson);
    // }
    // private static String save(String name, Object model) {
    //     return saveStr(name, JSON.serialize(model));
    // }
    private static String saveStr(String name, String modelJson) {
        return SBQQ.ServiceRouter.save(name, modelJson);
    }


    /**
     * ******* QUOTE API ********
     */

    public static String generateDocument(Id quoteId) {

        //logic to get quote details for dynamic document name

        SBQQ__Quote__c quote = [SELECT Name,
                                    SBQQ__Opportunity2__r.Name
                                    FROM SBQQ__Quote__c
                                    WHERE Id = :quoteId];

        SBQQ__QuoteTemplate__c quoteTemplate = [SELECT Id FROM SBQQ__QuoteTemplate__c 
                                                WHERE Name = :System.Label.CPQ_Partner_Quote_Template_Id];
        
        //OPP_NAME-QUOTE_NAME-CURR_DATETIME
        String docNameFormat = CPQSettings.getMetadataValue('documentNameFormat');
        docNameFormat = docNameFormat.replace('OPP_NAME', quote.SBQQ__Opportunity2__r.Name)
                                    .replace('QUOTE_NAME', quote.Name)
                                    .replace('CURR_DATETIME', String.valueOf(System.now()));
        
        CPQ_ApiDataModels.QuoteProposalModel model = new CPQ_ApiDataModels.QuoteProposalModel();
        model.quoteId = quoteId;
        // model.templateId = System.Label.CPQ_Partner_Quote_Template_Id;
        model.templateId = quoteTemplate.Id;
        model.name = docNameFormat;
         
        String jobId = saveStr(QUOTE_DOCUMENT, JSON.serialize(model));

        if(debug) {
            System.debug(LoggingLevel.WARN, '--model: ' + model);
            System.debug(LoggingLevel.WARN, '--jobId: ' + jobId);

        }
        return jobId;
    }
}