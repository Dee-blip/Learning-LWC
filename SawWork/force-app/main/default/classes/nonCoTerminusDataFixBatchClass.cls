global class nonCoTerminusDataFixBatchClass implements Database.Batchable<Sobject>, Database.Stateful{
    global final string query;
    global DMLResults results;
    global integer insertCount;
    Set<Id> opportunityIdList = new Set<Id>();

    global nonCoTerminusDataFixBatchClass(){
        //List<Id> opportunityIdList = new List<Id>();
        for(Renewal_Contract_Object__c rco : [select id, Opportunity__r.id from Renewal_Contract_Object__c where id not in (select Associated_Contract__c from Renewal_Contract_Product__c) and Opportunity__r.isclosed = false]){
                opportunityIdList.add(rco.Opportunity__r.id);
        }
        //where id not in (select opportunity_product__c from Renewal_Contract_Product__c)
        insertCount = 0;
        String condition = GsmUtilClass.getGSMSettingValue('Query_Condition');
        if(condition.equalsIgnoreCase('true')){
            query = 'select id, Product_Akam_ID__c, OpportunityId from opportunitylineitem where opportunityId IN :opportunityIdList';
        }
        else{
            query = 'select id, Product_Akam_ID__c, OpportunityId from opportunitylineitem where opportunityId IN ' + condition;
        }
        //query = 'select id, Product_Akam_ID__c, OpportunityId from opportunitylineitem where opportunityId IN (Select id from Opportunity where IsClosed = false)';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        results= new DMLResults(); 
        results.storeObjectState();
        return Database.getQueryLocator(query);
    } 

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        List<OpportunityLineItem> OliList = (List<OpportunityLineItem>)scope;
        System.debug('OpportunityLineItem:'+OliList);
        Set<String> akamProductIdSet = new Set<String>();
        Map<String, Contract_Product__c> contractProductAkamIdToContractProduct = new Map<String, Contract_Product__c>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id, List<String>> mapOpptyIdToContractIdList = new Map<Id, List<String>>();
        Map<String, Id> mapOpptyPlusContractToRenewalContractObjectId = new Map<String, Id>();
        
        for(OpportunityLineItem oli : OliList){
            akamProductIdSet.add(oli.Product_Akam_ID__c);
            opportunityIdSet.add(oli.OpportunityId);
        }

        //List<Contract_Product__c> cpList = [Select id, Contract_Product_Akam_Id__c, Forecast_Product_Id__c, Effective_End_Date__c from Contract_Product__c where Forecast_Product_Id__c IN :akamProductIdList and Deleted_From_Source__c = false];
        for(Contract_Product__c cp : [Select id, Original_Contract_Id__r.Name, Contract_Product_Akam_Id__c, Forecast_Product_Id__c, Effective_End_Date__c from Contract_Product__c where Forecast_Product_Id__c IN :akamProductIdSet and Deleted_From_Source__c = false and Effective_End_Date__c != null limit 50000]){
            contractProductAkamIdToContractProduct.put(cp.Original_Contract_Id__r.Name + ' - ' + cp.Forecast_Product_Id__c , cp);
        }
		System.debug('contractProductAkamIdToContractProduct:'+contractProductAkamIdToContractProduct);
        for(Renewal_Contract_Object__c rco : [Select id, Contract__c, Opportunity__c, Contract__r.Original_Contract_Id__c from Renewal_Contract_Object__c where Opportunity__c IN :opportunityIdSet]){
            mapOpptyPlusContractToRenewalContractObjectId.put(rco.Opportunity__c + ':' + rco.Contract__r.Original_Contract_Id__c, rco.id);
            if(mapOpptyIdToContractIdList.keyset().contains(rco.Opportunity__c)){
                mapOpptyIdToContractIdList.get(rco.Opportunity__c).add(rco.Contract__r.Original_Contract_Id__c);
            }
            else{
                mapOpptyIdToContractIdList.put(rco.Opportunity__c, new List<String>{rco.Contract__r.Original_Contract_Id__c});
            }
        }
		System.debug('mapOpptyIdToContractIdList:'+mapOpptyIdToContractIdList);


        List<Renewal_Contract_Product__c> rcpList = new List<Renewal_Contract_Product__c>();
        for(OpportunityLineItem oli : OliList){
            if(mapOpptyIdToContractIdList.keyset().contains(oli.opportunityid)){
                for(String contractId :  mapOpptyIdToContractIdList.get(oli.opportunityid)){
                    String key = contractId + ' - ' + oli.Product_Akam_ID__c;
                    if(contractProductAkamIdToContractProduct.keyset().contains(key)){
                        Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
                        Contract_Product__c conProd = contractProductAkamIdToContractProduct.get(key);
                        acp.Associated_Contract__c = mapOpptyPlusContractToRenewalContractObjectId.get(oli.opportunityId + ':' + contractId);
                        acp.Opportunity_Product__c = oli.id;
                        acp.Contract_Product__c = conProd.id;
                        if(conProd.Effective_End_Date__c != null){
                            acp.End_Month__c = conProd.Effective_End_Date__c.year()+'-'+conprod.Effective_End_Date__c.month();
                        }
                        acp.name = conProd.Forecast_Product_id__c;
                        rcpList.add(acp);
                    }
                }
            }
        }

        if(rcpList.size() > 0){
            insertCount = insertCount + rcpList.size();
            results.add(Database.insert(rcpList, false),rcpList);
    
        }
    }

    global void finish(Database.BatchableContext BC){
        AsyncApexJob jobDetails = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        string finalResult = 'Status: '+jobDetails.Status+', Total Records: '+insertCount+', Success: '+(insertCount - jobDetails.NumberOfErrors)+', Failure: '+jobDetails.NumberOfErrors;
        results.withClassName('nonCoTerminusDataFixBatchClass').insertRecordsInErrorLog();
        results.withJobName('nonCoTerminusDataFixBatchClass').toAddress('smore@akamai.com').sendLogMail();
    }
}