/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Akhila      3527281     Scheduler class to log object usage of every user on UserLicenseUsageLog__c
+=====================================================================================================--*/
global class LicenseUsageLogOnUserScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        Set<String> sAllQueriesToExecute = new Set<String>();
        Map<String,String> mObjectLicense = new Map<String,String>();
        for(License_Query__c licQuery :[Select Query_Prefix__c,Object__c,License_type__c from License_Query__c where License_Namespace_Prefix__c!=null]){
            sAllQueriesToExecute.add('select ' +licQuery.Query_Prefix__c.toLowerCase()+' from '+licQuery.Object__c.toLowerCase());
            mObjectLicense.put(licQuery.Object__c.toLowerCase(), licQuery.License_type__c);
        }
        String currentQuery;
        for(String q : sAllQueriesToExecute)
        {
            currentQuery = q;
            break;
        }
        LicenseUsageLogOnUserBatch b = new LicenseUsageLogOnUserBatch(sAllQueriesToExecute,currentQuery,mObjectLicense); 
        database.executebatch(b,1000);
   }
}