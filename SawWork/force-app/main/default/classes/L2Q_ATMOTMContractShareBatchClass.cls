/*

   Author -  Hitesh - SFDC-5912
   Updated - SFDC-8272 Contract Share Create Logic Added
   */

global class L2Q_ATMOTMContractShareBatchClass extends GenericBatchClass
{
    //global final string query; 
    global DMLResults results;
    global List<Id> L2Q_ATMOTMContractIdContractIdSet;

     global L2Q_ATMOTMContractShareBatchClass()
     {
         super(); 

        operationType = 'Insert'; // update it to insert
        className = 'L2Q_ATMOTMContractShareBatchClass';
        //Get all the Contracts
        String L2Q_ATMOTMContractIds = GSMSettings.getVerbose('L2Q_ATMOTMContractIds');
        L2Q_ATMOTMContractIdContractIdSet = new List<Id>();

        if(!String.isEmpty(L2Q_ATMOTMContractIds))
        {
            for(String str : L2Q_ATMOTMContractIds.split(','))
                {
                    L2Q_ATMOTMContractIdContractIdSet.add((Id)str);
                }
        }

        if(system.Test.isRunningTest())
            query ='select Id, Account_Name__c, Opportunity_Name__c from merge_contract_header__c LIMIT 200';
        else if(L2Q_ATMOTMContractIdContractIdSet.size() > 0)
            query ='select Id, Account_Name__c, Opportunity_Name__c from merge_contract_header__c Where Id IN:L2Q_ATMOTMContractIdContractIdSet';
        else
            query ='select Id, Account_Name__c, Opportunity_Name__c from merge_contract_header__c ';
     }

     
     //Both Upsert and Delete to be called from same batch class - aayushi commented
     /*global Database.QueryLocator start(Database.BatchableContext BC){ 
         results= new DMLResults(); 
         results.storeObjectState();
         

         return Database.getQueryLocator(query); 
     }*/
    //Scope size is configured in metadata
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<merge_contract_header__c> mchScope = (List<merge_contract_header__c>)scope;
        Map<Id,Map<Id,Id>> contractIdToAccountOpptyMap = new Map<Id,Map<Id,Id>>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> opptyIdSet = new Set<Id>();
        Map<Id,List<AccountTeamMember>> accountToATMMap = new Map<Id,List<AccountTeamMember>>();
        Map<Id,List<OpportunityTeamMember>> opptyToOTMMap = new Map<Id,List<OpportunityTeamMember>>();
        Map<Id,Id> accountToOwnerMap = new Map<Id,Id>();
        Map<Id,Id> opptyToOwnerMap = new Map<Id,Id>();
        //List<Contract_Share__c> contractSharesToBeUpserted = new List<Contract_Share__c>();
        List<Merge_Contract_Header__Share> mchsToBeUpserted = new List<Merge_Contract_Header__Share>();

         


        //Populate the Account and Oppty Set for the Contract
        for(Merge_Contract_Header__c mch :mchScope)
        {
            Map<Id,Id> accOpptyMap = new Map<Id,Id>();
            accOpptyMap.put(mch.Account_Name__c,mch.Opportunity_Name__c);
            contractIdToAccountOpptyMap.put(mch.Id,accOpptyMap);
            accountIdSet.add(mch.Account_Name__c);
            if(mch.Opportunity_Name__c!= null)
            {
                opptyIdSet.add(mch.Opportunity_Name__c);
            } 
        }
        //Populate Account to it's Owner and Account to Team member Map
        for(Account acc : [Select Id, Owner.IsActive, OwnerId, 
                                    (Select Id, AccountId, UserId From AccountTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
                                    From Account WHERE Id IN : accountIdSet])
        { 
            for(AccountTeamMember accTM :acc.AccountTeamMembers)
            {
                if(!accountToATMMap.containsKey(acc.Id))
                {
                    List<AccountTeamMember> tempIdList = new List<AccountTeamMember>();
                    tempIdList.add(accTM);
                    accountToATMMap.put(accTM.AccountId,tempIdList);
                }
                else
                {
                    List<AccountTeamMember> tempIdList = new List<AccountTeamMember>();
                    
                       tempIdList =  accountToATMMap.get(accTM.AccountId);
                       tempIdList.add(accTM);
                       accountToATMMap.put(accTM.AccountId,tempIdList);
                     
                }
            }

            if(acc.Owner.IsActive)
                accountToOwnerMap.put(acc.Id,acc.OwnerId);

        }

        //Populate Opportunity to it's Owner and Oppty to Team member Map
        system.debug('Oppty Id Set '+opptyIdSet+ 'Map Acc Oppty '+contractIdToAccountOpptyMap);
        for(Opportunity opp : [Select Id, Owner.IsActive, OwnerId, 
                                    (Select Id, OpportunityId, UserId From OpportunityTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
                                    From Opportunity WHERE Id IN : opptyIdSet])
            {
                for(OpportunityTeamMember opptyTM: opp.OpportunityTeamMembers)
                {

                   if(!opptyToOTMMap.containsKey(opptyTM.OpportunityId))
                    {
                        List<OpportunityTeamMember> tempIdList = new List<OpportunityTeamMember>();
                        tempIdList.add(opptyTM);
                        opptyToOTMMap.put(opptyTM.OpportunityId,tempIdList);
                    }
                    else
                    {
                        List<OpportunityTeamMember> tempIdList = new List<OpportunityTeamMember>();
                        
                        tempIdList =  opptyToOTMMap.get(opptyTM.OpportunityId);
                        tempIdList.add(opptyTM);
                        opptyToOTMMap.put(opptyTM.OpportunityId,tempIdList);
                        
                    }
                }
            if(opp.Owner.IsActive)
                opptyToOwnerMap.put(opp.Id,opp.OwnerId); 
            }

    
    //Formulate Share Records for all the ATMs OTms and Owners for Accounts and Oppty's associated to Contract in scope
    for(Id contractId : contractIdToAccountOpptyMap.keySet())
    {
        for (Id accId : contractIdToAccountOpptyMap.get(contractId).keySet())
        {
            if(accountToATMMap.containsKey(accId))
            {
                for(AccountTeamMember atm: accountToATMMap.get(accId))
                {
                    /*contractSharesToBeUpserted.add(new Contract_Share__c(
                                Associated_User__c=atm.UserId, 
                                Associated_Account__c=atm.AccountId, 
                                Parent_Contract__c = contractId,
                                ATM_OTM_SF_Id__c = contractId+':'+atm.Id,
                                RowCause__c = 'ATM/OTM'));*/

                       mchsToBeUpserted.add(new Merge_Contract_Header__Share(
                                    AccessLevel = 'Read',
                                    ParentId = contractId,
                                    UserOrGroupId = atm.UserId
                                ));
                }
            }
            if(accountToOwnerMap.containsKey(accId))
            {
                /*contractSharesToBeUpserted.add(new Contract_Share__c(
                                Associated_User__c=accountToOwnerMap.get(accId), 
                                Associated_Account__c= accId, 
                                Parent_Contract__c = contractId,
                                ATM_OTM_SF_Id__c = contractId+':'+accId+':'+accountToOwnerMap.get(accId),
                                RowCause__c = 'Owner'));*/
                mchsToBeUpserted.add(new Merge_Contract_Header__Share(
                                    AccessLevel = 'Read',
                                    ParentId = contractId,
                                    UserOrGroupId = accountToOwnerMap.get(accId)
                                ));
            }
        }

        for (Id oppId : contractIdToAccountOpptyMap.get(contractId).values())
        {
            if(opptyToOTMMap.containsKey(oppId))
            {   
                for(OpportunityTeamMember otm: opptyToOTMMap.get(oppId))
                {
                    /*contractSharesToBeUpserted.add(new Contract_Share__c(
                                Associated_User__c=otm.UserId, 
                                Associated_Opportunity__c=otm.OpportunityId, 
                                Parent_Contract__c = contractId,
                                ATM_OTM_SF_Id__c = contractId+':'+otm.Id,
                                RowCause__c = 'ATM/OTM'));*/
                    mchsToBeUpserted.add(new Merge_Contract_Header__Share(
                                    AccessLevel = 'Read',
                                    ParentId = contractId,
                                    UserOrGroupId = otm.UserId
                                ));
                }
            }
            /*if(opptyToOwnerMap.containsKey(oppId))
            {
                contractSharesToBeUpserted.add(new Contract_Share__c(
                                Associated_User__c=opptyToOwnerMap.get(oppId), 
                                Associated_Opportunity__c= oppId, 
                                Parent_Contract__c = contractId,
                                ATM_OTM_SF_Id__c = contractId+':'+oppId+':'+opptyToOwnerMap.get(oppId),
                                RowCause__c = 'Owner'));
            }*/
        }
    }
    if(mchsToBeUpserted.size()>0)
    {
        //results.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
        /*results.add(Database.upsert(mchsToBeUpserted,false), mchsToBeUpserted);
        results.withClassName('L2Q_ATMOTMContractShareBatchClass').insertRecordsInErrorLog();*/
        //Database.upsert(mchsToBeUpserted,false);
         super.execute(BC, mchsToBeUpserted);
    }

        
    }

    global override void finish(Database.BatchableContext BC) 
    {
        System.Debug(LoggingLevel.Error, 'AGH_D finish method');
        super.finish(bc); 
        
    }
 }