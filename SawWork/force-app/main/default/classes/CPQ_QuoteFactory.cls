/**
* This class converts the quote line data of a quote into a list of apex object which are used to display the data on pdf and excel outputs
* Test Class: CPQ_printLineItemsTest
* @author  Shashank Hegade, Kirti Mishra
* @version 1.0
* @since   2020-08-21
*/
public without sharing class CPQ_QuoteFactory {

    private static final Set<String> INTEGRATION_LINES = CPQSettings.getMetadataValues('autonomyIntegrationProducts');
    private static final Set<String> INTEGRATION_BUNDLE_CODES = CPQSettings.getMetadataValues('autonomyIntegrationBundleProductCodes');

    private static final Map<String, String> BILL_FREQ = new Map<String, String>{
        'Monthly' => 'per month',
        'Annual' => 'per year',
        'One-Time' => 'one time'};
    private static final Set<String> QL_NET_TOTAL_ONLY = new Set<String>{'Base Fee', 'Flat Fee', 'Monthly Fee', 'One Time Fee'}; //set of QL names which should show only netTotal and billing frequency
   
    private Map<String, Product2> prodCodeNameMap;
    private Map<Id, SBQQ__QuoteLine__c> mapQlines;
    
    public Set<Id> solutionProdLineIds {get;set;}
    public Set<String> mainProdIds {get;set;}
    public QuoteWrapper quoteData {get;set;}
    public Map<String, Object> uomPluralMappings {get;set;}
    public Map<String, Object> currencyCodeSymbolMappings {get;set;}
    public Decimal monthlyFees {get;set;}
    public Decimal yearlyFees {get;set;}
    public Decimal oneTimeFees {get;set;}
    public Decimal projectedMinOrderValue {get;set;}
    public Boolean intProdExists {get; set;}
    public Boolean stdSupportExists {get; set;}
    public Boolean excludeAdjustableFees {get; set;}
    Map<Id, List<SBQQ__QuoteLine__c>> mapQlinesByReqGroup {get; set;}
    Map<String,Decimal> includedUnits { get; set; }
    

    public without sharing class  QuoteWrapper extends CPQ_QuoteWrapper {

        public QuoteWrapper(Id quoteId){

            super();

            this.quoteId = quoteId;
            SBQQ__Quote__c quoteRecord = [SELECT Id, Name, CurrencyIsoCode
                                        FROM SBQQ__Quote__c
                                        WHERE Id = :quoteId LIMIT 1];
            if(quoteRecord != null){
                this.name = quoteRecord.name;
                this.currencyCode = quoteRecord.CurrencyIsoCode; 
            }

            this.productLines = new List<QuoteLineWrapper>();
            this.integrationLines = new List<QuoteLineWrapper>();

        }
    }

    public class QuoteLineWrapper extends CPQ_QuoteLineWrapper implements Comparable{
        
        Integer order {get; set;}
        Decimal groupId { get; set; }
        Boolean additionalUnit { get; set; }

        public QuoteLineWrapper(){
            super();
        }

        public QuoteLineWrapper(Id quoteLineId){
            super();
            this.Id = quoteLineId;
            this.order = 0;
            this.groupId = 0;
            this.additionalUnit = false;
        }

        public Integer compareTo(Object compare){
            
            QuoteLineWrapper compareToLine = (QuoteLineWrapper)compare;

             if(this.order > compareToLine.order){
                 return 1;
             }
             else{
                 return -1;
             }
        }


    }


    public CPQ_QuoteFactory(Id recordId) {

        this.quoteData = new QuoteWrapper(recordId);
        this.uomPluralMappings = CPQSettings.getMetadataValueMap('uomPluralMappings');
        this.currencyCodeSymbolMappings = CPQSettings.getMetadataValueMap('currencyCodeSymbolMappings');

        if(this.currencyCodeSymbolMappings.containsKey(this.quoteData.currencyCode)){
            this.quoteData.currencySymbol = (String) currencyCodeSymbolMappings.get(this.quoteData.currencyCode);
        }

        this.mainProdIds = new Set<String>();
        this.solutionProdLineIds = new Set<Id>();
        this.monthlyFees = 0.0;
        this.yearlyFees = 0.0;
        this.oneTimeFees = 0.0;
        this.projectedMinOrderValue = 0.0;
        this.intProdExists = false;
        this.stdSupportExists= false;
        this.excludeAdjustableFees = false;
        this.mapQlinesByReqGroup = new map<Id,List<SBQQ__QuoteLine__c>>();
        this.prodCodeNameMap = new Map<String, Product2>();
        this.includedUnits = new Map<String, Decimal>();
        this.mapQlines = new Map<Id, SBQQ__QuoteLine__c>();


    }

    /**
     * generateQuoteData method is the main class which accommodates all the methods which help in generating the quote data 
     * @return CPQ_QuoteWrapper which is the custom apex object structure to hold the quote and quoteline data 
     * @see                     CPQ_QuoteWrapper 
     */
    public CPQ_QuoteWrapper generateQuoteData(){

        try{

            Set<Id> prodIds = new Set<Id>();
            Set<Id> qlIds = new Set<Id>();
            Set<Id> leftQlIds = new Set<Id>();
            Map<String, List<SBQQ__QuoteLine__c>> mapQlinesByProdCode = new Map<String, List<SBQQ__QuoteLine__c>>();
            Map<Id, Product2> mapIdProd = new Map<Id, Product2>();
            Set<String> solutionProdCode = new Set<String>();
            Map<Id, List<SBQQ__QuoteLine__c>> reqByIdcommitQls = new Map<Id, List<SBQQ__QuoteLine__c>>();
            Set<Id> solutionFLProds = new Set<Id>(); //first level products under solution

            Map<Id, SBQQ__QuoteLine__c> mapQlines = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, Name,
                                                                                        SBQQ__ProductOption__c, 
                                                                                        SBQQ__Product__c,
                                                                                         SBQQ__ProductOption__r.SBQQ__Feature__c,
                                                                                         SBQQ__ProductOption__r.SBQQ__Feature__r.Name,
                                                                                         SBQQ__ProductOption__r.SBQQ__Feature__r.SBQQ__Number__c,
                                                                                         SBQQ__ProductOption__r.CPQ_AdditionalUnits__c,
                                                                                         SBQQ__ProductCode__c, 
                                                                                         UOM__c, 
                                                                                         SBQQ__Quantity__c,
                                                                                         SBQQ__Bundled__c, 
                                                                                         SBQQ__RequiredBy__c, 
                                                                                         SBQQ__RequiredBy__r.SBQQ__ProductName__c,
                                                                                         SBQQ__ProductName__c, 
                                                                                         SBQQ__PricingMethod__c,
                                                                                         SBQQ__NetPrice__c, 
                                                                                         SBQQ__NetTotal__c,
                                                                                         SBQQ__EffectiveSubscriptionTerm__c,
                                                                                         CPQ_Overage__c,
                                                                                         CPQ_FinalOverage__c,
                                                                                         CPQ_Associated_Product_Id__c,
                                                                                         SBQQ__Number__c,
                                                                                         CPQ_Charge_Type__c,
                                                                                         SBQQ__SpecialPrice__c,
                                                                                         CPQ_Measurement__c,
                                                                                         CPQ_Billing_Model__c,
                                                                                         CPQ_Time_Period__c,
                                                                                         SBQQ__SegmentLabel__c,
                                                                                         CPQ_Monthly_Fee__c,
                                                                                         CPQ_Revenue_Commitment__c,
                                                                                         CPQ_Billing_Frequency__c,
                                                                                         CPQ_PAC_Line_Item_Id__c,
                                                                                         SBQQ__Quote__r.CPQ_Term_Months__c,
                                                                                         SBQQ__Discount__c,
                                                                                         CPQ_FinalNetPrice__c
                                                                                         FROM SBQQ__QuoteLine__c
                                                                                         WHERE SBQQ__Quote__c =:quoteData.quoteId
                                                                                          AND SBQQ__ComponentVisibility__c != 'Never'	//not showing included products
                                                                                         ORDER BY SBQQ__Number__c, SBQQ__SegmentIndex__c]);

            Set<String> productCodeSet = new Set<String>();
            for (SBQQ__QuoteLine__c qline : mapQlines.values()) {
                //get all prod ids
                prodIds.add(qline.SBQQ__Product__c);
                String associatedProdId = qline.CPQ_Associated_Product_Id__c;
                productCodeSet.add(associatedProdId);
                if(INTEGRATION_LINES.contains(associatedProdId)){
                    //add prod
                    List<SBQQ__QuoteLine__c> tempList = new List<SBQQ__QuoteLine__c>();
                    if(mapQlinesByProdCode.containsKey(associatedProdId)){
                        tempList = mapQlinesByProdCode.get(associatedProdId);
                    }
                    tempList.add(qline);
                    mapQlinesByProdCode.put(associatedProdId, tempList);
                }
                else if (String.isBlank(qline.SBQQ__RequiredBy__c)) {

                    solutionProdLineIds.add(qline.Id);

                    List<SBQQ__QuoteLine__c> tempList1 = new List<SBQQ__QuoteLine__c>();
                    if(!mapQlinesByReqGroup.containsKey(qline.Id)){
                        mapQlinesByReqGroup.put(qline.Id, tempList1); 
                    } 

                    
                }
                else {

                    SBQQ__QuoteLine__c parentLine  = mapQlines.get(qline.SBQQ__RequiredBy__c);

                    List<SBQQ__QuoteLine__c> tempList1 = new List<SBQQ__QuoteLine__c>();
                    if(mapQlinesByReqGroup.containsKey(qline.SBQQ__RequiredBy__c)){
                        tempList1 = mapQlinesByReqGroup.get(qline.SBQQ__RequiredBy__c);
                    } 
                    tempList1.add(qline);
                    mapQlinesByReqGroup.put(qline.SBQQ__RequiredBy__c, tempList1);

                    
                }

                
                    Decimal quantity = 0;
                    String uniqueKey = getUniqueKey(qline);
                    if(includedUnits.containsKey(uniqueKey)){
                        quantity = includedUnits.get(uniqueKey);
                    }

                    quantity = quantity + qline.SBQQ__Quantity__c;
                    includedUnits.put(uniqueKey, quantity);
                
                //calculate fees
                // monthlyFees += qline.SBQQ__NetTotal__c;
                if(qline.CPQ_Billing_Frequency__c == 'Monthly' && qline.CPQ_Billing_Model__c != 'Straight Line Commitment' && qline.CPQ_Billing_Model__c != 'Usage Commitment'){
                    if (qline.SBQQ__PricingMethod__c == 'Block') {
                        monthlyFees += netPriceCalculator(qLine);//qline.SBQQ__SpecialPrice__c;
                    } else{
                        monthlyFees += netTotalCalculator(qLine);//(qline.SBQQ__SpecialPrice__c * qline.SBQQ__Quantity__c);
                    }
                } 
                else if (qline.CPQ_Billing_Frequency__c == 'Monthly' && qline.CPQ_Billing_Model__c == 'Straight Line Commitment') {
                    if (qline.SBQQ__PricingMethod__c == 'Block') {
                        monthlyFees += (netPriceCalculator(qLine) / qline.SBQQ__Quote__r.CPQ_Term_Months__c);
                    } else{
                        monthlyFees += (netTotalCalculator(qLine) / qline.SBQQ__Quote__r.CPQ_Term_Months__c);
                    }
                    
                }
                else if (qline.CPQ_Billing_Frequency__c == 'Annual') {
                    yearlyFees += netPriceCalculator(qLine);//qline.SBQQ__SpecialPrice__c;

                } else if(qline.CPQ_Billing_Frequency__c == 'One-Time'){
                    oneTimeFees += netTotalCalculator(qLine);
                }
                projectedMinOrderValue += qline.SBQQ__NetTotal__c;
            }            

        //Assignments

            quoteData.monthlyFees = monthlyFees;
            quoteData.yearlyFees = yearlyFees;
            quoteData.oneTimeFees = oneTimeFees;
            quoteData.projectedMinOrderValue = projectedMinOrderValue;

        //end

            //TODO: There is a scope to improve this logic of finding the product Name while creating the quote line wrapper using a single helper method
            mapIdProd = new Map<Id, Product2>([SELECT Id, Name, ProductCode, Description, CPQ_IncludedFeatures__c
                                               FROM Product2
                                               WHERE RecordType.Name = 'Partner Products' AND (Id IN :prodIds OR ProductCode IN :productCodeSet)]);
            for(Product2 prod : mapIdProd.values()) {
                if(!prodCodeNameMap.containsKey(prod.ProductCode)) {
                    prodCodeNameMap.put(prod.ProductCode, prod);
                }
            }

        

        for(Id solutionLineId : solutionProdLineIds){

            List<QuoteLineWrapper> tempStorage = new List<QuoteLineWrapper>();

            SBQQ__QuoteLine__c solutionLine =  mapQlines.get(solutionLineId);  
            String associatedProdId = solutionLine.SBQQ__ProductCode__c; 
        
            QuoteLineWrapper mainLine = new QuoteLineWrapper(solutionLineId);
            mainLine.productCode = prodCodeNameMap.get(associatedProdId).Name;
            mainLine.prodMrktCode = associatedProdId;
            mainLine.name = prodCodeNameMap.get(associatedProdId).Name;
            mainLine.isMain = true;
            mainLine.isFLProd = true;
            mainLine.billingModel = solutionLine.CPQ_Billing_Model__c;
            mainLine.prodDesc = prodCodeNameMap.get(associatedProdId).Name;
            mainLine.usage = false;

            Set<String> includedFeaturesSet = prodCodeNameMap.get(associatedProdId).CPQ_includedFeatures__c != null ? new Set<String>(prodCodeNameMap.get(associatedProdId).CPQ_includedFeatures__c.split(';')): new Set<String>();

            tempStorage.add(mainLine);

            for(SBQQ__QuoteLine__c optionQL: mapQlinesByReqGroup.get(solutionLineId)){

                List<QuoteLineWrapper> sublineTempStorage = createSublineBundles(this,solutionLine,optionQL);
                
                if(sublineTempStorage == null || sublineTempStorage.size() == 0){
                    //this is a direct subline under mainLine
                    List<QuoteLineWrapper> sublines = createSubline(this,optionQL);

                    for(QuoteLineWrapper subline: sublines ){
                        if(subline.billingModel == 'Fee'){
                            tempStorage[0].quoteLines.add(subline);
                            //tempStorage[0].billingModel = 'Fee';
                            
                        }
                        else{
                            tempStorage[0].periodCommitLines.add(subline);
                            tempStorage[0].billingModel = subline.billingModel;
                        }

                    }

                    tempStorage[0].quoteLines.sort();
                    
                }
                else{
                    //This has furter configuration
                    for(QuoteLineWrapper item: sublineTempStorage){
                        
                        if(item.additionalUnit){
                            // if the subline is additional unit then add it separately 
                            tempStorage.add(item);
                            continue;
                        }
                        Integer sublineIndex = checkSublineProductCode(tempStorage, item);
                        if(sublineIndex == -1){
                            //if the quote line bundle does not have included commitment to combine with
                            includedFeaturesSet.add(item.name);
                            tempStorage.add(item);
                        }
                        else {
                            // if quote line bundle has included commitment to combine with
                            tempStorage[sublineIndex].quoteLines.addAll(item.quoteLines);
                            tempStorage[sublineIndex].periodCommitLines.addAll(item.periodCommitLines);
                            tempStorage[sublineIndex].quoteLines.sort();
                        }
                    }
                }

             
            }
            tempStorage[0].prodDesc = includedFeaturesSet.size() > 0 ? tempStorage[0].prodDesc + ' - ' + String.join(new List<String>(includedFeaturesSet),',').replace('&', CPQ_UtilityClass.specialCharacterReplacement('&')): '';
            quoteData.productLines.addAll(tempStorage);

        }


        quoteData.integrationLines.addAll(createIntegrationLines(mapQlinesByProdCode));
        if(quoteData.integrationLines.size() > 0){
                quoteData.intProdExists = true;
            }
        
        }
        catch(Exception e){
            CPQ_LogException.errors.add( new CPQ_LogException(e,null).setShortMessage('CPQ_QuoteFactory: Error in generateQuoteData method').getErrorRecord());

       }
       finally{
            CPQ_LogException.flush();
            CPQ_LogException.clear();
       }

       System.debug(JSON.serialize(quoteData));

       return quoteData;
    }

    /**
     * createSublineBundles method is used create the sub bundles under a main products. This mehtod is used as recursive method
     * @param instance it is an instance of the main quote factory class which holds all the meta data required to create the sub lines.
     * @param parent   it is parent quote line on which the sub bundle needs to be created.
     * @param optionQL it is quote line belongs to the sub bundle.
     * @return         ist of QuoteLineWrapper , which is collection of all the sub bundles under the main bundle 
     * @see            QuoteLineWrapper 
     */

    private static List<QuoteLineWrapper> createSublineBundles(CPQ_QuoteFactory instance, SBQQ__QuoteLine__c parent, SBQQ__QuoteLine__c optionQL){

        List<QuoteLineWrapper> tempStorage = new List<QuoteLineWrapper>();

        if(parent.Id == optionQL.Id){
            return tempStorage;
        }

        if(parent.SBQQ__ProductCode__c == optionQL.CPQ_Associated_Product_Id__c && optionQL.SBQQ__ProductOption__r.CPQ_AdditionalUnits__c == false){
            //if child and parent have same associated product id and the the quote line is not the additional commitment for the included UOM
            return tempStorage;
        }
        
        if(optionQL.SBQQ__ProductOption__r.CPQ_AdditionalUnits__c == true && instance.mapQlinesByReqGroup.containsKey(optionQL.Id) ){
            return tempStorage;
        }
        
        if( !instance.mapQlinesByReqGroup.containsKey(optionQL.Id)){
            //if the product code is diffrent and the map does not contains the key mean, it's a standalone product with no additional configuration, but included to bundle
            instance.mapQlinesByReqGroup.put(optionQL.Id,new List<SBQQ__QuoteLine__c>{optionQL});
        }
        
       

        //SBQQ__QuoteLine__c mainSubLine =  instance.mapQlines.get(solutionLineId);  //100%
        String associatedProdId = optionQL.CPQ_Associated_Product_Id__c; // ??
    
        QuoteLineWrapper mainLine = new QuoteLineWrapper(optionQL.Id);
        mainLine.productCode = instance.prodCodeNameMap.get(associatedProdId).Name;
        mainLine.prodMrktCode = associatedProdId;
        mainLine.name = instance.prodCodeNameMap.get(associatedProdId).Name;
        mainLine.isMain = true;
        mainLine.isFLProd = false;
        mainLine.billingModel = optionQL.CPQ_Billing_Model__c;
        mainLine.prodDesc = instance.prodCodeNameMap.get(associatedProdId).Description;
        mainLine.usage = false;
        mainLine.additionalUnit = optionQL.SBQQ__ProductOption__r.CPQ_AdditionalUnits__c;

        tempStorage.add(mainLine);

        for(SBQQ__QuoteLine__c subQL: instance.mapQlinesByReqGroup.get(optionQL.Id)){
            
            List<QuoteLineWrapper> sublineTempStorage = createSublineBundles(instance,optionQL,subQL);
            
            if(sublineTempStorage == null || sublineTempStorage.size() == 0){
                //this is a direct subline under mainLine
                List<QuoteLineWrapper> sublines = createSubline(instance,subQL);

                for(QuoteLineWrapper subline: sublines ){
                    if(subline.billingModel == 'Fee'){
                        tempStorage[0].quoteLines.add(subline);
                        //tempStorage[0].billingModel = 'Fee';
                        
                    }
                    else{
                        tempStorage[0].periodCommitLines.add(subline);
                        tempStorage[0].billingModel = subline.billingModel;
                    }

                    
                }

                tempStorage[0].quoteLines.sort();
                
            }
            else{
                //This has furter configuration
                for (QuoteLineWrapper subline : sublineTempStorage) {

                    if(subline.additionalUnit){
                        // if the subline is additional unit then add it separately 
                        tempStorage.add(subline);
                        continue;
                    }
                    
                    Integer sublineIndex = checkSublineProductCode(tempStorage, subline);

                    if(sublineIndex == -1 ){
                        tempStorage.add(subline);
                    }
                    else {

                        tempStorage[sublineIndex].quoteLines.addAll(subline.quoteLines);
                        tempStorage[sublineIndex].periodCommitLines.addAll(subline.periodCommitLines);
                        tempStorage[sublineIndex].quoteLines.sort();
                        
                    }
                }
                
                //tempStorage.addAll(sublineTempStorage);
            }

         
        }

        return tempStorage;


    }

    /**
     * createSubline method which converts the individual quote line into QuoteLineWrapper structure 
     * @param instance is an instance of the main quote factory class which holds all the meta data required to create the sub lines.
     * @param optionQL individual quote line
     * @return         list of QuoteLineWrapper , which is collection of all the sub bundles under the main bundle 
     * @see            QuoteLineWrapper 
     */
    private static List<QuoteLineWrapper> createSubline(CPQ_QuoteFactory instance ,SBQQ__QuoteLine__c optionQL){

        List<QuoteLineWrapper> tempQuoteLineWrapperList = new List<QuoteLineWrapper>();

        String pluralUom = '';
        String singularUom = '';
        String finalUom = '';
        if(String.isNotBlank(optionQL.CPQ_Measurement__c)){
            pluralUom = optionQL.CPQ_Measurement__c;
            singularUom = optionQL.CPQ_Measurement__c; // uom like Million Hits plural / singular will be used same
            if(instance.uomPluralMappings.containsKey(optionQL.CPQ_Measurement__c)){
                singularUom = (String) instance.uomPluralMappings.get(optionQL.CPQ_Measurement__c);
            }
        }
        finalUom = pluralUom; // to be used with quantity
        if(optionQL.SBQQ__Quantity__c <= 1){
                finalUom = singularUom;
        }


        Decimal groupId = optionQL.SBQQ__ProductOption__r.SBQQ__Feature__r.SBQQ__Number__c == null ? computeOrder(optionQL.SBQQ__ProductName__c) : optionQL.SBQQ__ProductOption__r.SBQQ__Feature__r.SBQQ__Number__c;

        if (optionQL.CPQ_Billing_Model__c == 'Usage Commitment') {
            instance.quoteData.excludeAdjustableFees = true;

            QuoteLineWrapper tempLine = new QuoteLineWrapper(optionQL.Id);
            tempLine.timePeriod = optionQL.CPQ_Time_Period__c;
            tempLine.name = optionQL.CPQ_Time_Period__c;
            tempLine.quantity = String.valueOf(optionQL.SBQQ__Quantity__c.format())+' '+ finalUom;
            tempLine.netQuantity = optionQL.SBQQ__Quantity__c.round();
            //tempLine.netPrice = optionQL.SBQQ__SpecialPrice__c;
            tempLine.netPrice = netPriceCalculator(optionQL);
            tempLine.rateSuffix = ' per ' + singularUom;
            tempLine.billingModel = 'Usage';
            tempLine.commitType = optionQL.CPQ_Revenue_Commitment__c;
            tempLine.netTotal = optionQL.CPQ_Revenue_Commitment__c;
            tempLine.overageRate = optionQL.CPQ_FinalOverage__c;
            tempLine.prodMrktCode = optionQL.CPQ_Associated_Product_Id__c;
            tempLine.billingFrequency = optionQL.CPQ_Billing_Frequency__c;
            tempLine.order = getOrder( groupId , computeOrder(tempLine.name));
            tempLine.groupId = groupId;

            tempQuoteLineWrapperList.add(tempLine);
            
        } else if (optionQL.CPQ_Billing_Model__c == 'Straight Line Commitment' ) {
            instance.quoteData.excludeAdjustableFees = true;

            QuoteLineWrapper tempLine = new QuoteLineWrapper(optionQL.Id);
            tempLine.timePeriod = optionQL.CPQ_Time_Period__c;
            tempLine.name = optionQL.CPQ_Time_Period__c; 
            tempLine.quantity = String.valueOf(optionQL.SBQQ__Quantity__c.format())+' '+ finalUom;
            tempLine.netQuantity = optionQL.SBQQ__Quantity__c.round();
            //tempLine.netPrice = optionQL.SBQQ__SpecialPrice__c;
            tempLine.netPrice = netPriceCalculator(optionQL);
            tempLine.rateSuffix = ' per ' + singularUom;
            tempLine.billingModel = 'straightLine';
            tempLine.commitType = optionQL.CPQ_Monthly_Fee__c; 
            tempLine.netTotal = optionQL.CPQ_Monthly_Fee__c;
            tempLine.overageRate = optionQL.CPQ_FinalOverage__c;
            tempLine.prodMrktCode = optionQL.CPQ_Associated_Product_Id__c;
            tempLine.billingFrequency = optionQL.CPQ_Billing_Frequency__c;
            tempLine.order = getOrder( groupId , computeOrder(tempLine.name));
            tempLine.groupId = groupId;
            tempQuoteLineWrapperList.add(tempLine);

        }
        
        else {
            
            

            QuoteLineWrapper tempLine = new QuoteLineWrapper(optionQL.Id);
            tempLine.name = optionQL.CPQ_Charge_Type__c == 'Quantity based commit' ? 'Base Fee' : optionQL.SBQQ__ProductOption__r.CPQ_AdditionalUnits__c ? 'Additional ' + finalUom + ': Up to': (String.isNotBlank(optionQL.CPQ_PAC_Line_Item_Id__c) ? optionQL.CPQ_PAC_Line_Item_Id__c : optionQL.CPQ_Charge_Type__c); //QBC type QL condition added - [CPQ-566]
            tempLine.billingFrequency = BILL_FREQ.get(optionQL.CPQ_Billing_Frequency__c);
            tempLine.quantity = tempLine.name == 'Included' || tempLine.name == 'Included Units' ? String.valueOf(optionQL.SBQQ__Quantity__c.format())+' ' + finalUom : (QL_NET_TOTAL_ONLY.contains(tempLine.name) ? '' : String.valueOf(optionQL.SBQQ__Quantity__c.format())+' ' + finalUom +' '+tempLine.billingFrequency); // billing frequency included with qty except for Included rows
            tempLine.netQuantity = optionQL.SBQQ__Quantity__c.round();
            tempLine.netPrice = QL_NET_TOTAL_ONLY.contains(tempLine.name) ? 0.0 : netPriceCalculator(optionQL);//optionQL.SBQQ__SpecialPrice__c;
            tempLine.rateSuffix = QL_NET_TOTAL_ONLY.contains(tempLine.name) ? '' : ' per ' + singularUom;
            tempLine.netTotal = optionQL.CPQ_Billing_Frequency__c == 'One-Time' ? optionQL.SBQQ__NetPrice__c : netTotalCalculator(optionQL);//(optionQL.SBQQ__SpecialPrice__c * optionQL.SBQQ__Quantity__c);

            if (optionQL.SBQQ__PricingMethod__c == 'Block') {
                tempLine.netPrice = 0.0;
                tempLine.rateSuffix = '';
                //if the pricing method is blank the net total for the month is same as the net price
                tempLine.netTotal = netPriceCalculator(optionQL);//optionQL.SBQQ__SpecialPrice__c;
            }
            if (optionQL.SBQQ__Bundled__c) {
                tempLine.name = tempLine.rateSuffix = 'Included';
                tempLine.netPrice = 0.0;
            }

            tempLine.billingModel = 'Fee';
            tempLine.prodMrktCode = optionQL.CPQ_Associated_Product_Id__c;
            tempLine.order = getOrder( groupId , computeOrder(tempLine.name));
            tempLine.groupId = groupId;
            

            tempQuoteLineWrapperList.add(tempLine);
            
            //add Included line if QL is type QBC - [CPQ-566]
            if (optionQL.CPQ_Charge_Type__c == 'Quantity based commit') {
                
                QuoteLineWrapper tempLine1 = new QuoteLineWrapper(optionQL.Id);
                tempLine1.Name = optionQL.SBQQ__ProductOption__r.CPQ_AdditionalUnits__c ? 'Additional ' + finalUom + ': Up to' : 'Included ' + finalUom + ': Up to';
                tempLine1.quantity = String.valueOf(optionQL.SBQQ__Quantity__c.format())+' ' + finalUom;
                tempLine1.netQuantity = optionQL.SBQQ__Quantity__c.round();
                tempLine1.rateSuffix = 'Included';
                tempLine1.billingModel = 'Fee';
                tempLine1.billingFrequency = BILL_FREQ.get(optionQL.CPQ_Billing_Frequency__c);
                tempLine1.prodMrktCode = optionQL.CPQ_Associated_Product_Id__c;
                tempLine1.order = getOrder( groupId , computeOrder(tempLine1.name));
                tempLine1.groupId = groupId;
                

                tempQuoteLineWrapperList.add(tempLine1);

            }

            //add dummy Overage line
            if (optionQL.CPQ_Overage__c > 0) {
                
                Decimal overageQuantity =  instance.includedUnits.get(getUniqueKey(optionQL)).round();
                QuoteLineWrapper overageLine = new QuoteLineWrapper(optionQL.Id);
                if((optionQL.CPQ_Charge_Type__c == 'Included' || optionQL.CPQ_Charge_Type__c == 'Included Units') && overageQuantity > optionQL.SBQQ__Quantity__c){
                    //Included line with overage quantity greater than included quantity has additional commitment
        
                    return tempQuoteLineWrapperList;
                }

                overageLine.name = 'Usage Rate for Overage';
                overageLine.billingFrequency = BILL_FREQ.get(optionQL.CPQ_Billing_Frequency__c);
                overageLine.quantity = 'over '+ overageQuantity.intValue().format() +' '+pluralUom+' '+overageLine.billingFrequency; 
                overageLine.netQuantity = overageQuantity;
                overageLine.netPrice = optionQL.CPQ_FinalOverage__c;
                overageLine.rateSuffix = ' per ' + singularUom;
                overageLine.overageRate = optionQL.CPQ_FinalOverage__c;
                overageLine.billingModel = 'Fee';
                overageLine.prodMrktCode = optionQL.CPQ_Associated_Product_Id__c;
                overageLine.order = getOrder( groupId , computeOrder(overageLine.name));
                overageLine.groupId = groupId;
                
                

                tempQuoteLineWrapperList.add(overageLine);

            }
        }

        return tempQuoteLineWrapperList;
    }

    /**
     * computeOrder is a helper method to generate the order number for a quote line 
     * @param lineName is the name of the quote line
     * @return Integer is the number assigned to quote line which represents it's order based on the name
     */
    
    private static Integer computeOrder(String lineName){
        
        Integer orderValue = 0;

        switch on lineName {
            when 'Base Fee' {
                orderValue  = 10;
            }
            when 'Monthly Fee' {
                orderValue  = 20;
            }
            when 'Flat Fee' {
                orderValue  = 30;
            }
            when 'Included' {
                orderValue = 40;
            }
            when 'Commitment'{
                orderValue = 50;
            }
            when 'Usage Rate for Overage'{
                orderValue = 60;
            }
            when else {
                orderValue = 70;
            }
        }

        if(lineName.contains('Included')){
            orderValue = 40;
        }

        return orderValue;

    }

    /**
     * checkSublineProductCode is a helper method to check if the main bundle already has a product with product code of the subline 
     * @param tempStorage is list of all the objectified quote lines so for
     * @param subline is the line which needs to checked inside the tempstorage
     * @return Integer index in the tempStorage if the subline found , else -1
     */

    private static Integer checkSublineProductCode(List<QuoteLineWrapper> tempStorage , QuoteLineWrapper subline){

        
        for(QuoteLineWrapper item: tempStorage){
            if(item.prodMrktCode == subline.prodMrktCode){
                return tempStorage.indexOf(item);   
            }
        }

        return -1;
    }

    /**
     * getOrder is a helper method which combines the feature number and the order to give the sorting nubmer to quote line 
     * @param feature is feature number of the quote line
     * @param order is order number of the quote line
     * @return Integer which represents the sorting number for quote line
     */

    private static Integer getOrder ( Decimal feature, Integer order){
        
        String concatNumber = String.valueOf(feature) + String.valueOf(order);

        return Integer.valueOf(concatNumber);

    }

    /**
     * getUniqueKey is a helper method which combines some values on the line to generate a unique key for the particular category  
     * @param qline quote line
     * @return string is the key associated with quote line
     */

    private static string getUniqueKey(SBQQ__QuoteLine__c qline){

        return (String)qline.SBQQ__RequiredBy__c + qline.CPQ_Associated_Product_Id__c + qline.CPQ_Measurement__c;

    }

    /**
     * netPriceCalculator method calculates the net price of a line item based on the unit price and the additional discount applicable to it
     * @param qline quote line
     * @return Decimal net price of the quote line
     */

    private static Decimal netPriceCalculator(SBQQ__QuoteLine__c qLine){
        
        return qLine.CPQ_FinalNetPrice__c;
        
    }

    /**
     * netTotal method calculates the net total of a line item based on the quantity
     * @param qline quote line
     * @return Decimal net total of the quote line
     */

    private static Decimal netTotalCalculator(SBQQ__QuoteLine__c qLine){

        return netPriceCalculator(qLine) * qLine.SBQQ__Quantity__c ;

    }


    private List<QuoteLineWrapper> createIntegrationLines(Map<String, List<SBQQ__QuoteLine__c>> mapQlinesByProdCode){

        List<QuoteLineWrapper> returnList = new List<QuoteLineWrapper>();
        List<QuoteLineWrapper> tempBundleLines = new List<QuoteLineWrapper>();
        /* the products which are bundled and grouped based on the associated product Id of the option
        */
        for(string associatedProdId: INTEGRATION_BUNDLE_CODES){
            

            Map<String, QuoteLineWrapper> tempLines = new Map<String,QuoteLineWrapper>();
            Set<String> includedItem = new Set<String>();
            Decimal tempNetPrice = 0.0;

            List<SBQQ__QuoteLine__c> integrationLines = mapQlinesByProdCode.remove(associatedProdId);
            // continue if the product code does not exists in the map
            if(integrationLines == null){
                continue;
            }
            /* Aggregate the lines find the net total
            * create Integration main line
            * check if the subline product code have the dependency 
            * create included subline
            */

            QuoteLineWrapper tempIntLine = new QuoteLineWrapper(null);
            tempIntLine.billingFrequency = 'one time';
            tempIntLine.prodMrktCode = associatedProdId;
            tempIntLine.productCode = prodCodeNameMap.get(associatedProdId).Name;  
            tempIntLine.isMain = true;
            tempIntLine.isFLProd = true;
            tempIntLine.prodDesc = prodCodeNameMap.get(associatedProdId).Description;
            tempIntLine.usage = true;
            tempIntLine.name = 'One Time Fee';
            tempIntLine.netQuantity = 0.0;

            includedItem.addAll(prodCodeNameMap.get(associatedProdId).CPQ_IncludedFeatures__c == null ? new List<String>() : prodCodeNameMap.get(associatedProdId).CPQ_IncludedFeatures__c.split(';'));
        
            for(SBQQ__QuoteLine__c optionQL : integrationLines){
                //aggregate the line price
                tempNetprice += netTotalCalculator(optionQL);
                tempLines.putAll(createIntegrationSubline(associatedProdId, mapQlinesByProdCode.remove(optionQL.SBQQ__ProductCode__c))); 
                //get if the sub product has any included feature
                List<String> included = prodCodeNameMap.containsKey(optionQL.SBQQ__ProductCode__c) ? prodCodeNameMap.get(optionQL.SBQQ__ProductCode__c).CPQ_IncludedFeatures__c == null ? new List<String>() : prodCodeNameMap.get(optionQL.SBQQ__ProductCode__c).CPQ_IncludedFeatures__c.split(';') : new List<String>() ;
                includedItem.addAll(included);

            }
            //add all the sub modules included
            includedItem.addAll(tempLines.keySet());

            tempIntLine.oneTimeFee = tempNetPrice;
            tempIntLine.prodDesc = prodCodeNameMap.get(associatedProdId).Name + ' - ' + String.join(new List<String>(includedItem) ,', ') + ' Modules';
            tempBundleLines.add(tempIntLine);
            tempBundleLines.addAll(tempLines.values());

        }

        /*The products which are not bundled and grouped based on the associated product Id of the option
        */
        for(String associatedProdId: mapQlinesByProdCode.keySet()){

            Decimal tempNetprice = 0.0;
            List<SBQQ__QuoteLine__c> integrationOptions =  mapQlinesByProdCode.get(associatedProdId);
            for(SBQQ__QuoteLine__c optionQL : integrationOptions){
                tempNetprice += netTotalCalculator(optionQL);
            }

            QuoteLineWrapper tempIntLine = new QuoteLineWrapper(null);
            tempIntLine.oneTimeFee = tempNetprice;
            tempIntLine.billingFrequency = 'one time'; //TODO: Need to update here
            tempIntLine.prodMrktCode = associatedProdId;
            tempIntLine.productCode = prodCodeNameMap.get(associatedProdId).Name;  
            tempIntLine.name = 'one time';
            tempIntLine.isMain = true;
            tempIntLine.prodDesc = prodCodeNameMap.get(associatedProdId).Description;
            tempIntLine.usage = true;
            
            returnList.add(tempIntLine);

        }

        if(tempBundleLines.size() > 0){
            returnList.addAll(tempBundleLines);
        }
        
        return returnList;
    }
   
    private Map<String, QuoteLineWrapper> createIntegrationSubline(String associatedProductCode, List<SBQQ__QuoteLine__c> subQuoteLines){
        
        map<String, QuoteLineWrapper> returnList = new map< String, QuoteLineWrapper>();
        if(subQuoteLines == null){
            return returnList;
        }

        for(SBQQ__QuoteLine__c item: subQuoteLines){
            
            //TODO: Check if this logic can be improved. the way to set the product name for included and other type of helper optional SKUs (e.g Quantity Based commit)
            String productName = item.SBQQ__ProductName__c.contains('Included') ? item.SBQQ__RequiredBy__r.SBQQ__ProductName__c : this.prodCodeNameMap.get(item.CPQ_Associated_Product_Id__c).Name;
            if(productName == null || productName == '' || returnList.containsKey(productName)){
                continue;
            }
            QuoteLineWrapper tempIntLine = new QuoteLineWrapper(item.Id);
            tempIntLine.name = String.isNotBlank(item.CPQ_PAC_Line_Item_Id__c) ? item.CPQ_PAC_Line_Item_Id__c : item.CPQ_Charge_Type__c;
            tempIntLine.prodMrktCode = item.CPQ_Associated_Product_Id__c;
            //TODO: Check if this logic can be improved. the way to set the product name for included and other type of helper optional SKUs (e.g Quantity Based commit)
            tempIntLine.productCode = productName; 
            tempIntLine.isMain = associatedProductCode == item.CPQ_Associated_Product_Id__c ? false : true;
            tempIntLine.usage = true;
            tempIntLine.netPrice = netPriceCalculator(item);
            tempIntLine.rateSuffix = item.CPQ_Charge_Type__c.contains('Included') ? 'Included' : '';
            tempIntLine.quantity = String.valueOf(item.SBQQ__Quantity__c.format())+' '+ item.CPQ_Measurement__c;
            tempIntLine.netQuantity = item.SBQQ__Quantity__c;
            tempIntLine.billingFrequency = BILL_FREQ.containsKey(item.CPQ_Billing_Frequency__c) ? BILL_FREQ.get(item.CPQ_Billing_Frequency__c) : item.CPQ_Billing_Frequency__c ;
            returnList.put(productName, tempIntLine);
        }

        return returnList;
    }

}