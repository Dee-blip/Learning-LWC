/****************************************************************************
* Class name          :   SC_DD_DealDeskCont.cls
* Author              :   Vishnu Vardhan
* Created             :   01-November-2019
* Purpose             :   Controller for Deal Desk LWC Components
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* @getContractInfo    :   Returns List of ContractInfoWrapper ( ContractInfoWrapper groups Contracts under Service Product Name)
* @getGssProductDetails : fetch list of active GSS products, for Service Product and Produt Type picklists
* @getProductRules    :   get Package Component Customization info
* @getAccounts        :   Search Active Accounts - for account look up
* @getCustomerMrr     :   Get MRR Data
* @getConversionRates :   Get Currency Conversion Rates
* @getDeal            :   Get Deal - from PreDeal
* @saveDeal           :   Save Deal
* @saveOtherDeal      :   Save Other Deal

* -isDealDeskDown     :   If the Pre Deal Object is under processing, throw error message
* -canEvaluate        :   check if current user can evaluate deals for selected account
* -calcDealFromGRAZT  :   Calculate Deal fron GRAZT Data
* -calcDealFromPreDeal :   Calculate Deal fron Pre Deal Data
* -getEpsZone         :   get EPS ZONE - based on 25th and 50th percentile(median)
* -getEsrZone         :   Get ESR ZONE - based on local list esr, esr bucketing range vary for pnp and non-pnp prods
* -getDealZone     :   Get Deal Zone Based on EPS and ESR Zone
*****************************************************************************
* Util Methods
* - get25PercentileCurrentMargin : Get 25th percentile current margin
* - getListMedian                : Get Median value for a list of decimal numbers
* - getMedianCurrentMargin       : Get Median Current Margin 
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
April 6, 2020    Vishnu Vardhan   ESESP-3415      Fixes LWC error when controller return null value
April 6, 2020    Vishnu Vardhan   ESESP-3422      Exclude zero revenue data from EPS calculation
April 22, 2020   Vishnu Vardhan   ESESP-3377      Show message when requested is below min
April 22, 2020   Vishnu Vardhan   ESESP-3479      Deal Desk Access to Product Managers
May 11, 2020     Vishnu Vardhan   ESESP-3578      Updated Computed ESR logic(Advanced Product), as it depends on Pricing Object
June 18, 2020    Vishnu Vardhan   ESESP-3579      "Other" Deals feature
Oct 26, 2020     Vishnu Vardhan   ESESP-4288      Updated Computed ESR logic(Advanced Product)
Oct 27, 2020     Vamsee S         ESESP-4279      Updated Computed ESR logic(Premium 3.0 Product)
Dec 20, 2020     Vishnu Vardhan   ESESP-4301      Refactored Portfolio (SOA, RRS, MSS) 2.0
Jan 22, 2021     Vishnu Vardhan   ESESP-4694      new products - Protect & Perform 1.1 
March 12, 2020   Vishnu Vardhan   ESESP-4937      GRAZT changes
*****************************************************************************/

