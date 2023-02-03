/*

   Author - Anand Hegde Aug 19th 2016
   */

global class CurrentSalesChannelDeletionBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    global CurrentSalesChannelDeletionBatchClass()
    {
        query='Select CurrentSalesChannelExternalID__c, Id, Name from Current_Sales_Channel__c';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){ 
        results= new DMLResults(); 
        return Database.getQueryLocator(query); 
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Current_Sales_Channel__c> existingSummaryRecords = (List<Current_Sales_Channel__c>)scope;

        Set<Id> customerAccountIds = new Set<Id>();
        Map<String, Boolean> externalIdToNeedsDelete = new Map<String, Boolean>();
        Map<String, Id> externalIdToSFId = new Map<String, Id>();

        for(Current_Sales_Channel__c csc : existingSummaryRecords)
        {
            String[] accIds= csc.CurrentSalesChannelExternalID__c.split('#');
            customerAccountIds.add(accIds[0]);
            externalIdToNeedsDelete.put(csc.CurrentSalesChannelExternalID__c, true);
            externalIdToSFId.put(csc.CurrentSalesChannelExternalID__c, csc.Id);
        }

        List<String> contractTypes = GsmUtilClass.getGSMSettingValue('CurrentSalesChannelContractTypes').split(',');

        //for(AggregateResult detailRecord : [select Original_Contract_Id__r.Account_Name__c , Original_Contract_Id__r.Parent_Account_Name__c from  Merge_Contract_Detail__c where Original_Contract_Id__r.Active__c=true and Original_Contract_Id__r.isdeleted=false and Original_Contract_Id__r.Account_Name__c in :customerAccountIds and Original_Contract_Id__r.Contract_Type__c in :contractTypes group by Original_Contract_Id__r.Account_Name__c, Original_Contract_Id__r.Parent_Account_Name__c])
        for(merge_contract_header__c mch : [select Account_Name__c,Parent_Account_Name__c,Effective_End_Date__c,Contract_Type__c,Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__c,Parent_Contract__r.Account_Name__c,Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Account_Name__c,Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c
                        from merge_contract_header__c 
                        where Active__c=true and isdeleted=false and Contract_Type__c in :contractTypes and Account_Name__c in :customerAccountIds and Effective_End_Date__c >= TODAY])

        {
            String key = null;
            if(mch.Contract_Type__c == 'Direct Customer')
            {
                key = mch.Account_Name__c+'#'+null;
            }

            else
            {
                if(mch.Parent_Contract__c != null && mch.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Account_Name__c != null)
                         key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Account_Name__c;
                    else 
                         key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Account_Name__c;
                     
                }
                else if(mch.Parent_Contract__r.Parent_Contract__c != null && mch.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                         key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                    else
                         key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                }
                else if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c != null && mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                        key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                    else
                         key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                 }
                
            
            }
            externalIdToNeedsDelete.put(key, false);
        }
        /*for(AggregateResult mch : [select Account_Name__c, Parent_Account_Name__c from merge_contract_header__c where Active__c=true and isdeleted=false and Contract_Type__c in :contractTypes and Account_Name__c in :customerAccountIds group by Account_Name__c, Parent_Account_Name__c order by Account_Name__c])
        {
            String key = '';
            if(mch.get('Account_Name__c')==mch.get('Parent_Account_Name__c'))
                key = mch.get('Account_Name__c')+'#'+NULL;
            else
                key = mch.get('Account_Name__c')+'#'+mch.get('Parent_Account_Name__c');

            externalIdToNeedsDelete.put(key, false);
        }*/



        System.Debug(Logginglevel.Error, 'AGH_D externalIdToNeedsDelete'+externalIdToNeedsDelete);

        List<Current_Sales_Channel__c> summaryRecordsToBeDeleted = new List<Current_Sales_Channel__c>();
        for(Current_Sales_Channel__c csc : existingSummaryRecords)
        {
            System.Debug(Logginglevel.Error, 'AGH_D csc loop'+csc);
            
            if(externalIdToNeedsDelete.get(csc.CurrentSalesChannelExternalID__c))
            {
                summaryRecordsToBeDeleted.add(csc);
            }

        }


        if(summaryRecordsToBeDeleted.size()>0)
        {
            results.dmlDelete(summaryRecordsToBeDeleted);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        results.withJobName('Current Sales Channel Delete').toAddress(GsmUtilClass.getGSMSettingValue('CurrentSalesChannelEmailLogToAddress')).sendLogMail();
    }
}