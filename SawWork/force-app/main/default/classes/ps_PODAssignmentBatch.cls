/* 
/*********************************************************************************************************************
 * JIRA             : ESESP-5250
 * Author           : Sujay Surendranath
 * Created Date     : 03-23-2022
 * Purpose          : To Handle Delivery POD Process in the system on Assigning POD at Account & Account Dept Level
 
 /********************************************************************************************************************
*/ 

public class ps_PODAssignmentBatch implements Database.Batchable<sObject>, Database.Stateful{

	public String 		 query;
    public Set<String>   accOrDepIds;
    public String 		 podRecordId;
    

	    
    public ps_PODAssignmentBatch()
    {
        
    }
    
     public Database.QueryLocator start(Database.BatchableContext BC) 
     {
        System.debug('accOrDepIds :: '+ accOrDepIds);

        System.debug('podRecordId :: ' + podRecordId);
         if(query == null)
        {
			query = 'SELECT Id, Name, ReportId__c, Report_link__c, Updating_Object__c, Active__c, Batch_Process__c  FROM POD_Association__c WHERE Id = \'' + podRecordId + '\' AND Batch_Process__c = true ';
            system.debug('query : ' + query);
            if(Test.isRunningTest())
            {
                query += ' limit 1';
            }
        }
        return Database.getQueryLocator(query);
         
     }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<POD_Association__c> lstPODs = (List<POD_Association__c>)scope;
         
        List<Account> 					assignPODsForAcc = new List<Account>();
        List<Account_Department__c> assignPODsForAccDept = new List<Account_Department__c>();

        String podName, podId;

        System.debug('accOrDepIds :: '+ accOrDepIds);
        System.debug('accOrDepIds :: '+ accOrDepIds.size());

        for(POD_Association__c ePod: lstPODs)
        {
            podName = ePod.Name;
            podId   = ePod.Id;


            if(ePod.Updating_Object__c == 'Account')
            {
                for(Account eAcc : [SELECT Id, POD_Association__c from Account where Id In: accOrDepIds])
                {
                    Account acc = new Account();
                    acc.POD_Association__c = ePod.Id;
                    acc.Id = eAcc.Id;
                    assignPODsForAcc.add(acc);
                    System.debug(acc);
                }
            }
            else if(ePod.Updating_Object__c == 'Account Dept') 
            {
                for(Account_Department__c eAccDept : [SELECT Id, POD_Association__c from Account_Department__c where Id In: accOrDepIds])
                {
                    eAccDept.POD_Association__c = ePod.Id;
                    assignPODsForAccDept.add(eAccDept);
                    System.debug(eAccDept);
                }
            }
            else if(ePod.Updating_Object__c == 'Account & Account Dept')
            {
                Set<String> accountIds = new Set<String>();
                for(Account_Department__c  eAccDept : [SELECT Id, POD_Association__c, Account_Name__r.POD_Association__c, Account_Name__c, Account_Name__r.AKAM_Account_ID__c  from Account_Department__c  where Id In: accOrDepIds])
                {
                    eAccDept.POD_Association__c = ePod.Id;
                    assignPODsForAccDept.add(eAccDept);
                    System.debug(eAccDept);
                    
                    if(! accountIds.contains(eAccDept.Account_Name__c))
                    {
                        assignPODsForAcc.add(new Account(Id = eAccDept.Account_Name__c, POD_Association__c = ePod.Id));
                        accountIds.add(eAccDept.Account_Name__c);
                    }
                }
            }
            else 
            {
                System.debug('objName is out of scope' + ePod.Updating_Object__c);
            }
        }

        List<sObject> mergeLists = new List<sObject>();

        if(!assignPODsForAcc.isEmpty() )
        {
            System.debug('assignPODsForAcc :: ' + assignPODsForAcc);
            mergeLists.addAll(assignPODsForAcc);
            //Database.SaveResult[] saveResults = Database.update(assignPODsForAcc, false);
            //PS_PODTriggerClass.populateErrorTableForUpdate(saveResults, assignPODsForAcc, podName, podId);

        }

        if(!assignPODsForAccDept.isEmpty())
        {
            mergeLists.addAll(assignPODsForAccDept);
            // Database.SaveResult[] saveResults = Database.update(assignPODsForAccDept, false);
            // PS_PODTriggerClass.populateErrorTableForUpdate(saveResults, assignPODsForAccDept,podName, podId);

        }

        Database.SaveResult[] saveResults = Database.update(mergeLists, false);
        PS_PODTriggerClass.populateErrorTableForUpdate(saveResults, mergeLists,podName, podId);    
        
    }
    
	public void finish(Database.BatchableContext BC) 
    {
        POD_Association__c unLockPod = new POD_Association__c();
        unLockPod.Id = podRecordId;
        unLockPod.Batch_Process__c = false;
        update unLockPod;
	}
    
}