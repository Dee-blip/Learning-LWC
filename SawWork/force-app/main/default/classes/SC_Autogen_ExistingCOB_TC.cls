/*=====================================================================================================+
    Class name          :   SC_Autogen_ExistingCOB_TC
    Author              :   Aditya Sonam
    Created             :   29-Dec-14
    Purpose             :   This test class is used to cover code for below Components
                            1. SC_Autogen_ExistingCOB_Batch
                            2. SC_Autogen_ExistingCOB_Support
 
+=====================================================================================================*/
 
@isTest(seeAlldata=False)
public class SC_Autogen_ExistingCOB_TC
{
    // For Account Record
    public static Account accRec;
    public static EB_AccountProductMap__c eb_product;
   
    // For Contract Record
    public static List<Merge_Contract_Header__c> contrctList;
   
    // For Contract-Detail Record
    public static List<Merge_Contract_Detail__c> contrctDetailList;
   public static List<Merge_Contract_Detail__c> contrctDetailList1;
   
    //For Autogen_Contract_Header_Detail__c
    public static List<Autogen_Contract_Header_Detail__c> autogenContractList;
   
    //For Autogen_Contract_Header_Detail__c
    public static List<Autogen_Contract_Header_Detail__c> autogenContractList1;
   
    //For Product Record
   
    Public static List<Exist_Cust_Onbord_Product__c> prodList;
    public static User amgAgent;
   
    // Method for Creating Test Data
  
