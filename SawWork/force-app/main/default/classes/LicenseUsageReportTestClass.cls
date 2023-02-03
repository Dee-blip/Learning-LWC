/*--=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  03-Oct-2016    Akhila      3527281     Test class for Automating License Usage Report

|  03-Nov-2020    Sandeep     FFPSA-1765    Code Scan Issues fixes
+=====================================================================================================--*/
@isTest(seeAllData = false )
public class LicenseUsageReportTestClass {

    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static pse__Practice__c pract;
    Public static Id practId;
    Public static User usr;
    Public static User usr2;
    Public static pse__Proj__c proj1;

    public static void createQueryData()
    {
        List<License_Query__c> lQList = new List<License_Query__c>();
        License_Query__c lQ = new License_Query__c();
        lQ.Object__c = 'email';
        lQ.Query_Suffix__c = 'avidapan@akamai.com';
        lQList.add(lQ);
        lQ = new License_Query__c();
        lQ.Object__c = 'days';
        lQ.Query_Suffix__c = '365';
        lQList.add(lQ);
        lQ = new License_Query__c();
        lQ.License_Namespace_Prefix__c = 'pse';
        lQ.License_Type__c='Financial Force';
        lQ.Query_Prefix__c='createddate,lastmodifieddate,lastmodifiedbyid,createdbyid';
        lQ.Object__c = 'pse__proj__c';
        lQ.Query_Suffix__c = 'lastmodifiedbyid not in: uIdSet and createdbyid not in: uIdSet';
        lQList.add(lQ);
        insert lQList;
    }    
    
    public testmethod static void testLicenseUsageLogOnUserScheduler()
    {
        Test.startTest();
        createQueryData();
        LicenseUsageLogOnUserScheduler s = new LicenseUsageLogOnUserScheduler();
        system.schedule('LicenseUsageLogOnUserSchedulerTest','0 20 18 05 OCT ? 2089',s) ;
        Test.stopTest();
    }
    
    
    

    public testmethod static void testLicenseUsageReporterBatchClass()
    {
        //Create projects
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;


        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);




