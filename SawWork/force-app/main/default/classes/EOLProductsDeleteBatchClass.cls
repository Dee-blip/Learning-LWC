/*

   Author - Hitesh - 18 May 2018
   - Added Logic to get the EOL/EOS Product under Account Deleted if Last Modified date has passed 60 days and Status is Closed
   */

global class EOLProductsDeleteBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
	public String eolProductsDeleteNoOfDays = GsmUtilClass.getGSMSettingValue('EOLProductsDeleteNoOfDays');
	public Date lastmodifyDate = Date.today().addDays(-Integer.valueof(eolProductsDeleteNoOfDays));

     global EOLProductsDeleteBatchClass()
     {
         //Get all the  EOl EOS Product Records which are Closed and not been modified for last 60 days
        //Since LastModifiedDate is system date which cnnot be edited in test method for test class
         if(Test.isRunningTest()){
                query='select Id,EndOfLifeProductsExternalID__c from End_of_Life_Products__c where Status__c =\'Closed\'';
            }
            else {
                query='select Id,EndOfLifeProductsExternalID__c from End_of_Life_Products__c where Status__c =\'Closed\' AND LastModifiedDate  <= :lastmodifyDate ';
            }
     }

     
     global Database.QueryLocator start(Database.BatchableContext BC){ 
         results= new DMLResults(); 
         results.storeObjectState();
         

         return Database.getQueryLocator(query); 
     }
    //Scope size is configured in metadata
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        



        List<End_of_Life_Products__c> eolProducts = (List<End_of_Life_Products__c>)scope;
        
        if(eolProducts.size()>0)
        {
            results.dmlDelete(eolProducts);
        }


        
    }

    global void finish(Database.BatchableContext BC)
    {
        results.withJobName('EOL Products Delete').toAddress(GsmUtilClass.getGSMSettingValue('EOlProductsEmailLogToAddress')).sendLogMail();
        
        
    }
 }