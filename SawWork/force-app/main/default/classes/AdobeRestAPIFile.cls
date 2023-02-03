@RestResource(urlMapping='/FetchAccDetails/*')
global with sharing class AdobeRestAPIFile {
    
    global static Integer fetchCount = 50000;
    
    @HttpPost
    global static String fetchAccountDetails(String websiteList){
        //Changed from String, Account to String, String to save bytes while transferring data back to Mule
        Map<String, String> domainToAccMap = new Map<String, String>();
		List<List<String>> batchedSiteList = new List<List<String>>();
        Boolean requiresSpliiting = false;
		List<String> siteList = websiteList.split(',');
        
        if(siteList[0] == null){
        	siteList.remove(0);    
        }
        
        if(Test.isRunningTest()){
            fetchCount = 2;
        }
        
        Set<String> updatedList = new Set<String>();
        List<List<String>> finalSiteList = new List<List<String>>();
        for(String site: siteList){
            if(site != null){
                String str = '%' + site + '%';
            	updatedList.add(str);
            }
            
        }
        finalSiteList.add(new List<String>(updatedList));
       
        //Logic to divide list in small chunks
        //Missing use-case: Below logic is using like operator which might attach a different Akam ID with website
        //Eg. We have two webistes facebook.com with Cust_Status = 1 and book.com with Cust_status = 3
        //In this case, if Adobe sends book.com then below code will return facebook.com Akam Acc ID due to like condition
        
        batchedSiteList = divideAndConquer(finalSiteList, 2);
        
        if(batchedSiteList != null){
            for(List<String> strList: batchedSiteList){
                List<Account> accList = [SELECT id, AKAM_Account_ID__c , name, type, website, DUNS_URL__c FROM Account WHERE website LIKE :strList OR DUNS_URL__c LIKE :strList ORDER BY Cust_Status__c asc, LastModifiedDate desc];
                //Look into loop orders
                for(String site: strList){
                    if(domainToAccMap.containsKey(site) == false){
                       for(Account acc: accList){
                            String siteToCheck = site.substring(1, site.length()-1);
                            if((acc.website != null && acc.website.contains(siteToCheck)) || (acc.DUNS_URL__c != null && acc.DUNS_URL__c.contains(siteToCheck))){
                                    domainToAccMap.put(siteToCheck, acc.AKAM_Account_ID__c);
                                    break;
                            }
                        }
                    }
                }
            }
        }
        string jsonstring = JSON.serialize(domainToAccMap);
        return jsonstring;
    }
    
    public static List<List<String>> divideAndConquer(List<List<String>> finalSiteList, Integer divisor){
        
        Integer count = 0;
        Boolean requireFurtherSplitting = false;
        for(List<String> strList: finalSiteList){
           count  = [SELECT count() FROM Account WHERE website LIKE :strList OR DUNS_URL__c LIKE :strList];
            if(count > fetchCount){
                 requireFurtherSplitting =true;
            } 
        }
        if(requireFurtherSplitting == false){
            return finalSiteList;
        }else{
            List<List<String>> batchedSiteList = new List<List<String>>();
            for(List<String> strList: finalSiteList){
                Integer length = strList.size();
                Integer batchSize = (length/divisor) - 1;
                if(requireFurtherSplitting && (strList.size() > batchSize)){
                    Integer i = 0;
                    List<String> tempList = new List<String>();
                    for(String str: strList){
                        tempList.add(str);
                        if(i == batchSize){
                            i = 0;
                            if(!tempList.isEmpty()){
                                batchedSiteList.add(tempList);
                            	tempList = new List<String>();
                            }  
                        }else{
                          i++;
                        }
                    }
                }
            }
            if(!batchedSiteList.IsEmpty() && requireFurtherSplitting){
            	return divideAndConquer(batchedSiteList, divisor*2);
            }
        }
        return new List<List<String>>();
    } 
    
    /*
     * "SELECT Id, AKAM_Account_ID__c, Name, Type, Website, BillingCountry, " .
		"Account.Owner.Name, Account.Owner.Phone, Account.Owner.Email, Account.Owner.Alias, " .
		"AKAM_Modified_Date__c, DUNS_URL__c " .
		"FROM Account " .
		"WHERE Website LIKE '%.$domain%' OR Website LIKE '%//$domain' OR Website = '$domain' OR DUNS_URL__c LIKE '%.$domain%' OR DUNS_URL__c LIKE '%//$domain' OR DUNS_URL__c = '$domain' " .
		"ORDER BY AKAM_Modified_Date__c desc";
     */

}