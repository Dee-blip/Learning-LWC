/**
 *
 * Details: Data models for interacting with Steelbrick CPQ
 *
 * Developer         Date            Version     Update 
 * kimishra          19-AUG-2020      1.0        QuoteProposalModel for quote document generation
 *
 */
 public without sharing class CPQ_ApiDataModels {
    // DATA MODELS
    
    public class QuoteProposalModel {
        public String name;
        public Id quoteId;
        public Id templateId;
        public String language;
        public String outputFormat;
        public String paperSize;
    }
    
}