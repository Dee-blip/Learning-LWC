public without sharing class SC_Jarvis_Case_Questionnaire_Controller 
{
    public SC_Jarvis_Case_Questionnaire_Controller() 
    {

    }
    public class SearchResultValues
    {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Value;

        public SearchResultValues(String idValue, String nameString, String valueString)
        {
            Id = idValue;
            Name = nameString;
            Value = valueString;
        }
    }
    @AuraEnabled(cacheable=true)  
    public static List<SearchResultValues> findLookupRecords(String searchKey) 
    {  
        string searchText = String.escapeSingleQuotes(searchKey) + '%';  
        String query = 'Select Id,Case_Product_Name__c from Siebel_Marketing_Prod_Case_Prod_Map__c'; 
        query += ' where Service_Product__c = true and Case_Product_Name__c like :searchText';        
        
        query += ' order by Case_Product_Name__c LIMIT 6';  
        Set<String> caseProducts = new Set<String>();
        List<SearchResultValues> wrapperValues = new List<SearchResultValues>();
        SearchResultValues wrapperRec;
        for(Siebel_Marketing_Prod_Case_Prod_Map__c prodMap : Database.query(query))
        {
            if(!caseProducts.contains(prodMap.Case_Product_Name__c))
            {
                caseProducts.add(prodMap.Case_Product_Name__c);
                wrapperRec = new SearchResultValues(prodMap.Id,prodMap.Case_Product_Name__c,prodMap.Case_Product_Name__c);
                wrapperValues.add(wrapperRec);
            }
        }
        return wrapperValues; 

    }  

    @AuraEnabled(cacheable=true)  
    public static SC_Select_Options_Wrapper getProblem(String productName)
    {
        SC_Select_Options_Wrapper wrapper = new SC_Select_Options_Wrapper();
        if(string.isBlank(productName))
        {
            return wrapper;
        }
        Set<String> problems = new Set<String>();

        List<Case_Product_Siebel_LOV__c> lovRecordsForAccount = [Select Account_ID__c from Case_Product_Siebel_LOV__c where 
        Marked_For_Deletion__c = false and  Product__c = :productName limit 1];
        if(lovRecordsForAccount != null && lovRecordsForAccount.size() == 1)
        {
            Account accountRec;
            String accountIdFilter;
            if(lovRecordsForAccount.get(0).Account_ID__c != null)
            {
                try 
                {
                    accountRec = [Select id from Account where Akam_Account_Id__c = :lovRecordsForAccount.get(0).Account_ID__c limit 1];
                    accountIdFilter = accountRec.Id;
                } 
                catch (Exception e) 
                {
                    accountRec = null;
                }    
            }
            for (Case_Product_Siebel_LOV__c lovRec : SC_Jarvis_utility.getLOVs(null, accountIdFilter, new Set<String>{productName} ))
            {
                if(!problems.contains(lovRec.Problem__c))
                {
                    problems.add(lovRec.Problem__c);
                    wrapper.options.add(new SC_Select_Options(lovRec.Problem__c,lovRec.Problem__c));   
                }
            }
    
        }
        return wrapper;
    }
    
}