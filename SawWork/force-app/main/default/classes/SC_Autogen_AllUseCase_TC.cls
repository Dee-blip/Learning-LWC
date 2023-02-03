/*=====================================================================================================+
    Class name          :   SC_Autogen_AllUseCase_TC 
    Author              :   Himanshu Kar
    Created             :   22-APR-14
    Purpose             :   This test class is used to cover code for below Components
                            1. SC_Autogen_COB_Batch, SC_Autogen_COB_Support 
                            3. SC_Autogen_TCR_WAF_Batch, SC_Autogen_TCR_WAF_Support
                            4. SC_Autogen_RUS_PPSM_QBR_Batch, SC_Autogen_RUS_PPSM_QBR_Support
                            5. SC_Sync_Contract_Header_Detail_Batch
                            6. SC_Autogen_PIHC_Batch - 
                            7. SC_Autogen_ExistingCOB_Batch, SC_Autogen_ExistingCOB_Support
                            8. AutogenJobTrigger
                            9. SC_EntitlementTrigger
                            10. SC_PIVCReportClass
                            
    Last Modified Developer     Purpose            
    ============= =========     =======
    22-APR-14     Himanshu      Initial Development 
    28-JUL-14     Himanshu      Added RUS,PPSM,QBR and SMP Use case
    20-AUG-14     Himanshu      Added NES Use case
    03-NOV-14     Himanshu      Added KONA Use Case
    13-NOV-14     Himanshu      Added KONA - On Boarding Use Case
    03-FEB-15     Himanshu      Added SAAS Use Case
    05-FEB-15     Kunal         Added PIHC use Case
    04-Mar-15     Akhila        Added PSCaseRouting test case
    04-May-16     Himanshu      Added GSD,MDS,KSD,SOA use cases
    14-Jun-16     Himanshu      Added BOCC Use Case
    12-Dec-16     Himanshu      Increased the code coverage
    05-Jul-17     Vamsee        Added RRS Use Case
    02-Feb-18     Vamsee        Removed Test Methods for PIVC & PIHC 
    25-Jun-18     Sumanth       Added Use case for Protect & Perform -ESESP-1129
    02-May-19     Aditya        Added use case for Premium 3.0 Autogen cases
    06-May-19     Sumanth       Added use case for Plus Autogen Cases
    03-Jun-19     Vikas         Added use case for Advanced and PMO Autogen Cases
    05-Aug-19     Sumanth       Added method for PLUS Advanced Batch Class
    08-May-20     Sharath       Commenting out the BOCC Autogen use case as part of ESESP-3547
    29-Jun-20     Pinkesh       ESESP-3254: Added usecase for Event Support products under PLUS Advanced Batch Class
+=====================================================================================================*/

@isTest(seeAllData=false)
public class SC_Autogen_AllUseCase_TC
{
    // For Account Record
    public static Account accRec;
    
    // For Account Record
    public static Account PIVCAccRec;
    
    // For Contract Header Record
    public static List<Merge_Contract_Header__c> contrctList;
    public static list<Autogen_Contract_Header_Detail__c> autogenContHeadList1 = new List<Autogen_Contract_Header_Detail__c>();
    
