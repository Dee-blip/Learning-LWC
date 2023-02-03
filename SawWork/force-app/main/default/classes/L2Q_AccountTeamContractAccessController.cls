public without sharing class L2Q_AccountTeamContractAccessController {

    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        return theme;
    }
    
    @AuraEnabled
    public static String refreshAccountContractAccess(Id genericRecordID) {
        
        List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
        Map<Id,List<Id>> contractIdToUserIdListMap = new Map<Id,List<Id>>();
        Map<Id,List<Id>> accountToATMMap = new Map<Id,List<Id>>();
        Map<Id,List<Id>> opptyToOTMMap = new Map<Id,List<Id>>();

        DMLResults insertResults = new DMLResults();

        system.debug('Account Id '+genericRecordID);
        

        Map<Id,Map<Id,List<Id>>> accountOrOpptyToContractToUserList = new Map<Id,Map<Id,List<Id>>>();
        List<Merge_Contract_Header__Share> mchShareList = new List<Merge_Contract_Header__Share>();
        //Get all Account Team/Opportunity Team members and populate Map of Account/Oppty Id to List of related Team members
        if(genericRecordID != null)
        {
            for(AccountTeamMember accTM : [Select Id,AccountId, UserId From AccountTeamMember Where AccountId =: genericRecordID])
                
            {
                if(!accountToATMMap.containsKey(accTM.AccountId))
                {
                    List<Id> tempIdList = new List<Id>();
                    tempIdList.add(accTM.UserId);
                    accountToATMMap.put(accTM.AccountId,tempIdList);
                }
                else
                {
                    List<Id> tempIdList = new List<Id>();
                    
                       tempIdList =  accountToATMMap.get(accTM.AccountId);
                       tempIdList.add(accTM.UserId);
                       accountToATMMap.put(accTM.AccountId,tempIdList);
                     
                }      
            }
            for(OpportunityTeamMember opptyTM : [Select Id,OpportunityId, UserId From OpportunityTeamMember Where  Opportunity.AccountId =: genericRecordID ])
            {
                if(!opptyToOTMMap.containsKey(opptyTM.OpportunityId))
                {
                    List<Id> tempIdList = new List<Id>();
                    tempIdList.add(opptyTM.UserId);
                    opptyToOTMMap.put(opptyTM.OpportunityId,tempIdList);
                }
                else
                {
                    List<Id> tempIdList = new List<Id>();
                    
                       tempIdList =  opptyToOTMMap.get(opptyTM.OpportunityId);
                       tempIdList.add(opptyTM.UserId);
                       opptyToOTMMap.put(opptyTM.OpportunityId,tempIdList);
                     
                } 
            }
            system.debug('Acc Map '+accountToATMMap +' Oppty Map '+opptyToOTMMap);
            //Get all the Contract Share records for Contracts associated to Account and all related Opportunities.

            for(Merge_Contract_Header__Share mchShare : [Select Parent.Account_Name__c,Parent.Opportunity_Name__c, ParentId, Id, AccessLevel,UserOrGroupId FROM 
            Merge_Contract_Header__Share Where Parent.Account_Name__c = :genericRecordID OR Parent.Opportunity_Name__c IN :opptyToOTMMap.keySet()  ])
            {
                //Map of Account to Contracts and Contracts to ContractShares
                
                if(accountToATMMap.containsKey(mchShare.Parent.Account_Name__c))
                {
                    if(!accountOrOpptyToContractToUserList.containsKey(mchShare.Parent.Account_Name__c))
                    {
                        Map<Id,List<Id>> tempMap = new Map<Id,List<id>>();
                        List<id> tempList = new List<Id>();
                        tempList.add(mchShare.UserOrGroupId);
                        tempMap.put(mchShare.ParentId,tempList);
                        accountOrOpptyToContractToUserList.put(mchShare.Parent.Account_Name__c,tempMap);
                    }
                    else
                    {
                        Map<Id,List<Id>> tempMap = new Map<Id,List<id>>();
                        tempMap = accountOrOpptyToContractToUserList.get(mchShare.Parent.Account_Name__c);
                        if(!tempMap.containsKey(mchShare.ParentId))
                        {
                            
                            tempMap.put(mchShare.ParentId, new List<Id>());
                        }
                        
                            
                            tempMap.get(mchShare.ParentId).add(mchShare.UserOrGroupId);
                            
                    }
                    system.debug('=== Parent to Contract Account 1st === '+accountOrOpptyToContractToUserList);


                }

                //Map of Opportunity to Associated Contracts and Contracts to ContractShares
                if(opptyToOTMMap.containsKey(mchShare.Parent.Opportunity_Name__c))
                {
                    if(!accountOrOpptyToContractToUserList.containsKey(mchShare.Parent.Opportunity_Name__c))
                    {
                        Map<Id,List<Id>> tempMap = new Map<Id,List<id>>();
                        List<id> tempList = new List<Id>();
                        tempList.add(mchShare.UserOrGroupId);
                        tempMap.put(mchShare.ParentId,tempList);
                        accountOrOpptyToContractToUserList.put(mchShare.Parent.Opportunity_Name__c,tempMap);
                    }
                    else
                    {
                        Map<Id,List<Id>> tempMap = new Map<Id,List<id>>();
                        tempMap = accountOrOpptyToContractToUserList.get(mchShare.Parent.Opportunity_Name__c);
                        if(!tempMap.containsKey(mchShare.ParentId))
                        {
                            
                            tempMap.put(mchShare.ParentId, new List<Id>());

                        }
                        
                        tempMap.get(mchShare.ParentId).add(mchShare.UserOrGroupId);

                        system.debug('Inside Else  Under Else - Temp Map '+tempMap);

                         
                    }
                system.debug('=== Parent to Contract Oppty 1st === '+accountOrOpptyToContractToUserList);

                }
                system.debug('Parent to Contract Oppty/Account 2nd'+accountOrOpptyToContractToUserList);



            }
            //for ends here
                        
        //Loop through all Account, compare Share records against TeamMembers to find the Diff and create new
        if(!accountToATMMap.isEmpty())
        {
            for(Id accountId :accountToATMMap.keySet())
            {
                if(accountOrOpptyToContractToUserList.containsKey(accountId))
                {
                    for(Id contractId : accountOrOpptyToContractToUserList.get(accountId).keySet() )
                    {
                        List<Id> userIDList = accountOrOpptyToContractToUserList.get(accountId).get(contractId);
                        for(Id userID : accountToATMMap.get(accountId))
                        {
                            if(!userIDList.contains(userID))
                            {
                              Merge_Contract_Header__Share mchShare = new  Merge_Contract_Header__Share(AccessLevel = 'Read', UserOrGroupId = userID, ParentId = contractId);
                              mchShareList.add(mchShare);
 
                            }
                        }
                        
                    }
                }
            }
            
        }
        //Loop through all Opportunity, compare Share records against TeamMembers to find the Diff and create new

        if(!opptyToOTMMap.isEmpty())
        {
            for(Id opptyId :opptyToOTMMap.keySet())
            {
                if(accountOrOpptyToContractToUserList.containsKey(opptyId))
                {
                    for(Id contractId : accountOrOpptyToContractToUserList.get(opptyId).keySet() )
                    {
                        List<Id> userIDList = accountOrOpptyToContractToUserList.get(opptyId).get(contractId);
                        for(Id userID : opptyToOTMMap.get(opptyId))
                        {
                            if(!userIDList.contains(userID))
                            {
                              Merge_Contract_Header__Share mchShare = new  Merge_Contract_Header__Share(AccessLevel = 'Read', UserOrGroupId = userID, ParentId = contractId);
                              mchShareList.add(mchShare);
 
                            }
                        }
                        
                    }
                }
            }
            
        }

        
    }
    
    try{
          if(mchShareList.size()>0)
            insertResults.add(Database.insert(mchShareList,false),mchShareList);
            return 'Success';
             
        }

    catch(DmlException e) {
            system.debug(Logginglevel.ERROR,'Error Message '+e.getMessage());

            String errorMessage = null;
            errorMessage = e.getMessage();
            
            Error_Log__c elc = new Error_Log__c(Name='', Class__c='L2Q_AccountTeamContractAccessController', Error_Message__c=e.getMessage());
            insert elc;
            
            return errorMessage;
        }

      
        
    //return 'Success';
        
    }

}