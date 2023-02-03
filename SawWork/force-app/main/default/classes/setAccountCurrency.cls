/*
Author : Samir Jha
FF: Akamai, Contract Currency at the Account Object
Modified by: janantha for CR 3021086. Ensure only required Accounts are picked up
and clean up the class.
*/
global class setAccountCurrency implements Database.Batchable<sObject>
{
    private string query;
    //list<Merge_Contract_Header__c> allContracts;
    list<Account> allAccounts;   
    list<Merge_Contract_Detail__c> allContractLineItems;
    list<PSA_Products__c> PSAProductNames= new list<PSA_Products__c>();
    set<String> ProductList=new set<String>() ;
    list<string> CurrencyList = new list<string>();
    list<string> ExpiredCurrencyList = new list<string>();
    String AccCurrency;

    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
      query='select Id,Name,lastModifiedDate,Contract_Currency__c,CurrencyIsoCode,Invoice_Currency__c from Account';
      return Database.getQueryLocator(query); //here we query all active contracts in the system 
    }

    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
        allAccounts=scope;
        List<ID> AccIDrelevantToBatch=new list<Id>();

        for(Account ac1:allAccounts)
        {
          AccIDrelevantToBatch.add(ac1.id);    
        }
        Date TodayDate=system.today();              
        
        List<ID> ConIDrelevantToBatch=new list<Id>();
        for(Merge_Contract_Header__c cont1:[select Id,Account_Name__c,Account_Name__r.id,Active__c,lastModifiedDate,Currency__c,Effective_Start_Date__c,Effective_End_Date__c from Merge_Contract_Header__c where Active__c =TRUE AND Account_Name__r.id IN :AccIDrelevantToBatch])
        {
          ConIDrelevantToBatch.add(cont1.id);
        }
        
        /*Get all the Contract Line Items. Merge_Contract_Detail__c - Contract Line Items.*/
        //allContractLineItems=[select id,Original_Contract_Id__c,Effective_End_Date__c,Product__c from Merge_Contract_Detail__c where Original_Contract_Id__c In :ConIDrelevantToBatch];       
        
        //allAccounts=[select id,CurrencyIsoCode,Contract_Currency__c from Account];
        Map<Id,list<Merge_Contract_Header__c>> AccountContractMap = new Map<Id,list<Merge_Contract_Header__c>>();
        Map<Id,list<Merge_Contract_Header__c>> AccountExpiredContractMap = new Map<Id,list<Merge_Contract_Header__c>>();
        Map<Merge_Contract_Header__c,list<Merge_Contract_Detail__c>> ContractContractDetailMap = new Map<Merge_Contract_Header__c,list<Merge_Contract_Detail__c>>();
        Map<Merge_Contract_Header__c,list<Merge_Contract_Detail__c>> ExpiredContractContractDetailMap = new Map<Merge_Contract_Header__c,list<Merge_Contract_Detail__c>>();
        list<Merge_Contract_Header__c> allSelectedContractsForAccount=new  list<Merge_Contract_Header__c>();
        list<Merge_Contract_Header__c> allSelectedExpiredContractsForAccount=new  list<Merge_Contract_Header__c>();
        List<Account> upDateAccount= new list<Account>();
       
        Boolean PSLineitem;
        
        /*PSA Products is a custom setting containing all products*/
        for(PSA_Products__c psa_p:[select Id,Name,Product_Name__c from PSA_Products__c])
        {
            ProductList.add(psa_p.Product_Name__c);          
        } 
        
        for(Merge_Contract_Header__c c:[select Id,Account_Name__c,Account_Name__r.id,Active__c,lastModifiedDate,Currency__c,Effective_Start_Date__c,Effective_End_Date__c,(select id,Original_Contract_Id__c,Effective_End_Date__c,Product__c from Merge_Contract_Details__r where Original_Contract_Id__c In :ConIDrelevantToBatch) from Merge_Contract_Header__c where Active__c =TRUE AND Account_Name__r.id IN :AccIDrelevantToBatch])
        {      
          for(Merge_Contract_Detail__c cd:c.Merge_Contract_Details__r)
          {
            //All Contract Line Items that have not expired
            if(cd.Original_Contract_Id__c==c.id && cd.Effective_End_Date__c >= system.today())
            {                 
              if(ProductList.contains(cd.Product__c))
                  allSelectedContractsForAccount.add(c);
            }           
            //All expired Contract Line Items
            else if (cd.Original_Contract_Id__c==c.id && cd.Effective_End_Date__c < system.today())
            {
              if(ProductList.contains(cd.Product__c))
                  allSelectedExpiredContractsForAccount.add(c);
            }
          }     
        }   
    /*
      Create a map of Account IDs and associated Contracts.
      //Logic to get the currency which appears maximum number of times in contracts associated to that account. 
      //After that check whether current currency is the same or different.If different add to update Account list.
    */
      for( Merge_Contract_Header__c c:allSelectedContractsForAccount)
      {    
          if(!AccountContractMap.containsKey(c.Account_Name__r.id))
          {             
            AccountContractMap.put(c.Account_Name__r.id,new list<Merge_Contract_Header__c>());//Creating a Map of Account and associated Contracts.
          }
          AccountContractMap.get(c.Account_Name__r.id).add(c);           
      }  
      
      for(Merge_Contract_Header__c c:allSelectedExpiredContractsForAccount)
      { 
          if(!AccountExpiredContractMap.containsKey(c.Account_Name__r.Id))
          {
            AccountExpiredContractMap.put(c.Account_Name__r.Id,new list<Merge_Contract_Header__c>());//Creating a Map of Account and associated Contracts.
          }
          AccountExpiredContractMap.get(c.Account_Name__r.Id).add(c);                   
      }
       //Logic to get the currency which appears maximum number of times in contracts associated to that account. 
       //After that check whether current currency is the same or different.If different add to update Account list.
       
    list<Merge_Contract_Header__c> contractForAccount = new list<Merge_Contract_Header__c>();
    list<Merge_Contract_Header__c> expiredContract= new list<Merge_Contract_Header__c>();
    
    for(Account a:allAccounts)
    {
        Currencylist.clear();
        ExpiredCurrencyList.clear();
        contractForAccount=AccountContractMap.get(a.id);
    
        if(contractForAccount != null)
        {
            for(Merge_Contract_Header__c c1:contractForAccount)
            {
              Currencylist.add(c1.Currency__c);
            }
        }
    
        expiredContract=AccountExpiredContractMap.get(a.id);
        if(expiredContract != null)
        {
            for(Merge_Contract_Header__c c1:expiredContract)
            {
              ExpiredCurrencyList.add(c1.Currency__c);
            }   
        }
      
        if(Currencylist.size()!=0 && AccountContractMap.containsKey(a.id) && !((AccountContractMap.get(a.id)).isEmpty()))
        {
          AccCurrency=MaxCurrency(Currencylist);
          if( a.Contract_Currency__c== NULL || a.Contract_Currency__c == '' || a.Contract_Currency__c!=AccCurrency)
          {   
            a.Contract_Currency__c=AccCurrency; 
            upDateAccount.add(a);
          }
       }
      else if(ExpiredCurrencyList.size() !=0 && AccountExpiredContractMap.containsKey(a.id)) 
      {
        AccCurrency=MaxCurrency(ExpiredCurrencyList);
        if(a.Contract_Currency__c== NULL || a.Contract_Currency__c== ''||a.Contract_Currency__c!=AccCurrency)
        {  
          a.Contract_Currency__c=AccCurrency;
          upDateAccount.add(a);
        }
      }
      else
      {
        if(a.Invoice_Currency__c != NULL && a.Invoice_Currency__c != a.Contract_Currency__c && a.Invoice_Currency__c != '')
        {
          a.Contract_Currency__c = a.Invoice_Currency__c;
          upDateAccount.add(a);
        }
        else if( (a.Invoice_Currency__c == NULL || a.Invoice_Currency__c == '') && (a.Contract_Currency__c != 'USD'))
        {
          a.Contract_Currency__c = 'USD';
          upDateAccount.add(a);
        }
        
      }

  } 
    Database.Update(upDateAccount);     
}
  
global void finish(Database.BatchableContext BC)
{
}
/*
Function to return Max Currency from a list of Currencies.

*/
    public String MaxCurrency(list<String> CurrencyCode)
    {
        Map<String,list<String>> currencyCountMap = new Map<String,list<String>>();
        for(String Cur:CurrencyCode)
        {
         if(!currencyCountMap.containsKey(Cur))
         {
            currencyCountMap.put(Cur,new List<String>());
         }
        currencyCountMap.get(Cur).add(Cur);
        }
        integer maxcount=0;
        string maxcur='';
        integer curcount=0;
        for (String cur1:currencyCountMap.keySet())
        {
        curcount=currencyCountMap.get(cur1).size();
        if(maxcount<curcount)
        {
        maxcount=curcount;
        maxcur=cur1;
        }
        }
       
        return maxcur;
    }
}