/*____________________________________________________________________________________________________________

|  DATE             DEVELOPER                     CR                    DESCRIPTION                               
_____________________________________________________________________________________________________________________

|  16-April-2018    Vandhana Krishnamurthy     ESESP-603(18.5)     
____________________________________________________________________________________________________________*/

global class SC_Sync_SupportAdvocacy_Batch implements Database.Batchable<SObject>, Database.stateful 
{
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        'Batch Class Name = SC_SupportAdvocacy\n';
    public String errHdr = ' ******* ';
    
    public Map<String,String> SuppAdvoProdmap = new Map<String,String>();
    public List<String> allSuppAdvoProd = new List<String>();
    public Map<Id,Account> mapAccount = new Map<Id,Account>();
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    
    //Normal Execution Query for CONTRACT_ENGINEERING_PRODUCT_DETAILS
    public String batchQuery = Null;
    
    public Set<Id> mainAccIdSet = new Set<Id>();
    public Set<Id> accUpdateId = new Set<Id>();
    
    // Constructor
    public SC_Sync_SupportAdvocacy_Batch()
    {
        allSuppAdvoProd = [SELECT Value_Text__c,MasterLabel
                           FROM SC_Utility__mdt 
                           WHERE MasterLabel = 'Support Advocacy Products' AND Active__c = TRUE].Value_Text__c.split(',');
            
        batchQuery = 'SELECT CONTRACT_ID__c,EFFECTIVE_START_DATE__c,EFFECTIVE_END_DATE__c,ENGINEERING_PRODUCT_NAME__c,' + 
                     'MARKETING_PRODUCT_ID__c,MARKETING_PRODUCT_NAME__c,UNIQUE_KEY__c, isContractNotSynced__c ' +
                     'FROM CONTRACT_ENGINEERING_PRODUCT_DETAIL__c ' + 
                     'WHERE ENGINEERING_PRODUCT_NAME__c IN :allSuppAdvoProd' ;
    }
    
    // START METHOD
    global Database.QueryLocator start(Database.BatchableContext BC)
    {        
        batchQuery = (System.Test.isRunningTest()) ? batchQuery + ' order by Createddate Limit 10' : batchQuery;
        System.debug('QUERY : ' + batchQuery);
        return Database.getQueryLocator(batchQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        System.debug('Entered execute');
        
        // List to store all Incoming Contract Header
        List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allQueriedCEPD = new list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        allQueriedCEPD = (CONTRACT_ENGINEERING_PRODUCT_DETAIL__c[]) scope ;
        System.debug('All Queried CEPD : ' + allQueriedCEPD);
        
        try
        {    
            processCEPD(allQueriedCEPD);
        }
        catch(Exception e)
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
        }  
    }
    
    global void finish(Database.BatchableContext BC)
    {    
        System.debug('Entered FINISH');
        System.debug(mainAccIdSet);
        System.debug(accUpdateId);
        
        List<Account> lstAcc = new List<Account>();
        
        for(Account acc : [Select Id,Support_Advocate__c 
                           FROM Account 
                           WHERE ID In:accUpdateId 
                           OR Support_Advocate__c = TRUE])
        {
            if(!acc.Support_Advocate__c && accUpdateId.contains(acc.Id))
            {
                acc.Support_Advocate__c = TRUE;
                lstAcc.add(acc);
            }
            else if(acc.Support_Advocate__c && !accUpdateId.contains(acc.Id))
            {
                acc.Support_Advocate__c = FALSE;
                lstAcc.add(acc);
            }
        }
        
        Database.update(lstAcc);
        
        string setEmailSub = 'Exception: In Batch Job - SC_Sync_SupportAdvocacy_Batch. # Of Errors : '+ noOfErrors;
        
        // Calling Send Email Method for Errors
        if(noOfErrors > 0)
        {
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        }
    }
    
    // Method-1: For Processing
    public void processCEPD(list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allIncomingData)
    {
        System.debug('Entered Processing Method');
        
        Map<String, Set<String>> contractIdProductId_AllEnggProdListMap = new Map<string, set<string>>();
        
        list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> getRelatedCEPDRecs = new list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        
        Map<string, Merge_Contract_Header__c> contMCHMap = new Map<string, Merge_Contract_Header__c>();
        
        Set<Id> accId = new Set<Id>();
        
        List<Account> accountList = new List<Account>();
        
        Map<Id,Account> accMap = new Map<Id,Account>();
        
        List<Account> accToUpdate = new List<Account>();
        Set<String> allOrgContractIds = new Set<String>();
        
        //1. Loop through all Incoming CEPD for unique Original Contract Id 
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachRec : allIncomingData)
        {
            if(eachRec.CONTRACT_ID__c != null 
               && eachRec.EFFECTIVE_START_DATE__c <= System.today() 
               && eachRec.EFFECTIVE_END_DATE__c >= System.today())
                allOrgContractIds.add(eachRec.CONTRACT_ID__c);
        } 
        
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachRec : allIncomingData)
        {
            if(allOrgContractIds.contains(eachRec.CONTRACT_ID__c)) 
            {
                getRelatedCEPDRecs.add(eachRec);
            }
        } 
        
        // Step-3: Calculate Valid contracts who are Qualifying ...............
        
        System.debug('Validated Contract IDs : ' + allOrgContractIds);
        // Step-4 : Getting Contract Details from Merge Contract Header Object and call to sync method
        if(allOrgContractIds.size() > 0)
        {            
            for(Merge_Contract_Header__c eachMCHRec : [SELECT Id,Account_Name__c,Original_Contract_ID__c 
                                                       FROM Merge_Contract_Header__c 
                                                       WHERE Original_Contract_ID__c IN :allOrgContractIds
                                                       AND Account_Name__c NOT IN :mainAccIdSet
                                                      ])
            {
                mainAccIdSet.add(eachMCHRec.Account_Name__c);    
                accId.add(eachMCHRec.Account_Name__c);    
            }
        }
        System.debug('mainAccIdSet : ' + mainAccIdSet);
        System.debug('accId : ' + accId);
        
		Map<String,String> mchOrigConIdAccMap = new Map<String,String>();
        Map<Id,Merge_Contract_Header__c> mchMap = new Map<Id,Merge_Contract_Header__c>([SELECT Id,Account_Name__c,Original_Contract_ID__c 
                                                                                        FROM Merge_Contract_Header__c 
                                                                                        WHERE Account_Name__c IN :accId]);
        for(Id mchId : mchMap.keySet())
        {
            mchOrigConIdAccMap.put(mchMap.get(mchId).Original_Contract_ID__c,mchMap.get(mchId).Account_Name__c);
        }
        
        Map<Id,CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> cepdMap = new Map<Id,CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>([SELECT CONTRACT_ID__c
                                                                                                                     FROM CONTRACT_ENGINEERING_PRODUCT_DETAIL__c
                                                                                                                     WHERE ENGINEERING_PRODUCT_NAME__c IN :allSuppAdvoProd
                                                                                                                     AND CONTRACT_ID__c IN :mchOrigConIdAccMap.keySet()
                                                                                                                     AND EFFECTIVE_START_DATE__c <= Today
                                                                                                                     AND EFFECTIVE_END_DATE__c >= Today]);
        
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachCEPD : cepdMap.values())
        {
            if(mchOrigConIdAccMap.containsKey(eachCEPD.CONTRACT_ID__c))
                accUpdateId.add(mchOrigConIdAccMap.get(eachCEPD.CONTRACT_ID__c));
        }
        
    }
    
    
}