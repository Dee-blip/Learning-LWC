/*
* Details : Test data generator class for CPQ classes.
* 
* Developers: kimishra, shegade
*
*/

@isTest
public class CPQ_TestDataFactory {
    
    /** 
* ******************************************************
* This method is test data for create Account
* ******************************************************
*/
    @future
    public static void createCPQUser(String profileName) {
        //generate user record
        Profile p = [SELECT Id FROM Profile WHERE Name= :profileName];
        String uniqueUserName = 'cpqUser' + DateTime.now().getTime() + '@akamai.com';
        User u1 = new User(Alias = 'newUser', Email='newuser@akamai.com',
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                           LocaleSidKey='en_US', ProfileId = p.Id,
                           TimeZoneSidKey='America/Los_Angeles', UserName= uniqueUserName);
        insert u1;
        
        //insert CPQ permission sets
        /*List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
List<PermissionSet> psList = [SELECT Id FROM PermissionSet
WHERE Name IN ('Salesforce CPQ User','Salesforce CPQ Additional', 'Advanced Approvals User')];

for(PermissionSet ps : psList) {
psaList.add(new PermissionSetAssignment(AssigneeId = u1.id, PermissionSetId = ps.Id));
}
insert psaList;*/
        
        //return u1.Id;
    }
    
    /** 
* *********************************************************
* This method is test data for create Group with a member
* *********************************************************
*/
    @future
    public static void createGroup(String groupName) {
        //Create Parent Group
        Group grp = new Group();
        grp.name = groupName;
        grp.Type = 'Regular'; 
        Insert grp; 
        
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
    }
    
    @future
    public static void createGroupMember(String grpId, String userId){
        User user1 = [SELECT Id, Name FROM User WHERE Alias = 'newUser' LIMIT 1];
        Group grp = [SELECT Id, Name FROM Group WHERE Name = 'OM Approval Group'];
        
        //insert new user as group member
        GroupMember grpMem2 = new GroupMember();
        grpMem2.UserOrGroupId = user1.Id;
        grpMem2.GroupId = grp.Id;
        Insert grpMem2;
    }
    
    /** 
* ***********************************************************************
* This method is test data for create CPQ related custom settings
* ***********************************************************************
*/  
    //@future
    public static void createCustomSettings() {
        //CPQ_Order_Region_RSM_Region_Mapping__c setting
        //CPQ_Order_Region_RSM_Region_Mapping__c  regionRSMsetting = new CPQ_Order_Region_RSM_Region_Mapping__c(Name = 'North America', CPQ_Geo_Location__c = 'AMER');
        //insert regionRSMsetting;
        
        //CPQ_Generic_Settings__c settings
        List<CPQ_Generic_Settings__c> genericSettingToInsert = new List<CPQ_Generic_Settings__c>{
            new CPQ_Generic_Settings__c(Name = 'Geo Location RSM Mapping', CPQ_Value__c='{ "AMER":"RLANZ", "APJ":"SPISHARO", "EMEA":"MHELLMER", "LATAM":"RJERUSAL" }'),
                new CPQ_Generic_Settings__c(Name = 'OrderRegionLegalEntityMapping', CPQ_Value__c='{ "United Arab Emirates": "UAE", "United Kingdom": "UK" }'),
                new CPQ_Generic_Settings__c(Name = 'DefaultRegionGeoLocation', CPQ_Value__c='{ "Region": "United States", "Geo Location": "North America" }'),
                new CPQ_Generic_Settings__c(Name = 'paeEmailTemplate',CPQ_Value__c='Autonomy Process Initiation Notification', CPQ_Active__c = true),
                new CPQ_Generic_Settings__c(Name = 'defaultOrgWideEmail',CPQ_Value__c='shegade@akamai.com', CPQ_Active__c = true),
                new CPQ_Generic_Settings__c(Name = 'targetUserAlias',CPQ_Value__c='CRMOPS', CPQ_Active__c = true),
                new CPQ_Generic_Settings__c(Name = 'errorEmailsTo',CPQ_Value__c='shegade@akamai.com', CPQ_Active__c = true)

                };
                    
                    /*CPQ_Generic_Settings__c locationRSMsetting = new CPQ_Generic_Settings__c(Name = 'Geo Location RSM Mapping',
CPQ_Value__c='{ "AMER":"RLANZ", "APJ":"SPISHARO", "EMEA":"MHELLMER", "LATAM":"RJERUSAL" }');
genericSettingToInsert.add(locationRSMsetting);*/
                    
                    
                    insert genericSettingToInsert;
        
        //custom setting for Momentum Product Approval
        ProductApprovalCS__c approvalCS = new ProductApprovalCS__c (Name = 'LegacyStreamingWF',
                                                                    Value__c = 'F-PA-0100');
        insert approvalCS;
    }
    