    // Method-1: Creating Test Data for Account + Contract Header
    public static void testDataSetup()
    {    
        utilTestClass.createCustomSettings();
        utilTestClass.SC_Autogen_init_Method();
        //utilTestClass.createData_SC_SupportEmail();
        //utiltestClass.createData_SC_Autogen_Run_Freq();
        //utiltestClass.createData_SC_Autogen_Case_Freq();
        
        List<SC_Autogen_Job_Enable_Disable__c> csList = new List<SC_Autogen_Job_Enable_Disable__c>(); 
            List<String> usecaseList = new List<String>{'RUS','PPSM','QBR','SMP','KONA-COB','KDD','MDS','KSD'};
         SC_Autogen_Job_Enable_Disable__c eachED;
        for(String eachString : usecaseList){
            eachED = new SC_Autogen_Job_Enable_Disable__c();
            eachED.Name = eachString;
            eachED.IsActive__c = True;
            csList.add(eachED);
        }
        Insert csList;
        
        List<String> useCaseName = new List<String>{'PLXR-COB', 'RRS-Parent', 'RRS-WebAppProtector', 'RRS-BotManager', 'PSS-COB', 'PLXC-COB', 'SOA-Parent', 'SOA-BotManager', 'SOA-KSD', 'PPPPSC', 'PPPPMK', 'PPMKPSM', 'PPSOPSM', 'SOA-Prolexic', 'SOA-WebAppFirewall', 'GDS-RC', 'GDS-COB', 'SOA-WebAppProtector', 'PSE-COB', 'TAS-COB'};
        List<String> marketingProductId = new List<String>{'M-LC-91831', 'M-LC-161467', 'M-LC-161468', 'M-LC-161469', 'M-LC-159904', 'M-LC-95127', 'M-LC-160425', 'M-LC-160428', 'M-LC-160426', 'M-LC-162633', 'M-LC-162622', 'M-LC-162746', 'M-LC-162752', 'M-LC-160429', 'M-LC-160427', 'M-LC-159905', 'M-LC-159905', 'M-LC-161083', 'M-LC-135915', 'M-LC-134267'};   
        List<SC_AutogenJob__c> autogenList = new List<SC_AutogenJob__c>();
        SC_AutogenJob__c eachAutogen;
        
        for(Integer i=0; i<20;i++){
            eachAutogen = new SC_AutogenJob__c();
            eachAutogen.Active__c = True;
            eachAutogen.Autogen_UseCase_Name__c = useCaseName[i];
            eachAutogen.Product__c = marketingProductId[i];
            eachAutogen.Case_Record_Type__c = 'Professional Services';
            eachAutogen.Origin__c = 'Autogen';
            eachAutogen.Subject__c = 'Test';
            eachAutogen.Description__c = 'Test';
            eachAutogen.Severity__c = '3';
            eachAutogen.Request_Type__c = 'Customer Onboarding';
            if(eachAutogen.Autogen_UseCase_Name__c == 'PPPPSC' || eachAutogen.Autogen_UseCase_Name__c == 'PPPPMK' || eachAutogen.Autogen_UseCase_Name__c ==  'PPMKPSM' || eachAutogen.Autogen_UseCase_Name__c ==  'PPSOPSM'){
              	eachAutogen.Service__c = 'Premium Service and Support 2.0,Security Optimization Assistance';
                eachAutogen.Subject__c = 'Test,Test';
            }
            autogenList.add(eachAutogen);
        }
        Insert autogenList;
       
        
 		SC_Autogen_Job_Enable_Disable__c autogenJob = [SELECT Id,IsActive__c FROM SC_Autogen_Job_Enable_Disable__c WHERE Name = 'SMP-Project'];
        autogenJob.IsActive__c = False;
        Update autogenJob;
        
        // For Account Record
        accRec = new Account(Name='Test1 Account1',AKAM_Account_ID__c='Test-111-ABC-XYZ1',Type='Brand - Active',Parent_Division__c='APJ_',Division__c='Americas',Support_Level__c ='Premium_2.0',Auto_Create_SOA_Reminder_Cases__c=true);
        insert accRec;
        
        PIVCAccRec = new Account(Name='Test1 Account2',AKAM_Account_ID__c='Test-112-ABC-XYZ1',Type='Brand - Active',Parent_Division__c='APJ_',Division__c='Americas');
        insert PIVCAccRec;
        
        // For Contract Record
        contrctList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c merge_contract;
        for(integer count =0; count < 5 ; count++)
        {    
            merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                       ='2Test Merge Contract-' + count;
            merge_contract.Contract_Id__c             ='2Test-123-' + count;
            merge_contract.Original_Contract_Id__c    ='2Test-123-ABC-XYZ' + count;
            merge_contract.Account_Name__c            = accRec.Id;
            merge_contract.Locked__c                  = true;
            merge_contract.Cancellation_Date__c       = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c          = False;
            merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c      = system.Today().addMonths(6);
            merge_contract.AKAM_Created_Date__c       = system.Today();
            merge_contract.Active__c                  = true;
            merge_contract.CI_Account_Name__c = 'Test-111-ABC-XYZ1';
            
            // Setting Effective Start Date of 3rd Contract Header - For SMP Use Case
            if(count == 3)    
                merge_contract.Effective_Start_Date__c    = system.Today().addDays(-165);
            
            // Setting Effective Start Date - For QBR Use Case
            if(count == 1)    
                merge_contract.Effective_Start_Date__c    = system.Today().addMonths(-9);
            
            // For PIVC Use Case
            if(count == 4){
                merge_contract.Account_Name__c   = PIVCAccRec.Id;
                merge_contract.CI_Account_Name__c = 'Test-112-ABC-XYZ1';
            }
                
            System.debug('==========='+count+'-'+merge_contract);
            contrctList.add(merge_contract);
        }
        
        Insert contrctList;
        
        // Calling Sync Method
        SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(true,false);
        synchHeader.HeaderSyncMethod(contrctList);
        
    }
    
    // Method# 2 - For Setting Contract Line
    public static Merge_Contract_Detail__c createContractLine(string ProdId, Date effectiveStrtdt, Date effcectiveEndDt, string UOM,
                                                              Id contHdId,string uniqueId)
    {
        
        Merge_Contract_Detail__c mcd        = new Merge_Contract_Detail__c();
        mcd.Original_Contract_Id__c         =   contHdId;
        mcd.Effective_Start_Date__c         =   effectiveStrtdt;
        mcd.Effective_End_Date__c           =   effcectiveEndDt;
        mcd.Product_Id__c                   =   ProdId;
        mcd.Units_Low__c                    =   12;
        mcd.Units_High__c                   =   12;
        mcd.Unit_of_Measure__c              =   UOM;
        mcd.Product__c                      =   ProdId;
        mcd.AKAM_Created_Date__c            = system.Today();
        mcd.Original_Detail_Id__c           =   contHdId + uniqueId;    
        
        if(ProdId == 'M-LC-120877' )
            mcd.Is_COB_Created__c = True;
        
        return mcd;
    }
    
    // Method# 3 - Setting Contract Line Data for All Use Case
    public static void SetContractLineData(){
        
        // Creating Contract Line
        List<Merge_Contract_Detail__c> allContrctLine = new List<Merge_Contract_Detail__c>();
        
        // Creating one WAF Product
        Merge_Contract_Detail__c mcd  = new Merge_Contract_Detail__c();
        mcd = createContractLine('M-LC-1239',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-111');
        allContrctLine.add(mcd);
        
        // Creating 2nd WAF Product
        mcd  = new Merge_Contract_Detail__c();
        mcd = createContractLine('M-LC-1239',system.Today().addDays(1),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-112');
        allContrctLine.add(mcd);
        
        // Creating one TCR Product
        Merge_Contract_Detail__c mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-1040',system.Today().addMonths(-5),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-113');
        allContrctLine.add(mcd1);
        
        // Creating 2nd TCR Product
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-1041',system.Today().addMonths(-5),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-114');
        allContrctLine.add(mcd1);
        
        // Creating RUS Product -1(14th Day Case Creation)
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-38271',system.Today().addDays(-14),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-115');
        allContrctLine.add(mcd1);
        