    static void testDataSetup()
    {
        // ***********Creating Test Data ***************
       
        // Call to - createCustomSettings For Case Setup
        //utilTestClass.createCustomSettings();
       
        // Call to - SC_Autogen_init_Method For Autogen Setup
        //Create All custom setting to set seeAllData=false
        //utilTestClass.createCustomSettings();
        //utilTestClass.SC_Autogen_init_Method();
       
       // For Account Record
        //accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111-ABC-XYZ');
        //insert accRec;
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' and Isactive = True LIMIT 1];
        System.runAs(sysAdmin) {
            utilTestClass.createCustomSettings();
            utilTestClass.createData_SC_SupportEmail();
            utiltestClass.createData_SC_Autogen_Run_Freq();
            utiltestClass.createData_SC_Autogen_Case_Freq();
            utiltestClass.createData_SC_AutoGencase_Activity();
            utiltestClass.createData_SC_Serv_ReqTyp_value();
        }
        accRec = new Account(Name='Test1 Account1',AKAM_Account_ID__c='Test-111-ABC-XYZ1',Type='Brand - Active',Parent_Division__c='APJ_',Division__c='Americas',Support_Level__c ='Premium_2.0',Auto_Create_SOA_Reminder_Cases__c=true);
        accRec.Type = 'Indirect Customer - Active';
        insert accRec;
        
        //accRec = [select Id,Name,AKAM_Account_ID__c from Account limit 1];
       
        eb_product = new EB_AccountProductMap__c(Name='mPulse',EB_MarkedForDeletion__c = false,EB_Product__c='TestmPulse',EB_Account__c=accRec.id);
        insert eb_product;
       
        // For Contract Record
        contrctList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c merge_contract;
       
        For(integer count =0; Count < 2;Count++)
        {
            merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                 ='Test Merge Contract-'+count;
            merge_contract.Contract_Id__c             ='Test-123';
            merge_contract.Original_Contract_Id__c    = 'Test-123-ABC-XYZ'+count;
            merge_contract.Account_Name__c          = accRec.Id;
            merge_contract.Locked__c              = true;
            merge_contract.Active__c = true;
            merge_contract.Cancellation_Date__c     = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c        = False;
            merge_contract.AKAM_Created_Date__c = system.Today();
            merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c    = system.Today().addMonths(6);
           
            contrctList.add(merge_contract);   
        }
       
        Insert contrctList;
       
        system.debug('Test Class Contract Header'+contrctList);
       
        // For Contract-Detail Record
        contrctDetailList = new List<Merge_Contract_Detail__c>();
        contrctDetailList1 = new List<Merge_Contract_Detail__c>();
        Merge_Contract_Detail__c merge_Detail;
        Merge_Contract_Detail__c merge_Detail1;
       
        for(Merge_Contract_Header__c mcH :contrctList){
           
            if(mcH.Name != 'Test Merge Contract-1')  
            {
                merge_Detail = new Merge_Contract_Detail__c();
                merge_Detail.Name                       = mcH.Name;
                merge_Detail.Original_Detail_Id__c     = mcH.Original_Contract_Id__c;
                merge_Detail.Original_Contract_Id__c    = mcH.ID;
                merge_Detail.Product_Id__c             = 'M-LC-132825';
                merge_Detail.IS_Existing_COB__c         = True;
                // merge_Detail.Old_Product_Id__c           ='TestProd';
                merge_Detail.Effective_Start_Date__c    = system.Today().addDays(-14);
                merge_Detail.Effective_End_Date__c      = system.Today().addMonths(6);
               
                contrctDetailList.add(merge_Detail);
               
            }
            else{
                System.debug('------Inside Else------');   
                merge_Detail1 = new Merge_Contract_Detail__c();
                merge_Detail1.Name                       = mcH.Name;
                merge_Detail1.Original_Detail_Id__c     = mcH.Original_Contract_Id__c;
                merge_Detail1.Original_Contract_Id__c    = mcH.ID;
                merge_Detail1.Product_Id__c             = 'M-LC-132825';
                merge_Detail1.IS_Existing_COB__c         = True;
                // merge_Detail.Old_Product_Id__c           ='TestProd';
                merge_Detail1.Effective_Start_Date__c    = system.Today().addDays(-14);
                merge_Detail1.Effective_End_Date__c      = system.Today().addMonths(6);
               
                contrctDetailList1.add(merge_Detail1);
            }   
        }
       
        Insert contrctDetailList;
        system.debug('Test Class Contract Line Item 1'+contrctDetailList);
        Insert contrctDetailList1;
        system.debug('Test Class Contract Line Item 2'+contrctDetailList1);
       
        autogenContractList = new List<Autogen_Contract_Header_Detail__c>();
       
        Autogen_Contract_Header_Detail__c autogenContractDetail;
       
        for(Merge_Contract_Detail__c mcHD :contrctDetailList)
        {   
            autogenContractDetail = new Autogen_Contract_Header_Detail__c();
           
            autogenContractDetail.IS_Existing_COB__c = True;
            autogenContractDetail.Original_Detail_ID__c = mcHD.Id;
            autogenContractDetail.Parent_Contract_Header__c  = mcHD.Original_Contract_Id__c ;
            autogenContractDetail.Product__c  = 'M-LC-132825';
            autogenContractDetail.Effective_Start_Date__c    = system.Today().addDays(-14);
            autogenContractDetail.Effective_End_Date__c      = system.Today().addMonths(6);
            //autogenContractDetail.Name                       = mcHD.Name;
            autogenContractDetail.RecordTypeID = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
            autogenContractDetail.Parent_Contract_Detail__c = mcHD.Id;
            autogenContractDetail.Product_Changes_in_Last_24_Hour__c = 'M-LC-132825';
           
            autogenContractList.add(autogenContractDetail);
        }
       
        insert autogenContractList;
       
        system.debug('Autogen Contract List 1'+autogenContractList);
       
        autogenContractList1 = new List<Autogen_Contract_Header_Detail__c>();
       
        Autogen_Contract_Header_Detail__c autogenContractDetail1;
       
        for(Merge_Contract_Detail__c mcHD1 :contrctDetailList1){
           
            autogenContractDetail1 = new Autogen_Contract_Header_Detail__c();
           
            autogenContractDetail1.IS_Existing_COB__c = False;
            autogenContractDetail1.Original_Detail_ID__c = mcHD1.Id;
            autogenContractDetail1.Parent_Contract_Header__c  = mcHD1.Original_Contract_Id__c ;
            autogenContractDetail1.Product__c  = 'M-LC-132829';
            autogenContractDetail1.Effective_Start_Date__c    = system.Today().addDays(-14);
            autogenContractDetail1.Effective_End_Date__c      = system.Today().addMonths(6);
            //autogenContractDetail.Name                       = mcHD.Name;
            autogenContractDetail1.RecordTypeID = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
            autogenContractDetail1.Parent_Contract_Detail__c = mcHD1.Id;
            autogenContractDetail1.Product_Changes_in_Last_24_Hour__c = 'TestProd-123-ABC-XYZ';
           
            autogenContractList1.add(autogenContractDetail1);
        }
       
        insert autogenContractList1;
    }
   
