/** Sonali Tandon       24.08.2015  CR 3126751 - Engagement level to differentiate accounts in salesforce
1.Customer- All accounts whose account status contains an Active status value. The where clause of the query should filter for account status

2.Sales Engaged- Acc status is inactive or lead +Query all Opportunities whose stage is Open) and add all the related account id's to the set. Once you have all the account Id's filter only those accounts whose status contains Lead or Inactive values.

3.Marketing Engaged-
Query all activities on contacts which has subject "Opened Email" and activity created by Marketo user. The activity/Task should be created in last 90 days. Take all the unique related to account Id's 
OR
Query all the campaign member object where type= contact and status=responded and member status updated date in last 180 days and retrieve its related account
OR
Query all leads created by contact in last 180 days 
OR
Marketing Opportunity(QFA), pull all opportunities where QFA Compensated is "Yes" for Outbound Opportunity or QFA Compensated is "Inbound" for in bound Opportunity and to calculate last 180 days use Created/Accepted Date- Marketing. Pull all its related account

4.No Engagement -This field should be checked when Account Status is Inactive or Lead and no active(either all closed or no opptys) opportunity is associated with the account.
*/

global class CronAccountEngagementLevelBatchClass implements Database.Batchable<sObject>, Database.Stateful
{    
     global Integer failedUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
    
     
    global CronAccountEngagementLevelBatchClass()
     {
         failedUpdates = 0;
         errorFlag = false;
         errorString = new List<String>();
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC)
     {
          return Database.getQueryLocator([Select Id,Name,AKAM_Account_ID__c,Type,Validation_Override__c,Engagement_Level__c,Account_Status__c,Total_No_of_Opportunities__c from Account]);
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        System.Debug('checkpoint X: in execute' + scope);
        List<Account> listOfAccounts = (List<Account>)scope;
        Set<Id> setOfAccountIds = new Set<Id>();
        Set<Id> setOfAccountsIdsToUpdate =new Set<Id>();
        Set<Id> setOfMarketingAccountIdsTrue = new Set<Id>();
        Set<Id> setOfMarketingAccountIdsFalse = new Set<Id>();
        Set<Id> setOfMarketingAccountIdsToUpdate = new Set<Id>();
        List<Account> listOfAccountsToUpdate = new List<Account>();
        Set<Id> listOfAccountsWithNoOpptys = new Set<Id>();
        Set<Id> listOfAccountsWithOpptys = new Set<Id>();
        Set<Id> temporarySet = new Set<Id>();
        Map<Id,List<Opportunity>> mapOfAccountToOpptys = new Map<Id,List<Opportunity>>();
        Map<Id,Account> mapOfAccountIdToAccounts = new Map<Id,Account>();
        //String marketoSyncUserId = GSM_Custom_Settings__c.getInstance('CronAccEngagementLevel#MarketoId').value__c; //SFDC-2304
        String marketoSyncUserId = GsmUtilClass.getGSMSettingValue('CronAccEngagementLevel_MarketoId'); //SFDC-2304
        System.debug('marketo user id' + marketoSyncUserId);
        Boolean openOpptyFlag;
        Database.SaveResult[] results;
        Integer count=0;


        Id businessContactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        Map<String,Schema.RecordTypeInfo> leadRecordTypeInfo  = Schema.SObjectType.Lead.getRecordTypeInfosByName();
        Id inboundLeadRecordTypeId = leadRecordTypeInfo.get('Account Development - Inbound').getRecordTypeId();
        Id outboundLeadRecordTypeId = leadRecordTypeInfo.get('Account Development - Outbound').getRecordTypeId();
        
        System.debug('Business recordtype id'+ businessContactRecordTypeId);
        
        System.debug('records in scope'+ listOfAccounts.size());
        
        if(listOfAccounts.size()>0)
        {
           for(Account acc : listOfAccounts)
           {
               setOfAccountIds.add(acc.Id);
               mapOfAccountIdToAccounts.put(acc.Id,acc);

               if(acc.Total_No_of_Opportunities__c == 0)
               {
                // if acc status is lead/contains inactive and it has no opptys attached to it --> Not Engaged 
                   if((acc.Account_Status__c.contains('Inactive') || acc.Account_Status__c =='Lead') && !acc.Engagement_Level__c.contains('No Engagement'))
                   {
                        acc.Engagement_Level__c = 'No Engagement';
                        listOfAccountsWithNoOpptys.add(acc.Id);
                        setOfAccountsIdsToUpdate.add(acc.Id);
                             
                   } 
                   // if acc status is Active and has no opptys attached to it -->Customer
                    if(acc.Account_Status__c.contains('Active') && !acc.Engagement_Level__c.contains('Customer Engaged'))
                    {
                        acc.Engagement_Level__c  = 'Customer Engaged';
                        listOfAccountsWithNoOpptys.add(acc.Id);
                        setOfAccountsIdsToUpdate.add(acc.Id);
                        
                    }
                
               }
           }

           temporarySet.addAll(setOfAccountIds);
           temporarySet.removeAll(listOfAccountsWithNoOpptys);
           listOfAccountsWithOpptys.addAll(temporarySet);

            if(listOfAccountsWithOpptys.size()>0) {
           // create map of account id -> list of it's opportunities
           for(Opportunity opp : [Select Id,RecordTypeId, AccountId,StageName,QFA_Compensated__c,Created_Accepted_Date_Marketing__c from Opportunity where AccountId In : setOfAccountIds])
            {
                
                if (!mapOfAccountToOpptys.containsKey(opp.AccountId))
                    mapOfAccountToOpptys.put(opp.AccountId, new  List<Opportunity>{opp});
                else
                    mapOfAccountToOpptys.get(opp.AccountId).add(opp);   
                
            }

           // go through accounts with opportunities
        for(Id accId :mapOfAccountToOpptys.keySet())
        {
            System.debug('Id, Account Status ' + accId + mapOfAccountIdToAccounts.get(accId).Account_Status__c);
            openOpptyFlag = false;
        
            for(Opportunity oppty :mapOfAccountToOpptys.get(accId))
            {
                System.debug(' Status, Id, Stage, QFA, ' +  mapOfAccountIdToAccounts.get(accId).Account_Status__c + oppty.Id + oppty.StageName + oppty.QFA_Compensated__c + oppty.Created_Accepted_Date_Marketing__c);

                if(!oppty.StageName.contains('Closed'))
                    openOpptyFlag = true;       
                        
                if((oppty.QFA_Compensated__c =='Yes' || oppty.QFA_Compensated__c =='Inbound') && oppty.Created_Accepted_Date_Marketing__c > System.today().addDays(-180))
                {
                    System.debug('marketing id' + accId);
                    setOfMarketingAccountIdsTrue.add(accId);
                } 
                
            }
             System.debug('AccId, openOpptyFlag ' + openOpptyFlag + accId );

            // if acc status is lead/contains inactive and it has no open opptys / no opptys attached to it --> Not Engaged 
            if((mapOfAccountIdToAccounts.get(accId).Account_Status__c.contains('Inactive') || mapOfAccountIdToAccounts.get(accId).Account_Status__c =='Lead')
                && !openOpptyFlag)
            {
               System.debug('accid no engagement' + accId);
               if(!mapOfAccountIdToAccounts.get(accId).Engagement_Level__c.contains('No Engagement'))
               {
                 mapOfAccountIdToAccounts.get(accId).Engagement_Level__c = 'No Engagement';
                 setOfAccountsIdsToUpdate.add(accId);
               }
            }
            else
            {
                // if acc status is lead/contains inactive and it has open opptys attached to it --> sales engaged
                if((mapOfAccountIdToAccounts.get(accId).Account_Status__c.contains('Inactive') || mapOfAccountIdToAccounts.get(accId).Account_Status__c =='Lead')
                && (openOpptyFlag && !mapOfAccountIdToAccounts.get(accId).Engagement_Level__c.contains('Sales Engaged')))
                {
                    mapOfAccountIdToAccounts.get(accId).Engagement_Level__c = 'Sales Engaged';
                    setOfAccountsIdsToUpdate.add(accId);
                  
                }

                // if acc status contains Active -->Customer
                if(mapOfAccountIdToAccounts.get(accId).Account_Status__c.contains('Active') && !mapOfAccountIdToAccounts.get(accId).Engagement_Level__c.contains('Customer Engaged'))
                {
                    mapOfAccountIdToAccounts.get(accId).Engagement_Level__c = 'Customer Engaged';
                    setOfAccountsIdsToUpdate.add(accId);
                }

            }
                
        }

    }

         for(Contact con : [Select ID,LastActivityDate, Email, RecordTypeId, AccountId, (Select Id,WhoId,CreatedDate,Subject,OwnerId from ActivityHistories where OwnerId = :marketoSyncUserId and Subject Like '%Opened Email%' and CreatedDate = LAST_N_DAYS:90 )
         from Contact where  RecordTypeId =:  businessContactRecordTypeId  AND (NOT Email LIKE '%@akamai.com%') AND  AccountId in : setOfAccountIds ])  // exclude PSA contacts  //email!=akamai.com // and Not in : unegaged])
        {
            System.debug('Activity history' + con.ActivityHistories);
            if(!con.ActivityHistories.isEmpty())
            {
                System.debug('marketing id' + con.AccountId);
                setOfMarketingAccountIdsTrue.add(con.AccountId);
  
            }
               
        }
        
        for(CampaignMember cm :[Select Contact.Id,Contact.AccountId, CreatedDate 
            from CampaignMember where Contact.AccountId in : setOfAccountIds AND  Contact.AccountId!= null and Status ='Responded' and FirstRespondedDate  = LAST_N_DAYS:180] )
        {
            
                System.debug('marketing id' + cm.Contact.AccountId);
                setOfMarketingAccountIdsTrue.add(cm.Contact.AccountId);
            
                
        }
        
        for(Lead l :[Select Id, RecordTypeId,Associated_Account__c, CreatedDate,Associated_Contact__c from Lead where Associated_Account__c in : setOfAccountIds 
         AND (RecordTypeId =: inboundLeadRecordTypeId OR RecordTypeId =: outboundLeadRecordTypeId) AND  Associated_Contact__c!=null and CreatedDate  = LAST_N_DAYS:180] )
        {
            
            if(l.Associated_Account__c!= null){
                System.debug('marketing id' + l.Associated_Account__c);
                setOfMarketingAccountIdsTrue.add(l.Associated_Account__c);
            }
                 
        }
            
        // Set Marketing Engaged(current value = false) to true if any condition is satisfied
         for(Id accountId : setOfMarketingAccountIdsTrue)
        {
            if(!mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.contains('Marketing Engaged'))
            {
                if(mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.contains('No Engagement'))
                    mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c = 'Marketing Engaged';
                else 
                    mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c += ';Marketing Engaged';
                setOfMarketingAccountIdsToUpdate.add(accountId);
            }    
        }

      //  System.debug('setOfNoEngagementAccountIds' + setOfNoEngagementAccountIds);

        System.debug('setOfMarketingAccountIdsTrue' + setOfMarketingAccountIdsTrue);

        // get set of accounts which are not marketing engaged
        setOfAccountIds.removeAll(setOfMarketingAccountIdsTrue);
        setOfMarketingAccountIdsFalse.addAll(setOfAccountIds);
        System.debug('setOfMarketingAccountIdsFalse' + setOfMarketingAccountIdsFalse);

        // clean up : Set Marketing Engaged(current value = true) to false if none of the conditions are satisfied
        for(Id accountId : setOfMarketingAccountIdsFalse)
        {
            if(mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.contains(';') && mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.contains('Marketing Engaged'))
            {
                mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c = mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.remove(';');
                mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c = mapOfAccountIdToAccounts.get(accountId).Engagement_Level__c.remove('Marketing Engaged');
                setOfMarketingAccountIdsToUpdate.add(accountId);
            }     
        }


        System.debug('setOfMarketingAccountIdsToUpdate  ' + setOfMarketingAccountIdsToUpdate);

        // add all marketing engaged accounts to the main set 
        setOfAccountsIdsToUpdate.addAll(setOfMarketingAccountIdsToUpdate);

       
        
        // get all accounts to be updated
        for(Id accId : setOfAccountsIdsToUpdate)
        {
            mapOfAccountIdToAccounts.get(accId).Validation_Override__c = true;
            listOfAccountsToUpdate.add(mapOfAccountIdToAccounts.get(accId));
        }


        System.debug('#Final :List of accs to update ' + listOfAccountsToUpdate);
        
       results = Database.update(listOfAccountsToUpdate, false);
       String accountURL;
       String baseUrl;
       for (Database.SaveResult sr : results) 
        {
            System.Debug('Checkpoint X: in saveresults for loop');
            if (!sr.isSuccess()) 
            {
                errorFlag = true; 
                for(Database.Error err : sr.getErrors())
                {
                    baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                    accountURL = '<a href="'+ baseUrl+ listOfAccountsToUpdate[count].Id +'">' + listOfAccountsToUpdate[count].Name + '</a>';    
                    errorString.add('<tr>' + '<td>'+ listOfAccountsToUpdate[count].AKAM_Account_ID__c  +'</td>'+'<td>'+ accountURL +'</td>'+ '<td>' + err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                    System.debug('err message : '+ err.getMessage());
                    failedUpdates = failedUpdates + 1;
                }
            }
            count = count +1;
        } 
        
    }
  }

    global void finish(Database.BatchableContext BC)
    {
        String tableBegin;
        
        if(errorFlag)
        {
            List<Cron_Batch_Run__c> listOfCronRuns = [select id, CreatedDate, SystemModstamp, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__C = 'Account Engagement Level' and Result__c!=null order by CreatedDate DESC];
            if(listOfCronRuns.size()>0)
            {
                listOfCronRuns[0].Result__c = 'Error';
                update listOfCronRuns[0];
            }
         }
         
         AsyncApexJob a = [SELECT id, ApexClassId, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE id = :BC.getJobId()];
        
         String emailMessage = 'Your batch job AccountEngagementLevelBatchClass has finished. ' +'<br/>Total batches : ' + a.totalJobItems + '<br/>Batches processed :  ' +  a.jobitemsprocessed + '<br/>Failures :' + a.numberOfErrors +
         '<br/>Failed records : '+  failedUpdates ;
       
        
         if(errorFlag)
         {
             tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Account AKAM ID</th><th>Account Name</th><th>Error</th><th>Error Field</th></tr>';
             emailMessage = emailMessage + '<br/>' +tableBegin;
             for( String str : errorString)
             {
                 emailMessage = emailMessage +  str;
             }
             emailMessage = emailMessage + '</table>';
         }
         
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         //String emailAddresses = GSM_Custom_Settings__c.getInstance('CronAccEngagementLevel#emailList').value__c; //SFDC-2304
         String emailAddresses = GsmUtilClass.getGSMSettingValue('CronAccEngagementLevel_emailList'); //SFDC-2304
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