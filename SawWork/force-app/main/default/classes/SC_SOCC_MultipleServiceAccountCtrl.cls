/*
************************************************************************************************************
    Author              :   Tejaswini 
    Created             :   06-April-2021
    Purpose             :   Controller to Associate Multiple Service Accounts to one PD
    Test Class          :   SC_SOCC_MultipleServiceAccountCtrl_Test

	Date                 Developer                  JIRA #          Description                                                      
-----------------------------------------------------------------------------------------------------------
	06 Apr 2021          Tejaswini      			ESESP-4953		SOCC CAR 2 - RunBooks 2

************************************************************************************************************
*/
public with sharing class SC_SOCC_MultipleServiceAccountCtrl {
    @AuraEnabled
    public static List<SC_LookupSearchResult> getServiceAccounts(Id recordPdID) 
    {
        String objIcon = 'standard:account';
        String ACCURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/';
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();
        for(Account acc : [select id,name from Account where 
            id IN (select Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =:recordPdID) order by createddate desc])
            {
                results.add(
                new SC_LookupSearchResult(
                        acc.Id,
                        'Account',
                        objIcon,
                        acc.Name,
                        ACCURL+acc.Id
                    )
                );
            }
        return results;
    }

    private final static Integer MAX_RESULTS = 5;
    @AuraEnabled
    public static List<SC_LookupSearchResult> search(String searchTerm, List<String> selectedIds, String objId) 
    {
        // Prepare query paramters
        searchTerm += '*';
        String accId;
        for(Policy_Domain__c pdobj:[Select Id, Account_Name__c from Policy_Domain__c where id =: Id.valueOf(objId)]){
            System.debug('acc id'+pdobj.Account_Name__c);
            accId=pdobj.Account_Name__c;
        }
        selectedIds.add(accId);
        System.debug('the selected Ids are  '+selectedIds);
        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN Name FIELDS
            RETURNING
                Account(Id, Name where Id NOT In :selectedIds)
            LIMIT :MAX_RESULTS
        ];
		
        System.debug('the search results are'+searchResults);
        // Prepare results
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();

        // Extract Accounts & convert them into SC_LookupSearchResult
        String objIcon = 'standard:account';
        String ACCURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/';
        Account[] AccList = (List<Account>) searchResults[0];
        System.debug('the accList are '+AccList);
        for (Account accRec : AccList) {
            results.add(new SC_LookupSearchResult(accRec.Id,'Account',objIcon,accRec.Name,ACCURL+accRec.Id));
        }
        results.sort(); //sort based on Account Name
        return results;
    }

    @AuraEnabled
    public static void saveServiceAccountMappings(List<Id> accountList,id recordPdID) 
    {
        List<Service_Account_PD_Mapping__c> serviceAccountPDMapList = new List<Service_Account_PD_Mapping__c>();
        Map<Id,Service_Account_PD_Mapping__c> serviceAccountPDMap = new Map<Id,Service_Account_PD_Mapping__c>();

        for(Service_Account_PD_Mapping__c thisRec :[select id,Policy_Domain__c,Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: recordPdID ]){
            serviceAccountPDMap.put(thisRec.Service_Account__c,thisRec);
        }

        for(ID accId : accountList){
            if(!serviceAccountPDMap.keyset().contains(accId)){
                Service_Account_PD_Mapping__c serviceAccountPDMapRec = new Service_Account_PD_Mapping__c(); 
                serviceAccountPDMapRec.Service_Account__c = accId;
                serviceAccountPDMapRec.Policy_Domain__c = recordPdID;
                
                serviceAccountPDMapList.add(serviceAccountPDMapRec);
            }
        }

        if(serviceAccountPDMapList.size() > 0){
            insert serviceAccountPDMapList;
        }
        
        //Query on Pd to see if Service Account is there or not..if not there then add it
        
        Policy_Domain__c pd=[Select Id,Service_Account__c from Policy_Domain__c where Id =:recordPdID];
        if(pd.Service_Account__c==null){
            if(accountList.get(0)!=null){
                pd.Service_Account__c=accountList.get(0);
                update pd;
            }
            
        }
        
        
    }

    @AuraEnabled
    public static void deleteServiceAccountMappings(List<Id> accountList,id recordPdID) 
    {
        List<Service_Account_PD_Mapping__c> serviceAccountPDMapDeleteList = new List<Service_Account_PD_Mapping__c>();
        Map<Id,Service_Account_PD_Mapping__c> serviceAccountPDMap = new Map<Id,Service_Account_PD_Mapping__c>();

        for(Service_Account_PD_Mapping__c thisRec :[select id,Policy_Domain__c,Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: recordPdID ]){
            serviceAccountPDMap.put(thisRec.Service_Account__c,thisRec);
        }

        for(Id accId : serviceAccountPDMap.keyset()){
            if(accountList.size() == 0 || (accountList.size() > 0 && !accountList.contains(accId))){
                serviceAccountPDMapDeleteList.add(serviceAccountPDMap.get(accId));
            }
        }
            
        if(serviceAccountPDMapDeleteList.size() > 0){
            delete serviceAccountPDMapDeleteList;
        }
        
        //If the service account which is deleted is the Service account on Pd then update the pd with the next service account of it
        
        Policy_Domain__c pd=[Select Id,Service_Account__c from Policy_Domain__c where Id =:recordPdID Limit 1];
        List<Service_Account_PD_Mapping__c> lSaPdMap=[Select Id, Policy_Domain__c, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c=:recordPdID ORDER BY CreatedDate ASC LIMIT 1];
        System.debug ('the pd is'+pd);
        System.debug('Service acc pd mapping detais '+lSaPdMap);
        Id serviceAccId;
        if(lSaPdMap.size()>0){
            for(Service_Account_PD_Mapping__c saPdMapObj:lSaPdMap)
            {
                serviceAccId=saPdMapObj.Service_Account__c;
            }
        }
        if(pd.Service_Account__c!=null && pd.Service_Account__c!=serviceAccId){
            pd.Service_Account__c=serviceAccId;
            update pd;
            
        }
        
        
    }
}