public without sharing class SC_DD_DealDeskCont{
    static final String PCK_PROJ_MAN = 'Project Management';
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * Config              :   Wrapper Class to hold package component customization info
    ****************************************************************************/
    public class Config {
        @AuraEnabled
        public Id sfid;
        @AuraEnabled
        public Id product;
        @AuraEnabled
        public String configName;
        @AuraEnabled
        public String configLabel;
        @AuraEnabled
        public String customFormula;
        @AuraEnabled
        public Decimal defaultCustValue;
        @AuraEnabled
        public Decimal requested;
        @AuraEnabled
        public Integer sequence;
        @AuraEnabled
        public Decimal standard;
        @AuraEnabled
        public Decimal min;
        @AuraEnabled
        public String minError;
        @AuraEnabled
        public Decimal max;
        @AuraEnabled
        public String maxError;
        @AuraEnabled
        public Boolean allowBelowMin;
        @AuraEnabled
        public Boolean allowAboveMax;
    }
    // ESESP-3578      Updated Computed ESR logic(Advanced Product), as it can depend on Pricing Object
    // For complex Computed ESR Logic, implement below interface and mention the class name in "Computed_ESR_Override_Class__c" field of GSS Servicie Product
    // For Simple logic (Math), just update "Computed_ESR_Formula__c" field of GSS Product 
    public interface Intf_EsrOverride {
        Decimal getComputedEsrLocal(SC_DD_Deal__c deal);
    }

    // Computed ESR logic for Advanced Product
    public class AdvancedProductEsr implements Intf_EsrOverride {
        final String PCK_PROJ_MAN = 'Project Management';
        final String PCK_ADDL_PROJ_MANAG_HOURS = 'Additional Project Management (Hrs/quarter)';
        public Decimal getComputedEsrLocal(SC_DD_Deal__c deal) {
            
            Map<String,Config> packageCompInfo = (Map<String,Config>)JSON.deserializeStrict(deal.Package_Comp_Info__c, Map<String,Config>.class);
            Decimal projManagementCompUnits = packageCompInfo.get(PCK_PROJ_MAN).requested;
            Decimal projManagementUnitPrice = 0;
            Decimal addlProjManagementHoursPerQuarter = packageCompInfo.get(PCK_ADDL_PROJ_MANAG_HOURS).requested;

            // If Project Components are entered, fetch Project Component Unit Price
            if(projManagementCompUnits > 0) {
                //April 2022     Manasa     ESESP-6655 --- added the additional filter GSS product in query
                List<SC_DD_Product_Pricing__c> prodPricing = [select List_ESR_Local_Currency__c, Local_List_Price__c, Currency__c from SC_DD_Product_Pricing__c 
                                                                where recordType.name = 'Component' and Package_Component__r.name = :PCK_PROJ_MAN and Currency__c = :deal.Local_Currency__c and GSS_Product__c = :deal.GSS_Product__c];
                if(prodPricing.size() == 0) {
                    throw new AuraHandledException( 'Project Management Component is not available for selected currency');
                }
                projManagementUnitPrice = prodPricing[0].Local_List_Price__c;
            } else if(addlProjManagementHoursPerQuarter >  0) {
                //Oct 26, 2020     Vishnu Vardhan   ESESP-4288
                throw new AuraHandledException( 'Include Project Management Fee in Requested Price for deal evaluation purposes. It will however need to be listed separately on the Order Form as it has it\'s own fee line (add-on)');
            }

            // Computed ESR
            return (deal.Requested_Price__c - ( projManagementCompUnits *  projManagementUnitPrice * 0.8) - (addlProjManagementHoursPerQuarter * 100 * 0.8)) * 0.7 / deal.Requested_Hours__c;
        }
    }
    
    // Computed ESR logic for Premium 3.0 Product : ESESP-4279  
    public class PremiumThreeProductEsr implements Intf_EsrOverride {
        final String PCK_PRO_CONFIG = 'Proactive Monitored Configs';
        final String PCK_SUPP_ADVO = 'Support Advocacy (Hrs/quarter)';
        final String PCK_PS_HOURS = 'PS Hours (Hrs/quarter)';
        final String PCK_TAS = 'TAS (Hrs/quarter)';
        final String PCK_TBA = 'Technical Business Assessment';
        final String PCK_MONTHLY_HOURS = 'Computed Total Package Hours/Month';
 
        public Decimal getComputedEsrLocal(SC_DD_Deal__c deal) {
           
            Map<String,Config> packageCompInfo = (Map<String,Config>)JSON.deserializeStrict(deal.Package_Comp_Info__c, Map<String,Config>.class);
          
            Decimal requestedProactiveConfigs = packageCompInfo.get(PCK_PRO_CONFIG).requested;
            Decimal requestedMonthlyHours = packageCompInfo.get(PCK_SUPP_ADVO).requested / 3 + packageCompInfo.get(PCK_PS_HOURS).requested / 3 +
                                            packageCompInfo.get(PCK_TAS).requested * 1.17 / 3 + packageCompInfo.get(PCK_TBA).requested *2.5;
 
            // Computed ESR
            return (deal.Requested_Price__c - ((requestedProactiveConfigs - 20) * 400 )) * 0.8 / requestedMonthlyHours;
        }
    }
    
    // Computed ESR logic for MSS 2.0 Product : ESESP-4279  
    public class MSSTwoProductEsr implements Intf_EsrOverride {
        //  
        final String PCK_POLICIES = 'Managed Policies (Monthly)';
        final String PCK_ENDPOINTS = 'Managed Endpoints (Monthly)';
        final String PCK_PIM = 'Managed PI Configurations (Monthly)';
        final String PCK_MONTHLY_HOURS = 'Computed Total Package Hours/Month';
 
        public Decimal getComputedEsrLocal(SC_DD_Deal__c deal) {
           
            Map<String,Config> packageCompInfo = (Map<String,Config>)JSON.deserializeStrict(deal.Package_Comp_Info__c, Map<String,Config>.class);
            Decimal managedComps = packageCompInfo.get(PCK_POLICIES).requested + packageCompInfo.get(PCK_ENDPOINTS).requested + packageCompInfo.get(PCK_PIM).requested;
            System.debug('managedComps ' + managedComps);
            if(managedComps == 0) {
                throw new AuraHandledException( 'Atleast one of "Endpoint" or "PIM Configuration" or "Policies" should exist');
            }
                        
            // Computed ESR
            return (deal.Requested_Price__c/ deal.Requested_Hours__c);
        }
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * ContractInfoWrapper :   Contract Info Wrapper - for displaying Contract Data in "Contract Info" modal
    ****************************************************************************/
    public class ContractInfoWrapper{
        @AuraEnabled
        public String serviceProduct;
        @AuraEnabled 
        public integer rowspan{ get { return contractInfoList.size();}}
        @AuraEnabled
        public List<Merge_Contract_Detail__c> contractInfoList = new List<Merge_Contract_Detail__c>();
        
        public ContractInfoWrapper(String serviceProd){
            this.serviceProduct = serviceProd;
        }
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getContractInfo    :   Returns List of ContractInfoWrapper ( ContractInfoWrapper groups Contracts under Service Product Name)
    * where used          : c-dd-evaluation-form lwc component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static list<ContractInfoWrapper> getContractInfo(String accountId){

        // Merge_Contract_Detail__c Will have only marketing Product Id, so building map of Marketing Product => Service Product
        // Map: Marketing Product Name --> Service Product Name
        //   1. get 'Contract' mappings from SC_DD_Mapping__c
        //   2. build Map: Marketing Product Name --> Service Product Name 
        map<string,string> contractMapping = new map<string,string>();
        
        for(SC_DD_Mapping__c eachMapping : [SELECT Product__r.Name, Parent_GSS_Product__r.Name
                                            FROM SC_DD_Mapping__c Where 
                                            Recordtype.name = 'Contract' AND End_of_Life__c = false AND Product__c != null AND Parent_GSS_Product__c != null ])
        {
            contractMapping.put(eachMapping.Product__r.Name, eachMapping.Parent_GSS_Product__r.Name);
        }
        
        // Map: Service Product Name --> Contract Info (wrapper)
        //   1. get Contract Info of all Marketing Products from Merge_Contract_Detail__c
        //   2. Get Service Product Name for each Contract - using Contract's Marketing Product Id
        //   3. If Service Product Not found, group it under "Others"
        Map<String, ContractInfoWrapper> contractInfoWrapperMap = new Map<String, ContractInfoWrapper>();
        
        for(Merge_Contract_Detail__c eachContractDetail : [select id,Product_Id__c, Effective_Start_Date__c, Effective_end_Date__c, Unit_of_Measure__c, 
                                                           Units_Low__c, Units_High__c, Billing_Duration__c, Product__c, Original_Contract_Id__r.Name from Merge_Contract_Detail__c
                                                           where Original_Contract_Id__r.Account_Name__r.akam_account_id__c= :accountId and Record_Type__c = 'Committed' and Effective_End_Date__c > :System.today()])
        {
            // Get Service Product Name to which this contract belongs, if not found group it under "Others" 
            String prodName = contractMapping.get(eachContractDetail.Product_Id__c);
            if(String.isBlank(prodName)) {
                prodName = 'Others';
            }
            if(!contractInfoWrapperMap.containsKey(prodName)) {
                contractInfoWrapperMap.put(prodName, new SC_DD_DealDeskCont.ContractInfoWrapper(prodName));
            }
            contractInfoWrapperMap.get(prodName).contractInfoList.add(eachContractDetail);
        }
        // returning Grouped Contract Info List
        return contractInfoWrapperMap.values();
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getGssProductDetails : fetch list of active GSS products, for Service Product and Produt Type picklists
    * where used          :  c-dd-evaluation-form lwc component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<SC_DD_GSSServiceProduct__c> getGssProductDetails() {
        isDealDeskDown();
        return [select id, Name, Product_Type__c, LOE_API_Call_Required__c, Computed_ESR_Formula__c, Product_Combination__c, List_Price_Multiplicand__c 
                from SC_DD_GSSServiceProduct__c
                where Is_Service_Support_Product__c = true and Is_Active__c = true order by Name];
        
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getProductRules    :   get Package Component Customization info
    * where used          :   c-dd-package-customization lwc component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Map<String, Config> getProductRules(String prod, String prodType, String currentValuesStr) {
        
        
        Map<String, Config> prodConfigs = new Map<String, Config>();
        Map<String, Config> currentValues;

        if(String.isNotBlank(currentValuesStr)) {
            currentValues = (Map<String, Config>)JSON.deserialize(currentValuesStr,  Map<String, Config>.class);
        } 

        for(SC_DD_Package_Components__c cf: [select id, Name, Component_Label__c, Package_Hours_Formula__c, Sequence__c, GSS_Product__c, Max__c, Min__c, Standard__c FROM SC_DD_Package_Components__c 
                                             where GSS_Product__r.Name = :prod and GSS_Product__r.Product_Type__c = :prodType]) 
        {
            Config prodConfig = new Config();
            prodConfig.sfid = cf.Id;
            prodConfig.product = cf.GSS_Product__c;
            prodConfig.configName = cf.Name;
            prodConfig.configLabel = String.isNotBlank(cf.Component_Label__c)? cf.Component_Label__c: cf.Name;
            prodConfig.customFormula = cf.Package_Hours_Formula__c;
            prodConfig.defaultCustValue = cf.Standard__c;
            // if current values exist requested value will be current value, if not use Standard value
            prodConfig.requested = currentValues!= null ? currentValues.get(cf.Name).requested: cf.Standard__c;
            prodConfig.standard = cf.Standard__c ;
            prodConfig.sequence = Integer.valueOf(cf.Sequence__c);
            prodConfig.min = cf.Min__c ;
            prodConfig.max = cf.Max__c ;
            prodConfig.minError = 'Negative values not allowed';//'minimum value is ' + cf.Min__c ;
            prodConfig.maxError = 'maximum value is ' + cf.Max__c ;
            prodConfig.allowBelowMin = false;
            prodConfig.allowAboveMax = false;
            prodConfigs.put(cf.Name, prodConfig);
        }

        return prodConfigs;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getAccounts        :   Search Active Accounts - for account look up
    * where used          :   c-dd-evaluation-form lwc component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String searchStr){
        if(String.isBlank(searchStr)) {
            // ESESP-3415 - return empty list instead of null value
            return new List<Account>();
        }
        searchStr = '%' + searchStr + '%';

        return [select Id, Name, AKAM_Account_ID__c from Account 
                            where (Name like :searchStr OR AKAM_Account_ID__C like :searchStr) and ( Type like '%Active%' OR Type = 'Lead')
                            and (not account_Status__c like '%Inactive') and (not name like '%Akamai%') limit 10];
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getCustomerMrr     :   Get MRR Data
    * where used          :   c-dd-customer-mrr component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<SC_DD_Customer_MRR__c> getCustomerMrr(String akamAccId){

        return [SELECT Id, Local_Currency__c, Local_Revenue__c, Product__c, USD_Revenue__c 
                FROM SC_DD_Customer_MRR__c WHERE Akam_Account_ID__c =:akamAccId and Status__c = 'Active'];
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getConversionRates :   Get Currency Conversion Rates
    * where used          :   c-dd-evaluation-form lwc component
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<CurrencyType> getConversionRates(){
        return [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive = true];
    }

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -isDealDeskDown     :   If the Pre Deal Object is under processing, throw error message
    ****************************************************************************/
    public static Boolean isDealDeskDown() {
        SC_DD_Utility__c ddSetting = SC_DD_Utility__c.getInstance('DD Setting');
        if(ddSetting != null && ddSetting.UI_Status__c == 'Processing') {
            // Deal Desk Down for routine maintenence.
            throw new AuraHandledException('ERR_APP_DOWN');  
        }
        
        return true;
    }
    // ESESP-3479      Deal Desk Access to Product Managers
    static Set<String> graztSkipPerms = new Set<String> {'SC_DD_Product_Managers'};

    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -canEvaluate        :   check if current user can evaluate deals for selected account
    ****************************************************************************/
    static Boolean canEvaluate(String akamAccId) {
        // ESESP-3479  - Added PermissionAssignments sub query to user query, and check if user has graztSkipPermissions
        User currUser = [select id, Profile.Name, (select id, permissionset.name from permissionSetAssignments where permissionset.name in:graztSkipPerms limit 1) from User where Id = :UserInfo.getUserId()];
        // SPO and DDA Users can evaluate Deals for all Accounts
        if(FeatureManagement.checkPermission('DD_SPO') || currUser.Profile.Name  == SC_DD_ApprovalCompCont.DDA_PROFILE || currUser.permissionSetAssignments.size() > 0) {
            return true;
        }

        // Other users can evaluate Deals only for accounts with in their GRAZT
        Account acc = [select TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c from Account where Akam_Account_Id__c = :akamAccId];
        
        return [select Id from  Inv_WorkBox_Region_Mapping__c where RecordType.Name = 'DealDesk' 
                            AND Is_Old__c = false
                            AND (User__c = :currUser.Id OR User__r.ManagerId = :currUser.Id OR User__r.Manager.ManagerId = :currUser.Id)
                            AND TERR_HIER_1_F__c = :acc.TERR_HIER_1__c AND TERR_HIER_2_F__c in (:acc.TERR_HIER_2__c, '*') AND TERR_HIER_3_F__c in (:acc.TERR_HIER_3__c, '*') 
                            AND TERR_HIER_4_F__c in (:acc.TERR_HIER_4__c, '*') AND  TERR_HIER_5_F__c in (:acc.TERR_HIER_5__c, '*')
                            limit 1 ].size() > 0;
            
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @getDeal            :   Get Deal - from PreDeal
    * where used         :   c-deal-desk lwc component
    ****************************************************************************/
    // ESESP-3377 - Added extra input param - isBelowMinPackageComp
    @AuraEnabled(cacheable=true)
    public static String getDeal(String akamAccountId, String prodFullName, String packComp, Decimal requestedHours, 
                                    Decimal requestedPriceLocal, Decimal computedEsrLocal, String localCurrency,
                                    String loeId, Boolean isNapCustomer, Boolean isBelowMinPackageComp )
    {
        // Access Check - Checks for DDA Profile, SPO Permission, GRAZT config
        if(canEvaluate(akamAccountId) == false) {
            throw new AuraHandledException('NO_ACC_ACCESS');
        }

        String currencyCode = localCurrency.substringBetween('(', ')');       
        Decimal conversionRate = [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE ISOCode = :currencyCode and IsActive=TRUE].ConversionRate;
        Decimal requestedPriceUsd = requestedPriceLocal / conversionRate;
        
        
        Account acc = [select id, SC_DD_DGRAT__c from Account where Akam_Account_ID__c = :akamAccountId];
        
        SC_DD_GSSServiceProduct__c servProd = [select id, Name, Full_Name__c, List_Price_Multiplicand__c, Computed_ESR_Override_Class__c, ESR_Green_Threshold__c, ESR_Yellow_Threshold__c,
                                               (select List_ESR_Local_Currency__c, Local_List_Price__c, Currency__c from Product_Pricing__r where (Currency__c = :localCurrency OR Currency__c = 'US (USD)') and RecordType.Name = 'Product' ) 
                                                from SC_DD_GSSServiceProduct__c where Product_Combination__c = :prodFullName and Is_Service_Support_Product__c = true and Is_Active__c = true];

        // Get Pre Deals for Account and Product Combination
        List<SC_DD_Customer_PreDeal_Data__c> currAccProdPredeals = [select Akam_Account_ID__c, Account_DGRAT__c, Current_Customer_Role_MRR__c,
                                                                    PS_Hours__c, PS_Delivery_Cost__c, PS_Budget_Hour__c, PS_No_Of_Months__c,
                                                                    PS_Non_Billable_Hours__c, SOCC_LOE_Hours__c, SOCC_LOE_Delivery_Cost__c, 
                                                                    AkaTec_LOE_Hours__c, Akatec_LOE_Delivery_Cost__c, PS_PerHour_Cost__c,
                                                                    Revenue_Months__c, Total_Revenue_All_Months__c, Total_Revenue_Filtered_Months__c
                                                                    from SC_DD_Customer_PreDeal_Data__c 
                                                                    where  Akam_Account_ID__c = :akamAccountId and Product_name__c = :servProd.Name
                                                                    and Status__c = 'Active'];
        
        SC_DD_Deal__c deal;
        // If Pre Processed/ Pre Calculated deal exist for selected account and product combination, use it
        // Case1: Calculation_Type__c = 'ACCOUNT';
        if(currAccProdPredeals.size() > 0 && currAccProdPredeals[0].PS_Delivery_Cost__c > 0) { 
            deal = calcDealFromPreDeal(currAccProdPredeals[0], requestedPriceUsd, requestedHours);
        }
        else{
            // If Pre Calculated Deal doesn't exist for selected Account & Product
            // Fetch Pre Calculated Deals of Other Accounts with in Same GRAZT
            List<SC_DD_Customer_PreDeal_Data__c> graztDeals = [select Akam_Account_ID__c, PS_Hours__c, PS_Delivery_Cost__c, PS_Budget_Hour__c, PS_No_Of_Months__c,
                                                               PS_Non_Billable_Hours__c, SOCC_LOE_Hours__c, SOCC_LOE_Delivery_Cost__c,  AkaTec_LOE_Hours__c, Akatec_LOE_Delivery_Cost__c,
                                                               Revenue_Months__c, Total_Revenue_All_Months__c, Total_Revenue_Filtered_Months__c
                                                               from SC_DD_Customer_PreDeal_Data__c 
                                                               where  Account_DGRAT__c = :acc.SC_DD_DGRAT__c and Product_name__c = :servProd.Name and PS_No_Of_Months__c > 0
                                                               and Status__c = 'Active'];
            // Case2: Calculation Type = 'GRAZT';
            if(graztDeals.size() > 0) {
                deal = calcDealFromGRAZT(graztDeals, requestedPriceUsd, requestedHours);
            } 
            // Case3: Calculation Type = 'ESR';
            else {
                deal = new SC_DD_Deal__c();
                deal.Expected_Profitability_Score__c = 0;
                deal.Calculation_Type__c = 'ESR';
            }
            
            // If Deal has no PS Data, but has Total Revenue/ Customer MRR
            if(currAccProdPredeals.size() > 0) {
                deal.Total_Revenue_Unfiltered__c = currAccProdPredeals[0].Total_Revenue_All_Months__c;
                deal.Revenue_Months__c = currAccProdPredeals[0].Revenue_Months__c;
                deal.Current_Customer_Role_MRR__c = currAccProdPredeals[0].Current_Customer_Role_MRR__c;
            }
            
        }
        // Populate List Price, List Price Local, List ESR, List ESR Local of the Product - from Pricing table
        for(SC_DD_Product_Pricing__c pricing: servProd.Product_Pricing__r) {
            if(pricing.Currency__c == localCurrency) {
                deal.List_ESR_Local__c = pricing.List_ESR_Local_Currency__c;
                deal.List_Price_Local__c = pricing.Local_List_Price__c; 
            }
            if(pricing.Currency__c == 'US (USD)') {
                deal.List_ESR__c = pricing.List_ESR_Local_Currency__c;
                deal.List_Price__c = pricing.Local_List_Price__c; 
            }
        }
        
        deal.recalculateFormulas();
        
        // User Input Data
        deal.Account__c = acc.Id;
        deal.GSS_Product__c = servProd.Id;
        deal.Local_Currency__c = localCurrency;
        deal.Requested_Hours__c = requestedHours;
        deal.Requested_Price__c = requestedPriceLocal;
        deal.LOE_Id__c = loeId;
        deal.is_NAP_Customer__c  = isNapCustomer;
        deal.Package_Comp_Info__c = packComp;
        // ESESP-3578 
        // If "Computed_ESR_Override_Class__c" class exist, dynamically instantiate the Class and call it's method to calculate computedEsr
        // If not, just use the computed esr sent by LWC component (Calculated based on "Computed_ESR_Formula__c" )

        if(String.isNotBlank(servProd.Computed_ESR_Override_Class__c)) {
            Intf_EsrOverride esrOverride = (Intf_EsrOverride)Type.forName(servProd.Computed_ESR_Override_Class__c).newInstance();
            deal.Computed_ESR_Local__c = esrOverride.getComputedEsrLocal(deal);
        } else {
            deal.Computed_ESR_Local__c = computedEsrLocal;
        }
        deal.Computed_ESR__c =  (deal.Computed_ESR_Local__c / conversionRate).setScale(2);
        
        // EPS Calculation - Only Deals with Caluclation Type 'ACCOUNT' & 'GRAZT' will have EPS
        if(deal.Calculation_Type__c == 'ACCOUNT' || deal.Calculation_Type__c == 'GRAZT') {
            // ESESP-3422 - added extra filter to SOQL - Total Revenue (Filtered Months) > 0
            List<SC_DD_Customer_PreDeal_Data__c> allPreDealsOfProduct = [ select Current_Margin__c from SC_DD_Customer_PreDeal_Data__c 
                                                                         where status__c = 'Active' and Product_name__c = :servProd.Name and Total_Revenue_Filtered_Months__c > 0 and PS_No_Of_Months__c > 0 order by Current_Margin__c ASC];
            if(allPreDealsOfProduct.isEmpty()) {
                deal.Calculation_Type__c = 'ESR';
                deal.Expected_Profitability_Score__c = 0;
            } else {
                Decimal currMarginMedian = getMedianCurrentMargin(allPreDealsOfProduct);
                Decimal currMargin25Percentile = get25PercentileCurrentMargin(allPreDealsOfProduct);
                
                deal.Median_Profitability_Score__c = currMarginMedian;
                deal.EPS_Zone__c = getEpsZone(deal.Expected_Profitability_Score__c, currMarginMedian, currMargin25Percentile);
            }
        }
        // ESR Calculation
        deal.ESR_Zone__c = getEsrZone(deal, servProd);
        // Derrive Deal Zone from EPS and ESR Zones
        deal.Deal_Zone__c = getDealZone(deal);
        deal.Approval_Stage__c = 'DDA';
        //ESESP-3377 - if requested is below min, update Below_Min_Package_Comp__c
        deal.Below_Min_Package_Comp__c = isBelowMinPackageComp;
        
        return JSON.serialize(deal) ;
        
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * @saveDeal           :   Save Deal
    * where used          :   c-deal-desk lwc component
    ****************************************************************************/
    @AuraEnabled
    public static Id saveDeal(SC_DD_Deal__c deal){
        if(deal.Evaluation_Action__c == 'Escalated') {
            deal.Approval_Time_Limit__c = System.now().addHours(72);
        }
        deal.requestor__c = System.UserInfo.getUserId();
        deal.recordtypeId = Schema.SObjectType.SC_DD_Deal__c.getRecordTypeInfosByName().get('Deals').getRecordTypeId();

        deal.month__c =  System.now().format('MMMM');
        upsert deal;
        return deal.Id;
    }

    //ESESP-3579  "Other" Deals feature
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   09-June-2020
    * @saveDeal           :   Save Other Deal
    * where used          :   c-deal-desk lwc component
    ****************************************************************************/
    @AuraEnabled
    public static Id saveOtherDeal(String akamAccId,
                                    String prodSelected,
                                    String productName,
                                    String productDescription,
                                    String approvalType,
                                    String localCurrency,
                                    Decimal requestedPrice,
                                    Decimal priceListPrice,
                                    String explanationAndJustification,
                                    Boolean isNapCustomer
    ){
        User currUser = [select id, profile.name from user where id = :UserInfo.getUserId()];
        Decimal discount = priceListPrice > 0 ? (priceListPrice - requestedPrice) * 100 / priceListPrice: 0;
        SC_DD_Deal__c otherDeal = new SC_DD_Deal__c();
        SC_DD_GSSServiceProduct__c servProd = [select Id from SC_DD_GSSServiceProduct__c where name = :prodSelected and Is_Service_Support_Product__c = true and Is_Active__c = true limit 1];
        otherDeal.Account__r = new Account(AKAM_Account_Id__c = akamAccId);
        otherDeal.GSS_Product__c = servProd.Id;
        otherDeal.Other_Product_Name__c = productName;
        otherDeal.Other_Product_Description__c = productDescription;
        otherDeal.Approval_Type__c = approvalType;
        otherDeal.Amount_of_Discount__c = discount!= null && approvalType == 'Discount' ? discount.setScale(1, System.RoundingMode.DOWN): null;
        otherDeal.is_NAP_Customer__c = isNapCustomer;
        otherDeal.local_currency__c = localCurrency;
        otherDeal.Requested_Price__c = requestedPrice;
        otherDeal.Price_in_pricelist__c = priceListPrice;
        otherDeal.Explanation_Justification__c = explanationAndJustification;
        otherDeal.Comments__c = explanationAndJustification;
        otherDeal.Deal_Zone__c = 'Red';

        if(FeatureManagement.checkPermission('DD_SPO')) {
            otherDeal.Evaluation_Action__c = 'Approved';
            otherDeal.Approval_Stage__c = 'Closed';
            otherDeal.Commented_By__c = 'SPO';
        } else if(currUser.Profile.Name  == SC_DD_ApprovalCompCont.DDA_PROFILE) {
            otherDeal.Evaluation_Action__c = 'Escalated ';
            otherDeal.Approval_Stage__c = 'SLM/SLD';
            otherDeal.Commented_By__c = 'DDA';
        } else {
            throw new AuraHandledException('Don\'t have permissions to submit "Other" Product Deals');
        }

        otherDeal.requestor__c = System.UserInfo.getUserId();
        otherDeal.month__c =  System.now().format('MMMM');

        otherDeal.recordtypeId = Schema.SObjectType.SC_DD_Deal__c.getRecordTypeInfosByName().get('Other Deals').getRecordTypeId();
        
        insert otherDeal;
        return otherDeal.Id;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -calcDealFromGRAZT  :   Calculate Deal fron GRAZT Data
    ****************************************************************************/
    static SC_DD_Deal__c calcDealFromGRAZT(List<SC_DD_Customer_PreDeal_Data__c> graztDeals, Decimal requestedPriceUsd, Decimal requestedHours) {
        
        SC_DD_Deal__c deal = new SC_DD_Deal__c();
        List<Decimal> psFactors = new List<Decimal>();
        List<Decimal> akatecFactors = new List<Decimal>(); 
        List<Decimal> soccFactors = new List<Decimal>();
        
        for(SC_DD_Customer_PreDeal_Data__c pd: graztDeals) {
            psFactors.add(pd.PS_Delivery_Cost__c / pd.PS_Hours__c);
            akatecFactors.add(pd.Akatec_LOE_Delivery_Cost__c / pd.PS_No_Of_Months__c);
            soccFactors.add(pd.SOCC_LOE_Delivery_Cost__c / pd.PS_No_Of_Months__c);
        }
        psFactors.sort();
        akatecFactors.sort();
        soccFactors.sort();
        Decimal medianPsFactor = getListMedian(psFactors);
        Decimal medianAkatecFactor = getListMedian(akatecFactors);
        Decimal medianSoccFactor = getListMedian(soccFactors);
        
        deal.Expected_Profitability_Score__c = (requestedPriceUsd - ( requestedHours * medianPsFactor + medianAkatecFactor + medianSoccFactor)) * 100 / requestedPriceUsd;
        deal.Expected_Profitability_Score__c =  deal.Expected_Profitability_Score__c.setScale(4);
        
        deal.Calculation_Type__c = 'GRAZT';
        
        return deal;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -calcDealFromPreDeal :   Calculate Deal fron Pre Deal Data
    ****************************************************************************/
    static SC_DD_Deal__c calcDealFromPreDeal(SC_DD_Customer_PreDeal_Data__c predeal, Decimal requestedPriceUsd, Decimal requestedHours) {
        
        SC_DD_Deal__c deal = new SC_DD_Deal__c();
        deal.Calculation_Type__c = 'ACCOUNT';
        deal.PS_Hours__c = predeal.PS_Hours__c;
        deal.PS_Delivery_Cost__c = predeal.PS_Delivery_Cost__c;
        deal.PS_Non_Billable_Hours__c = predeal.PS_Non_Billable_Hours__c;
        deal.PS_Project_Budget_Hours__c = predeal.PS_Budget_Hour__c; // check logic
        deal.Filtered_Revenue_Months__c = predeal.PS_No_Of_Months__c;
        
        deal.SOC_Hours__c = predeal.SOCC_LOE_Hours__c;
        deal.SOCC_Delivery_Cost__c = predeal.SOCC_LOE_Delivery_Cost__c;
        
        deal.Revenue_Months__c = predeal.Revenue_Months__c;
        deal.Total_Revenue_Unfiltered__c = predeal.Total_Revenue_All_Months__c;
        deal.Total_Revenue_Filtered__c = predeal.Total_Revenue_Filtered_Months__c;
        
        
        //deal.PS_Avg_non_billable_hours__c = ;
        deal.AkaTec_Hours__c = predeal.AkaTec_LOE_Hours__c;
        deal.AkaTec_Delivery_Cost__c = predeal.Akatec_LOE_Delivery_Cost__c;
        deal.Current_Customer_Role_MRR__c = predeal.Current_Customer_Role_MRR__c;
        
        deal.Expected_Profitability_Score__c = ( requestedPriceUsd - requestedHours * predeal.PS_PerHour_Cost__c - 
                                                 ((deal.AkaTec_Delivery_Cost__c + deal.SOCC_Delivery_Cost__c)/ deal.Filtered_Revenue_Months__c)
                                                ) * 100 / requestedPriceUsd;
        deal.Expected_Profitability_Score__c = deal.Expected_Profitability_Score__c.setScale(4);
        // } else {
        //     deal.Expected_Profitability_Score__c = 0;
        // }
        
        return deal;
        
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getEpsZone         :   get EPS ZONE - based on 25th and 50th percentile(median)
    ****************************************************************************/
    static String getEpsZone(Decimal eps, Decimal currMarginMedian, Decimal currMargin25Percentile ) {
        String epsZone; 
        
        if(eps > currMarginMedian ) {
            epsZone = 'Green';
        }
        else if(eps >= currMargin25Percentile && eps <= currMarginMedian) {
            epsZone = 'Yellow';
        }
        else if(eps < currMargin25Percentile) {
            epsZone = 'Red';
        }
        return epsZone;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getEsrZone         :   Get ESR ZONE - based on local list esr, esr bucketing range vary for pnp and non-pnp prods
    ****************************************************************************/
    static String getEsrZone(SC_DD_Deal__c deal, SC_DD_GSSServiceProduct__c servProd) {

        String esrZone;
        
        Decimal esr = deal.Computed_ESR_Local__c;
        Decimal localListEsr = deal.List_ESR_Local__c; 

        // threshholds
        Decimal greenThreshold = servProd.ESR_Green_Threshold__c;
        Decimal yellowThreshold = servProd.ESR_Yellow_Threshold__c;
        
        // ESR is calculated in LWC (Javascript)
        // Scaling down to offset Javascipt Accuracy Issues
        Decimal scaledDownEsr = esr.setScale(12);
        Decimal scaledDownLocalListEsr = localListEsr.setScale(12);

        if(scaledDownEsr >=  greenThreshold * scaledDownLocalListEsr) {
            esrZone = 'Green';
        } else if(scaledDownEsr >=  yellowThreshold * scaledDownLocalListEsr) {
            esrZone = 'Yellow';
        } else {
            esrZone = 'Red';
        }
        
        return esrZone;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getDealZone     :   Get Deal Zone Based on EPS and ESR Zone
    ****************************************************************************/
    static String getDealZone(SC_DD_Deal__c deal) {
        String dealZone;

        
        if(String.isBlank(deal.EPS_Zone__c)) {
            // For Calculation type = ESR, which meanes no account history, no grazt data
            // EPS will be blank, consider esr zone as deal zone
            dealZone = deal.ESR_Zone__c;
        }
        else if(deal.EPS_Zone__c == 'Red' || deal.ESR_Zone__c == 'Red') {
            dealZone = 'Red';
        }
        else if(deal.EPS_Zone__c == 'Yellow' || deal.ESR_Zone__c == 'Yellow') {
            dealZone = 'Yellow';
        }
        else if(deal.EPS_Zone__c == 'Green' && deal.ESR_Zone__c == 'Green'){
            dealZone = 'Green';
        }
        return dealZone;
    }
    
    
    /************************* Util Methods *************************/
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getListMedian      :   Get Median value for a list of decimal numbers
    ****************************************************************************/
    static Decimal getListMedian(List<Decimal> itemList) {
        
        itemList.sort();
        Integer itemsCount = itemList.size();
        
        Decimal percentile50 ;
        Integer percentile50Index;
        if(math.mod(itemsCount, 2) == 0) {
            percentile50Index = itemsCount / 2;
            percentile50 = (itemList[percentile50Index] + itemList[percentile50Index - 1]) / 2;
        } else{
            percentile50Index = Integer.valueOf(Math.floor(itemsCount / 2));
            percentile50 = itemList[percentile50Index];
        }
        return percentile50;
    }
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -getMedianCurrentMargin :   Get Median Current Margin 
    ****************************************************************************/
    static Decimal getMedianCurrentMargin(List<SC_DD_Customer_PreDeal_Data__c> preDealData) {
        Integer dealCount = preDealData.size();
        
        Decimal percentile50 ;
        Integer percentile50Index;
        if(math.mod(dealCount, 2) == 0) {
            percentile50Index = dealCount / 2;
            percentile50 = (preDealData[percentile50Index].Current_Margin__c + preDealData[percentile50Index - 1].Current_Margin__c) / 2;
        } else{
            percentile50Index = Integer.valueOf(Math.floor(dealCount / 2));
            percentile50 = preDealData[percentile50Index].Current_Margin__c;
        }
        return percentile50;
    }
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   25-February-2020
    * -get25PercentileCurrentMargin :   Get 25th percentile current margin
    ****************************************************************************/
    static Decimal get25PercentileCurrentMargin(List<SC_DD_Customer_PreDeal_Data__c> preDealData) {
        Integer dealCount = preDealData.size();
        Integer percentile25Index = Integer.valueOf(Math.floor(dealCount * .25));
        return preDealData[percentile25Index].Current_Margin__c;
    }
    
}