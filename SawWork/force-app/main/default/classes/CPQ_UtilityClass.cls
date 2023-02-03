/*
* Object: SBQQ__Quote__c
* Details : Class for utility methods on CPQ quote object
* 
* Developer         Date            Version     Update 
* kimishra          08/06/2019      1.0         Initial logic to recall quote approval from process
* shegade			09/16/2019		1.1			logic to update the OA lookup, if it exists on related Opportunity
* kimishra          03-MAR-2021     1.2         logic to create contentVersion for attachment data by setContentVersion method
* 
*/
public with sharing class CPQ_UtilityClass {
    @InvocableMethod(label='Recall approval' description='recalls the approval for quote if new QLs with Approval Worklfow are added.')
    public static List<Id> getQuoteIds(List<ID> ids) {
        System.debug(LoggingLevel.INFO, '--recalling approval for: '+ids[0]);
        SBAA.ApprovalAPI.recall(ids[0], SBAA__Approval__c.Quote__c);
        return ids;
    }
    
    public static boolean UpdateTheQuoteLookup(SBQQ__Quote__c quoteRecord){
        
        Order_Approval__c[] oARecord = [ SELECT id,Associated_Opportunity__c
                                        FROM Order_Approval__c 
                                        WHERE Associated_Opportunity__c = :quoteRecord.SBQQ__Opportunity2__c
                                        WITH SECURITY_ENFORCED
                                        LIMIT 1 ];
        
        if(oArecord.size() > 0){
            update quoteRecord;
            return true;
        }
        return false;
    }
    
    public static Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
    
    public static String specialCharacterReplacement(String specialChar){
        
        String returnValue = '';
        switch on specialChar {
            when ('&') {
                returnValue = 'and';
            }
            when else {
                return '';
            }
        }
        return returnValue;
    }

    //CPQ-501 logic to create ContenVersion
    public inherited sharing class ContentVersionBuilder{
        private ContentVersion newRecord;

        public ContentVersionBuilder(String pathOnClient, String title, String versionData) {
            newRecord = new ContentVersion(PathOnClient = pathOnClient, Title = title, VersionData = EncodingUtil.base64Decode(versionData));
        }

        public ContentVersionBuilder(String pathOnClient, String title, Blob versionData) {
            newRecord = new ContentVersion(PathOnClient = pathOnClient, Title = title, VersionData = versionData);
        }

        public ContentVersionBuilder withContentLocation(String contentLocation) {
            newRecord.ContentLocation = contentLocation;
            return this;
        }

        public ContentVersionBuilder withNetworkName(String networkName) {
            newRecord.NetworkId = String.isNotBlank(networkName) ? [SELECT Id FROM Network WHERE Name = :networkName LIMIT 1].Id : Network.getNetworkId();
            return this;
        }

        public ContentVersionBuilder withFirstPublishLocationId(Id firstPublishLocationId) {
            newRecord.FirstPublishLocationId = firstPublishLocationId;
            return this;
        }

        public ContentVersion saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public ContentVersion getRecord(){
            return newRecord;
        }
    }
}