    /** 
* ******************************************************
* This method is test data for create Account
* ******************************************************
*/
    public static Account createAccount(Boolean doInsert) {
        Account acc = new Account(Name = 'Test Account',
                                  Finance_Region__c = 'North America');
        if(doInsert){
            insert acc;
        }
        return acc;
    }
    
    /** 
* ******************************************************
* This method is test data for create Opportunity
* ******************************************************
*/
    public static Opportunity createOpportunity(Boolean doInsert) {
        return createOpportunity(doInsert, createAccount(true).Id);
    }
    
    public static Opportunity createOpportunity(Boolean doInsert, Id accId) {
        Opportunity oppt = new Opportunity(Name ='Test Opportunity',
                                           AccountID = accId,
                                           StageName = '5. Negotiate',
                                           Amount = 3000,
                                           Order_Region__c = 'North America',
                                           CloseDate = System.today()
                                          );
        if(doInsert) {
            insert oppt;
            System.debug(LoggingLevel.INFO, '--test order region: '+oppt.Order_Region__c);
        }
        return oppt;
    }
    
    /** 
* ******************************************************
* This method is test data for create Quote
* ******************************************************
*/
    public static SBQQ__Quote__c createQuote(Boolean doInsert) {
        return createQuote(doInsert, createOpportunity(true));
    }
    
