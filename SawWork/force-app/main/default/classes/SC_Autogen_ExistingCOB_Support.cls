/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(4.4)    DESCRIPTION                                                       

|  ===========      =========       =======     =========== 

|  23-Dec-2014      Aditya Sonam    2637462     This is a support class for - SC_Autogen_ExistingCOB_Batch
|  23-Feb-2015      Aditya Sonam    2928180     Added condition for Existing Customer with single contract and new line item                 
|  07-May-2015      Aditya Sonam    2637462     Changes the logic to create case per Account and added case detail in description   
|  27-Jul-2015      Aditya Sonam    3084461     Removing the Logic from Merged_Contract_Detail and Implementing on its Copy Autogen_Contract_Header_Detail__c
|  13-Sep-2015      Himanshu Kar    2924517     Auto-gen for PIVC 
|  11-Apr-2016      Aditya Sonam    3118481     Adding 30 Days condition and Populating Markt Prod Name on Report
|  18-May-2017      Aditya Sonam    ESESP-584   Moving PIVC component to another class, This class will run after each NCO batch job.
|  20-Sep-2018      Sumanth Naik    ESESP-1356  Removing the dependency on Product set and creation of Additional Task for NES & Premium Products
|  26-Sep-2018      Vamsee S        ESESP-976   Add Prolexic Alert to ECO Cases
|  16-Oct-2018      Vandhana        ESESP-693   AMG Case Mgmt Improvement
|  19-Apr-2019      Sumanth Naik    ESESP-1834  Added change type in Contract and exception in contract detail query respectively
|  28-Oct-2019      Vikas R         ESESP-1581  Added logic to change the number of tasks and related cases creation
|  22-Jan-2020      Vikas R         ESESP-2846  Added logic to change the Description of Akatec Cases
+=====================================================================================================*/

/*
* Test Class : SC_Autogen_AllUseCase_TC 
*/


public class SC_Autogen_ExistingCOB_Support
{    
    // Map to store Account and Detail Id for method 4
    static Map<Id,String> caseAccountDetailMap = new Map<Id,String>();
    
    // stores account id and Detail Effective start date      
    static Map<Id,Date> detailEffStrtDateDesc = new Map<Id,Date>();
    
    // Fetching Business Hour
    public BusinessHours businessHr = [SELECT Id FROM BusinessHours WHERE Name = 'Service Business Hours - 24x5'];
    
    // List to store for Newly Created Case
    public static List<Case> newCaseList = new List<Case>(); 
    
    // List to store case which are 30 days old in open state and had a product change
    public static List<Case> oldCaseList = new List<Case>();
    
    //ESESP-1356 Set to store products for which additional task needs to be created
    Set<String> AdditionalTaskList = new Set<String>([Select Value__c from SC_Utility__mdt where MasterLabel = 'Additional Task ECOB' limit 1].Value__c.split(','));
    
    //ESESP 1356 List to store cases for which additional tasks needs to be created
    public static List<Case> TaskCreationCaseList = new List<Case>(); 

