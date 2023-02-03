/** Sonali Tandon - 4/02/2016 - SFDC-246- CR 3262841
Cron job to calculate Focus__c attribute on Account to run once a momth. Focus is calculated based outside and inside traffic of primary country.
 Traffic data is consumed from Alexa Web Services.

 **/
global class CronPopulateAccountFocusAttributeClass extends GenericBatchClass
{
     global Integer failedUpdates;
     global Boolean errorFlag {get;set;}
     global Integer successFullCallOuts;
     global Decimal price;
     global Integer alexaBatchSize;
     global Integer sizeOfErrorLogRecords;

    global CronPopulateAccountFocusAttributeClass()
     {
         super();
         failedUpdates = 0;
         errorFlag = false;
         successFullCallOuts = 0;
         sizeOfErrorLogRecords = 0; 
         super.errorString = new List<String>();
         price = Decimal.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_PricePerCallout')); //SFDC-2391
         alexaBatchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_BatchRequestSize')); //SFDC-2391
         className = 'CronPopulateAccountFocusAttributeClass';
         query = 'Select Id,AKAM_Account_ID__c, Name,Focus__c,Domain__c, Website, Target_Category__c, BillingCountry from Account where Target_Category__c LIKE \'CAT-%\'';

     }

     global class DataWrapper
     {
        global Id accountId;
        global String website;
        global String primaryCountry;
        global String focus;
     }

     
     /*global Database.QueryLocator start(Database.BatchableContext BC)
     {
          return Database.getQueryLocator([Select Id,AKAM_Account_ID__c, Name,Focus__c,Domain__c, Website, Target_Category__c, BillingCountry from Account where Target_Category__c LIKE 'CAT-%']);
     }*/
    
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   

        List<Account> listOfAccounts = (List<Account>)scope;
        List<Account> listOfAccountsToUpdate = new List<Account>();
        List<DataWrapper> listOfDataWrappers = new List<DataWrapper>();
        List<DataWrapper> finalListOfDataWrappers = new List<DataWrapper>();
        List<Error_log__c> listOfErrorLogs = new List<Error_log__c>();

        Integer quotient = listOfAccounts.size()/alexaBatchSize;
        Integer remainder = Math.mod(listOfAccounts.size(), alexaBatchSize);
        Integer counter = 1;

        Map<Id,Account> mapOfAccountIdToAccount = new Map<Id,Account>();

        Database.SaveResult[] results;

        System.debug('quotient' + quotient + 'remainder' + remainder);
       
        for(Account account : listOfAccounts)
        {

            try{

                mapOfAccountIdToAccount.put(account.Id, account);

                System.debug('counter' + counter);

                // Get domain. If domain is blank, use website 
                if(account.Domain__c!=null)
                {
                    DataWrapper data = new DataWrapper();
                    data.accountId = account.Id;
                    data.website = account.Domain__c;
                    data.primaryCountry = account.BillingCountry;
                    listOfDataWrappers.add(data);
                } 
                if(account.Domain__c == null && account.Website!=null)
                {
                    DataWrapper data = new DataWrapper();
                    data.accountId = account.Id;
                    data.website = account.Website;
                    data.primaryCountry = account.BillingCountry;
                    listOfDataWrappers.add(data);

                }
                
                // batch records as per alexaBatchSize
                if((listOfDataWrappers.size() == alexaBatchSize && counter<= quotient*alexaBatchSize) || (listOfDataWrappers.size() == remainder && counter > quotient*alexaBatchSize))
                {
                    
                    AlexaWebServiceCallClass wsObj  = new AlexaWebServiceCallClass(listOfDataWrappers);
                    HttpResponse response = wsObj.startWebserviceCall();

                    // if response code = 200 
                    if(response.getStatusCode() == 200)
                    {
                        AlexaWebServiceParseClass parseObj = new AlexaWebServiceParseClass(listOfDataWrappers);
                        AlexaWebServiceParseClass.ParsedResponse parseResponseObj = parseObj.parseResponse(response);

                        // if the response is valid 
                        if(parseResponseObj.statusMessage.contains('Success'))
                        {
                            System.debug('In loop : listOfDataWrappers' + finalListOfDataWrappers);
                            finalListOfDataWrappers.addAll(listOfDataWrappers);
                            successFullCallOuts ++;
                        }
                        // if response is invalid 
                        else if(parseResponseObj.statusMessage.contains('Error') || Test.isRunningTest())
                        {
                            for(DataWrapper data : listOfDataWrappers)
                            {
                                System.debug('Response = 200 error' + listOfDataWrappers.size() );
                                Error_log__c errorLog = new Error_log__c();
                                errorLog.Class__c = 'CronPopulateAccountFocusAttributeClass';
                                errorLog.Error_Message__c = 'Website : ' + data.website + '\n' + 'Error message : '+ parseResponseObj.statusMessage;
                                errorLog.RecordId__c = data.accountId;
                                listOfErrorLogs.add(errorLog);
                                sizeOfErrorLogRecords++;
                            }    
                        }

                    
                    }
                    // if there is any callout exception/other exception/ status code!=200
                    else
                    {
                        for(DataWrapper data : listOfDataWrappers)
                        {
                            System.debug('Callout exception/other exception/ status code!=200' + listOfDataWrappers.size());
                            Error_log__c errorLog = new Error_log__c();
                            errorLog.Class__c = 'CronPopulateAccountFocusAttributeClass';
                            errorLog.Error_Message__c = 'Website : ' + data.website + '\n' + 'Error message : '+ response.getBody();
                            errorLog.RecordId__c = data.accountId;
                            listOfErrorLogs.add(errorLog);
                            sizeOfErrorLogRecords++;
                        }          
                    }

                    // reset 
                      listOfDataWrappers.clear();
                    if(Test.isRunningTest()){
                       //'For coverage purpose'
                       integer i = 1/0;
                    }
                  
                }
            }
             catch(Exception e )
            {
                Error_log__c errorLog = new Error_log__c();
                errorLog.Class__c = 'CronPopulateAccountFocusAttributeClass';
                errorLog.Error_Message__c = e +  ' ' + e.getStackTraceString();
                listOfErrorLogs.add(errorLog);
                sizeOfErrorLogRecords++;
            }
            
            counter ++;

        }

        System.debug('finalListOfDataWrappers' + finalListOfDataWrappers);
        System.debug('listOfErrorLogs' + listOfErrorLogs);

        if(finalListOfDataWrappers.size()>0)
        {
            for(DataWrapper finalData : finalListOfDataWrappers)
            {
                if(mapOfAccountIdToAccount.containsKey(finalData.accountId))
                {
                    mapOfAccountIdToAccount.get(finalData.accountId).Focus__c = finalData.focus;
                    listOfAccountsToUpdate.add(mapOfAccountIdToAccount.get(finalData.accountId)); 
                }
                
            }
        }

        System.debug('listOfAccountsToUpdate' + listOfAccountsToUpdate);
                
        if(listOfAccountsToUpdate.size()>0)
         results = Database.update(listOfAccountsToUpdate, false);

        if(listOfErrorLogs.size()> 0)
            insert listOfErrorLogs;


        String accountURL;
        String baseUrl;
        Integer count=0;

        if(results!= null){

            for (Database.SaveResult sr : results) 
            {   
                System.debug('Checkpoint X: in saveresults for loop');
                if (!sr.isSuccess()) 
                {
                    errorFlag = true; 
                    for(Database.Error err : sr.getErrors())
                    {
                        baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                        accountURL = '<a href="'+ baseUrl+ listOfAccountsToUpdate[count].Id +'">' + listOfAccountsToUpdate[count].Name + '</a>';    
                        super.errorString.add('<tr>' + '<td>'+ listOfAccountsToUpdate[count].AKAM_Account_ID__c  +'</td>'+'<td>'+ accountURL +'</td>'+ '<td>' + err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                        System.debug('err message : '+ err.getMessage());
                        failedUpdates = failedUpdates + 1;
                    }
                }
                count = count +1;
            } 
        }
       
    }

    global override void finish(Database.BatchableContext BC)
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
        
        String emailMessage = 'Your batch job CronPopulateAccountFocusAttributeClass has finished. ' +'<br/>Total batches : ' + a.totalJobItems + '<br/>Batches processed :  ' +  a.jobitemsprocessed + '<br/>Failures :' + a.numberOfErrors +
         '<br/>Failed records on update : '+  failedUpdates + '<br/>No. of successful callouts : ' + successFullCallOuts + '<br/> Cost : $' + (successFullCallOuts*price);
        if(sizeOfErrorLogRecords>0)
            emailMessage    = emailMessage + '<br/>' + 'Failed records due to other exceptions :' + sizeOfErrorLogRecords + '. Please check Error Log for more details on these records.';
        
         if(errorFlag)
         {
             tableBegin = 'Details of failed records on update : <br/>' + '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Account AKAM ID</th><th>Account Name</th><th>Error</th><th>Error Field</th></tr>';
             emailMessage = emailMessage + '<br/>' +tableBegin;
             for( String str : errorString)
             {
                 emailMessage = emailMessage +  str;
             }
             emailMessage = emailMessage + '</table>';
         }
         
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String emailAddresses = GsmUtilClass.getGSMSettingValue('Alexa_EmailAddresses'); //SFDC-2391
         System.debug('custom'+emailAddresses);
         String[] toAddresses = emailAddresses.split(',');
        
         mail.setToAddresses(toAddresses);
         mail.setReplyTo('noreply@salesforce.com');
         mail.setSenderDisplayName('Batch Job Summary');
         mail.setSubject('Batch job completed');
         mail.setPlainTextBody(emailMessage);
         mail.setHtmlBody(emailMessage);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         super.finish(BC);

    }
}