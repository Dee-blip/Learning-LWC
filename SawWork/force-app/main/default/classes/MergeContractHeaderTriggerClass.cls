global class MergeContractHeaderTriggerClass
{
    public static void updateAccountPartnerStatus(List<Merge_Contract_Header__c> listOfContracts)
    {
        List<Id> listOfAccountIds = new List<Id>();
        Map<Id, List<Merge_Contract_Header__c>> mapOfAccountIdToContracts = new Map<Id, List<Merge_Contract_Header__c>>();
        Map<Id, Account> mapOfAccountIdToAccount = new Map<Id, Account>();
        for(Merge_Contract_Header__c mch : listOfContracts)
        {
            listOfAccountIds.add(mch.Account_Name__c);
        }
        
        for(Account tempAccount : [SELECT Id, Partner_Type__c, Partner_status__c from Account where Id in :listOfAccountIds])
        {
             mapOfAccountIdToAccount.put(tempAccount.Id, tempAccount);
        }
        List<Merge_Contract_Header__c> listOfMCH = [select Id, Partner_Type__c, Account_Name__c from Merge_Contract_Header__c where Account_Name__c in :mapOfAccountIdToAccount.keySet()];    
        
        for( Merge_Contract_Header__c tempMCH : listOfMCH )
        {
            if(!mapOfAccountIdToContracts.containsKey(tempMCH.Account_Name__c))
                mapOfAccountIdToContracts.put(tempMCH.Account_Name__c, new List<Merge_Contract_Header__c>());
            mapOfAccountIdToContracts.get(tempMCH.Account_Name__c).add(tempMCH);
        }
        
        Set<Account> setOfUpdatedAccounts = new Set<Account>();
        List<Account> listOfUpdatedAccounts = new List<Account>();
        for (Merge_Contract_Header__c contract : listOfContracts )
        {
            Account acc = mapOfAccountIdToAccount.get(contract.Account_Name__c);
            if(acc.Partner_Type__c!=null)
            {
                if(String.isBlank(contract.Partner_Type__c))
                {
                    Integer allNullContracts =1;
                    List<Merge_Contract_Header__c> associatedContracts = mapOfAccountIdToContracts.get(acc.Id);
                    for(Merge_Contract_Header__c otherContract : associatedContracts)
                    {
                        if(String.isNotBlank(otherContract.Partner_Type__c) && otherContract.Id!=contract.Id)
                        {
                            allNullContracts = 0;
                            break;
                         }
                    }
                    if(allNullContracts==1)
                    {
                        acc.put('Partner_status__c', 'Prospect');   
                    }
                    else
                    {
                        acc.put('Partner_status__c', 'Partner');
                    }                    
                }
                else
                {
                    acc.put('Partner_status__c', 'Partner');
                }
                acc.Validation_Override__c=true;
                if(!setOfUpdatedAccounts.contains(acc))
                {
                    setOfUpdatedAccounts.add(acc);
                    listOfUpdatedAccounts.add(acc);
                }
            }
        }
        update(listOfUpdatedAccounts);
    }

    public static void populateNAPMasterContractID(List<Merge_Contract_Header__c> mchAKAMNAPMasterUpdatedList)
    {
        Map<String, Id> akamIDToMCH = new Map<String, Id>();
        List<Id> listOfIdsWithUpdatedNAPMaster = new List<String>();
        for(Merge_Contract_Header__c tempMCH : mchAKAMNAPMasterUpdatedList)
        {
            listOfIdsWithUpdatedNAPMaster.add(tempMCH.Akam_NAP_Master_Contract_ID__c);
        }
        System.Debug('d_agh: listOfIdsWithUpdatedNAPMaster' + listOfIdsWithUpdatedNAPMaster);

        for(Merge_Contract_Header__c tempMCH : [select Id, Original_Contract_Id__c from Merge_Contract_Header__c where Original_Contract_Id__c in :listOfIdsWithUpdatedNAPMaster])
        {
            akamIDToMCH.put(tempMCH.Original_Contract_Id__c, tempMCH.Id);
        }

        System.Debug('d_agh: akamIDToMCH' + akamIDToMCH);

        List<Merge_Contract_Header__c> listOfMCHToBeUpdated = new List<Merge_Contract_Header__c>();

        for(Merge_Contract_Header__c ithMCH: mchAKAMNAPMasterUpdatedList)
        {
            Merge_Contract_Header__c tempMCH = new Merge_Contract_Header__c(Id=ithMCH.Id, NAP_Master_Contract__c=akamIDToMCH.get(ithMCH.Akam_NAP_Master_Contract_ID__c));
            listOfMCHToBeUpdated.add(tempMCH);
        }
        System.Debug('d_agh: listOfMCHToBeUpdated'+listOfMCHToBeUpdated);
        if(listOfMCHToBeUpdated.size()>0)
        {
            update listOfMCHToBeUpdated;
        }
    }
}