    public static SBQQ__Quote__c createQuote(Boolean doInsert, Opportunity opp) {
        SBQQ__Quote__c qt = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,
                                               SBQQ__Account__c = opp.AccountId
                                              );
        if(doInsert) {
            insert qt;
            System.debug(LoggingLevel.INFO,'--test geo location: '+qt.CPQ_Geo_Location__c);
        }
        return qt;
    }


    
    /** 
* ******************************************************
* This method is test data for create Order Approval
* ******************************************************
*/
    public static Order_Approval__c createOrderApproval(Boolean doInsert) {
        return createOrderApproval(doInsert, createOpportunity(true));
    }
    
    public static Order_Approval__c createOrderApproval(Boolean doInsert, Opportunity opp) {
        Order_Approval__c oa = new Order_Approval__c(Associated_Opportunity__c = opp.id);
        
        if(doInsert) {
            insert oa;
        }
        return oa;
    }
    
    /** 
* ******************************************************
* This method is test data for create Approver
* ******************************************************
*/
    public static sbaa__Approver__c createApprover(Boolean doInsert, String groupName) {
        sbaa__Approver__c appr;
        if(groupName != null){
            Group grp = [SELECT Id, Name FROM Group WHERE Name = :groupName LIMIT 1];
            appr = new sbaa__Approver__c(Name = UserInfo.getName(),
                                                           sbaa__GroupId__c = grp.Id);
        } else{
            appr = new sbaa__Approver__c(Name = UserInfo.getName(),
                                                           sbaa__User__c = UserInfo.getUserId());
        }
        if(doInsert) {
            insert appr;
        }
        return appr;
    }
    
    /** 
* ******************************************************
* This method is test data for create QuoteLine
* ******************************************************
*/
    public static SBQQ__QuoteLine__c createQuoteLine(Boolean doInsert, string prodName) {
        return createQuoteLine(doInsert, createQuote(true),prodName);
    }
    
    public static SBQQ__QuoteLine__c createQuoteLine(Boolean doInsert, SBQQ__Quote__c quote, string prodName) {
        
        product2 newProd = createProduct(true, prodName);
        
        Approval_Workflow__c newApprovalWorkflow = [SELECT Id, Name FROM Approval_Workflow__c WHERE Name = :prodName LIMIT 1];
        System.debug(LoggingLevel.INFO,'--newApprovalWorkflow: '+newApprovalWorkflow);
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.id,
                                                       SBQQ__Product__c  = newProd.id,
                                                       SBQQ__NetPrice__c = 9.00);
        
        if(doInsert) {
            insert ql;
        }
        return ql;
    }
    
    /** 
* ******************************************************
* This method is test data for create Product
* ******************************************************
*/
    
    private static product2 createProduct(Boolean doInsert, string productName){
            
        RecordType cPrecordType = [SELECT id, DeveloperName, SobjectType 
                                FROM RecordType
                                WHERE DeveloperName = 'Carrier_Products' AND SobjectType = 'Product2'];
        Integer randomInt = getindex();
        product2 newProduct = new product2(Name = productName, RecordTypeid = cPrecordType.id,
                                        AKAM_INT_ID__c = randomInt,
                                        AKAM_Product_ID__c = 'F-PRO-'+randomInt);
        System.debug(LoggingLevel.INFO, '--test prod: '+newProduct);
        
        if(doInsert){
            insert newProduct;
        }
        return newProduct;
    }
    
    /** 
* ******************************************************
* This method is test data for create Approval Workflow
* ******************************************************
*/
    
    public static Approval_Workflow__c createApprovalWorkflow(Boolean doInsert, string approvalWorkflowName){
        //approvalWorkflowName should be same as the Quote Line product name
        Survey__c survey = createSurvey(true, approvalWorkflowName);
        System.debug(LoggingLevel.INFO,'--wf akam id: '+survey.AKAM_Workflow_ID__c);
        Approval_Workflow__c newApprovalWorkflow = new Approval_Workflow__c(Name = approvalWorkflowName,
                                                                            Survey__c = survey.Id);
        
        if(doInsert){
            insert newApprovalWorkflow;
        }
        
        return newApprovalWorkflow;
    }
    /** 
* ******************************************************
* This method is test data for create Survey
* ******************************************************
*/
    public static Survey__c createSurvey(Boolean doInsert, String surveyName){
        Survey__c survey = new Survey__c(Name = surveyName,
                                         Submit_Response__c = 'empty');
        if(doInsert){
            insert survey;
        }
        return survey;
    }
    
    /** 
* ******************************************************
* This method is test data for create AA Rule setup
* ******************************************************
*/
    private static void setupAARules(){
        //product approval rule
        sbaa__ApprovalRule__c rule1 = createApprovalRule(true, 'Product Approval Rule', null);
        sbaa__ApprovalCondition__c rule1Condition1 = createRuleCondition(true, rule1);
        System.debug(LoggingLevel.INFO, 'rule1Condition1: '+rule1Condition1);
    }
    
    public static sbaa__ApprovalRule__c createApprovalRule(Boolean doInsert, String ruleName, String groupName){
        sbaa__Approver__c approver;
        if(groupName != null){
            approver = createApprover(true, groupName);
        } else{
            approver = createApprover(true, null);
        }
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(Name = ruleName,
                                                               sbaa__TargetObject__c = 'SBQQ__Quote__c',
                                                               sbaa__Approver__c = approver.Id,
                                                               sbaa__Active__c = TRUE,
                                                               sbaa__ApprovalStep__c = 1);
        if(doInsert){
            insert rule;
        }
        return rule;
    }
    
    
    public static sbaa__ApprovalCondition__c createRuleCondition(Boolean doInsert, sbaa__ApprovalRule__c rule){
        sbaa__ApprovalCondition__c condition = new sbaa__ApprovalCondition__c(sbaa__ApprovalRule__c = rule.Id,
                                                                              sbaa__Index__c = 1,
                                                                              sbaa__TestedField__c = 'CPQ_Approval_Quote_Lines__c',
                                                                              sbaa__Operator__c = 'greater than',
                                                                              sbaa__FilterType__c = 'Value',
                                                                              sbaa__FilterValue__c = '0');
        if(doInsert){
            insert condition;
        }
        return condition;
    }
    
    /** 
* ******************************************************
* This method is test data for create AA Approval
* ******************************************************
*/
    public static sbaa__Approval__c createApproval(Boolean doInsert, sbaa__ApprovalRule__c rule, Id quoteId, String status){
        sbaa__Approval__c appr = new sbaa__Approval__c(sbaa__Rule__c = rule.Id,
                                                       sbaa__RecordField__c = 'Quote__c',
                                                       Quote__c = quoteId,
                                                       sbaa__Status__c = status,
                                                       sbaa__ApprovalStep__c = rule.sbaa__ApprovalStep__c,
                                                       sbaa__Approver__c = rule.sbaa__Approver__c);
        
        if(doInsert){
            insert appr;
        }
        return appr;
    }
    /** 
* ******************************************************
* This method is to generate random 7 digit number
* ******************************************************
*/
    public static Integer getindex(){
        return Math.round((Math.random() * (900000) + 100000));
    }
    
    /** 
* ***********************************************************************
* This method is test data for create Legal Entities
* ***********************************************************************
*/
    public static void createLegalEntities() {
        //CPQ_Generic_Settings__c settings
        List<Legal_Entity__c> legalEntitiesToInsert = new List<Legal_Entity__c>{
            new Legal_Entity__c(Name = 'United States', Legal_Entity_Address__c='Test US Address', Legal_Entity_for_Quote_Doc__c='Akamai Technologies'),
                new Legal_Entity__c(Name = 'UK', Legal_Entity_Address__c='Test UK Address', Legal_Entity_for_Quote_Doc__c='Akamai Technologies')
                };
                    insert legalEntitiesToInsert;
        
    }

