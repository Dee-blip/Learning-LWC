/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER         CR            DESCRIPTION                               

|  ===========    =========         ============      =========== 
                                                       
|  17-JUN-2014    Himanshu Kar      2604198(3.43)       This is a support class for - SC_Autogen_RUS_PPSM_QBR_Batch
                                              This Class is used for below Use Cases:
|                                               1. RUS
                                                  2. PPSM
|                                                 3. QBR
                                            
   07-AUG-2014    Himanshu Kar    2637480(3.44)       4. SMP - On Boarding
|                                 2637489(3.44)       5. SMP - Recurring(Optmization schedule )
                                            
|  20-AUG-2014    Himanshu Kar      2567658(3.45)       6. NES - On Boarding (1 Case Pear Each Line)
                                          
|  03-NOV-2014    Himanshu Kar      2735652(4.1)        7. KONA   

|  13-NOV-2014    Himanshu Kar      2735625(4.2)        8. KONA - On Boarding (1 Case Per Each Contract Header) 

|  24-FEB-2015    Himanshu Kar      2784576(4.5)        Changed Logic for SMP on-boarding - Create 1 case instead of Multiple cases 

|  24-FEB-2015    Himanshu Kar      2784594(4.5)        Changed Logic for SMP Recurring - Create 1 case instead of Multiple cases 

|  25-FEB-2015    Himanshu Kar      2844210(4.5)        9. KDD - On Boarding (1 Case Per Each Contract Header)  
   
|  20-APR-2015    Himanshu Kar      2957996(4.7)    Added Configuration approach to decide whether Autogen UseCase will run or not 

|  20-APR-2015    Himanshu Kar      2966051(4.8)    Changed Routing for PPSM Use Case - Changed recordType Calculation

|  13-Jul-2015    Himanshu Kar      2799363(4.9)    Create 1 QBR Case per contract Per Product basis instead of Multiple cases for each Line Item

|  13-Jul-2015    Himanshu Kar      3003203(4.9)    Changed Logic for Recurring Case Creation for - SMP Security Product

|  13-Jul-2015    Himanshu Kar      2906031(4.9)    Changed Logic for KONA Onboarding - case can be created with future Effective Date

|  13-Aug-2015    Himanshu Kar      3085851(4.10)   Changed the Design for removing Custom Fields on Contract Detail Object

|  12-Oct-2015    Himanshu Kar      3003194(4.12)   Integration of SC-Project. Use Case = SMP-NonSec COB 

|  12-Nov-2015    Himanshu Kar      3117781(4.13)   10. GDS - On Boarding (1 Case Per Each Contract Header) - Guided Delivery Service

|  12-Nov-2015    Himanshu Kar      3117831(4.13)   11. GDS - Recurring (1 Case Per Each Contract Header)

|  12-Nov-2015    Himanshu Kar      3117841(4.13)   12. MDS - On Boarding (1 Case Per Each Contract Header) - Managed Delivery Service 

|  16-Dec-2015    Himanshu Kar      3114091(4.14)   Changed Case Parameters for KONA Use Case

|  11-Mar-2016    Sonia             3320211(16.3.1)       GDRAT-to-DGRAT reorg: AMG functionality fixes - 
                                      Replaced all Geography checks to use the custom setting

|  16-APR-2016    Himanshu Kar      3239511(16.4)   13. KSD - On Boarding (1 Case Per Each Contract Header)

|  16-APR-2016    Himanshu Kar      3239491(16.4)   14. KONA-COB Case Creation Logic Change (Based on KSD COB Case)
                                      - UseCase 1 : KONA-COB-WithKSD (If KSD Case present with Status != Closed)
                                      - UseCase 2 : KONA-COB-WithoutKSD (If no KSD Case or KSD Case with Status = Closed)
|                           
   18-MAY-2016    Himanshu Kar      3239521(16.5)   15. Modified KDD Case Parameters and added logic for Task Creation
   
|  18-MAY-2016    Himanshu Kar      3240961(16.5)   16. Implemented below new Use Cases for SOA(Security Optimization Assistance)
                  a. SOA-Parent - For SOA Parent Product
                  b. SOA-Prolexic - For SOA Prolexic Product(Child)
                  c. SOA-BotManager - For SOA Bot Manager Product(Child)
                  d. SOA-WebAppFirewall - For SOA Web Application Firewall Product(Child)
                  e. SOA-KSD - For Kona Site Defender(Child)

|  18-JUN-2016    Himanshu Kar      3333321(16.6)   17. Implemented BOCC - On Boarding (1 Case Per Each Contract Header)

|  11-JUL-2016    Himanshu Kar      3437991(16.7)   18. Modified SOA Use Case and added this to New Design

|  19-Sep-2016    Aditya Sonam      3283891(16.10)   - Removed 'Security Review cases for Managed Kona' functionality implemented in CR 2735652

|  20-Sep-2016    Vamsee Surya      3310631(16.10)   - Modified the request type for Guided Delivery Service and also added case sequence number to the subject

|  17-OCT-2016    Himanshu Kar      3527841(16.10)   - Modification of SMP Security Logic

|  17-Nov-2016    Himanshu Kar      3513251(16.11)   - Modified Query on ACHD object to handle Contract Renewal Logic

|  26-Dec-2016    Vandhana 
                Krishnamurthy       3549401(17.1)    - GDS Quarterly Touchpoint cases not getting generated when they should

|  26-Dec-2016    Pinkesh Rathore   3597711(17.1)    - Need to update SOA auto-gen Onboarding Case with new option - Web Application Protector

|  16-Jan-2017    Vandhana 
                Krishnamurthy       3562411(17.2)    - Auto generate on-boarding case for 
                                                        PS-Enterprise Product

|  16-Jan-2017    Pinkesh Rathore   3562411(17.2)    - Auto generate on-boarding case for 
                                                        TAS Product


|  16-Jan-2017    Vandhana 
                Krishnamurthy       3337441(17.2)    - Auto generate on-boarding case for 
                                                        Prolexic Connect Product

|  28-Mar-2017  Pinkesh             3697982(17.4)    -  Made validate override True in updateCaseMethod method

|  18-May-2017  Pinkesh       ESESP-460   -   Auto-gen Onboarding Case when PLX Routed product activated on the contract.

|  23-Jun-2017  Vamsee      ESESP-590   -   Auto-gen Onboarding PS Case (RRS Product)

|  14-Sep-2017  Pinkesh       ESESP-690   -   Auto-gen Onboarding Case when PS-S product activated on the contract.
   
|  12-Jun-2018  Sumanth       ESESP-1129  -   Auto-gen Onboarding Case when Protect and Perform::Security Optimization Plus Service Management is added on the contract

|  20-Jun-2018  Sumanth       ESESP-1129  -   Auto-gen Onboarding Case when Protect and Perform - Premium Plus Security  is added on the contract

|  20-Jun-2018  Sumanth       ESESP-1129  -   Auto-gen Onboarding Case when Protect and Perform - Premium Plus Managed Kona onboarding  is added on the contract

|  20-Jun-2018  Sumanth       ESESP-1129  -   Auto-gen Onboarding Case when Protect and Perform - Managed Kona Plus Service Management  is added on the contract
         
|  20-Sep-2018  Sumanth       ESESP-1356  -   Commenting out code related NES Onboarding

|  25-Apr-2019  Sumanth       ESESP-2046  -   Plus-onboarding cases auto-generation       
         
|  24-May-2019  Vikas       ESESP-2045  -     Advanced-onboarding cases auto-generation 

|  15-May-2020  Vamsee    ESESP-3550  -     Removed Autogen Logic for BOCC Onboarding 
         
  ##### No of Methods - 39 ########                       
                                                       
+=====================================================================================================*/

public class SC_Autogen_RUS_PPSM_QBR_Support{

      // List to store all Cases to be Created
      public static List<Case> caseCreateList = new List<Case>();
      
      // List to store all Qualified Cases for which Task to be Created
      public static List<Case> caseTaskCreateList = new List<Case>();
      
      // List to store all Tasks to be Created
      public static List<Task> taskCreateList = new List<Task>();
      
      // List to store all Contract Id for which Task to be Created
      public static set<Id> contractIdTaskCreateList = new set<Id>();
      
      // Get the DGRAT value from Custom setting
      public static SC_DGRAT_Reorg_Mapping__c DGRATMapping =  SC_DGRAT_Reorg_Mapping__c.getInstance();  
  
      // List to Update all NES, Contract Lines
       public static Map<Id,Autogen_Contract_Header_Detail__c> allContractLnsUpdateMap = new Map<Id,Autogen_Contract_Header_Detail__c>();
        
      // Fetching Assignment Rule
      public AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
      
      // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
      public Id setDetailRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
      
      // Fetching Business Hour
      public BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Service Business Hours - 24x5'];
      
      // Fetch Default Task Owner from Custom Setting - SC_SupportEmail__c
      string getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
    
      //Map to store RRS contracts and case description
      Map<Id,String> contractID_CaseDesc_RRSMap = new Map<Id,String>();
        
      // Fetch User Id from User Alias
      public User userRec = [select Id from user where alias = :getOwnerAlias limit 1];
      
      // Map to store Autogen Use Case - Complete Record(SC_AutogenJob__c)
      Map<string,SC_AutogenJob__c> autogenUseCase_FullRec = new Map<string,SC_AutogenJob__c>();
    
      //Map to store the Account PS Product - Corresponding Case Product Value
      Map<String, Id> accountPSProduct_CaseProductMap = new Map<String, Id>();
      
      /*...........Variables for New Contract Process Change   */
      
      // 1. Map to store ContractDetail ID - IS_COB_Created (For All)
      public static Map<Id,Autogen_Contract_Header_Detail__c> contractDetailId_COBCreatedMap_ACHD = new Map<Id,Autogen_Contract_Header_Detail__c>();
      
      // 2. Map to store ContractHeader ID - IS_COB_Created (For KONA-COB)
      public static Map<Id,boolean> contractHeaderId_KONACOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 3. Map to store ContractHeader ID - IS_COB_Created (For KDD)
      public static Map<Id,boolean> contractHeaderId_KDDCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 4. Map to store ContractHeader ID - IS_COB_Created (For SMP Security Products)
      public static Map<Id,boolean> contractHeaderId_SMP_SEC_COBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 5. Map to store ContractHeader ID - IS_COB_Created (For SMP Non Security Products)
      public static Map<Id,boolean> contractHeaderId_SMP_NONSEC_COBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 6. Map to store ContractHeader ID - IS_COB_Created (For GDS)
      public static Map<Id,boolean> contractHeaderId_GDSCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 7. Map to store ContractHeader ID - IS_COB_Created (For MDS)
      public static Map<Id,boolean> contractHeaderId_MDSCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 8. Map to store ContractHeader ID - IS_COB_Created (For KSD)
      public static Map<Id,boolean> contractHeaderId_KSDCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 9. Map to store ContractHeader ID - IS_COB_Created (For SOA Main Product)
      public static Map<Id,boolean> contractHeaderId_SOAMainProdCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 10. Map to store ContractHeader ID - IS_COB_Created (For SOA Prolexic Product)
      public static Map<Id,boolean> contractHeaderId_SOAProlexicCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 11. Map to store ContractHeader ID - IS_COB_Created (For SOA BotManager Product)
      public static Map<Id,boolean> contractHeaderId_SOABotManagerCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 12. Map to store ContractHeader ID - IS_COB_Created (For SOA WebAppFirewall Product)
      public static Map<Id,boolean> contractHeaderId_SOAWebAppFirewallCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 13. Map to store ContractHeader ID - IS_COB_Created (For SOA KSD Product)
      public static Map<Id,boolean> contractHeaderId_SOAKSDCOBCreatedMap_ACHD = new Map<Id,boolean>();
    
      //CR:3597711 14. Map to store ContractHeader ID - IS_COB_Created (For SOA Web Application Protector)
      public static Map<Id,boolean> contractHeaderId_SOAWebAppProtectorCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 15. Map to store Contract Header ID - SOA Main Product CL (For SOA Use Case)
      public static Map<Id,Merge_Contract_Detail__c> contractHeaderId_SOAMainProdCL = new Map<Id,Merge_Contract_Detail__c>();
      
      // 16. Map to store ContractHeader ID - Case Desc (For Update of SOA Main Product)
      public static Map<Id,string> contractHeaderId_SOAMainCaseUpdateMap = new Map<Id,string>();
      
      // PSE
      // 18. Map to store ContractHeader ID - IS_COB_Created (For Professional Services - Enterprise)
      public static Map<Id,boolean> contractHeaderId_PSECOBCreatedMap_ACHD = new Map<Id,boolean>();

      //TAS
      // 19. Map to store ContractHeader ID - IS_COB_Created (For Technical Advisory Service)
      public static Map<Id,boolean> contractHeaderId_TASCOBCreatedMap_ACHD = new Map<Id,boolean>();

      // PLX-Connect
      // 20. Map to store ContractHeader ID - IS_COB_Created (For PLX-Connect)
      public static Map<Id,boolean> contractHeaderId_PLXCCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // PLX-Routed
      // 21. Map to store ContractHeader ID - IS_COB_Created (For PLX-Routed)
      public static Map<Id,boolean> contractHeaderId_PLXRCOBCreatedMap_ACHD = new Map<Id,boolean>();

      // PS-S
      // 22. Map to store ContractHeader ID - IS_COB_Created (For Professional Services - Security)
      public static Map<Id,boolean> contractHeaderId_PSSCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      //Protect and Perform::Security Optimization Plus Service Management 
      // 23. Map to store ContractHeader ID - IS_COB_Created (Protect and Perform::Security Optimization Plus Service Management )
      public static Map<Id,boolean> contractHeaderId_PPSOPSMCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      //Protect and Perform - Premium Plus Security 
      // 24. Map to store ContractHeader ID - IS_COB_Created (Protect and Perform - Premium Plus Security )
      public static Map<Id,boolean> contractHeaderId_PPPPSCCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      //Protect and Perform - Premium Plus Managed Kona 
      // 25. Map to store ContractHeader ID - IS_COB_Created (Protect and Perform - Premium Plus Managed Kona )
      public static Map<Id,boolean> contractHeaderId_PPPPMKCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      //Protect and Perform - Managed Kona Plus Service Management 
      // 26. Map to store ContractHeader ID - IS_COB_Created (Protect and Perform - Managed Kona Plus Service Management)
      public static Map<Id,boolean> contractHeaderId_PPMKPSMCOBCreatedMap_ACHD = new Map<Id,boolean>();
      
      // 27. Map to Store On Boarded CLI details for Plus - ESESP-2046 - Stores CLI Id and corresponding value of IS_COB_CLI
      //public static Map<Id,boolean> OnboardedCLIPlus = new Map<Id,boolean>();
    
      // 28. Map to Store On Boarded CLI details for Advanced - ESESP-2045 - Stores CLI Id and corresponding value of IS_COB_CLI
      /*
      public static Map<Id,boolean> OnboardedCLIAdvanced = new Map<Id,boolean>();
      public static List<Case> advancedCaseCreateList = new List<Case>();
      Map<String,List<Case>> parentContractDetailCaseMap = new Map<String,List<Case>>();
      */
      
      
      
      // 29. Map to Store On Boarded CLI details for Advanced - ESESP-2045 - Stores CLI Id and corresponding value of IS_COB_CLI
      // public static Map<Id,boolean> OnboardedCLIPMO = new Map<Id,boolean>();
       
      
      /*...........End of Variables for New Contract Process Change   */
      
      // Constructor
      public SC_Autogen_RUS_PPSM_QBR_Support(){

        // Query on SC_AutogenJob__c object
        for(SC_AutogenJob__c eachAutogenJob : [select Id,Autogen_UseCase_Name__c,Active__c,Additional_Calculation_1__c,
                       Additional_Calculation_2__c,Case_Owner__c,Case_Record_Type__c,
                       Description__c,Do_not_Show_in_Portal__c,Initial_Frequency__c,
                       IS_Case_Routing_Required__c,Origin__c,Product__c,PS_Product__c,
                       Recurring_Frequency__c,Request_Sub_Type__c,Request_Type__c,Service__c,
                       Severity__c,Subject__c,Subsequent_Frequency_in_Days__c,
                       Subsequent_Frequency_in_Months__c,Use_Case_Implementation_Date__c,IsTaskTobeCreated__c,
                       Sub_Type__c,Service_Category__c,visibility__c  
                    //   from SC_AutogenJob__c where Active__c = True]){
                    from SC_AutogenJob__c]){
          
          autogenUseCase_FullRec.put(eachAutogenJob.Autogen_UseCase_Name__c, eachAutogenJob);            
        }
      }
            
      // Method - 1: Main method for RUS,PPSM and QBR Calculation
      // Called from - SC_Autogen_RUS_PPSM_QBR_Batch Class
      public void main_RUS_PPSM_QBR_Method(List<Merge_Contract_Header__c> allReturnContracts){
      
      system.debug('allReturnContracts'+allReturnContracts);
      
      //for debugging 2046
      for(Merge_Contract_Header__c C: allReturnContracts )
      {
      
           system.debug('Contract header Name '+ C.Id);
      }
           
      
        
            // Set to store RUS Product Id values
            Set<String> allRUSProd = new Set<String>();
            
            // Set to store PPSM Product Id values
            Set<String> allPPSMProd = new Set<String>();
            
            // Set to store QBR Product Id values
            Set<String> allQBRProd = new Set<String>();
            
            // Set to store SMP Product Id values
            Set<String> allSMPProd = new Set<String>();
            
            // Set to store NES Product Id values
            //ESESP-1356 Set<String> allNESProd = new Set<String>();
            
            // Set to store KONA Product Id values
           // Set<String> allKONAProd = new Set<String>(); -- Removed as part of CR 3283891
            
            // Set to store KONA-COB Product Id values
            Set<String> allKONA_COB_Prod = new Set<String>();
            
            // Set to store KDD-COB Product Id values
            Set<String> allKDD_COB_Prod = new Set<String>();
            
            // Set to store GDS Product Id values
            Set<String> allGDS_Prod = new Set<String>();
            
            // Set to store MDS Product Id values
            Set<String> allMDS_Prod = new Set<String>();
            
            // Set to store KSD Product Id values
            Set<String> allKSD_Prod = new Set<String>();
            
            // Set to store SOA Main Product Id values
            Set<String> all_SOA_Main_Prod = new Set<String>();
            
            // Set to store SOA Prolexic Product Id values
            Set<String> all_SOA_Prolexic_Prod = new Set<String>();
            
            // Set to store SOA BotManager Product Id values
            Set<String> all_SOA_BotManager_Prod = new Set<String>();
            
            // Set to store SOA WebAppFirewall Product Id values
            Set<String> all_SOA_WebAppFirewall_Prod = new Set<String>();
            
            // Set to store SOA KSD Product Id values
            Set<String> all_SOA_KSD_Prod = new Set<String>();
            
            //CR:3597711 Set to store SOA Web Application Protector Product Id values
            Set<String> all_SOA_WebAppProtector_Prod = new Set<String>();
          
            // PSE
            // Set to store PS - Enterprise Id values
            Set<String> all_PSE_Prod = new Set<String>();

            // TAS
            // Set to store TAS Id values
            Set<String> all_TAS_Prod = new Set<String>();    

            // PLX Connect
            // Set to store PLX-Connect Id values
            Set<String> all_PLXC_Prod = new Set<String>();

            // Set to store PLX-Routed Id values
            Set<String> all_PLXR_Prod = new Set<String>();

            // Set to store PS-S Id values
            Set<String> all_PSS_Prod = new Set<String>();
            
            // Set to store PPSOPSM Id values
            Set<String> all_PPSOPSM_Prod = new Set<String>();
            
            // Set to store PPPPSC Id values
            Set<String> all_PPPPSC_Prod = new Set<String>();
            
            // Set to store PPPPMK Id values
            Set<String> all_PPPPMK_Prod = new Set<String>();
            
            // Set to store PPMKPSM Id values
            Set<String> all_PPMKPSM_Prod = new Set<String>();
            
            // Set to store all Plus Product Id Values ESESP-2046
            //Set<String> all_Plus_Prod = new Set<String>();
          
            // Set to store all Advanced Product Id Values ESESP-2045
            // Set<String> all_Advanced_Prod = new Set<String>();
          
            // Set to store all Advanced Product Id Values ESESP-2045
            // Set<String> all_PMO_Prod = new Set<String>();
            
          
            //  Set to store RRS Id values
            Set<String> all_RRS_Prod = new Set<String>();

            // List#1 - To Store all Use Case Products for Active Line Items
            Set<String> allUsecaseProd = new Set<String>();
            
            // List#2 - To Store all Use Case Products for Future Effective Start Date
            Set<String> allUsecaseProdFutureESD = new Set<String>();
            
            // List#3 - To Store all Use Case Products including Active Line Items + Future Effective Start Date
            Set<String> allUsecaseProd_ACHD = new Set<String>();
            
            // boolean for storing Returned Result from AddAll Method
            boolean returnFlag = false;
          
            /****  Adding Values for All Product Lists  ****/
            // 1. For RUS Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('RUS').IsActive__c){
                
                  returnFlag = allRUSProd.addAll(SC_TCR_WAF_ProdList__c.getValues('RUS').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allRUSProd);
            }
          
            // 2. For PPSM Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('PPSM').IsActive__c){
                
