/*
    Author - Hitesh - 18 May 2018
    Added Logic to get the EOL/EOS Product Summed up as EOL Products under Account 
    Modified By - Vivek Baidya on 10-April-2019 as part of SFDC-4502
*/

global class EOLProductsBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    Map<string,string> productToGroup;
    
    //Get all the marekting Product Names for EOl EOS with Engg product Name as EOl EOS
    global String enggEOLProductNameList = GsmUtilClass.getGSMSettingValue('EOL_EOS_Marketing_Product');
    global List<String> enggEOLFeatureNameList = new List<String>();
    
    global EOLProductsBatchClass()
    {
        productToGroup = new Map<string,string>();
        for(EOL_Product_Mapping__c mapObj : [select Id, Name, Is_Marketing_Product__c, Marketing_Product_Id__c, Product_Name__c from EOL_Product_Mapping__c limit 50000]){
            if(mapObj.Marketing_Product_Id__c != null)
                productToGroup.put(mapObj.Marketing_Product_Id__c, mapObj.Name);
            else
                productToGroup.put(mapObj.Product_Name__c, mapObj.Name);
        }
        //Get all Engineering Product names getting EOL
        for(GSM_Settings_Verbose__mdt enggEOLFeatureNameMDT : [select Id, Value__c,DeveloperName from GSM_Settings_Verbose__mdt where DeveloperName Like 'EOL_Product_Feature_List%'])
        {
            enggEOLFeatureNameList = enggEOLFeatureNameMDT.Value__c.split(',');
        }
        //Query all Marketing Products corresponding to above Engg Product and EOL Marketing Product Ids
        query='SELECT Name,Engineering_Product_Name__c,Marketing_Product_Id__c,Parent_Product_Id__c FROM Marketing_Product__c where Deleted_From_Siebel__c = false AND(Engineering_Product_Name__c = :enggEOLProductNameList OR Engineering_Product_Name__c IN :enggEOLFeatureNameList)';
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        results= new DMLResults(); 
        results.storeObjectState();
        return Database.getQueryLocator(query); 
    }
    
    //scope size is configured in metadata
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Marketing_Product__c> markProductList = (List<Marketing_Product__c>)scope;
        List<String> wholeEndOfLifeProducts = new List<String>();
        
        Set<String> marketingIDSet = new Set<String>();
        
        for(Marketing_Product__c mpRec :markProductList)
        {
            if(mpRec.Parent_Product_Id__c == null && mpRec.Engineering_Product_Name__c.contains('End_of_Life_Product'))
                wholeEndOfLifeProducts.add(mpRec.Marketing_Product_Id__c);
            marketingIDSet.add(mpRec.Marketing_Product_Id__c);
            if(mpRec.Parent_Product_Id__c != null)
                marketingIDSet.add(mpRec.Parent_Product_Id__c);
        }
        
        Map<String,List<Merge_Contract_Detail__c>> groupToCLIListMap = new Map<String,List<Merge_Contract_Detail__c>>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<String> contractMarketingIdSet = new Set<String>();
        for(Merge_Contract_Detail__c mchDetail : [select Id,Original_Contract_Id__c,Original_Contract_Id__r.Original_Contract_Id__c,Original_Contract_Id__r.Id  ,Original_Contract_Id__r.Account_Name__c, Product__c, Product_Id__c from Merge_Contract_Detail__c Where Product_Id__c IN :marketingIDSet AND Effective_Start_Date__c <= TODAY AND Effective_End_Date__c >= TODAY ])
        {
            if(!contractMarketingIdSet.contains(mchDetail.Original_Contract_Id__c+mchDetail.Product_Id__c))
            {
                accountIdSet.add(mchDetail.Original_Contract_Id__r.Account_Name__c);
                for(String mId : marketingIDSet){
                    groupToCLIListMap = new Map<String,List<Merge_Contract_Detail__c>>(mpOrEpKeyToCLIListMap(groupToCLIListMap,mId,mchDetail,productToGroup));
                }
            }
            contractMarketingIdSet.add(mchDetail.Original_Contract_Id__c+mchDetail.Product_Id__c);
        }
        
        Map<String,End_of_Life_Products__c> eolExternalIdToParent = new Map<String,End_of_Life_Products__c>();
        Map<String,Impacted_Contract_Lines__c> eolExternalIdToChild = new Map<String,Impacted_Contract_Lines__c>();
        for(End_of_Life_Products__c existingEOLRecords : [Select Account_Name__c, EndOfLifeProductsExternalID__c, EOL_Product__c, 
                                                          (select ImpactedProductLinesExternalID__c,Contract_Line_Item__c, End_of_Life_Product__c, EOL_Impact__c, Id, Original_Contract_ID__c, Product_ID__c,Product_Name__c 
                                                           from Impacted_Contract_Lines__r) from End_of_Life_Products__c 
                                                          Where Account_Name__c IN :accountIdSet])
        {
            eolExternalIdToParent.put(existingEOLRecords.EndOfLifeProductsExternalID__c,existingEOLRecords);
            for(Impacted_Contract_Lines__c eolChildRec : existingEOLRecords.Impacted_Contract_Lines__r)
            {
                eolExternalIdToChild.put(eolChildRec.ImpactedProductLinesExternalID__c,eolChildRec);
            }
        }
        
        List<End_of_Life_Products__c> eolMPUpsertList = new List<End_of_Life_Products__c>();
        List<Impacted_Contract_Lines__c> eolCLIUpsertList = new List<Impacted_Contract_Lines__c>();
        List<Impacted_Contract_Lines__c> iclToDelete = new List<Impacted_Contract_Lines__c>();
        List<End_of_Life_Products__c> eolToDelete = new List<End_of_Life_Products__c>();
        Map<String,Impacted_Contract_Lines__c> keyToICLMapToUpsert = new Map<String,Impacted_Contract_Lines__c>();
        
        for(String mpKey :groupToCLIListMap.keySet())
        {
            Id accId = (Id)mpKey.split('#')[0];
            Integer count;
            if(eolExternalIdToParent.containsKey(mpKey) )
            {
                count = 0;
                End_of_Life_Products__c existingParent = eolExternalIdToParent.get(mpKey);
                for(Merge_Contract_Detail__c mcd: groupToCLIListMap.get(mpKey))
                {
                    String impact;
                    if(wholeEndOfLifeProducts.contains(mcd.Product_Id__c))
                        impact = 'Whole Product';
                    else
                        impact = 'Feature Impacted';
                    String key = mcd.Original_Contract_Id__r.Id+'#'+mcd.Product_Id__c+'#'+mpKey;
                    if(eolExternalIdToChild.containsKey(key))
                    {
                        Impacted_Contract_Lines__c existingChild = eolExternalIdToChild.get(key);
                        if(mcd.Id != existingChild.Contract_Line_Item__c || impact == 'Whole Product')
                        {
                            existingChild.Contract_Line_Item__c = mcd.Id;
                            existingChild.EOL_Impact__c = impact;
                            keyToICLMapToUpsert.put(key,existingChild);
                        }
                    }
                    else
                    {
                        Impacted_Contract_Lines__c newRec = new Impacted_Contract_Lines__c(ImpactedProductLinesExternalID__c = key,EOL_Impact__c = impact,Contract_Line_Item__c = mcd.Id,Original_Contract_ID__c =mcd.Original_Contract_Id__r.Id,End_of_Life_Product__c =existingParent.Id,Product_Name__c =mcd.Product__c);
                        keyToICLMapToUpsert.put(key,newRec); 
                        
                        /*preparing list of impactedContractLine records which was under Undefined EOL Product; can be deleted when mapping of products is available*/
                        String tempChildKey = mcd.Original_Contract_Id__r.Id+'#'+mcd.Product_Id__c+'#'+accId+'#Undefined';
                        if(eolExternalIdToChild.containsKey(tempChildKey) && !iclToDelete.contains(eolExternalIdToChild.get(tempChildKey))){
                            iclToDelete.add(eolExternalIdToChild.get(tempChildKey));
                            count++;
                        }
                    }
                }
            }
            else
            {
                count = 0;
                End_of_Life_Products__c newParentRec = new End_of_Life_Products__c(Account_Name__c = accId, EndOfLifeProductsExternalID__c = mpKey, EOL_Product__c = mpKey.split('#')[1]);
                eolMPUpsertList.add(newParentRec);
                if(groupToCLIListMap.containsKey(mpKey))
                {
                    for(Merge_Contract_Detail__c mcd: groupToCLIListMap.get(mpKey))
                    {
                        String impact;
                        if(wholeEndOfLifeProducts.contains(mcd.Product_Id__c))
                            impact = 'Whole Product';
                        else
                            impact = 'Feature Impacted';
                        String key = mcd.Original_Contract_Id__r.Id+'#'+mcd.Product_Id__c+'#'+mpKey;
                        End_of_Life_Products__c eolParent = new End_of_Life_Products__c(EndOfLifeProductsExternalID__c= mpKey);
                        
                        /*preparing list of impactedContractLine records which was under Undefined EOL Product; can be deleted when mapping of products is available*/
                        String tempChildKey = mcd.Original_Contract_Id__r.Id+'#'+mcd.Product_Id__c+'#'+accId+'#Undefined';
                        if(eolExternalIdToChild.containsKey(tempChildKey) && !iclToDelete.contains(eolExternalIdToChild.get(tempChildKey))){
                            iclToDelete.add(eolExternalIdToChild.get(tempChildKey));
                            count++;
                        }
                        
                        Impacted_Contract_Lines__c newChildRec = new Impacted_Contract_Lines__c(ImpactedProductLinesExternalID__c = key,EOL_Impact__c=impact,Contract_Line_Item__c = mcd.Id,Original_Contract_ID__c =mcd.Original_Contract_Id__r.Id,Product_Name__c =mcd.Product__c);
                        newChildRec.End_of_Life_Product__r = eolParent;
                        keyToICLMapToUpsert.put(key,newChildRec);
                    }
                }
            }
            /*preparing list of eol records having Undefined EOL Product which can be deleted when mapping of products is available*/
            String tempParentKey = accId+'#Undefined';
            if(eolExternalIdToParent.containsKey(tempParentKey) && eolExternalIdToParent.get(tempParentKey).Impacted_Contract_Lines__r != null){
                if((eolExternalIdToParent.get(tempParentKey).Impacted_Contract_Lines__r.size() - count) == 0){
                    eolToDelete.add(eolExternalIdToParent.get(tempParentKey));
                }
            }
        }
        
        if(!keyToICLMapToUpsert.isEmpty())
            eolCLIUpsertList = keyToICLMapToUpsert.values();
        if(eolMPUpsertList.size()>0)
            results.add(Database.upsert(eolMPUpsertList,End_of_Life_Products__c.Fields.EndOfLifeProductsExternalID__c, false),eolMPUpsertList);
        if(eolCLIUpsertList.size()>0)
            results.add(Database.upsert(eolCLIUpsertList,Impacted_Contract_Lines__c.Fields.ImpactedProductLinesExternalID__c, false),eolCLIUpsertList);
        if(iclToDelete.size()>0)
            Database.delete(iclToDelete, false);
        if(eolToDelete.size()>0)
            Database.delete(eolToDelete, false);
    }
    
    global void finish(Database.BatchableContext BC)
    {
        results.withJobName('EOL Products Upsert').toAddress(GsmUtilClass.getGSMSettingValue('EOlProductsEmailLogToAddress')).sendLogMail();
    }
    
    /*preparing map of accountID#groupname as key and list of mergeContractDetails as value*/
    public static Map<String,List<Merge_Contract_Detail__c>> mpOrEpKeyToCLIListMap(Map<String,List<Merge_Contract_Detail__c>> mapObj, String mpId, Merge_Contract_Detail__c mchDetail, Map<string,string> productToGroupMap)
    {
        String key = '';
        String groupNames = '';
        if(mchDetail.Product_Id__c == mpId)
        {
            if(productToGroupMap.containsKey(mchDetail.Product_Id__c))
                groupNames = productToGroupMap.get(mchDetail.Product_Id__c);
            else if(productToGroupMap.containsKey(mchDetail.Product__c))
                groupNames = productToGroupMap.get(mchDetail.Product__c);
            else
                groupNames = 'Undefined';
            for(String groupName : groupNames.split(',')){
                groupName = groupName.trim();
                if(groupName!=null && groupName!='' && groupName!='null'){
                    key = mchDetail.Original_Contract_Id__r.Account_Name__c+'#'+groupName;
                    if(mapObj.containsKey(key) ) 
                    {          
                        List<Merge_Contract_Detail__c> tempList = new List<Merge_Contract_Detail__c>();
                        tempList = mapObj.get(key);
                        tempList.add(mchDetail);
                        mapObj.put(key,tempList);
                    }
                    else
                    {
                        List<Merge_Contract_Detail__c> tempList = new List<Merge_Contract_Detail__c>();
                        tempList.add(mchDetail);
                        mapObj.put(key,tempList);
                    }
                }
            }
        }
        return mapObj;
    }
}