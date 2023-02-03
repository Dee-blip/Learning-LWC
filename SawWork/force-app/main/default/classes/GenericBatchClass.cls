global virtual class GenericBatchClass implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts
{
     
     global Integer failedUpdates;
     global Integer totalUpdates;

     global Integer successfulUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
     global static Boolean nowRunningDataFix =false;
     global String query {get;set;}
     global Boolean saveErrorLog =true;
     public String className;
     public String errorAddressCustomSetting ;
     public String operationType;
     
     global GenericBatchClass()
     { 
         failedUpdates = 0;
         successfulUpdates = 0;
         errorFlag = false;
         errorString = new List<String>();
         totalUpdates = 0;
         errorAddressCustomSetting='BatchClassStatusMailFallback';
         operationType = 'Update';
     }


     global Database.QueryLocator start(Database.BatchableContext BC)
     {
        System.debug(LoggingLevel.ERROR,'query' + query);
         return Database.getQueryLocator(query);
     }
     
    
    
    global virtual void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        if(scope!=null && scope.size()>0)
        {
            nowRunningDataFix = true;       
            totalUpdates += scope.size();
            Database.SaveResult[] srList;

            if(operationType == 'Insert')
                srList = Database.insert(scope, false);
            else if(operationType == 'Update')
                srList = Database.update(scope, false);

            List<Error_Log__c> errorLogs = new List<Error_Log__c>();
            Integer count=0;
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
            for (Database.SaveResult sr : srList) 
            {
                System.Debug('Checkpoint X: in saveresults for loop');
                if (!sr.isSuccess() || TEST.isRunningTest()) 
                {
                    errorFlag = true;
                    failedUpdates = failedUpdates +1;
                    String errMessage='';
                    for(Database.Error err : sr.getErrors()) 
                    {                  
                        errMessage += err.getFields() +': ' + err.getMessage() + '<br/>';
                        System.debug('SH Debug : errMessage :'+errMessage);

                    }
                    String recordURL = '<a href="';
                    recordURL += baseUrl+scope[count].Id+'">';
                    try {
                        recordURL += scope[count].get('Name');
                    } catch(Exception e) {
                        System.debug('Name field is not available');
                    }  
                    recordURL += '</a>';

                    errorString.add('<tr><td>'+recordURL+'</td><td>' + errMessage +'</td></tr>');

                    if(saveErrorLog)
                    {
                        Error_Log__c el = new Error_Log__c(Name=className, Class__c=className, Error_Message__c=errMessage , RecordId__c=scope[count].Id);
                        errorLogs.add(el);
                    }
                }
                count = count + 1;      
            }
            if(errorLogs.size()>0){
                Sawyer.saw(errorLogs, className, className)   ; 
                //Database.insert(errorLogs, false);
            }

        }
    }
    global virtual void finish(Database.BatchableContext BC)
    {
         
        AsyncApexJob a = [SELECT id, ApexClass.Name, JobItemsProcessed, TotalJobItems, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE id = :BC.getJobId()];

        String ErrorMsg =  'Your batch job '+ a.ApexClass.Name + ' has finished. ' +'<br/>Total batches : ' + a.totalJobItems + '<br/>Batches processed :  ' +  a.jobitemsprocessed + '<br/>Record Updates Tried: ' + totalUpdates+
                      '<br/>Failed records : '+  failedUpdates + '<br/><br/>';
        String status = 'Completed';
        if(a.NumberOfErrors != 0){
            status = 'Failed';
        }
        if(errorString.size() > 0){
            for(String err : errorString){
                ErrorMsg += '---'+err;
            }
           
        }
        JobQueueSchedulerFramework.updateJobDetailRecords(a.id ,ErrorMsg , status, '',totalUpdates , failedUpdates);
        
    }
 }