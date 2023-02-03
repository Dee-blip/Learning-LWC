/** This class is a daily job that copies NAP Master Partner System of Record (PSOR) values to the 
  1. Partner Accounts linked to that NAP Master Contract 
  2. Accounts associated with Reseller Contracts where the NAP Master Contract is linked to the Reseller Contract.

Author        Date        Description
Sonali Tandon   2/09/16       Created class.
                    SFDC-1137 : NAP -- PSOR NAP Master Data Copied to Account Header.
Ruchika Sharma  20/11/17       Updated class to accomodate new logic.
                    SFDC-2130 : PSOR -- Refresh Job that links Contract to Account Header.
**/

global class NAPContractPSORBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{

  global DMLResults results;
  global final String query;
  List<PSORMappingClass> psorList;
  Date todayDate ;
  List<String> trgList;

  global NAPContractPSORBatchClass()
  {
    trgList = new List<String>();
    String codeForDisabling = GsmUtilClass.getGSMSettingValue('ByPassForPSORBathcClass');
    trgList.addAll(codeForDisabling.split(','));
    String NAPPSORMapping = GSMSettings.getVerbose('NAP_PSOR_Mapping');
    psorList = PSORMappingClass.parse(NAPPSORMapping);
    System.debug(LoggingLevel.ERROR,'psorList: '+psorList);
    todayDate = Date.today();
    query = 'Select Id,Contract_Type__c,'+PSORMappingClass.allFieldsToQuery(psorList)+ 'Account_Name__c, Account_Name__r.Name from Merge_Contract_Header__c where (Contract_Type__c = \'NAP Master Agreement\' OR (Contract_Type__c LIKE \'%Reseller%\' AND NAP_Master_Contract__c!=null AND Effective_End_Date__c >=:todayDate )) AND Account_Name__c!=null AND Active__c = TRUE ORDER BY Account_Name__c';     
  }


  global Database.QueryLocator start(Database.BatchableContext BC)
  { 
        results= new DMLResults(); 
        System.debug(LoggingLevel.ERROR,'inside batch start');
        return Database.getQueryLocator(query); 
    }

      global void execute(Database.BatchableContext BC, List<sObject> scope)
    { 
        //String trg1 = '';
        
      System.debug(LoggingLevel.ERROR,'will disable trigger');
      ByPassAndLimitUtils.doRegisteration(trgList, 0);
      ByPassAndLimitUtils.disable(trgList);
      //byPassOpportunityShare = true;
      System.debug(LoggingLevel.ERROR,'iinside execute of NAPContractPSORBatchClass'+ByPassAndLimitUtils.isDisabled('OpportunityTriggerGeneric'));
      List<Merge_Contract_Header__c> listOfContracts  = (List<Merge_Contract_Header__c>)scope;
      if(listOfContracts.size()>0)
      {
        List<Id> listOfNAPMastersOfResellers = new List<Id>();
        Map<Id, Set<Id>> mapOfNAPMasterAgreementToSetOfAccountIds         = new Map<Id, Set<Id>>(); // update only unique set of accounts; same account can be tied to NAP Master Agreement and all Tier Resellers.
        Map<Id,Merge_Contract_Header__c> mapOfAccountIdToPSORDetails = new Map<Id,Merge_Contract_Header__c>();
        Map<Id,Merge_Contract_Header__c> mapOfNAPMasterAgreementToPSORDetails  = new Map<Id,Merge_Contract_Header__c>();
        List<Account> listOfAccountsToBeUpserted                = new List<Account>();
        for(Merge_Contract_Header__c mergeContractItem : listOfContracts)
        {
          if(mergeContractItem.Contract_Type__c == 'NAP Master Agreement')
          {
            if(mapOfNAPMasterAgreementToSetOfAccountIds.containsKey(mergeContractItem.Id))
              mapOfNAPMasterAgreementToSetOfAccountIds.get(mergeContractItem.Id).add(mergeContractItem.Account_Name__c);
            else
              mapOfNAPMasterAgreementToSetOfAccountIds.put(mergeContractItem.Id, new Set<Id> {mergeContractItem.Account_Name__c});

            // get the real deal ( NAP Master PSOR values)
            mapOfNAPMasterAgreementToPSORDetails.put(mergeContractItem.Id,mergeContractItem);
          }
          else
          {
            if(mapOfNAPMasterAgreementToSetOfAccountIds.containsKey(mergeContractItem.NAP_Master_Contract__c))
              mapOfNAPMasterAgreementToSetOfAccountIds.get(mergeContractItem.NAP_Master_Contract__c).add(mergeContractItem.Account_Name__c);
            else
              mapOfNAPMasterAgreementToSetOfAccountIds.put(mergeContractItem.NAP_Master_Contract__c, new Set<Id> {mergeContractItem.Account_Name__c});

            //used later as safety net
            listOfNAPMastersOfResellers.add(mergeContractItem.NAP_Master_Contract__c);
          }

          // this map was created to use the Account PSOR values 
          mapOfAccountIdToPSORDetails.put(mergeContractItem.Account_Name__c,mergeContractItem); 
        }
        
        //List of NAp master contract to populate it in account associated with resellers
        Set<Id> napMasterContract = new Set<Id>();
        //for(Merge_Contract_Header__c mhc : listOfNAPMastersOfResellers)
          napMasterContract.addAll(listOfNAPMastersOfResellers);
        List<Id> mapOfNAPMasterAgreementToPSORDetailsId = new List<Id>();
        mapOfNAPMasterAgreementToPSORDetailsId.addAll(mapOfNAPMasterAgreementToPSORDetails.keyset());
        String napMAQuery = 'Select Id,'+PSORMappingClass.contractFieldsToQuery(psorList)+'Contract_Type__c from Merge_Contract_Header__c where  Id IN :listOfNAPMastersOfResellers AND (NOT Id  IN :mapOfNAPMasterAgreementToPSORDetailsId)';
        // safety net just in case NAP Master Agreement isnt present in this batch
        for(sObject sobj : Database.query(napMAQuery))
        {
          Merge_Contract_Header__c mergeContractItem = (Merge_Contract_Header__c)sobj;
          mapOfNAPMasterAgreementToPSORDetails.put(mergeContractItem.Id,mergeContractItem);
        }

        if(mapOfNAPMasterAgreementToSetOfAccountIds.size()>0)
          listOfAccountsToBeUpserted = setPSORValues(mapOfNAPMasterAgreementToSetOfAccountIds,mapOfAccountIdToPSORDetails,mapOfNAPMasterAgreementToPSORDetails,napMasterContract);

        if(listOfAccountsToBeUpserted.size()>0)
          results.add(Database.upsert(listOfAccountsToBeUpserted,false),listOfAccountsToBeUpserted);
      }
    }

 global List<Account> setPSORValues(Map<Id, Set<Id>> mapOfNAPMasterAgreementToSetOfAccountIds,Map<Id,Merge_Contract_Header__c> mapOfAccountIdToPSORDetails,Map<Id,Merge_Contract_Header__c> mapOfNAPMasterAgreementToPSORDetails,Set<Id> napMasterContract)
    {
     // List<Account> listOfAccountsToBeUpserted = new List<Account>();
      Map<Id,Account> mapOfAccountIdToAccountName = new Map<Id,Account>();
      Boolean flag;

      for(Id napMasterAgreement : mapOfNAPMasterAgreementToSetOfAccountIds.keyset())
      {
        for(Id accountId : mapOfNAPMasterAgreementToSetOfAccountIds.get(napMasterAgreement))
        {
          

            flag          = FALSE;
            Account accountInstance = new Account(Id = accountId);
            Merge_Contract_Header__c mch = mapOfNAPMasterAgreementToPSORDetails.get(napMasterAgreement);
            Merge_Contract_Header__c mchAcc = mapOfAccountIdToPSORDetails.get(accountId);
            // time to save some DMLs 
            for(PSORMappingClass psor: psorList){
              //no need to check for NAP_Master_Contract__c here.
              if(!psor.accField.equals('NAP_Master_Contract__c')){
                System.debug(LoggingLevel.ERROR,'Account_Name__c:: '+mchAcc.Account_Name__c+' accField: '+psor.accField+' value: '+mchAcc.getSobject('Account_Name__r').get(psor.accField)+' mch: '+mch.id+' contractField: '+psor.contractField+' value: '+mch.get(psor.contractField));
                if(mchAcc.getSobject('Account_Name__r').get(psor.accField) != mch.get(psor.contractField))
                {
                  System.debug(LoggingLevel.ERROR,' diff for: '+mchAcc.Account_Name__c+' this: '+psor.accField);
                  accountInstance.put(psor.accField,mch.get(psor.contractField));
                  flag                                      = TRUE;
                }
              }
          }
          if(flag)
          {
            accountInstance.Validation_Override__c  = TRUE;
            accountInstance.Name = mapOfAccountIdToPSORDetails.get(accountId).Account_Name__r.Name; // setting account name in for record URL in case of failures.
            //if this NAP master agreement is present in napMasterContract list, then its NAP master contract of reseller and needs to be populated on account.
            if(napMasterContract.contains(napMasterAgreement))
              accountInstance.NAP_Master_Contract__c = napMasterAgreement;
              mapOfAccountIdToAccountName.put(accountId,accountInstance);
          }

        }
      }
      System.debug(LoggingLevel.ERROR,'mapOfAccountIdToAccount: '+mapOfAccountIdToAccountName+' size: '+mapOfAccountIdToAccountName.size());
      return mapOfAccountIdToAccountName.values();
    }
    
    global void finish(Database.BatchableContext BC)
    {
        results.withJobName('Update Account With NAP PSOR values from Contract').toAddress(GsmUtilClass.getGSMSettingValue('NAPContractPSORBatchClass_EmailId')).sendLogMail();
        results.withClassName('NAPContractPSORBatchClass').stampCronRunLog();
    }
      
}