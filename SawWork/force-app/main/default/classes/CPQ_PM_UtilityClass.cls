public with sharing class CPQ_PM_UtilityClass {

    public inherited sharing class ProductBuilder{

        private Product2 newRecord;

        public ProductBuilder(String prodName, String recordType, Boolean isActive){
            Integer randomInt = getindex();
            RecordType recordTypeObject = [SELECT id, DeveloperName, SobjectType 
                                            FROM RecordType
                                            WHERE DeveloperName =:recordType AND SobjectType = 'Product2'
                                            WITH SECURITY_ENFORCED];

            newRecord = new Product2(Name = prodName
                                    , recordTypeId = recordTypeObject?.Id
                                    , IsActive = false
                                    );
            if(test.isRunningTest())
            {
               newRecord.AKAM_Product_ID__c = 'F-PRO-'+randomInt;
            }                          
        }

        public ProductBuilder withCode(String productCode){
            newRecord.ProductCode = productCode;
            return this;
        }

        public ProductBuilder withFamily(String family){
            newRecord.Family = family;
            return this;
        }

        public ProductBuilder isComponent(Boolean isComp) {
            //default value in Product2 is FALSE
            newRecord.SBQQ__Component__c = isComp;
            return this;
        }

        public ProductBuilder configurationSettings(String event, String type) {
            newRecord.SBQQ__ConfigurationEvent__c = event;
            newRecord.SBQQ__ConfigurationType__c = type;
            return this;
        }

        public ProductBuilder withConfigurationFieldSet(String configurationFieldSet) {
            newRecord.SBQQ__ConfigurationFieldSet__c = configurationFieldSet;
            return this;
        }

        public ProductBuilder withUpdateCode(String versionNumber) {
            newRecord.CPQ_ProductUpdateCode__c = versionNumber;
            return this;
        }

        public ProductBuilder withOptionLayout(String optionLayout) {
            newRecord.SBQQ__OptionLayout__c = optionLayout;
            return this;
        }

        public ProductBuilder withDescription(String description){
            newRecord.Description = description;
            return this;
        }

        public Product2 saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public Product2 getRecord(){
            return newRecord;
        }

    }

    public inherited sharing class PricebookEntryBuilder {

        private PricebookEntry newRecord;

        public PricebookEntryBuilder(Id pricebookId, Id productId, String currencyCode, Boolean isActive) {
            newRecord = new PricebookEntry(Pricebook2Id = pricebookId, 
                                            Product2Id = productId,
                                            CurrencyIsoCode = currencyCode
                                            , IsActive = isActive);

        }

        public PricebookEntryBuilder withUnitPrice(Decimal unitPrice) {
            newRecord.UnitPrice = unitPrice;
            return this;
        }

        public PricebookEntry saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public PricebookEntry getRecord(){
            return newRecord;
        }
    }

    public inherited sharing class ProductFeatureBuilder{

        private SBQQ__ProductFeature__c newRecord;

        public ProductFeatureBuilder(String name,  Id configuredSKU, Integer featureNumber){

            newRecord = new SBQQ__ProductFeature__c(Name = name, 
                                                    SBQQ__ConfiguredSKU__c = configuredSKU,
                                                    SBQQ__Number__c = featureNumber
                                                    , SBQQ__MinOptionCount__c = 0
                                                    );
        }

        public ProductFeatureBuilder withOptionSelection(String optionSelectionMethod){
            newRecord.SBQQ__OptionSelectionMethod__c = optionSelectionMethod;
            return this;
        }

        public ProductFeatureBuilder withCategory(String categoryName) {
            newRecord.SBQQ__Category__c = categoryName;
            return this;
        }

        public ProductFeatureBuilder withConfigurationFieldSet(String configurationFieldSet) {
            newRecord.SBQQ__ConfigurationFieldSet__c = configurationFieldSet;
            return this;
        }

        public SBQQ__ProductFeature__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__ProductFeature__c getRecord(){
            return newRecord;
        }
    }

    public inherited sharing class ProductOptionBuilder {

        private SBQQ__ProductOption__c newRecord;

        public ProductOptionBuilder(Id configuredSKU, Id optionalSKU, Integer optionNumber, Decimal quantity) {
            newRecord = new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = configuredSKU,
                                                    SBQQ__OptionalSKU__c = optionalSKU,
                                                    SBQQ__Number__c = optionNumber,
                                                    SBQQ__Quantity__c = quantity);

        }

        public ProductOptionBuilder withAssociatedProductId(String associatedProductId) {
            newRecord.CPQ_Associated_Product_Id__c = associatedProductId;
            return this;
        }

        public ProductOptionBuilder withBillingFrequency (String billingFrequency) {
            newRecord.CPQ_Billing_Frequency__c = billingFrequency;
            return this;

        }

        public ProductOptionBuilder withBillingModel (String billingModel) {
            newRecord.CPQ_Billing_Model__c = billingModel;
            return this;

        }
        
        public ProductOptionBuilder withChargeType (String chargeType) {
            newRecord.CPQ_Charge_Type__c = chargeType;
            return this;
            
        }

        public ProductOptionBuilder withPliName (String pliName) {
            newRecord.CPQ_PAC_Line_Item_Id1__c = pliName;
            newRecord.CPQ_Product_Notes__c = pliName;
            return this;
            
        }

        public ProductOptionBuilder withOptionType (String optionType) {
            newRecord.SBQQ__Type__c = optionType;
            return this;

        }

        public ProductOptionBuilder withMeasurement (String uom) {
            newRecord.CPQ_Measurement__c = uom;
            return this;

        }

        public ProductOptionBuilder quantityEditableSetting (Boolean quantityEditable) {
            newRecord.SBQQ__QuantityEditable__c = quantityEditable;
            return this;
        }

        public ProductOptionBuilder withIncludedSettings (Boolean includedSettings) {
            newRecord.SBQQ__Bundled__c = includedSettings;
            newRecord.SBQQ__Required__c = includedSettings;
            newRecord.SBQQ__Selected__c = includedSettings;
            return this;
        }

        public SBQQ__ProductOption__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__ProductOption__c getRecord(){
            return newRecord;
        }

    }

    public inherited sharing class ConfigurationAttributeBuilder{

        private SBQQ__ConfigurationAttribute__c newRecord;

        public ConfigurationAttributeBuilder(String name, Id productId, Id featureId, String targetField, Decimal displayOrder, String columnOrder, String position, Boolean applyImediately){

            newRecord = new SBQQ__ConfigurationAttribute__c(
                Name = name
                , SBQQ__Product__c = productId
                , SBQQ__Feature__c = featureId
                , SBQQ__TargetField__c = targetField
                , SBQQ__DisplayOrder__c	= displayOrder
                , SBQQ__ColumnOrder__c = columnOrder
                , SBQQ__Position__c = position
                , SBQQ__AppliedImmediately__c = applyImediately
            );
        }

        public ConfigurationAttributeBuilder withDefaultObjectField(String defaultObject, String defaultField) {
            newRecord.SBQQ__DefaultObject__c = defaultObject;
            newRecord.SBQQ__DefaultField__c = defaultField;
            return this;
        }

        public ConfigurationAttributeBuilder requiredSetting(Boolean isRequired){
            newRecord.SBQQ__Required__c = isRequired;
            return this;
        }

        public SBQQ__ConfigurationAttribute__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__ConfigurationAttribute__c getRecord(){
            return newRecord;
        }
    }

    public inherited sharing class OptionConstraintBuilder{

        private SBQQ__OptionConstraint__c newRecord;

        public OptionConstraintBuilder(String name, String type, Id productId) {
            newRecord = new SBQQ__OptionConstraint__c(
                name = name
                , SBQQ__Type__c = type
                , SBQQ__ConfiguredSKU__c = productId
            );
            
        }

        public OptionConstraintBuilder withConstraint(Id contrained, Id constraining){
            newRecord.SBQQ__ConstrainedOption__c = contrained;
            newRecord.SBQQ__ConstrainingOption__c = constraining;
            return this;
        }

        public SBQQ__OptionConstraint__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__OptionConstraint__c getRecord(){
            return newRecord;
        }
    }

    /** DATA MODELS */

    // ATTRIBUTES API - START
    public class PacAttributesApi {
        public String marketingProductId {get;set;} 
        public String productName {get;set;} 
        public String currentActiveVersion {get;set;} 
        public ProductAttributes productAttributes {get;set;}

    }

    public class ProductAttributes {
		/* public String internalName {get;set;} 
		public String forecastingProductId {get;set;} 
		public String businessUnit {get;set;} 
		public String prodKey {get;set;} 
		public String caseProdName {get;set;} 
		public Boolean isBaseProd {get;set;} 
		public Boolean isStandaloneProd {get;set;} 
		public Boolean isShippingAddendumReq {get;set;} 
		public Boolean isUsageBased {get;set;} 
		public Boolean forDirect {get;set;}  */
		public String marketingCategory {get;set;} 
		/* public String functionalCategory {get;set;} 
		public TrialInfo trialInfo {get;set;} 
		public String phaseName {get;set;} 
		public List<String> offeringType {get;set;} 
		public List<String> customerTypes {get;set;} 
		public Contacts contacts {get;set;} 
		public List<String> serverTypes {get;set;} 
		public List<String> includedRegions {get;set;} 
		public String defaultServerType {get;set;} 
		public List<String> trafficTypes {get;set;} 
		public String lastUpdatedDate {get;set;} 
		public List<Features> features {get;set;} 
		public List<Link> link {get;set;} 
		public List<String> geoSets {get;set;}  */
		public Boolean forPartner {get;set;} 
    
    }

    /* public class Contacts {
		public Architect architect {get;set;} 
		public Architect manager {get;set;} 
		public Architect marketingManager {get;set;} 
		public Architect serviceArchitect {get;set;} 
		public String programManager {get;set;} 
		public String marketingManagerAlias {get;set;} 

    } */

   /*  public class TrialInfo {
		public String trialDuration {get;set;} 
		public String trialApprovalWorkflowId {get;set;} 
		public List<String> customerTypes {get;set;} 
		public List<String> trialType {get;set;} 

    } */

    /* public class Features {
		public String featureId {get;set;} 
		public String name {get;set;} 
		public String description {get;set;} 

    } */

    /* public class Architect {
		public String name {get;set;} 
		public String loginName {get;set;} 

    } */

    /* public class Link {
		public String xRel {get;set;} // in json: _rel
		public String xHref {get;set;} // in json: _href

    } */
    // ATTRIBUTES API - END

    // SECTIONS API - START
    public class PacSectionsApi {
        public Integer id {get;set;}
        public String name {get;set;}
        public Integer ranking {get;set;}
        public ListItemGroupInfo listItemGroupInfo {get;set;}

    }

    public class ListItemGroupInfo {
        // public String groupName {get;set;}
        public String groupingCriterion {get;set;}
        // public List<String> setNames {get;set;}

    }
    // SECTIONS API - END

    // PRICING API - START
    public class PacPricingApi {
        /* public String productId {get;set;} 
        public String productName {get;set;} 
        public String pricingAccess {get;set;} 
        public String wholesalePricePartnerTier {get;set;}  */
        public List<ListItems> listItems {get;set;} 
    
    }


    public class ListItems {
		public Integer id {get;set;} 
		public String name {get;set;} 
		public String productId {get;set;} 
		public String productName {get;set;} 
		public String associatedProdId {get;set;} 
		public String associatedProdName {get;set;} 
		public String secLvlAssociatedProdId {get;set;} 
		// public String secLvlAssociatedProdName {get;set;} 
		// public List<ContextParentProd> contextParentProd {get;set;} 
		public List<String> contextParentProd {get;set;} 
		public Integer sectionId {get;set;} 
		public String sectionName {get;set;} 
		// public Integer sectionRanking {get;set;} 
		public String uom {get;set;} 
		public String pricingModel {get;set;} 
		public String billingFrequency {get;set;} 
		// public List<String> geoSetNames {get;set;} 
		public DefaultEntitlement defaultEntitlement {get;set;} 
		// public String listItemGroupId {get;set;} 
		public String listItemGroup {get;set;} 
		public String listItemSet {get;set;} 
		public String listItemGroupCriteria {get;set;} 
		/* public Boolean isImpactedByAssociatedProd {get;set;} 
		public String impactedByMktProdId {get;set;} 
		public Boolean isSelectedOnImpact {get;set;} 
		public Boolean isListItemGrpSelectedOnImpact {get;set;} 
		public Boolean impactedByOverrdnMktProdId {get;set;} 
		public Boolean isApplicableWhenAddon {get;set;}  */
		public Boolean isApplicableWhenStandalone {get;set;} 
		// public Boolean isAppliedToAll {get;set;} 
		public Integer ranking {get;set;} 
		/* public String gsaSinCodeName {get;set;} 
		public String gsaSinCode {get;set;} 
		public String description {get;set;} 
		public Boolean isAddOn {get;set;} 
		public String key {get;set;} 
		public Boolean isTrial {get;set;}  */
		public List<String> customerTypes {get;set;}
		public String currencyId {get;set;}
        /*  
		public String currencyName {get;set;} 
		public String rateCardName {get;set;} 
		public GeosetPricesProvidedFor geosetPricesProvidedFor {get;set;}  */
		public List<Tiers> tiers {get;set;} 
		//public String pricingAccess {get;set;} 

    }

    public class DefaultEntitlement {
		public Decimal value {get;set;} 
		// public Boolean isInf {get;set;} 

    }

   /*  public class GeosetPricesProvidedFor {
		public String displayName {get;set;} 
		public String name {get;set;} 

    } */

    public class Tiers {
		public Tier tierLow {get;set;} 
		public Tier tierHigh {get;set;} 
		//public String tierKey {get;set;} 
		//public Decimal partNumber {get;set;}
		public List<GeoRegionPricing> geoRegionPricing {get;set;}
    
    }

    public class Tier {
		public Integer value {get;set;} 
		//public Boolean isInf {get;set;} 
    
    }

    public class GeoRegionPricing {
		/* public String geoRegion {get;set;} 
		public String geoSetName {get;set;} 
		public String geoSetDisplayName {get;set;} 
		public Boolean geoSetIsDefault {get;set;}  */
		public PricePoints pricePoints {get;set;} 

    }

    public class PricePoints {
		/* public Decimal dd {get;set;} 
		public Decimal listOverage {get;set;} 
		public Decimal wholesaleOverage {get;set;} 
		public Decimal feOverage {get;set;} */
		public String list_Z {get;set;} // in json: list
		/*public Decimal target {get;set;} 
		public Decimal srp {get;set;} 
		public Decimal pmOverage {get;set;} */ 
		public Decimal wholesale {get;set;} 
		/* public Decimal wholesaleDiscPercentage {get;set;} 
		public Decimal ddOverage {get;set;} 
		public Decimal wholesaleOverageDiscPercentage {get;set;} 
		public Decimal pm {get;set;} 
		public Decimal srpOverage {get;set;} 
		public Decimal targetOverage {get;set;} 
		public Decimal fe {get;set;}  */

    }
    // PRICING API - END
    // LITERATURE API - START
    public class PacLiteratureApiWrapper {

        public String marketingProductId {get; set;}
        public String productName {get; set;}
        public MarketingCollaterals marketingCollaterals{get; set;}

    }

    public class MarketingCollaterals {

        public string tagLine {get;set;}
        public string longDescription {get; set;}

    }
    // LITERATURE API - START
    public class productLaunchRecordBuilder{

        private CPQ_ProductLaunchManagement__c record;
        public productLaunchRecordBuilder(Id launchID, String Name){
            this.record = new CPQ_ProductLaunchManagement__c();

            this.record.Launch__c = launchID;
            this.record.Name = Name;
        }

        public productLaunchRecordBuilder(CPQ_ProductLaunchManagement__c record){
            this.record = record;
        }

        public productLaunchRecordBuilder setCreationStatus(String status){
            record.Product_Creation_Status__c = status;

            return this;
        }

        public productLaunchRecordBuilder setLaunchStatus(String status){
            record.Product_Launch_Status__c = status;

            return this;
        }

        public productLaunchRecordBuilder setCreationMessage(String message){
            record.Product_Creation_Message__c = message;

            return this;
        }

        public CPQ_ProductLaunchManagement__c getRecord(){
            return record;
        }
    }

    public class ErrorResponse {

        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String instance { get; set; }
        @AuraEnabled
        public Integer status { get; set; }
        @AuraEnabled
        public String detail { get; set; }

    }

    public class ApiResponseWrapper {

        @AuraEnabled
        public Boolean validity { get; set; }
        @AuraEnabled
        public ErrorResponse errorResponse {get; set;}
        @AuraEnabled
        public String attributeResponse { get; set; }
        @AuraEnabled
        public String sectionResponse { get; set; }
        @AuraEnabled
        public String pricingResponse { get; set; }
        @AuraEnabled
        public List<OptionalProducts> optionalProducts {get; set;}
        @AuraEnabled
        public String productsInfo { get; set; }

        public String literatureResponse { get; set; }
        public Map<String,String> currencyResponse{get; set;}
    
    }

    public class OptionalProducts {
        // @AuraEnabled
        // public Id productId {get; set;}
        @AuraEnabled
        public String productCode {get; set;}
        @AuraEnabled
        public List<ListItems> listItems {get; set;}
        @AuraEnabled
        public Integer numberOfOptions {get; set;}
    }
    public static Integer getindex(){
        return Math.round((Math.random() * (900000) + 100000));
    }
}