                  returnFlag = allPPSMProd.addAll(SC_TCR_WAF_ProdList__c.getValues('PPSM').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allPPSMProd);
            }
          
            // 3. For QBR Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('QBR').IsActive__c){
                
                  returnFlag = allQBRProd.addAll(SC_TCR_WAF_ProdList__c.getValues('QBR').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allQBRProd);
            }
          
            // 4. For SMP Product(SMP COB + SMP RC)
            if(SC_Autogen_Job_Enable_Disable__c.getValues('SMP').IsActive__c){
                
                  returnFlag = allSMPProd.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allSMPProd);
            }
          
            // 5. For NES Product
            /* ESESP 1356 
            if(SC_Autogen_Job_Enable_Disable__c.getValues('NES').IsActive__c){
                
                  returnFlag = allNESProd.addAll(SC_TCR_WAF_ProdList__c.getValues('NES').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allNESProd);
            }
            
            */
           /*  Removed as part of CR 3283891
            // 6. For KONA Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('KONA').IsActive__c){
                
                  returnFlag = allKONAProd.addAll(SC_TCR_WAF_ProdList__c.getValues('KONA').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allKONAProd);
            }*/

            // 7. For KONA-COB Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('KONA-COB').IsActive__c){
                
                  returnFlag = allKONA_COB_Prod.addAll(SC_TCR_WAF_ProdList__c.getValues('KONA-COB').Product_Id__c.split(','));
                  returnFlag = allUsecaseProdFutureESD.addAll(allKONA_COB_Prod);
            }
          
            // 8. For KDD Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('KDD').IsActive__c){
                
                  returnFlag = allKDD_COB_Prod.addAll(SC_TCR_WAF_ProdList__c.getValues('KDD').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allKDD_COB_Prod);
            }
            
            // 9. For GDS Product
            if(autogenUseCase_FullRec.get('GDS-COB').Active__c || autogenUseCase_FullRec.get('GDS-RC').Active__c){
                
                  returnFlag = allGDS_Prod.addAll(SC_TCR_WAF_ProdList__c.getValues('GDS').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allGDS_Prod);
            }
            
            // 10. For MDS Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('MDS').IsActive__c){
                
                  returnFlag = allMDS_Prod.addAll(SC_TCR_WAF_ProdList__c.getValues('MDS').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allMDS_Prod);
            }
            
            // 11. For KSD Product
            if(SC_Autogen_Job_Enable_Disable__c.getValues('KSD').IsActive__c){
                
                  returnFlag = allKSD_Prod.addAll(SC_TCR_WAF_ProdList__c.getValues('KSD').Product_Id__c.split(','));
                  returnFlag = allUsecaseProd.addAll(allKSD_Prod);
            }
            
            // 12. For SOA Parent Product 
            if(autogenUseCase_FullRec.get('SOA-Parent').Active__c){
                
                  returnFlag = all_SOA_Main_Prod.addAll(autogenUseCase_FullRec.get('SOA-Parent').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_SOA_Main_Prod);
            }
            
            // 13. For SOA Prolexic Product 
            if(autogenUseCase_FullRec.get('SOA-Prolexic').Active__c){
                
                  returnFlag = all_SOA_Prolexic_Prod.addAll(autogenUseCase_FullRec.get('SOA-Prolexic').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_SOA_Prolexic_Prod);
            }
            
            // 14. For SOA BotManager Product 
            if(autogenUseCase_FullRec.get('SOA-BotManager').Active__c){
                
                  returnFlag = all_SOA_BotManager_Prod.addAll(autogenUseCase_FullRec.get('SOA-BotManager').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_SOA_BotManager_Prod);
            }
            
            // 15. For SOA WebAppFirewall Product 
            if(autogenUseCase_FullRec.get('SOA-WebAppFirewall').Active__c){
                
                  returnFlag = all_SOA_WebAppFirewall_Prod.addAll(autogenUseCase_FullRec.get('SOA-WebAppFirewall').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_SOA_WebAppFirewall_Prod);
            }
            
            // 16. For SOA KSD Product 
            if(autogenUseCase_FullRec.get('SOA-KSD').Active__c){
                
                  returnFlag = all_SOA_KSD_Prod.addAll(autogenUseCase_FullRec.get('SOA-KSD').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_SOA_KSD_Prod);
            }
            
          //CR:3597711 17. For Web Aplication Protector Product
            if(autogenUseCase_FullRec.get('SOA-WebAppProtector').Active__c){
              
                 returnFlag = all_SOA_WebAppProtector_Prod.addAll(autogenUseCase_FullRec.get('SOA-WebAppProtector').Product__c.split(','));
               returnFlag = allUsecaseProd.addAll(all_SOA_WebAppProtector_Prod);
           }
          
           
            // 19. For PS-Enterprise Product 
            if(autogenUseCase_FullRec.get('PSE-COB').Active__c){
                
                returnFlag = all_PSE_Prod.addAll(autogenUseCase_FullRec.get('PSE-COB').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_PSE_Prod);
            }

            // 20. For TAS Product 
            if(autogenUseCase_FullRec.get('TAS-COB').Active__c){
                
                returnFlag = all_TAS_Prod.addAll(autogenUseCase_FullRec.get('TAS-COB').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_TAS_Prod);
            }

            // 21. For PLX-Connect Product 
            if(autogenUseCase_FullRec.get('PLXC-COB').Active__c){
                
                returnFlag = all_PLXC_Prod.addAll(autogenUseCase_FullRec.get('PLXC-COB').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_PLXC_Prod);
            }
            
            // 22. For PLX-Routed Product 
            if(autogenUseCase_FullRec.get('PLXR-COB').Active__c){
                
                returnFlag = all_PLXR_Prod.addAll(autogenUseCase_FullRec.get('PLXR-COB').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_PLXR_Prod);
            }

            // 23. For PS-S Product 
            if(autogenUseCase_FullRec.get('PSS-COB').Active__c){
                
                returnFlag = all_PSS_Prod.addAll(autogenUseCase_FullRec.get('PSS-COB').Product__c.split(','));
                  returnFlag = allUsecaseProd.addAll(all_PSS_Prod);
            }

            // 24. For RRS Products 
            if(autogenUseCase_FullRec.get('RRS-Parent').Active__c){
                
                returnFlag = all_RRS_Prod.addAll(autogenUseCase_FullRec.get('RRS-Parent').Product__c.split(','));
                if(autogenUseCase_FullRec.get('RRS-WebAppProtector').Active__c){
                   returnFlag = all_RRS_Prod.addAll(autogenUseCase_FullRec.get('RRS-WebAppProtector').Product__c.split(',')); 
                }
                if(autogenUseCase_FullRec.get('RRS-BotManager').Active__c){
                   returnFlag = all_RRS_Prod.addAll(autogenUseCase_FullRec.get('RRS-BotManager').Product__c.split(',')); 
                }
                returnFlag = allUsecaseProd.addAll(all_RRS_Prod);
            }
            
            // 25. For Product Protect and Perform::Security Optimization Plus Service Management
            if(autogenUseCase_FullRec.get('PPSOPSM').Active__c){
                
                  returnFlag = all_PPSOPSM_Prod.addAll(autogenUseCase_FullRec.get('PPSOPSM').Product__c.split(','));
                  system.debug('all_PPSOPSM_Prod'+all_PPSOPSM_Prod);
                  returnFlag = allUsecaseProd.addAll(all_PPSOPSM_Prod);
            }  
            
            // 26. For Protect and Perform - Premium Plus Security Optimization
            if(autogenUseCase_FullRec.get('PPPPSC').Active__c){
                
                  returnFlag = all_PPPPSC_Prod.addAll(autogenUseCase_FullRec.get('PPPPSC').Product__c.split(','));
                  //system.debug('all_PPSOPSM_Prod'+all_PPSOPSM_Prod);
                  returnFlag = allUsecaseProd.addAll(all_PPPPSC_Prod);
            }  
            
            
            // 27. For Protect and Perform - Premium Plus Managed Kona
            if(autogenUseCase_FullRec.get('PPPPMK').Active__c){
                
                  returnFlag = all_PPPPMK_Prod.addAll(autogenUseCase_FullRec.get('PPPPMK').Product__c.split(','));
                  //system.debug('all_PPSOPSM_Prod'+all_PPSOPSM_Prod);
                  returnFlag = allUsecaseProd.addAll(all_PPPPMK_Prod);
            }  
            
            
            // 28. For Protect and Perform - Managed Kona Plus Service Management
            if(autogenUseCase_FullRec.get('PPMKPSM').Active__c){
                
                  returnFlag = all_PPMKPSM_Prod.addAll(autogenUseCase_FullRec.get('PPMKPSM').Product__c.split(','));
                  //system.debug('all_PPSOPSM_Prod'+all_PPSOPSM_Prod);
                  returnFlag = allUsecaseProd.addAll(all_PPMKPSM_Prod);
            }  
            
            /*
            // 29. For Plus Onboarding - ESESP-2046
            if(autogenUseCase_FullRec.get('Plus').Active__c){
                
                  returnFlag = all_Plus_Prod.addAll(autogenUseCase_FullRec.get('Plus').Product__c.split(','));
                  system.debug('ESESP-2046 all_Plus_Prod'+all_Plus_Prod);
                  
                  //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
                  returnFlag = allUsecaseProdFutureESD.addAll(all_Plus_Prod);
            }  
            
            // 30. For Advanced Onboarding - ESESP-2045
            if(autogenUseCase_FullRec.get('Advanced').Active__c){
                
                  returnFlag = all_Advanced_Prod.addAll(autogenUseCase_FullRec.get('Advanced').Product__c.split(','));
                  system.debug('ESESP-2045 all_Advanced_Prod'+all_Advanced_Prod);
                  
                  //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
                  returnFlag = allUsecaseProdFutureESD.addAll(all_Advanced_Prod);
            } 
          
            // 31. For PM Onboarding - ESESP-2045
            if(autogenUseCase_FullRec.get('Project Management Option').Active__c){
                
                  returnFlag = all_PMO_Prod.addAll(autogenUseCase_FullRec.get('Project Management Option').Product__c.split(','));
                  system.debug('ESESP-2045 all_PMO_Prod'+all_PMO_Prod);
                  
                  //Adding in allUsecaseProdFutureESD since we need to consider CLI future start date too
                  returnFlag = allUsecaseProdFutureESD.addAll(all_PMO_Prod);
            } 
            */
          
            // Setting Values for - allUsecaseProd_ACHD set
            returnFlag = allUsecaseProd_ACHD.addAll(allUsecaseProd);
            system.debug('allUsecaseProd_ACHD'+allUsecaseProd_ACHD);
            
            returnFlag = allUsecaseProd_ACHD.addAll(allUsecaseProdFutureESD);
            system.debug('allUsecaseProd'+allUsecaseProd);
          
          
          // List to store all RUS Contracts
         List<Merge_Contract_Detail__c> contractLineList_RUS = new List<Merge_Contract_Detail__c>();
        
        // List to store all PPSM Contracts
        List<Merge_Contract_Detail__c> contractLineList_PPSM = new List<Merge_Contract_Detail__c>(); 
    
        // List to store all QBR Contracts
        List<Merge_Contract_Detail__c> contractLineList_QBR = new List<Merge_Contract_Detail__c>(); 
    
        // List to store all SMP Contracts
        List<Merge_Contract_Detail__c> contractLineList_SMP = new List<Merge_Contract_Detail__c>(); 
    
        // List to store all NES Contracts
       //ESESP-1356  List<Merge_Contract_Detail__c> contractLineList_NES = new List<Merge_Contract_Detail__c>(); 
    
        // List to store all KONA Contracts
        //List<Merge_Contract_Detail__c> contractLineList_KONA = new List<Merge_Contract_Detail__c>(); --Removed as part of CR 3283891
    
        // List to store all KONA On Boarding Contracts
        List<Merge_Contract_Detail__c> contractLineList_KONA_COB = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all KONA On Boarding Contracts
        List<Merge_Contract_Detail__c> contractLineList_KDD_COB = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all GDS Contracts
        List<Merge_Contract_Detail__c> contractLineList_GDS = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all MDS Contracts
        List<Merge_Contract_Detail__c> contractLineList_MDS = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all KSD Contracts
        List<Merge_Contract_Detail__c> contractLineList_KSD = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all SOA Parent Contracts
        List<Merge_Contract_Detail__c> contractLineList_SOA_Parent = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all SOA Prolexic Contracts
        List<Merge_Contract_Detail__c> contractLineList_SOA_Prolexic = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all SOA BotManager Contracts
        List<Merge_Contract_Detail__c> contractLineList_SOA_BotManager = new List<Merge_Contract_Detail__c>(); 
    
        // List to store all SOA WebAppFirewall Contracts
        List<Merge_Contract_Detail__c> contractLineList_SOA_WebAppFirewall = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all SOA KSD Contracts
        List<Merge_Contract_Detail__c> contractLineList_SOA_KSD = new List<Merge_Contract_Detail__c>(); 
          
        //CR:3597711 - List to store all SOA Web Application Protector Contracts 
        List<Merge_Contract_Detail__c> contractLineList_SOA_WebAppProtector = new List<Merge_Contract_Detail__c>();
        
        // List to store all PSE Contracts
        List<Merge_Contract_Detail__c> contractLineList_PSE = new List<Merge_Contract_Detail__c>();

        // List to store all TAS Contracts
        List<Merge_Contract_Detail__c> contractLineList_TAS = new List<Merge_Contract_Detail__c>();  

        // List to store all PLX-Connect Contracts
        List<Merge_Contract_Detail__c> contractLineList_PLXC = new List<Merge_Contract_Detail__c>();  

        // List to store all PLX-Routed Contracts
        List<Merge_Contract_Detail__c> contractLineList_PLXR = new List<Merge_Contract_Detail__c>();

        // List to store all PS-S Contracts
        List<Merge_Contract_Detail__c> contractLineList_PSS = new List<Merge_Contract_Detail__c>();
          
        // List to store all RRS Contracts
        List<Merge_Contract_Detail__c> contractLineList_RRS =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Protect and Perform::Security Optimization Plus Service Management contracts
        List<Merge_Contract_Detail__c> contractLineList_PPSOPSM =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Protect and Perform - Premium Plus Security Optimization  contracts
        List<Merge_Contract_Detail__c> contractLineList_PPPPSC =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Protect and Perform - Premium Plus Managed Kona contracts
        List<Merge_Contract_Detail__c> contractLineList_PPPPMK =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Protect and Perform - Managed Kona Plus Service Management contracts
        List<Merge_Contract_Detail__c> contractLineList_PPMKPSM =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Plus contract Line Items ESESP-2046
        //List<Merge_Contract_Detail__c> contractLineList_Plus =  new List<Merge_Contract_Detail__c>();
        
        //List to store all Advanced contract Line Items ESESP-2045
        //List<Merge_Contract_Detail__c> contractLineList_Advanced =  new List<Merge_Contract_Detail__c>();
          
        //List to store all Advanced contract Line Items ESESP-2045
        //List<Merge_Contract_Detail__c> contractLineList_PMO =  new List<Merge_Contract_Detail__c>();
        
        // List to store all Contracts - For all Use Cases(For Active Contract Lines) 
        List<Merge_Contract_Detail__c> contractLineList_ALL = new List<Merge_Contract_Detail__c>(); 
        
        // List to store all Contracts - For all Use Cases (For Future Contract Lines)
        List<Merge_Contract_Detail__c> contractLineList_ALL_Future = new List<Merge_Contract_Detail__c>();
      
        
        /*...........Variables for New Contract Process Change   */
        
        // 1. List to store all Contracts - For all Use Cases from Autogen_Contract_Header_Detail__c Object
        List<Autogen_Contract_Header_Detail__c> contractLineList_ACHD = new List<Autogen_Contract_Header_Detail__c>();
        
        
            // Query# 1 -  To fetch all Contract Line Items - For All Use Cases(For Active Contract Lines)
            if(allUsecaseProd.size() > 0){
        
                system.debug('Entering inside query 1');
                contractLineList_ALL = [Select id,Effective_Start_Date__c,Original_Contract_Id__c ,Effective_End_Date__c,
                              Original_Contract_Id__r.Account_Name__r.Name,
                              Original_Contract_Id__r.Account_Name__r.Geography_Formula__c,
                              Original_Contract_Id__r.Account_Name__c,Product__c,Name,Units_Low__c,Units_High__c,
                              Original_Contract_Id__r.Account_Name__r.Support_Level__c,
                              Original_Contract_Id__r.Effective_Start_Date__c,Original_Contract_Id__r.Effective_End_Date__c,
                              Product_Id__c,Unit_of_Measure__c,createdDate,AKAM_Created_Date__c
                        from Merge_Contract_Detail__c
                        where Original_Contract_Id__c In :allReturnContracts and
                          Effective_Start_Date__c <= Today and
                          Effective_End_Date__c >= Today and
                          Effective_Start_Date__c <> null and
                          Effective_End_Date__c <> null and
                          Product_Id__c in :allUsecaseProd
                        order by createdDate asc
                            ];
            }
            
          
          
           system.debug('contractLineList_ALL'+contractLineList_ALL);
            // Query# 2 -  To fetch all Contract Line Items - (For Future Contract Lines)
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
            
            system.debug('contractLineList_ALL_Future'+contractLineList_ALL_Future);
            //for debugging 2046
      for(Merge_Contract_Detail__c C: contractLineList_ALL_Future )
      {
      
           system.debug('Contract Detail Name '+ C.Id);
           
           
      
      }
            
            // Query# 3 -  To fetch all Contract Line Items from Newly Changed Tracking Object - Autogen_Contract_Header_Detail__c
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
          
            
            
          
          
            // Loop for each Line Item with the Product ID (For Active Contract Lines) - For Query#1
            for(Merge_Contract_Detail__c eachLineRec : contractLineList_ALL){
          
      // Setting RUS Contract List
      if(allRUSProd.contains(eachLineRec.Product_Id__c)){
    
          if(eachLineRec.Units_Low__c <> null && eachLineRec.Units_Low__c <> 0 && eachLineRec.Unit_of_Measure__c == 'Reviews')
              contractLineList_RUS.add(eachLineRec);
      }
    
      // Setting PPSM Contract List
      if(allPPSMProd.contains(eachLineRec.Product_Id__c)){
    
        contractLineList_PPSM.add(eachLineRec);
      }
            
      // Setting QBR Contract List
      if(allQBRProd.contains(eachLineRec.Product_Id__c)){
    
        contractLineList_QBR.add(eachLineRec);
      }
    
      // Setting SMP Contract List
      if(allSMPProd.contains(eachLineRec.Product_Id__c)){
    
        contractLineList_SMP.add(eachLineRec);
      }
    
      // Setting NES Contract List
      /* ESESP-1356
      if(allNESProd.contains(eachLineRec.Product_Id__c)){
    
        contractLineList_NES.add(eachLineRec);
      }
      
      */
    
      /* Removed as part of CR 3283891
      // Setting KONA Contract List
      if(allKONAProd.contains(eachLineRec.Product_Id__c)){
    
        //Adding to KONA Recurring List
        if(eachLineRec.Units_High__c <> null && eachLineRec.Units_High__c <> 0)
          contractLineList_KONA.add(eachLineRec);
          
      }*/
      
      // Setting KDD Contract List
      if(allKDD_COB_Prod.contains(eachLineRec.Product_Id__c)){
    
        contractLineList_KDD_COB.add(eachLineRec);
          
      }
      
      // Setting GDS Contract List
      if(allGDS_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_GDS.add(eachLineRec);
        
      }
      
      // Setting MDS Contract List
      if(allMDS_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_MDS.add(eachLineRec);
        
      }
      
      // Setting KSD Contract List
      if(allKSD_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_KSD.add(eachLineRec);
        
      }
      
      // Setting SOA-Parent Contract List
      if(all_SOA_Main_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_SOA_Parent.add(eachLineRec);
        contractHeaderId_SOAMainProdCL.put(eachLineRec.Original_Contract_Id__c , eachLineRec);
        
      }
      
      // Setting SOA-Prolexic Contract List
      if(all_SOA_Prolexic_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_SOA_Prolexic.add(eachLineRec);
        
      }
      
      // Setting SOA-BotManager Contract List
      if(all_SOA_BotManager_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_SOA_BotManager.add(eachLineRec);
        
      }
      
      // Setting SOA-WebAppFirewall Contract List
      if(all_SOA_WebAppFirewall_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_SOA_WebAppFirewall.add(eachLineRec);
        
      }
      
      // Setting SOA-KSD Contract List
      if(all_SOA_KSD_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_SOA_KSD.add(eachLineRec);
        
      }
      
      //CR:3597711 Setting SOA-Web Application Protector Contract List
      if(all_SOA_WebAppProtector_Prod.contains(eachLineRec.Product_Id__c)){
       
          contractLineList_SOA_WebAppProtector.add(eachLineRec);
      }           
                
      

      // Setting PSE Contract List
      if(all_PSE_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_PSE.add(eachLineRec);
        
      }

      // Setting TAS Contract List
      if(all_TAS_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_TAS.add(eachLineRec);
        
      }

      // Setting PLX-Connect Contract List
      if(all_PLXC_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_PLXC.add(eachLineRec);
        
      }

      // Setting PLX-Routed Contract List
      if(all_PLXR_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_PLXR.add(eachLineRec);
        
      }

      // Setting PS-S Contract List
      if(all_PSS_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_PSS.add(eachLineRec);
        
      }
                
      //Setting RRS Contract List
      if(all_RRS_Prod.contains(eachLineRec.Product_Id__c)){
  
        contractLineList_RRS.add(eachLineRec);
        
      }
      
      //Setting for PPSOPSM Contract List
      if(all_PPSOPSM_Prod.contains(eachLineRec.Product_Id__c)){
      
         //system.debug('Entering here in if');
  
        contractLineList_PPSOPSM.add(eachLineRec);
        
      }
      
       //Setting for PPPPSC Contract List
      if(all_PPPPSC_Prod.contains(eachLineRec.Product_Id__c)){
      
         //system.debug('Entering here in if');
  
        contractLineList_PPPPSC.add(eachLineRec);
        
      }
      
       //Setting for PPPPMK Contract List
      if(all_PPPPMK_Prod.contains(eachLineRec.Product_Id__c)){
      
         //system.debug('Entering here in if');
  
        contractLineList_PPPPMK.add(eachLineRec);
        
      }
      
       //Setting for PPMKPSM Contract List
      if(all_PPMKPSM_Prod.contains(eachLineRec.Product_Id__c)){
      
         //system.debug('Entering here in if');
  
        contractLineList_PPMKPSM.add(eachLineRec);
        
      }
      
      
      
      
    
    }
    
    
    
    // Loop for each Line Item with the Product ID (For Future Contract Lines) - For Query#2
            for(Merge_Contract_Detail__c eachLineRec : contractLineList_ALL_Future){
            
              // Setting KONA COB Contract List
              if(allKONA_COB_Prod.contains(eachLineRec.Product_Id__c) ){
      
                   contractLineList_KONA_COB.add(eachLineRec);
                } 
                
                /*
                
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
                    if(eachLineRec.Unit_of_Measure__c == 'Unit')
                    {
                        contractLineList_PMO.add(eachLineRec);
                    }
                } 
                */
            }
            
          
            
            // Loop for each Line Item with the Product ID in  Autogen_Contract_Header_Detail__c Object- For Query#3
            for(Autogen_Contract_Header_Detail__c eachACHDRec : contractLineList_ACHD){
            
                    // Adding Record to Map 
                contractDetailId_COBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Detail__c, eachACHDRec);
    
      
        // 1. Setting KONA-COB Map
        if(allKONA_COB_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_KONACOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
      
        // 2. Setting KDD-COB Map
        if(allKDD_COB_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_KDDCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
      
        // 3. Setting SMP-COB_Sec Map
        Set<String> SMPSecurityProdList = new Set<String>();
        returnFlag = SMPSecurityProdList.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP-Security').Product_Id__c.split(','));
        if(SMPSecurityProdList.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SMP_SEC_COBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
      
        // 4. Setting SMP-COB_NonSec Map
        Set<String> SMPNonSecurityProdList = new Set<String>();
        returnFlag = SMPNonSecurityProdList.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP-NonSecurity').Product_Id__c.split(','));
        if(SMPNonSecurityProdList.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SMP_NONSEC_COBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 5. Setting GDS Map
        if(allGDS_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_GDSCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 6. Setting MDS Map
        if(allMDS_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_MDSCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // Setting KSD Map
        if(allKSD_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_KSDCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 7. Setting SOA Main Product Map
        if(all_SOA_Main_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SOAMainProdCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 8. Setting SOA Prolexic Product Map
        if(all_SOA_Prolexic_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SOAProlexicCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 9. Setting SOA BotManager Product Map
        if(all_SOA_BotManager_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SOABotManagerCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 10. Setting SOA WebAppFirewall Product Map
        if(all_SOA_WebAppFirewall_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SOAWebAppFirewallCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 11. Setting SOA KSD Product Map
        if(all_SOA_KSD_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_SOAKSDCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        //CR:3597711 12. Setting SOA Web Application Protector Product Map
        if(all_SOA_WebAppProtector_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
            
            contractHeaderId_SOAWebAppProtectorCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
                
        

        // 14. Setting PSE Product Map
        if(all_PSE_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PSECOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }

        // 15. Setting TAS Product Map
        if(all_TAS_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_TASCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }

        // 16. Setting PLX-Connect Product Map
        if(all_PLXC_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PLXCCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        // 17. Setting PLX-Routed Product Map
        if(all_PLXR_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PLXRCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }

        // 18. Setting PS-S Product Map
        if(all_PSS_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PSSCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        //19. Setting Protect and Perform::Security Optimization Plus Service Management product map
        if(all_PPSOPSM_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PPSOPSMCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        //20. Setting Protect and Perform - Premium Plus Security Optimization product map
        if(all_PPPPSC_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PPPPSCCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        //21. Setting Protect and Perform - Premium Plus Managed Kona  product map
        if(all_PPPPMK_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PPPPMKCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        //22. Setting Protect and Perform - Managed Kona Plus Service Management product map
        if(all_PPMKPSM_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.Is_COB_Created__c == true){
      
          contractHeaderId_PPMKPSMCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
        }
        
        /*
        //23. Plus check to see if CLI is already onboarded ESESP-2046
        if(all_Plus_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
      
          //contractHeaderId_PPMKPSMCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
          //Collect ACHD that are onboarded
          System.debug('Collecting Onboarded CLIs for Plus');
          OnboardedCLIPlus.put(eachACHDRec.Parent_Contract_Detail__c, true);
          
        }
        
        //24. Advanced check to see if CLI is already onboarded ESESP-2045
        if(all_Advanced_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                    
           //contractHeaderId_PPMKPSMCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
           //Collect ACHD that are onboarded
           System.debug('Collecting Onboarded CLIs for Advanced');
           OnboardedCLIAdvanced.put(eachACHDRec.Parent_Contract_Detail__c, true);
                    
        }
        
        //25. PMO check to see if CLI is already onboarded ESESP-2045
        if(all_PMO_Prod.contains(eachACHDRec.Product__c) && eachACHDRec.IS_CLI_Onboarded__c == true){
                    
           //contractHeaderId_PPMKPSMCOBCreatedMap_ACHD.put(eachACHDRec.Parent_Contract_Header__c, true);
           //Collect ACHD that are onboarded
           System.debug('Collecting Onboarded CLIs for PMO');
           OnboardedCLIPMO.put(eachACHDRec.Parent_Contract_Detail__c, true);
                    
        }
        */
      
            
            }
            
            //system.debug('contractHeaderId_PPSOPSMCOBCreatedMap_ACHD'+contractHeaderId_PPSOPSMCOBCreatedMap_ACHD);
            
          
        // deallocate Memory for Product Variables
        allRUSProd.clear();
        allPPSMProd.clear();
        allQBRProd.clear();
        //ESESP-1356 allNESProd.clear();
        allSMPProd.clear();
        //allKONAProd.clear();  Removed as part of CR 3283891
        allKDD_COB_Prod.clear();
        allGDS_Prod.clear();
        allMDS_Prod.clear();
        allKSD_Prod.clear();
        all_SOA_Main_Prod.clear();
        all_SOA_Prolexic_Prod.clear();
        all_SOA_BotManager_Prod.clear();
        all_SOA_WebAppFirewall_Prod.clear();
        all_SOA_KSD_Prod.clear();
        all_SOA_WebAppProtector_Prod.clear();  //CR - 3597711
        all_PSE_Prod.clear();
        all_TAS_Prod.clear();
        all_PLXC_Prod.clear();
        all_PLXR_Prod.clear();
        all_PSS_Prod.clear();
        all_PPSOPSM_Prod.clear();
        all_PPPPSC_Prod.clear();
        all_PPPPMK_Prod.clear();
        all_PPMKPSM_Prod.clear();
        //all_Plus_Prod.clear();
        //all_Advanced_Prod.clear();
        //all_PMO_Prod.clear();
        allUsecaseProd.clear();
        allUsecaseProd_ACHD.clear();
        contractLineList_ALL.clear();
        contractLineList_ALL_Future.clear();
        contractLineList_ACHD.clear();
          
            // ...........Call to RUS Calculation Method..........
            if(contractLineList_RUS.size() > 0)
                RUS_Calculation(contractLineList_RUS);
            
            // ..........Call to PPSM Calculation Method..........
            if(contractLineList_PPSM.size() > 0)
                PPSM_Calculation(contractLineList_PPSM);
              
            // ..........Call to QBR Calculation Method..........
            if(contractLineList_QBR.size() > 0)
                QBR_Calculation(contractLineList_QBR);
              
            // ..........Call to SMP Calculation Method..........
            if(contractLineList_SMP.size() > 0)
                SMP_Calculation(contractLineList_SMP,'SMP','On-boarding Service Management 2.0 : ');
            
            /*ESESP-1356  
            // ..........Call to NES Calculation Method..........
            if(contractLineList_NES.size() > 0)
                NES_Calculation(contractLineList_NES);
            */
              
          /*
          // ..........Call to KONA Recurring Calculation Method..........
            if(contractLineList_KONA.size() > 0)
                KONA_Calculation(contractLineList_KONA);*/ // Removed as part of CR 3283891
                
            // ..........Call to KONA COB Calculation Method..........
            if(contractLineList_KDD_COB.size() > 0)
                KDD_Calculation_COB(contractLineList_KDD_COB);
                
            // ..........Call to GDS Calculation Method..........
            if(contractLineList_GDS.size() > 0)
                GDS_Calculation(contractLineList_GDS);
                
            // ..........Call to MDS Calculation Method..........
            if(contractLineList_MDS.size() > 0)
                MDS_Calculation(contractLineList_MDS);
                
            // ..........Call to KSD Calculation Method..........
            if(contractLineList_KSD.size() > 0)
                KSD_Calculation(contractLineList_KSD);
             
            // Note : First call all SOA Child Product Calculation. Then call SOA Main Product Calculation    
            // ..........Call to SOA Prolexic Calculation Method..........
            if(contractLineList_SOA_Prolexic.size() > 0)
                SOA_ChildProd_Calculation(contractLineList_SOA_Prolexic,'SOA-Prolexic','- Security Optimization Assistance for Prolexic Routed',contractHeaderId_SOAProlexicCOBCreatedMap_ACHD);
                
            // ..........Call to SOA BotManager Calculation Method..........
            if(contractLineList_SOA_BotManager.size() > 0)
                SOA_ChildProd_Calculation(contractLineList_SOA_BotManager,'SOA-BotManager','- Security Optimization Assistance for Bot Manager',contractHeaderId_SOABotManagerCOBCreatedMap_ACHD);
                
            // ..........Call to SOA WebAppFirewall Calculation Method..........
            if(contractLineList_SOA_WebAppFirewall.size() > 0)
                SOA_ChildProd_Calculation(contractLineList_SOA_WebAppFirewall,'SOA-WebAppFirewall','- Security Optimization Assistance for Web Application Firewall',contractHeaderId_SOAWebAppFirewallCOBCreatedMap_ACHD);
                
            // ..........Call to SOA KSD Calculation Method..........
            if(contractLineList_SOA_KSD.size() > 0)
                SOA_ChildProd_Calculation(contractLineList_SOA_KSD,'SOA-KSD','- Security Optimization Assistance for Kona Site Defender',contractHeaderId_SOAKSDCOBCreatedMap_ACHD);
                
            //CR:3597711 ..........Call to SOA Web Application Protector Calculation Method..........
            if(contractLineList_SOA_WebAppProtector.size() > 0)
                SOA_ChildProd_Calculation(contractLineList_SOA_WebAppProtector,'SOA-WebAppProtector','- Security Optimization Assistance for Web Application Protector', contractHeaderId_SOAWebAppProtectorCOBCreatedMap_ACHD);
          
            // ..........Call to SOA Main Prod Calculation Method..........
            if(contractLineList_SOA_Parent.size() > 0)
                SOA_MainProd_Calculation(contractLineList_SOA_Parent,'SOA-Parent');
                
            // ..........Call to BOCC Calculation Method..........
            
            // ..........Call to BOCC Calculation Method for PSE..........
            if(contractLineList_PSE.size() > 0)
                BOCC_Calculation(contractLineList_PSE,'PSE-COB',contractHeaderId_PSECOBCreatedMap_ACHD);

                // ..........Call to BOCC Calculation Method for TAS..........
            if(contractLineList_TAS.size() > 0)
                BOCC_Calculation(contractLineList_TAS,'TAS-COB',contractHeaderId_TASCOBCreatedMap_ACHD);

                // ..........Call to BOCC Calculation Method for PLX-Connect ..........
            if(contractLineList_PLXC.size() > 0)
                BOCC_Calculation(contractLineList_PLXC,'PLXC-COB',contractHeaderId_PLXCCOBCreatedMap_ACHD);

                // ..........Call to BOCC Calculation Method for PLX-Routed ..........
            if(contractLineList_PLXR.size() > 0)
                BOCC_Calculation(contractLineList_PLXR,'PLXR-COB',contractHeaderId_PLXRCOBCreatedMap_ACHD);

                // ..........Call to BOCC Calculation Method for PS-S ..........
            if(contractLineList_PSS.size() > 0)
                BOCC_Calculation(contractLineList_PSS,'PSS-COB',contractHeaderId_PSSCOBCreatedMap_ACHD);
          
              // ..........Call to RRS Calculation Method..........
            if(contractLineList_RRS.size() > 0)
                RRS_Calculation(contractLineList_RRS);
                
               // ..........Call to ProtectPerform_Calculation Method for Protect and Perform::Security Optimization Plus Service Management ..........
            if(contractLineList_PPSOPSM.size() > 0)
                ProtectPerform_Calculation(contractLineList_PPSOPSM,'PPSOPSM',contractHeaderId_PPSOPSMCOBCreatedMap_ACHD);
                
               // ..........Call to ProtectPerform_Calculation Method for Protect and Perform - Premium Plus Security Optimization ..........
            if(contractLineList_PPPPSC.size() > 0)
                ProtectPerform_Calculation(contractLineList_PPPPSC,'PPPPSC',contractHeaderId_PPPPSCCOBCreatedMap_ACHD);
                
              // ..........Call to ProtectPerform_Calculation Method for Protect and Perform - Premium Plus Managed Kona..........
            if(contractLineList_PPPPMK.size() > 0)
                ProtectPerform_Calculation(contractLineList_PPPPMK,'PPPPMK',contractHeaderId_PPPPMKCOBCreatedMap_ACHD);
                
              // ..........Call to ProtectPerform_Calculation Method for Protect and Perform - Managed Kona Plus Service Management ..........
            if(contractLineList_PPMKPSM.size() > 0)
                ProtectPerform_Calculation(contractLineList_PPMKPSM,'PPMKPSM',contractHeaderId_PPMKPSMCOBCreatedMap_ACHD);
                
              /*  
              //...........Call to PlusCalculation Method for Plus Products ESESP-2046
            if(contractLineList_Plus.size() > 0)
                Plus_Calculation(contractLineList_Plus,'Plus',OnboardedCLIPlus);
          
              //...........Call to PlusCalculation Method for Plus Products ESESP-2046
            if(contractLineList_Advanced.size() > 0)
                Plus_Calculation(contractLineList_Advanced,'Advanced',OnboardedCLIAdvanced);
          
             //...........Call to PlusCalculation Method for Plus Products ESESP-2046
            if(contractLineList_PMO.size() > 0)
                Plus_Calculation(contractLineList_PMO,'Project Management Option',OnboardedCLIPMO);
            */


              
            // deallocate Memory After all Use Case Calculation
            contractLineList_RUS.clear();
            contractLineList_PPSM.clear();
            contractLineList_QBR.clear();
            contractLineList_SMP.clear();
             //ESESP-1356 contractLineList_NES.clear();
            //contractLineList_KONA.clear(); Removed as part of CR 3283891
            
            contractLineList_KDD_COB.clear();
            contractLineList_GDS.clear();
            contractLineList_MDS.clear();
            contractLineList_KSD.clear();
            contractLineList_SOA_Prolexic.clear();
            contractLineList_SOA_BotManager.clear();
            contractLineList_SOA_WebAppFirewall.clear();
            contractLineList_SOA_KSD.clear();
            contractLineList_SOA_WebAppProtector.clear(); //CR:3597711
            contractLineList_SOA_Parent.clear();
            contractLineList_PSE.clear();
            contractLineList_TAS.clear();
            contractLineList_PLXC.clear();
            contractLineList_PLXR.clear();
            contractLineList_PSS.clear();
            contractLineList_PPSOPSM.clear();
            contractLineList_PPPPSC.clear();
            contractLineList_PPPPMK.clear();
            contractLineList_PPMKPSM.clear();
            //contractLineList_Plus.clear();
            //contractLineList_Advanced.clear();
            //contractLineList_PMO.clear();
            
            contractHeaderId_KDDCOBCreatedMap_ACHD.clear();
            contractHeaderId_SMP_SEC_COBCreatedMap_ACHD.clear();
            contractHeaderId_SMP_NONSEC_COBCreatedMap_ACHD.clear();
            contractHeaderId_GDSCOBCreatedMap_ACHD.clear();
            contractHeaderId_MDSCOBCreatedMap_ACHD.clear();
            contractHeaderId_KSDCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOAMainProdCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOAProlexicCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOABotManagerCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOAWebAppFirewallCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOAKSDCOBCreatedMap_ACHD.clear();
            contractHeaderId_SOAWebAppProtectorCOBCreatedMap_ACHD.clear(); //CR:3597711
            contractHeaderId_SOAMainProdCL.clear();
            contractHeaderId_SOAMainCaseUpdateMap.clear();
            contractHeaderId_PSECOBCreatedMap_ACHD.clear();
            contractHeaderId_TASCOBCreatedMap_ACHD.clear();
            contractHeaderId_PLXCCOBCreatedMap_ACHD.clear();
            contractHeaderId_PLXRCOBCreatedMap_ACHD.clear();
            contractHeaderId_PSSCOBCreatedMap_ACHD.clear();
            contractHeaderId_PPSOPSMCOBCreatedMap_ACHD.clear();
            contractHeaderId_PPPPSCCOBCreatedMap_ACHD.clear();
            contractHeaderId_PPPPMKCOBCreatedMap_ACHD.clear();
            contractHeaderId_PPMKPSMCOBCreatedMap_ACHD.clear();
            //OnboardedCLIPlus.clear();
            //OnboardedCLIAdvanced.clear();
            //OnboardedCLIPMO.clear();
            
          system.debug('*****ADVANCED***** caseCreateList : '+caseCreateList);
          system.debug('*****ADVANCED***** caseCreateList size: '+caseCreateList.size());
            // Insert Case - Phase:1 (For All Use Cases)
            if(caseCreateList.size() > 0)
                Upsert caseCreateList Id;
          
          /*
          //Create child cases for Advanced product ESESP-2045
          if(caseCreateList.size() > 0){
              createAdvancedChildCases(caseCreateList);
          }
          */
                
            /*....... Start of 2nd Phase Case Creation(Usecase=KONA-COB) ...........*/
            
              // List to store all the Cases Created from Phase-1 + Phase-2
              List<case> allCaseCreateList = new List<case>();
              
              // Map to store all Contract Id + Case Id for KSD
        Map<Id,Id> allKSDCaseMap = new Map<Id,Id>();
    
      // Adding all the cases created from Phase-1 to final List
      allCaseCreateList.addAll(caseCreateList);
      caseCreateList.clear();
      
       // ..........Call to KONA COB Calculation Method..........
      if(contractLineList_KONA_COB.size() > 0)
        KONA_Calculation_COB(contractLineList_KONA_COB,allKSDCaseMap);
     
      // deallocate Memory
      contractLineList_KONA_COB.clear();
      contractDetailId_COBCreatedMap_ACHD.clear();
      contractHeaderId_KONACOBCreatedMap_ACHD.clear();  
   
      // Insert Case - Phase:2
      if(caseCreateList.size() > 0){
        Insert caseCreateList;
        
              /*....... Start of 3rd Phase Case Update(Usecase=KSD-COB) ...........*/
             
              // Call to UpdateCase Method(Establishing Parent-Child Relationship)  
              updateCaseMethod(caseCreateList, allKSDCaseMap);
              
              // Adding all the cases created from Phase-2 to final List
              allCaseCreateList.addAll(caseCreateList);
             }
            
            /*....... Start of 4th Phase (Task Creation + ACHD object Update) ...........*/
            
              // 1. Update All Contract Lines
              System.debug('!!! All allContractLnsUpdateMap + ' + allContractLnsUpdateMap.values());
              if(allContractLnsUpdateMap.size() > 0)
                Update allContractLnsUpdateMap.values();
              System.debug('!!! All allContractLnsUpdateMap + ' + allContractLnsUpdateMap.values());
              
              // 2. Call to Task Calculation Method 
              TaskCreation_Calculation(allCaseCreateList);
            
              // 3. deallocate Memory
              caseCreateList.clear();
              allContractLnsUpdateMap.clear();
              
            // 4. Insert Task
              if(taskCreateList.size() > 0)
                  Insert taskCreateList;
                
            system.debug('....DML Values = ' + Limits.getQueries());
        
      }
      
      // Method - 2: Method for RUS Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void RUS_Calculation(List<Merge_Contract_Detail__c> contractLineList_RUS){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          
        
            // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
            contractLine_CaseTitleMap = CaseCalculation_RUS(contractLineList_RUS,'RUS');
          
            // deallocate Memory
            contractLineList_RUS.clear();
          
            // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0){
                CreateCase(contractLine_CaseTitleMap,'RUS');
            }
        
            // deallocate Memory
            contractLine_CaseTitleMap.clear();
      }
      
      // Method - 3: Method for PPSM Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void PPSM_Calculation(List<Merge_Contract_Detail__c> contractLineList_PPSM){
      
      // Map to store Contract Line - Case Title 
      Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
    
  
      // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
      contractLine_CaseTitleMap = CaseCalculation_PPSM(contractLineList_PPSM,'PPSM');
    
      // deallocate Memory
      contractLineList_PPSM.clear();
    
      // Phase:2 - Call to Case Creation Method from Phase-1
      if(contractLine_CaseTitleMap.size() > 0){
      CreateCase(contractLine_CaseTitleMap,'PPSM');
      }
  
      // deallocate Memory
      contractLine_CaseTitleMap.clear();
      }
      
      
      // Method - 4: Method for QBR Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void QBR_Calculation(List<Merge_Contract_Detail__c> contractLineList_QBR){
      
          // Map to store Contract Line - Case Title 
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          
        
          // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
          contractLine_CaseTitleMap = CaseCalculation_QBR(contractLineList_QBR,'QBR');
          
          // deallocate Memory
          contractLineList_QBR.clear();
          
          // Phase:2 - Call to Case Creation Method from Phase-1
          if(contractLine_CaseTitleMap.size() > 0){
              CreateCase(contractLine_CaseTitleMap,'QBR');
          }
        
          // deallocate Memory
          contractLine_CaseTitleMap.clear();
      
      }
       
      // Method - 5: Method for SMP Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void SMP_Calculation(List<Merge_Contract_Detail__c> contractLineList_SMP, string useCase, string setCOBSubject){
          
          // Map to store Contract Line - Case Title - For all Contract To Update
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleContractUpdtMap = new Map<Merge_Contract_Detail__c,string>();
          
          for(Merge_Contract_Detail__c eachLine : contractLineList_SMP){
            
              contractLine_CaseTitleContractUpdtMap.put(eachLine,useCase);
          }
          
        
          // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
           CaseCalculation_SMP(contractLineList_SMP,useCase,setCOBSubject);
          
          // deallocate Memory
          contractLineList_SMP.clear();
          
          // Calling Update Contract Lines Method
          updateAllContractLines_ACHD(contractLine_CaseTitleContractUpdtMap);
          
          // deallocate Memory
          contractLine_CaseTitleContractUpdtMap.clear();
      }
      
      
      /* ESESP-1356
      // Method - 6: Method for NES Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      
      public void NES_Calculation(List<Merge_Contract_Detail__c> contractLineList_NES){
      
          // Map to store Contract Line - Case Title 
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          
        
          // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
          contractLine_CaseTitleMap = CaseCalculation_NES(contractLineList_NES,'NES');
          
          // deallocate Memory
          contractLineList_NES.clear();
          
          // Phase:2 - Call to Case Creation Method from Phase-1
          if(contractLine_CaseTitleMap.size() > 0){
              CreateCase(contractLine_CaseTitleMap,'NES');

              updateAllContractLines_ACHD(contractLine_CaseTitleMap);
          }
        
          // deallocate Memory
          contractLine_CaseTitleMap.clear();
      
      }
      
      */
      
      /* Method - 7: Method for KONA Calculation --Removed as part of CR 3283891
      // Called from - main_RUS_PPSM_QBR_Method method
      public void KONA_Calculation(List<Merge_Contract_Detail__c> contractLineList_KONA){
      
            // Map to store Contract Line - Case Title 
        Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          
        
           // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
           contractLine_CaseTitleMap = CaseCalculation_KONA(contractLineList_KONA,'KONA');
           
           // deallocate Memory
           contractLineList_KONA.clear();
           
           // Phase:2 - Call to Case Creation Method from Phase-1
           if(contractLine_CaseTitleMap.size() > 0){
                CreateCase(contractLine_CaseTitleMap,'KONA');
           }
        
          // deallocate Memory
          contractLine_CaseTitleMap.clear();
      }*/
      
      // Method - 8: Method for KONA On Boarding Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void KONA_Calculation_COB(List<Merge_Contract_Detail__c> contractLineList_KONA_COB, Map<Id,Id> allKSDCaseMap ){
          
          // Map for updating all Contract Line Items
            Map<Merge_Contract_Detail__c,string> contractLine_UpdateMap = new Map<Merge_Contract_Detail__c,string>(); 
            
            // Map to store Contract HD ID - Contract Line for KONA COB Use Case
            Map<ID,Merge_Contract_Detail__c> contractHDID_LineItm_Map = new Map<ID,Merge_Contract_Detail__c>();
            
            for(Merge_Contract_Detail__c eachLineItm : contractLineList_KONA_COB){
            
              contractLine_UpdateMap.put(eachLineItm, 'KONA-COB');
              contractHDID_LineItm_Map.put(eachLineItm.Original_Contract_Id__c,eachLineItm);
            }
        
           // Phase:1 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
           CaseCalculation_KONA_COB(contractLineList_KONA_COB, contractHDID_LineItm_Map ,allKSDCaseMap);
           
           // deallocate Memory
           contractLineList_KONA_COB.clear();
           contractHDID_LineItm_Map.clear();
           
           // Call to Update method for making IS Cob Created = true
           updateAllContractLines_ACHD(contractLine_UpdateMap);
        
           // deallocate Memory
           contractLine_UpdateMap.clear();
      }
      
      // Method - 9: Method for KONA On Boarding Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void KDD_Calculation_COB(List<Merge_Contract_Detail__c> contractLineList_KDD_COB){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title - For all Contract To Update
        Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleContractUpdtMap = new Map<Merge_Contract_Detail__c,string>();
    
        for(Merge_Contract_Detail__c eachLine : contractLineList_KDD_COB){
  
      contractLine_CaseTitleContractUpdtMap.put(eachLine,'KDD');
        }
     
        // Call to KDD Calculation Method
        contractLine_CaseTitleMap = CaseCalculation_KDD(contractLineList_KDD_COB,'KDD');
        
        // deallocate Memory
            contractLineList_KDD_COB.clear();
        
        // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0){
                CreateCase(contractLine_CaseTitleMap,'KDD');
            }
            
            // Calling Update Contract Lines Method
          updateAllContractLines_ACHD(contractLine_CaseTitleContractUpdtMap);
          
            // deallocate Memory
            contractLine_CaseTitleMap.clear();
            contractLine_CaseTitleContractUpdtMap.clear();
      }


    
    // Start of changes for CR 3549401 - GDS Recurring Case creation logic
    // 1st case for a valid contract line item should go out on the 75th day from ESD, subsequent cases to go on every 90th day from the 1st case.

    public void GDS_Calculation_Recurring(List<Merge_Contract_Detail__c> contractLineItemList_GDS)
    {
        System.debug('!!! ENTERED GDS Recurring function!!!');
        
        // List to store all CLI with Per Month Unit of Measure
        List<Merge_Contract_Detail__c> validLineItemList = new List<Merge_Contract_Detail__c>();
        
        // List to store all Contract Header IDs with only 1 valid CLI
        Set<Id> validHeaderSet = new Set<Id>();

        // Map of Contract Header and no. of Contract Line Items
        Map<Id, Integer> contractHeaderLineCountMap = new Map<Id,Integer>();
        
        // variable to store no. of CLI per Contract Header for check
        Integer lineItemCount = 0;

        // Map of Contract Header ID with no. of Cases created for each header
        Map<Id,Integer> contractHeaderCaseCountMap = new Map<Id,Integer>();

        // Map of Contract Header with 1 associated CLI
        Map<Id,Merge_Contract_Detail__c> contractHeaderLineItemMap = new Map<Id,Merge_Contract_Detail__c>();

        // Map of COntract Line Item with Next Case Creat Date
        Map<Id,Date> contractLineNextCaseDateMap = new Map<Id,Date>();


        // Map of CLI and Case Subject to create Cases
        Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();

        // get filtered list of CLI with Per Month Unit of Measure
        for(Merge_Contract_Detail__c eachLineItem : contractLineItemList_GDS)
        {
            if(eachLineItem.Unit_of_Measure__c == 'Per Month')
                validLineItemList.add(eachLineItem);
        }    
        System.debug('!!! Valid Line Item : ' + validLineItemList);
        
        // populate map of Contract Header with no. of associated Line Items
        if(validLineItemList.size() > 0)
        {
            for(Merge_Contract_Detail__c eachLineItem : validLineItemList)
            {
                if(contractHeaderLineCountMap.containsKey(eachLineItem.Original_Contract_Id__c))
                {
                    lineItemCount = contractHeaderLineCountMap.get(eachLineItem.Original_Contract_Id__c);
                    contractHeaderLineCountMap.put(eachLineItem.Original_Contract_Id__c, (lineItemCount + 1));
                }
                else
                {
                    contractHeaderLineCountMap.put(eachLineItem.Original_Contract_Id__c, 1);
                }
            }
        
            // filtered list to get only those Contract Headers with 1 valid Line Item
           for(Id contractHeaderId : contractHeaderLineCountMap.keySet())
                {
                    if(contractHeaderLineCountMap.get(contractHeaderId) == 1)
                        validHeaderSet.add(contractHeaderId);
                }
        }
        System.debug('!!! Valid Header Set : ' + validHeaderSet);

        // create Map of Header and single CLI
        for(Merge_Contract_Detail__c eachLineItem : validLineItemList)
        {
            if(validHeaderSet.contains(eachLineItem.Original_Contract_Id__c))
            {
                contractHeaderLineItemMap.put(eachLineItem.Original_Contract_Id__c, eachLineItem);
            }
        }
        System.debug('!!! Header Line Item 1:1 Map : ' + contractHeaderLineItemMap);
        System.debug('Header line item map count ' + contractHeaderLineItemMap.size());
        // Aggregate Result to get no. of GDS RC Cases created for each Contract Header in validHeaderSet
        AggregateResult[] aggregatedQueryResult = [select Contract__c,Count(Id) from Case where Contract__c in :validHeaderSet AND Autogen_UseCase__c = 'GDS-RC' group by Contract__c];

        // populate map of Contract Header with no. of GDS RC cases already created for each Contract Header
        for(AggregateResult eachAggResult : aggregatedQueryResult)
        {
            contractHeaderCaseCountMap.put((Id)eachAggResult.get('Contract__c'), (Integer)eachAggResult.get('expr0'));
        }
    System.debug('!!! Header Case Count Map 1:N Map : ' + contractHeaderCaseCountMap);
        
        
        // Logic to check for RC creation frequency and setting Case subject
        
        // boolean isGDS_RCExist = false;
        Decimal GDSCaseInitialFreq = autogenUseCase_FullRec.get('GDS-RC').Initial_Frequency__c;
        String GDSCaseRecurringFreq = autogenUseCase_FullRec.get('GDS-RC').Recurring_Frequency__c;
        String GDSCaseSubject = autogenUseCase_FullRec.get('GDS-RC').Subject__c;
        Date startDate;
        Integer caseSeqNumber;

        for(Id eachContractHeader : contractHeaderLineItemMap.keySet())
        {
            System.debug('!!!Entered Logic function!');
            System.debug('Line Item : '+ contractHeaderLineItemMap.get(eachContractHeader));
            startDate = contractHeaderLineItemMap.get(eachContractHeader).Effective_Start_Date__c;
            System.debug('Start date : ' + startDate);
            caseSeqNumber = 1 ;

            caseSeqNumber = (contractHeaderCaseCountMap.get(eachContractHeader) == NULL) ? 1 : contractHeaderCaseCountMap.get(eachContractHeader) + 1;

            Integer diffDays = startDate.daysBetween(System.today());
            
            if(diffDays < 75)
                continue;
            else if(diffDays == 75)
            {
                contractLine_CaseTitleMap.put(contractHeaderLineItemMap.get(eachContractHeader), GDSCaseSubject + caseSeqNumber +' :: ');
            }
            else if(diffDays > 75)
            {
                diffDays -= 75;
                Integer days90remainder = Math.mod(diffDays, 90);
                if(days90remainder == 0)
                    contractLine_CaseTitleMap.put(contractHeaderLineItemMap.get(eachContractHeader), GDSCaseSubject + caseSeqNumber +' :: ');
            }
                
            // Adding for Task Creation List
            contractIdTaskCreateList.add(eachContractHeader);
        }

        // Phase:2 - Call to Case Creation Method from Phase-1
        if(contractLine_CaseTitleMap.size() > 0)
        {
            CreateCase(contractLine_CaseTitleMap,'GDS-RC');
        }
    }

      
      // Method - 10: Method for GDS Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void GDS_Calculation(List<Merge_Contract_Detail__c> contractLineList_GDS)
      {
        System.debug('!!! ENTERED GDS Calculation !!!');
        // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
        // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            // Flag to check the GDS recurrence 
            boolean isGDS_RCExist = false;
            
        for(Merge_Contract_Detail__c eachLine : contractLineList_GDS){
  
        contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
        }
        
        /*.........GDS - On Boarding..........*/
        
        // Phase:1 - Call to KDD Calculation Method(Reusing KDD Method for GDS calculation)
        contractLine_CaseTitleMap = CaseCalculation_KDD(contractLineList_GDS,'GDS');
          
        // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0)
            {
                System.debug('!!! ENTERED COB !!!');
                CreateCase(contractLine_CaseTitleMap,'GDS-COB');
                updateAllContractLines_ACHD(contractLine_CaseTitleMap);
            }
            
            /*.........GDS - Recurring..........*/
            // Call to KDD Calculation Method(Reusing KDD Method for GDS calculation)
            contractLine_CaseTitleMap.clear();

            GDS_Calculation_Recurring(contractLineList_GDS);
        
        // Phase:2 - Call to Case Creation Method from Phase-1
            //if(contractLine_CaseTitleMap.size() > 0)
            //{
            //    CreateCase(contractLine_CaseTitleMap,'GDS-RC');
            //}
        
            // deallocate Memory
            contractLineList_GDS.clear();
      }
      
      // Method - 11: Method for MDS Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void MDS_Calculation(List<Merge_Contract_Detail__c> contractLineList_MDS){
      
        // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
        // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            
        for(Merge_Contract_Detail__c eachLine : contractLineList_MDS){
  
        contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
        }
        
        /*.........MDS - On Boarding..........*/
        
        // Phase:1 - Call to KDD Calculation Method(Reusing KDD Method for MDS calculation)
        contractLine_CaseTitleMap = CaseCalculation_KDD(contractLineList_MDS,'MDS');
          
        // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0){
                
                CreateCase(contractLine_CaseTitleMap,'MDS-COB');

                updateAllContractLines_ACHD(contractLine_CaseTitleMap);
            }
        
        // deallocate Memory
            contractLineList_MDS.clear();
        
      }
      
      // Method - 12: Method for KSD Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void KSD_Calculation(List<Merge_Contract_Detail__c> contractLineList_KSD){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
        // List to store all Filtered KSD Line Items
            List<Merge_Contract_Detail__c> contractLineList_KSD_Filtered = new List<Merge_Contract_Detail__c>();
            
            // Fetch KSD Job Start Date from Custom Setting - SC_SupportEmail__c
          Date getKSDStartDate = SC_SupportEmail__c.getValues('1').KSDJobStartDate__c;
      
        for(Merge_Contract_Detail__c eachLine : contractLineList_KSD){
  
        if(Date.ValueOf(eachLine.createdDate) > getKSDStartDate && eachLine.Effective_Start_Date__c > getKSDStartDate)
          contractLineList_KSD_Filtered.add(eachLine);
        }
        
        /*.........KSD - On Boarding..........*/
        
        // Phase:1 - Call to KDD Calculation Method(Reusing KDD Method for KSD calculation)
        if(contractLineList_KSD_Filtered.size() > 0)
            contractLine_CaseTitleMap = CaseCalculation_KDD(contractLineList_KSD_Filtered,'KSD');
          
          // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0){
                
                CreateCase(contractLine_CaseTitleMap,'KSD-COB');

                updateAllContractLines_ACHD(contractLine_CaseTitleMap);
            }
        
          // deallocate Memory
            contractLineList_KSD.clear();
        
      }
      
      // Method - 13: Method for - BOCC Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
        public void BOCC_Calculation(List<Merge_Contract_Detail__c> contractLineList_Incoming, String useCase, Map<Id,boolean> contractHeaderId_COBCreatedMap_ACHD)
        {
            
            System.debug('Entered BOCC Calc');

            // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
            // List to store all Filtered Line Items
            List<Merge_Contract_Detail__c> contractLineList_Filtered = new List<Merge_Contract_Detail__c>();
            
            // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            // Fetch the Use Case Implementation Date
            Date getImplementationDate = autogenUseCase_FullRec.get(useCase).Use_Case_Implementation_Date__c;
        
            // Getting Case Subject value from SC Autogen Job
            String getSubject =  autogenUseCase_FullRec.get(useCase).Subject__c;
            
            Set<id> accountIdSet = new Set<id>();
        
            // Getting task creation value
            boolean IsTaskTobeCreated = autogenUseCase_FullRec.get(useCase).IsTaskTobeCreated__c;
        
            System.debug('!!!$$$ LINE ITEM LIST' + contractLineList_Incoming);
          
            for(Merge_Contract_Detail__c eachLine : contractLineList_Incoming)
            {
                System.debug('LINE ITEM ' + eachLine);
                
               
                
                    // commenting out old logic for case creation, introducing 48 hour window for Effective start date
                    // new logic - CreatedDate <= Today && ESD in last 48 hours
                    
                    //eachLine.Effective_Start_Date__c == system.today() && 
                    /*
                      (eachLine.Effective_Start_Date__c >= getImplementationDate && Date.ValueOf(eachLine.createdDate) >= getImplementationDate) 
                      ||
                      (eachLine.Effective_Start_Date__c <= getImplementationDate && Date.ValueOf(eachLine.createdDate) >= getImplementationDate) 
                      ||
                      (eachLine.Effective_Start_Date__c >=  getImplementationDate && Date.ValueOf(eachLine.createdDate) <= getImplementationDate)
                    */

                    // updating logic to ESD starting in the last 33 days

                    if (
                          eachLine.CreatedDate.date() <= System.today() 
                            && System.today().addDays(-33) <= eachLine.Effective_Start_Date__c
                            && eachLine.Effective_Start_Date__c <= System.today()
                        )
                    {
                        System.debug('Entry criteria pass' + eachLine.Product__c);
                        contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
                    }
                }
        
            /*.........On Boarding..........*/
            
            // Phase-1 : Checking if already On Boarding Case exist or not
            for(Id eachHeaderId : contractHdId_ContractDetMap.keyset())
            {
                
                if(contractHeaderId_COBCreatedMap_ACHD.get(eachHeaderId) == null)
                {
                    // Add to Map for case creation
                    contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), getSubject + ' ');
                    
                    //Changes by Vamsee - ESESP-5667 Populate Case Product
                    if(useCase == 'PLXR-COB' || useCase == 'PLXC-COB'){
                        accountIdSet.add(contractHdId_ContractDetMap.get(eachHeaderId).Original_Contract_Id__r.Account_Name__c);
                    }
                    
                    if(IsTaskTobeCreated)
                    {
                        // Adding Contract Header Id for Task Creation
                        contractIdTaskCreateList.add(eachHeaderId);
                    }
                }
            }
            
            system.debug('contractLine_CaseTitleMap'+contractLine_CaseTitleMap);
          

            // Vandhana - changed hardcoded BOCC value to 'useCase'

            // Phase:2 - Call to Case Creation Method from Phase-1
            
            //Changes by Vamsee - ESESP-5667 Populate Case Product
            if(accountIdSet.size() > 0){
                For(EB_AccountProductMap__c eachCP : [SELECT Id, EB_Product__c,EB_Account__c FROM EB_AccountProductMap__c WHERE EB_MarkedForDeletion__c = False 
                                                      AND EB_Product__c in('Prolexic Routed' , 'Prolexic Connect') AND EB_Account__c in :accountIdSet]){
                                                          if(eachCP.EB_Product__c == 'Prolexic Routed'){
                                                              accountPSProduct_CaseProductMap.put(eachCP.EB_Account__c + '-PLXR-COB',eachCP.Id);
                                                          }
                                                          else if(eachCP.EB_Product__c == 'Prolexic Connect'){
                                                              accountPSProduct_CaseProductMap.put(eachCP.EB_Account__c + '-PLXC-COB',eachCP.Id);
                                                          }
                }
            }
              
            if(contractLine_CaseTitleMap.size() > 0)
            {
                CreateCase(contractLine_CaseTitleMap,useCase);

                updateAllContractLines_ACHD(contractLine_CaseTitleMap);
            }
            
            // deallocate Memory
            contractLineList_Incoming.clear();
      }
      
      //Method to create 2 cases for each contract line item ESESP-1129
      public void ProtectPerform_Calculation(List<Merge_Contract_Detail__c> contractLineList_Incoming, String useCase, Map<Id,boolean> contractHeaderId_COBCreatedMap_ACHD)
      {
          
             System.debug('ProtectPerform_Calculation');

            // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
            // List to store all Filtered  Line Items
            List<Merge_Contract_Detail__c> contractLineList_Filtered = new List<Merge_Contract_Detail__c>();
            
            // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            // Fetch the Use Case Implementation Date
            Date getImplementationDate = autogenUseCase_FullRec.get(useCase).Use_Case_Implementation_Date__c;
        
            // Getting Case Subject value from SC Autogen Job
            String getSubject =  autogenUseCase_FullRec.get(useCase).Subject__c;
            List<String> subjectList = getSubject.split(',');
        
            // Getting task creation value
            boolean IsTaskTobeCreated = autogenUseCase_FullRec.get(useCase).IsTaskTobeCreated__c;
            
            for(Merge_Contract_Detail__c eachLine : contractLineList_Incoming)
            {
                System.debug('LINE ITEM ' + eachLine);
                
               
                

                    if (
                          eachLine.CreatedDate.date() <= System.today() 
                            && System.today().addDays(-33) <= eachLine.Effective_Start_Date__c
                            && eachLine.Effective_Start_Date__c <= System.today()
                        )
                    {
                        System.debug('Entry criteria pass' + eachLine.Product__c);
                        contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
                    }
                }
        
        system.debug('Contract Header'+contractHdId_ContractDetMap);
            /*.........On Boarding..........*/
            
            // Phase-1 : Checking if already On Boarding Case exist or not
            for(Id eachHeaderId : contractHdId_ContractDetMap.keyset())
            {
                
                if(contractHeaderId_COBCreatedMap_ACHD.get(eachHeaderId) == null)
                {
                    // Add to Map for case creation
                    contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), getSubject + ' ');
                    
                    if(IsTaskTobeCreated)
                    {
                        // Adding Contract Header Id for Task Creation
                        contractIdTaskCreateList.add(eachHeaderId);
                    }
                }
            }
            
            system.debug('contractLine_CaseTitleMap'+contractLine_CaseTitleMap);
          

            

            // Phase:2 - Call to Case Creation Method from Phase-1
            if(contractLine_CaseTitleMap.size() > 0)
            {
                //CreateCase(contractLine_CaseTitleMap,'BOCC');
                CreateCasePP(contractLine_CaseTitleMap,useCase);

                updateAllContractLines_ACHD(contractLine_CaseTitleMap);
            }
            
            // deallocate Memory
            contractLineList_Incoming.clear();
        
       }
       
    //Method for Plus Calculation ESESP-2046
    //Plus_Calculation
    /*
    public void Plus_Calculation(List<Merge_Contract_Detail__c> contractLineList_Incoming, String useCase, Map<Id,boolean> OnboardedCLIPlusACHD)
    {
        system.debug('Plus_Calculation');
        
        List<Merge_Contract_Detail__c> contractLineList_Filtered = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> contractLineList_Final = new List<Merge_Contract_Detail__c>();
        
        //Condition check 
        for(Merge_Contract_Detail__c eachLine : contractLineList_Incoming)
        {
            system.debug('Tommorow' + System.today().addDays(1));
            system.debug('33 advance' + System.today().addDays(33));
            system.debug('CLI ESD' + eachLine.Effective_Start_Date__c);
            if(System.today().addDays(-33) <= eachLine.Effective_Start_Date__c&& eachLine.Effective_Start_Date__c <= System.today())
            {
                if(System.today().addDays(-2) <= eachLine.CreatedDate.date() && eachLine.CreatedDate.date() <= System.today())
                {
                    contractLineList_Filtered.add(eachLine);
                }
            }
            
            if(System.today().addDays(1)<= eachLine.Effective_Start_Date__c && eachLine.Effective_Start_Date__c <= System.today().addDays(33))
            {
                system.debug('In condition 2 Plus');
                contractLineList_Filtered.add(eachLine);
            } 
        }
        system.debug('contractLineList_Filtered : '+contractLineList_Filtered);
        //Check if CLI has onboarding flag set
        for(Merge_Contract_Detail__c C:contractLineList_Filtered)
        {
            if(OnboardedCLIPlusACHD.get(C.Id)==null)
            {
                contractLineList_Final.add(C);
            }
        }
        
        //Pass the final Contract List for Case Creation
        if(contractLineList_Final.size()>0)
        {
            //Create Case
            if(useCase == 'Plus')
              CreateCasePlus(contractLineList_Final,useCase);
            
            System.debug('useCasegskafga : '+useCase);
            if(useCase == 'Advanced')
              CreateCaseAdvanced(contractLineList_Final,useCase);
            
            if(useCase == 'Project Management Option')
              CreateCasePMO(contractLineList_Final,useCase);
            
            //Update corresponding ACHD
            system.debug('contractLineList_Final : '+contractLineList_Final);
            updatePlusContractLines_ACHD(contractLineList_Final);
            
        }
    }
    */
    
       
    
       
      // Method - 14: Method for SOA Child Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void SOA_ChildProd_Calculation(List<Merge_Contract_Detail__c> contractLineList_SOAChild, string useCase, string caseDesc,
                    Map<Id,boolean> contractHeaderId_SOAChildreatedMap_ACHD){
      
        // Map to store Contract Line - Usecase(For Contract Update)
            Map<Merge_Contract_Detail__c,string> contractLine_usecaseMap = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title (For Case Creation)
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
        // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
          
        // Fetch the Use Case Implementation Date
        Date getSOAStartDate = autogenUseCase_FullRec.get(useCase).Use_Case_Implementation_Date__c;
          
        // Getting Case Subject value from SC Autogen Job
        string getSubject =  autogenUseCase_FullRec.get(useCase).Subject__c;
        
        // Getting task creation value
        boolean IsTaskTobeCreated = autogenUseCase_FullRec.get(useCase).IsTaskTobeCreated__c;
            
            // Loop for all the Incoming Contract Lines
        for(Merge_Contract_Detail__c eachLine : contractLineList_SOAChild){
  
        //if(Date.ValueOf(eachLine.createdDate) > getSOAStartDate && eachLine.Effective_Start_Date__c > getSOAStartDate){
        
        IF (
          (eachLine.Effective_Start_Date__c >= getSOAStartDate && Date.ValueOf(eachLine.createdDate) >= getSOAStartDate) ||
          (eachLine.Effective_Start_Date__c <= getSOAStartDate && Date.ValueOf(eachLine.createdDate) >= getSOAStartDate) ||
          (eachLine.Effective_Start_Date__c >=  getSOAStartDate && Date.ValueOf(eachLine.createdDate) <= getSOAStartDate)
        ){
        
          contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
          contractLine_usecaseMap.put(eachLine,useCase);
        
        }
        }
        
        // Variable to store SOA Child CL Creation Date
        Date SOAChildCreatedDateConverted;
        
        // Variable to store SOA Child CL Creation Date
        DateTime SOAChildCreatedDate;
        
        // Variable to store SOA Parent CL Creation Date
        Date SOAParentCreatedDateConverted;
        
        // Variable to store SOA Child CL Creation Date
        DateTime SOAParentCreatedDate;
        
          // Phase-1 : Loop for each Contract Header Calculation
            for(Id eachHeaderId : contractHdId_ContractDetMap.keyset()){
            
              /* Create SOA Child Case only if below situations satisfy:
              1. If child Contract gets created on the same day with main SOA Product with future ESD
              2. If a new Child Contract gets created tomorrow */
              
              // Assigning the Values
              SOAChildCreatedDate = contractHdId_ContractDetMap.get(eachHeaderId).createdDate;
              SOAChildCreatedDateConverted = date.newinstance(SOAChildCreatedDate.year(), SOAChildCreatedDate.month(), SOAChildCreatedDate.day());
              
              SOAParentCreatedDate = (contractHeaderId_SOAMainProdCL.get(eachHeaderId) != null) ? 
                          contractHeaderId_SOAMainProdCL.get(eachHeaderId).createdDate :
                          null;
              SOAParentCreatedDateConverted = (SOAParentCreatedDate != null) ? 
                            date.newinstance(SOAParentCreatedDate.year(), SOAParentCreatedDate.month(), SOAParentCreatedDate.day()) :
                            null;
              
              if(contractHeaderId_SOAChildreatedMap_ACHD.get(eachHeaderId) == null && // 1. NO COB Case got created for SOA Child
                contractHeaderId_SOAMainProdCL.get(eachHeaderId) != null &&   //2. SOA Main Prod Exists for that Contract
                contractHeaderId_SOAMainProdCOBCreatedMap_ACHD.get(eachHeaderId) != null &&  // 3. Already Case created for Main Prod
                contractHdId_ContractDetMap.get(eachHeaderId).Effective_Start_Date__c == system.today() &&
                (SOAChildCreatedDateConverted > SOAParentCreatedDateConverted ||  //4. Child Prod added Later
                contractHdId_ContractDetMap.get(eachHeaderId).Effective_Start_Date__c > SOAChildCreatedDateConverted) // 5. Child created on same day as Main Prod but ESD in future
              ){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), getSubject + ' ');
              
                // Adding Contract Header Id for Task Creation
                if(IsTaskTobeCreated){
                
                  // Adding Contract Header Id for Task Creation
                  contractIdTaskCreateList.add(eachHeaderId);
                } 
                
              }
              else
              {
                // Set the Map with Contract Hd Id and Case Desc
                if(contractHeaderId_SOAMainCaseUpdateMap.get(eachHeaderId) == null){
                
                  contractHeaderId_SOAMainCaseUpdateMap.put(eachHeaderId,caseDesc);
                }
                else
                {
                  contractHeaderId_SOAMainCaseUpdateMap.put(eachHeaderId,contractHeaderId_SOAMainCaseUpdateMap.get(eachHeaderId) + '\n' + caseDesc);
                } 
              }
              
      }
          
          // Phase:2 - Call to Case Creation Method 
            if(contractLine_CaseTitleMap.size() > 0){
                
                CreateCase(contractLine_CaseTitleMap, useCase);
                
            }
            
            // Phase:3 - Call to Update Contract Lines on ACHD Object 
            if(contractLine_usecaseMap.size() > 0)

              updateAllContractLines_ACHD(contractLine_usecaseMap);
        
        // deallocate Memory
            contractLineList_SOAChild.clear();
        
      }
      
      // Method - 15: Method for SOA MainProd Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void SOA_MainProd_Calculation(List<Merge_Contract_Detail__c> contractLineList_SOAParent, string useCase){
                          
        // Map to store Contract Line - Usecase(For Contract Update)
            Map<Merge_Contract_Detail__c,string> contractLine_usecaseMap = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title (For Case Creation)
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
        // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            // Map to store  Contract HD - Case
            Map<Id,Case> contractHdId_CaseMap = new Map<Id,Case>();
        
        // Fetch the Use Case Implementation Date
        Date getSOAStartDate = autogenUseCase_FullRec.get(useCase).Use_Case_Implementation_Date__c;
          
        // Getting Case Subject value from SC Autogen Job
        string getSubject =  autogenUseCase_FullRec.get(useCase).Subject__c;
        
        // Getting task creation value
        boolean IsTaskTobeCreated = autogenUseCase_FullRec.get(useCase).IsTaskTobeCreated__c;
            
            // Case Variable for Update
            Case eachCaseUpdate;
            
            // Loop for all the Incoming Contract Lines
        for(Merge_Contract_Detail__c eachLine : contractLineList_SOAParent){
  
        IF (
          (eachLine.Effective_Start_Date__c >= getSOAStartDate && Date.ValueOf(eachLine.createdDate) >= getSOAStartDate) ||
          (eachLine.Effective_Start_Date__c <= getSOAStartDate && Date.ValueOf(eachLine.createdDate) >= getSOAStartDate) ||
          (eachLine.Effective_Start_Date__c >=  getSOAStartDate && Date.ValueOf(eachLine.createdDate) <= getSOAStartDate)
        ){
        
          contractHdId_ContractDetMap.put(eachLine.Original_Contract_Id__c, eachLine);
          contractLine_usecaseMap.put(eachLine,useCase);
        
        }
        }
        
          
        // Phase-2: Loop for each Contract for SOA Main Product COB Calculation 
        for(Id eachHeaderId : contractHdId_ContractDetMap.keyset()){
        
          if(contractHeaderId_SOAMainProdCOBCreatedMap_ACHD.get(eachHeaderId) == null){
          
            contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), getSubject + ' ');
          
            // Adding Contract Header Id for Task Creation
                if(IsTaskTobeCreated){
                
                  // Adding Contract Header Id for Task Creation
                  contractIdTaskCreateList.add(eachHeaderId);
                } 
          }
        
        }
        
        // phase-3: Call to Case Creation Method 
            if(contractLine_CaseTitleMap.size() > 0){
                
                CreateCase(contractLine_CaseTitleMap, useCase);
                
            }
            
            // Phase:4 - Call to Update Contract Lines on ACHD Object 
            if(contractLine_usecaseMap.size() > 0)

              updateAllContractLines_ACHD(contractLine_usecaseMap);
        
        // deallocate Memory
            contractLineList_SOAParent.clear();           
      }
      
    
    // Method - 15: Method for RRS Prod Calculation
    // Called from - main_RUS_PPSM_QBR_Method method
    Public void RRS_Calculation(List<Merge_Contract_Detail__c> contractLineList_RRS){
        
        //Map to store Use case and product Id
        Map<String, String> useCase_ProductIdMap = new Map<String, String>();
        useCase_ProductIdMap.put('RRS-Parent',autogenUseCase_FullRec.get('RRS-Parent').Product__c);
        useCase_ProductIdMap.put('RRS-WebAppProtector',autogenUseCase_FullRec.get('RRS-WebAppProtector').Product__c);
      useCase_ProductIdMap.put('RRS-BotManager',autogenUseCase_FullRec.get('RRS-BotManager').Product__c);
        
        //Maps to store the Contract and case subject
        Map<Merge_Contract_Detail__c,string> RRS_ParentContract_caseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        Map<Merge_Contract_Detail__c,string> RRS_WAPContract_caseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        Map<Merge_Contract_Detail__c,string> RRS_BOTContract_caseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        
        //Set to store the Header Id in which Parent product is present
        Set<Id> parentProduct_ContractIdSet = new Set<Id>();
        
        String mapKey;
        
        //Map to store contract header Id and map of product id and contract detail
        Map<Id, Map<String, Merge_Contract_Detail__c>> ContractId_RRSLinesMap = new Map<Id, Map<String, Merge_Contract_Detail__c>>();
        Map<String, Merge_Contract_Detail__c> tempMap;
        
        Map<Merge_Contract_Detail__c, String> updateRRSLineMap = new Map<Merge_Contract_Detail__c, String>();
        
        for(Merge_Contract_Detail__c eachMCDRecord : contractLineList_RRS){
            if(eachMCDRecord.Product_Id__c == useCase_ProductIdMap.get('RRS-Parent')){
                parentProduct_ContractIdSet.add(eachMCDRecord.Original_Contract_Id__c);
      }
            //Check for back dated effective start date
            if(eachMCDRecord.CreatedDate.date() <= System.today() && System.today().addDays(-33) <= eachMCDRecord.Effective_Start_Date__c && eachMCDRecord.Effective_Start_Date__c <= System.today()){
                //Check whether COB is created or not
                if(contractDetailId_COBCreatedMap_ACHD.get(eachMCDRecord.Id) != null && contractDetailId_COBCreatedMap_ACHD.get(eachMCDRecord.Id).Is_COB_Created__c == False){
                    mapKey = eachMCDRecord.Original_Contract_Id__c;
                    if(ContractId_RRSLinesMap.get(mapKey) != null){
                        ContractId_RRSLinesMap.get(mapKey).put(eachMCDRecord.Product_Id__c, eachMCDRecord);
                    }
                    else{
                        ContractId_RRSLinesMap.put(mapKey, new Map<String, Merge_Contract_Detail__c>());
                        ContractId_RRSLinesMap.get(mapKey).put(eachMCDRecord.Product_Id__c, eachMCDRecord);
                    }
                    updateRRSLineMap.put(eachMCDRecord, 'True');
              } 
            }
       }
        for(Id eachContract : ContractId_RRSLinesMap.keySet()){
            Map<String, Merge_Contract_Detail__c> tempContract = ContractId_RRSLinesMap.get(eachContract);
            if(tempContract.get(useCase_ProductIdMap.get('RRS-Parent')) != null){
                //Parent product is present 
                String caseDesc = autogenUseCase_FullRec.get('RRS-Parent').Description__c;
                if(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')) != null && tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')) != null){
                    caseDesc += '\n\n' + 'Please note that customer has contracted the following variants of the Readiness and Response Service:'+
                        autogenUseCase_FullRec.get('RRS-WebAppProtector').Additional_Calculation_1__c + '\n'+
                        autogenUseCase_FullRec.get('RRS-BotManager').Additional_Calculation_1__c ;
                }
                else if(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')) != null){
                    caseDesc += '\n\n' + 'Please note that customer has contracted the following variants of the Readiness and Response Service:\n\n'+
                        autogenUseCase_FullRec.get('RRS-WebAppProtector').Additional_Calculation_1__c ;
                    
                }
                else if(tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')) != null){
                    caseDesc += '\n\n' + 'Please note that customer has contracted the following variants of the Readiness and Response Service:\n\n'+
                        autogenUseCase_FullRec.get('RRS-BotManager').Additional_Calculation_1__c;
                    
                }
                RRS_ParentContract_caseTitleMap.put(tempContract.get(useCase_ProductIdMap.get('RRS-Parent')), autogenUseCase_FullRec.get('RRS-Parent').Subject__c);
                contractIdTaskCreateList.add(tempContract.get(useCase_ProductIdMap.get('RRS-Parent')).Original_Contract_Id__c);
                contractID_CaseDesc_RRSMap.put(tempContract.get(useCase_ProductIdMap.get('RRS-Parent')).Original_Contract_Id__c,caseDesc);
            }
            else{
                //Check whether parent product is present
                if(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')) != null &&
                   parentProduct_ContractIdSet.contains(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')).Original_Contract_Id__c)){
                  //Child 1 product is present 
                  RRS_WAPContract_caseTitleMap.put(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')), autogenUseCase_FullRec.get('RRS-WebAppProtector').Subject__c);
                contractIdTaskCreateList.add(tempContract.get(useCase_ProductIdMap.get('RRS-WebAppProtector')).Original_Contract_Id__c);
                }
                //Check whether parent product is present
                if(tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')) != null &&
                  parentProduct_ContractIdSet.contains(tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')).Original_Contract_Id__c)){
                  //Child 2 product is present
                  RRS_BOTContract_caseTitleMap.put(tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')), autogenUseCase_FullRec.get('RRS-BotManager').Subject__c);
                contractIdTaskCreateList.add(tempContract.get(useCase_ProductIdMap.get('RRS-BotManager')).Original_Contract_Id__c);
                
                }
                
            }
            
    }
        if(RRS_ParentContract_caseTitleMap.size() > 0){
              CreateCase(RRS_ParentContract_caseTitleMap,'RRS-Parent');
        } 
        if(RRS_WAPContract_caseTitleMap.size() > 0){
              CreateCase(RRS_WAPContract_caseTitleMap,'RRS-WebAppProtector');
        } 
        if(RRS_BOTContract_caseTitleMap.size() > 0){
              CreateCase(RRS_BOTContract_caseTitleMap,'RRS-BotManager');
        } 
        //Update all the ACHD records
        if(updateRRSLineMap.size() > 0){
            updateAllContractLines_ACHD(updateRRSLineMap);
        }
       
    
    }
    
    
    
      // Method - 16: Method for Calculating Case Creation Criteria for RUS
      // Called from - RUS_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_RUS(List<Merge_Contract_Detail__c> contractLineList_RUS, string useCase){
    
        // Map to store Contract Line - Case Title 
          Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
    
        // variable for Case Creation Date Calculation
        Date caseCreationCalcDt ;
    
    // Get the Initial Case Creation Time from Custom Setting
    Integer initialFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues(useCase).Initial_Freq__c);
  
    // string to store Freq(No of Review) from Contract Line Item
    string caseFreq;
    
    // variable to calculate the no of Year Passed from Effective Start date
            Integer countNoOfyear;
    
    // Loop for Each Contract 
    for(Merge_Contract_Detail__c eachContractLineRec : contractLineList_RUS){
    
        // Getting Case Freq
        caseFreq = (integer.valueOf(eachContractLineRec.Units_Low__c) > 12) ? '12' :
      string.valueOf(eachContractLineRec.Units_Low__c);
    
        // Get the No of Month based on Review for Subsequent Case Creation Time from Custom Setting
        Integer subseqntFreqMonth = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreq).Subsequent_Freq_in_Months__c);
    
        // Get the  No of Days based on Review for Subsequent Case Creation Time from Custom Setting
        Integer subseqntFreqDays = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreq).Subsequent_Freq_in_Days__c);
  
      // Assigning Effective Start Date to variable
      caseCreationCalcDt = eachContractLineRec.Effective_Start_Date__c;
      
          // Calculate No Of Year
      countNoOfyear = caseCreationCalcDt.daysBetween(system.today())/365;
  
      // Set Effective Start Date by adding no of Year
      caseCreationCalcDt = caseCreationCalcDt.addMonths(12*countNoOfyear);
    
      // Setting value for 1st Occurance. 
      caseCreationCalcDt = caseCreationCalcDt.addDays(initialFreq);
   
      if(caseCreationCalcDt == System.Today() && caseCreationCalcDt <= eachContractLineRec.Effective_End_Date__c){
  
          // Add the Contract Line Record to Map  
          contractLine_CaseTitleMap.put(eachContractLineRec,'Technical Configuration Review ');
      }
      
      else
      {
        // Add Months and Day for Matching Next Case Creation Date
        caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
     
        while(caseCreationCalcDt <= eachContractLineRec.Effective_End_Date__c){
    
          if(caseCreationCalcDt == System.Today()){
    
            // Add the Contract Line Record to Map  
            contractLine_CaseTitleMap.put(eachContractLineRec,'Technical Configuration Review ');
    
            break;
          }
    
          // Add Months and Day for Matching Next Case Creation Date
          caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
    
        }  // End of While Loop
      
       }  // End of Else Block
      
    }    // End of For Loop
    
    return contractLine_CaseTitleMap;
              
      }
      
      // Method - 17: Method for Calculating Case Creation Criteria for PPSM
      // Called from - PPSM_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_PPSM(List<Merge_Contract_Detail__c> contractLineList_PPSM, string useCase){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
      
          // variable for Case Creation Date Calculation
            Date caseCreationCalcDt ;
          
            // variable to calculate the no of Year Passed from Effective Start date
            Integer countNoOfyear;
          
            // Fetch the Data from Custom Setting - SC_PPSM_Config__c
            List<SC_PPSM_Config__c>  allPPSMValues = SC_PPSM_Config__c.getall().values();
          
            // Loop for Each Contract 
            for(Merge_Contract_Detail__c eachContractLineRec : contractLineList_PPSM){
          
                // Assigning Effective Start Date to variable
            caseCreationCalcDt = eachContractLineRec.Effective_Start_Date__c;
      
            // Calculate No Of Year
        countNoOfyear = caseCreationCalcDt.daysBetween(system.today())/365;
  
        // Set Effective Start Date by adding no of Year
        caseCreationCalcDt = caseCreationCalcDt.addMonths(12*countNoOfyear);
  
        // Variable to store the PPSM Case Freq
        Integer caseFreq;
      
            // Loop for each PPSM Record from Custom setting
                    for(integer i =0 ; i < allPPSMValues.size() ; i ++){
                  
                      // Assigning Case Freq Value
                      caseFreq = Integer.valueOf(allPPSMValues[i].PPSM_Freq__c);
                    
                      if(caseCreationCalcDt.addDays(caseFreq) == system.Today() && 
                          caseCreationCalcDt.addDays(caseFreq) <= eachContractLineRec.Effective_End_Date__c){
                    
                          // Add the Contract Line Record to Map  
                    contractLine_CaseTitleMap.put(eachContractLineRec,allPPSMValues[i].Case_Title__c);
                    break;  
                      }
                
                  }
          
            }
          
          return contractLine_CaseTitleMap;
      }
      
      
      // Method - 18: Method for Calculating Case Creation Criteria for QBR
      // Called from - QBR_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_QBR(List<Merge_Contract_Detail__c> contractLineList_QBR, string useCase){
      
            // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        
    // variable for Case Creation Date Calculation
    Date caseCreationCalcDt ;
      
            // Get the Subsequent Case Creation Time from Custom Setting
            Integer subseqntFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues(useCase).Subsequent_Freq_in_Months__c);
            
            // Map to store Contract HD ID - Any Contract Line
            Map<string,Merge_Contract_Detail__c> contractHDIDKey_ContractDetMap = new Map<string,Merge_Contract_Detail__c>();
            
            // Design Contract Key (Contract HD Id + Product Id) - To Generate one QBR Case Per Contract Per Product
            string key;
            
            // Loop to set values for contractHDID_ContractDetMap (For creating one Case Per Contract Header)
            for(Merge_Contract_Detail__c eachContractLineRec : contractLineList_QBR){
            
              // Setting Values for the Key
              key = eachContractLineRec.Original_Contract_Id__c + '-' + eachContractLineRec.Product_Id__c;
              contractHDIDKey_ContractDetMap.put(key,eachContractLineRec);
            }
                  
            // Loop for Each Contract Line for Matching Case Creation Criteria 
            for(Merge_Contract_Detail__c eachContractLineRec : contractHDIDKey_ContractDetMap.values()){
        
        // Assigning Effective Start Date to variable
        caseCreationCalcDt = eachContractLineRec.Original_Contract_Id__r.Effective_Start_Date__c;
    
        // Add No of months for QBR UseCase for subsequent Case Creation
        caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreq);
    
        while(caseCreationCalcDt <= eachContractLineRec.Original_Contract_Id__r.Effective_End_Date__c){
    
              if(caseCreationCalcDt == System.Today()){
    
                  // Add the Contract Line Record to Map  
                  contractLine_CaseTitleMap.put(eachContractLineRec,'Quarterly Business Review ');
    
                  break;
              }
    
              // Add Months for Next Occurance
              caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreq);
    
        }
            }
        
          return contractLine_CaseTitleMap;
      
      }
      
      // Method - 19: Method for Calculating Case Creation Criteria for SMP
      // Called from - SMP_Calculation method
      public void CaseCalculation_SMP(List<Merge_Contract_Detail__c> contractLineList_SMP, string usecase,
                            string setCOBSubject){
      
            // Map to store Contract Line - Case Title for Case Creation (For Security Products - On Boarding)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_Sec_COB = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title for Case Creation (For Security Products - Recurring)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_Sec_RC = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title for Case Creation (For NonSecurity Products - On Boarding)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_NonSec_COB = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title for Case Creation (For NonSecurity Products - Recurring)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_NonSec_RC = new Map<Merge_Contract_Detail__c,string>();
            
            /* Diff SMP Use Cases
              1. SMP-Security-COB
              2. SMP-Security-RC
              3. SMP-NonSecurity-COB
              4. SMP-NonSecurity-RC
            */
            
            // Map to store Contract HD - Any Contract Detail (For Security Products-COB)
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap_Sec_COB = new Map<Id,Merge_Contract_Detail__c>();
            
             // Map to store Contract HD - Any Contract Detail (For Security Products-RC)
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap_Sec_RC = new Map<Id,Merge_Contract_Detail__c>();
            
            // Map to store Contract HD - Any Contract Detail (For Non Security Products)
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap_NonSec = new Map<Id,Merge_Contract_Detail__c>();
            
            // Map to store Contract HD - Any Contract Detail (For Non Security Products RC) -ESESP-1157
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap_NonSec_RC = new Map<Id,Merge_Contract_Detail__c>();
            
            // Boolean to check the return for SMP-RC method
            boolean isSMP_RCExist = false;
            
            
            boolean returnFlag = false;
            
            // Lists to Store all SMP Security and Non Security Products
            Set<String> SMPSecurityProdList = new Set<String>();
            Set<String> SMPNonSecurityProdList = new Set<String>();
            returnFlag = SMPSecurityProdList.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP-Security').Product_Id__c.split(','));
            returnFlag = SMPNonSecurityProdList.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP-NonSecurity').Product_Id__c.split(',')); 
            
            /*****************************ESESP-1157**********************************/
            //Set and logic to store all SMP Non Securtiy RC products 
            Set<String> SMPNonSecurityProdListRC = new Set<String>();
            returnFlag = SMPNonSecurityProdListRC.addAll(SC_TCR_WAF_ProdList__c.getValues('SMP-NonSecurity-RC').Product_Id__c.split(','));
            
            /*****************************ESESP-1157**********************************/
            //List to store CLI for SMP (Non Security Recurring) 
            List<Merge_Contract_Detail__c> CLISMPREC = new List<Merge_Contract_Detail__c>();
            
            system.debug('1157 SMPNonSecurityProdListRC '+SMPNonSecurityProdListRC);
            
            // Loop for all the Incoming Contract Lines
            for (Merge_Contract_Detail__c eachContractLine : contractLineList_SMP){
            
            system.debug('1157 Product'+eachContractLine.Product_Id__c);
              // Logic For SMP Security Products
              if(SMPSecurityProdList.contains(eachContractLine.Product_Id__c)){
                
                contractHdId_ContractDetMap_Sec_COB.put(eachContractLine.Original_Contract_Id__c, eachContractLine);
                
                  if(eachContractLine.Units_Low__c <> null && eachContractLine.Units_Low__c <> 0 && eachContractLine.Unit_of_Measure__c == 'Reviews')
                    contractHdId_ContractDetMap_Sec_RC.put(eachContractLine.Original_Contract_Id__c, eachContractLine);
              
              }
              
              // Logic For SMP Non Security Products
              else if(SMPNonSecurityProdList.contains(eachContractLine.Product_Id__c)){
                
                contractHdId_ContractDetMap_NonSec.put(eachContractLine.Original_Contract_Id__c, eachContractLine);
                
              }
              
              /**************************ESESP-1157*************************************/
              //Logic for SMP Non Security Recurring products
              if(SMPNonSecurityProdListRC.contains(eachContractLine.Product_Id__c))
              {
              
                   system.debug('1157 Entering if');
                   system.debug('1157 Unit of Measure'+eachContractLine.Unit_of_Measure__c);
                   if(eachContractLine.Unit_of_Measure__c=='Configurations')
                   {
                    //contractHdId_ContractDetMap_NonSec_RC.put(eachContractLine.Original_Contract_Id__c, eachContractLine);
                    CLISMPREC.add(eachContractLine);
                   }
                
              }
            
            }
            
            system.debug('1157 contractHdId_ContractDetMap_NonSec_RC'+contractHdId_ContractDetMap_NonSec_RC);
            
            // Loop for each Contract Header Calculation (For Security Products)
            for(Id eachHeaderId : contractHdId_ContractDetMap_Sec_COB.keyset()){
            
              /*** ......Logic for On Boarding............**/
              if(contractHeaderId_SMP_SEC_COBCreatedMap_ACHD.get(eachHeaderId) == null){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap_Sec_COB.put(contractHdId_ContractDetMap_Sec_COB.get(eachHeaderId), setCOBSubject);
              }
              
              /*** ......Logic for Recurring............**/
              
              if(contractHdId_ContractDetMap_Sec_RC.get(eachHeaderId) != null){
          
          isSMP_RCExist = CaseCalculation_SMP_RC(contractHdId_ContractDetMap_Sec_RC.get(eachHeaderId),usecase,'SMP-Sec');
        
                  if(isSMP_RCExist){
    
              contractLine_CaseTitleMap_Sec_RC.put(contractHdId_ContractDetMap_Sec_RC.get(eachHeaderId), 'Security Configuration Review : ');
          }
          }
            }
            
            // Loop for each Contract Header Calculation (For Non Security Products)
            for(Id eachHeaderId : contractHdId_ContractDetMap_NonSec.keyset()){
            
              /*** ......Logic for On Boarding............**/
              if(contractHeaderId_SMP_NONSEC_COBCreatedMap_ACHD.get(eachHeaderId) == null){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap_NonSec_COB.put(contractHdId_ContractDetMap_NonSec.get(eachHeaderId), 'Service Management 2.0 :: Customer Onboarding :: ');
                contractIdTaskCreateList.add(eachHeaderId);
              }
              
              /*** ......Logic for Recurring............**/
              
        //isSMP_RCExist = CaseCalculation_SMP_RC(contractHdId_ContractDetMap_NonSec.get(eachHeaderId),usecase,'SMP-NonSec');
        
                  //if(isSMP_RCExist){
    
            //contractLine_CaseTitleMap_NonSec_RC.put(contractHdId_ContractDetMap_NonSec.get(eachHeaderId), 'Optimization Schedule : ');
       // }
            }
            
            
            /************************************ESESP-1157****************************************/
            //Loop for Non Security Products Recurring 
            for(Merge_Contract_Detail__c CLI : CLISMPREC)
            {
            
                   
                            system.debug('CLI'+CLI);
                           
                            isSMP_RCExist = CaseCalculation_SMP_RC(CLI,usecase,'SMP-NonSec');
                            
                            system.debug('isSMP_RCExist'+isSMP_RCExist);
        
                           if(isSMP_RCExist){
    
                          contractLine_CaseTitleMap_NonSec_RC.put(CLI, 'Optimization Schedule : ');
                   
                   
            
            }
            
            }
            
            system.debug('1157 contractLine_CaseTitleMap_NonSec_RC'+contractLine_CaseTitleMap_NonSec_RC);
            
            
          // Call to Case Creation Method For - SMP Security - COB Products
          if(contractLine_CaseTitleMap_Sec_COB.size() > 0){
              CreateCase(contractLine_CaseTitleMap_Sec_COB,'SMP-Security-COB');
              
          }
          
          // Call to Case Creation Method For - SMP Security - RC Products
          if(contractLine_CaseTitleMap_Sec_RC.size() > 0){
              CreateCase(contractLine_CaseTitleMap_Sec_RC,'SMP-Security-RC');
              
          }
          
          // Call to Case Creation Method For - SMP Non Security - COB Products
          if(contractLine_CaseTitleMap_NonSec_COB.size() > 0){
              CreateCase(contractLine_CaseTitleMap_NonSec_COB,'SMP-NonSecurity-COB');
              
          }
          
          // Call to Case Creation Method For - SMP Non Security - RC Products
          if(contractLine_CaseTitleMap_NonSec_RC.size() > 0){
              CreateCase(contractLine_CaseTitleMap_NonSec_RC,'SMP-NonSecurity-RC');
              
          }
            
          // Deallocate Memory
          contractLine_CaseTitleMap_Sec_COB.clear();
          contractLine_CaseTitleMap_Sec_RC.clear();
          contractLine_CaseTitleMap_NonSec_COB.clear();
          contractLine_CaseTitleMap_NonSec_RC.clear();
            
      
      }
      
      // Method - 20: Common Method for Calculating Case Creation Criteria for KDD,GDS,MDS On boarding
      // Called from - KDD_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_KDD(List<Merge_Contract_Detail__c> contractLineList_KDD,
                                        string useCase){
      
            // Map to store Contract Line - Case Title for Case Creation
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract HD - Any Contract Detail 
            Map<Id,Merge_Contract_Detail__c> contractHdId_ContractDetMap = new Map<Id,Merge_Contract_Detail__c>();
            
            // Loop for all the Incoming Contract Lines
            for (Merge_Contract_Detail__c eachContractLine : contractLineList_KDD){
            
              contractHdId_ContractDetMap.put(eachContractLine.Original_Contract_Id__c, eachContractLine);
            } 
            
            
            
            // Loop for each Contract Header Calculation
            for(Id eachHeaderId : contractHdId_ContractDetMap.keyset()){
            
              /*** ......KDD - On Boarding............**/
              if(useCase == 'KDD' && contractHeaderId_KDDCOBCreatedMap_ACHD.get(eachHeaderId) == null ){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), 'Kona DDoS Defender :: Customer Onboarding :: ');
              
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }
              
              /*** ......GDS - On Boarding............**/
              else if(useCase == 'GDS' && contractHeaderId_GDSCOBCreatedMap_ACHD.get(eachHeaderId) == null){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), autogenUseCase_FullRec.get('GDS-COB').Subject__c);
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }

              /*** ......PSE - On Boarding............**/
              /*else if(useCase == 'PSE' && contractHeaderId_PSECOBCreatedMap_ACHD.get(eachHeaderId) == NULL)
              {
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), autogenUseCase_FullRec.get('PSE-COB').Subject__c);
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }*/

              /*** ......TAS - On Boarding............**/
              /*else if(useCase == 'TAS' && contractHeaderId_TASCOBCreatedMap_ACHD.get(eachHeaderId) == NULL)
              {
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), autogenUseCase_FullRec.get('TAS-COB').Subject__c);
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }*/
              
              /*** ......MDS - On Boarding............**/
              else if(useCase == 'MDS' && contractHeaderId_MDSCOBCreatedMap_ACHD.get(eachHeaderId) == null){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), 'Managed Delivery Service :: Customer Onboarding :: ');
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }
              
              /*** ......KSD - On Boarding............**/
              else if(useCase == 'KSD' && contractHeaderId_KSDCOBCreatedMap_ACHD.get(eachHeaderId) == null){
              
                // Add to Map for case creation
                contractLine_CaseTitleMap.put(contractHdId_ContractDetMap.get(eachHeaderId), 'Kona Site Defender :: Onboarding / Integration :: ');
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachHeaderId);
              }

            }
            
            
        return contractLine_CaseTitleMap;
      
      }
      
      // Method - 21: Method for Calculating Case Creation Criteria for SMP Recurring, GDS Recurring
      // Called from - CaseCalculation_SMP method
      public boolean CaseCalculation_SMP_RC(Merge_Contract_Detail__c SMPLineItem,string usecase, string smpUseCaseType){
      
        // Flag for returning the result whether it meets case creation criteria or not
        boolean retFlag = false;
        
        // variable for Case Creation Date Calculation
            Date caseCreationCalcDt ;
            
            // variable to store Effective End Date
            Date effectiveEndDate ;
          
            // variable to calculate the no of Year Passed from Effective Start date
            Integer countNoOfyear;
          
            // Variable to store the SMP Case Freq
            Integer caseFreq;
    
            // List to store SMP Case Creation Freq from Custom Setting
            List<string> SMPCaseFreq;

            if(useCase =='GDS-RC')
                SMPCaseFreq = autogenUseCase_FullRec.get('GDS-RC').Recurring_Frequency__c.split(',');
            else
                SMPCaseFreq = SC_Autogen_Running_Freq__c.getValues(usecase).Cron_Time__c.split(',');
                
            // Assigning Effective Start Date to variable
      caseCreationCalcDt = (smpUseCaseType == 'Others') ? 
                SMPLineItem.Original_Contract_Id__r.Effective_Start_Date__c :
                SMPLineItem.Effective_Start_Date__c;
            
      effectiveEndDate = (smpUseCaseType == 'Others') ? 
                SMPLineItem.Original_Contract_Id__r.Effective_End_Date__c :
                SMPLineItem.Effective_End_Date__c;

      // Calculate No Of Year
      countNoOfyear = caseCreationCalcDt.daysBetween(system.today())/365;

      // Set Effective Start Date by adding no of Year
      caseCreationCalcDt = caseCreationCalcDt.addMonths(12*countNoOfyear);
    
      /*......Calculation for SMP Non Security Products  */
      if(smpUseCaseType == 'SMP-NonSec' || smpUseCaseType == 'Others'){
    
        // Loop for each Case Freq from Custom setting
        for(string eachCaseFreq : SMPCaseFreq){

          // Assigning Case Freq Value
          caseFreq = Integer.valueOf(eachCaseFreq);
          
          //30 day check variable
          Date caseCreationCalcDtcheck = caseCreationCalcDt.addDays(caseFreq);
    
          if(caseCreationCalcDt.addDays(caseFreq) == system.Today() && 
           caseCreationCalcDtcheck.addDays(30) <= effectiveEndDate){

            // set Return Flag to True  
            retFlag = true;
            break;  
        }
    
      }
    }
    /*......Calculation for SMP Security Products  */
    else if(smpUseCaseType == 'SMP-Sec')
    { 
            
              // Get the Initial Case Creation Time from Custom Setting
      Integer initialFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues(smpUseCaseType).Initial_Freq__c);
      
      // string to store Freq(No of Review) from Contract Line Item
        string caseFreqFrmReview = (integer.valueOf(SMPLineItem.Units_Low__c) > 12) ? '12' :
                    string.valueOf(SMPLineItem.Units_Low__c);
              
      // Get the No of Month based on Review for Subsequent Case Creation Time from Custom Setting
        Integer subseqntFreqMonth = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreqFrmReview).Subsequent_Freq_in_Months__c);
    
        // Get the  No of Days based on Review for Subsequent Case Creation Time from Custom Setting
        Integer subseqntFreqDays = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreqFrmReview).Subsequent_Freq_in_Days__c);
        
        // Checking for 1st Occurance. 
      if(SMPLineItem.Effective_Start_Date__c.addDays(initialFreq) == System.Today() && caseCreationCalcDt <= SMPLineItem.Effective_End_Date__c){
  
          // set Return Flag to True  
        retFlag = true;
      }
      
      else
      {
        // Getting Starting of the Year + 40 Days
        caseCreationCalcDt = caseCreationCalcDt.addDays(initialFreq);
        
        // Add Months and Day for Matching Next Case Creation Date
        caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
     
        while(caseCreationCalcDt <= SMPLineItem.Effective_End_Date__c){
    
          if(caseCreationCalcDt == System.Today()){
    
            // set Return Flag to True  
            retFlag = true;
            break; 
          }
    
          // Add Months and Day for Matching Next Case Creation Date
          caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
    
        }  // End of While Loop
      
       }  // End of Else Block
    
    } // End of Main Else Block
    
    return retFlag;
      }
    
      /* ESESP-1356
      // Method - 22: Method for Calculating Case Creation Criteria for NES
      // Called from - NES_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_NES(List<Merge_Contract_Detail__c> contractLineList_NES, string useCase){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          
            // Loop for Each Contract 
            for(Merge_Contract_Detail__c eachContractLineRec : contractLineList_NES){
          
              if(contractDetailId_COBCreatedMap_ACHD.get(eachContractLineRec.Id) <> null && contractDetailId_COBCreatedMap_ACHD.get(eachContractLineRec.Id).Is_COB_Created__c == false){
            
                    // Add the Contract Line Record to Map  
                    contractLine_CaseTitleMap.put(eachContractLineRec,'NES Onboarding : ');
              }
          
            }
      
          return contractLine_CaseTitleMap;
      
      }
      
      */
      /* Removed as part of CR 3283891
      Method - 23: Method for Calculating Case Creation Criteria for KONA
      // Called from - KONA_Calculation method
      public Map<Merge_Contract_Detail__c,string> CaseCalculation_KONA(List<Merge_Contract_Detail__c> contractLineList_KONA, string useCase){
      
          // Map to store Contract Line - Case Title 
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
            
            //.... Phase-1 Calculation: For Designing the cntrctHD_contrctLineGrpMap ....//
          // Set to store all Contract HD IDs
          set<Id> allContractHDIDs = new set<ID>();
        
          // Map to store Contract HD Id + UOM - List of Contract Line Items
          Map<string,List<Merge_Contract_Detail__c>> cntrctHD_contrctLineGrpMap = new Map<string,List<Merge_Contract_Detail__c>>();
        
          // List to store all Related Contract Lines
            List<Merge_Contract_Detail__c> allRelatedContrctLns;
        
          // key to store Contract HD Id + UOM
            string cntrctHD_UomKey = null;
            
            
            // Loop for each Contract Lines
            for(Merge_Contract_Detail__c eachCntrctLnRec : contractLineList_KONA){
            
                // setting the value of allContractHDIDs
                allContractHDIDs.add(eachCntrctLnRec.Original_Contract_Id__c);
                
                // Designing The Key
                if(eachCntrctLnRec.Unit_of_Measure__c == 'Reviews')
                    cntrctHD_UomKey = eachCntrctLnRec.Original_Contract_Id__c + '-' + 'Reviews';
                    
                else if(eachCntrctLnRec.Unit_of_Measure__c == 'Per Site' || eachCntrctLnRec.Unit_of_Measure__c == 'Policies')
                    cntrctHD_UomKey = eachCntrctLnRec.Original_Contract_Id__c + '-' + 'SitePolicy';
                    
                else
                    cntrctHD_UomKey = eachCntrctLnRec.Original_Contract_Id__c + '-' + 'Rest';
                    
                    // Fetching Existing List Of Contract Lines
                    allRelatedContrctLns = cntrctHD_contrctLineGrpMap.get(cntrctHD_UomKey);
                
                    if(allRelatedContrctLns == null){
                        allRelatedContrctLns = new List<Merge_Contract_Detail__c>();
                    }
                    
                    allRelatedContrctLns.add(eachCntrctLnRec);
                    cntrctHD_contrctLineGrpMap.put(cntrctHD_UomKey,allRelatedContrctLns);
                
            }
            */
            //.... End of Phase-1 : ...//
            
            /*..2nd Phase ..//
            
            // Re-Initializing the variable
            allRelatedContrctLns = new List<Merge_Contract_Detail__c>();
            
            // List to store all calculated Contract Lines
            List<Merge_Contract_Detail__c> allCalculatedConrtLnsForHD = new List<Merge_Contract_Detail__c>();
            
             // List to store calculated Contract Lines
            List<Merge_Contract_Detail__c> CalculatedConrtLnsForHD = new List<Merge_Contract_Detail__c>();
            
            // Loop for each Contract Header
            for(Id eachContractHDID : allContractHDIDs){
            
                CalculatedConrtLnsForHD = new List<Merge_Contract_Detail__c>();
                
                // Calculations for "Review" Contract Lines
                allRelatedContrctLns = cntrctHD_contrctLineGrpMap.get(eachContractHDID + '-' + 'Reviews');
                
                if(allRelatedContrctLns <> null && allRelatedContrctLns.size() > 0){
                
                    CalculatedConrtLnsForHD = calculateCaseCreation2ndPhase_KONA(allRelatedContrctLns,'Reviews');
                }
                else
                {
                
                    // Calculations for "SitePolicy" Contract Lines
                    allRelatedContrctLns = cntrctHD_contrctLineGrpMap.get(eachContractHDID + '-' + 'SitePolicy');
                    
                    if(allRelatedContrctLns <> null && allRelatedContrctLns.size() > 0){
                        
                        CalculatedConrtLnsForHD = calculateCaseCreation2ndPhase_KONA(allRelatedContrctLns,'SitePolicy');
                        
                    }
                    else
                    {
                        // Calculations for "Rest" Contract Lines
                        allRelatedContrctLns = cntrctHD_contrctLineGrpMap.get(eachContractHDID + '-' + 'Rest');
                        
                        if(allRelatedContrctLns <> null && allRelatedContrctLns.size() > 0){
                        
                            CalculatedConrtLnsForHD = calculateCaseCreation2ndPhase_KONA(allRelatedContrctLns,'Rest');
                        }
                    
                    }
                }
                
                // Add all the Calculated Contract List to Final List
                if(CalculatedConrtLnsForHD.size() > 0)
                    allCalculatedConrtLnsForHD.addAll(CalculatedConrtLnsForHD);
                    
                
            } // End of For Loop
            
            // Loop for setting contractLine_CaseTitleMap
            for(Merge_Contract_Detail__c eachContractRec : allCalculatedConrtLnsForHD){
            
                contractLine_CaseTitleMap.put(eachContractRec, 'Security Review for Managed Kona: ');
            }
        
        return contractLine_CaseTitleMap;
      
      } */
      /* Removed as part of CR 3283891
      // Method - 24: Method for Calculating Case Creation Criteria for KONA Phase-2
      // Called from - CaseCalculation_KONA method
      public List<Merge_Contract_Detail__c> calculateCaseCreation2ndPhase_KONA(List<Merge_Contract_Detail__c> allRelatedContrctLns, string useCase){
      
        
          // List to store all Returned Contract Line List
          List<Merge_Contract_Detail__c> contractLineListAfter2ndPhase = new List<Merge_Contract_Detail__c>();
        
          // variable for Case Creation Date Calculation
            Date caseCreationCalcDt;
          
            // variable to calculate the no of Year Passed from Effective Start date
            Integer countNoOfyear;
          
            // Variable to store the KONA Case Freq
            string caseFreq;
            
            // Get the Initial Freq=14 Days from Custom Setting
            Integer initialFreq =  Integer.valueOf(SC_Autogen_Case_Freq__c.getValues('KONA').Initial_Freq__c);
            
            // Get the No of Month based on Review for Subsequent Case Creation Time from Custom Setting
            Integer subseqntFreqMonth ;
        
            // Get the  No of Days based on Review for Subsequent Case Creation Time from Custom Setting
            Integer subseqntFreqDays ;
            
            // If useCase = Reviews or SitePolicy then use RUS Table for calculation else use 
            if(useCase == 'Reviews' || useCase == 'SitePolicy'){
            
            // Loop for Each Contract 
            for(Merge_Contract_Detail__c eachContractLineRec : allRelatedContrctLns){
            
                // Setting value for 1st Occurance. 
                caseCreationCalcDt = eachContractLineRec.Effective_Start_Date__c.addDays(initialFreq);
            
                // Add Effective Start Date + 14 Days. If matches with
                if(caseCreationCalcDt == System.Today() && caseCreationCalcDt <= eachContractLineRec.Effective_End_Date__c){
    
                    // Add the Contract Line Record to Return List  
                    contractLineListAfter2ndPhase.add(eachContractLineRec);
                }
                else
                {
            
                    // Getting Case Freq
                    caseFreq = (integer.valueOf(eachContractLineRec.Units_High__c) > 12) ? '12' :
                            string.valueOf(eachContractLineRec.Units_High__c);
                        
                    subseqntFreqMonth = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreq).Subsequent_Freq_in_Months__c);
                    subseqntFreqDays = Integer.valueOf(SC_AutoGen_RUS_Cal__c.getValues(caseFreq).Subsequent_Freq_in_Days__c);
    
                    // Calculate No Of Year
                    countNoOfyear = caseCreationCalcDt.daysBetween(system.today())/365;
    
                    // Set Effective Start Date by adding no of Year
                    caseCreationCalcDt = caseCreationCalcDt.addMonths(12*countNoOfyear);
                
                    // Add Months and Day for Matching Next Case Creation Date
                    caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
                
                    // Loop up to Contract Effective End Date
                    while(caseCreationCalcDt <= eachContractLineRec.Effective_End_Date__c){
                        
                        if(caseCreationCalcDt == System.Today()){
      
                          // Add the Contract Line Record to Return List  
                          contractLineListAfter2ndPhase.add(eachContractLineRec);
      
                          break;
                        }
      
                        // Add Months and Day for Matching Next Case Creation Date
                        caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreqMonth).addDays(subseqntFreqDays);
      
                    }  // End of While Loop
                    
                } // End of Else Part - for 14 days
                
            } // End of For Loop
            
            } // End Of If Condn
            else
            {
              // Variable to store the Default KONA Case Freq
              Integer defaultKonacaseFreq;
                
                // Variable to store EESD(Earliest Effective Start Date)
                Date ESSD = null;
                
                // Variable to store LEED(Latest Effective End Date)
                Date LEED = null;
                
                // String to store all Concatenated Contract Details
                string allContractDetNames = ',';
                
                Merge_Contract_Detail__c oneContractLineRec = new Merge_Contract_Detail__c();
                
                // Loop for Each Contract 
                for(Merge_Contract_Detail__c eachContractLineRec : allRelatedContrctLns){
                
                    ESSD = eachContractLineRec.Original_Contract_Id__r.Effective_Start_Date__c;
                    LEED = eachContractLineRec.Original_Contract_Id__r.Effective_End_Date__c;
                    allContractDetNames +=  ',' +eachContractLineRec.Name;
                    oneContractLineRec = eachContractLineRec;
              }
            
            // Setting allContractDetNames Value
            allContractDetNames = (allContractDetNames.length() >=79) ? allContractDetNames.substring(2,79) : allContractDetNames.substring(2);
            oneContractLineRec.Name = allContractDetNames;
            
            // List to store SMP Case Creation Freq from Custom Setting
          List<string> KONACaseFreq = SC_Autogen_Running_Freq__c.getValues('KONA').Cron_Time__c.split(',');
            
            // Calculate No Of Year
            countNoOfyear = ESSD.daysBetween(system.today())/365;
    
            // Set Effective Start Date by adding no of Year
            caseCreationCalcDt = ESSD.addMonths(12*countNoOfyear);
            
      // Loop for each PPSM Record from Custom setting
      for(string eachCaseFreq : KONACaseFreq){
  
        // Assigning Case Freq Value
        defaultKonacaseFreq = Integer.valueOf(eachCaseFreq);
        
        if(caseCreationCalcDt.addDays(defaultKonacaseFreq) == system.Today() && caseCreationCalcDt.addDays(defaultKonacaseFreq) <= LEED){
  
          // Add the Contract Line Record to Return List  
          contractLineListAfter2ndPhase.add(oneContractLineRec);
        
          break;  
        }
        
      }
            
                
        } // End of Else Part
            
            // Return the List
            return contractLineListAfter2ndPhase;
      }*/
      
      // Method - 25: Method for Calculating Case Creation Criteria for KONA COB Use Case
      // Called from - KONA_Calculation_COB method
      public void CaseCalculation_KONA_COB(List<Merge_Contract_Detail__c> contractLineList_KONA_COB, 
                   Map<ID,Merge_Contract_Detail__c> contractHDID_LineItm_Map,
                   Map<Id,Id> allKSDCaseMap ){
      
          // Map to store Contract Line - Case Title (Kona with KSD Integration)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_withKSD = new Map<Merge_Contract_Detail__c,string>();
            
            // Map to store Contract Line - Case Title (Kona without KSD Integration)
            Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap_withoutKSD = new Map<Merge_Contract_Detail__c,string>();
            
            // Fetch all the KSD-COB cases for related KONA Contracts
            for(case eachKSDCase : [select Id,contract__c from case where contract__c = :contractHDID_LineItm_Map.keyset() and Autogen_UseCase__c = 'KSD-COB' and 
                    Status != 'Closed']){
                    
              allKSDCaseMap.put(eachKSDCase.contract__c, eachKSDCase.Id);       
            }
            
            // Loop for each Contract Header
            for(Id eachContractHDID : contractHDID_LineItm_Map.keyset()){
            
              // Condition to check if already COB case created?
              if(contractHeaderId_KONACOBCreatedMap_ACHD.get(eachContractHDID) == null){
              
                if(allKSDCaseMap.get(eachContractHDID) != null)
                  contractLine_CaseTitleMap_withKSD.put(contractHDID_LineItm_Map.get(eachContractHDID), 'Managed Kona Site Defender Service :: Customer Onboarding :: ');
                else
                  contractLine_CaseTitleMap_withoutKSD.put(contractHDID_LineItm_Map.get(eachContractHDID), 'Managed Kona Site Defender Service :: Customer Onboarding :: ');
                
                // Adding Contract Header Id for Task Creation
                contractIdTaskCreateList.add(eachContractHDID);
              }
            }
            
        // Call to Case Creation Method for - Kona with KSD Integration
            if(contractLine_CaseTitleMap_withKSD.size() > 0){
                CreateCase(contractLine_CaseTitleMap_withKSD,'KONA-COB-WithKSD');
            }
            
            // Call to Case Creation Method for - Kona without KSD Integration
            if(contractLine_CaseTitleMap_withoutKSD.size() > 0){
                CreateCase(contractLine_CaseTitleMap_withoutKSD,'KONA-COB-WithoutKSD');
            }
            
            
      }
      
    // Method - 26: Method for Case Creation - Common Method for all Use Case
    // Called from - All CaseCalculation method
    public void CreateCase(Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap, string useCase)
    {
        
        System.debug('case create method' + contractLine_CaseTitleMap + ' : ' + usecase);
        // Fetching Record Types for Case Object
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id setRecordTypeId ;
            
        // Case for 2 Record
        case eachCaserec; 
           
        
        // Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        // Loop for each Contract for Case Creation
        for(Merge_Contract_Detail__c eachCntrctLnRec : contractLine_CaseTitleMap.keyset())
        {
            // Call to RecordType Calculation Method 
            setRecordTypeId = recordTypeCalculation(eachCntrctLnRec,useCase,rtMap);
                   
            eachCaserec = new Case();
           
              
            // Setting Assignment Rule
            //if(! (useCase == 'KDD') )
            eachCaserec.setOptions(dmo);
                
            eachCaserec.RecordTypeId            = setRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.Service__c              = serviceCalculation(useCase, rtMap, setRecordTypeId ,eachCntrctLnRec);
            eachCaserec.Request_Type__c         = RequestTypeCalculation(useCase, rtMap, setRecordTypeId, eachCntrctLnRec );
            eachCaserec.Severity__c             = (autogenUseCase_FullRec.get(useCase) == null) ? '3' : autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= (autogenUseCase_FullRec.get(useCase) == null) ? true : autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = subjectCalculation(contractLine_CaseTitleMap.get(eachCntrctLnRec), eachCntrctLnRec, useCase);
            eachCaserec.Description             = descriptionCalculation(useCase, eachCntrctLnRec);
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.origin                  = originCalculation(useCase, rtMap, setRecordTypeId);
            eachCaserec.Request_Sub_Type__c     = (useCase == 'NES') ? 'Named Enhanced Support' : null;
            //eachCaserec.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (useCase == 'PLXC-COB' ? 'PLX Connect' : null);
            eachCaserec.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).PS_Product__c;
            
            if(useCase == 'PLXC-COB' || useCase == 'PLXR-COB')
            	eachCaserec.Case_Product__c =    accountPSProduct_CaseProductMap.get(eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c + '-'+useCase);
            
            eachCaserec.Sub_Type__c             = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Sub_Type__c;
            eachCaserec.Service_Category__c     = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Service_Category__c; 
            eachCaserec.Work_Type__c            = (setRecordTypeId == rtMap.get('AMG').getRecordTypeId() || setRecordTypeId == rtMap.get('Technical').getRecordTypeId()) ? 'Proactive' : null; 
            eachCaserec.Autogen_UseCase__c      = useCase;
            eachCaserec.Validation_Override__c  = true;
            
            
            
        
           // Adding Case Record to List
           caseCreateList.add(eachCaserec);
           
           

        }
    }
    
    
    //Method to create 2 cases for ESESP-1129
    public void CreateCasePP(Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap, string useCase)
    {
    
         System.debug('case create method' + contractLine_CaseTitleMap + ' : ' + usecase);
        // Fetching Record Types for Case Object
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id setRecordTypeId ;
        
        // Case for each Record
        case eachCaserec;  
        case eachCaserec1; 
        
        // Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        
        for(Merge_Contract_Detail__c eachCntrctLnRec : contractLine_CaseTitleMap.keyset())
        {
        
             // Call to RecordType Calculation Method 
            setRecordTypeId = recordTypeCalculation(eachCntrctLnRec,useCase,rtMap);
            
            //Subject List
            String getSubject =  autogenUseCase_FullRec.get(useCase).Subject__c;
            List<String> SubjectList = getSubject.split(',');
            
            //Service List
            String getService = autogenUseCase_FullRec.get(useCase).Service__c;
            List<String> ServiceList = getService.split(',');
            
            eachCaserec = new Case();
            eachCaserec1 = new Case();
            //Creating Case 1
            eachCaserec.setOptions(dmo);
                
            eachCaserec.RecordTypeId            = setRecordTypeId;
            eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec.Service__c              = ServiceList[0];
            eachCaserec.Request_Type__c         = RequestTypeCalculation(useCase, rtMap, setRecordTypeId, eachCntrctLnRec );
            eachCaserec.Severity__c             = (autogenUseCase_FullRec.get(useCase) == null) ? '3' : autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec.Do_Not_Show_in_Portal__c= (autogenUseCase_FullRec.get(useCase) == null) ? true : autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec.Subject                 = SubjectList[0]+' '+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec.Description             = descriptionCalculation(useCase, eachCntrctLnRec);
            eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec.origin                  = originCalculation(useCase, rtMap, setRecordTypeId);
            eachCaserec.Request_Sub_Type__c     = (useCase == 'NES') ? 'Named Enhanced Support' : null;
            //eachCaserec.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (useCase == 'PLXC-COB' ? 'PLX Connect' : null);
            eachCaserec.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).PS_Product__c;
            eachCaserec.Sub_Type__c             = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Sub_Type__c;
            eachCaserec.Service_Category__c     = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Service_Category__c; 
            eachCaserec.Work_Type__c            = (setRecordTypeId == rtMap.get('AMG').getRecordTypeId() || setRecordTypeId == rtMap.get('Technical').getRecordTypeId()) ? 'Proactive' : null; 
            eachCaserec.Autogen_UseCase__c      = useCase;
            eachCaserec.Validation_Override__c  = true;
            
            
            //Creating second case
            eachCaserec1.setOptions(dmo);
                
            eachCaserec1.RecordTypeId            = setRecordTypeId;
            eachCaserec1.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
            eachCaserec1.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
            eachCaserec1.Service__c              = ServiceList[1];
            eachCaserec1.Request_Type__c         = RequestTypeCalculation(useCase, rtMap, setRecordTypeId, eachCntrctLnRec );
            eachCaserec1.Severity__c             = (autogenUseCase_FullRec.get(useCase) == null) ? '3' : autogenUseCase_FullRec.get(useCase).Severity__c;
            eachCaserec1.Do_Not_Show_in_Portal__c= (autogenUseCase_FullRec.get(useCase) == null) ? true : autogenUseCase_FullRec.get(useCase).Do_not_Show_in_Portal__c;
            eachCaserec1.Subject                 = SubjectList[1]+' '+eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            eachCaserec1.Description             = descriptionCalculation(useCase, eachCntrctLnRec);
            eachCaserec1.Contract_Detail__c      = eachCntrctLnRec.Name;
            eachCaserec1.origin                  = originCalculation(useCase, rtMap, setRecordTypeId);
            eachCaserec1.Request_Sub_Type__c     = (useCase == 'NES') ? 'Named Enhanced Support' : null;
            //eachCaserec.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (useCase == 'PLXC-COB' ? 'PLX Connect' : null);
            eachCaserec1.PS_Product__c           = (useCase == 'KSD-COB') ? 'Kona Site Defender' : (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).PS_Product__c;
            eachCaserec1.Sub_Type__c             = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Sub_Type__c;
            eachCaserec1.Service_Category__c     = (autogenUseCase_FullRec.get(useCase) == null) ? null : autogenUseCase_FullRec.get(useCase).Service_Category__c; 
            eachCaserec1.Work_Type__c            = (setRecordTypeId == rtMap.get('AMG').getRecordTypeId() || setRecordTypeId == rtMap.get('Technical').getRecordTypeId()) ? 'Proactive' : null; 
            eachCaserec1.Autogen_UseCase__c      = useCase;
            eachCaserec1.Validation_Override__c  = true;
            
           caseCreateList.add(eachCaserec);
           caseCreateList.add(eachCaserec1);
            
             
        }
        
        
        
    
    }
    
    /*
    //Method to create Case for every line Item -Plus
    public void CreateCasePlus(List<Merge_Contract_Detail__c> ContractLine_Plus, string useCase)
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
    */
    
    /*    
    public void CreateCaseAdvanced(List<Merge_Contract_Detail__c> ContractLine_Advanced, string useCase){
        
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
        
        system.debug('CaseCreationList dayifkhsd :'+CaseCreationList);
        
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
                advancedCaseCreateList.add(CreateCaseAdvancedMultiple(eachCntrctLnRec, 'Professional Services', useCase, RTSubMap, RTDescMap));
                advancedCaseCreateList.add(CreateCaseAdvancedMultiple(eachCntrctLnRec, 'Technical', useCase, RTSubMap, RTDescMap));
                system.debug('advancedCaseCreateList inside method : '+advancedCaseCreateList.size());
                system.debug('CLI Detailc : '+eachCaserec.Contract_Detail__c);
                parentContractDetailCaseMap.put(eachCaserec.Contract_Detail__c,advancedCaseCreateList);
                system.debug('parentContractDetailCaseMap : '+parentContractDetailCaseMap);
            }
        }
    }
    */
    
    /*
    public Case CreateCaseAdvancedMultiple(Merge_Contract_Detail__c eachCntrctLnRec, String recTypeName, string useCase, Map<String,String> RTSubMap, Map<String,String> RTDescMap){
        system.debug('inside CreateCaseAdvancedMultiple');
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
    */
    
    /*
    //Method to create child cases for Advanced Product - ESESP-2045
    public void createAdvancedChildCases(List<Case> caseCreateList){
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
    */
    
    /*
    //Method to create child cases for Product Management Product - ESESP-2045
    public void CreateCasePMO(List<Merge_Contract_Detail__c> ContractLine_Advanced, string useCase){
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
    */
    
    
      // Method - 27: Method for Record Type Calculation
      // Called from - CreateCase method
    public Id recordTypeCalculation (Merge_Contract_Detail__c eachCntrctLnRec, string useCase, Map<String, Schema.RecordTypeInfo> rtMap)
    {
        // variable to store Account Geography
        String accountGeo;
            
        // Stores the Calculated RecordType
        Id setRecordTypeId ;
            
        // If Usecase = RUS or QBR, then do Geo calculation else not
        accountGeo = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Geography_Formula__c;
        setRecordTypeId = ( ((useCase == 'RUS') && accountGeo <> Null && (DGRATMapping.Geography_APJ__c.containsIgnoreCase(accountGeo) || DGRATMapping.Geography_EMEA__c.containsIgnoreCase(accountGeo))) || useCase == 'QBR') ?
                  rtMap.get('AMG').getRecordTypeId() :
                  rtMap.get('Professional Services').getRecordTypeId();
    
        // For Use Case = SMP , PPSM, GDS, MDS, KONA, PSE, TAS, PLXC, PLXR, PS-S 
        if(useCase.contains('SMP') || useCase == 'PPSM' || useCase.contains('MDS') || useCase.contains('KSD') || useCase == 'KONA' || useCase == 'KONA-COB-WithKSD' || useCase == 'KONA-COB-WithoutKSD' || useCase == 'KDD' || useCase == 'PSE-COB' || useCase == 'TAS-COB' || useCase == 'PLXC-COB' || useCase == 'PLXR-COB' || useCase == 'PSS-COB')
        {
            setRecordTypeId = rtMap.get('Professional Services').getRecordTypeId();
        }
        // For Use Case = NES      
        else if(useCase == 'NES')
        {
            setRecordTypeId = rtMap.get('AMG').getRecordTypeId();
        }
      
      
        else
        {
        // If any exception is there, no need to handle
            try
            {
                setRecordTypeId = rtMap.get(autogenUseCase_FullRec.get(usecase).Case_Record_Type__c).getRecordTypeId();
            } 
            catch(exception e){}
        }

        return setRecordTypeId;
    }
      

    // Method - 28: Method for Service Value Calculation
    // Called from - All CreateCase method
    public string serviceCalculation (string useCase, Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId, Merge_Contract_Detail__c eachCntrctLnRec)
    {
  
        // variable for setting service
        string setServiceval;
        
        if(setRecordTypeId == rtMap.get('AMG').getRecordTypeId() && (useCase == 'RUS' || useCase == 'PPSM'))
        {
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('AMG').ServiceVal__c;
        }
        else if (useCase == 'RUS' || useCase == 'PPSM')
        {
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').ServiceVal__c ; 
        }
        
        //For SMP Non Security RC ESESP-1157
        else if (useCase=='SMP-NonSecurity-RC')
        {
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('SMP-NonSecurity-RC').ServiceVal__c ; 
        }
  
        // For Use Case = SMP-Security      
        else if(useCase.contains('SMP-Security'))
        {
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').ServiceVal__c ;
        }
  
        // For Use Case = SMP NonSecurity     
        else if(useCase.contains('SMP-NonSecurity'))
        {
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').ServiceVal__c ;
        }
      
        else if (useCase.contains('SOA') || useCase.contains('GDS') || useCase.contains('PSE-COB') || useCase.contains('TAS-COB') || useCase.contains('PLXC-COB') || useCase.contains('PLXR-COB') || useCase.contains('RRS') || useCase.contains('PSS-COB') || useCase.contains('PPSOPSM'))
        {
            setServiceval = autogenUseCase_FullRec.get(useCase).Service__c ; 
        }
      
        else
        {
           setServiceval = SC_Serv_ReqTyp_value__c.getValues(useCase).ServiceVal__c ;  
        }
        
        return setServiceval;
    }
      
    // Method - 29: Method for Request Type Calculation
    // Called from -  CreateCase method
    public string RequestTypeCalculation (string useCase, Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId, Merge_Contract_Detail__c eachCntrctLnRec)
    {
        // variable for setting RequestType
        string setReqTypeval;
            
        if(setRecordTypeId == rtMap.get('AMG').getRecordTypeId() && (useCase == 'RUS' || useCase == 'PPSM'))
        {
            setReqTypeval = SC_Serv_ReqTyp_value__c.getValues('AMG').RequestTypeVal__c;
        }
          
        else if (useCase == 'RUS' || useCase == 'PPSM')
        {   
            setReqTypeval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').RequestTypeVal__c;
        } 
          
        // For Use Case = SMP      
        else if(useCase.contains('SMP'))
        {
            setReqTypeval = (useCase == 'SMP-Security-COB' || useCase == 'SMP-NonSecurity-COB') ? 'Customer Onboarding' : SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').RequestTypeVal__c;
        }
        
        else if (useCase.contains('SOA') || useCase.contains('GDS') || useCase.contains('PSE-COB') || useCase.contains('TAS-COB') || useCase.contains('PLXC-COB') || useCase.contains('PLXR-COB') || useCase.contains('RRS') || useCase.contains('PSS-COB') || useCase.contains('PPSOPSM')|| useCase.contains('PPPPSC')|| useCase.contains('PPPPMK')|| useCase.contains('PPMKPSM'))
        {
            setReqTypeval = autogenUseCase_FullRec.get(useCase).Request_Type__c ; 
        }

        else
        {   
            setReqTypeval = SC_Serv_ReqTyp_value__c.getValues(useCase).RequestTypeVal__c;
        }

        return setReqTypeval;
    }
      
    // Method - 30: Method for Subject Calculation
    // Called from - CreateCase method
    public string subjectCalculation(string caseTitle, Merge_Contract_Detail__c eachCntrctLnRec, string useCase)
    {  
        // Setting Subject
        string setSubject;
            
        setSubject = caseTitle + ' : ' + eachCntrctLnRec.Product__c + ' : ' + eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
                      
        // For Use Case = SMP      
        if(useCase.contains('SMP') || useCase == 'NES' || useCase == 'KONA' || useCase.contains('KONA-COB-') || useCase == 'KDD' || useCase.contains('GDS') || useCase.contains('MDS') || useCase.contains('KSD') || useCase.contains('SOA') || useCase.contains('PSE-COB') || useCase.contains('TAS-COB') || useCase.contains('PLXC-COB')  || useCase.contains('PLXR-COB') || useCase.contains('RRS') || useCase.contains('PSS-COB'))
        {
            setSubject = caseTitle + ' ' + eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
        }
    
        setSubject = (setSubject.length() > 254) ? setSubject.substring(0,254) : setSubject;    
        return setSubject;
    }
      
    // Method - 31: Method for Description Calculation
    // Called from - CreateCase method
    public string descriptionCalculation(string useCase, Merge_Contract_Detail__c eachCntrctLnRec)
    {
        // Setting Subject
        string setDescription = null;
        setDescription = 'This notification states that it is time to conduct a Technical Configuration Review.\n' +
              'If a Technical Configuration Review has been conducted within the last six months or ' + 
          'the Customer has conducted more than their contracted limit within the year ' +
          '(which is 2 by default) please close this case.\n' +
          'Otherwise, please notify the Professional Services Team on the account that it ' +
          'is time to conduct a Technical Configuration Review, by following the ' +
          '“Technical Configuration Review Request” process located here:\n' +
          'https://agora.akamai.com/wiki/Contacting_Professional_Services_Process#Request_Process';
        
        // For Use Case = QBR
        if(useCase == 'QBR')
        {
      
          setDescription = 'This is a proactive Case to do the quarterly business review with this ' +
            eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Support_Level__c +
            ' customer.\n' + 'The final report should be attached to the Case and the Case should be ' +
            ' closed once the review has been completed.\n' + 'The root cause should be updated to ' +
            'indicate whether the report was only shared by e-mail or reviewed with the customer.\n ' +
            'For more information:\n' + 'https://agora.akamai.com/wiki/GSS_products_priority';
        }
      
        // For Use Case = SMP  Security    
        else if(useCase.contains('SMP-Security')){
    
          setDescription = (useCase == 'SMP-Security-COB') ? 
                    'Service Management On-boarding' :
                    'Complete the Security Configuration Review for : ' + eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
      
        }
        // For Use Case = SMP Non Security     
        else if(useCase.contains('SMP-NonSecurity')){ 
    
          setDescription = (useCase == 'SMP-NonSecurity-COB') ? 
                    'Please refer to the detailed SMP 2.0 on-boarding steps located at:\n https://agora.akamai.com/wiki/GSS_products_SMP2_fulfillment#Onboarding:' :
                    'Complete the Optimization Schedule for : ' + eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
      
        }
     
     /*ESESP - 1356
       // For Use Case = NES      
        else if(useCase == 'NES')
        {
    
            setDescription = 'Please refer to the NES Onboarding process at:\n' +  
              'https://agora.akamai.com/wiki/CCare_Implementation#Named_Enhanced_Support_for_existing_customers';
        }
        
        */
     
       /* For Use Case = KONA
       else if(useCase == 'KONA'){
      setDescription = 'Managed Kona Security Review';
       } Removed as part of CR 3283891 */
     
       // For Use Case = KONA-COB-WithKSD
       else if(useCase == 'KONA-COB-WithKSD')
       {
            setDescription = 'Please refer to the Managed Kona Site Defender Service customer onboarding steps located at:  \n' + 
            'https://gsd.akamai.com/wiki/display/GSGS/Managed+Kona+Onboarding \n\n' + 
            'Please note that, based on existence of an open Kona Site Defender onboarding case (see “Related Cases” section), it is likely that Kona Site Defender needs to be integrated for this customer.';
       }
       
       // For Use Case = KONA-COB-WithoutKSD
       else if(useCase == 'KONA-COB-WithoutKSD')
       {
            setDescription = 'Please refer to the Managed Kona Site Defender Service customer onboarding steps located at:  \n' + 
            'https://gsd.akamai.com/wiki/display/GSGS/Managed+Kona+Onboarding';
       }
       
       // For Use Case = KDD
       else if(useCase == 'KDD')
       {
            setDescription = 'Please refer to the Kona DDoS Defender customer onboarding steps located at: \n' + 
                'https://gsd.akamai.com/wiki/display/GSGS/Kona+DDoS+Defender+-+On-boarding+Process';
       }
       
       // For Use Case = GDS-COB
       /*
       else if(useCase == 'GDS-COB'){
      setDescription = 'Please refer to the Guided Delivery Service customer onboarding steps located at: \n' +
                'https://agora.akamai.com/wiki/Guided_Delivery_Service_Provisioning_Body_of_Knowledge#Client_Onboarding';
       }
       
       // For Use Case = GDS-RC
       else if(useCase == 'GDS-RC'){
      setDescription = 'Please refer to the Guided Delivery Service Quarterly Insight steps located at: \n' +
              'https://agora.akamai.com/wiki/Guided_Delivery_Service_Provisioning_Body_of_Knowledge#Quarterly_Insight';
       }*/
       
       // For Use Case = MDS-COB
       else if(useCase == 'MDS-COB')
       {
            setDescription = 'Please refer to the Managed Delivery Service customer onboarding steps located at: \n' +
                'https://agora.akamai.com/wiki/Managed_Delivery_Service_Provisioning_Body_of_Knowledge#Client_Onboarding';
       }
       
       // For Use Case = KSD-COB
       else if(useCase == 'KSD-COB')
       {
            setDescription = 'Please refer to the Kona Site Defender customer onboarding/integration steps located at: \n' +
                'https://gsd.akamai.com/wiki/display/GSGS/Kona+Site+Defender+Services';
       }
        else if(useCase == 'RRS-Parent'){
            setDescription = contractID_CaseDesc_RRSMap.get(eachCntrctLnRec.Original_Contract_Id__c);
    }
       
       
       else
       {
            try
            {
                setDescription = autogenUseCase_FullRec.get(useCase).Description__c;
                
                // Additional Calculation for SOA Parent
                if(useCase == 'SOA-Parent')
                {
                
                  if(contractHeaderId_SOAMainCaseUpdateMap.get(eachCntrctLnRec.Original_Contract_Id__c) != null)
                        setDescription += '\n' + contractHeaderId_SOAMainCaseUpdateMap.get(eachCntrctLnRec.Original_Contract_Id__c);
                }
                
                // replacing Account Name
                setDescription = setDescription.replace('[Insert Account Name]', eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name); 
          }

          catch(exception e){}
        }
        return setDescription;
    }
      
    // Method - 32: Method for Origin Calculation
    // Called from - CreateCase method
      public string originCalculation(string useCase,Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId)
      {
          // Setting Default Value Of Case Origin
          string setOrigin = 'Autogen';
           
        // Setting Origin Field for GDS,MDS,KSD,KONA COB,KDD Use Case
        if (useCase.contains('MDS') || useCase.contains('KSD') || useCase == 'KONA-COB-WithKSD' || useCase == 'KONA-COB-WithoutKSD' || useCase == 'KDD' )
        {
            setOrigin = 'SF.com';
        }

        else 
        {
            try
            {
                setOrigin = autogenUseCase_FullRec.get(useCase).Origin__c;
            }
            catch(exception e){}
        }

        return setOrigin; 
    }
        
      // Method - 33: Method for Updating all Contract Lines for SMP,NES,GDS Products with IS COB Created = True
      // Called from - SMP_Calculation,NES_Calculation, GDS_Calculation method
      
      public void updateAllContractLines_ACHD(Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap)
      {
    
        System.debug('Eneterd ACHD update!');
        System.debug('Line Case Map : ' + contractLine_CaseTitleMap);
        // Record Variable to Update for Autogen_Contract_Header_Detail__c Object
        Autogen_Contract_Header_Detail__c eachACHDRec;
        
        // Designing the Key
        string key;
        
        // Loop for each Contract Line
        if(contractLine_CaseTitleMap != null)
        {
            for(Merge_Contract_Detail__c eachCntrctLnRec : contractLine_CaseTitleMap.keyset())
            {
                System.debug('Each line item in map ' + eachCntrctLnRec);
                key = eachCntrctLnRec.Id;
                if(contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID) <> null && contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID).Is_COB_Created__c == false)
                {
                    eachACHDRec = new Autogen_Contract_Header_Detail__c(Id=contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRec.ID).Id);
            eachACHDRec.Is_COB_Created__c = True;
            allContractLnsUpdateMap.put(key,eachACHDRec);
            System.debug('Each ACHD record isCOB : ' + eachACHDRec.Is_COB_Created__c);
            System.debug('Each ACHD record : ' + eachACHDRec);

                }
            }
        }
        //system.debug('..cob map=' + contractDetailId_COBCreatedMap_ACHD.keyset());
     //       if(contractLineCaseDateMap != null)
     //{
     //       for(Id eachCntrctLnRecId : contractLineCaseDateMap.keyset()){
            
     //         key = eachCntrctLnRecId;
     //         if(allContractLnsUpdateMap.get(key) == null){
              
     //               if(contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRecID) != null){
     //           eachACHDRec = new Autogen_Contract_Header_Detail__c(Id=contractDetailId_COBCreatedMap_ACHD.get(eachCntrctLnRecID).Id);
          //eachACHDRec.Next_Case_Create_Date_for_GDS_RC__c = contractLineCaseDateMap.get(eachCntrctLnRecId);
     //           allContractLnsUpdateMap.put(key,eachACHDRec);
     //               }
     //         }
     //         else
     //         {
     //           eachACHDRec = allContractLnsUpdateMap.get(key);
     //               eachACHDRec.Next_Case_Create_Date_for_GDS_RC__c = contractLineCaseDateMap.get(eachCntrctLnRecId);
     //           allContractLnsUpdateMap.put(key,eachACHDRec);
                
     //         }
              //system.debug('..contractLineNextCaseDateMap Next Value..' + allContractLnsUpdateMap);
            //}
        //}
    }
    
    /*
    //Update ACHD for Plus CLIs ESESP-2046
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
    */
    
      
      // Method - 34: Method for Task Creation Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      public void TaskCreation_Calculation(List<Case> allCreatedCaseList){
            
            // Map to store AutogenUseCase - List of Cases
            Map<string, List<Case>> useCase_CaseListMap = new Map<string, List<Case>>();
            
            // String to store the Key(Autogen UseCase Name)
            string usecaseKey;
            
            // List to store all Cases per UseCase
            List<Case> useCase_CaseList;
            
            // Loop for Case Created List to filter for which Case Task is to be created
            for(case eachCaserec : allCreatedCaseList){
            
              if(contractIdTaskCreateList.contains(eachCaserec.Contract__c)){
              
                // setting the Key Value
                usecaseKey = eachCaserec.Autogen_UseCase__c;
                
                if(useCase_CaseListMap.get(usecaseKey) == null){
                
                  useCase_CaseList = new List<Case>();
                  
                }
                else
                {
                  useCase_CaseList = useCase_CaseListMap.get(usecaseKey);
                  
                }
                useCase_CaseList.add(eachCaserec);
                useCase_CaseListMap.put(usecaseKey,useCase_CaseList);
              }
              
            }
            
            // Loop for each UseCase
            for(string eachUseCase : useCase_CaseListMap.keyset()){
            
              createTask(useCase_CaseListMap.get(eachUseCase),eachUseCase);
            }
            
            
      
      }
      
      // Method - 35: Method for Creating Task
      // Use Case - SMP-NonSecurity-COB, GDS-COB, GDS-RC, MDS-COB,KDS,KONA-COB
      // Added use case Professional Services - Enterprise and TAS
      public void createTask(List<Case> caseTaskCreateListIncoming, string useCase)
      { 
      
        // Fetch the Data from Custom Setting - AutoGencase - Activity
            List<SC_AutoGencase_Activity__c>  allActivityValues = new List<SC_AutoGencase_Activity__c>();
            for(SC_AutoGencase_Activity__c eachActivityRec : SC_AutoGencase_Activity__c.getall().values()){
            
              if(eachActivityRec.UseCase_Type__c == useCase){ 
              
                allActivityValues.add(eachActivityRec);
              }
            }
            
            // Fetching Service Activity record Type from Task Obj
            Id setRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
      
          // Task record used inside Loop for each Record
          Task newtask;
      
          // Variable to store Activity Date
          DateTime setActdate;
          
          // 1 Day Milli sec Value - For Business Hour Calculation
          Long milliSecValuefor1Day = 86400000;
          
          // Variable to get No Of Days for Setting Activity Due date
          Integer getNoOfDaysForTask;
        
          // Loop for each Case Id
          for (case eachCaseRec : caseTaskCreateListIncoming){
        
              // Loop for each Task Record from Custom setting
                  for(integer i =0 ; i < allActivityValues.size() ; i ++){
                
                      // Derivation for Activity Date
                      getNoOfDaysForTask = (allActivityValues[i].Activity_Due_date__c == NULL) ? 1 : 
                              Integer.valueOf(allActivityValues[i].Activity_Due_date__c);
                      
                      // Calculating Business Hour        
                      setActdate  = BusinessHours.add(bh.id, system.now(), milliSecValuefor1Day * getNoOfDaysForTask); 
                
                      newtask = new Task();
                      newtask.Subject                  =   allActivityValues[i].Activity_Name__c;
                      newtask.Description              =   allActivityValues[i].Activity_Details__c;
                      newtask.ActivityDate             =   Date.valueOf(setActdate);   
                      newtask.Type__c                  =   'Task';
                      newtask.Status                   =   'Not Started';
                      newtask.WhatId                   =   eachCaseRec.Id;
                      newtask.OwnerId                  =   userRec.Id;
                      newtask.RecordTypeId             =   setRecordTypeId;
            
                      // Adding to List
                      taskCreateList.add(newtask);
                }
          }
        
          
      }
      
      // Method - 36: Method for Update Case Calculation
      // Called from - main_RUS_PPSM_QBR_Method method
      // Use Case = KSD
      public void updateCaseMethod(List<case> allCaseCreateList, Map<Id,Id> allKSDCaseMap){

    // List of Cases for Update
    List<case> allCaseForUpdate = new List<case>();
  
    // Map to store Contract Id + KONA COB Case Id
    Map<Id, Id> contractId_KONACOBCaseIdMap = new Map<Id, Id>();
  
    // Loop for setting contractId_KONACOBCaseIdMap Map
    for(case eachKONACase : allCaseCreateList){
  
      contractId_KONACOBCaseIdMap.put(eachKONACase.Contract__c, eachKONACase.Id);
    }
  
    // For Individual Case Record
    Case eachKSDCaseUpdate;
  
    // Loop for each KSD Case
    for(Id eachContractId : allKSDCaseMap.keyset()){
  
      // Condition to prevent Case Update for Subsequent Run
      if(contractId_KONACOBCaseIdMap.get(eachContractId) != null){
      
        eachKSDCaseUpdate = new Case(Id=allKSDCaseMap.get(eachContractId),
                  ParentId = contractId_KONACOBCaseIdMap.get(eachContractId),Validation_Override__c = True);
        allCaseForUpdate.add(eachKSDCaseUpdate);
      }
    }
  
    // Updating all the KSD Cases
    if(allCaseForUpdate.size() > 0)
      Update allCaseForUpdate;
  }
        
}