    //ESESP-1834 Set to store exception values to avoid ECO creation
    Set<String> ExceptionList = new Set<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'Exception ECOB' limit 1].Value_Text__c.split(','));

    //ESESP-1834 Set to store exception values to avoid ECO creation
    Set<String> cobProductList = new Set<String>([Select Value__c from SC_Utility__mdt where MasterLabel = 'COB_Akatec_Case_Products' limit 1].Value__c.split(','));
    
    //Map of Product Id and Marketing Product Name to use it in Report(Added as part of CR 3118481)
    static Map<Id,String> mapMarketingProductId = new Map<Id,String>();

    public Set<Id> caseIdInsert = new Set<Id>();
    public Set<Id> caseIdInsertAdditional = new Set<Id>();
    //ESESP-1581 : Created a temp variable to store all the contract list to use in createTask()
    public List<Merge_Contract_Header__c> all_ContractListTemp = new List<Merge_Contract_Header__c>();
    //ESESP-1581 : Made this varibale public in order to call updateAllContractDtl() after task creation
    public List<Autogen_Contract_Header_Detail__c> contractDetailList = new list<Autogen_Contract_Header_Detail__c>();
    //ESESP-2846 : Created this variable to create the Description of Akatec Cases
    public List<Autogen_Contract_Header_Detail__c> newCaseACHDList = new List<Autogen_Contract_Header_Detail__c>();
    
    // Method to get all Active Contracts   
    public void mergedContractHeaderMethod(List<Account> allReturnAccount)
    {
        // List#1 - To Store ECOB Contracts(Only for Active Contracts)
        List<Merge_Contract_Header__c> ECOB_ContractList = new List<Merge_Contract_Header__c>();
        
        // List#3 - To Store all The Contracts
        List<Merge_Contract_Header__c> all_ContractList = new List<Merge_Contract_Header__c>();
        
        // List#4 - To Store the Cases created for ECOB
        List<Case> ECOBCaseList = new List<Case>();
       
        //ESESP-1581 : Map to store Contract Id and Case
        Map<Id,Case> contractCaseIdMap = new Map<Id,Case>();

        //List to store related Cases ESESP-1581
        List<Case> newChildCaseList = new List<Case>();
        //Map to store the autogen records
        Map<String,SC_AutogenJob__c> autogenMap = new Map<String,SC_AutogenJob__c>();
        
        //Fetching Assignment Rule
        AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        // Fetching Case Record Types
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Storing the record type Ids
        Id techncialCaseRecordTypeId = rtMap.get('Technical').getRecordTypeId();
        
        //Fetch autogen records
        for(SC_AutogenJob__c autogenJob :[Select id, Autogen_UseCase_Name__c, Description__c, subject__c, Request_Type__c, Service__c, Origin__c,Severity__c,
                                          Sub_Type__c, Visibility__c, Service_Category__c,Active__c
                                          from SC_AutogenJob__c])
        {
            autogenMap.put(autogenJob.Autogen_UseCase_Name__c,autogenJob);
        }
        /*for(SC_Utility__mdt utilMetadata : [SELECT Value__c,Active__c,MasterLabel 
                                              FROM SC_Utility__mdt 
                                              WHERE MasterLabel in ('COB_Akatec_Case_Products')])
        {
            if(utilMetadata.MasterLabel == 'COB_Akatec_Case_Products' && !String.isEmpty(utilMetadata.Value__c))
                cobProductList = utilMetadata.Value__c.split(',');
        }*/
        //ESESP-1581 : Store technical child record details
        SC_AutogenJob__c technicalAutogenJob = autogenMap.get('Technical-COB');
        
        all_ContractList = [Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,
                            Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,Account_Name__r.Geography_Formula__c,
                            AKAM_Created_Date__c,Opportunity_Name__c
                            from Merge_Contract_Header__c 
                            where
                            Locked__c = true and Active__c = true and 
                            Cancellation_Date__c = Null and
                            Contract_Transferred_To__c = Null and
                            Effective_End_Date__c > Today and 
                            AKAM_Created_Date__c <> null and
                            Change_Type__c!='Administrative' and
                            AKAM_Created_By__c!='SADMIN' and
                            Account_Name__c IN : allReturnAccount 
                            order by AKAM_Created_Date__c asc];
        
        system.debug('all_ContractList'+all_ContractList);
        //ESESP-1581 : adding contract list to a temp variable
        all_ContractListTemp.addAll(all_ContractList);
        // Loop for Filter Out ECOB Contracts
        for(Merge_Contract_Header__c eachEcobRec : all_ContractList)
        {
            ECOB_ContractList.add(eachEcobRec);     
        }
        
        all_ContractList.clear();
        
        // Calling for ECOB Calculation
        if(SC_Autogen_Job_Enable_Disable__c.getValues('ECOB').IsActive__c)
        {            
            main_ECOB_Method(ECOB_ContractList);
        } 
        
        // Deallocating Memory
        ECOB_ContractList.clear();
        caseAccountDetailMap.clear();
        
        // Insert the Cases
        if(newCaseList.size() > 0)
            Insert newCaseList;
        
        //Update Old Case(Added as part of CR 3118481)
        if(oldCaseList.size() > 0)
            Update oldCaseList;
        
        // Loop for created Cases
        for(case eachECOBCase : newCaseList)
        {
            if(eachECOBCase.Autogen_UseCase__c == 'ECOB')
            {
                ECOBCaseList.add(eachECOBCase);
                caseIdInsert.add(eachECOBCase.Id);
            }
        }
        
        //For Old Cases(Added as part of CR 3118481)
        for(case eachECOBOldCase : oldCaseList)
        {
            if(eachECOBOldCase.Autogen_UseCase__c == 'ECOB')
            {
                eachECOBOldCase.Is_ECOB_Update__c = true;
                ECOBCaseList.add(eachECOBOldCase);
            }
        }
        
        /******* ESESP-1356 Collect list of Cases for Creating Additional Task *********/
        
        for(Case C:ECOBCaseList)
        {
            if(AdditionalTaskList.contains(C.Product_Additional_Activity_ECOB__c))
            {
                TaskCreationCaseList.add(C);
                caseIdInsertAdditional.add(c.Id);
            }
        }
        
        /*............Additional Logic For ECOB......................*/ 
        if(ECOBCaseList.size() > 0)
        {
            //Activity#1 : Calling ecobContractReport method to update description field with Report Link
            SC_CaseIssueClass.ecobContractReport(ECOBCaseList); 
            
            //Activity#2 : Calling for Task Creation
            if(newCaseList.size() > 0)
            {
                createTask(ECOBCaseList);
            }
            //Activity#3 : Calling for Related Case Creation
            if(newCaseList.size() > 0 && technicalAutogenJob.Active__c == true)
            {
                for(Case thisCase : [Select id, AccountId,Account.Geography_Formula__c, Account.AKAM_Account_ID__c, Account.Name, Contract__r.Opportunity_Name__r.Name,Contract__r.Opportunity_Name__c,Contract__r.Opportunity_Name__r.AKAM_Opportunity_ID__c,Contract__c,Contract__r.Original_Contract_Id__c,Contract__r.Opportunity_Name__r.Billing_Effective_Date__c from case where id in:(newCaseList)]){
                    if(thisCase.Contract__c != null)
                        contractCaseIdMap.put(thisCase.Contract__c, thisCase);
                }
                //ESESP-2846 : Logic to set the Description field
                //Set<Case> parentCaseSet = new Set<Case>();
                List<Case> parentCaseList = new List<Case>();
                Map<Case,List<String>> parentCaseContractIdMap = new Map<Case,List<String>>();
                system.debug('contractCaseIdMap : '+contractCaseIdMap);
                Map<Id,List<String>> caseProductStringMap = new Map<Id,List<String>>();
                List<String> caseProductString;
                Id RecordTypeIDDetail = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();

                system.debug('newCaseACHDList before update: '+newCaseACHDList);
                for(Autogen_Contract_Header_Detail__c thisACHD : newCaseACHDList){
                    system.debug('thisCLIProduct_Id__c : '+thisACHD.Parent_Contract_Detail__r.Product_Id__c);
                    if(cobProductList.contains(thisACHD.Parent_Contract_Detail__r.Product_Id__c)){
                        caseProductString = new List<String>();
                        system.debug('4 : '+caseProductStringMap);
                        if(caseProductStringMap.get(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c) != Null){
                            String caseProductName = '';
                            system.debug('5 : '+thisACHD.Parent_Contract_Detail__r.Product__c);
                            if(thisACHD.Parent_Contract_Detail__r.Product__c != null)
                                caseProductName = ':'+thisACHD.Parent_Contract_Detail__r.Product__c;
                            
                            system.debug('6 : '+caseProductName);
                            caseProductString.add(thisACHD.Parent_Contract_Detail__r.Product_Id__c+caseProductName);
                            system.debug('7 : '+caseProductString);
                            caseProductStringMap.get(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c).addAll(caseProductString);
                            system.debug('8 : '+caseProductStringMap);
                            caseProductStringMap.put(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c,caseProductStringMap.get(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c));
                        	system.debug('9 : '+caseProductStringMap);
                        }
                        else{
                            system.debug('1 : '+thisACHD.Parent_Contract_Detail__r.Product__c);
                            String caseProductName = '';
                            if(thisACHD.Parent_Contract_Detail__r.Product__c != null)
                                caseProductName = ':'+thisACHD.Parent_Contract_Detail__r.Product__c;
                            system.debug('2 : '+caseProductName);
                            caseProductStringMap.put(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c,new List<String>{thisACHD.Parent_Contract_Detail__r.Product_Id__c+caseProductName});
                        	system.debug('3 : '+caseProductStringMap);
                        }
                        
                        system.debug('caseProductString : '+caseProductString);
                        system.debug('caseProductStringMap : '+caseProductStringMap);
                        parentCaseContractIdMap.put(contractCaseIdMap.get(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c),caseProductStringMap.get(thisACHD.Parent_Contract_Detail__r.Original_Contract_Id__c));
                    }
                }
                 
                parentCaseList.addAll(parentCaseContractIdMap.keySet());
                
                for(Case thisCase:parentCaseList){
                    newChildCaseList.add(createRelatedCase(thisCase, technicalAutogenJob, dmo, techncialCaseRecordTypeId,'Technical',parentCaseContractIdMap));
                }
                //Inserting new list of child cases ESESP-1581
                if(newChildCaseList.size() > 0)
                    insert newChildCaseList;
            }
            //Activity#4 : Calling for Contract Detail Info Record Creation
            createContractDetailInfoObject(ECOBCaseList);
        }
        //ESESP-1581 : This was called before createTask() was called, moved it after task creation as per the requirement 
        //Create only when a new contract is added for an account
        updateAllContractDtl(contractDetailList);
        
        if(TaskCreationCaseList.size() > 0)
        {
            system.debug('TaskCreationCaseList'+TaskCreationCaseList);
            //createAdditionalTask(TaskCreationCaseList);
        }
        
        newCaseList.clear();
        oldCaseList.clear(); 
        newChildCaseList.clear();
        detailEffStrtDateDesc.clear(); 
        contractDetailList.clear();
        all_ContractListTemp.clear();
    }
    
    /************** Main Method *************/
    public void main_ECOB_Method(List<Merge_Contract_Header__c> allReturnContracts)
    {    
        // Create a Set to store all Original Contract Ids
        set<Id> allOrgContractIds = new set<Id>();
        
        //Record Type Id for 'Line' from Object Autogen_Contract_Header_Detail__c
        Id RecordTypeIDDetail = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
        
        // Loop to Iterate the All Fetched Contract List to Set values for above 2 variables
        for(Merge_Contract_Header__c mcH : allReturnContracts)
        {
            allOrgContractIds.add(mcH.Id);
        } 
        
        // Calling method fetchExclusionProduct
        List<String> productSet = new List<String>();
        
        productSet = fetchExclusionProduct();
        
        //Fetching Contract Detail record based on the valid contract fetched in batch start method
        //Update Query-removed Effective Start Date condition from where clause and added Marketing_product_name__c in Query(Added as part of CR 3118481)
        //ESESP-1356 Updating query to condition NOT IN productset since productset now returns list of products to be excluded
        
        //ESESP-1581 : Made the variable as public
        contractDetailList = new list<Autogen_Contract_Header_Detail__c>([Select Id,Parent_Contract_Header__c ,Parent_Contract_Detail__r.Product_Id__c,Parent_Contract_Detail__r.Original_Contract_Id__c,
                                                                          Parent_Contract_Detail__r.Product__c,Original_Detail_Id__c,Product__c,Effective_Start_Date__c,Effective_End_Date__c,Parent_Contract_Detail__c,Marketing_Product_Name__c,
                                                                          Parent_Contract_Header__r.Account_Name__c,Parent_Contract_Header__r.Account_Name__r.Name,RecordTypeId,
                                                                          Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c,Parent_Contract_Header__r.Opportunity_Name__r.Name,
                                                                          Parent_Contract_Header__r.Opportunity_Name__r.AKAM_Opportunity_ID__c,Parent_Contract_Header__r.Name,
                                                                          Parent_Contract_Header__r.createddate,Parent_Contract_Header__r.Effective_Start_Date__c, Product_Changes_in_Last_24_Hour__c  
                                                                          from Autogen_Contract_Header_Detail__c
                                                                          where  IS_Existing_COB__c = True and RecordTypeId =: RecordTypeIDDetail and
                                                                          Effective_End_Date__c >= Today and Parent_Contract_Header__c IN : allReturnContracts 
                                                                          and Parent_Contract_Detail__r.Contract_Exception__c NOT IN :ExceptionList
                                                                          and Product__c NOT IN :productSet order by Effective_Start_Date__c desc]);
        
        
        System.debug('contractDetailList: ' + contractDetailList);
        for(Merge_Contract_Header__c mchs : allReturnContracts){
            System.debug('allReturnContracts: ' + mchs.id);
        }
        
        //Fetching all details for which IS Existing Onboarding flag is false to to compare products from details whose IS Existing Onboarding = True
        List<Autogen_Contract_Header_Detail__c>  allContractProdList = new List<Autogen_Contract_Header_Detail__c>([Select Parent_Contract_Header__c,Product__c from Autogen_Contract_Header_Detail__c       
                                                                                                                    where IS_Existing_COB__c = False and RecordTypeId =: RecordTypeIDDetail and Parent_Contract_Header__c IN :allReturnContracts]);
        String productStr = '';
        
        //Map to store Contract id and Product
        Map<Id,String> contractProductMap = new Map<Id,String>();
        
        If(allContractProdList.size()>0)
        {
            // Loop to add all products related to a contract 
            for(Autogen_Contract_Header_Detail__c mc : allContractProdList)
            {
                productStr = contractProductMap.get(mc.Parent_Contract_Header__c);
                if(productStr == Null)
                {
                    productStr = '';
                }
                
                productStr = productStr +','+ mc.Product__c;
                contractProductMap.put(mc.Parent_Contract_Header__c,productStr);            
            }
        }
        
        //Stores List of Contract associated with an Account 
        List<Merge_Contract_Header__c> listContractHeader;
        
        //Stores the ContractDetail information for which the product value has changed to a new value or added        
        Map<Id,Autogen_Contract_Header_Detail__c > existContractDetailMap = new Map<Id,Autogen_Contract_Header_Detail__c >();
        
        // Variables to stores the Valid Product,Prod Name, Detail and Eff Strt Date from Object Exist_Cust_Onbord_Products__c associated with a contract
        List<String> prodChangeList;
        
        // For each contract detail fetching Account and its Product, Product Name, Detail Id and Detail Eff Start Date       
        for(Autogen_Contract_Header_Detail__c  mcD : contractDetailList){
            
            //Inserting Product Id and Marketing Product Name in Map
            mapMarketingProductId.put(mcD.Parent_Contract_Detail__c,mcD.Marketing_Product_Name__c);
            
            //List to store products from details whose Is Existing flag is false and are already present for a contract 
            prodChangeList = new list<String>();
            
            //Splitting the field Product_Changes_in_Last_24_Hrs__c and creating a list of products.
            if(mcD.Product_Changes_in_Last_24_Hour__c != Null )
            {
                mcD.Product_Changes_in_Last_24_Hour__c = mcD.Product_Changes_in_Last_24_Hour__c.replaceFirst(':','');
                prodChangeList = mcD.Product_Changes_in_Last_24_Hour__c.split(':');     
                system.debug('prodChangeList :'+prodChangeList);
                system.debug('contractProductMap :'+contractProductMap);
                system.debug('Parent_Contract_Header__c : '+mcD.Parent_Contract_Header__c);
                system.debug('prodChangeList : '+prodChangeList[0]);
                system.debug('mcD.Product__c : '+mcD.Product__c);
                system.debug('CONDITION : '+contractProductMap.containsKey(mcD.Parent_Contract_Header__c));
                //Checking if the contract has multiple line items
                // Contract with multiple details has a product change        
                if(contractProductMap.containsKey(mcD.Parent_Contract_Header__c) 
                   && !(contractProductMap.get(mcD.Parent_Contract_Header__c).containsIgnoreCase(mcD.Product__c))
                   && prodChangeList[0] != mcD.Product__c)
                {
                    system.debug('inside first if');
                    existContractDetailMap.put(mcD.Parent_Contract_Header__r.Account_Name__c,mcD);
                    setContractDetail(mcD);
                    detailEffectStartDate(mcD);   
                    newCaseACHDList.add(mcD);
                }
                
                //Stores Contract and its details information for existing customer with Single contract 
                //Single contract with single line item and product change
                //contract with multiple line item and all line item updated
                //Removed mcD.Parent_Contract_Header__r.createddate < system.today (Added as part of CR 3118481)
                else if (!contractProductMap.containsKey(mcD.Parent_Contract_Header__c)
                         && (prodChangeList[0] <> mcD.Product__c || (prodChangeList[0] == mcD.Product__c)))
                {
                    system.debug('inside second if');
                    existContractDetailMap.put(mcD.Parent_Contract_Header__r.Account_Name__c,mcD );
                    setContractDetail(mcD);
                    detailEffectStartDate(mcD);
                    newCaseACHDList.add(mcD);
                }
                
                //store contract and its details for new detail added to an existing contract with multiple details
                //Contract with multiple line item has a new line item
                else if (contractProductMap.containsKey(mcD.Parent_Contract_Header__c)
                         && !(contractProductMap.get(mcD.Parent_Contract_Header__c).containsIgnoreCase(mcD.Product__c))
                         && prodChangeList[0] == mcD.Product__c) 
                {     
                    existContractDetailMap.put(mcD.Parent_Contract_Header__r.Account_Name__c,mcD );
                    setContractDetail(mcD);
                    detailEffectStartDate(mcD);
                    newCaseACHDList.add(mcD);
                }
            }  
        }   
        system.debug('existContractDetailMap size : '+existContractDetailMap.values().size());
        system.debug('newCaseACHDList size: '+newCaseACHDList.size());
        system.debug('existContractDetailMap : '+existContractDetailMap);
        system.debug('newCaseACHDList : '+newCaseACHDList);
        // ********** Case Creation **********
        createCase(existContractDetailMap);
        
        //********** Update Contracts with Is_Existing_Contract = False **********
        //ESESP-1581 : This was called before createTask() was called, moved it after task creation as per the requirement 
        //Create only when a new contract is added for an account
        //updateAllContractDtl(contractDetailList);
        
        // ********** Deallocate Memory **********
        //contractDetailList.clear();
    }
    
    /************** Method 2: for Fetching Product to be excluded *************/
    //ESESP-1356 Modifying the Method name from fetchValidProduct to fetchExclusionProduct since it will now return list of products to be excluded
    // Called from - main_ECOB_Method method
    
    public List<String> fetchExclusionProduct()
    {
        List<String> productSet = new List<String>();
        
        //ESESP-1356 The onboarding flag condititon removed .The object Exist_Cust_Onbord_Product__c will now be used to maintain exclusion list
        //of products
        for(Exist_Cust_Onbord_Product__c forEachProd : [Select Marketing_Prod_ID__c 
                                                        from Exist_Cust_Onbord_Product__c])
        {
            productSet.add(forEachProd.Marketing_Prod_ID__c);                                                    
        }  
        return productSet;
    }
    
    /************** Method - 3: Method for Case Creation ************/
    // Called from - main_ECOB_Method method
    
    public void createCase(Map<Id,Autogen_Contract_Header_Detail__c> existContractDetailMap)
    {    
        Case eachCaserec;   
        String setSubject;
        String setDescription;
        Date todayMinus30 = System.Today() - Integer.valueof(SC_ECOB_Report_ID__c.getValues('ECOB No Day').ECOB_No_Day__c);
        
        Autogen_Contract_Header_Detail__c  mcdForCOB;          
        
        //List of case for which COB case was created in last 30 days with status as not closed (Added as part of CR 3118481)
        List<Case> newCaseCOBAccountId = new List<Case>([select id,Contract__c,AccountId,Autogen_UseCase__c,ECOB_Details__c 
                                                         from case where AccountID IN : existContractDetailMap.keyset() 
                                                         and (Autogen_UseCase__c = 'ECOB' or Autogen_UseCase__c = 'COB') 
                                                         and createddate <= Today and createddate >= :todayMinus30 
                                                         and status NOT IN ('Closed','Rejected','Duplicate','Resolved','Invalid') 
                                                         order by createddate desc]);
        //Set of Id to store Contract id related to each COB case created in last 30 days(Added as part of CR 3118481)
        Set<Id> setCOBAccountID = new Set<Id>();
        
        //Set of Id to store Case id of each COB case created in last 30 days(Added as part of CR 3118481)
        Map<Id,Case> caseAccountMap = new Map<Id,Case>();
        
        for(Case forEachCOBCase :newCaseCOBAccountId)
        {    
            setCOBAccountID.add(forEachCOBCase.AccountId);
            
            if(forEachCOBCase.Autogen_UseCase__c == 'ECOB')
            {
                caseAccountMap.put(forEachCOBCase.AccountId,forEachCOBCase);
            }
        }
        
        // Fetching Assignment Rule for Case Creation
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        // Fetching Assignment Rule for Case Updation 
        // Database.DMLOptions dmoForUpdate = new Database.DMLOptions();
        //dmo.AssignmentRuleHeader.useDefaultRule = true;
        //dmoForUpdate.EmailHeader.TriggerUserEmail = true; 
        
        // Fetching Case Record Types
        Id setRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        Autogen_Contract_Header_Detail__c  mcD;
        List<Autogen_Contract_Header_Detail__c> achdList = new List<Autogen_Contract_Header_Detail__c>();
        
        // Loop for creating each Case per Account
        for(Id mcDId : existContractDetailMap.keySet())
        {
            mcD = existContractDetailMap.get(mcDId);   
            system.debug('mcD : '+mcD);
            setSubject = 'Existing Customer : ' + mcD.Parent_Contract_Header__r.Account_Name__r.Name + ' : Complete On-boarding Process';  
            setSubject = (setSubject.length() > 254) ? setSubject.substring(0,254) : setSubject;
            
            //Added as part of ESESP-1581
            String opportunityName = (mcD.Parent_Contract_Header__r.Opportunity_Name__r.Name == null) ? '':mcD.Parent_Contract_Header__r.Opportunity_Name__r.Name;
            String opportunityId = (mcD.Parent_Contract_Header__r.Opportunity_Name__r.AKAM_Opportunity_ID__c == null) ? '':mcD.Parent_Contract_Header__r.Opportunity_Name__r.AKAM_Opportunity_ID__c;    
            String oppLink;
            
            
            if(opportunityId != '')
                oppLink = opportunityId+'('+System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + mcD.Parent_Contract_Header__r.Opportunity_Name__c + ')';
            else
                oppLink = '';
            
            
            
            setDescription = 'Account Name: ' + mcD.Parent_Contract_Header__r.Account_Name__r.Name + ' \n' +
                'Account Id: ' + mcD.Parent_Contract_Header__r.Account_Name__r.AKAM_Account_ID__c +'\n'+
                'Opportunity Name: '+opportunityName+'\n'+
                'Opportunity Id:'+ oppLink;
            
            //End of change
            
            setDescription = (setDescription.length() > 31999) ? setDescription.substring(0,31999) : setDescription;
            
            //Condition to exclude contract for which COB case is already created(Added as part of CR 3118481)
            if(!setCOBAccountID.contains(mcD.Parent_Contract_Header__r.Account_Name__c))
            {    
                eachCaserec = new Case();
                eachCaserec.setOptions(dmo);
                eachCaserec.RecordTypeId            = setRecordTypeId;
                eachCaserec.AccountId               = mcD.Parent_Contract_Header__r.Account_Name__c;
                eachCaserec.Contract__c             = mcD.Parent_Contract_Header__c;
                eachCaserec.Service__c              = SC_Serv_ReqTyp_value__c.getValues('ECOB').ServiceVal__c;
                eachCaserec.Request_Type__c         = SC_Serv_ReqTyp_value__c.getValues('ECOB').RequestTypeVal__c;
                eachCaserec.Request_Sub_Type__c     = SC_Serv_ReqTyp_value__c.getValues('ECOB').Request_SubTypeVal__c ;
                eachCaserec.Origin                  = 'Autogen';
                eachCaserec.Severity__c             = '3';
                eachCaserec.Do_Not_Show_in_Portal__c= true;
                eachCaserec.Subject                 = setSubject;
                eachCaserec.Description             = setDescription;
                eachCaserec.ECOB_Details__c         = caseAccountDetailMap.get(mcD.Parent_Contract_Header__r.Account_Name__c);
                eachCaserec.Work_Type__c            = 'Proactive';
                eachCaserec.Autogen_UseCase__c      = 'ECOB';
                eachCaserec.Product_Additional_Activity_ECOB__c    = mcD.Product__c;
                eachCaserec.CLI_Products__c         = mcD.Marketing_Product_Name__c;
                
                // Adding to Case Creation List
                newCaseList.add(eachCaserec);  
            }
            
            else if(caseAccountMap.get(mcD.Parent_Contract_Header__r.Account_Name__c) != Null)
            {
                eachCaserec = new Case();
                //eachCaserec.setOptions(dmoForUpdate);
                eachCaserec.Id = caseAccountMap.get(mcD.Parent_Contract_Header__r.Account_Name__c).Id; 
                eachCaserec.ECOB_Details__c = caseAccountDetailMap.get(mcD.Parent_Contract_Header__r.Account_Name__c);
                eachCaserec.Description     = setDescription;
                eachCaserec.Autogen_UseCase__c = 'ECOB'; 
                eachCaserec.CLI_Products__c    = mcD.Marketing_Product_Name__c;
                //eachCaserec.Is_ECOB_Update__c = true;
                
                oldCaseList.add(eachCaserec); 
            }
        } 
    }         
    
    // Method - 5: Method to create On-Boarding child cases for  ESESP-1581
    // Called from - mergedContractHeaderMethod method
    private Case createRelatedCase(Case thisCase, SC_AutogenJob__c autogenJob, Database.DMLOptions dmo, Id caseRecordTypeId, String caseType,Map<Case,List<String>> parentCaseContractIdMap){
        string technicalCaseDescription;
        Case relatedCase;
        relatedCase = new Case();
        if(caseType == 'Technical'){
            List<String> productIdList = new List<String>();
            system.debug('parentCaseContractIdMap :'+parentCaseContractIdMap);
            if(parentCaseContractIdMap != null){
                productIdList.addAll(parentCaseContractIdMap.get(thisCase));
            }
            system.debug('productIdList in related case : '+productIdList);
            String opportunityName = (thisCase.Contract__r.Opportunity_Name__r.Name == null) ? '':thisCase.Contract__r.Opportunity_Name__r.Name;
            String opportunityId = (thisCase.Contract__r.Opportunity_Name__r.AKAM_Opportunity_ID__c == null) ? '':thisCase.Contract__r.Opportunity_Name__r.AKAM_Opportunity_ID__c;
            String contractId = (thisCase.Contract__r.Original_Contract_Id__c == null) ? '':thisCase.Contract__r.Original_Contract_Id__c;
            String BEDString = String.valueOf(thisCase.Contract__r.Opportunity_Name__r.Billing_Effective_Date__c);
            String BED = (BEDString == null) ? '':BEDString;
            technicalCaseDescription = autogenJob.Description__c.replace('insert account name',thisCase.Account.Name);
            technicalCaseDescription = technicalCaseDescription.replace('insert account akam id',thisCase.Account.AKAM_Account_ID__c);
            technicalCaseDescription = technicalCaseDescription.replace('insert opportunity name',opportunityName);
            technicalCaseDescription = technicalCaseDescription.replace('insert opportunity akam id',opportunityId);
            technicalCaseDescription = technicalCaseDescription.replace('insert contract id',contractId);
            technicalCaseDescription = technicalCaseDescription.replace('insert BED',BED);
            technicalCaseDescription = technicalCaseDescription.replace('insert link to products', String.join(productIdList, ','));
            relatedCase.setOptions(dmo);
            relatedCase.ParentId = thisCase.Id;
            relatedCase.AccountId = thisCase.AccountId;
            relatedCase.RecordTypeId = caseRecordTypeId;
            relatedCase.Sub_Type__c = autogenJob.Sub_Type__c;
            relatedCase.Do_Not_Show_In_Portal_Picklist__c = autogenJob.Visibility__c;
            relatedCase.Work_Type__c = 'Proactive';
            relatedCase.Service_Category__c = autogenJob.Service_Category__c ;
            system.debug('sdsdsds'+thisCase.Account.Name);
            relatedCase.Subject = autogenJob.subject__c.replace('insert account name',thisCase.Account.Name);
            relatedCase.Description = technicalCaseDescription;
            relatedCase.Severity__c = autogenJob.Severity__c;
            relatedCase.Case_Assignment_Using_Active_Rules__c = false;
            relatedCase.Origin = autogenJob.Origin__c;
            relatedCase.Status = 'Unassigned';
        }
        return relatedCase;
    }
    
    // Create ECOB_Contract_Detail_Information__c 
    public void createContractDetailInfoObject(list<case> createdCaseList)
    {
        ECOB_Contract_Detail_Information__c ecobConDet  ;
        //List to store Contract Detail, Case Id, and Marketing Product Name to be used in Report
        List<ECOB_Contract_Detail_Information__c> ecobConDetList = new List<ECOB_Contract_Detail_Information__c>();
        
        // Looping for each ECOB Case List  
        for (Case eachCase : createdCaseList)
        {
            //if(eachCase.ECOB_Details__c != Null)
            if(String.isNotBlank(eachCase.ECOB_Details__c))
            {
                List<Id> caseIdList = new List<Id>();
                for(String ecobDetail : eachCase.ECOB_Details__c.split(',')){
                    system.debug('sdsdsd'+ecobDetail);
                    if(!String.isEmpty(ecobDetail) && !String.isBlank(ecobDetail) && ecobDetail.trim() != 'null')
                    {
                        caseIdList.add(Id.valueOf(ecobDetail));
                    }
                }
                for( Id detailId : caseIdList) 
                {
                    ecobConDet = new ECOB_Contract_Detail_Information__c();
                    ecobConDet.Case_ID__c = eachCase.Id ;
                    ecobConDet.Contract_Detail_Id__c = detailId;
                    ecobConDet.Market_Product_Name__c = mapMarketingProductId.get(detailId); //(Added as part of CR 3118481)
                    
                    // Adding record to the list 
                    ecobConDetList.add(ecobConDet);
                }            
            }             
        }
        
        if(ecobConDetList.size() > 0 )
        {              
            insert ecobConDetList;
        }
    }
    
    //Method 4: Method to insert Account Id and related detail is which are valid for case creation in a Map
    //Called from Main Method
    
    public void setContractDetail(Autogen_Contract_Header_Detail__c  contractDetail)
    {
        // variable to detail Id's which are valid for case creation
        string detailId = caseAccountDetailMap.get(contractDetail.Parent_Contract_Header__r.Account_Name__c);
        
        if(detailId == null)
        {
            caseAccountDetailMap.put(contractDetail.Parent_Contract_Header__r.Account_Name__c,contractDetail.Parent_Contract_Detail__c );
        }
        else
        {     
            detailId += ',' + contractDetail.Parent_Contract_Detail__c;
            caseAccountDetailMap.put(contractDetail.Parent_Contract_Header__r.Account_Name__c,detailId);
        }
    }
    
    //Method 5: to get earliest effective start date of details
    //Called from main method
    
    public void detailEffectStartDate(Autogen_Contract_Header_Detail__c  effdetail)
    {
        date effstrtdate = detailEffStrtDateDesc.get(effdetail.Parent_Contract_Header__r.Account_Name__c);
        if(effstrtdate ==  null)
        {
            detailEffStrtDateDesc.put(effdetail.Parent_Contract_Header__r.Account_Name__c,effdetail.Effective_Start_Date__c);           
        }
        else if(effstrtdate > effdetail.Effective_Start_Date__c )
        {
            detailEffStrtDateDesc.put(effdetail.Parent_Contract_Header__r.Account_Name__c,effdetail.Effective_Start_Date__c);
        }        
    }
    
    // Method - 6: Method for Task Creation
    // Called from - mmain_ECOB_Method method
    public void createTask(List<Case> createdCaseList)
    {
        Id RecordTypeIDDetail = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
        system.debug('all_ContractListTemp : '+all_ContractListTemp);
        Map<Id,Autogen_Contract_Header_Detail__c> CLIACHDMap = new Map<Id,Autogen_Contract_Header_Detail__c>();
        Map<Id,Id> ContractCLIMap = new Map<Id,Id>();
        List<Autogen_Contract_Header_Detail__c> contractDetailList = new list<Autogen_Contract_Header_Detail__c>([Select Id,Parent_Contract_Header__c ,IS_Existing_COB__c,
                                                                                                                  Original_Detail_Id__c,Product__c,Effective_Start_Date__c,Effective_End_Date__c,Parent_Contract_Detail__c,Marketing_Product_Name__c
                                                                                                                  from Autogen_Contract_Header_Detail__c
                                                                                                                  where RecordTypeId =: RecordTypeIDDetail and Parent_Contract_Header__c IN : all_ContractListTemp 
                                                                                                                  ]);
        for(Autogen_Contract_Header_Detail__c thisACHD : contractDetailList){
            system.debug('inside if of contractDetailList'+thisACHD);
            ContractCLIMap.put(thisACHD.Parent_Contract_Detail__c,thisACHD.Parent_Contract_Header__c);
            CLIACHDMap.put(thisACHD.Parent_Contract_Detail__c,thisACHD);
            
        }
        system.debug('ContractCLIMap : '+ContractCLIMap);
        system.debug('CLIACHDMap : '+CLIACHDMap);
        //List<SC_Autogen_ExistingCOB_Activity__c> allActivityValues = SC_Autogen_ExistingCOB_Activity__c.getall().values();
        
        //ESESP-1581: Start
        List<Case> caseList = new List<Case>([Select id,Origin,Subject,Account.Name,Description,Account.Support_Level__c,Contract__c,AccountId,Account.IsPartner,Account.Customer_Tier__c,Account.Indirect_Customer__c from Case where Id IN :createdCaseList]);
        Map<Id,List<SC_Autogen_ExistingCOB_Activity__c>> caseIdActivityListMap = new Map<Id,List<SC_Autogen_ExistingCOB_Activity__c>>();
        List<SC_Autogen_ExistingCOB_Activity__c> allActivityValues;
        List<Case> childCaseCreationList = new List<Case>();
        Map<Id,Boolean> caseIdDuplicateCLIMap = new Map<Id,Boolean>();
        for(Case eachCase : caseList){
            Boolean duplicateCLI = false;
            for(Id CLIID : ContractCLIMap.keySet()){
                system.debug('CLIID : '+CLIID);
                system.debug('ContractCLIMap.get(CLIID) : '+ContractCLIMap.get(CLIID));
                system.debug('eachCase.Contract__c : '+eachCase.Contract__c);
                system.debug('CLIACHDMap get : '+CLIACHDMap.get(CLIID).IS_Existing_COB__c);
                caseIdDuplicateCLIMap.put(eachCase.id,false);
                if(ContractCLIMap.get(CLIID) == eachCase.Contract__c){
                    system.debug('ONLY ONE'+CLIACHDMap.get(CLIID).id);
                    if(!CLIACHDMap.get(CLIID).IS_Existing_COB__c){
                        system.debug('existing cli');
                        caseIdDuplicateCLIMap.put(eachCase.id,true);
                        break;
                    }
                }
            }
            
            if(eachCase.Account.Support_Level__c != Null && (eachCase.Account.Support_Level__c.contains('Premium') || (eachCase.Account.Support_Level__c.contains('Enhanced') && !eachCase.Account.Support_Level__c.contains('Standard'))))
                childCaseCreationList.add(eachCase);
            allActivityValues = new List<SC_Autogen_ExistingCOB_Activity__c>();
            for(SC_Autogen_ExistingCOB_Activity__c eachActivityRec : SC_Autogen_ExistingCOB_Activity__c.getall().values())
            { 
                //ESESP-1581: Add only tasks which has to be created by checking the Active__c field
                if(eachActivityRec.Active__c){
                    allActivityValues.add(eachActivityRec);
                }
                system.debug('duplicateCLI : '+!duplicateCLI);
                system.debug('eachActivityRec Activity Name : '+eachActivityRec.Activity_Name__c);
                //if(!duplicateCLI && eachActivityRec.Activity_Name__c == 'Engagement Document'){
                    //allActivityValues.add(eachActivityRec);
                //}
                /*if(eachActivityRec.Activity_Name__c != 'Account Health'){
                    allActivityValues.add(eachActivityRec);
                }*/
                /*if(eachActivityRec.Activity_Name__c =='Engagement Doc'){
                    if(!eachCase.Account.Indirect_Customer__c){
                        allActivityValues.add(eachActivityRec);
                    }
                }  
                else if(eachActivityRec.Activity_Name__c == 'Special Intructions/Customer WIKI Page'){
                    if(eachCase.Account.Customer_Tier__c == 'A' || eachCase.Account.Customer_Tier__c == 'A+' || eachCase.Account.Customer_Tier__c == 'B'){
                       allActivityValues.add(eachActivityRec); 
                    }
                }
                else if(eachActivityRec.Activity_Name__c =='AkaTec Primary Assignment'){
                     if(eachCase.Account.Support_Level__c != Null && (!eachCase.Account.Support_Level__c.contains('Premium') || (eachCase.Account.Support_Level__c.contains('Enhanced') && eachCase.Account.Support_Level__c.contains('Standard')))){
                        allActivityValues.add(eachActivityRec);
                    }
                }
                else
                    allActivityValues.add(eachActivityRec);*/
            }
            system.debug('allActivityValues: '+allActivityValues);
            caseIdActivityListMap.put(eachCase.id,allActivityValues);
        }
        
        if(childCaseCreationList.size()>0)
            //createChildCase(childCaseCreationList);    
        
        childCaseCreationList.clear();
        caseList.clear();
        //End
        String getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        List<User> userRec = new  List<User>();
        userRec = [select Id from user where alias = :getOwnerAlias limit 1];

        // changes - ESESP-693 : changed Task Record Type to AMG Activity
        //Id setRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        Id setRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
        List<Task> allTaskInsertList = new List<Task>();
        Task newtask;
        DateTime setActdate;
        Long milliSecValuefor1Day = 86400000;
        Integer getNoOfDaysForTask;

        Map<Id,Case> caseOwnerMap = new Map<Id,Case>();
        caseOwnerMap = new Map<Id,Case>([Select OwnerId from Case where Id in :caseIdInsert]);
        Boolean existingECOB = false;
        for (case eachCaseRec : createdCaseList)
        {
            if(eachCaseRec.Is_ECOB_Update__c == false)
            {
                system.debug('caseIdActivityListMap: '+caseIdActivityListMap);
                for(SC_Autogen_ExistingCOB_Activity__c allActivityVal :caseIdActivityListMap.get(eachCaseRec.id)){
                    system.debug('caseIdDuplicateCLIMap :'+caseIdDuplicateCLIMap);
                    if(caseIdDuplicateCLIMap.get(eachCaseRec.id)){
                        if(allActivityVal.Activity_Name__c != 'Engagement Document')
                            continue;
                    }
                    
                    system.debug('allActivityVal: '+allActivityVal);
                    if (allActivityVal.Activity_Due_date__c == '0')
                    {
                        setActdate = detailEffStrtDateDesc.get(eachCaseRec.AccountId);  
                    }
                    else
                    {
                        getNoOfDaysForTask = Integer.valueOf(allActivityVal.Activity_Due_date__c);
                        setActdate  = BusinessHours.add(businessHr.id, system.now(), milliSecValuefor1Day * getNoOfDaysForTask); 
                    }
                    
                    newtask = new Task();
                    newtask.Subject                  =   allActivityVal.Activity_Name__c;
                    newtask.Description              =   allActivityVal.Activity_Detail__c;                                                            
                    newtask.Type__c                  =   'Task';
                    newtask.Status                   =   'Not Started';
                    newtask.WhatId                   =   eachCaseRec.Id;
                    //newtask.OwnerId                  =   userRec[0].Id;
                    if(String.valueOf(caseOwnerMap.get(eachCaseRec.Id).OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()))
                        newTask.OwnerId             =   caseOwnerMap.get(eachCaseRec.Id).OwnerId;
                    else
                        newtask.OwnerId              =   userRec[0].Id;
                    newtask.RecordTypeId             =   setRecordTypeId;
                    newtask.ActivityDate             =   Date.valueOf(setActdate);
                    
                    allTaskInsertList.add(newtask);
                }
            }
        }
        
        if(allTaskInsertList != Null &&  !allTaskInsertList.isEmpty())
            Insert allTaskInsertList;
    }        
    
    // Method - 7: Method for Updating all Contract Detail with IS ECOB Created = True
    // Called from - main_COB_Method method
    
    public void updateAllContractDtl(List<Autogen_Contract_Header_Detail__c > contractDetailList)
    {    
        List<Autogen_Contract_Header_Detail__c > allReturnDetailUpdate = new List<Autogen_Contract_Header_Detail__c >();
        
        for(Autogen_Contract_Header_Detail__c  mcDetail :contractDetailList)
        {
            mcDetail.IS_Existing_COB__c = False;
            mcDetail.Product_Changes_in_Last_24_Hour__c  = '';
            allReturnDetailUpdate.add(mcDetail);        
        }
        
        if(allReturnDetailUpdate.size() > 0)
            Update allReturnDetailUpdate;
        
    }
    
    public void createAdditionalTask(List<Case> AdditonalTaskCaseList)
    {
        SCECOBAdditionalTask__c s = SCECOBAdditionalTask__c.getValues('ECOB Additional Task');
        string getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        List<User> userRec = new  List<User>();
        
        userRec = [select Id from user where alias = :getOwnerAlias limit 1];
        Map<Id,Case> caseOwnerAddMap = new Map<Id,Case>([Select OwnerId from Case where Id in :caseIdInsertAdditional]);
        
        // changes by Vandhana for ESESP-693: changed Task record type to AMG Activity
        Id setRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG Activity').getRecordTypeId();
        List<Task> allTaskInsertList = new List<Task>();
        Task newtask;
        DateTime setActdate;
        
        Long milliSecValuefor1Day = 86400000;
        Integer getNoOfDaysForTask;
        
        for(Case eachCaseRec : AdditonalTaskCaseList)
        {
            if(eachCaseRec.Is_ECOB_Update__c == false)
            {
                setActdate = detailEffStrtDateDesc.get(eachCaseRec.AccountId);  
                newtask = new Task();
                newtask.Subject                  =   s.Activity_Name__c;
                newtask.Description              =   s.Activity_Detail__c;                                                            
                newtask.Type__c                  =   'Task';
                newtask.Status                   =   'Not Started';
                newtask.WhatId                   =   eachCaseRec.Id;
                //newtask.OwnerId                  =   userRec[0].Id;
                if(caseOwnerAddMap.get(eachCaseRec.Id) != null && String.valueOf(caseOwnerAddMap.get(eachCaseRec.Id).OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()))
                    newTask.OwnerId             =   caseOwnerAddMap.get(eachCaseRec.Id).OwnerId;
                else
                    newtask.OwnerId             =   userRec[0].Id;
                newtask.RecordTypeId             =   setRecordTypeId;                
                newtask.ActivityDate             =   Date.valueOf(setActdate);
                
                allTaskInsertList.add(newtask);
            }
        }
        
        // Create Task
        if(allTaskInsertList != Null &&  !allTaskInsertList.isEmpty())
            Insert allTaskInsertList;        
    }
    
    //ESESP-1581: Method for child case where Account has support level Premium
    public void createChildCase(List<Case> childCaseList){
       /* Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id setRecordTypeId = rtMap.get('Technical').getRecordTypeId();
        List<Case> childCaseListForInsert = new List<Case>();
        Case eachCaserec;
        for(Case eachCase : childCaseList){
            eachCaserec = new Case();
            eachCaserec.RecordTypeId            = setRecordTypeId;
            eachCaserec.AccountId               = eachCase.AccountId;
            eachCaserec.Contract__c             = eachCase.Contract__c;
            eachCaserec.Sub_Type__c             = 'Service & Support Packages';
            eachCaserec.Service_Category__c     = 'Onboarding';
            eachCaserec.Origin                  = eachCase.Origin;
            eachCaserec.Severity__c             = '3';
            eachCaserec.Do_Not_Show_in_Portal__c= true;
            eachCaserec.Subject                 = 'Onboarding Request for '+eachCase.Account.Name+' - Support package';
            eachCaserec.Description             = 'Onboarding Request for '+eachCase.Account.Name+' - Support package';
            eachCaserec.Autogen_UseCase__c      = 'ECOB';
            eachCaserec.Work_Type__c            = 'Proactive';
            eachCaserec.Case_Assignment_Using_Active_Rules__c = true;
            eachCaserec.ParentId                = eachCase.Id;
            childCaseListForInsert.add(eachCaserec);
        }
        insert childCaseListForInsert;*/ 
    }
}