    // Method# 1 - (For UseCase = ECOB )
    static testmethod void Autogen_ECOB()
    {
        testDataSetup();
 
        Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];
        User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
       
        SC_Autogen_ExistingCOB_Batch ecob_BatchCls = new SC_Autogen_ExistingCOB_Batch();
        ecob_BatchCls.batchQuery = '**Not Null**';
        ecob_BatchCls.noOfErrors = 1;
        
        //SC_Sync_Contract_Header_Detail_Batch SC_Sync_Header_Detail = new SC_Sync_Contract_Header_Detail_Batch(True,False);
        //SC_Sync_Header_Detail.batchQuery = '**Not Null**';
       
        Test.startTest();
        
        Id batchProcessId = Database.executeBatch(ecob_BatchCls);  
        
        SC_Autogen_ExistingCOB_Support SC_ECOB_SupCls = new SC_Autogen_ExistingCOB_Support();
       
        contrctList = [Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,
                       Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,Account_Name__r.Geography_Formula__c,
                       AKAM_Created_Date__c
                       from Merge_Contract_Header__c
                       where
                       Locked__c = true and Active__c = true and
                       Cancellation_Date__c = Null and
                       Contract_Transferred_To__c = Null and
                       Effective_End_Date__c > Today and
                       AKAM_Created_Date__c <> null
                       //and Account_Name__c IN : allReturnAccount
                       order by LastModifieddate  desc limit 10];
 
