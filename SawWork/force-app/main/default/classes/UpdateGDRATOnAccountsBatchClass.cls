global class UpdateGDRATOnAccountsBatchClass implements Database.Batchable<sObject>, Database.Stateful
{
 
     global Integer failedUpdates;
     global List<String> errorString ;
     global Set<Id> newuserIdSet = new Set<Id>();
     //global Set<Id> newuserRoleRuleIds = new Set<Id>();
     global Map<Id,Account_Reassignment_Rule__c> newuserIdToRuleMap= new Map<Id,Account_Reassignment_Rule__c>();
     global Map<Id,String> newuserIdToAKAMTerritoryIdMap= new Map<Id,String>();
     global Boolean errorFlag {get;set;}
     
     global UpdateGDRATOnAccountsBatchClass(Map<Id,Account_Reassignment_Rule__c> userIdToRuleMap,Set<Id> userIdSet,Map<Id,String> userIdToAKAMTerritoryIdMap)
     {
         failedUpdates = 0;
         errorFlag = false;
         errorString = new List<String>();
         newuserIdToRuleMap = userIdToRuleMap;
         newuserIdSet = userIdSet;
         newuserIdToAKAMTerritoryIdMap = userIdToAKAMTerritoryIdMap;
        // newuserRoleRuleIds = userRoleRuleIds;
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC)
     {

        System.debug('User id set' + newuserIdSet );
          return Database.getQueryLocator([Select AKAM_Account_ID__c,Akam_Territory_Mapping_Id__c,OwnerId,Id,Name,TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c,/*Parent_Division__c,Division__c,Region__c,Area__c,*/Anaplan_Sub_Territory__c, Validation_Override__c FROM Account WHERE OwnerId IN : newuserIdSet]);
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        
        System.Debug('checkpoint X: in execute' + scope);
        List<Account> listOfAccounts = (List<Account>)scope;
        Map<Id,List<Account>> userIdToAccountsMap = new Map<Id,List<Account>> ();
        List<Account> listOfAccountsToUpdate = new List<Account>();
        List<Account_Reassignment_Rule__c> resetGDRATOnRuleList = new List<Account_Reassignment_Rule__c>();
        
        // create a map of user->user's accounts
        for(Account acc : listOfAccounts)
        {
            if (!userIdToAccountsMap.containsKey(acc.OwnerId))
                userIdToAccountsMap.put(acc.OwnerId, new  List<Account>{acc});
            else
                userIdToAccountsMap.get(acc.OwnerId).add(acc);          
        }
        System.debug('userIdToAccountsMap' +userIdToAccountsMap.size());
        
        // populate each account's GDRAT with the rule's GDRAT
        //CR 2987156 populate each account's Akam territory ID with the rule's Akam territory ID 
        for(Id userId : userIdToAccountsMap.keySet())
        {
            for(Account account : userIdToAccountsMap.get(userId))
            {
                System.debug('account ' + account.Name);
                account.TERR_HIER_1__c = newuserIdToRuleMap.get(userId).TERR_HIER_1__c;
                account.TERR_HIER_2__c = newuserIdToRuleMap.get(userId).TERR_HIER_2__c;
                account.TERR_HIER_3__c = newuserIdToRuleMap.get(userId).TERR_HIER_3__c;
                account.TERR_HIER_4__c = newuserIdToRuleMap.get(userId).TERR_HIER_4__c;
                account.TERR_HIER_5__c = newuserIdToRuleMap.get(userId).TERR_HIER_5__c;
                account.Anaplan_Sub_Territory__c = newuserIdToRuleMap.get(userId).SubTerritory__c;
                account.Akam_Territory_Mapping_Id__c = newuserIdToAKAMTerritoryIdMap.get(userId);
                account.Validation_Override__c = true;
                listOfAccountsToUpdate.add(account);
            }

            // reset Change Associated Account checkbox = false
            Account_Reassignment_Rule__c accReassignmentRule = new Account_Reassignment_Rule__c(Id = newuserIdToRuleMap.get(userId).Id);
            accReassignmentRule.Changed_GDRAT__c = false;
            resetGDRATOnRuleList.add(accReassignmentRule);
        }
        System.debug('listOfAccountsToUpdate size' +listOfAccountsToUpdate.size());
        Database.SaveResult[] resultsOfAccountUpdate;
        
        if(resetGDRATOnRuleList.size()>0)
            update resetGDRATOnRuleList;
        if(listOfAccountsToUpdate.size()>0)
          resultsOfAccountUpdate = Database.update(listOfAccountsToUpdate, false);

        Integer count=0;
        String reassignmentRuleURL;
        String accountURL;
        String baseUrl;
        for (Database.SaveResult sr : resultsOfAccountUpdate) 
        {
            System.Debug('Checkpoint X: in saveresults for loop');
            if (!sr.isSuccess()) 
            {                errorFlag = true; 
                for(Database.Error err : sr.getErrors()) 
                {         
                    baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                    accountURL = '<a href="'+ baseUrl+ listOfAccountsToUpdate[count].Id +'">' + listOfAccountsToUpdate[count].Name + '</a>';           
                    reassignmentRuleURL = '<a href="'+ baseUrl+ newuserIdToRuleMap.get(listOfAccountsToUpdate[count].OwnerId).Id +'">' + newuserIdToRuleMap.get(listOfAccountsToUpdate[count].OwnerId).Name + '</a>';           
                    errorString.add('<tr>' + '<td>'+ listOfAccountsToUpdate[count].AKAM_Account_ID__c +'</td>'+'<td>'+ accountURL +'</td>'+ '<td>' + reassignmentRuleURL +'</td>'+'<td>' + err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                    failedUpdates = failedUpdates + 1;
                }
            }      
             count = count +1;   
        }
    }
        

    global void finish(Database.BatchableContext BC)
    {

        AsyncApexJob a = [SELECT id, ApexClassId, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE id = :BC.getJobId()];
        
         String emailMessage = 'Updation of GRATZ field on accounts has finished.  It executed ' + a.totalJobItems + ' batches.  Of which, '+ a.jobitemsprocessed + ' processed without any  exceptions '+ 'thrown and '+ a.numberOfErrors + ' batches threw unhandled exceptions.'
        + '  Of the batches that executed without error, ' + failedUpdates + ' records were not updated.';
       
        String tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Account AKAM ID</th><th>Account</th><th>Account Reassignment Rule</th><th>Error</th><th>Error Field</th></tr>';  
        
        // update user roles at the end 
        //if(newuserRoleRuleIds.size()>0)
        //{
        //    AccountReassignmentRuleTriggerClass.UpdateOwnerRole(newuserRoleRuleIds);
        //}

         if(errorFlag)
         {
            emailMessage = emailMessage + '<br/>' +tableBegin;
             for( String str : errorString)
             {
                 emailMessage = emailMessage +  str;
             }
             emailMessage = emailMessage + '</table>';
         }
         
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         //String emailAddresses = GSM_Custom_Settings__c.getInstance('UpdateGDRATBatch#ErrorMail').value__c; //SFDC-2304
         String emailAddresses = GsmUtilClass.getGSMSettingValue('UpdateGDRATBatch_ErrorMail'); //SFDC-2304
         System.debug('custom'+emailAddresses);
         String[] toAddresses = emailAddresses.split(',');
         System.debug('toaddresses'+toAddresses);
         mail.setToAddresses(toAddresses);
         mail.setReplyTo('noreply@salesforce.com');
         mail.setSenderDisplayName('Batch Job Summary');
         mail.setSubject('Batch job completed');
         mail.setPlainTextBody(emailMessage);
         mail.setHtmlBody(emailMessage);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

    }
}