        Test.startTest();
        License_Job_Logger__c licRec = new License_Job_Logger__c();
        licRec.Email__c = UserInfo.getUserEmail();
		licRec.Start_Date_Time__c = DateTime.now().addMonths(-1);
		licRec.End_Date_Time__c  = DateTime.now();
        licRec.Submitted_By__c = UserInfo.getUserId();
        licRec.Status__c = 'In Progress';
        licRec.License_Type__c= ' Financial Force';
        licRec.License_Namespace_Prefix__c = 'pse';
        insert licRec;
        Set<String> querySet = new Set<String>();
        String firstQuery = 'Select createddate,lastmodifieddate,lastmodifiedbyid,createdbyid from pse__proj__c where lastmodifiedbyid not in: uIdSet and createdbyid not in: uIdSet';
        querySet.add(firstQuery);
        querySet.add('Select createddate,lastmodifieddate,lastmodifiedbyid,createdbyid from pse__milestone__c where lastmodifiedbyid not in: uIdSet and createdbyid not in: uIdSet');
        LicenseUsageReporterBatchClass b = new LicenseUsageReporterBatchClass(new Set<Id>(),querySet,firstQuery,200,licRec);
        Database.executeBatch(b,200);
        Test.stopTest();
    }
    
    public static testmethod void testLicenseUsageReporterController()
    {
        Test.startTest();
        createQueryData();
        License_Job_Logger__c licRec = new License_Job_Logger__c();
        licRec.Email__c = UserInfo.getUserEmail();
		licRec.Start_Date_Time__c = DateTime.now().addMonths(-1);
		licRec.End_Date_Time__c  = DateTime.now();
        licRec.Submitted_By__c = UserInfo.getUserId();
        licRec.Status__c = 'In Progress';
        licRec.License_Type__c= 'Financial Force';
        licRec.License_Namespace_Prefix__c = 'pse';
        ApexPages.StandardController sc = new ApexPages.StandardController(licRec);
        LicenseUsageReporterController luc = new LicenseUsageReporterController(sc);
    	luc.getdisableSubmitBtn();
        luc.submit();
        Test.stopTest();
    }
    
    public static testmethod void testLicenseUsageReportController()
    {

        Test.startTest();


        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        insert usr;

        system.runAs(usr)
        {
            PackageLicense pl = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status FROM PackageLicense WHERE NamespacePrefix = 'pse'];

            UserPackageLicense upl = new UserPackageLicense();
            upl.PackageLicenseId = pl.Id;
            upl.UserId = usr.Id;
            insert upl;

        }

        UserLicenseUsageLog__c allUsers = new UserLicenseUsageLog__c();
        //allUsers.UserExternalId__c = '005G0000003ClaSIAS';
        allUsers.UserExternalId__c = usr.id;
        allUsers.User__c = usr.id;
        allUsers.LicenseUsageLog__c = '[ {  "objectsUsage" : [ {    "lastUsedDate" : "2018-12-26T17:45:56.000Z",    "object" : "pse__timecard_header__c"  }, {    "lastUsedDate" : "2018-12-26T17:45:56.000Z",    "object" : "pse__milestone__c"  }, {    "object" : "pse__assignment__c",    "lastUsedDate" : "2018-12-26T17:45:56.000Z"  }, {    "lastUsedDate" : "2018-12-20T22:30:55.000Z",    "object" : "pse__proj__c"  }, {    "object" : "project_contract__c",    "lastUsedDate" : "2018-12-10T19:21:08.000Z"  }, {    "object" : "project_contract_line_item__c",    "lastUsedDate" : "2018-12-10T19:21:08.000Z"  }, {    "object" : "pse__project_methodology__c",    "lastUsedDate" : "2018-12-10T19:21:37.000Z"  } ],  "lastUsedDate" : "2018-12-26T17:45:56.000Z",  "lastUsedObject" : "pse__assignment__c",  "licenseName" : "Financial Force"} ]';
        insert allUsers;


        License_Report_Run_Logger__c licRep = new License_Report_Run_Logger__c();
        licRep.License_Name__c = 'Financial Force';
        licRep.Filter__c = 'Inactive Users';
        licRep.Start_Date__c = System.today().addMonths(-3);
        licRep.Report_Creator__c = Userinfo.getUserId();

        PageReference pageRef = Page.LicenseUsageDownload;
        Test.setCurrentPage(pageRef);
        // put the lead id as a parameter
        ApexPages.currentPage().getParameters().put('licenseName','pse');
        ApexPages.currentPage().getParameters().put('usageStartDate',String.valueOf(Date.today()));
        ApexPages.currentPage().getParameters().put('usageType','read');

        ApexPages.StandardController sc = new ApexPages.StandardController(licRep);
        LicenseUsageReportController luc = new LicenseUsageReportController(sc);
        LicenseUsageReportController luc2 = new LicenseUsageReportController();

        
        luc.runReport();
		luc.sendCSVToCreator();        
        Test.stopTest();
    }

    public static testmethod void testLicenseUsageLogOnUserBatchController()
    {
        Test.startTest();

        
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        insert usr;

        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;


        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);


        Set<String> sAllQueriesToExecute = new Set<String>();
        Map<String,String> mObjectLicense = new Map<String,String>();

        License_Query__c lcq = new License_Query__c();
        lcq.License_Namespace_Prefix__c = 'pse';
        lcq.Query_Prefix__c = 'createddate,lastmodifieddate,lastmodifiedbyid,createdbyid';
        lcq.Object__c = 'pse__proj__c';
        lcq.License_type__c = 'Financial Force';
        insert lcq;


        UserLicenseUsageLog__c u = new UserLicenseUsageLog__c();
        u.LicenseUsageLog__c = '[ {  "objectsUsage" : [ {    "lastUsedDate" : "2017-03-05T12:26:58.000Z",    "object" : "pse__timecard_header__c"  }, {    "lastUsedDate" : "2017-03-05T12:26:58.000Z",    "object" : "pse__milestone__c"  } ],  "lastUsedDate" : "2017-03-05T12:26:58.000Z",  "lastUsedObject" : "pse__milestone__c",  "licenseName" : "Financial Force"} ]';
        //u.UserExternalId__c = '005G0000003ClaSIAS';
        u.UserExternalId__c = usr.id;
        insert u;

        
        
        License_Query__c lQueries = new License_Query__c();
        lQueries.Query_Suffix__c = 'gss-services-dev@akamai.com';
        lQueries.Object__c = 'email';
        insert lQueries;


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
        System.debug('All Queries: '+sAllQueriesToExecute);
        System.debug('Current Queryyy: '+currentQuery);


        sAllQueriesToExecute.add('select ID from pse__timecard_header__c');

        LicenseUsageLogOnUserBatch b = new LicenseUsageLogOnUserBatch(sAllQueriesToExecute,currentQuery,mObjectLicense); 
        database.executebatch(b,1000);

        Test.stopTest();
    }
}