        SC_ECOB_SupCls.main_ECOB_Method(contrctList);
        Test.stopTest();
    }
   
    static testmethod void Autogen_ECOB3()
    {
        testDataSetup();
        Test.startTest();
        
        List<Case> caseUpdateList = new List<Case>();
        User amgAgent = [Select Id from User where Profile.Name = 'Support - AMG Agent' AND isActive = true limit 1];
        Case caseCOB = new Case();
          caseCOB.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosbyName().get('AMG').getRecordTypeId();
          caseCOB.AKAM_Created_Date__c = System.now().addDays(-60);
          caseCOB.AKAM_System__c = 'FORCE';
          caseCOB.AKAM_Created_By__c = 'CRMOPS';
          caseCOB.Work_Type__c = 'Proactive';
          caseCOB.Request_Type__c = 'Customer Onboarding';
          caseCOB.Service__c = 'Accounts Audits';
          caseCOB.Subject = 'Test Case For PIHC';
          caseCOB.Description = 'Test Case For PIHC';
          caseCOB.AccountId = accRec.Id;
          caseCOB.Origin='Autogen';
        caseCOB.Validation_Override__c = True;
        caseCOB.Autogen_UseCase__c = 'ECOB';
        Insert caseCOB;
        caseCOB.OwnerId = amgAgent.Id;
        caseCOB.Status = 'In Progress';
        caseCOB.Akam_Closed_Date__c = Date.today().addDays(-40);
        caseCOB.Validation_Override__c = true;
        caseUpdateList.add(caseCOB);
        update caseCOB;
       
        caseCOB.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosbyName().get('Invalid Case').getRecordTypeId();
        caseCOB.Status = 'Closed';
        caseCOB.Validation_Override__c = true;
        
       
        update caseCOB;
        Test.stopTest();
    }
    static testmethod void Autogen_ECOB2()
    {
        testDataSetup();
        List<Case> CaseList = new List<Case>();
        accRec = [select Id,Name,AKAM_Account_ID__c from Account limit 1];
        
        //utilTestClass.createCustomSettings();
        
        Case caseCOB = new Case();
        caseCOB.Subject ='Test SUbject';
        caseCOB.AccountId=accRec.Id;
        caseCOB.Origin = 'Autogen';
        caseCOB.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosbyName().get('AMG').getRecordTypeId();
        caseCOB.AKAM_Created_Date__c = System.now().addDays(-60);
        caseCOB.AKAM_System__c = 'FORCE';
        caseCOB.AKAM_Created_By__c = 'CRMOPS';
        caseCOB.Work_Type__c = 'Proactive';
        caseCOB.Request_Type__c = 'Customer Onboarding';
        caseCOB.Service__c = 'Accounts Audits';
        caseCOB.Subject = 'Test Case For PIHC';
        caseCOB.Description = 'Test Case For PIHC';
        caseCOB.AccountId = accRec.Id;
        caseCOB.Origin='Autogen';
        CaseList.add(caseCOB);
        insert CaseList;
        
        SC_Autogen_ExistingCOB_Support sc = new SC_Autogen_ExistingCOB_Support();
        sc.createAdditionalTask(CaseList);
        sc.createChildCase(CaseList);
        
    }
   
    static testmethod void Autogen_COBUseCase()
    {
        // Calling dataSetup Method
        SC_Autogen_AllUseCase_TC.testDataSetup();
        Test.startTest(); 
        SC_Autogen_COB_Batch cobJob = new SC_Autogen_COB_Batch(); 
        cobJob.noOfErrors = 2;
        Id batchProcessId = Database.executeBatch(cobJob); 
        Test.stopTest();
    }
         static testmethod void TM_SC_CPS_RetryEmailBatch()
    {
        // Calling dataSetup Method
        SC_Autogen_AllUseCase_TC.testDataSetup();
        List<Case> caseList = new List<Case>();
        Id recordTypeIdWE = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Web Experience').getRecordTypeId();    
        Case ncase;
        for(integer i=0;i<10;i++){
          ncase = new Case();
         ncase.Subject ='Test SUbject-Running Test';
        ncase.Origin = 'Email';
        ncase.validation_override__c = true;
        //ncase.Expiration_Date__c = i== 1 ? System.now().addDays(15) : System.now().addDays(5);
        ncase.RecordTypeId = recordTypeIdWE;
            if(i==0){
                ncase.Expiration_Date__c = System.now().addDays(15);
            	ncase.CPSExpiration15Days__c = true;
            }
            else if(i==1){
                ncase.Expiration_Date__c = System.now().addDays(5);
            	ncase.CPSExpiration5Days__c = true;
            }
            else if(i==2){
                ncase.Expiration_Date__c = System.now().addDays(3);
            	ncase.CPSDaysBeforeExpiry__c = '3';
            }
            else if(i==3){
                ncase.Expiration_Date__c = System.now().addDays(1);
            	ncase.CPSDaysBeforeExpiry__c = '1';
            }
            else if(i==4){
                ncase.Expiration_Date__c = System.now().addDays(30);
            	ncase.CPSDaysBeforeExpiry__c = '30';
            }
            else if(i==5){
                ncase.Expiration_Date__c = System.now().addDays(12);
            	ncase.CPSDaysBeforeExpiry__c = '12';
            }
            else if(i==6){
                ncase.Expiration_Date__c = System.now().addDays(7);
            	ncase.CPSDaysBeforeExpiry__c = '7';
            }
            else if(i==7){
                ncase.Expiration_Date__c = System.now().addDays(2);
            	ncase.CPSDaysBeforeExpiry__c = '2';
            }
            else if(i==8){
                ncase.Expiration_Date__c = System.now().addDays(8);
            	ncase.CPSExpiration8Days__c = true;
            }
            else{
                ncase.Expiration_Date__c = System.now().addDays(-1);
            	ncase.CPSExpiration1DayAfter__c = true;
            }
        caseList.add(ncase);
        }
         

        insert caseList;

        Test.startTest(); 
        SC_CPS_RetryEmailBatch cobJob = new SC_CPS_RetryEmailBatch();
        SC_CPS_RetryEmailQueueable qJob = new SC_CPS_RetryEmailQueueable();
        qJob.sendFailureEmail('Test Error Email');
        cobJob.noOfErrors = 2;
        Id batchProcessId = Database.executeBatch(cobJob); 
        Test.stopTest();
    }
}