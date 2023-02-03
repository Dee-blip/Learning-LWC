/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Akhila      3527281     Controller class for the first version of Automating License Usage Report

+=====================================================================================================--*/
public without sharing class LicenseUsageReporterController {

    public License_Job_Logger__c licRec{get;set;}
    public List<License_Job_Logger__c > jlogs {get;set;}
    public Boolean validStartDate {get;set;}
    private Integer list_size = 3;
    private Integer total_size;      //Total no of records        
    
    //Constructor
    public LicenseUsageReporterController(ApexPages.StandardController controller)
    {
        licRec = (License_Job_Logger__c)controller.getRecord();
        licRec.Email__c = UserInfo.getUserEmail();
        licRec.Start_Date_Time__c = DateTime.now().addMonths(-3);
		licRec.End_Date_Time__c  = DateTime.now();
        licRec.Submitted_By__c = UserInfo.getUserId();
        licRec.Status__c = 'In Progress';
        this.total_size = [select count() from License_Job_Logger__c ];
    }
    
     public Boolean getdisableSubmitBtn(){
        //If a Batch jub is running, disable submit button everywhere.
        List<License_Job_Logger__c> lLicJob= [Select Id from License_Job_Logger__c where Status__c = 'In Progress'];
        if(!lLicJob.isEmpty())
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    public void submit(){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Report request submitted, report will be sent to '+ licRec.Email__c));
        String queryString = '';
        String queryGroup = '';
        Set<String> querySet = new Set<String>();
        //Add all the queries to the set
        for(License_Query__c licQryRec : [Select Query_Prefix__c,Object__c,Query_Suffix__c,License_Namespace_Prefix__c from License_Query__c  
                                          where License_type__c =:licRec.License_Type__c ])
        {
            licRec.License_Namespace_Prefix__c = licQryRec.License_Namespace_Prefix__c;
            querySet.add('select ' + licQryRec.Query_Prefix__c + ' from ' + licQryRec.Object__c + ' where ' + licQryRec.Query_Suffix__c);
        }
        
        //If there is atleast one query, querySet will not be empty
        if(!querySet.isEmpty())
        {    
            Set<Id> u= new Set<Id>();
            Integer batchSize = 200; 
            
            //Insert the license record and attach the csv report to the record
            insert licRec;
            
            //Pass empty user set to consolidate all the users who are using license, the entire query set, the first query to be executed, 
            //batchsize and the License Report Logger record id
            String firstQuery = '';
            for(String q : querySet)
            {
                firstQuery = q;
                break;
            }
            System.debug(licRec.End_Date_Time__c);
            LicenseUsageReporterBatchClass b = new LicenseUsageReporterBatchClass(u,querySet,firstQuery,batchSize,licRec);
            Id batchId = Database.executeBatch(b,batchSize);
            
            //Assigning licRec to new record to avoid exception on clicking of submitting again
            licRec.Id = null;               
        }
    }
    //Get latest 10 job records
    public List<License_Job_Logger__c> licJobLogs {
        get {
                licJobLogs = [SELECT Submitted_By__c ,Status__c,CreatedDate,License_type__c , Email__c  from License_Job_Logger__c order by CreatedDate desc limit 10 ];
            	return licJobLogs;
        	}
        private set;
    }
        
}