        // Creating RUS Product -2(Recurring Case Creation)
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-38271',system.Today().addMonths(-2).addDays(-14),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-116');
        allContrctLine.add(mcd1);
        
        // Creating PPSM Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-37859',system.Today().addDays(-15),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-117');
        allContrctLine.add(mcd1);
        
        // Creating QBR Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-1184',system.Today().addMonths(-6),system.Today().addMonths(6),'Reviews',contrctList[1].Id,'UniqueId-118');
        allContrctLine.add(mcd1);
        
        // Creating SMP On Boarding Product(Security Product) 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-128087',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[2].Id,'UniqueId-119');
        allContrctLine.add(mcd1);
        
        // Creating SMP On Boarding Product(Non Security Product) 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-120877',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[2].Id,'UniqueId-120');
        allContrctLine.add(mcd1);
        
        // Creating SMP - Optimization Product(Non Security Product)  
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-120877',system.Today().addDays(-165),system.Today().addMonths(6),'Reviews',contrctList[3].Id,'UniqueId-121');
        allContrctLine.add(mcd1);
        
        // Creating SMP - Optimization Product(Security Product)  
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-128087',system.Today().addDays(-165),system.Today().addMonths(6),'Reviews',contrctList[3].Id,'UniqueId-122');
        allContrctLine.add(mcd1);
        
        // Creating NES Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-134061',system.Today().addDays(-5),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-123');
        allContrctLine.add(mcd1);
        
        // Creating KONA Product for - Reviews UOMS
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-62167',system.Today().addMonths(-1).addDays(-14),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-124');
        allContrctLine.add(mcd1);
        
        // Creating KONA Product for - Per Site UOMS (1)
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-139829',system.Today().addMonths(-2).addDays(-14),system.Today().addMonths(6),'Per Site',contrctList[1].Id,'UniqueId-125');
        allContrctLine.add(mcd1);
        
        // Creating KONA Product for - Per Site UOMS (2)
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-139829',system.Today().addDays(-14),system.Today().addMonths(6),'Per Site',contrctList[1].Id,'UniqueId-126');
        allContrctLine.add(mcd1);
        
        // Creating KONA Product for - Other UOMS 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-139829',system.Today().addMonths(-1).addDays(-14),system.Today().addMonths(6),'Others',contrctList[2].Id,'UniqueId-127');
        allContrctLine.add(mcd1);
        
        // Creating KONA-COB Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-62167',system.Today().addMonths(-1).addDays(-14),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-128');
        allContrctLine.add(mcd1);
        
        // Creating SAAS Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-151159',system.Today().addMonths(-12),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-129');
        allContrctLine.add(mcd1);
        
        // Creating ECOB Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('TestProd-123-ABC-XYZ',system.Today().addMonths(-12),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-130');
        allContrctLine.add(mcd1);
        
        // Creating KDD Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-144155',system.Today().addMonths(-12),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-131');
        allContrctLine.add(mcd1);
        
        // Creating GDS - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-159905',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-132');
        allContrctLine.add(mcd1);
        
        // Creating GDS - Recurring Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-159905',system.Today().addDays(-75),system.Today().addMonths(6),'Others',contrctList[2].Id,'UniqueId-133');
        allContrctLine.add(mcd1);
        
        // Creating MDS - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-159939',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-134');
        allContrctLine.add(mcd1);
        
        // Creating KSD - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-140035',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-135');
        allContrctLine.add(mcd1);
        
        // Creating SOA Parent - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160425',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-136');
        allContrctLine.add(mcd1);
        
        // Creating SOA Prolexic - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160429',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-137');
        allContrctLine.add(mcd1);
        
        // Creating SOA BotManager - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160428',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-138');
        allContrctLine.add(mcd1);
        
        // Creating SOA WebAppFirewall - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160427',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-139');
        allContrctLine.add(mcd1);
        
        // Creating SOA KSD - On Boarding Product 
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160426',system.Today().addMonths(-1),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-140');
        allContrctLine.add(mcd1);
        
        //Commenting out the BOCC Autogen use case as part of ESESP-3547
        // Creating BOCC - On Boarding Product 
        //mcd1  = new Merge_Contract_Detail__c();
        //mcd1 = createContractLine('M-LC-160618',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-141');
        //allContrctLine.add(mcd1);
        
        // Creating Existing COB Product
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('TestProd-123-ABC-XYZ1',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-142');
        allContrctLine.add(mcd1);
        
        // Creating RRS Parent Product
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-161467',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-143');
        allContrctLine.add(mcd1);
        
        // Creating RRS Child Product
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-161468',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-144');
        allContrctLine.add(mcd1);
        
        // Creating RRS Child Product
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-161469',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-145');
        allContrctLine.add(mcd1);
        
        //Creating Protect & Perform Product -ESESP-1129
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162752',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-146');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162633',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-147');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162622',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-148');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162746',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-149');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-160425',system.Today(),system.Today().addMonths(6),'Others',contrctList[0].Id,'UniqueId-150');
        allContrctLine.add(mcd1);

     
        //Creating CLI for Plus
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-165777',system.Today(),system.Today().addMonths(6),'Per Month',contrctList[0].Id,'UniqueId-152');
        allContrctLine.add(mcd1);
        
        //Creating CLI for Advanced
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-165776',system.Today(),system.Today().addMonths(6),'Per Month',contrctList[0].Id,'UniqueId-153');
        allContrctLine.add(mcd1);
        
        //Creating CLI for PMO
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-165782',system.Today(),system.Today().addMonths(6),'Unit',contrctList[0].Id,'UniqueId-154');
        allContrctLine.add(mcd1);
        
        //Creating CLI for Managed Security Service - Kona Site Defender
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-166459',system.Today(),system.Today().addMonths(6),'Per Month',contrctList[0].Id,'UniqueId-155');
        allContrctLine.add(mcd1);
        
        //Creating CLI for Managed Security Services - Bot Manager Premier
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-166458',system.Today(),system.Today().addMonths(6),'Per Month',contrctList[0].Id,'UniqueId-156');
        allContrctLine.add(mcd1);
        
        //Creating CLI for Managed Security Services - Bot Manager Premier and Kona Site Defender
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-166460',system.Today(),system.Today().addMonths(6),'Per Month',contrctList[0].Id,'UniqueId-157');
        allContrctLine.add(mcd1);
        
        //Creating CLI for mPulse
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-166357',system.Today().addMonths(-1),system.Today().addMonths(1),'Per Month',contrctList[0].Id,'UniqueId-158');
        allContrctLine.add(mcd1); 
        
        //Creating CLI for mPulse
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-166357',system.Today().addMonths(1),system.Today().addMonths(2),'Per Month',contrctList[0].Id,'UniqueId-159');
        allContrctLine.add(mcd1); 
        
        // Creating one COB Product
        mcd1 = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162760',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-160');
        allContrctLine.add(mcd1);
        
        // Creating one COB Product 
        mcd1 = new Merge_Contract_Detail__c();  
        mcd1 = createContractLine('M-LC-114903',system.Today(),system.Today().addMonths(5),'Reviews',contrctList[0].Id,'UniqueId-165'); 
        allContrctLine.add(mcd1);
        
        Merge_Contract_Detail__c mcd2  = new Merge_Contract_Detail__c();
        // Creating one COB Product
        mcd2 = new Merge_Contract_Detail__c();
        mcd2 = createContractLine('M-LC-60519',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[1].Id,'UniqueId-161');
        allContrctLine.add(mcd2);
        Merge_Contract_Detail__c mcd3  = new Merge_Contract_Detail__c();
        // Creating one COB Product
        mcd3 = new Merge_Contract_Detail__c();
        mcd3 = createContractLine('M-LC-114903',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[2].Id,'UniqueId-162');
        allContrctLine.add(mcd3);
        Merge_Contract_Detail__c mcd4  = new Merge_Contract_Detail__c();
        // Creating one COB Product
        mcd4 = new Merge_Contract_Detail__c();
        mcd4 = createContractLine('M-LC-165450',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[3].Id,'UniqueId-163');
        allContrctLine.add(mcd4);
        Merge_Contract_Detail__c mcd5  = new Merge_Contract_Detail__c();
        // Creating one COB Product
        mcd5 = new Merge_Contract_Detail__c();
        mcd5 = createContractLine('M-LC-133031',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[4].Id,'UniqueId-164');
        allContrctLine.add(mcd5);

        //Creating CLI for Event Support Essentials
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-168462',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-166');
        allContrctLine.add(mcd1);

        //Creating CLI for Event Support Enhanced
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-168461',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-167');
        allContrctLine.add(mcd1);

        //Creating CLI for Event Support Comprehensive
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-168460',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-168');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-91831',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-169');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-159904',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-170');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-95127',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-171');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-161083',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-172');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-135915',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-173');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-134267',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-174');
        allContrctLine.add(mcd1);
        
        mcd1  = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-1050',system.Today(),system.Today().addMonths(6),'Base Fee',contrctList[0].Id,'UniqueId-175');
        allContrctLine.add(mcd1);
        
        // Creating one ECOB Product
        //mcd1 = new Merge_Contract_Detail__c();
        //mcd1 = createContractLine('M-LC-136533',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-161');
        //allContrctLine.add(mcd1);
        
        // Insert All Contract Lines
        Insert allContrctLine;
        
        // Calling Sync Method
        SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(false,false);
        synchHeader.HeaderSyncMethod(contrctList);
        
    }
    
    static testmethod void Autogen_SOAUseCase()
    {
        // Calling dataSetup Method
        testDataSetup();
        
        AccountteamMember atm = new AccountteamMember();
        atm.AccountId = contrctList[0].Account_Name__c;
        atm.TeamMemberRole = 'Security Services - Primary';
        atm.UserId = userInfo.getUserId();
        insert atm;
        
        List<Merge_Contract_Detail__c> lineItemList = new List<Merge_Contract_Detail__c>();
        Merge_Contract_Detail__c mcd = new Merge_Contract_Detail__c();
        mcd = createContractLine('M-LC-160425',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-151');
        mcd.Original_Contract_Id__c = contrctList[0].Id;
        lineItemList.add(mcd);
        
        Merge_Contract_Detail__c mcd1 = new Merge_Contract_Detail__c();
        mcd1 = createContractLine('M-LC-162635',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-1511');
        mcd1.Original_Contract_Id__c = contrctList[0].Id;
        lineItemList.add(mcd1);
        
        Merge_Contract_Detail__c mcd2 = new Merge_Contract_Detail__c();
        mcd2 = createContractLine('M-LC-162637',system.Today(),system.Today().addMonths(6),'Reviews',contrctList[0].Id,'UniqueId-1512');
        mcd2.Original_Contract_Id__c = contrctList[0].Id;
        lineItemList.add(mcd2);
        
        
        insert lineItemList;
        
        List<Merge_Contract_Detail__c> allLineList = [Select Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c,Original_Contract_Id__r.Account_Name__c,
                      Original_Detail_Id__c,Product_Id__c, Units_Low__c, Product__c, Unit_of_Measure__c  
                      from Merge_Contract_Detail__c where Original_Contract_Id__c = :contrctList[0].Id];
        
        
        Map<Id,String> accUserMap = new Map<Id,String>();
        accUserMap.put(accRec.id, 'None');
        Map<Id,List<Merge_Contract_Detail__c>> accountDetailMap = new Map<Id,List<Merge_Contract_Detail__c>>();
        accountDetailMap.put(accRec.id, allLineList);

        Test.startTest(); 
        SC_Autogen_SOA_Reminder_Batch cobJob = new SC_Autogen_SOA_Reminder_Batch(); 
        cobJob.noOfErrors = 2;
        Id batchProcessId = Database.executeBatch(cobJob);
        SC_Autogen_SOA_Reminder_Support supportCls = new SC_Autogen_SOA_Reminder_Support();
        supportCls.getAccountTeamDetails(allLineList);
        supportCls.createCase(accUserMap,accountDetailMap);
        supportCls.sendEmailForError('test','test',new list<case>{});
        Test.stopTest();
        
    }
    
    /* Commented By Vamsee -  ESESP-613
        // Method# 4 - Test Data Setup for PIHC
      public static void testDataForPIHC(){
        
          List<User> lUser= [SELECT Id FROM User WHERE Alias = 'CRMOPS'];
          Id recordTypeAMG = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
          Integer rangePIHC = (SC_Autogen_Case_Freq__c.getValues('PIHC').Initial_Freq__c).intValue();
      
      
          Case caseCOB = new Case();
          caseCOB.RecordTypeId = recordTypeAMG;
          caseCOB.AKAM_Created_Date__c = System.now().addDays(-rangePIHC);
          caseCOB.AKAM_System__c = 'FORCE';
          caseCOB.AKAM_Created_By__c = 'CRMOPS';
          caseCOB.Work_Type__c = 'Proactive';
          caseCOB.Request_Type__c = 'Customer Onboarding';
          caseCOB.Service__c = 'Accounts Audits';
          caseCOB.Subject = 'Test Case For PIHC';
          caseCOB.Description = 'Test Case For PIHC';
          caseCOB.AccountId = accRec.Id;
          caseCOB.Origin='Autogen';
          
          system.runAs(lUser[0]){
            insert caseCOB;
          }
       }
      */
    // Method# 5 - Test Data Setup for ECOB
    public static void testDataForECOB()
    {    
        //1. For Product Record
        Exist_Cust_Onbord_Product__c validProduct = new Exist_Cust_Onbord_Product__c();
        validProduct.Marketing_Prod_ID__c = 'TestProd-123-ABC-XYZ1';
        validProduct.Onboard_Flag__c = True;
        validProduct.Marketing_Product__c = 'TestProd-123-ABC-XYZ1';
        
        Insert  validProduct;        
    }
    
    /*Commented by Vamsee -  ESESP-613
      // Method# 6 - Test Data Setup for PIVC
      public static void testDataForPIVC(){
      
        //1. Creating Account Team Member
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accRec.Id;
        atm.UserId = Userinfo.getUserId();
        atm.TeamMemberRole = 'Technical Sales - Primary';
        insert atm;
        
        // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
        Id getAccountLevelRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('AccountLevel').getRecordTypeId();
      
        Merge_Contract_Header__c headerRec = new Merge_Contract_Header__c(Id=contrctList[0].Id);
        headerRec.Effective_Start_Date__c = system.today();
        Update headerRec;
        
        // Creating 1 ACHD rec for PIVC Use Case
        Autogen_Contract_Header_Detail__c achdRec = new Autogen_Contract_Header_Detail__c();
        achdRec.RecordTypeId = getAccountLevelRecordTypeId;
        achdRec.Parent_Account__c = accRec.Id;
        achdRec.Parent_Contract_Header__c = headerRec.Id;
        Insert achdRec;
        
        // Updating PIVC Case freq to 0
        SC_Autogen_Case_Freq__c pivcFreq = SC_Autogen_Case_Freq__c.getValues('PIVC');
        pivcFreq.Subsequent_Freq_in_Days__c=0;
        Update pivcFreq;
        
      }
    */
    // Method# 7 - (For UseCase = COB)
    static testmethod void Autogen_COBUseCase()
    {
        // Calling dataSetup Method
        testDataSetup();
        SetContractLineData();
        Test.startTest(); 
        SC_AutogenJob__c scAutoJob = new SC_AutogenJob__c();
        scAutoJob.Active__c = true;
        scAutoJob.Autogen_UseCase_Name__c = 'AMG-COB';
        scAutoJob.Case_Record_Type__c = 'Professional Services';
        scAutoJob.Description__c = 'Account Name: [insert account name]'+
            'Account Id: [insert account akam id]'+
            'Opportunity Name: [insert opportunity name]'+
            'Opportunity Id: [insert opportunity akam id]'+
            'Please refer to the detailed on-boarding steps located at: https:ac.akamai.com/docs/DOC-5430'+
            'The tasks of this case will guide you through the high-level on-boarding steps. Please complete and close out the tasks prior to closing this case';
        scAutoJob.Do_not_Show_in_Portal__c = true;
        scAutoJob.Initial_Frequency__c = 7;
        scAutoJob.IS_Case_Routing_Required__c = true;
        scAutoJob.IsTaskTobeCreated__c = true;
        scAutoJob.Origin__c = 'Autogen';
        scAutoJob.Product__c = 'M-LC-162760';
        scAutoJob.PS_Product__c = 'PLX Connect';
        scAutoJob.Recurring_Frequency__c = '90';
        scAutoJob.Request_Type__c = 'Customer Onboarding';
        scAutoJob.Service__c = 'Technical Advisory Service';
        scAutoJob.Subject__c = 'New Account: [insert account name]: Complete On-boarding Process	';
        scAutoJob.Severity__c = '3';
        scAutoJob.Sub_Type__c = 'BOCC';
        
        SC_AutogenJob__c scAutoJob1 = new SC_AutogenJob__c();
        scAutoJob1.Active__c = true;
        scAutoJob1.Autogen_UseCase_Name__c = 'Technical-COB';
        scAutoJob1.Case_Record_Type__c = 'Professional Services';
        scAutoJob1.Description__c = 'Account Name: [insert account name]'+
                                    'Account Id: [insert account akam id]'+
                                    'Opportunity Name: [insert opportunity name]'+
                                    'Opportunity Id: [insert opportunity akam id]'+
                                    'Contract ID: [insert contract id]'+
                                    'Billing Effective Date: [insert BED]'+
                                    'Contract changes: [insert link to products]';
        scAutoJob1.Do_not_Show_in_Portal__c = true;
        scAutoJob1.Initial_Frequency__c = 7;
        scAutoJob1.IS_Case_Routing_Required__c = true;
        scAutoJob1.IsTaskTobeCreated__c = true;
        scAutoJob1.Origin__c = 'Autogen';
        scAutoJob1.Recurring_Frequency__c = '90';
        scAutoJob1.Subject__c = 'Onboarding Request for [insert account name]';
        scAutoJob1.Severity__c = '3';
        scAutoJob1.Sub_Type__c = 'Service & Support Packages';
        insert new List<SC_AutogenJob__c>{scAutoJob,scAutoJob1};
        SC_Autogen_COB_Batch cobJob = new SC_Autogen_COB_Batch(); 
        cobJob.noOfErrors = 2;
        Id batchProcessId = Database.executeBatch(cobJob); 
        
        Test.stopTest();
        
        
    }
    
    // Method# 8 - (For All Autogen UseCase)
    static testmethod void Autogen_AllUseCase()
    {
        // Calling All dataSetup Method
        testDataSetup();
        SetContractLineData();
        testDataForECOB();
        Test.startTest(); 
        
        SC_Autogen_TCR_WAF_Batch TCRJob = new SC_Autogen_TCR_WAF_Batch(); 
        TCRJob.noOfErrors = 2;
        
        // Calling all the Batch Class
        Id batchProcessId = Database.executeBatch(TCRJob); 
        
        // For PIVC Use Case
        try
        {    
            List<Autogen_Contract_Header_Detail__c> ACHDListForUpdate = [select Id,Parent_Account__c,Parent_Account__r.Name,
                                                                         Parent_Contract_Header__c,Parent_Contract_Header__r.Name,
                                                                         Parent_Account__r.AKAM_Account_ID__c, 
                                                                         Parent_Contract_Header__r.Effective_Start_Date__c 
                                                                         from Autogen_Contract_Header_Detail__c limit 5
                                                                        ];
            // List of Cases
            List<Case> caseList = [select Id from case where Is_ECOB_Update__c=false limit 1];
            
            set<Id> allAccountIds = new set<Id>();
            allAccountIds.add(accRec.Id);   
            
            List<Merge_Contract_Header__c> allReturnContracts = new List<Merge_Contract_Header__c>();
            allReturnContracts.add(contrctList[0]);
            allReturnContracts.add(contrctList[1]);
            allReturnContracts.add(contrctList[4]);
            
            //SC_Autogen_ExistingCOB_Support ecobCls = new SC_Autogen_ExistingCOB_Support();
            //ecobCls.PIVC_Calculation(allReturnContracts);
            //ecobCls.createTask(caseList);  
        }
        catch(Exception e){}
        
        Test.stopTest();
    }
        
    // Method# 9 - (For All UseCase covering Exception Part)
    static testmethod void Autogen_COBUseCase_Exceptions()
    {
        // Calling dataSetup Method
        testDataSetup();
        
        // Updating few Custom setting data for generating exception
        SC_SupportEmail__c scSupEmail = [select id,Default_Task_Owner__c,Last_Contract_Header_Synch_Job_Run__c,
                                         Last_Contract_Detail_Synch_Job_Run__c 
                                         from SC_SupportEmail__c where Name = '1' limit 1];
        scSupEmail.Default_Task_Owner__c = null;
        scSupEmail.Last_Contract_Header_Synch_Job_Run__c = null;
        scSupEmail.Last_Contract_Detail_Synch_Job_Run__c = null;
        Update scSupEmail;
        
        delete [select id from SC_Autogen_Job_Enable_Disable__c where Name IN('TCR','GDS','PIVC')];
        
        Test.startTest();
        
        try
        {
            Id batchProcessId = Database.executeBatch(new SC_Autogen_COB_Batch());
        } 
        catch(Exception e){}
        
        try
        {    
            Id batchProcessId2 = Database.executeBatch(new SC_Autogen_TCR_WAF_Batch());
        }
        catch(Exception e){} 
        
        try
        {
            Id batchProcessId3 = Database.executeBatch(new SC_Autogen_RUS_PPSM_QBR_Batch());
        } 
        catch(Exception e){}
        
        /* Commented by Vamsee -  ESESP-613    
        try{
        
        SC_Autogen_PIHC_Batch PIHCJob = new SC_Autogen_PIHC_Batch(); 
        PIHCJob.noOfErrors = 2;
        Id batchProcessId4 = Database.executeBatch(PIHCJob);
        } catch(Exception e){}
        */  
        try
        {    
            SC_Autogen_ExistingCOB_Batch ECOBJob = new SC_Autogen_ExistingCOB_Batch(); 
            ECOBJob.noOfErrors = 2;
            Id batchProcessId5 = Database.executeBatch(ECOBJob);
        } 
        catch(Exception e){}
        
        try
        {    
            SC_Autogen_Premium_Three_Batch premJob = new SC_Autogen_Premium_Three_Batch(); 
            premJob.noOfErrors = 2;
            Id batchProcessId5 = Database.executeBatch(premJob);
        }
        catch(Exception e){} 
        
        /* Commented by Vamsee -  ESESP-613
            try{
            SC_Autogen_PIVC_Batch PIVCJob = new SC_Autogen_PIVC_Batch(); 
            PIVCJob.noOfErrors = 2;
            Id batchProcessId6 = Database.executeBatch(PIVCJob);
            }
            catch(Exception e){}
            */      
        SC_Sync_Contract_Header_Detail_Batch synchHeader = new SC_Sync_Contract_Header_Detail_Batch(true,false);
        synchHeader.HeaderSyncMethod(contrctList);
        
        Test.stopTest();
        
    }
    
    //Commenting out the BOCC Autogen use case as part of ESESP-3547
    // Method# 10 -Test Case: AutogenJobTrigger
    //static testmethod void Test_AutogenJobTrigger()  
    //{   
    //    SC_AutogenJob__c boccUseCase = [select Id,Product__c from SC_AutogenJob__c 
    //                                    where Autogen_UseCase_Name__c='BOCC' limit 1];        
    //    test.startTest();
    //    boccUseCase.Product__c = 'BOCC-Prod';
    //    Update boccUseCase;
    //    test.stopTest(); 
    //}
    
    // Method# 11 -Test Case: SC_PIVCReportClass
    static testmethod void Test_PIVCReportCls()  
    {
        testDataSetup();
        
        test.startTest();
        
        Merge_Contract_Header__c PIVCContract = contrctList[4];
        ApexPages.StandardController std = new ApexPages.StandardController(PIVCContract);
        Apexpages.currentPage().getParameters().put('getAccountId',accRec.Id);
        Apexpages.currentPage().getParameters().put('AccountName','Test');
        Apexpages.currentPage().getParameters().put('OrgContractId','test');
        SC_PIVCReportClass pivcRptCls = new SC_PIVCReportClass(std); 
        
        test.stopTest(); 
        
        //Call Empty Classes
        SC_Autogen_PIHC_Batch autogenPIHCBatch = new SC_Autogen_PIHC_Batch();
        SC_Autogen_PIVC_Support autogenPIVCSupport = new SC_Autogen_PIVC_Support();
        SC_Autogen_PIVC_Batch autogenPIVCBatch = new SC_Autogen_PIVC_Batch();
    }
    
    public static void createAutogenECOBSyncData()
    {    
        Id recordTypeLine = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
        
        list<Account> accList = new List<Account>();
        
        for(integer i=0;i<3;i++)
        {
            Account acc = new Account();
            //Changing account name since fast deploy was failing -date Jun-3-2019
            acc.Name = 'Test Account Premium'+i;
            acc.AKAM_Account_ID__c = 'Test-113-ABC-XYZ'+i;
            acc.Parent_Division__c = 'Web APJ_Web';
            acc.Support_Level__c = 'Premium';
            accList.add(acc);            
        } 
        insert accList;
        
        Case caseRec = new Case();
        caseRec.AccountId = accList[0].id;
        caseRec.status = 'Assigned';
        caseRec.Autogen_UseCase__c = 'ECOB';
        caseRec.Subject = 'test';
        caseRec.Description = 'test';
        caseRec.Origin = 'Email';
        insert caseRec;
        
        // For Contract Record     
        List<Merge_Contract_Header__c> contarctHeadList = new List<Merge_Contract_Header__c>();
        for(integer i=0;i<3;i++)
        {
            Merge_Contract_Header__c merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                     ='Test Merge Contract-123'+i;
            merge_contract.Contract_Id__c               ='Test-123-123'+i;
            merge_contract.Original_Contract_Id__c    = 'Test-123-ABC-XYZ'+i;
            merge_contract.Account_Name__c            = accList[i].Id;
            merge_contract.Locked__c                  = true;
            merge_contract.Cancellation_Date__c       = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c          = False;
            merge_contract.Effective_Start_Date__c    = i==2?system.Today().addDays(-30):system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c      = system.Today().addMonths(6);
            merge_contract.AKAM_Created_Date__c       = system.Today();
            merge_contract.Active__c                  = true; 
            
            contarctHeadList.add(merge_contract);
        }
        
        insert contarctHeadList;
        
        List<Exist_Cust_Onbord_Product__c> validProductList = new List<Exist_Cust_Onbord_Product__c>();
        for(integer i=0;i<3;i++)
        {
            Exist_Cust_Onbord_Product__c validProduct = new Exist_Cust_Onbord_Product__c();
            validProduct.Marketing_Prod_ID__c = 'TestProd-123-ABC-XYZ1'+i;
            validProduct.Onboard_Flag__c = True;
            validProduct.Marketing_Product__c = 'TestProd-123-ABC-XYZ1'+i;
            validProductList.add(validProduct);
            
        }
        insert  validProductList;
        
        List<Merge_Contract_Detail__c> contDetailList = new List<Merge_Contract_Detail__c>();
        
        for(integer i=0;i<3;i++)
        {    
            Merge_Contract_Detail__c mcdetail =  new Merge_Contract_Detail__c();
            mcdetail.Original_Contract_Id__c = contarctHeadList[i].Id;
            mcdetail.Original_Detail_Id__c = 'TestDetailTest'+i;
            //mcdetail.Product__c = 'TestProd-123-ABC-XYZ1'+i;
            mcdetail.Product__c = 'M-LC-160618';
            mcdetail.Effective_End_Date__c = system.today();
            mcdetail.Effective_Start_Date__c = system.today();
            //mcdetail.Product_Id__c = 'TestProd-123-ABC-XYZ1'+i;
            mcdetail.Product_Id__c = 'M-LC-160618';
            mcdetail.AKAM_Created_Date__c  = system.Today();
            mcdetail.Record_Type__c = 'Committed';
            contDetailList.add(mcdetail);   
        }
        insert contDetailList;
        
        Id getAccountLevelRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('AccountLevel').getRecordTypeId();    
        list<Autogen_Contract_Header_Detail__c> autogenContHeadList = new List<Autogen_Contract_Header_Detail__c>();
        //list<Autogen_Contract_Header_Detail__c> autogenContHeadList1 = new List<Autogen_Contract_Header_Detail__c>();
        for(integer i=0;i<3;i++)
        {
            Autogen_Contract_Header_Detail__c autogenCHD = new Autogen_Contract_Header_Detail__c();
            
            autogenCHD.IS_Existing_COB__c = i==0?true:false;
            autogenCHD.Marketing_Product_Name__c = 'TestProd-123-ABC-XYZ1'+i;
            autogenCHD.Parent_Contract_Detail__c  = contDetailList[i].id;
            autogenCHD.AKAM_Created_Date__c = system.today();
            autogenCHD.Effective_Start_Date__c = i==2?system.Today().addDays(-30):system.Today();
            autogenCHD.Effective_End_Date__c = system.today()+2;
            autogenCHD.Product_Changes_in_Last_24_Hour__c = ':TestProd-123-ABC-XYZ1'+i;
            autogenCHD.RecordTypeId = i==2?getAccountLevelRecordTypeId:recordTypeLine;
            autogenCHD.Product__c = i==1?'M-LC-165821':'TestProd-123-ABC-XYZ1'+i;
            autogenCHD.Parent_Contract_Header__c = contarctHeadList[i].id; 
            autogenCHD.Parent_Account__c = accList[i].id;
            autogenContHeadList.add(autogenCHD);     
          } 
        
        insert autogenContHeadList;
        autogenContHeadList1.addAll(autogenContHeadList);
        
    }
    
    public static testmethod void ECOBTest()
    {    
 		testDataSetup();

        createAutogenECOBSyncData();
        Test.startTest(); 
        Id batchProcessId = Database.executeBatch(new SC_Autogen_ExistingCOB_Batch());
        Id batchProcessId6 = Database.executeBatch(new SC_Autogen_Premium_Three_Batch());
        Test.stopTest();
    } 
    
     public static testmethod void autogenPremiumTest()
    {    
		testDataSetup();
		createAutogenECOBSyncData();
        List<Autogen_Contract_Header_Detail__c> acList = [Select Id, Parent_Contract_Header__r.Account_Name__c,Parent_Contract_Detail__r.Name,IS_CLI_Onboarded__c,
                                                         Effective_Start_Date__c, Parent_Contract_Header__c,Product__c,Effective_End_Date__c,Parent_Contract_Detail__c,Parent_Contract_Detail__r.Createddate,
                                                         Parent_Contract_Header__r.Name,Parent_Contract_Header__r.Account_Name__r.Name,Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c FROM Autogen_Contract_Header_Detail__c
                                                         Where Product__c = 'M-LC-165821' and id in: autogenContHeadList1];
        Test.startTest();
            SC_Autogen_Premium_Three_Support sup = new SC_Autogen_Premium_Three_Support();
            sup.createMapOfContractAndACHD(acList[0]);
            sup.createParentCase(acList);
        Test.stopTest();
    }
    
    //Test method for Plus Advanced
    public static testmethod void PLUSAdvancedTest()
    {
        testDataSetup();
        SetContractLineData();
        testDataForECOB();
        Test.startTest(); 
        
        SC_Autogen_PLUS_ADVANCED_Batch PLUSADVANCEDJob = new SC_Autogen_PLUS_ADVANCED_Batch(); 
        PLUSADVANCEDJob.noOfErrors = 2;
        
        // Calling all the Batch Class
        Id batchProcessId = Database.executeBatch(PLUSADVANCEDJob);
        
        Test.stopTest(); 
        
         
    
    }
}