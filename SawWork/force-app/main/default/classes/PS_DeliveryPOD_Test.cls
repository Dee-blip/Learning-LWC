@isTest(SeeAllData=true) 
public class PS_DeliveryPOD_Test 
{


    public static Account                       acct;
    public static PSA_TestUtility               testUtil;  
    public static Contact                       resource;
    public static User                          usr; 
    public static POD_Association__c            pod;
    public static Delivery_Team__c              dt;
    public static Delivery_Team_Membership__c   dtm;
    public static AccountTeamMember             atm;
    public static Account_Department__c         ad;
    
    static
    {

        testUtil            = new PSA_TestUtility();
        
        usr                 = testUtil.newUserSysAdmin(false);
        usr.UserName        =  '456' + usr.UserName;
        usr.Title           = 'Director..Service Line';
        usr.Cost_Center__c  = 10138;
        //usr.managerId       = usr2.id;

        insert usr;
        

        acct                 = testUtil.newAccount(false);
        acct.Name            = 'Living Church Of God';
        acct.TERR_HIER_1__c  = 'Media Americas';
        acct.TERR_HIER_2__c  = 'Media Americas';
        acct.TERR_HIER_3__c  = 'Broadcasting';
        acct.TERR_HIER_4__c  = 'Media East';
        acct.TERR_HIER_5__c  = 'Media East';

        insert acct;
        
        atm                 = utilTestClass.CreateAccountTeamMember(acct.id, userinfo.getuserId());
        atm.TeamMemberRole  = 'PS - Primary';
        insert atm;
        
        ad                  = new Account_Department__c();
        ad.Account_Name__c  = acct.Id;
        ad.Name             = 'test';
        
        insert ad;


        resource                    =   testUtil.newResource(false, acct.Id, usr.Id);
        resource.email              =   'deliveryPODcontact@akamai.com';
        
        insert resource;


        //utilTestClass.createCustomSettings();
        //utilTestClass.createData_SC_SupportEmail();
        
        
        
        POD_Association__c pod  =   new POD_Association__c();
            pod.Name = 'POD tets'; 
            pod.Updating_Object__c = 'Account';
            pod.Active__c = true;
            pod.POD_Executed__c = true;
            pod.Report_Link__c  = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
        insert pod;
        
        pod.Name = 'Tets POD';
        update pod;        
        

        
        dt                          =   new Delivery_Team__c(Name = 'DT tets', POD_Association__c = pod.Id, Description__c = 'tets' );
        insert dt;
        
        
        dtm                         =   new Delivery_Team_Membership__c (Delivery_Team_Member_ID__c  = 'DTM tets', Role__c  = 'Security Architect', Name__c = 'Syhat', Resource__c = resource.Id, Delivery_Team__c = dt.Id, From_Date__c = Date.newInstance(2022, 01, 01), To_Date__c  = Date.newInstance(2022, 01, 31), Assigned__c = 40);
        insert dtm; 
        
        dtm.Assigned__c = 40;
        update dtm;
        

    }
    
    @isTest 
    public static void updatePOD()
    {
        Test.startTest();
            POD_Association__c pod  =   new POD_Association__c();
            pod.Name = 'POD tets'; 
            pod.Updating_Object__c = 'Account Dept';
            pod.Active__c = true;
            pod.POD_Executed__c = true;
            pod.Report_Link__c  = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert pod;
        Test.stopTest();
    }
    
    
    @isTest 
    public static void updateDTM()
    {
        Test.startTest();
        
            Delivery_Team_Membership__c dtm2 =  new Delivery_Team_Membership__c (Delivery_Team_Member_ID__c  = 'DTM tets2', Role__c  = 'Security Architect', Name__c = 'Syhat', Resource__c = resource.Id, Delivery_Team__c = dt.Id, From_Date__c = Date.newInstance(2022, 01, 01), To_Date__c  = Date.newInstance(2022, 01, 31), Assigned__c = 40);
            insert dtm2; 
        
        Test.stopTest();
    }
    
    @isTest 
    public static void deletePOD_DTM()
    {
        Test.startTest();
        
            POD_Association__c poddel   =   new POD_Association__c();
            poddel.Name = 'POD tets'; 
            poddel.Updating_Object__c = 'Account Dept';
            poddel.Active__c = true;
            poddel.POD_Executed__c = true;
            poddel.Report_Link__c  = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert poddel;
        
            Delivery_Team_Membership__c dtm2 =  new Delivery_Team_Membership__c (Delivery_Team_Member_ID__c  = 'DTM tets3', Role__c  = 'Security Architect', Name__c = 'Syhat', Resource__c = resource.Id, Delivery_Team__c = dt.Id, From_Date__c = Date.newInstance(2022, 01, 01), To_Date__c  = Date.newInstance(2022, 01, 31), Assigned__c = 40);
            insert dtm2; 
        
            delete poddel;
        
            delete dtm2;
        
        Test.stopTest();
    }
    
    
    @isTest 
    public static void podAssignmentOverBatchAccount()
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            Set<String> accOrDepIdds        = new Set<String>();
        