/** 
* **********************************************************************************
* This method is test data for create Quote Template w/o section and contents
* **********************************************************************************
*/
    public static void createQuoteTemplate() {
        //CPQ_Generic_Settings__c settings
        SBQQ__QuoteTemplate__c quoteTemplate = new SBQQ__QuoteTemplate__c(Name='Quote Template - Partner');
        insert quoteTemplate;
        
    }

/** 
* ******************************************************
* This method is test data for CPQ Generic custom setting
* ******************************************************
*/

    public class CpqGenericCustomSettingBuilder{

        private CPQ_Generic_Settings__c newRecord;
        public cpqGenericCustomSettingBuilder(String settingName){
            newRecord = new CPQ_Generic_Settings__c(Name = settingName);
        }

        public CpqGenericCustomSettingBuilder withValue(String value){
            newRecord.CPQ_Value__c = Value;
            return this;
        }

        public CpqGenericCustomSettingBuilder withActive(Boolean isActive){
            newRecord.CPQ_Active__c = isActive;
            return this;
        }

        public void saveRecord(){
            insert newRecord;  
        }

        public CPQ_Generic_Settings__c getRecord(){
            return this.newRecord;
        }

    }

    /** 
* ******************************************************
* This method is test data for Quote
* ******************************************************
*/
    public class CpqQuoteBuilder{

        private SBQQ__Quote__c newRecord;
        public CpqQuoteBuilder(Opportunity oppty){
            newRecord = new SBQQ__Quote__c(SBQQ__Opportunity2__c = oppty.Id, SBQQ__Account__c = oppty.AccountId);
        }

        public CpqQuoteBuilder withQuoteType(String value){
            newRecord.CPQ_Quote_Type__c = Value;
            return this;
        }

        public SBQQ__Quote__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__Quote__c getRecord(){
            return newRecord;
        }

    }

    /** 
* ******************************************************
* This method is test data for Products
* ******************************************************
*/
    public class ProductBuilder{

        private Product2 newRecord;
        public ProductBuilder(String prodName, String recordType){

            RecordType recordTypeObject = [SELECT id, DeveloperName, SobjectType 
            FROM RecordType
            WHERE DeveloperName =:recordType AND SobjectType = 'Product2'];

            Integer randomInt = getindex();

            newRecord = new Product2(name = prodName, 
                                    recordTypeId = recordTypeObject.Id,
                                    AKAM_INT_ID__c = randomInt,
                                    AKAM_Product_ID__c = 'F-PRO-'+randomInt,
                                    ProductCode = 'F-PRO-'+randomInt);
        }

        public ProductBuilder withCode(String productCode){
            newRecord.ProductCode = productCode;
            return this;
        }

        public Product2 saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public ProductBuilder activate(){
            newRecord.IsActive = true;
            return this;
        }

        public Product2 getRecord(){
            return newRecord;
        }

    }

    /** 
* ******************************************************
* This method is test data for Quote Line for a given Quote
* ******************************************************
*/
    public class QuoteLineBuilder{
        
        private SBQQ__QuoteLine__c newRecord;
        public QuoteLineBuilder(SBQQ__Quote__c quote, Product2 product){

            newRecord = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = product.Id,SBQQ__NetPrice__c = 9.00);

        }

        public QuoteLineBuilder withNetPrice(Decimal netPrice){
            newRecord.SBQQ__NetPrice__c = netPrice;
            return this;
        }

        public QuoteLineBuilder withProductOption(SBQQ__ProductOption__c option){
            newRecord.SBQQ__ProductOption__c = option.Id;
            return this;
        }

        public QuoteLineBuilder withAssociatedProdId(String associatedId){
            newRecord.CPQ_Associated_Product_Id__c = associatedId;
            return this;
        }

        public QuoteLineBuilder withNumber(Integer optionNumber){
            newRecord.SBQQ__Number__c = optionNumber;
            return this;
        }
        
        public QuoteLineBuilder withUOM(String uom){
            newRecord.CPQ_Measurement__c = uom;
            return this;
        }

        public QuoteLineBuilder withBillingFrequency(String frequency){
            newRecord.CPQ_Billing_Frequency__c = frequency;
            return this;
        }

        public QuoteLineBuilder withBillingModel(String model){
            newRecord.CPQ_Billing_Model__c = model;
            return this;
        }

        public QuoteLineBuilder withChargeType(String charge){
            newRecord.CPQ_Charge_Type__c = charge;
            return this;
        }

        public QuoteLineBuilder withPricingMethod(String pricingMethod){
            newRecord.SBQQ__PricingMethod__c = pricingMethod;
            return this;
        }

        public QuoteLineBuilder withCustomName(String customName){
            newRecord.CPQ_PAC_Line_Item_Id__c = customName;
            return this;
        }

        public SBQQ__QuoteLine__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__QuoteLine__c getRecord(){
            return newRecord;
        }


    }

    /** 
* ******************************************************
* This method creates a standard pricebook which can be used to add the pricebook entries
* ******************************************************
*/

    public static Pricebook2 createStandardPriceBook(){

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        Update standardPricebook;

        return standardPricebook;
    }

