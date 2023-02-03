/**
|  HISTORY  |                                                                            

|  DATE             DEVELOPER       JIRA        DESCRIPTION                               

|  ===========      =========       =======     =========== 

|  10-Jul-2019      Sumanth       ESESP-2460    Support Class for SC_Autogen_Plus_Advanced_Batch
|  30-Aug-2019      Vikas         ESESP-2509    MSS 1.0 - Onboarding Case auto-generation
|  22-Oct-2019      Bhavesh       ESESP-2265    mPulse Service - Onboarding Case auto-generation
|  19-Jun-2020      Pinkesh       ESESP-3254    Customer Event Support - automated onboarding case generation

**/
public class SC_Autogen_PLUS_ADVANCED_Support
{
    // List to store all Cases to be Created
    public static List<Case> caseCreateList = new List<Case>();

    // List to store all Cases to be Created
    public static List<Case> caseCreateListTemp = new List<Case>();

    // Fetching Assignment Rule
    public AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];

    // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
    public Id setDetailRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();

    // Fetching Business Hour
    public BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Service Business Hours - 24x5']; 

    // Map to store Autogen Use Case - Complete Record(SC_AutogenJob__c)
    Map<string,SC_AutogenJob__c> autogenUseCase_FullRec = new Map<string,SC_AutogenJob__c>();

    //Map of Id,ACHD
    public static Map<Id,Autogen_Contract_Header_Detail__c> allContractLnsUpdateMap = new Map<Id,Autogen_Contract_Header_Detail__c>();

    /** 
        Variables for New Contract Process Change 
    **/

    // 0. Map to store ContractDetail ID - IS_COB_Created (For All)
    public static Map<Id,Autogen_Contract_Header_Detail__c> contractDetailId_COBCreatedMap_ACHD = new Map<Id,Autogen_Contract_Header_Detail__c>();

    // 1. Map to Store On Boarded CLI details for Plus - ESESP-2046 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIPlus = new Map<Id,boolean>();

    // 2. Map to Store On Boarded CLI details for Advanced - ESESP-2045 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIAdvanced = new Map<Id,boolean>();
    public static List<Case> advancedCaseCreateList = new List<Case>();
    Map<String,List<Case>> parentContractDetailCaseMap = new Map<String,List<Case>>();

    // 3. Map to Store On Boarded CLI details for PMO - ESESP-2045 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIPMO = new Map<Id,boolean>();

    // 4. Map to Store On Boarded CLI details for MSS BM - ESESP-2509- Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLI_MSS_BM = new Map<Id,boolean>();

    // 5. Map to Store On Boarded CLI details for MSS KD - ESESP-2509 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLI_MSS_KD = new Map<Id,boolean>();

    // 6. Map to Store On Boarded CLI details for MSS BM KD - ESESP-2509 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLI_MSS_BM_KD = new Map<Id,boolean>();

    // 7. Map to Store On Boarded CLI details for mPulse - ESESP-2265 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLImPulse = new Map<Id,boolean>();
    public static List<Case> mPulseCaseCreateList = new List<Case>();
    //Map<String,List<Case>> parentContractDetailCaseMap = new Map<String,List<Case>>();  

    // 8. Map to Store On Boarded CLI details for Plus - ESESP-3254 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIEventSupportEssentials = new Map<Id,boolean>();

    // 9. Map to Store On Boarded CLI details for Plus - ESESP-3254 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIEventSupportEnhanced = new Map<Id,boolean>();

    // 10. Map to Store On Boarded CLI details for Plus - ESESP-3254 - Stores CLI Id and corresponding value of IS_COB_CLI
    public static Map<Id,boolean> onboardedCLIEventSupportComprehensive = new Map<Id,boolean>();

    /** 
        End of Variables for New Contract Process Change 
    **/

    /**
        Constructor
    **/
    public SC_Autogen_PLUS_ADVANCED_Support()
    {
        // Query on SC_AutogenJob__c object
        for(SC_AutogenJob__c eachAutogenJob : [select Id,Autogen_UseCase_Name__c,Active__c,Additional_Calculation_1__c,
                        Additional_Calculation_2__c,Case_Owner__c,Case_Record_Type__c,
                        Description__c,Do_not_Show_in_Portal__c,Initial_Frequency__c,
                        IS_Case_Routing_Required__c,Origin__c,Product__c,PS_Product__c,
                        Recurring_Frequency__c,Request_Sub_Type__c,Request_Type__c,Service__c,
                        Severity__c,Subject__c,Subsequent_Frequency_in_Days__c,
                        Subsequent_Frequency_in_Months__c,Use_Case_Implementation_Date__c,IsTaskTobeCreated__c,
                        Sub_Type__c,Service_Category__c,visibility__c  
                        //from SC_AutogenJob__c where Active__c = True]){
                    from SC_AutogenJob__c]){
            
            autogenUseCase_FullRec.put(eachAutogenJob.Autogen_UseCase_Name__c, eachAutogenJob);            
        }
    }
        
    public List<Case> main_PLUS_ADVANCED_Method(List<Merge_Contract_Header__c> allReturnContracts)
    {
        system.debug('allReturnContracts'+allReturnContracts);
        // Set to store all Plus Product Id Values ESESP-2046
        Set<String> all_Plus_Prod = new Set<String>();
        
        // Set to store all Advanced Product Id Values ESESP-2045
        Set<String> all_Advanced_Prod = new Set<String>();
        
        // Set to store all Advanced Product Id Values ESESP-2045
        Set<String> all_PMO_Prod = new Set<String>();

        // Set to store all Advanced Product Id Values ESESP-2509
        Set<String> all_MSS_BM_Prod = new Set<String>();

        // Set to store all Advanced Product Id Values ESESP-2509
        Set<String> all_MSS_KD_Prod = new Set<String>();

        // Set to store all Advanced Product Id Values ESESP-2509
        Set<String> all_MSS_BM_KD_Prod = new Set<String>();
        
        // List#1 - To Store all Use Case Products for Active Line Items
        Set<String> allUsecaseProd = new Set<String>();
        
        // List#2 - To Store all Use Case Products for Future Effective Start Date
        Set<String> allUsecaseProdFutureESD = new Set<String>();
        
        // List#3 - To Store all Use Case Products including Active Line Items + Future Effective Start Date
        Set<String> allUsecaseProd_ACHD = new Set<String>();

        // Set to store all mPulse Product Id Values ESESP-2265
        Set<String> all_mPulse_Prod = new Set<String>();

        // Set to store all Event Support Essentials Product Id Values ESESP-3254
        Set<String> all_EventSupportEssentials = new Set<String>();

        // Set to store all Event Support Enhanced Product Id Values ESESP-3254
        Set<String> all_EventSupportEnhanced = new Set<String>();

        // Set to store all Event Support Comprehensive Product Id Values ESESP-3254
        Set<String> all_EventSupportComprehensive = new Set<String>();
        
        // boolean for storing Returned Result from AddAll Method
        boolean returnFlag = false;
        
        /** 
            Adding Product to Product sets
        **/
        // 1. For Plus Onboarding - ESESP-2046
        if(autogenUseCase_FullRec.get('Plus').Active__c){

            returnFlag = all_Plus_Prod.addAll(autogenUseCase_FullRec.get('Plus').Product__c.split(','));
            system.debug('ESESP-2046 all_Plus_Prod'+all_Plus_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_Plus_Prod);
        }
        
        // 2. For Advanced Onboarding - ESESP-2045
        if(autogenUseCase_FullRec.get('Advanced').Active__c){
            
            returnFlag = all_Advanced_Prod.addAll(autogenUseCase_FullRec.get('Advanced').Product__c.split(','));
            system.debug('ESESP-2045 all_Advanced_Prod'+all_Advanced_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_Advanced_Prod);
        } 
        
        // 3. For PM Onboarding - ESESP-2045
        if(autogenUseCase_FullRec.get('Project Management Option').Active__c){
            
            returnFlag = all_PMO_Prod.addAll(autogenUseCase_FullRec.get('Project Management Option').Product__c.split(','));
            system.debug('ESESP-2045 all_PMO_Prod'+all_PMO_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_PMO_Prod);
        }

        // 4. For MSS_BM Onboarding - ESESP-2509
        if(autogenUseCase_FullRec.get('MSS - Bot Manager Premier').Active__c){
            
            returnFlag = all_MSS_BM_Prod.addAll(autogenUseCase_FullRec.get('MSS - Bot Manager Premier').Product__c.split(','));
            system.debug('ESESP-2509 all_MSS_BM_Prod'+all_MSS_BM_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_MSS_BM_Prod);
        }

        // 5. For MSS_KD Onboarding - ESESP-2509
        if(autogenUseCase_FullRec.get('MSS - Kona Site Defender').Active__c){
            
            returnFlag = all_MSS_KD_Prod.addAll(autogenUseCase_FullRec.get('MSS - Kona Site Defender').Product__c.split(','));
            system.debug('ESESP-2509 all_MSS_KD_Prod'+all_MSS_KD_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_MSS_KD_Prod);
        }

        // 6. For MSS_BM_KD Onboarding - ESESP-2509
        if(autogenUseCase_FullRec.get('MSS - BMP & KSD').Active__c){
            
            returnFlag = all_MSS_BM_KD_Prod.addAll(autogenUseCase_FullRec.get('MSS - BMP & KSD').Product__c.split(','));
            system.debug('ESESP-2509 all_MSS_BM_KD_Prod'+all_MSS_BM_KD_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_MSS_BM_KD_Prod);
        }

        // 7. For Advanced Onboarding - ESESP-2265
        if(autogenUseCase_FullRec.get('mPulse').Active__c){
            
            returnFlag = all_mPulse_Prod.addAll(autogenUseCase_FullRec.get('mPulse').Product__c.split(','));
            system.debug('ESESP-2265 all_mPulse_Prod'+all_mPulse_Prod);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_mPulse_Prod);
        } 

        // 8. For Event Support Essentials Onboarding - ESESP-3254
        if(autogenUseCase_FullRec.get('Event Support Essentials').Active__c){

            returnFlag = all_EventSupportEssentials.addAll(autogenUseCase_FullRec.get('Event Support Essentials').Product__c.split(','));
            system.debug('ESESP-3254 all_EventSupportEssentials'+all_EventSupportEssentials);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_EventSupportEssentials);
        }

        // 9. For Event Support Enhanced Onboarding - ESESP-3254
        if(autogenUseCase_FullRec.get('Event Support Enhanced').Active__c){

            returnFlag = all_EventSupportEnhanced.addAll(autogenUseCase_FullRec.get('Event Support Enhanced').Product__c.split(','));
            system.debug('ESESP-3254 all_EventSupportEnhanced'+all_EventSupportEnhanced);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_EventSupportEnhanced);
        }

        // 10. For Event Support Comprehensive Onboarding - ESESP-3254
        if(autogenUseCase_FullRec.get('Event Support Comprehensive').Active__c){

            returnFlag = all_EventSupportComprehensive.addAll(autogenUseCase_FullRec.get('Event Support Comprehensive').Product__c.split(','));
            system.debug('ESESP-3254 all_EventSupportComprehensive'+all_EventSupportComprehensive);
            
            //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
            returnFlag = allUsecaseProdFutureESD.addAll(all_EventSupportComprehensive);
        }
        
        // Setting Values for - allUsecaseProd_ACHD set
        returnFlag = allUsecaseProd_ACHD.addAll(allUsecaseProdFutureESD);
        system.debug('allUsecaseProd_ACHD'+allUsecaseProd_ACHD);
        
        /**
            Store Contract Line Items
        **/
        //List to store all Plus contract Line Items ESESP-2046
        List<Merge_Contract_Detail__c> contractLineList_Plus =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Advanced contract Line Items ESESP-2045
        List<Merge_Contract_Detail__c> contractLineList_Advanced =  new List<Merge_Contract_Detail__c>();
        
        //List to store all PMO contract Line Items ESESP-2045
        List<Merge_Contract_Detail__c> contractLineList_PMO =  new List<Merge_Contract_Detail__c>();

        //List to store all MSS Bot Manager contract Line Items ESESP-2509
        List<Merge_Contract_Detail__c> contractLineList_MSS_BM =  new List<Merge_Contract_Detail__c>();

        //List to store all MSS Kona Defender contract Line Items ESESP-2509
        List<Merge_Contract_Detail__c> contractLineList_MSS_KD =  new List<Merge_Contract_Detail__c>();

        //List to store all MSS Bot Manager plus Kona Defender contract Line Items ESESP-2509
        List<Merge_Contract_Detail__c> contractLineList_MSS_BM_KD =  new List<Merge_Contract_Detail__c>();
        
        // List to store all Contracts - For all Use Cases(For Active Contract Lines) 
        List<Merge_Contract_Detail__c> contractLineList_ALL = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all Contracts - For all Use Cases (For Future Contract Lines)
        List<Merge_Contract_Detail__c> contractLineList_ALL_Future = new List<Merge_Contract_Detail__c>();
        
        //List to store all mPulse contract Line Items ESESP-2265
        List<Merge_Contract_Detail__c> contractLineList_mPulse =  new List<Merge_Contract_Detail__c>();

        //List to store all Event Support Essentials contract Line Items ESESP-3254
        List<Merge_Contract_Detail__c> contractLineList_EventSupportEssentials =  new List<Merge_Contract_Detail__c>();

        //List to store all Event Support Enhanced contract Line Items ESESP-3254
        List<Merge_Contract_Detail__c> contractLineList_EventSupportEnhanced =  new List<Merge_Contract_Detail__c>();

        //List to store all Event Support Comprehensive contract Line Items ESESP-3254
        List<Merge_Contract_Detail__c> contractLineList_EventSupportComprehensive =  new List<Merge_Contract_Detail__c>();

        /**
            List to store ACHD
        **/
        // 1. List to store all Contracts - For all Use Cases from Autogen_Contract_Header_Detail__c Object
        List<Autogen_Contract_Header_Detail__c> contractLineList_ACHD = new List<Autogen_Contract_Header_Detail__c>();
        
        /**
            Query# 1 -  To fetch all Contract Line Items - (For Future Contract Lines)
        **/
        if(allUsecaseProdFutureESD.size() > 0){
    
            contractLineList_ALL_Future = [Select id,Effective_Start_Date__c,Original_Contract_Id__c ,Effective_End_Date__c,
                                Original_Contract_Id__r.Account_Name__r.Name,
                                Original_Contract_Id__r.Account_Name__r.Geography_Formula__c,
                                Original_Contract_Id__r.Account_Name__c,Product__c,Name,Units_Low__c,Units_High__c,
                                Original_Contract_Id__r.Account_Name__r.Support_Level__c,
                                Original_Contract_Id__r.Effective_Start_Date__c,Original_Contract_Id__r.Effective_End_Date__c,
                                Product_Id__c,Unit_of_Measure__c,createdDate
                            from Merge_Contract_Detail__c
                            where Original_Contract_Id__c In :allReturnContracts and
                            Effective_End_Date__c >= Today and
                            Effective_Start_Date__c <> null and
                            Effective_End_Date__c <> null and
                            Product_Id__c in :allUsecaseProdFutureESD
                            ];
        }
        
        /**
            Query# 3 -  Fetch ACHD Records 
        **/
        if(allUsecaseProd_ACHD.size() > 0){
        
            contractLineList_ACHD = [select Id,Parent_Contract_Header__c,Parent_Contract_Detail__c,Product__c,IS_COB_Created__c,IS_CLI_Onboarded__c
                        from Autogen_Contract_Header_Detail__c
                        where recordTypeId = :setDetailRecordTypeId and 
                        Product__c in :allUsecaseProd_ACHD and 
                        Parent_Contract_Header__c In :allReturnContracts and 
                            Effective_Start_Date__c <> null and
                            Effective_End_Date__c <> null 
                    ];
        }
        
        
        /**
            Loop for each Line Item with the Product ID (For Future Contract Lines) - For Query#2
        **/
        
        for(Merge_Contract_Detail__c eachLineRec : contractLineList_ALL_Future)
        {
            //Collecting valid Contract Line Item for Plus Products ESESP-2046
            if(all_Plus_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_Plus.add(eachLineRec);
                }
            }
            
            //Collecting valid Contract Line Item for Advanced Products ESESP-2045
            if(all_Advanced_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_Advanced.add(eachLineRec);
                }
            } 
            
            //Collecting valid Contract Line Item for PMO Products ESESP-2045
            if(all_PMO_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_PMO.add(eachLineRec);
                }
            } 

            //Collecting valid Contract Line Item for MSS Bot Manager Products ESESP-2509
            if(all_MSS_BM_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_MSS_BM.add(eachLineRec);
                }
            } 

            //Collecting valid Contract Line Item for MSS Kona defender Products ESESP-2509
            if(all_MSS_KD_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_MSS_KD.add(eachLineRec);
                }
            } 

            //Collecting valid Contract Line Item for MSS Bot Manager plus Kona Defender Products ESESP-2509
            if(all_MSS_BM_KD_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_MSS_BM_KD.add(eachLineRec);
                }
            } 

            //Collecting valid Contract Line Item for mPulse Products ESESP-2265
            if(all_mPulse_Prod.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Per Month')
                {
                    contractLineList_mPulse.add(eachLineRec);
                }
            }

            //Collecting valid Contract Line Item for Event Support Essentials Products ESESP-2046
            if(all_EventSupportEssentials.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Base Fee')
                {
                    contractLineList_EventSupportEssentials.add(eachLineRec);
                }
            }

            //Collecting valid Contract Line Item for Event Support Enhanced Products ESESP-2046
            if(all_EventSupportEnhanced.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Base Fee')
                {
                    contractLineList_EventSupportEnhanced.add(eachLineRec);
                }
            }

            //Collecting valid Contract Line Item for Event Support Comprehensive Products ESESP-2046
            if(all_EventSupportComprehensive.contains(eachLineRec.Product_Id__c)){
                if(eachLineRec.Unit_of_Measure__c == 'Base Fee')
                {
                    contractLineList_EventSupportComprehensive.add(eachLineRec);
                }
            } 
        }
        system.debug('contractLineList_Plus'+contractLineList_Plus);
        system.debug('contractLineList_Advanced'+contractLineList_Advanced);
        system.debug('contractLineList_PMO'+contractLineList_PMO);
        system.debug('contractLineList_MSS_BM'+contractLineList_MSS_BM);
        system.debug('contractLineList_MSS_KD'+contractLineList_MSS_KD);
        system.debug('contractLineList_MSS_BM_KD'+contractLineList_MSS_BM_KD);
        system.debug('contractLineList_mPulse'+contractLineList_mPulse);
        system.debug('contractLineList_EventSupportEssentials'+contractLineList_EventSupportEssentials);
        system.debug('contractLineList_EventSupportEnhanced'+contractLineList_EventSupportEnhanced);
        system.debug('contractLineList_EventSupportComprehensive'+contractLineList_EventSupportComprehensive);
        
        /**
            Loop for each Line Item with the Product ID in  Autogen_Contract_Header_Detail__c Object
        **/ 
        for(Autogen_Contract_Header_Detail__c eachACHDRec : contractLineList_ACHD)
        {
            // Adding Record to Map 
            contractDetailId_COBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Detail__c, eachACHDRec);

            //1. Plus check to see if CLI is already onboarded ESESP-2046
            if(all_Plus_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for Plus');
                onboardedCLIPlus.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }
            
            //2. Advanced check to see if CLI is already onboarded ESESP-2045
            if(all_Advanced_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for Advanced');
                onboardedCLIAdvanced.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }
            
            //3. PMO check to see if CLI is already onboarded ESESP-2045
            if(all_PMO_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for PMO');
                onboardedCLIPMO.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //4. MSS Bot Manager check to see if CLI is already onboarded ESESP-2509
            if(all_MSS_BM_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for MSS_BM');
                onboardedCLI_MSS_BM.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //5. MSS Kona Defender check to see if CLI is already onboarded ESESP-2509
            if(all_MSS_KD_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for MSS_KD');
                onboardedCLI_MSS_KD.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //6. MSS Bot Manager plus Kona Defender check to see if CLI is already onboarded ESESP-2509
            if(all_MSS_BM_KD_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for MSS_BM_KD');
                onboardedCLI_MSS_BM_KD.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //7. mPulse check to see if CLI is already onboarded ESESP-2265
            if(all_mPulse_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for mPulse');
                onboardedCLImPulse.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //8. Event Support Essentials check to see if CLI is already onboarded ESESP-3254
            if(all_EventSupportEssentials.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for Event Support Essentials');
                onboardedCLIEventSupportEssentials.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //9. Event Support Enhanced check to see if CLI is already onboarded ESESP-3254
            if(all_EventSupportEnhanced.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for Event Support Enhanced');
                onboardedCLIEventSupportEnhanced.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }

            //10. Event Support Comprehensive check to see if CLI is already onboarded ESESP-3254
            if(all_EventSupportComprehensive.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                //Collect ACHD that are onboarded
                System.debug('Collecting Onboarded CLIs for Event Support Comprehensive');
                onboardedCLIEventSupportComprehensive.put(eachACHDRec.Parent_Contract_Detail__c, true);
            }
        }
        
        // deallocate Memory for Product Variables
        all_Plus_Prod.clear();
        all_Advanced_Prod.clear();
        all_PMO_Prod.clear();
        all_MSS_BM_Prod.clear();
        all_MSS_KD_Prod.clear();
        all_MSS_BM_KD_Prod.clear();
        contractLineList_ALL.clear();
        contractLineList_ALL_Future.clear();
        contractLineList_ACHD.clear();
        all_mPulse_Prod.clear();
        all_EventSupportEssentials.clear();
        all_EventSupportEnhanced.clear();
        all_EventSupportComprehensive.clear();

        
        /**
            Call to Case Calculation Methods
        **/

        //...........Call to filterCLI Method for Plus Products ESESP-2046
        if(contractLineList_Plus.size() > 0)
            filterCLI(contractLineList_Plus,'Plus',onboardedCLIPlus);
        
        //...........Call to filterCLI Method for Advanced Products ESESP-2045
        if(contractLineList_Advanced.size() > 0)
            filterCLI(contractLineList_Advanced,'Advanced',onboardedCLIAdvanced);
        
        //...........Call to filterCLI Method for PMO Products ESESP-2045
        if(contractLineList_PMO.size() > 0)
            filterCLI(contractLineList_PMO,'Project Management Option',onboardedCLIPMO);

        //...........Call to filterCLI Method for MSS BM Products ESESP-2509
        if(contractLineList_MSS_BM.size() > 0)
            filterCLI(contractLineList_MSS_BM,'MSS - Bot Manager Premier',onboardedCLI_MSS_BM);

        //...........Call to filterCLI Method for MSS KD Products ESESP-2509
        if(contractLineList_MSS_KD.size() > 0)
            filterCLI(contractLineList_MSS_KD,'MSS - Kona Site Defender',onboardedCLI_MSS_KD);

        //...........Call to filterCLI Method for MSS BM KD Products ESESP-2509
        if(contractLineList_MSS_BM_KD.size() > 0)
            filterCLI(contractLineList_MSS_BM_KD,'MSS - BMP & KSD',onboardedCLI_MSS_BM_KD);

        //...........Call to filterCLI Method for mPulse Products ESESP-2265
        if(contractLineList_mPulse.size() > 0)
            filterCLI(contractLineList_mPulse,'mPulse',onboardedCLImPulse);
        
        //...........Call to filterCLI Method for Event Support Essentials Products ESESP-3254
        if(contractLineList_EventSupportEssentials.size() > 0)
            filterCLI(contractLineList_EventSupportEssentials,'Event Support Essentials',onboardedCLIEventSupportEssentials);

        //...........Call to filterCLI Method for Event Support Enhanced Products ESESP-3254
        if(contractLineList_EventSupportEnhanced.size() > 0)
            filterCLI(contractLineList_EventSupportEnhanced,'Event Support Enhanced',onboardedCLIEventSupportEnhanced);

        //...........Call to filterCLI Method for Event Support Comprehensive Products ESESP-3254
        if(contractLineList_EventSupportComprehensive.size() > 0)
            filterCLI(contractLineList_EventSupportComprehensive,'Event Support Comprehensive',onboardedCLIEventSupportComprehensive);
        

        /** Clearing Contract Lists **/
        contractLineList_Plus.clear();
        contractLineList_Advanced.clear();
        contractLineList_PMO.clear();
        contractLineList_MSS_BM.clear();
        contractLineList_MSS_KD.clear();
        contractLineList_MSS_BM_KD.clear();
        contractLineList_mPulse.clear();
        contractLineList_EventSupportEssentials.clear();
        contractLineList_EventSupportEnhanced.clear();
        contractLineList_EventSupportComprehensive.clear();
        
        /** Clearing ACHD Maps **/
        onboardedCLIPlus.clear();
        onboardedCLIAdvanced.clear();
        onboardedCLIPMO.clear();
        onboardedCLI_MSS_BM.clear();
        onboardedCLI_MSS_KD.clear();
        onboardedCLI_MSS_BM_KD.clear();
        onboardedCLImPulse.clear();
        onboardedCLIEventSupportEssentials.clear();
        onboardedCLIEventSupportEnhanced.clear();
        onboardedCLIEventSupportComprehensive.clear();
            
        /** Inserting Cases **/
        if(caseCreateList.size() > 0)
            Upsert caseCreateList Id;
        
        //Create child cases for Advanced product ESESP-2045
        if(caseCreateList.size() > 0){
            createAdvancedChildCases(caseCreateList);
        }

        /** Updating ACHD **/
        if(allContractLnsUpdateMap.size() > 0)
        {
            Update allContractLnsUpdateMap.values();
        }
        
        // deallocate Memory
        caseCreateListTemp.addAll(caseCreateList);
        caseCreateList.clear();
        allContractLnsUpdateMap.clear(); 
        return caseCreateListTemp;        
    }
        
    /****
        @desc    Method to Calculate Case Creation Conditions for Plus & Advanced
        @param   List<CLI>,UseCase,Map<ACHDId,boolean>
        @return  null
    ****/
    public void filterCLI(List<Merge_Contract_Detail__c> contractLineList_Incoming, String useCase, Map<Id,boolean> onboardedCLIAGACHD)
    {        
        List<Merge_Contract_Detail__c> contractLineList_Filtered = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> contractLineList_Final = new List<Merge_Contract_Detail__c>();
        
        //Condition check 
        for(Merge_Contract_Detail__c eachLine : contractLineList_Incoming)
        {
            system.debug('Tommorow' + System.today().addDays(1));
            system.debug('34 advance' + System.today().addDays(34));
            system.debug('34 Prior' + System.today().addDays(-34));
            if(System.today().addDays(-34) <= eachLine.Effective_Start_Date__c&& eachLine.Effective_Start_Date__c <= System.today())
            {
                if(System.today().addDays(-2) <= eachLine.CreatedDate.date() && eachLine.CreatedDate.date() <= System.today())
                {
                    contractLineList_Filtered.add(eachLine);
                }
            }
            
            if(System.today().addDays(1)<= eachLine.Effective_Start_Date__c && eachLine.Effective_Start_Date__c <= System.today().addDays(34))
            {
                contractLineList_Filtered.add(eachLine);
            } 
        }
        //Check if CLI has onboarding flag set
        for(Merge_Contract_Detail__c C:contractLineList_Filtered)
        {
            if(onboardedCLIAGACHD.get(C.Id)==null)
            {
                contractLineList_Final.add(C);
            }
        }
        
        //Pass the final Contract List for Case Creation
        if(contractLineList_Final.size()>0)
        {
            //Create Case
            if(useCase == 'Plus')
                createCasePlus(contractLineList_Final,useCase);
            
            if(useCase == 'Advanced')
                createCaseAdvanced(contractLineList_Final,useCase);
            
            if(useCase == 'Project Management Option')
                createCasePMO(contractLineList_Final,useCase);

            if(useCase == 'MSS - Bot Manager Premier' || useCase == 'MSS - Kona Site Defender' || useCase == 'MSS - BMP & KSD')
                createCaseMSS(contractLineList_Final,useCase);
            
            if(useCase == 'mPulse')
                createCaseMPulse(contractLineList_Final,useCase);
            
            if(useCase == 'Event Support Essentials')
                createCasePlus(contractLineList_Final,useCase);
            
            if(useCase == 'Event Support Enhanced')
                createCasePlus(contractLineList_Final,useCase);
            
            if(useCase == 'Event Support Comprehensive')
                createCasePlus(contractLineList_Final,useCase);
                       
            //Update corresponding ACHD
            system.debug('contractLineList_Final : '+contractLineList_Final);
            updatePlusContractLines_ACHD(contractLineList_Final);
        }
    }

    /****
        @desc    Method to Add Cases to CaseList Plus
        @param   List<CLI>,UseCase
        @return  null
    ****/
    public void createCasePlus(List<Merge_Contract_Detail__c> ContractLine_Plus, string useCase)
    {
        system.debug('Create Case Plus '+useCase);
            
        // Create a Map with startdate+enddate+accountid as key and List of CLI as value.This is to not create repetitive cases if two CLIs
        // under same Account have same start date and end date
        Map<String,List<Merge_Contract_Detail__c>> CaseCreationMap = new Map<String,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> CaseCreationList = new List<Merge_Contract_Detail__c>();
        
        //Populate the map
        for(Merge_Contract_Detail__c CLI:ContractLine_Plus)
        {
            String Key = CLI.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(CLI.Effective_Start_Date__c)+string.valueOfGmt(CLI.Effective_End_Date__c);
            List<Merge_Contract_Detail__c> ContDet = CaseCreationMap.get(key);
            system.debug('ESESP-2046 Key '+Key);
            
            if(ContDet==null)
            {
                ContDet = new List<Merge_Contract_Detail__c>();
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
            else
            {
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
        }
        
        system.debug('Printing the Map ' + CaseCreationMap);
        
        //Constructing a new List for Case Creation from CaseCreationMap
        for(List<Merge_Contract_Detail__c> CntlineList:CaseCreationMap.values())
        {
            CaseCreationList.add(CntlineList[0]);
        }
        
        system.debug('Final plus Case Creation List ' + CaseCreationList);
        
        // Fetching Professional services Record Type
        Id devRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        Id devTechRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        
        case eachCaserec;
        
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        //Create Case for Each Valid CLI
        for(Merge_Contract_Detail__c eachCntrctLnRec : CaseCreationList)
        {
            eachCaserec = new Case();
            eachCaserec.RecordTypeId = devRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+autogenUseCase_FullRec.get(useCase).Subject__c+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = autogenUseCase_FullRec.get(useCase).Description__c;
            eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
            //Added these two as part of jira 2329 since they required this for creation of projects
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
            
            caseCreateList.add(eachCaserec);
        }
    }


    /****
        @desc    Method to Add Cases to CaseList Advanced
        @param   List<CLI>,UseCase
        @return  null
    ****/
    public void createCaseAdvanced(List<Merge_Contract_Detail__c> ContractLine_Advanced, string useCase)
    {
        
        system.debug('Create Case Advanced '+useCase);
            
        // Create a Map with startdate+enddate+accountid as key and List of CLI as value.This is to not create repetitive cases if two CLIs
        // under same Account have same start date and end date
        Map<String,List<Merge_Contract_Detail__c>> CaseCreationMap = new Map<String,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> CaseCreationList = new List<Merge_Contract_Detail__c>();
        
        system.debug('ContractLine_Advanced : '+ContractLine_Advanced);
        //Populate the map
        for(Merge_Contract_Detail__c CLI:ContractLine_Advanced)
        {
            String Key = CLI.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(CLI.Effective_Start_Date__c)+string.valueOfGmt(CLI.Effective_End_Date__c);
            List<Merge_Contract_Detail__c> ContDet = CaseCreationMap.get(key);
            system.debug('ESESP-2046 Key '+Key);
            
            if(ContDet==null)
            {
                ContDet = new List<Merge_Contract_Detail__c>();
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
            else
            {
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
        }
        
        system.debug('Printing the Map ' + CaseCreationMap);
        
        //Constructing a new List for Case Creation from CaseCreationMap
        for(List<Merge_Contract_Detail__c> CntlineList:CaseCreationMap.values())
        {
            CaseCreationList.add(CntlineList[0]);
        }
        
        system.debug('Final plus Case Creation List ' + CaseCreationList);
        
        // Fetching Professional services Record Type
        Id devRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        case eachCaserec;
        
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;

        String sub = autogenUseCase_FullRec.get(useCase).Subject__c;
        String descp = autogenUseCase_FullRec.get(useCase).Description__c;
        List<String> subjectList = new List<String>();
        Map<String,String> RTSubMap = new Map<String,String>();
        List<String> descList = new List<String>();
        Map<String,String> RTDescMap = new Map<String,String>();
        
        subjectList = sub.split(';');
        descList = descp.split(';');
        
        for(String eachSub : subjectList){
            RTSubMap.put(eachSub.split('=')[0],eachSub.split('=')[1]);
        }
        for(String eachDesc : descList){
            RTDescMap.put(eachDesc.split('=')[0],eachDesc.split('=')[1]);
        }
        //Create Case for Each Valid CLI
        for(Merge_Contract_Detail__c eachCntrctLnRec : CaseCreationList)
        {
            //CSG Case
            eachCaserec = new Case();
            eachCaserec.setOptions(dmo);
            eachCaserec.RecordTypeId = devRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+RTSubMap.get('CSG')+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = RTDescMap.get('CSG');
            eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
            //Added these two as part of jira 2329 since they required this for creation of projects
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
            
            caseCreateList.add(eachCaserec);
            
            if(useCase == 'Advanced'){
                advancedCaseCreateList = new List<Case>();
                advancedCaseCreateList.add(createCaseAdvancedMultiple(eachCntrctLnRec, 'Professional Services', useCase, RTSubMap, RTDescMap));
                advancedCaseCreateList.add(createCaseAdvancedMultiple(eachCntrctLnRec, 'Technical', useCase, RTSubMap, RTDescMap));
                system.debug('advancedCaseCreateList inside method : '+advancedCaseCreateList.size());
                system.debug('CLI Detailc : '+eachCaserec.Contract_Detail__c);
                parentContractDetailCaseMap.put(eachCaserec.Contract_Detail__c,advancedCaseCreateList);
                system.debug('parentContractDetailCaseMap : '+parentContractDetailCaseMap);
            }
        }
    }

    /****
        @desc    Method to Add Cases to CaseList mPulse (ESESP-2265)
        @param   List<CLI>,UseCase
        @return  null
    ****/
    public void createCaseMPulse(List<Merge_Contract_Detail__c> ContractLine_mPulse, string useCase)
    {
        
        system.debug('Create Case mPulse '+useCase);
            
        // Create a Map with startdate+enddate+accountid as key and List of CLI as value.This is to not create repetitive cases if two CLIs
        // under same Account have same start date and end date
        Map<String,List<Merge_Contract_Detail__c>> CaseCreationMap = new Map<String,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> CaseCreationList = new List<Merge_Contract_Detail__c>();
        
        system.debug('ContractLine_mPulse : '+ContractLine_mPulse);
        //Populate the map
        for(Merge_Contract_Detail__c CLI:ContractLine_mPulse)
        {
            String Key = CLI.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(CLI.Effective_Start_Date__c)+string.valueOfGmt(CLI.Effective_End_Date__c);
            List<Merge_Contract_Detail__c> ContDet = CaseCreationMap.get(key);
            system.debug('ESESP-2046 Key '+Key);
            
            if(ContDet==null)
            {
                ContDet = new List<Merge_Contract_Detail__c>();
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
            else
            {
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
        }
        
        system.debug('Printing the Map ' + CaseCreationMap);
        
        //Constructing a new List for Case Creation from CaseCreationMap
        for(List<Merge_Contract_Detail__c> CntlineList:CaseCreationMap.values())
        {
            CaseCreationList.add(CntlineList[0]);
        }
        
        system.debug('Final plus Case Creation List ' + CaseCreationList);
        
        // Fetching Professional services Record Type
        Id devRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        case eachCaserec;
        
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        //Create Case for Each Valid CLI
        for(Merge_Contract_Detail__c eachCntrctLnRec : CaseCreationList)
        {
            eachCaserec = new Case();
            eachCaserec.RecordTypeId = devRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+autogenUseCase_FullRec.get(useCase).Subject__c+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = autogenUseCase_FullRec.get(useCase).Description__c;
            eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
            
            caseCreateList.add(eachCaserec);
        }
    }

    /****
        @desc    Method to Add Cases to CaseList PMO
        @param   List<CLI>,UseCase
        @return  null
    ****/
    public void createCasePMO(List<Merge_Contract_Detail__c> ContractLine_Advanced, string useCase)
    {
        // Create a Map with startdate+enddate+accountid as key and List of CLI as value.This is to not create repetitive cases if two CLIs
        // under same Account have same start date and end date
        Map<String,List<Merge_Contract_Detail__c>> CaseCreationMap = new Map<String,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> CaseCreationList = new List<Merge_Contract_Detail__c>();
        
        //Populate the map
        for(Merge_Contract_Detail__c CLI:ContractLine_Advanced)
        {
            String Key = CLI.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(CLI.Effective_Start_Date__c)+string.valueOfGmt(CLI.Effective_End_Date__c);
            List<Merge_Contract_Detail__c> ContDet = CaseCreationMap.get(key);
            if(ContDet==null)
            {
                ContDet = new List<Merge_Contract_Detail__c>();
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
            else
            {
                ContDet.add(CLI);
                CaseCreationMap.put(Key,ContDet);
            }
        }
        
        //Constructing a new List for Case Creation from CaseCreationMap
        for(List<Merge_Contract_Detail__c> CntlineList:CaseCreationMap.values())
        {
            CaseCreationList.add(CntlineList[0]);
        }
                
        // Fetching Professional services Record Type
        Id devRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        case eachCaserec;
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        //Create Case for Each Valid CLI
        for(Merge_Contract_Detail__c eachCntrctLnRec : CaseCreationList)
        {
            //CSG Case
            eachCaserec = new Case();
            eachCaserec.setOptions(dmo);
            eachCaserec.RecordTypeId = devRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+autogenUseCase_FullRec.get(useCase).Subject__c+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = autogenUseCase_FullRec.get(useCase).Description__c;
            eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
            //Added these two as part of jira 2329 since they required this for creation of projects
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
            
            caseCreateList.add(eachCaserec); 
        }
    }

    /****
        @desc    Method to Add Cases to CaseList MSS
        @param   List<CLI>,UseCase
        @return  null
    ****/
    public void createCaseMSS(List<Merge_Contract_Detail__c> contractLine_MSS, string useCase)
    {
        // Create a Map with startdate+enddate+accountid as key and List of CLI as value.This is to not create repetitive cases if two CLIs
        // under same Account have same start date and end date
        Map<String,List<Merge_Contract_Detail__c>> caseCreationMap = new Map<String,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> caseCreationList = new List<Merge_Contract_Detail__c>();
        
        //Populate the map
        for(Merge_Contract_Detail__c CLI:contractLine_MSS)
        {
            String Key = CLI.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(CLI.Effective_Start_Date__c)+string.valueOfGmt(CLI.Effective_End_Date__c);
            List<Merge_Contract_Detail__c> ContDet = caseCreationMap.get(key);
            if(ContDet==null)
            {
                ContDet = new List<Merge_Contract_Detail__c>();
                ContDet.add(CLI);
                caseCreationMap.put(Key,ContDet);
            }
            else
            {
                ContDet.add(CLI);
                caseCreationMap.put(Key,ContDet);
            }
        }
        
        //Constructing a new List for Case Creation from caseCreationMap
        for(List<Merge_Contract_Detail__c> CntlineList:caseCreationMap.values())
        {
            caseCreationList.add(CntlineList[0]);
        }
                
        // Fetching Professional services Record Type
        Id devRecordTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        case eachCaserec;
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        //Create Case for Each Valid CLI
        for(Merge_Contract_Detail__c eachCntrctLnRec : caseCreationList)
        {
            //CSG Case
            eachCaserec = new Case();
            eachCaserec.setOptions(dmo);
            eachCaserec.RecordTypeId = devRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+autogenUseCase_FullRec.get(useCase).Subject__c+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = autogenUseCase_FullRec.get(useCase).Description__c;
            eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
            //Added these two as part of jira 2329 since they required this for creation of projects
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
            
            caseCreateList.add(eachCaserec); 
        }
    }

    /****
        @desc    Support Method for Advanced Cases
        @param   List<CLI>,recTypeName,Usecase,RTSubMap,RTDescMap
        @return  null
    ****/

    public Case createCaseAdvancedMultiple(Merge_Contract_Detail__c eachCntrctLnRec, String recTypeName, string useCase, Map<String,String> RTSubMap, Map<String,String> RTDescMap)
    {
        system.debug('inside createCaseAdvancedMultiple');
        //Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        Id recTypeId =Schema.SObjectType.Case.getRecordTypeInfosByName().get(recTypeName).getRecordTypeId();
        Case eachCaserec = new Case();
        eachCaserec.setOptions(dmo);
        eachCaserec.RecordTypeId = recTypeId;
        eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
        eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
        eachCaserec.origin                  = autogenUseCase_FullRec.get(useCase).Origin__c;
        eachCaserec.Severity__c             = autogenUseCase_FullRec.get(useCase).Severity__c;
        eachCaserec.Do_Not_Show_in_Portal__c= autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
        eachCaserec.Case_Assignment_Using_Active_Rules__c = autogenUseCase_FullRec.get(useCase).IS_Case_Routing_Required__c;
        eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
        eachCaserec.Autogen_UseCase__c      = autogenUseCase_FullRec.get(useCase).Autogen_UseCase_Name__c;
        
        if(recTypeName == 'Professional Services'){
            eachCaserec.Subject                 = autogenUseCase_FullRec.get(useCase).Service__c+'::'+RTSubMap.get('SD')+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Service__c              = autogenUseCase_FullRec.get(useCase).Service__c;
            eachCaserec.Request_Type__c         = autogenUseCase_FullRec.get(useCase).Request_Type__c;
            eachCaserec.Description             = RTDescMap.get('CSG');

        }
        if(recTypeName == 'Technical'){
            eachCaserec.Subject                 = 'Advanced::'+RTSubMap.get('Akatec')+'::'+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Sub_Type__c       = autogenUseCase_FullRec.get(useCase).Sub_Type__c;
            eachCaserec.Do_Not_Show_In_Portal_Picklist__c       = autogenUseCase_FullRec.get(useCase).Visibility__c;
            eachCaserec.Description = RTDescMap.get('Akatec');
        }
        return eachCaserec;
    }


    /****
        @desc    Method to Create Advanced Child Cases
        @param   List<CLI>
        @return  null
    ****/
    public void createAdvancedChildCases(List<Case> caseCreateList)
    {
        List<Case> insetAdvancedCaseList = new List<Case>();
        Map<Id,List<Case>> advancedChildCaseMap = new Map<Id,List<Case>>();
        
        system.debug('*****ADVANCED***** parentContractDetailCaseMap : '+parentContractDetailCaseMap);
        system.debug('*****ADVANCED***** parentContractDetailCaseMap size: '+parentContractDetailCaseMap.size());
        for(Case CSGCase : caseCreateList){
            if(CSGCase.Autogen_UseCase__c == 'Advanced'){
                advancedChildCaseMap.put(CSGCase.id, parentContractDetailCaseMap.get(CSGCase.Contract_Detail__c));
            }
        }
        
        system.debug('*****ADVANCED***** advancedChildCaseMap : '+advancedChildCaseMap);
        system.debug('*****ADVANCED***** advancedChildCaseMap size: '+advancedChildCaseMap.size());
        for(Id parentId : advancedChildCaseMap.keySet()){
            for(Case cc : advancedChildCaseMap.get(parentId)){
                cc.parentId = parentId;
                system.debug('cc : : : '+cc);
                insetAdvancedCaseList.add(cc);
            }
        }
        
        system.debug('*****ADVANCED***** insetAdvancedCaseList : '+insetAdvancedCaseList);
        system.debug('*****ADVANCED***** insetAdvancedCaseList size: '+insetAdvancedCaseList.size());
        if(insetAdvancedCaseList.size() > 0){
            insert insetAdvancedCaseList;
        }
    }


    /****
        @desc    Method to Update ACHD for Plus & Advanced
        @param   List<CLI>
        @return  null
    ****/
    public void updatePlusContractLines_ACHD(List<Merge_Contract_Detail__c> contractLineList_Final)
    {
        system.debug('Updating Plus related ACHD');
        Autogen_Contract_Header_Detail__c eachACHDRec;
        
        //Designing the Key
        string key;
        // Loop for each Contract Line
        if(contractLineList_Final != null)
        {
            for(Merge_Contract_Detail__c eachCntrctLnRec : contractLineList_Final)
            {
                System.debug('Each line item in map ' + eachCntrctLnRec);
                key = eachCntrctLnRec.Id;
                if(contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID) <> null && contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID).IS_CLI_Onboarded__c == false)
                {
                    eachACHDRec = new Autogen_Contract_Header_Detail__c(Id=contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID).Id);
                    eachACHDRec.IS_CLI_Onboarded__c = True;
                    allContractLnsUpdateMap.put(key,eachACHDRec);
                    System.debug('Each ACHD record isCOB : ' + eachACHDRec.IS_CLI_Onboarded__c);
                    System.debug('Each ACHD record : ' + eachACHDRec);          
                }
            }
        }
    }

    /****
        @desc    Method to Update Parent Case on created TPM cases
        @param   List<Case>
        @return  null
    ****/
    public void linkTPMCasesWithEMCases(List<Case> createdCases){
        System.debug('new cases***'+createdCases);
        List<Case> applicableCases = new List<Case>();
        
        List<String> contractDetailsIds = new List<String>();
        List<Merge_Contract_Detail__c> contractDetailsList = new List<Merge_Contract_Detail__c>();
        Map<String,Merge_Contract_Detail__c> contractDetailsMap = new Map<String,Merge_Contract_Detail__c>();
        Map<String,List<Case>> keyVsTPMCases = new Map<String,List<Case>>();
        Map<String,List<Case>> keyVsEMCases = new Map<String,List<Case>>();
        List<Case> TPMCasesToUpdate = new List<Case>();
        Map<String,String> RTSubMap = new Map<String,String>();
        String key = '';
        List<String> subjectList = autogenUseCase_FullRec.get('Advanced').Subject__c.split(';');
        for(String eachSub : subjectList){
            RTSubMap.put(eachSub.split('=')[0],eachSub.split('=')[1]);
        }
        for(Case iteratedCase : createdCases){
            if(iteratedCase.Subject.contains(autogenUseCase_FullRec.get('Project Management Option').Subject__c) || iteratedCase.Subject.contains(RTSubMap.get('CSG'))){
                if(iteratedCase.Contract_Detail__c != ''){
                    applicableCases.add(iteratedCase);
                    contractDetailsIds.add(iteratedCase.Contract_Detail__c);
                }
            }
        }
        
        if(contractDetailsIds.size() > 0){
            contractDetailsList = [Select Id,Name,Original_Contract_Id__r.Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c from Merge_Contract_Detail__c where Name IN: contractDetailsIds];
            for(Merge_Contract_Detail__c iteratedContractDetail : contractDetailsList){
                contractDetailsMap.put(iteratedContractDetail.Name,iteratedContractDetail); 
            }
            
            for(Case iteratedCase : applicableCases){
                key = contractDetailsMap.get(iteratedCase.Contract_Detail__c).Original_Contract_Id__r.Account_Name__c +'-'+ contractDetailsMap.get(iteratedCase.Contract_Detail__c).Effective_Start_Date__c +'-'+ contractDetailsMap.get(iteratedCase.Contract_Detail__c).Effective_End_Date__c;
                
                if(iteratedCase.Subject.contains(autogenUseCase_FullRec.get('Project Management Option').Subject__c)){
                    if(!keyVsTPMCases.containsKey(key)){
                        keyVsTPMCases.put(key,new List<Case>());
                    }
                    keyVsTPMCases.get(key).add(iteratedCase);
                }else if(iteratedCase.Subject.contains(RTSubMap.get('CSG'))){
                    if(!keyVsEMCases.containsKey(key)){
                        keyVsEMCases.put(key,new List<Case>());
                    }
                    keyVsEMCases.get(key).add(iteratedCase);
                }
            }
            
            for(String iteratedKey : keyVsTPMCases.keySet()){
                if(keyVsEMCases.containsKey(iteratedKey)){
                    for(Case iteratedTPMCase : keyVsTPMCases.get(iteratedKey)){
                        
                        if(String.isBlank(iteratedTPMCase.parentId)){
                            iteratedTPMCase.parentId = keyVsEMCases.get(iteratedKey)[0].Id;
                            TPMCasesToUpdate.add(iteratedTPMCase);
                        }
                    }
                }
            }
            
        }

        if(TPMCasesToUpdate.size() > 0){
            update TPMCasesToUpdate;
        }
        
    }
}