            accOrDepIdds.add(acct.Id);
        
            ps_PODAssignmentBatch bacthAssignmentForPOD = new ps_PODAssignmentBatch();
            bacthAssignmentForPOD.accOrDepIds = accOrDepIdds;
            bacthAssignmentForPOD.podRecordId = podRec.Id;  
            
            Database.executeBatch(bacthAssignmentForPOD);
        
            List<Id> lAccOrDep = new List<Id>();
            lAccOrDep.add(ad.Id);
        
            PS_PODTriggerClass.assignPODstoAccOrAccDeptRecords(lAccOrDep, 'Account', podRec.Id, podRec.Name);
        
        Test.stopTest();
    }
    
    
    
    @isTest 
    public static void podAssignmentOverBatchAccountAndAccountDept()
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account & Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            Set<String> accOrDepIdds        = new Set<String>();
        
            accOrDepIdds.add(ad.Id);
        
            ps_PODAssignmentBatch bacthAssignmentForPOD = new ps_PODAssignmentBatch();
            bacthAssignmentForPOD.accOrDepIds = accOrDepIdds;
            bacthAssignmentForPOD.podRecordId = podRec.Id;  
            Database.executeBatch(bacthAssignmentForPOD);  
        
            List<Id> lAccOrDep = new List<Id>();
            lAccOrDep.add(ad.Id);
        
            PS_PODTriggerClass.assignPODstoAccOrAccDeptRecords(lAccOrDep, 'Account & Account Dept', podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest 
    public static void podAssignmentOverBatchAccountDept()
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            Set<String> accOrDepIdds        = new Set<String>();
        
            accOrDepIdds.add(ad.Id);
        
            ps_PODAssignmentBatch bacthAssignmentForPOD = new ps_PODAssignmentBatch();
            bacthAssignmentForPOD.accOrDepIds = accOrDepIdds;
            bacthAssignmentForPOD.podRecordId = podRec.Id;  
            Database.executeBatch(bacthAssignmentForPOD); 
            
            List<Id> lAccOrDep = new List<Id>();
            lAccOrDep.add(ad.Id);
        
            PS_PODTriggerClass.assignPODstoAccOrAccDeptRecords(lAccOrDep, 'Account Dept', podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper_Coverage() //PS_PODTriggerClass - getReportAsWrapper
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List <Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'POD'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper2_Coverage() //getReportAsWrapper
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List<Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'Account_With_Account_Dept_DevTestClass'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper3_Coverage() //getReportAsWrapper
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account & Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List<Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'Account_With_Account_Dept_DevTestClass'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper4_Coverage() //getReportAsWrapper
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List<Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'Account_With_Account_Dept_DevTestClass'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper5_Coverage() //getReportAsWrapper for invalid case
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List<Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'POD'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    @isTest(SeeAllData='true')
    public static void getReportAsWrapper6_Coverage() //getReportAsWrapper for invalid case
    {
        Test.startTest();
        
            POD_Association__c podRec   = new POD_Association__c();
            podRec.Name                 = 'POD tets1'; 
            podRec.Updating_Object__c   = 'Account & Account Dept';
            podRec.Active__c            = true;
            podRec.POD_Executed__c      = true;
            podRec.Batch_Process__c     = true;
            podRec.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
            insert podRec;
        
            PS_PODTriggerClass.getPODDetail(podRec.Id);
            
            List<Report> reportList = [select Id, DeveloperName, Format, Name from Report where DeveloperName = 'Account_With_Account_Dept_DevTestClass'];
            String reportId = (String)reportList.get(0).get('Id');
        
            PS_PODTriggerClass.getReportAsWrapper(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
            //PS_PODTriggerClass.cls_WrapperForLWC clasWraper = (PS_PODTriggerClass.cls_WrapperForLWC) PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
            //
            //clsWrap = PS_PODTriggerClass.retrieveAccounts(reportId, podRec.Updating_Object__c,podRec.Id, podRec.Name);
        
        
        Test.stopTest();
    }
    
    
    
    public static POD_Association__c getPODRecord(boolean insertRecord, String name, String updatingObj, boolean active, boolean executed, boolean batchProcess, String reportLink)
    {
        POD_Association__c newPOD = new POD_Association__c();
        newPOD.Name                 = 'POD tets1'; 
        newPOD.Updating_Object__c   = 'Account & Account Dept';
        newPOD.Active__c            = true;
        newPOD.POD_Executed__c      = true;
        newPOD.Batch_Process__c     = true;
        newPOD.Report_Link__c       = 'https://akamai--gssdevqa.my.salesforce.com/00O8I000000FT2g';
        
        
        if(insertRecord)
        {
            insert newPOD;
            
        }
        return newPOD;
    }

}