/** 
* ******************************************************
* This method is test data for Price Book Entry on Standard PriceBook
* ******************************************************
*/
    public class PriceBookEntryBuilder{

        PricebookEntry newRecord;

        public PriceBookEntryBuilder(Id productId, Id priceBookId){

            newRecord = new PricebookEntry(IsActive = true, Pricebook2Id = priceBookId, Product2Id = productId);
        }

        public PriceBookEntryBuilder withCurrency(String currencyCode){
            newRecord.CurrencyIsoCode = currencyCode;
            return this;
        }

        public PriceBookEntryBuilder withPrice(Decimal price){
            newRecord.UnitPrice = price;
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


    /** 
* ******************************************************
* This method is test data for Product Feature for given Product
* ******************************************************
*/

    public class ProductFeatureBuilder{

        private SBQQ__ProductFeature__c newRecord;
        public ProductFeatureBuilder(Product2 product){

            newRecord = new SBQQ__ProductFeature__c(SBQQ__ConfiguredSKU__c = product.Id, SBQQ__Number__c=10);

        }

        public SBQQ__ProductFeature__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__ProductFeature__c getRecord(){
            return newRecord;
        }
    }

    /** 
* ******************************************************
* This method is test data for Product option for given Product and Feature
* ******************************************************
*/

    public class ProductOptionBuilder{

        private SBQQ__ProductOption__c newRecord;
        public ProductOptionBuilder(Product2 configuredProduct, Product2 optionalProduct, SBQQ__ProductFeature__c feature){

            newRecord = new SBQQ__ProductOption__c(SBQQ__ConfiguredSKU__c = configuredProduct.Id,
                                                    SBQQ__OptionalSKU__c = optionalProduct.Id,
                                                    SBQQ__Feature__c = feature.Id,
                                                    SBQQ__Selected__c = true,
                                                    SBQQ__Required__c = true);

        }

        public ProductOptionBuilder withNumber(Integer optionNumber){
            newRecord.SBQQ__Number__c = optionNumber;
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

    /** 
* ******************************************************
* This method is test data for Building the HTTP Request in AkamaiAuthEdgeStrategy Class
* ******************************************************
*/

    public class APIConnectorBuilder{

        private API_Connector_Object__c newRecord;
        public APIConnectorBuilder(String name, string host){
            newRecord = new API_Connector_Object__c(Name = name, Host__c = host,Timeout__c = 30000, Time_format__c = 'yyyyMMdd\'T\'HH:mm:ss');
        }

        public APIConnectorBuilder withClientSecret(String clientSecret){
            newRecord.Client_Secret__c = clientSecret;
            return this;
        }

        public APIConnectorBuilder withClientToken(String clientToken){
            newRecord.Client_Token__c = clientToken;
            return this;
        }

        public APIConnectorBuilder withCryptoAlgorithm(String cryptoAlgorithm){
            newRecord.Crypto_Algorithm__c = cryptoAlgorithm;
            return this;
        }

        public APIConnectorBuilder withAccessToken(String accessToken){
            newRecord.Access_Token__c = accessToken;
            return this;
        }

        public APIConnectorBuilder withNamedCredential(String namedCredentials){
            newRecord.Named_Credential__c = namedCredentials;
            return this;
        }

        public APIConnectorBuilder withMoniker(String moniker){
            newRecord.Moniker__c = moniker;
            return this;
        }

        public API_Connector_Object__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public API_Connector_Object__c getRecord(){
            return newRecord;
        }


    }

    /** 
* ******************************************************
* This method is to get the latest error log from the logger object
* ******************************************************
*/

    public static String getLatestError(){

        List<CPQ_Error_Log__c> errorLogs = [SELECT  Id,Stack_Trace__c, Message__c FROM CPQ_Error_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        if(errorLogs.size() > 0 ){
            return errorLogs[0].Message__c;
        }
        return null;
    }
    
    /**
     * ******************************************************
     * This method is test data for OM Case for given Opportunity
     * ******************************************************
     */
    public class CpqOMCaseBuilder{

        private Case newRecord;
        public CpqOMCaseBuilder(Opportunity oppty, Order_Approval__c oa, String recordType){
            RecordType recordTypeObject = [SELECT Id, DeveloperName, SobjectType 
                                            FROM RecordType
                                            WHERE DeveloperName = :recordType AND SobjectType = 'Case'];
            newRecord = new Case(Opportunity__c = oppty.Id,
                                AccountId = oppty.AccountId,
                                Order_Approval__c = oa.Id,
                                RecordTypeId = recordTypeObject.Id);
        }

        public CpqOMCaseBuilder withOrderType(String value){
            newRecord.Order_Type__c = Value;
            return this;
        }

        public CpqOMCaseBuilder withOrigin(String value){
            newRecord.Origin = value;
            return this;
        }

        public CpqOMCaseBuilder withStatus(String value){
            newRecord.Status = value;
            return this;
        }

        public CpqOMCaseBuilder withValidationOverride(Boolean value){
            newRecord.Validation_Override__c = value;
            return this;
        }

        public Case saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public Case getRecord(){
            return newRecord;
        }

    }

    /**
     * ******************************************************
     * This method is test data for OM Case for given Opportunity
     * ******************************************************
     */
    public class CpqApprovalDetailBuilder{
        
        private Approval_Details__c newRecord;
        public CpqApprovalDetailBuilder(Order_Approval__c oaRec, Case caseRec){
            newRecord = new Approval_Details__c(AKAM_Approved_Date__c = Date.today(),
                                                Approval_Requested_By__c = UserInfo.getUserId(),
                                                Order_Approval__c = oaRec.Id,
                                                Related_To__c = caseRec.Id);
        }

        public CpqApprovalDetailBuilder withRequestType(String value){
            newRecord.Approval_Request__c = value;
            return this;
        }

        public CpqApprovalDetailBuilder withDescription(String value){
            newRecord.Approval_Details_Description__c = value;
            return this;
        }

        public CpqApprovalDetailBuilder withStatus(String value){
            newRecord.Approval_Status__c = value;
            return this;
        }

        public CpqApprovalDetailBuilder withApproverNotes(String value){
            newRecord.Approver_Notes__c = value;
            return this;
        }

        public CpqApprovalDetailBuilder withValidationOverride(Boolean value){
            newRecord.Validation_Override__c = value;
            return this;
        }

        public Approval_Details__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public Approval_Details__c getRecord(){
            return newRecord;
        }

    }

    /**
     * ******************************************************
     * This method is test data for Document Generation for the quote. Added on 05/04/2020 by shegade
     * ******************************************************
     */

    public class QuoteDocumentBuilder{

        private SBQQ__QuoteDocument__c newRecord;

        public QuoteDocumentBuilder(Id quoteId, Id attachmentId){
            this.newRecord = new SBQQ__QuoteDocument__c(SBQQ__Quote__c = quoteId, SBQQ__AttachmentId__c = attachmentId);
        }

        public SBQQ__QuoteDocument__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__QuoteDocument__c getRecord(){
            return newRecord;
        }
    }

    /**
     * ******************************************************
     * This method is test data for Attachments. Added on 05/04/2020 by shegade
     * ******************************************************
     */

    public class AttachmentBuilder{
        private Attachment newRecord;

        public AttachmentBuilder(Id parentId, String bodyString){
            this.newRecord = new Attachment();
            this.newRecord.Body=Blob.valueOf(bodyString);
            this.newRecord.Name='test_' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.txt';
            this.newRecord.parentId=parentId;
        }

        public Attachment saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public Attachment getRecord(){
            return newRecord;
        }
    }


    /**
     * ******************************************************
     * This method is test data for Product Rule. Added on 28/09/2021 by shegade
     * ******************************************************
     */
    public class ProductRuleBuilder{
        private SBQQ__ProductRule__c newRecord;

        public ProductRuleBuilder(String name){

            this.newRecord = new SBQQ__ProductRule__c();
            this.newRecord.Name = name;
            this.newRecord.SBQQ__ConditionsMet__c = 'All';
            this.newRecord.SBQQ__Scope__c = 'Product';
            this.newRecord.SBQQ__Type__c = 'Selection';
            this.newRecord.SBQQ__EvaluationEvent__c = 'Always';
        }

        public SBQQ__ProductRule__c saveRecord(){
            insert newRecord;
            return  newRecord; 
        }

        public SBQQ__ProductRule__c getRecord(){
            return newRecord;
        }
    }


}